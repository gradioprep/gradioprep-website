-- Phase 1E: controlled account closure and retention schedule.
-- This migration closes account access and inventories retained records.
-- It deliberately does not physically erase learner content. The retention
-- classes below follow the Founder-approved Phase 0 12-/24-month schedule.
-- R2 backup rows are metadata-only and remain unused until the regional,
-- transfer, encryption and key-custody approval gate passes.

ALTER TABLE private.account_deletion_requests
  ADD COLUMN closure_executed_by uuid,
  ADD COLUMN closure_executed_at timestamptz,
  ADD COLUMN retention_items_created integer NOT NULL DEFAULT 0
    CHECK (retention_items_created >= 0),
  ADD CONSTRAINT account_deletion_closure_evidence_complete
    CHECK (
      (closure_executed_at IS NULL AND closure_executed_by IS NULL
       AND retention_items_created = 0)
      OR
      (closure_executed_at IS NOT NULL AND closure_executed_by IS NOT NULL)
    ),
  ADD CONSTRAINT account_deletion_execution_status_matches_evidence
    CHECK ((status IN ('executing', 'completed')) = (closure_executed_at IS NOT NULL));

CREATE TABLE private.retention_items (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  deletion_request_id uuid NOT NULL
    REFERENCES private.account_deletion_requests(id) ON DELETE RESTRICT,
  subject_user_id uuid REFERENCES auth.users(id) ON DELETE SET NULL,
  source_schema text NOT NULL CHECK (source_schema IN ('public', 'private')),
  source_table text NOT NULL CHECK (source_table IN (
    'attempts', 'attempt_responses', 'assessment_submissions',
    'submission_versions', 'submission_files', 'assessment_versions',
    'criterion_results', 'assessment_drafts', 'assessment_draft_history',
    'private_qa_records'
  )),
  source_record_id uuid NOT NULL,
  retention_class text NOT NULL CHECK (retention_class IN (
    'source_content_12m', 'feedback_history_24m', 'timer_event_12m'
  )),
  source_end_event_at timestamptz NOT NULL,
  eligible_after timestamptz NOT NULL,
  state text NOT NULL DEFAULT 'retained'
    CHECK (state IN ('retained', 'deletion_due', 'claimed', 'deleted')),
  claimed_at timestamptz,
  deleted_at timestamptz,
  created_at timestamptz NOT NULL DEFAULT clock_timestamp(),
  UNIQUE (deletion_request_id, source_schema, source_table, source_record_id),
  CHECK (
    (state = 'claimed') = (claimed_at IS NOT NULL)
    OR (state = 'deleted' AND claimed_at IS NOT NULL)
  ),
  CHECK ((state = 'deleted') = (deleted_at IS NOT NULL)),
  CHECK (
    eligible_after = source_end_event_at +
      CASE retention_class
        WHEN 'feedback_history_24m' THEN interval '24 months'
        ELSE interval '12 months'
      END
  )
);

CREATE INDEX retention_items_request_eligibility_idx
  ON private.retention_items (deletion_request_id, eligible_after, source_table);
CREATE INDEX retention_items_due_idx
  ON private.retention_items (eligible_after, id)
  WHERE state IN ('retained', 'deletion_due');

ALTER TABLE private.retention_items ENABLE ROW LEVEL SECURITY;
REVOKE ALL ON private.retention_items FROM PUBLIC, anon, authenticated, service_role;

CREATE TABLE private.retention_backup_objects (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  retention_item_id uuid NOT NULL
    REFERENCES private.retention_items(id) ON DELETE RESTRICT,
  backup_provider text NOT NULL CHECK (backup_provider = 'cloudflare_r2'),
  backup_object_ref text NOT NULL
    CHECK (char_length(btrim(backup_object_ref)) BETWEEN 1 AND 300),
  source_deleted_at timestamptz,
  expires_at timestamptz,
  state text NOT NULL DEFAULT 'retained'
    CHECK (state IN ('retained', 'expiry_due', 'expired')),
  expired_at timestamptz,
  created_at timestamptz NOT NULL DEFAULT clock_timestamp(),
  UNIQUE (backup_provider, backup_object_ref),
  CHECK (
    (source_deleted_at IS NULL AND expires_at IS NULL AND expired_at IS NULL AND state = 'retained')
    OR
    (source_deleted_at IS NOT NULL AND expires_at = source_deleted_at + interval '30 days'
      AND ((state = 'expiry_due' AND expired_at IS NULL)
        OR (state = 'expired' AND expired_at IS NOT NULL AND expired_at >= expires_at)))
  )
);

CREATE INDEX retention_backup_expiry_idx
  ON private.retention_backup_objects (expires_at, id)
  WHERE state = 'expiry_due';

ALTER TABLE private.retention_backup_objects ENABLE ROW LEVEL SECURITY;
REVOKE ALL ON private.retention_backup_objects FROM PUBLIC, anon, authenticated, service_role;

CREATE OR REPLACE FUNCTION private.protect_account_deletion_request()
RETURNS trigger
LANGUAGE plpgsql
SET search_path = ''
AS $function$
BEGIN
  IF TG_OP = 'DELETE' THEN
    RAISE EXCEPTION USING ERRCODE = '42501', MESSAGE = 'account_deletion_request_delete_requires_retention_workflow';
  END IF;

  IF ROW(
    NEW.id, NEW.request_scope, NEW.request_reason_category,
    NEW.identity_verification_method, NEW.identity_verified_at,
    NEW.requester_email_confirmed_at, NEW.requested_at, NEW.response_due_at
  ) IS DISTINCT FROM ROW(
    OLD.id, OLD.request_scope, OLD.request_reason_category,
    OLD.identity_verification_method, OLD.identity_verified_at,
    OLD.requester_email_confirmed_at, OLD.requested_at, OLD.response_due_at
  )
  OR (NEW.subject_user_id IS DISTINCT FROM OLD.subject_user_id AND NEW.subject_user_id IS NOT NULL) THEN
    RAISE EXCEPTION USING ERRCODE = '42501', MESSAGE = 'account_deletion_request_identity_immutable';
  END IF;

  IF NEW.status IS DISTINCT FROM OLD.status AND NOT (
    (OLD.status = 'under_review' AND NEW.status IN ('on_hold', 'approved', 'rejected'))
    OR (OLD.status = 'approved' AND NEW.status IN ('on_hold', 'executing'))
    OR (OLD.status = 'on_hold' AND NEW.status IN ('under_review', 'approved'))
    OR (OLD.status = 'executing' AND NEW.status = 'completed')
  ) THEN
    RAISE EXCEPTION USING ERRCODE = '42501', MESSAGE = 'account_deletion_request_invalid_transition';
  END IF;

  IF OLD.reviewed_at IS NOT NULL AND ROW(
    NEW.reviewed_by, NEW.reviewed_at, NEW.decision_reason_category
  ) IS DISTINCT FROM ROW(
    OLD.reviewed_by, OLD.reviewed_at, OLD.decision_reason_category
  ) THEN
    RAISE EXCEPTION USING ERRCODE = '42501', MESSAGE = 'account_deletion_review_evidence_immutable';
  END IF;

  IF OLD.closure_executed_at IS NOT NULL AND ROW(
    NEW.closure_executed_by, NEW.closure_executed_at, NEW.retention_items_created
  ) IS DISTINCT FROM ROW(
    OLD.closure_executed_by, OLD.closure_executed_at, OLD.retention_items_created
  ) THEN
    RAISE EXCEPTION USING ERRCODE = '42501', MESSAGE = 'account_deletion_closure_evidence_immutable';
  END IF;

  IF NEW.closure_executed_at IS NOT NULL AND OLD.closure_executed_at IS NULL
    AND (NEW.status <> 'executing' OR NEW.closure_executed_by IS NULL) THEN
    RAISE EXCEPTION USING ERRCODE = '42501', MESSAGE = 'account_deletion_closure_evidence_invalid';
  END IF;

  IF OLD.completed_at IS NOT NULL AND NEW.completed_at IS DISTINCT FROM OLD.completed_at THEN
    RAISE EXCEPTION USING ERRCODE = '42501', MESSAGE = 'account_deletion_completion_evidence_immutable';
  END IF;

  RETURN NEW;
END;
$function$;

CREATE OR REPLACE FUNCTION private.protect_retention_item()
RETURNS trigger
LANGUAGE plpgsql
SET search_path = ''
AS $function$
BEGIN
  IF TG_OP = 'DELETE' THEN
    RAISE EXCEPTION USING ERRCODE = '42501', MESSAGE = 'retention_item_delete_forbidden';
  END IF;

  IF ROW(
    NEW.id, NEW.deletion_request_id, NEW.subject_user_id, NEW.source_schema,
    NEW.source_table, NEW.source_record_id, NEW.retention_class,
    NEW.source_end_event_at, NEW.eligible_after, NEW.created_at
  ) IS DISTINCT FROM ROW(
    OLD.id, OLD.deletion_request_id, OLD.subject_user_id, OLD.source_schema,
    OLD.source_table, OLD.source_record_id, OLD.retention_class,
    OLD.source_end_event_at, OLD.eligible_after, OLD.created_at
  )
  OR (NEW.subject_user_id IS DISTINCT FROM OLD.subject_user_id AND NEW.subject_user_id IS NOT NULL) THEN
    RAISE EXCEPTION USING ERRCODE = '42501', MESSAGE = 'retention_item_identity_immutable';
  END IF;

  IF OLD.state = 'deleted' THEN
    RAISE EXCEPTION USING ERRCODE = '42501', MESSAGE = 'retention_item_deletion_evidence_immutable';
  END IF;

  IF NEW.state IS DISTINCT FROM OLD.state AND NOT (
    (OLD.state = 'retained' AND NEW.state IN ('deletion_due', 'claimed'))
    OR (OLD.state = 'deletion_due' AND NEW.state IN ('claimed', 'retained'))
    OR (OLD.state = 'claimed' AND NEW.state IN ('retained', 'deleted'))
  ) THEN
    RAISE EXCEPTION USING ERRCODE = '42501', MESSAGE = 'retention_item_invalid_transition';
  END IF;

  RETURN NEW;
END;
$function$;

CREATE TRIGGER retention_item_integrity
  BEFORE UPDATE OR DELETE ON private.retention_items
  FOR EACH ROW EXECUTE FUNCTION private.protect_retention_item();

CREATE OR REPLACE FUNCTION private.protect_retention_backup_object()
RETURNS trigger
LANGUAGE plpgsql
SET search_path = ''
AS $function$
BEGIN
  IF TG_OP = 'DELETE' THEN
    RAISE EXCEPTION USING ERRCODE = '42501', MESSAGE = 'retention_backup_evidence_delete_forbidden';
  END IF;

  IF ROW(NEW.id, NEW.retention_item_id, NEW.backup_provider,
         NEW.backup_object_ref, NEW.created_at)
     IS DISTINCT FROM
     ROW(OLD.id, OLD.retention_item_id, OLD.backup_provider,
         OLD.backup_object_ref, OLD.created_at) THEN
    RAISE EXCEPTION USING ERRCODE = '42501', MESSAGE = 'retention_backup_identity_immutable';
  END IF;

  IF OLD.state = 'expired' THEN
    RAISE EXCEPTION USING ERRCODE = '42501', MESSAGE = 'retention_backup_expiry_evidence_immutable';
  END IF;

  IF NEW.state IS DISTINCT FROM OLD.state AND NOT (
    (
      OLD.state = 'retained' AND NEW.state = 'expiry_due'
      AND OLD.source_deleted_at IS NULL
      AND NEW.source_deleted_at IS NOT NULL
      AND NEW.expires_at = NEW.source_deleted_at + interval '30 days'
      AND NEW.expired_at IS NULL
    )
    OR
    (
      OLD.state = 'expiry_due' AND NEW.state = 'expired'
      AND OLD.expires_at <= clock_timestamp()
      AND NEW.expired_at IS NOT NULL
      AND NEW.expired_at >= OLD.expires_at
    )
  ) THEN
    RAISE EXCEPTION USING ERRCODE = '42501', MESSAGE = 'retention_backup_invalid_transition';
  END IF;

  RETURN NEW;
END;
$function$;

CREATE TRIGGER retention_backup_integrity
  BEFORE UPDATE OR DELETE ON private.retention_backup_objects
  FOR EACH ROW EXECUTE FUNCTION private.protect_retention_backup_object();

CREATE OR REPLACE FUNCTION private.propagate_retention_backup_expiry()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $function$
BEGIN
  IF OLD.state <> 'deleted' AND NEW.state = 'deleted' THEN
    UPDATE private.retention_backup_objects
    SET source_deleted_at = NEW.deleted_at,
        expires_at = NEW.deleted_at + interval '30 days',
        state = 'expiry_due'
    WHERE retention_item_id = NEW.id
      AND state = 'retained';
  END IF;
  RETURN NEW;
END;
$function$;

CREATE TRIGGER retention_item_backup_expiry
  AFTER UPDATE OF state ON private.retention_items
  FOR EACH ROW EXECUTE FUNCTION private.propagate_retention_backup_expiry();

CREATE OR REPLACE FUNCTION private.prepare_late_retention_backup_expiry()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $function$
DECLARE
  source_deleted timestamptz;
BEGIN
  SELECT item.deleted_at INTO source_deleted
  FROM private.retention_items AS item
  WHERE item.id = NEW.retention_item_id AND item.state = 'deleted';

  IF source_deleted IS NOT NULL THEN
    NEW.source_deleted_at := source_deleted;
    NEW.expires_at := source_deleted + interval '30 days';
    NEW.state := 'expiry_due';
  END IF;
  RETURN NEW;
END;
$function$;

CREATE TRIGGER retention_backup_late_insert_expiry
  BEFORE INSERT ON private.retention_backup_objects
  FOR EACH ROW EXECUTE FUNCTION private.prepare_late_retention_backup_expiry();

-- Recreate the Owner queue with the account-closure checkpoint fields.
DROP FUNCTION public.list_account_deletion_requests();

CREATE FUNCTION public.list_account_deletion_requests()
RETURNS TABLE(
  request_id uuid,
  subject_user_id uuid,
  request_reason_category text,
  request_status text,
  requested_at timestamptz,
  response_due_at timestamptz,
  identity_verified_at timestamptz,
  identity_verification_method text,
  reviewed_by uuid,
  reviewed_at timestamptz,
  decision_reason_category text,
  completed_at timestamptz,
  closure_executed_at timestamptz,
  retention_items_created integer,
  has_active_legal_hold boolean,
  active_legal_hold_authority_category text,
  active_legal_hold_authority_reference text,
  active_legal_hold_reason_summary text,
  active_legal_hold_review_due_at timestamptz
)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $function$
DECLARE
  actor_id uuid := auth.uid();
BEGIN
  IF coalesce(auth.jwt() ->> 'role', '') <> 'authenticated'
    OR actor_id IS NULL
    OR NOT private.current_account_is_active()
    OR NOT private.current_user_has_role('owner'::public.app_role)
    OR coalesce(auth.jwt() ->> 'aal', 'aal1') <> 'aal2' THEN
    RAISE EXCEPTION USING ERRCODE = '42501', MESSAGE = 'account_deletion_owner_aal2_required';
  END IF;

  INSERT INTO private.security_audit_events (
    actor_id, action, target_type, target_id, outcome, reason_category
  )
  VALUES (
    actor_id, 'account_deletion_requests_listed',
    'account_deletion_request_collection', NULL, 'success', 'owner_aal2'
  );

  RETURN QUERY
  SELECT request.id, request.subject_user_id,
    request.request_reason_category, request.status, request.requested_at,
    request.response_due_at, request.identity_verified_at,
    request.identity_verification_method, request.reviewed_by,
    request.reviewed_at, request.decision_reason_category,
    request.completed_at, request.closure_executed_at,
    request.retention_items_created,
    EXISTS (
      SELECT 1 FROM private.account_deletion_legal_holds AS legal_hold
      WHERE legal_hold.request_id = request.id AND legal_hold.released_at IS NULL
    ),
    (
      SELECT legal_hold.authority_category
      FROM private.account_deletion_legal_holds AS legal_hold
      WHERE legal_hold.request_id = request.id AND legal_hold.released_at IS NULL
    ),
    (
      SELECT legal_hold.authority_reference
      FROM private.account_deletion_legal_holds AS legal_hold
      WHERE legal_hold.request_id = request.id AND legal_hold.released_at IS NULL
    ),
    (
      SELECT legal_hold.reason_summary
      FROM private.account_deletion_legal_holds AS legal_hold
      WHERE legal_hold.request_id = request.id AND legal_hold.released_at IS NULL
    ),
    (
      SELECT legal_hold.review_due_at
      FROM private.account_deletion_legal_holds AS legal_hold
      WHERE legal_hold.request_id = request.id AND legal_hold.released_at IS NULL
    )
  FROM private.account_deletion_requests AS request
  ORDER BY request.requested_at ASC, request.id ASC;
END;
$function$;
CREATE OR REPLACE FUNCTION public.close_account_for_deletion(p_request_id uuid)
RETURNS TABLE(
  request_id uuid,
  account_closed_at timestamptz,
  retention_items_created integer,
  is_replay boolean
)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $function$
DECLARE
  actor_id uuid := auth.uid();
  target_user_id uuid;
  selected_request private.account_deletion_requests%ROWTYPE;
  selected_submission record;
  close_time timestamptz;
  item_count integer := 0;
  affected integer := 0;
  active_owner_count integer := 0;
BEGIN
  IF coalesce(auth.jwt() ->> 'role', '') <> 'authenticated'
    OR actor_id IS NULL
    OR NOT private.current_account_is_active()
    OR NOT private.current_user_has_role('owner'::public.app_role)
    OR coalesce(auth.jwt() ->> 'aal', 'aal1') <> 'aal2' THEN
    RAISE EXCEPTION USING ERRCODE = '42501', MESSAGE = 'account_deletion_owner_aal2_required';
  END IF;

  IF p_request_id IS NULL THEN
    RAISE EXCEPTION USING ERRCODE = '22023', MESSAGE = 'invalid_account_deletion_request';
  END IF;

  SELECT request.* INTO selected_request
  FROM private.account_deletion_requests AS request
  WHERE request.id = p_request_id
  FOR UPDATE;

  IF NOT FOUND THEN
    RAISE EXCEPTION USING ERRCODE = 'P0002', MESSAGE = 'account_deletion_request_not_found';
  END IF;

  IF selected_request.status IN ('executing', 'completed')
    AND selected_request.closure_executed_at IS NOT NULL THEN
    RETURN QUERY SELECT selected_request.id, selected_request.closure_executed_at,
      selected_request.retention_items_created, true;
    RETURN;
  END IF;

  IF selected_request.status <> 'approved' OR selected_request.subject_user_id IS NULL THEN
    RAISE EXCEPTION USING ERRCODE = 'P0001', MESSAGE = 'account_deletion_request_not_approved';
  END IF;

  IF EXISTS (
    SELECT 1 FROM private.account_deletion_legal_holds AS legal_hold
    WHERE legal_hold.request_id = p_request_id AND legal_hold.released_at IS NULL
  ) THEN
    RAISE EXCEPTION USING ERRCODE = 'P0001', MESSAGE = 'account_deletion_request_on_legal_hold';
  END IF;

  target_user_id := selected_request.subject_user_id;
  IF target_user_id = actor_id THEN
    RAISE EXCEPTION USING ERRCODE = '42501', MESSAGE = 'account_deletion_independent_owner_required';
  END IF;

  PERFORM pg_catalog.pg_advisory_xact_lock(7123674591123::bigint);

  PERFORM 1 FROM public.profiles AS profile
  WHERE profile.user_id = target_user_id
    AND profile.account_status = 'active'
  FOR UPDATE;
  IF NOT FOUND THEN
    RAISE EXCEPTION USING ERRCODE = 'P0001', MESSAGE = 'account_deletion_subject_not_active';
  END IF;

  IF EXISTS (
    SELECT 1 FROM public.role_assignments AS role
    WHERE role.user_id = target_user_id
      AND role.role = 'owner'::public.app_role
      AND role.revoked_at IS NULL
  ) THEN
    SELECT count(*)::integer INTO active_owner_count
    FROM public.role_assignments AS role
    JOIN public.profiles AS profile ON profile.user_id = role.user_id
    WHERE role.role = 'owner'::public.app_role
      AND role.revoked_at IS NULL
      AND profile.account_status = 'active';

    IF active_owner_count <= 1 THEN
      RAISE EXCEPTION USING ERRCODE = '23514', MESSAGE = 'last_active_owner_protected';
    END IF;
  END IF;

  close_time := clock_timestamp();

  -- Stop all accepted human-assessment work safely. The existing lifecycle RPC
  -- revokes grader assignment, archives private drafts and records each change.
  FOR selected_submission IN
    SELECT submission.id, submission.status
    FROM public.assessment_submissions AS submission
    WHERE submission.learner_id = target_user_id
      AND submission.status IN ('queued', 'assigned', 'grading', 'feedback_published')
    ORDER BY submission.accepted_at, submission.id
    FOR UPDATE
  LOOP
    IF selected_submission.status = 'feedback_published' THEN
      PERFORM public.transition_assessment_submission(
        selected_submission.id, 'closed', 'account_deletion_closure'
      );
    ELSE
      PERFORM public.transition_assessment_submission(
        selected_submission.id, 'withdrawn', 'account_deletion_closure'
      );
    END IF;
  END LOOP;

  UPDATE public.attempts
  SET status = 'withdrawn',
      updated_at = close_time
  WHERE learner_id = target_user_id
    AND status = 'in_progress';

  UPDATE public.guardian_learner_links
  SET status = 'revoked',
      consent_verified_at = NULL,
      can_view_profile = false,
      can_view_learning_progress = false,
      can_view_submissions = false,
      updated_at = close_time
  WHERE (guardian_id = target_user_id OR learner_id = target_user_id)
    AND status IN ('pending', 'verified');

  UPDATE public.course_enrolments
  SET status = 'withdrawn',
      ends_at = greatest(starts_at, close_time)
  WHERE learner_id = target_user_id
    AND status IN ('active', 'paused');

  UPDATE public.course_enrolments
  SET ends_at = greatest(starts_at, close_time)
  WHERE learner_id = target_user_id
    AND status IN ('completed', 'withdrawn')
    AND ends_at IS NULL;

  -- Role revocation invokes the existing grader-assignment invalidation trigger.
  UPDATE public.role_assignments
  SET revoked_at = close_time,
      revoked_by = actor_id,
      reason = 'account_deletion_closure'
  WHERE user_id = target_user_id
    AND revoked_at IS NULL;

  -- Close and de-identify the Auth identity while retaining the UUID needed
  -- to link protected academic records through their approved retention period.
  DELETE FROM auth.sessions WHERE user_id = target_user_id;
  DELETE FROM auth.identities WHERE user_id = target_user_id;
  DELETE FROM auth.mfa_factors WHERE user_id = target_user_id;

  UPDATE auth.users
  SET email = 'closed+' || replace(target_user_id::text, '-', '') || '@invalid.invalid',
      encrypted_password = '',
      email_confirmed_at = NULL,
      phone = NULL,
      phone_confirmed_at = NULL,
      confirmation_token = '',
      recovery_token = '',
      email_change_token_current = '',
      email_change_token_new = '',
      email_change = '',
      phone_change_token = '',
      phone_change = '',
      reauthentication_token = '',
      banned_until = 'infinity'::timestamptz,
      raw_app_meta_data = '{}'::jsonb,
      raw_user_meta_data = '{}'::jsonb,
      updated_at = close_time
  WHERE id = target_user_id;

  UPDATE public.profiles
  SET account_status = 'closed',
      display_name = 'Closed account',
      updated_at = close_time
  WHERE user_id = target_user_id;

  -- Typed attempt responses and accepted PDFs follow the source-content
  -- 12-month rule from the recorded course-end/administrative-closure event.
  INSERT INTO private.retention_items (
    deletion_request_id, subject_user_id, source_schema, source_table,
    source_record_id, retention_class, source_end_event_at, eligible_after
  )
  SELECT p_request_id, target_user_id, 'public', 'attempt_responses',
    response.id, 'source_content_12m',
    greatest(coalesce(enrolment.ends_at, close_time), response.created_at),
    greatest(coalesce(enrolment.ends_at, close_time), response.created_at) + interval '12 months'
  FROM public.attempt_responses AS response
  JOIN public.attempts AS attempt ON attempt.id = response.attempt_id
  JOIN public.task_versions AS task ON task.id = attempt.task_version_id
  LEFT JOIN public.course_enrolments AS enrolment
    ON enrolment.learner_id = target_user_id AND enrolment.pathway_id = task.pathway_id
  WHERE attempt.learner_id = target_user_id
  ON CONFLICT DO NOTHING;
  GET DIAGNOSTICS affected = ROW_COUNT; item_count := item_count + affected;

  INSERT INTO private.retention_items (
    deletion_request_id, subject_user_id, source_schema, source_table,
    source_record_id, retention_class, source_end_event_at, eligible_after
  )
  SELECT p_request_id, target_user_id, 'public', 'assessment_submissions',
    submission.id, 'source_content_12m',
    greatest(coalesce(enrolment.ends_at, close_time), submission.accepted_at),
    greatest(coalesce(enrolment.ends_at, close_time), submission.accepted_at) + interval '12 months'
  FROM public.assessment_submissions AS submission
  JOIN public.task_versions AS task ON task.id = submission.task_version_id
  LEFT JOIN public.course_enrolments AS enrolment
    ON enrolment.learner_id = target_user_id AND enrolment.pathway_id = task.pathway_id
  WHERE submission.learner_id = target_user_id
  ON CONFLICT DO NOTHING;
  GET DIAGNOSTICS affected = ROW_COUNT; item_count := item_count + affected;

  INSERT INTO private.retention_items (
    deletion_request_id, subject_user_id, source_schema, source_table,
    source_record_id, retention_class, source_end_event_at, eligible_after
  )
  SELECT p_request_id, target_user_id, 'public', 'submission_versions',
    version.id, 'source_content_12m',
    greatest(coalesce(enrolment.ends_at, close_time), version.created_at),
    greatest(coalesce(enrolment.ends_at, close_time), version.created_at) + interval '12 months'
  FROM public.submission_versions AS version
  JOIN public.assessment_submissions AS submission ON submission.id = version.submission_id
  JOIN public.task_versions AS task ON task.id = submission.task_version_id
  LEFT JOIN public.course_enrolments AS enrolment
    ON enrolment.learner_id = target_user_id AND enrolment.pathway_id = task.pathway_id
  WHERE submission.learner_id = target_user_id
  ON CONFLICT DO NOTHING;
  GET DIAGNOSTICS affected = ROW_COUNT; item_count := item_count + affected;

  INSERT INTO private.retention_items (
    deletion_request_id, subject_user_id, source_schema, source_table,
    source_record_id, retention_class, source_end_event_at, eligible_after
  )
  SELECT p_request_id, target_user_id, 'private', 'submission_files',
    file_record.id, 'source_content_12m',
    greatest(coalesce(enrolment.ends_at, close_time), file_record.accepted_at),
    greatest(coalesce(enrolment.ends_at, close_time), file_record.accepted_at) + interval '12 months'
  FROM private.submission_files AS file_record
  JOIN public.assessment_submissions AS submission ON submission.id = file_record.submission_id
  JOIN public.task_versions AS task ON task.id = submission.task_version_id
  LEFT JOIN public.course_enrolments AS enrolment
    ON enrolment.learner_id = target_user_id AND enrolment.pathway_id = task.pathway_id
  WHERE file_record.learner_id = target_user_id
    AND file_record.upload_state = 'accepted'
  ON CONFLICT DO NOTHING;
  GET DIAGNOSTICS affected = ROW_COUNT; item_count := item_count + affected;

  -- Timer/attempt event records have their own 12-month clock from the attempt.
  INSERT INTO private.retention_items (
    deletion_request_id, subject_user_id, source_schema, source_table,
    source_record_id, retention_class, source_end_event_at, eligible_after
  )
  SELECT p_request_id, target_user_id, 'public', 'attempts',
    attempt.id, 'timer_event_12m',
    greatest(coalesce(attempt.submitted_at, attempt.started_at), attempt.created_at),
    greatest(coalesce(attempt.submitted_at, attempt.started_at), attempt.created_at) + interval '12 months'
  FROM public.attempts AS attempt
  WHERE attempt.learner_id = target_user_id
  ON CONFLICT DO NOTHING;
  GET DIAGNOSTICS affected = ROW_COUNT; item_count := item_count + affected;

  -- Published feedback, rubric outcomes, draft/version history and private QA
  -- remain for 24 months after the formal course-end/closure event.
  INSERT INTO private.retention_items (
    deletion_request_id, subject_user_id, source_schema, source_table,
    source_record_id, retention_class, source_end_event_at, eligible_after
  )
  SELECT p_request_id, target_user_id, 'public', 'assessment_versions',
    version.id, 'feedback_history_24m',
    greatest(coalesce(enrolment.ends_at, close_time), version.published_at),
    greatest(coalesce(enrolment.ends_at, close_time), version.published_at) + interval '24 months'
  FROM public.assessment_versions AS version
  JOIN public.assessment_submissions AS submission ON submission.id = version.submission_id
  JOIN public.task_versions AS task ON task.id = submission.task_version_id
  LEFT JOIN public.course_enrolments AS enrolment
    ON enrolment.learner_id = target_user_id AND enrolment.pathway_id = task.pathway_id
  WHERE submission.learner_id = target_user_id
  ON CONFLICT DO NOTHING;
  GET DIAGNOSTICS affected = ROW_COUNT; item_count := item_count + affected;

  INSERT INTO private.retention_items (
    deletion_request_id, subject_user_id, source_schema, source_table,
    source_record_id, retention_class, source_end_event_at, eligible_after
  )
  SELECT p_request_id, target_user_id, 'public', 'criterion_results',
    result.id, 'feedback_history_24m',
    greatest(coalesce(enrolment.ends_at, close_time), result.created_at),
    greatest(coalesce(enrolment.ends_at, close_time), result.created_at) + interval '24 months'
  FROM public.criterion_results AS result
  JOIN public.assessment_versions AS version ON version.id = result.assessment_version_id
  JOIN public.assessment_submissions AS submission ON submission.id = version.submission_id
  JOIN public.task_versions AS task ON task.id = submission.task_version_id
  LEFT JOIN public.course_enrolments AS enrolment
    ON enrolment.learner_id = target_user_id AND enrolment.pathway_id = task.pathway_id
  WHERE submission.learner_id = target_user_id
  ON CONFLICT DO NOTHING;
  GET DIAGNOSTICS affected = ROW_COUNT; item_count := item_count + affected;

  INSERT INTO private.retention_items (
    deletion_request_id, subject_user_id, source_schema, source_table,
    source_record_id, retention_class, source_end_event_at, eligible_after
  )
  SELECT p_request_id, target_user_id, 'private', 'assessment_drafts',
    draft.submission_id, 'feedback_history_24m',
    greatest(coalesce(enrolment.ends_at, close_time), draft.updated_at),
    greatest(coalesce(enrolment.ends_at, close_time), draft.updated_at) + interval '24 months'
  FROM private.assessment_drafts AS draft
  JOIN public.assessment_submissions AS submission ON submission.id = draft.submission_id
  JOIN public.task_versions AS task ON task.id = submission.task_version_id
  LEFT JOIN public.course_enrolments AS enrolment
    ON enrolment.learner_id = target_user_id AND enrolment.pathway_id = task.pathway_id
  WHERE submission.learner_id = target_user_id
  ON CONFLICT DO NOTHING;
  GET DIAGNOSTICS affected = ROW_COUNT; item_count := item_count + affected;

  INSERT INTO private.retention_items (
    deletion_request_id, subject_user_id, source_schema, source_table,
    source_record_id, retention_class, source_end_event_at, eligible_after
  )
  SELECT p_request_id, target_user_id, 'private', 'assessment_draft_history',
    history.id, 'feedback_history_24m',
    greatest(coalesce(enrolment.ends_at, close_time), history.archived_at),
    greatest(coalesce(enrolment.ends_at, close_time), history.archived_at) + interval '24 months'
  FROM private.assessment_draft_history AS history
  JOIN public.assessment_submissions AS submission ON submission.id = history.submission_id
  JOIN public.task_versions AS task ON task.id = submission.task_version_id
  LEFT JOIN public.course_enrolments AS enrolment
    ON enrolment.learner_id = target_user_id AND enrolment.pathway_id = task.pathway_id
  WHERE submission.learner_id = target_user_id
  ON CONFLICT DO NOTHING;
  GET DIAGNOSTICS affected = ROW_COUNT; item_count := item_count + affected;

  INSERT INTO private.retention_items (
    deletion_request_id, subject_user_id, source_schema, source_table,
    source_record_id, retention_class, source_end_event_at, eligible_after
  )
  SELECT p_request_id, target_user_id, 'private', 'private_qa_records',
    qa.id, 'feedback_history_24m',
    greatest(coalesce(enrolment.ends_at, close_time), qa.created_at),
    greatest(coalesce(enrolment.ends_at, close_time), qa.created_at) + interval '24 months'
  FROM private.private_qa_records AS qa
  JOIN public.assessment_versions AS version ON version.id = qa.assessment_version_id
  JOIN public.assessment_submissions AS submission ON submission.id = version.submission_id
  JOIN public.task_versions AS task ON task.id = submission.task_version_id
  LEFT JOIN public.course_enrolments AS enrolment
    ON enrolment.learner_id = target_user_id AND enrolment.pathway_id = task.pathway_id
  WHERE submission.learner_id = target_user_id
  ON CONFLICT DO NOTHING;
  GET DIAGNOSTICS affected = ROW_COUNT; item_count := item_count + affected;

  UPDATE private.account_deletion_requests
  SET status = 'executing',
      closure_executed_by = actor_id,
      closure_executed_at = close_time,
      retention_items_created = item_count
  WHERE id = p_request_id;

  INSERT INTO private.security_audit_events (
    actor_id, action, target_type, target_id, outcome, reason_category
  )
  VALUES (
    actor_id, 'account_deletion_account_closed',
    'account_deletion_request', p_request_id, 'success', 'retention_plan_created'
  );

  RETURN QUERY SELECT p_request_id, close_time, item_count, false;
END;
$function$;

CREATE OR REPLACE FUNCTION public.list_account_retention_plan(p_request_id uuid)
RETURNS TABLE(
  retention_item_id uuid,
  source_schema text,
  source_table text,
  source_record_id uuid,
  retention_class text,
  source_end_event_at timestamptz,
  eligible_after timestamptz,
  state text,
  backup_copy_count bigint,
  earliest_backup_expiry_at timestamptz
)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $function$
DECLARE
  actor_id uuid := auth.uid();
BEGIN
  IF coalesce(auth.jwt() ->> 'role', '') <> 'authenticated'
    OR actor_id IS NULL
    OR NOT private.current_account_is_active()
    OR NOT private.current_user_has_role('owner'::public.app_role)
    OR coalesce(auth.jwt() ->> 'aal', 'aal1') <> 'aal2' THEN
    RAISE EXCEPTION USING ERRCODE = '42501', MESSAGE = 'account_deletion_owner_aal2_required';
  END IF;

  IF p_request_id IS NULL OR NOT EXISTS (
    SELECT 1 FROM private.account_deletion_requests AS request
    WHERE request.id = p_request_id AND request.status IN ('executing', 'completed')
  ) THEN
    RAISE EXCEPTION USING ERRCODE = 'P0002', MESSAGE = 'account_retention_plan_not_found';
  END IF;

  INSERT INTO private.security_audit_events (
    actor_id, action, target_type, target_id, outcome, reason_category
  )
  VALUES (
    actor_id, 'account_retention_plan_listed',
    'account_deletion_request', p_request_id, 'success', 'owner_aal2'
  );

  RETURN QUERY
  SELECT item.id, item.source_schema, item.source_table,
    item.source_record_id, item.retention_class, item.source_end_event_at,
    item.eligible_after, item.state,
    (SELECT count(*) FROM private.retention_backup_objects AS backup
     WHERE backup.retention_item_id = item.id),
    (SELECT min(backup.expires_at) FROM private.retention_backup_objects AS backup
     WHERE backup.retention_item_id = item.id)
  FROM private.retention_items AS item
  WHERE item.deletion_request_id = p_request_id
  ORDER BY item.eligible_after, item.source_schema, item.source_table, item.source_record_id;
END;
$function$;

ALTER FUNCTION private.protect_account_deletion_request() OWNER TO postgres;
ALTER FUNCTION private.protect_retention_item() OWNER TO postgres;
ALTER FUNCTION private.protect_retention_backup_object() OWNER TO postgres;
ALTER FUNCTION private.propagate_retention_backup_expiry() OWNER TO postgres;
ALTER FUNCTION private.prepare_late_retention_backup_expiry() OWNER TO postgres;
ALTER FUNCTION public.list_account_deletion_requests() OWNER TO postgres;
REVOKE ALL ON FUNCTION public.list_account_deletion_requests() FROM PUBLIC, anon, service_role;
GRANT EXECUTE ON FUNCTION public.list_account_deletion_requests() TO authenticated;
ALTER FUNCTION public.close_account_for_deletion(uuid) OWNER TO postgres;
ALTER FUNCTION public.list_account_retention_plan(uuid) OWNER TO postgres;

REVOKE ALL ON FUNCTION private.protect_account_deletion_request() FROM PUBLIC, anon, authenticated;
REVOKE ALL ON FUNCTION private.protect_retention_item() FROM PUBLIC, anon, authenticated;
REVOKE ALL ON FUNCTION private.protect_retention_backup_object() FROM PUBLIC, anon, authenticated;
REVOKE ALL ON FUNCTION private.propagate_retention_backup_expiry() FROM PUBLIC, anon, authenticated;
REVOKE ALL ON FUNCTION private.prepare_late_retention_backup_expiry() FROM PUBLIC, anon, authenticated;
REVOKE ALL ON FUNCTION public.close_account_for_deletion(uuid) FROM PUBLIC, anon, service_role;
REVOKE ALL ON FUNCTION public.list_account_retention_plan(uuid) FROM PUBLIC, anon, service_role;

GRANT EXECUTE ON FUNCTION public.close_account_for_deletion(uuid) TO authenticated;
GRANT EXECUTE ON FUNCTION public.list_account_retention_plan(uuid) TO authenticated;

COMMENT ON TABLE private.retention_items IS
'Metadata-only retention inventory for an approved account closure. Source records remain intact until their class-specific 12-/24-month eligibility time; deletion execution is a separate controlled phase.';
COMMENT ON TABLE private.retention_backup_objects IS
'Metadata-only inventory of separately encrypted off-site object copies. A source-content deletion starts exactly 30 days of backup expiry. Do not populate or provision Cloudflare R2 until transfer, region, encryption and key-custody approvals pass.';
COMMENT ON FUNCTION public.close_account_for_deletion(uuid) IS
'Owner AAL2 closure operation for an approved request with no active legal hold. Revokes access, closes Auth identity and enrolments, and builds a non-content retention plan. It never deletes retained learning records or PDF objects.';
