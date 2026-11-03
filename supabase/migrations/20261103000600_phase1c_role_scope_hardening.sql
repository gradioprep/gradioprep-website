-- Phase 1C security hardening: align task metadata visibility and owner reads
-- with enrolment, consent, assignment and AAL2 boundaries.
-- No new data/provider/service is provisioned by this migration.

CREATE OR REPLACE FUNCTION private.can_read_task_version(target_task_version_id uuid)
RETURNS boolean
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = ''
AS $$
  SELECT EXISTS (
    SELECT 1
    FROM public.task_versions AS task_version
    WHERE task_version.id = target_task_version_id
      AND private.current_account_is_active()
      AND (
        (
          private.current_user_has_role('owner'::public.app_role)
          AND coalesce(auth.jwt() ->> 'aal', 'aal1') = 'aal2'
        )
        OR (
          task_version.release_state = 'published'
          AND (
            (
              private.current_user_has_role('student'::public.app_role)
              AND EXISTS (
                SELECT 1
                FROM public.course_enrolments AS enrolment
                WHERE enrolment.learner_id = (SELECT auth.uid())
                  AND enrolment.pathway_id = task_version.pathway_id
                  AND enrolment.status = 'active'
              )
            )
            OR (
              private.current_user_has_role('guardian'::public.app_role)
              AND EXISTS (
                SELECT 1
                FROM public.attempts AS attempt
                WHERE attempt.task_version_id = task_version.id
                  AND private.can_view_learner(attempt.learner_id, 'submissions')
              )
            )
            OR (
              private.current_user_has_role('grader'::public.app_role)
              AND coalesce(auth.jwt() ->> 'aal', 'aal1') = 'aal2'
              AND EXISTS (
                SELECT 1
                FROM public.attempts AS attempt
                JOIN public.grader_assignments AS assignment
                  ON assignment.attempt_id = attempt.id
                WHERE attempt.task_version_id = task_version.id
                  AND attempt.status = 'submitted'
                  AND assignment.grader_user_id = (SELECT auth.uid())
                  AND assignment.revoked_at IS NULL
              )
            )
          )
        )
      )
  );
$$;

REVOKE ALL ON FUNCTION private.can_read_task_version(uuid) FROM PUBLIC, anon, authenticated;
GRANT EXECUTE ON FUNCTION private.can_read_task_version(uuid) TO authenticated;

-- Task metadata follows the same resource scope as the related attempt:
-- enrolled student, explicitly consented linked guardian, assigned AAL2 grader,
-- or owner at AAL2. Admin is not an implicit reader.
DROP POLICY IF EXISTS task_versions_select_released_or_owner ON public.task_versions;
CREATE POLICY task_versions_select_scoped
  ON public.task_versions FOR SELECT TO authenticated
  USING (private.can_read_task_version(id));

DROP POLICY IF EXISTS task_version_prompts_select_released_or_owner ON public.task_version_prompts;
CREATE POLICY task_version_prompts_select_scoped
  ON public.task_version_prompts FOR SELECT TO authenticated
  USING (private.can_read_task_version(task_version_id));

-- Owner-wide identity access is privileged and requires AAL2 inside PostgreSQL.
-- Users retain self/participant access at AAL1; AAL2 is required for cross-user
-- owner inspection. The Worker must independently enforce AAL2 on any such route.
DROP POLICY IF EXISTS profiles_select_scoped ON public.profiles;
CREATE POLICY profiles_select_scoped
  ON public.profiles FOR SELECT TO authenticated
  USING (
    private.current_account_is_active()
    AND (
      user_id = (SELECT auth.uid())
      OR private.can_view_learner(user_id, 'profile')
      OR (
        private.current_user_has_role('owner'::public.app_role)
        AND coalesce(auth.jwt() ->> 'aal', 'aal1') = 'aal2'
      )
    )
  );

DROP POLICY IF EXISTS role_assignments_select_own_or_owner ON public.role_assignments;
CREATE POLICY role_assignments_select_own_or_owner
  ON public.role_assignments FOR SELECT TO authenticated
  USING (
    private.current_account_is_active()
    AND (
      user_id = (SELECT auth.uid())
      OR (
        private.current_user_has_role('owner'::public.app_role)
        AND coalesce(auth.jwt() ->> 'aal', 'aal1') = 'aal2'
      )
    )
  );

DROP POLICY IF EXISTS guardian_links_select_participant_or_owner ON public.guardian_learner_links;
CREATE POLICY guardian_links_select_participant_or_owner
  ON public.guardian_learner_links FOR SELECT TO authenticated
  USING (
    private.current_account_is_active()
    AND (
      guardian_id = (SELECT auth.uid())
      OR learner_id = (SELECT auth.uid())
      OR (
        private.current_user_has_role('owner'::public.app_role)
        AND coalesce(auth.jwt() ->> 'aal', 'aal1') = 'aal2'
      )
    )
  );

DROP POLICY IF EXISTS course_enrolments_select_scoped ON public.course_enrolments;
CREATE POLICY course_enrolments_select_scoped
  ON public.course_enrolments FOR SELECT TO authenticated
  USING (
    private.current_account_is_active()
    AND (
      learner_id = (SELECT auth.uid())
      OR private.can_view_learner(learner_id, 'progress')
      OR (
        private.current_user_has_role('owner'::public.app_role)
        AND coalesce(auth.jwt() ->> 'aal', 'aal1') = 'aal2'
      )
    )
  );
