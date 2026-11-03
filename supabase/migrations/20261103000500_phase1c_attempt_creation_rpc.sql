-- Phase 1C: atomically create a learner-owned typed attempt.
-- Remove direct PostgREST inserts; the only create path rechecks task and enrolment
-- eligibility inside one database transaction using the verified auth.uid().

REVOKE INSERT (learner_id, task_version_id)
  ON public.attempts FROM PUBLIC, anon, authenticated;

CREATE OR REPLACE FUNCTION public.create_attempt(p_task_version_id uuid)
RETURNS TABLE (
  attempt_id uuid,
  learner_id uuid,
  task_version_id uuid,
  status text,
  started_at timestamptz,
  submitted_at timestamptz
)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
DECLARE
  actor_id uuid := auth.uid();
  selected_pathway_id text;
  created_attempt public.attempts%ROWTYPE;
BEGIN
  IF actor_id IS NULL
    OR NOT private.current_account_is_active()
    OR NOT private.current_user_has_role('student'::public.app_role) THEN
    RAISE EXCEPTION USING ERRCODE = '42501', MESSAGE = 'attempt_creation_forbidden';
  END IF;

  SELECT task_version.pathway_id
    INTO selected_pathway_id
    FROM public.task_versions AS task_version
    WHERE task_version.id = p_task_version_id
      AND task_version.release_state = 'published'
      AND task_version.response_mode = 'typed';

  IF NOT FOUND OR NOT EXISTS (
    SELECT 1
    FROM public.course_enrolments AS enrolment
    WHERE enrolment.learner_id = actor_id
      AND enrolment.pathway_id = selected_pathway_id
      AND enrolment.status = 'active'
  ) THEN
    RAISE EXCEPTION USING ERRCODE = 'P0002', MESSAGE = 'attempt_task_not_available';
  END IF;

  INSERT INTO public.attempts (learner_id, task_version_id)
  VALUES (actor_id, p_task_version_id)
  RETURNING * INTO created_attempt;

  INSERT INTO private.security_audit_events (
    actor_id, action, target_type, target_id, outcome, reason_category
  )
  VALUES (actor_id, 'attempt_created', 'attempt', created_attempt.id, 'success', 'learner_action');

  RETURN QUERY
    SELECT created_attempt.id,
           created_attempt.learner_id,
           created_attempt.task_version_id,
           created_attempt.status,
           created_attempt.started_at,
           created_attempt.submitted_at;
END;
$$;

REVOKE ALL ON FUNCTION public.create_attempt(uuid) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.create_attempt(uuid) TO authenticated;
