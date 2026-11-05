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
