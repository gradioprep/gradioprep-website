-- Phase 2: transaction-safe linkage from a submitted timed/untimed attempt
-- to its matching human-assessment submission. No analytics are derived here.
ALTER TABLE public.attempts
  ADD CONSTRAINT attempts_timed_assessment_link_identity_unique
  UNIQUE (id, learner_id, task_version_id);

ALTER TABLE public.assessment_submissions
  ADD CONSTRAINT assessment_submissions_timed_assessment_link_identity_unique
  UNIQUE (id, learner_id, task_version_id);

CREATE TABLE private.timed_attempt_assessment_links (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  attempt_id uuid NOT NULL,
  assessment_submission_id uuid NOT NULL,
  learner_id uuid NOT NULL,
  task_version_id uuid NOT NULL,
  idempotency_key uuid NOT NULL,
  linked_at timestamptz NOT NULL DEFAULT clock_timestamp(),
  CONSTRAINT timed_attempt_assessment_links_attempt_unique UNIQUE (attempt_id),
  CONSTRAINT timed_attempt_assessment_links_submission_unique UNIQUE (assessment_submission_id),
  CONSTRAINT timed_attempt_assessment_links_idempotency_unique
    UNIQUE (learner_id, idempotency_key),
  CONSTRAINT timed_attempt_assessment_links_attempt_identity_fk
    FOREIGN KEY (attempt_id, learner_id, task_version_id)
    REFERENCES public.attempts (id, learner_id, task_version_id)
    ON DELETE CASCADE,
  CONSTRAINT timed_attempt_assessment_links_submission_identity_fk
    FOREIGN KEY (assessment_submission_id, learner_id, task_version_id)
    REFERENCES public.assessment_submissions (id, learner_id, task_version_id)
    ON DELETE CASCADE
);

COMMENT ON TABLE private.timed_attempt_assessment_links IS
  'Private, immutable one-to-one relationship between a learner-owned submitted attempt and the matching human-assessment submission. Contains no response text, marks or timing calculations.';

ALTER TABLE private.timed_attempt_assessment_links ENABLE ROW LEVEL SECURITY;
REVOKE ALL ON private.timed_attempt_assessment_links
  FROM PUBLIC, anon, authenticated, service_role;

CREATE OR REPLACE FUNCTION private.prevent_timed_attempt_assessment_link_mutation()
RETURNS trigger
LANGUAGE plpgsql
SET search_path = ''
AS $function$
BEGIN
  -- Preserve normal account-deletion cascades while rejecting direct mutation.
  IF TG_OP = 'DELETE' AND pg_catalog.pg_trigger_depth() > 1 THEN
    RETURN OLD;
  END IF;
  RAISE EXCEPTION USING ERRCODE = '42501', MESSAGE = 'timed_attempt_assessment_link_immutable';
END;
$function$;

CREATE TRIGGER timed_attempt_assessment_links_immutable
  BEFORE UPDATE OR DELETE ON private.timed_attempt_assessment_links
  FOR EACH ROW EXECUTE FUNCTION private.prevent_timed_attempt_assessment_link_mutation();

REVOKE ALL ON FUNCTION private.prevent_timed_attempt_assessment_link_mutation()
  FROM PUBLIC, anon, authenticated, service_role;

CREATE OR REPLACE FUNCTION public.link_timed_attempt_assessment_submission(
  p_attempt_id uuid,
  p_assessment_submission_id uuid,
  p_idempotency_key uuid
)
RETURNS TABLE (
  link_id uuid,
  attempt_id uuid,
  assessment_submission_id uuid,
  learner_id uuid,
  task_version_id uuid,
  linked_at timestamptz,
  is_replay boolean
)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $function$
DECLARE
  v_actor_id uuid := auth.uid();
  selected_attempt public.attempts%ROWTYPE;
  selected_submission public.assessment_submissions%ROWTYPE;
  existing_link private.timed_attempt_assessment_links%ROWTYPE;
  created_link private.timed_attempt_assessment_links%ROWTYPE;
BEGIN
  IF v_actor_id IS NULL
    OR NOT private.current_account_is_active()
    OR NOT private.current_user_has_role('student'::public.app_role) THEN
    RAISE EXCEPTION USING ERRCODE = '42501', MESSAGE = 'timed_attempt_assessment_link_forbidden';
  END IF;

  IF p_attempt_id IS NULL
    OR p_assessment_submission_id IS NULL
    OR p_idempotency_key IS NULL THEN
    RAISE EXCEPTION USING ERRCODE = '22023', MESSAGE = 'invalid_timed_attempt_assessment_link';
  END IF;

  -- Serialize reuse of an idempotency key even when requests target different rows.
  PERFORM pg_catalog.pg_advisory_xact_lock(
    pg_catalog.hashtextextended(v_actor_id::text || ':' || p_idempotency_key::text, 0)
  );

  -- Parent-row locks and unique constraints make competing link requests safe.
  SELECT attempt.*
    INTO selected_attempt
  FROM public.attempts AS attempt
  WHERE attempt.id = p_attempt_id
    AND attempt.learner_id = v_actor_id
  FOR UPDATE;

  IF NOT FOUND THEN
    RAISE EXCEPTION USING ERRCODE = 'P0002', MESSAGE = 'attempt_not_found';
  END IF;

  SELECT submission.*
    INTO selected_submission
  FROM public.assessment_submissions AS submission
  WHERE submission.id = p_assessment_submission_id
    AND submission.learner_id = v_actor_id
  FOR UPDATE;

  IF NOT FOUND THEN
    RAISE EXCEPTION USING ERRCODE = 'P0002', MESSAGE = 'assessment_submission_not_found';
  END IF;

  IF selected_attempt.task_version_id IS DISTINCT FROM selected_submission.task_version_id THEN
    RAISE EXCEPTION USING ERRCODE = 'P0001', MESSAGE = 'attempt_task_version_mismatch';
  END IF;

  -- An identical learner/pair/key retry returns the original row. A key cannot
  -- be repurposed for a different pair.
  SELECT link.*
    INTO existing_link
  FROM private.timed_attempt_assessment_links AS link
  WHERE link.learner_id = v_actor_id
    AND link.idempotency_key = p_idempotency_key
  FOR UPDATE;

  IF FOUND THEN
    IF existing_link.attempt_id = p_attempt_id
      AND existing_link.assessment_submission_id = p_assessment_submission_id THEN
      RETURN QUERY SELECT existing_link.id, existing_link.attempt_id,
        existing_link.assessment_submission_id, existing_link.learner_id,
        existing_link.task_version_id, existing_link.linked_at, true;
      RETURN;
    END IF;
    RAISE EXCEPTION USING ERRCODE = 'P0001',
      MESSAGE = 'timed_attempt_assessment_link_idempotency_conflict';
  END IF;

  IF EXISTS (
    SELECT 1
    FROM private.timed_attempt_assessment_links AS link
    WHERE link.attempt_id = p_attempt_id
       OR link.assessment_submission_id = p_assessment_submission_id
  ) THEN
    RAISE EXCEPTION USING ERRCODE = 'P0001',
      MESSAGE = 'timed_attempt_assessment_link_conflict';
  END IF;

  IF selected_attempt.status <> 'submitted' OR selected_attempt.submitted_at IS NULL THEN
    RAISE EXCEPTION USING ERRCODE = 'P0001', MESSAGE = 'attempt_not_submitted';
  END IF;

  IF selected_submission.status = 'withdrawn'
    OR selected_submission.response_mode NOT IN ('typed', 'typed_pdf') THEN
    RAISE EXCEPTION USING ERRCODE = 'P0001', MESSAGE = 'assessment_submission_not_linkable';
  END IF;

  -- Recheck active enrolment, published task, exact mapped published rubric,
  -- response mode and submission eligibility inside the same transaction.
  IF NOT EXISTS (
    SELECT 1
    FROM public.task_versions AS task_version
    JOIN public.course_enrolments AS enrolment
      ON enrolment.pathway_id = task_version.pathway_id
     AND enrolment.learner_id = v_actor_id
     AND enrolment.status = 'active'
    JOIN public.task_rubric_mappings AS mapping
      ON mapping.task_version_id = task_version.id
     AND mapping.rubric_version_id = selected_submission.rubric_version_id
    JOIN public.rubric_versions AS rubric_version
      ON rubric_version.id = mapping.rubric_version_id
     AND rubric_version.release_state = 'published'
    WHERE task_version.id = selected_attempt.task_version_id
      AND task_version.release_state = 'published'
      AND task_version.response_mode = 'typed'
  ) THEN
    RAISE EXCEPTION USING ERRCODE = 'P0001', MESSAGE = 'assessment_submission_not_linkable';
  END IF;

  -- Require the immutable accepted response and the database timer's submitted
  -- event; browser timestamps and client-supplied elapsed values are never used.
  IF NOT EXISTS (
    SELECT 1
    FROM public.submission_versions AS version
    WHERE version.submission_id = selected_submission.id
      AND version.version_number = 1
      AND btrim(version.response_text) <> ''
  ) OR NOT EXISTS (
    SELECT 1
    FROM public.attempt_responses AS response
    WHERE response.attempt_id = selected_attempt.id
      AND btrim(response.response_text) <> ''
  ) OR NOT EXISTS (
    SELECT 1
    FROM private.attempt_timer_sessions AS timer_session
    JOIN private.attempt_timer_events AS timer_event
      ON timer_event.attempt_id = timer_session.attempt_id
     AND timer_event.event_type = 'submitted'
    WHERE timer_session.attempt_id = selected_attempt.id
      AND timer_session.learner_id = v_actor_id
      AND timer_session.task_version_id = selected_attempt.task_version_id
      AND timer_event.actor_id = v_actor_id
  ) THEN
    RAISE EXCEPTION USING ERRCODE = 'P0001', MESSAGE = 'attempt_not_linkable';
  END IF;

  INSERT INTO private.timed_attempt_assessment_links (
    attempt_id, assessment_submission_id, learner_id, task_version_id, idempotency_key
  )
  VALUES (
    selected_attempt.id, selected_submission.id, v_actor_id,
    selected_attempt.task_version_id, p_idempotency_key
  )
  RETURNING * INTO created_link;

  INSERT INTO private.security_audit_events (
    actor_id, action, target_type, target_id, outcome, reason_category
  )
  VALUES (
    v_actor_id, 'student_timed_attempt_assessment_linked',
    'timed_attempt_assessment_link', created_link.id, 'success', 'learner_action'
  );

  RETURN QUERY SELECT created_link.id, created_link.attempt_id,
    created_link.assessment_submission_id, created_link.learner_id,
    created_link.task_version_id, created_link.linked_at, false;
END;
$function$;

ALTER FUNCTION public.link_timed_attempt_assessment_submission(uuid, uuid, uuid)
  OWNER TO postgres;
REVOKE ALL ON FUNCTION public.link_timed_attempt_assessment_submission(uuid, uuid, uuid)
  FROM PUBLIC, anon, service_role;
GRANT EXECUTE ON FUNCTION public.link_timed_attempt_assessment_submission(uuid, uuid, uuid)
  TO authenticated;

COMMENT ON FUNCTION public.link_timed_attempt_assessment_submission(uuid, uuid, uuid) IS
  'Atomically links one learner-owned submitted attempt to one matching eligible human-assessment submission. Enforces same learner/task, published task/rubric, submission/response/timer state, one-to-one uniqueness and exact-pair idempotency.';

-- Allow the trusted Worker audit-ingestion RPC to persist denied/failed outcomes.
CREATE OR REPLACE FUNCTION public.record_worker_audit_outcome(
  p_actor_id uuid,
  p_action text,
  p_target_id uuid,
  p_outcome text,
  p_failure_category text DEFAULT NULL
)
RETURNS boolean
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $function$
DECLARE
  resource_type text;
  success_reason text;
  requires_null_target boolean := false;
  is_protected_read boolean := false;
  event_reason text;
BEGIN
  IF coalesce(auth.jwt() ->> 'role', '') <> 'service_role'
    OR p_actor_id IS NULL
    OR NOT EXISTS (SELECT 1 FROM auth.users AS actor WHERE actor.id = p_actor_id) THEN
    RETURN false;
  END IF;

  CASE p_action
    WHEN 'student_attempt_list_authorized' THEN resource_type := 'attempt_collection'; success_reason := 'student_self'; requires_null_target := true; is_protected_read := true;
    WHEN 'student_attempt_read_authorized' THEN resource_type := 'attempt'; success_reason := 'student_self'; is_protected_read := true;
    WHEN 'grader_attempt_queue_authorized' THEN resource_type := 'attempt_queue'; success_reason := 'assigned_grader_aal2'; requires_null_target := true; is_protected_read := true;
    WHEN 'grader_attempt_read_authorized' THEN resource_type := 'attempt'; success_reason := 'active_grader_assignment_aal2'; is_protected_read := true;
    WHEN 'student_submission_list_authorized' THEN resource_type := 'assessment_submission_collection'; success_reason := 'student_self'; requires_null_target := true; is_protected_read := true;
    WHEN 'student_submission_read_authorized' THEN resource_type := 'assessment_submission'; success_reason := 'student_self'; is_protected_read := true;
    WHEN 'grader_submission_queue_authorized' THEN resource_type := 'assessment_submission_queue'; success_reason := 'assigned_grader_aal2'; requires_null_target := true; is_protected_read := true;
    WHEN 'grader_submission_read_authorized' THEN resource_type := 'assessment_submission'; success_reason := 'active_grader_assignment_aal2'; is_protected_read := true;
    WHEN 'owner_submission_queue_authorized' THEN resource_type := 'assessment_submission_queue'; success_reason := 'owner_aal2'; requires_null_target := true; is_protected_read := true;
    WHEN 'staff_invitations_listed' THEN resource_type := 'staff_invitation_collection'; success_reason := 'owner_aal2'; requires_null_target := true; is_protected_read := true;
    WHEN 'private_qa_records_read' THEN resource_type := 'assessment_version'; success_reason := 'owner_qa_review'; is_protected_read := true;
    WHEN 'owner_role_revocation' THEN resource_type := 'role_assignment_subject';
    WHEN 'owner_attempt_assignment' THEN resource_type := 'attempt';
    WHEN 'owner_submission_assignment' THEN resource_type := 'assessment_submission';
    WHEN 'owner_submission_reassignment' THEN resource_type := 'assessment_submission';
    WHEN 'owner_submission_transition' THEN resource_type := 'assessment_submission';
    WHEN 'owner_private_qa_record_create' THEN resource_type := 'assessment_version';
    WHEN 'grader_assessment_draft_save' THEN resource_type := 'assessment_submission';
    WHEN 'grader_assessment_feedback_publish' THEN resource_type := 'assessment_submission';
    WHEN 'staff_submission_transcript_review' THEN resource_type := 'assessment_submission';
    WHEN 'student_submission_file_upload' THEN resource_type := 'assessment_submission';
    WHEN 'owner_submission_file_cleanup' THEN resource_type := 'submission_file_collection'; requires_null_target := true;
    WHEN 'student_attempt_create' THEN resource_type := 'task_version';
    WHEN 'student_attempt_response_save' THEN resource_type := 'attempt';
    WHEN 'student_attempt_submit' THEN resource_type := 'attempt';
    WHEN 'student_assessment_submission_accept' THEN resource_type := 'task_version';
    WHEN 'staff_invitation_created' THEN resource_type := 'staff_invitation'; requires_null_target := true;
    WHEN 'staff_invitation_revoked' THEN resource_type := 'staff_invitation';
    WHEN 'staff_attempt_timer_adjustment' THEN resource_type := 'attempt';
    WHEN 'student_timed_attempt_assessment_link' THEN resource_type := 'attempt';
    ELSE RETURN false;
  END CASE;

  IF (requires_null_target AND p_target_id IS NOT NULL)
    OR (NOT requires_null_target AND p_target_id IS NULL) THEN
    RETURN false;
  END IF;

  IF p_outcome = 'success' THEN
    IF NOT is_protected_read OR p_failure_category IS NOT NULL THEN RETURN false; END IF;
    event_reason := success_reason;
  ELSIF p_outcome = 'denied' THEN
    IF p_failure_category IS NOT NULL THEN RETURN false; END IF;
    event_reason := 'resource_scope_denied';
  ELSIF p_outcome = 'failed' THEN
    IF is_protected_read THEN
      IF p_failure_category IS NOT NULL THEN RETURN false; END IF;
      event_reason := 'database_read_failed';
    ELSE
      IF p_failure_category IS NULL OR p_failure_category NOT IN (
        'resource_not_found','state_conflict','validation_failed',
        'last_owner_protected','capacity_unavailable','operation_failed'
      ) THEN RETURN false; END IF;
      event_reason := p_failure_category;
    END IF;
  ELSE
    RETURN false;
  END IF;

  INSERT INTO private.security_audit_events (
    actor_id, action, target_type, target_id, outcome, reason_category
  )
  VALUES (
    p_actor_id, p_action, resource_type, p_target_id, p_outcome, event_reason
  );
  RETURN true;
END;
$function$;

ALTER FUNCTION public.record_worker_audit_outcome(uuid,text,uuid,text,text) OWNER TO postgres;
REVOKE ALL ON FUNCTION public.record_worker_audit_outcome(uuid,text,uuid,text,text)
  FROM PUBLIC, anon, authenticated;
GRANT EXECUTE ON FUNCTION public.record_worker_audit_outcome(uuid,text,uuid,text,text)
  TO service_role;
