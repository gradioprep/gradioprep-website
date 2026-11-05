-- Phase 1C-E: complete staff-invitation and private-QA read audit outcomes.
-- Successful operations remain transactionally audited by their own RPCs.
-- This migration adds safe denied/failed paths and tightens the write-audit contract.

-- Phase 1C-E: record protected-read success, denial and query-failure outcomes.
-- Only allowlisted read operations can be recorded. Authorization is rechecked
-- inside PostgreSQL; the Worker cannot turn an unauthorized request into a
-- successful or failed-read event by supplying a different outcome.

CREATE OR REPLACE FUNCTION public.audit_protected_read_outcome(
  p_action text,
  p_target_id uuid,
  p_outcome text
)
RETURNS boolean
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $function$
DECLARE
  actor_id uuid := auth.uid();
  resource_type text;
  success_reason text;
  required_role public.app_role;
  requires_aal2 boolean := false;
  allowed boolean := false;
  event_outcome text;
  event_reason text;
BEGIN
  IF actor_id IS NULL OR p_outcome IS NULL OR p_outcome NOT IN ('success', 'failed') THEN
    RETURN false;
  END IF;

  CASE p_action
    WHEN 'student_attempt_list_authorized' THEN
      resource_type := 'attempt_collection';
      success_reason := 'student_self';
      required_role := 'student'::public.app_role;
      allowed := p_target_id IS NULL;

    WHEN 'student_attempt_read_authorized' THEN
      resource_type := 'attempt';
      success_reason := 'student_self';
      required_role := 'student'::public.app_role;
      allowed := p_target_id IS NOT NULL
        AND EXISTS (
          SELECT 1 FROM public.attempts AS attempt
          WHERE attempt.id = p_target_id AND attempt.learner_id = actor_id
        );

    WHEN 'grader_attempt_queue_authorized' THEN
      resource_type := 'attempt_queue';
      success_reason := 'assigned_grader_aal2';
      required_role := 'grader'::public.app_role;
      requires_aal2 := true;
      allowed := p_target_id IS NULL;

    WHEN 'grader_attempt_read_authorized' THEN
      resource_type := 'attempt';
      success_reason := 'active_grader_assignment_aal2';
      required_role := 'grader'::public.app_role;
      requires_aal2 := true;
      allowed := p_target_id IS NOT NULL
        AND EXISTS (
          SELECT 1
          FROM public.attempts AS attempt
          JOIN public.grader_assignments AS assignment
            ON assignment.attempt_id = attempt.id
          WHERE attempt.id = p_target_id
            AND attempt.status = 'submitted'
            AND assignment.grader_user_id = actor_id
            AND assignment.revoked_at IS NULL
        );

    WHEN 'student_submission_list_authorized' THEN
      resource_type := 'assessment_submission_collection';
      success_reason := 'student_self';
      required_role := 'student'::public.app_role;
      allowed := p_target_id IS NULL;

    WHEN 'student_submission_read_authorized' THEN
      resource_type := 'assessment_submission';
      success_reason := 'student_self';
      required_role := 'student'::public.app_role;
      allowed := p_target_id IS NOT NULL
        AND EXISTS (
          SELECT 1 FROM public.assessment_submissions AS submission
          WHERE submission.id = p_target_id AND submission.learner_id = actor_id
        );

    WHEN 'grader_submission_queue_authorized' THEN
      resource_type := 'assessment_submission_queue';
      success_reason := 'assigned_grader_aal2';
      required_role := 'grader'::public.app_role;
      requires_aal2 := true;
      allowed := p_target_id IS NULL;

    WHEN 'grader_submission_read_authorized' THEN
      resource_type := 'assessment_submission';
      success_reason := 'active_grader_assignment_aal2';
      required_role := 'grader'::public.app_role;
      requires_aal2 := true;
      allowed := p_target_id IS NOT NULL
        AND EXISTS (
          SELECT 1
          FROM public.assessment_submissions AS submission
          JOIN public.submission_grader_assignments AS assignment
            ON assignment.submission_id = submission.id
          WHERE submission.id = p_target_id
            AND submission.status IN ('assigned', 'grading', 'feedback_published')
            AND assignment.grader_user_id = actor_id
            AND assignment.revoked_at IS NULL
        );

    WHEN 'owner_submission_queue_authorized' THEN
      resource_type := 'assessment_submission_queue';
      success_reason := 'owner_aal2';
      required_role := 'owner'::public.app_role;
      requires_aal2 := true;
      allowed := p_target_id IS NULL;

    WHEN 'staff_invitations_listed' THEN
      resource_type := 'staff_invitation_collection';
      success_reason := 'owner_aal2';
      required_role := 'owner'::public.app_role;
      requires_aal2 := true;
      allowed := p_target_id IS NULL;

    WHEN 'private_qa_records_read' THEN
      resource_type := 'assessment_version';
      success_reason := 'owner_qa_review';
      required_role := 'owner'::public.app_role;
      requires_aal2 := true;
      allowed := p_target_id IS NOT NULL
        AND EXISTS (
          SELECT 1
          FROM public.assessment_versions AS version
          WHERE version.id = p_target_id
        );

    ELSE
      -- Never permit arbitrary action names or caller-selected target types.
      RETURN false;
  END CASE;

  allowed := allowed
    AND private.current_account_is_active()
    AND private.current_user_has_role(required_role)
    AND (
      NOT requires_aal2
      OR coalesce(auth.jwt() ->> 'aal', 'aal1') = 'aal2'
    );

  IF allowed THEN
    event_outcome := p_outcome;
    event_reason := CASE
      WHEN p_outcome = 'failed' THEN 'database_read_failed'
      ELSE success_reason
    END;
  ELSE
    event_outcome := 'denied';
    event_reason := CASE
      WHEN NOT private.current_account_is_active() THEN 'inactive_account'
      WHEN NOT private.current_user_has_role(required_role) THEN 'role_required'
      WHEN requires_aal2
        AND coalesce(auth.jwt() ->> 'aal', 'aal1') <> 'aal2'
        THEN 'aal2_required'
      ELSE 'resource_scope_denied'
    END;
  END IF;

  INSERT INTO private.security_audit_events (
    actor_id, action, target_type, target_id, outcome, reason_category
  )
  VALUES (
    actor_id, p_action, resource_type, p_target_id, event_outcome, event_reason
  );

  RETURN allowed;
END;
$function$;

ALTER FUNCTION public.audit_protected_read_outcome(text, uuid, text) OWNER TO postgres;
REVOKE ALL ON FUNCTION public.audit_protected_read_outcome(text, uuid, text)
  FROM PUBLIC, anon, authenticated;
GRANT EXECUTE ON FUNCTION public.audit_protected_read_outcome(text, uuid, text)
  TO authenticated;

COMMENT ON FUNCTION public.audit_protected_read_outcome(text, uuid, text) IS
  'Rechecks allowlisted protected-read authorization and appends success, denied, or authorized query-failed metadata. It never stores learner response, feedback, QA, token, or credential content.';

-- Preserve the narrow legacy RPC used by existing SQL tests/callers. Its only
-- possible successful outcome is success; authorization is rechecked above.
CREATE OR REPLACE FUNCTION public.audit_authorized_protected_read(
  p_action text,
  p_target_id uuid DEFAULT NULL
)
RETURNS boolean
LANGUAGE sql
SECURITY DEFINER
SET search_path = ''
AS $function$
  SELECT public.audit_protected_read_outcome(p_action, p_target_id, 'success');
$function$;

ALTER FUNCTION public.audit_authorized_protected_read(text, uuid) OWNER TO postgres;
REVOKE ALL ON FUNCTION public.audit_authorized_protected_read(text, uuid)
  FROM PUBLIC, anon, authenticated;
GRANT EXECUTE ON FUNCTION public.audit_authorized_protected_read(text, uuid)
  TO authenticated;

-- Phase 1C-E: audit denied/failed learner attempt and submission writes.
-- Existing success events remain transactional inside the corresponding RPCs
-- and triggers. This function only records a failed or denied result after a
-- Worker-side operation has returned, and rechecks the caller/target in SQL.

CREATE OR REPLACE FUNCTION public.audit_privileged_write_outcome(
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
  actor_id uuid := auth.uid();
  required_role public.app_role;
  resource_type text;
  requires_aal2 boolean := true;
  requires_active_assignment boolean := false;
  requires_target_id boolean := true;
  actor_active boolean := false;
  actor_has_role boolean := false;
  assurance_ok boolean := false;
  assignment_ok boolean := true;
  allowed boolean := false;
  event_outcome text;
  event_reason text;
BEGIN
  IF actor_id IS NULL OR p_outcome IS NULL
    OR p_outcome NOT IN ('denied', 'failed') THEN
    RETURN false;
  END IF;

  CASE p_action
    WHEN 'owner_role_revocation' THEN
      resource_type := 'role_assignment_subject';
      required_role := 'owner'::public.app_role;

    WHEN 'owner_attempt_assignment' THEN
      resource_type := 'attempt';
      required_role := 'owner'::public.app_role;

    WHEN 'owner_submission_assignment' THEN
      resource_type := 'assessment_submission';
      required_role := 'owner'::public.app_role;

    WHEN 'owner_submission_reassignment' THEN
      resource_type := 'assessment_submission';
      required_role := 'owner'::public.app_role;

    WHEN 'owner_submission_transition' THEN
      resource_type := 'assessment_submission';
      required_role := 'owner'::public.app_role;

    WHEN 'owner_private_qa_record_create' THEN
      resource_type := 'assessment_version';
      required_role := 'owner'::public.app_role;

    WHEN 'staff_invitation_created' THEN
      resource_type := 'staff_invitation';
      required_role := 'owner'::public.app_role;
      requires_target_id := false;

    WHEN 'staff_invitation_revoked' THEN
      resource_type := 'staff_invitation';
      required_role := 'owner'::public.app_role;

    WHEN 'grader_assessment_draft_save' THEN
      resource_type := 'assessment_submission';
      required_role := 'grader'::public.app_role;
      requires_active_assignment := true;

    WHEN 'grader_assessment_feedback_publish' THEN
      resource_type := 'assessment_submission';
      required_role := 'grader'::public.app_role;
      requires_active_assignment := true;

    WHEN 'student_attempt_create' THEN
      resource_type := 'task_version';
      required_role := 'student'::public.app_role;
      requires_aal2 := false;

    WHEN 'student_attempt_response_save' THEN
      resource_type := 'attempt';
      required_role := 'student'::public.app_role;
      requires_aal2 := false;

    WHEN 'student_attempt_submit' THEN
      resource_type := 'attempt';
      required_role := 'student'::public.app_role;
      requires_aal2 := false;

    WHEN 'student_assessment_submission_accept' THEN
      resource_type := 'task_version';
      required_role := 'student'::public.app_role;
      requires_aal2 := false;

    ELSE
      -- Never expose a generic "write audit" primitive to browser clients.
      RETURN false;
  END CASE;

  actor_active := private.current_account_is_active();
  actor_has_role := required_role IS NULL OR private.current_user_has_role(required_role);
  assurance_ok := coalesce(auth.jwt() ->> 'aal', 'aal1') = 'aal2';

  IF p_target_id IS NOT NULL THEN
    CASE p_action
      WHEN 'grader_assessment_draft_save', 'grader_assessment_feedback_publish' THEN
        SELECT EXISTS (
          SELECT 1
          FROM public.submission_grader_assignments AS assignment
          WHERE assignment.submission_id = p_target_id
            AND assignment.grader_user_id = actor_id
            AND assignment.revoked_at IS NULL
        )
        INTO assignment_ok;

      WHEN 'student_attempt_create' THEN
        assignment_ok := EXISTS (
          SELECT 1
          FROM public.task_versions AS task_version
          JOIN public.course_enrolments AS enrolment
            ON enrolment.pathway_id = task_version.pathway_id
           AND enrolment.learner_id = actor_id
           AND enrolment.status = 'active'
          WHERE task_version.id = p_target_id
            AND task_version.release_state = 'published'
            AND task_version.response_mode = 'typed'
        );

      WHEN 'student_attempt_response_save', 'student_attempt_submit' THEN
        assignment_ok := EXISTS (
          SELECT 1
          FROM public.attempts AS attempt
          WHERE attempt.id = p_target_id
            AND attempt.learner_id = actor_id
        );

      WHEN 'student_assessment_submission_accept' THEN
        assignment_ok := EXISTS (
          SELECT 1
          FROM public.task_versions AS task_version
          JOIN public.course_enrolments AS enrolment
            ON enrolment.pathway_id = task_version.pathway_id
           AND enrolment.learner_id = actor_id
           AND enrolment.status = 'active'
          JOIN public.task_rubric_mappings AS mapping
            ON mapping.task_version_id = task_version.id
          JOIN public.rubric_versions AS rubric_version
            ON rubric_version.id = mapping.rubric_version_id
           AND rubric_version.release_state = 'published'
          WHERE task_version.id = p_target_id
            AND task_version.release_state = 'published'
            AND task_version.response_mode = 'typed'
            AND EXISTS (
              SELECT 1 FROM public.task_version_prompts AS prompt
              WHERE prompt.task_version_id = task_version.id
            )
        );

      WHEN 'staff_invitation_revoked' THEN
        SELECT EXISTS (
          SELECT 1
          FROM private.staff_invitations AS invitation
          WHERE invitation.id = p_target_id
        )
        INTO assignment_ok;

      ELSE
        assignment_ok := true;
    END CASE;
  ELSE
    assignment_ok := NOT requires_target_id;
  END IF;

  allowed := actor_active
    AND actor_has_role
    AND (NOT requires_aal2 OR assurance_ok)
    AND (NOT requires_target_id OR p_target_id IS NOT NULL)
    AND assignment_ok;

  IF allowed AND p_outcome = 'denied' THEN
    -- A browser-callable RPC cannot prove that the Worker denied an otherwise
    -- database-authorised request. Do not append a caller-forged denial.
    RETURN false;
  ELSIF allowed THEN
    IF p_failure_category IS NULL OR p_failure_category NOT IN (
      'resource_not_found',
      'state_conflict',
      'validation_failed',
      'last_owner_protected',
      'capacity_unavailable',
      'operation_failed'
    ) THEN
      RAISE EXCEPTION USING
        ERRCODE = '22023',
        MESSAGE = 'invalid_privileged_write_failure_category';
    END IF;

    event_outcome := 'failed';
    event_reason := p_failure_category;
  ELSE
    event_outcome := 'denied';
    event_reason := CASE
      WHEN NOT actor_active THEN 'inactive_account'
      WHEN NOT actor_has_role THEN 'role_required'
      WHEN requires_aal2 AND NOT assurance_ok THEN 'aal2_required'
      WHEN requires_active_assignment AND NOT assignment_ok THEN 'assignment_required'
      WHEN NOT assignment_ok THEN 'resource_scope_denied'
      ELSE 'resource_scope_denied'
    END;
  END IF;

  INSERT INTO private.security_audit_events (
    actor_id, action, target_type, target_id, outcome, reason_category
  )
  VALUES (
    actor_id, p_action, resource_type, p_target_id, event_outcome, event_reason
  );

  RETURN true;
END;
$function$;

ALTER FUNCTION public.audit_privileged_write_outcome(text, uuid, text, text)
  OWNER TO postgres;
REVOKE ALL ON FUNCTION public.audit_privileged_write_outcome(text, uuid, text, text)
  FROM PUBLIC, anon, authenticated;
GRANT EXECUTE ON FUNCTION public.audit_privileged_write_outcome(text, uuid, text, text)
  TO authenticated;

COMMENT ON FUNCTION public.audit_privileged_write_outcome(text, uuid, text, text) IS
  'Records allowlisted Owner/assigned-Grader and own-learner write denials and post-RPC failures. It cannot manufacture success events or store response/idempotency/feedback/QA payloads.';

CREATE OR REPLACE FUNCTION public.audit_staff_invitation_acceptance_failure(
  p_token_hash text,
  p_failure_category text DEFAULT NULL
)
RETURNS boolean
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $function$
DECLARE
  actor_id uuid := auth.uid();
  invitation_row private.staff_invitations%ROWTYPE;
  account_email text;
  account_email_confirmed_at timestamptz;
  event_outcome text;
  event_reason text;
BEGIN
  IF actor_id IS NULL
    OR p_token_hash IS NULL
    OR p_token_hash !~ '^[0-9a-f]{64}$' THEN
    RETURN false;
  END IF;

  SELECT invitation.*
  INTO invitation_row
  FROM private.staff_invitations AS invitation
  WHERE invitation.token_hash = p_token_hash;

  IF NOT FOUND THEN
    -- Unknown bearer tokens have no attributable row. Do not create an
    -- unscoped audit event or disclose whether the hash exists.
    RETURN false;
  END IF;

  IF NOT private.current_account_is_active() THEN
    event_outcome := 'denied';
    event_reason := 'inactive_account';
  ELSIF coalesce(auth.jwt() ->> 'aal', 'aal1') <> 'aal2' THEN
    event_outcome := 'denied';
    event_reason := 'aal2_required';
  ELSE
    SELECT auth_user.email, auth_user.email_confirmed_at
    INTO account_email, account_email_confirmed_at
    FROM auth.users AS auth_user
    WHERE auth_user.id = actor_id;

    IF account_email IS NULL OR account_email_confirmed_at IS NULL THEN
      event_outcome := 'denied';
      event_reason := 'email_unverified';
    ELSIF pg_catalog.lower(account_email) <> invitation_row.invited_email THEN
      event_outcome := 'denied';
      event_reason := 'email_mismatch';
    ELSIF invitation_row.revoked_at IS NOT NULL
      OR invitation_row.accepted_at IS NOT NULL
      OR invitation_row.expires_at <= pg_catalog.now() THEN
      event_outcome := 'failed';
      event_reason := 'state_conflict';
    ELSE
      IF p_failure_category IS NULL OR p_failure_category NOT IN (
        'validation_failed', 'state_conflict', 'operation_failed'
      ) THEN
        event_reason := 'operation_failed';
      ELSE
        event_reason := p_failure_category;
      END IF;
      event_outcome := 'failed';
    END IF;
  END IF;

  INSERT INTO private.security_audit_events (
    actor_id, action, target_type, target_id, outcome, reason_category
  )
  VALUES (
    actor_id, 'staff_invitation_accepted', 'staff_invitation',
    invitation_row.id, event_outcome, event_reason
  );

  RETURN true;
END;
$function$;

ALTER FUNCTION public.audit_staff_invitation_acceptance_failure(text, text)
  OWNER TO postgres;
REVOKE ALL ON FUNCTION public.audit_staff_invitation_acceptance_failure(text, text)
  FROM PUBLIC, anon, authenticated;
GRANT EXECUTE ON FUNCTION public.audit_staff_invitation_acceptance_failure(text, text)
  TO authenticated;

COMMENT ON FUNCTION public.audit_staff_invitation_acceptance_failure(text, text) IS
  'Records an invitation-acceptance denial/failure only after resolving its SHA-256 hash to a private invitation row and deriving actor/email/MFA/state outcome; never stores token hash or email.';
