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
  actor_has_role := private.current_user_has_role(required_role);
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

      ELSE
        assignment_ok := true;
    END CASE;
  ELSE
    assignment_ok := false;
  END IF;

  allowed := actor_active
    AND actor_has_role
    AND (NOT requires_aal2 OR assurance_ok)
    AND p_target_id IS NOT NULL
    AND assignment_ok;

  IF allowed AND p_outcome = 'denied' THEN
    -- The trusted Worker can deny a request before the database RPC (for
    -- example during a role precheck). Preserve that API-layer denial too.
    event_outcome := 'denied';
    event_reason := 'worker_precheck_denied';
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
  'Records allowlisted Owner/assigned-Grader and own-learner write denials and post-RPC failures. It cannot manufacture success events or store response/idempotency/feedback/QA payloads.';
