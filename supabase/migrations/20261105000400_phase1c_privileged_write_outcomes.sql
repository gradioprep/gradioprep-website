-- Phase 1C-E: append-only outcomes for privileged state-changing operations.
-- Success events remain transactionally written by the operation RPCs/triggers.
-- This separate RPC records only a denied or failed result after the operation
-- has returned an error; it never accepts caller-selected event action/target types.

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
  actor_active boolean := false;
  actor_has_role boolean := false;
  assurance_ok boolean := false;
  assignment_ok boolean := true;
  allowed boolean := false;
  event_outcome text;
  event_reason text;
BEGIN
  IF actor_id IS NULL
    OR p_outcome IS NULL
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

    WHEN 'grader_assessment_draft_save' THEN
      resource_type := 'assessment_submission';
      required_role := 'grader'::public.app_role;
      requires_active_assignment := true;

    WHEN 'grader_assessment_feedback_publish' THEN
      resource_type := 'assessment_submission';
      required_role := 'grader'::public.app_role;
      requires_active_assignment := true;

    ELSE
      -- Do not expose a generic "write audit" primitive to authenticated users.
      RETURN false;
  END CASE;

  actor_active := private.current_account_is_active();
  actor_has_role := private.current_user_has_role(required_role);
  assurance_ok := coalesce(auth.jwt() ->> 'aal', 'aal1') = 'aal2';

  IF requires_active_assignment AND p_target_id IS NOT NULL THEN
    SELECT EXISTS (
      SELECT 1
      FROM public.submission_grader_assignments AS assignment
      WHERE assignment.submission_id = p_target_id
        AND assignment.grader_user_id = actor_id
        AND assignment.revoked_at IS NULL
    )
    INTO assignment_ok;
  END IF;

  allowed := actor_active
    AND actor_has_role
    AND (NOT requires_aal2 OR assurance_ok)
    AND p_target_id IS NOT NULL
    AND assignment_ok;

  IF allowed THEN
    -- An authorised operation cannot be logged as denied. For a real failure,
    -- accept only a small safe vocabulary; never store SQL messages or user data.
    IF p_outcome = 'denied' THEN
      RETURN true;
    END IF;

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
    -- An unauthorised caller cannot claim an authorised failure. Irrespective
    -- of the requested label, this records only the database-derived denial.
    event_outcome := 'denied';
    event_reason := CASE
      WHEN NOT actor_active THEN 'inactive_account'
      WHEN NOT actor_has_role THEN 'role_required'
      WHEN requires_aal2 AND NOT assurance_ok THEN 'aal2_required'
      WHEN requires_active_assignment AND NOT assignment_ok THEN 'assignment_required'
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

ALTER FUNCTION public.audit_privileged_write_outcome(text, uuid, text, text)
  OWNER TO postgres;
REVOKE ALL ON FUNCTION public.audit_privileged_write_outcome(text, uuid, text, text)
  FROM PUBLIC, anon, authenticated;
GRANT EXECUTE ON FUNCTION public.audit_privileged_write_outcome(text, uuid, text, text)
  TO authenticated;

COMMENT ON FUNCTION public.audit_privileged_write_outcome(text, uuid, text, text) IS
  'Records allowlisted Owner/assigned-Grader privileged write denials and post-RPC failures. It cannot record success, invent targets/actions, bypass operation authorization, or store learner/QA/feedback payloads.';
