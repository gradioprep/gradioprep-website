BEGIN;
CREATE EXTENSION IF NOT EXISTS pgtap WITH SCHEMA extensions;
SELECT no_plan();

-- Inventory guard: every currently protected public/private table must exist
-- and have RLS enabled. Update this expected count only alongside a reviewed
-- inventory and tests for the new table.
SELECT is(
  (
    SELECT count(*)::integer
    FROM pg_class AS relation
    JOIN pg_namespace AS namespace ON namespace.oid = relation.relnamespace
    WHERE relation.relkind = 'r'
      AND namespace.nspname IN ('public', 'private')
      AND relation.relname IN (
        'profiles',
        'role_assignments',
        'guardian_learner_links',
        'course_enrolments',
        'task_versions',
        'task_version_prompts',
        'attempts',
        'attempt_responses',
        'grader_assignments',
        'security_audit_events',
        'staff_invitations',
        'attempt_response_versions',
        'grading_capacity_config',
        'rubrics',
        'rubric_versions',
        'rubric_criteria',
        'task_rubric_mappings',
        'assessment_submissions',
        'submission_versions',
        'submission_grader_assignments',
        'assessment_versions',
        'criterion_results',
        'assessment_drafts',
        'assessment_draft_history',
        'private_qa_records'
      )
  ),
  32,
  'all thirty-two protected application tables in the baseline inventory are present'
);

SELECT is(
  (
    SELECT count(*)::integer
    FROM pg_class AS relation
    JOIN pg_namespace AS namespace ON namespace.oid = relation.relnamespace
    WHERE relation.relkind = 'r'
      AND namespace.nspname IN ('public', 'private')
      AND relation.relname IN (
        'profiles',
        'role_assignments',
        'guardian_learner_links',
        'course_enrolments',
        'task_versions',
        'task_version_prompts',
        'attempts',
        'attempt_responses',
        'grader_assignments',
        'security_audit_events',
        'staff_invitations',
        'attempt_response_versions',
        'grading_capacity_config',
        'rubrics',
        'rubric_versions',
        'rubric_criteria',
        'task_rubric_mappings',
        'assessment_submissions',
        'submission_versions',
        'submission_grader_assignments',
        'assessment_versions',
        'criterion_results',
        'assessment_drafts',
        'assessment_draft_history',
        'private_qa_records',
        'curriculum_route_versions',
        'curriculum_unit_versions',
        'curriculum_unit_outcome_mappings',
        'milestone_cycle_versions',
        'milestone_segments',
        'milestone_unit_memberships',
        'learner_unit_progress'
      )
      AND relation.relrowsecurity
  ),
  32,
  'RLS is enabled on every protected application table in the baseline inventory'
);

SELECT ok(
  (
    SELECT coalesce(bool_and(
      NOT has_table_privilege(
        'anon',
        format('%I.%I', namespace.nspname, relation.relname),
        'SELECT'
      )
      AND NOT has_table_privilege(
        'anon',
        format('%I.%I', namespace.nspname, relation.relname),
        'INSERT'
      )
      AND NOT has_table_privilege(
        'anon',
        format('%I.%I', namespace.nspname, relation.relname),
        'UPDATE'
      )
      AND NOT has_table_privilege(
        'anon',
        format('%I.%I', namespace.nspname, relation.relname),
        'DELETE'
      )
    ), false)
    FROM pg_class AS relation
    JOIN pg_namespace AS namespace ON namespace.oid = relation.relnamespace
    WHERE relation.relkind = 'r'
      AND namespace.nspname IN ('public', 'private')
      AND relation.relname IN (
        'profiles',
        'role_assignments',
        'guardian_learner_links',
        'course_enrolments',
        'task_versions',
        'task_version_prompts',
        'attempts',
        'attempt_responses',
        'grader_assignments',
        'security_audit_events',
        'staff_invitations',
        'attempt_response_versions',
        'grading_capacity_config',
        'rubrics',
        'rubric_versions',
        'rubric_criteria',
        'task_rubric_mappings',
        'assessment_submissions',
        'submission_versions',
        'submission_grader_assignments',
        'assessment_versions',
        'criterion_results',
        'assessment_drafts',
        'assessment_draft_history',
        'private_qa_records',
        'curriculum_route_versions',
        'curriculum_unit_versions',
        'curriculum_unit_outcome_mappings',
        'milestone_cycle_versions',
        'milestone_segments',
        'milestone_unit_memberships',
        'learner_unit_progress'
      )
  ),
  'anonymous has no direct read or write privilege on any protected table'
);

SELECT ok(
  (
    SELECT coalesce(bool_and(
      NOT has_table_privilege(
        'authenticated',
        format('%I.%I', namespace.nspname, relation.relname),
        'SELECT'
      )
      AND NOT has_table_privilege(
        'authenticated',
        format('%I.%I', namespace.nspname, relation.relname),
        'INSERT'
      )
      AND NOT has_table_privilege(
        'authenticated',
        format('%I.%I', namespace.nspname, relation.relname),
        'UPDATE'
      )
      AND NOT has_table_privilege(
        'authenticated',
        format('%I.%I', namespace.nspname, relation.relname),
        'DELETE'
      )
    ), false)
    FROM pg_class AS relation
    JOIN pg_namespace AS namespace ON namespace.oid = relation.relnamespace
    WHERE relation.relkind = 'r'
      AND namespace.nspname = 'private'
      AND relation.relname IN (
        'security_audit_events',
        'staff_invitations',
        'attempt_response_versions',
        'grading_capacity_config',
        'rubrics',
        'rubric_versions',
        'rubric_criteria',
        'task_rubric_mappings',
        'assessment_submissions',
        'submission_versions',
        'assessment_drafts',
        'assessment_draft_history',
        'private_qa_records',
      )
  ),
  'authenticated has no direct table privilege on private audit, invitation, response-history, capacity, draft and academic-QA records'
);

SELECT ok(
  (
    SELECT bool_and(
      NOT has_table_privilege('authenticated', 'public.role_assignments', 'INSERT')
      AND NOT has_table_privilege('authenticated', 'public.role_assignments', 'UPDATE')
      AND NOT has_table_privilege('authenticated', 'public.role_assignments', 'DELETE')
      AND NOT has_table_privilege('authenticated', 'public.guardian_learner_links', 'INSERT')
      AND NOT has_table_privilege('authenticated', 'public.guardian_learner_links', 'UPDATE')
      AND NOT has_table_privilege('authenticated', 'public.guardian_learner_links', 'DELETE')
      AND NOT has_table_privilege('authenticated', 'public.course_enrolments', 'INSERT')
      AND NOT has_table_privilege('authenticated', 'public.course_enrolments', 'UPDATE')
      AND NOT has_table_privilege('authenticated', 'public.course_enrolments', 'DELETE')
      AND NOT has_table_privilege('authenticated', 'public.grader_assignments', 'INSERT')
      AND NOT has_table_privilege('authenticated', 'public.grader_assignments', 'UPDATE')
      AND NOT has_table_privilege('authenticated', 'public.grader_assignments', 'DELETE')
      AND NOT has_table_privilege('authenticated', 'public.attempts', 'INSERT')
      AND NOT has_table_privilege('authenticated', 'public.attempts', 'UPDATE')
      AND NOT has_table_privilege('authenticated', 'public.attempts', 'DELETE')
      AND NOT has_table_privilege('authenticated', 'public.attempt_responses', 'INSERT')
      AND NOT has_table_privilege('authenticated', 'public.attempt_responses', 'UPDATE')
      AND NOT has_table_privilege('authenticated', 'public.attempt_responses', 'DELETE')
      AND NOT has_table_privilege('authenticated', 'public.assessment_submissions', 'INSERT')
      AND NOT has_table_privilege('authenticated', 'public.assessment_submissions', 'UPDATE')
      AND NOT has_table_privilege('authenticated', 'public.assessment_submissions', 'DELETE')
      AND NOT has_table_privilege('authenticated', 'public.submission_versions', 'INSERT')
      AND NOT has_table_privilege('authenticated', 'public.submission_versions', 'UPDATE')
      AND NOT has_table_privilege('authenticated', 'public.submission_versions', 'DELETE')
      AND NOT has_table_privilege('authenticated', 'public.rubrics', 'INSERT')
      AND NOT has_table_privilege('authenticated', 'public.rubrics', 'UPDATE')
      AND NOT has_table_privilege('authenticated', 'public.rubrics', 'DELETE')
      AND NOT has_table_privilege('authenticated', 'public.rubric_versions', 'INSERT')
      AND NOT has_table_privilege('authenticated', 'public.rubric_versions', 'UPDATE')
      AND NOT has_table_privilege('authenticated', 'public.rubric_versions', 'DELETE')
      AND NOT has_table_privilege('authenticated', 'public.rubric_criteria', 'INSERT')
      AND NOT has_table_privilege('authenticated', 'public.rubric_criteria', 'UPDATE')
      AND NOT has_table_privilege('authenticated', 'public.rubric_criteria', 'DELETE')
      AND NOT has_table_privilege('authenticated', 'public.task_rubric_mappings', 'INSERT')
      AND NOT has_table_privilege('authenticated', 'public.task_rubric_mappings', 'UPDATE')
      AND NOT has_table_privilege('authenticated', 'public.task_rubric_mappings', 'DELETE')
       AND NOT has_table_privilege('authenticated', 'public.submission_grader_assignments', 'INSERT')
       AND NOT has_table_privilege('authenticated', 'public.submission_grader_assignments', 'UPDATE')
       AND NOT has_table_privilege('authenticated', 'public.submission_grader_assignments', 'DELETE')
       AND NOT has_table_privilege('authenticated', 'public.assessment_versions', 'INSERT')
       AND NOT has_table_privilege('authenticated', 'public.assessment_versions', 'UPDATE')
       AND NOT has_table_privilege('authenticated', 'public.assessment_versions', 'DELETE')
       AND NOT has_table_privilege('authenticated', 'public.criterion_results', 'INSERT')
       AND NOT has_table_privilege('authenticated', 'public.criterion_results', 'UPDATE')
       AND NOT has_table_privilege('authenticated', 'public.criterion_results', 'DELETE')
    )
  ),
  'authenticated users cannot directly mutate roles, links, enrolments, assignments, attempts or responses'
);

SELECT ok(
  NOT has_table_privilege('authenticated', 'public.curriculum_route_versions', 'INSERT')
  AND NOT has_table_privilege('authenticated', 'public.curriculum_route_versions', 'UPDATE')
  AND NOT has_table_privilege('authenticated', 'public.curriculum_route_versions', 'DELETE')
  AND NOT has_table_privilege('authenticated', 'public.curriculum_unit_versions', 'INSERT')
  AND NOT has_table_privilege('authenticated', 'public.curriculum_unit_versions', 'UPDATE')
  AND NOT has_table_privilege('authenticated', 'public.curriculum_unit_versions', 'DELETE')
  AND NOT has_table_privilege('authenticated', 'public.curriculum_unit_outcome_mappings', 'INSERT')
  AND NOT has_table_privilege('authenticated', 'public.curriculum_unit_outcome_mappings', 'UPDATE')
  AND NOT has_table_privilege('authenticated', 'public.curriculum_unit_outcome_mappings', 'DELETE')
  AND NOT has_table_privilege('authenticated', 'public.milestone_cycle_versions', 'INSERT')
  AND NOT has_table_privilege('authenticated', 'public.milestone_cycle_versions', 'UPDATE')
  AND NOT has_table_privilege('authenticated', 'public.milestone_cycle_versions', 'DELETE')
  AND NOT has_table_privilege('authenticated', 'public.milestone_segments', 'INSERT')
  AND NOT has_table_privilege('authenticated', 'public.milestone_segments', 'UPDATE')
  AND NOT has_table_privilege('authenticated', 'public.milestone_segments', 'DELETE')
  AND NOT has_table_privilege('authenticated', 'public.milestone_unit_memberships', 'INSERT')
  AND NOT has_table_privilege('authenticated', 'public.milestone_unit_memberships', 'UPDATE')
  AND NOT has_table_privilege('authenticated', 'public.milestone_unit_memberships', 'DELETE')
  AND NOT has_table_privilege('authenticated', 'public.learner_unit_progress', 'INSERT')
  AND NOT has_table_privilege('authenticated', 'public.learner_unit_progress', 'UPDATE')
  AND NOT has_table_privilege('authenticated', 'public.learner_unit_progress', 'DELETE'),
  'authenticated can read published progress rows but cannot directly mutate the curriculum catalogue or progress'
);

SELECT ok(
  has_table_privilege('authenticated', 'public.profiles', 'SELECT')
  AND has_table_privilege('authenticated', 'public.role_assignments', 'SELECT')
  AND has_table_privilege('authenticated', 'public.guardian_learner_links', 'SELECT')
  AND has_table_privilege('authenticated', 'public.course_enrolments', 'SELECT')
  AND has_table_privilege('authenticated', 'public.task_versions', 'SELECT')
  AND has_table_privilege('authenticated', 'public.task_version_prompts', 'SELECT')
  AND has_table_privilege('authenticated', 'public.attempts', 'SELECT')
  AND has_table_privilege('authenticated', 'public.attempt_responses', 'SELECT')
  AND has_table_privilege('authenticated', 'public.grader_assignments', 'SELECT')
  AND has_table_privilege('authenticated', 'public.assessment_submissions', 'SELECT')
  AND has_table_privilege('authenticated', 'public.submission_versions', 'SELECT')
  AND has_table_privilege('authenticated', 'public.rubrics', 'SELECT')
  AND has_table_privilege('authenticated', 'public.rubric_versions', 'SELECT')
  AND has_table_privilege('authenticated', 'public.rubric_criteria', 'SELECT')
  AND has_table_privilege('authenticated', 'public.task_rubric_mappings', 'SELECT')
  AND has_table_privilege('authenticated', 'public.submission_grader_assignments', 'SELECT')
  AND has_table_privilege('authenticated', 'public.assessment_versions', 'SELECT')
  AND has_table_privilege('authenticated', 'public.criterion_results', 'SELECT')
  AND has_table_privilege('authenticated', 'public.curriculum_route_versions', 'SELECT')
  AND has_table_privilege('authenticated', 'public.curriculum_unit_versions', 'SELECT')
  AND has_table_privilege('authenticated', 'public.curriculum_unit_outcome_mappings', 'SELECT')
  AND has_table_privilege('authenticated', 'public.milestone_cycle_versions', 'SELECT')
  AND has_table_privilege('authenticated', 'public.milestone_segments', 'SELECT')
  AND has_table_privilege('authenticated', 'public.milestone_unit_memberships', 'SELECT')
  AND has_table_privilege('authenticated', 'public.learner_unit_progress', 'SELECT'),
  'authenticated SELECT grants exist only as the starting point for row-scoped RLS reads'
);

-- Direct attempts/response writes are denied; the narrow authenticated RPCs
-- remain the only mutation paths and re-check auth.uid(), state and ownership.
SET LOCAL ROLE authenticated;
SELECT set_config('request.jwt.claim.sub', '11111111-1111-4111-8111-111111111111', true);
SELECT set_config('request.jwt.claims', '{"sub":"11111111-1111-4111-8111-111111111111","role":"authenticated","aal":"aal1"}', true);
SELECT throws_ok(
  $$INSERT INTO public.attempts (learner_id, task_version_id)
    VALUES ('11111111-1111-4111-8111-111111111111', 'a1111111-1111-4111-8111-111111111111')$$,
  '42501', NULL,
  'student cannot bypass create_attempt with a direct attempt insert'
);
SELECT throws_ok(
  $$INSERT INTO public.attempt_responses (attempt_id, task_version_id, prompt_id, response_text)
    VALUES ('c1111111-1111-4111-8111-111111111111', 'a1111111-1111-4111-8111-111111111111', 'b1111111-1111-4111-8111-111111111111', 'forged direct response')$$,
  '42501', NULL,
  'student cannot bypass save_attempt_response with a direct response insert'
);
SELECT throws_ok(
  $q$UPDATE public.grader_assignments SET grader_user_id = auth.uid()$q$,
  '42501', NULL,
  'student cannot directly alter grader assignments'
);
SELECT throws_ok(
  $q$UPDATE public.attempts SET learner_id = auth.uid() WHERE id = 'c1111111-1111-4111-8111-111111111111'$q$,
  '42501', NULL,
  'student cannot transfer an attempt by changing its learner ownership'
);
SELECT throws_ok(
  $q$UPDATE public.attempts SET status = 'withdrawn', submitted_at = now() WHERE id = 'c1111111-1111-4111-8111-111111111111'$q$,
  '42501', NULL,
  'student cannot manipulate server-controlled attempt state or timestamps'
);
SELECT throws_ok(
  $q$UPDATE public.attempt_responses SET attempt_id = 'c2222222-2222-4222-8222-222222222222' WHERE id = (SELECT id FROM public.attempt_responses LIMIT 1)$q$,
  '42501', NULL,
  'student cannot move a response between learners or attempts'
);
SELECT throws_ok(
  $q$UPDATE public.attempt_responses SET version = 99, updated_at = now() WHERE id = (SELECT id FROM public.attempt_responses LIMIT 1)$q$,
  '42501', NULL,
  'student cannot manipulate response version or timestamps'
);
SELECT throws_ok(
  $q$UPDATE public.guardian_learner_links SET status = 'verified' WHERE guardian_id = auth.uid()$q$,
  '42501', NULL,
  'student cannot forge or update guardian verification links'
);
SELECT throws_ok(
  $q$UPDATE public.course_enrolments SET learner_id = auth.uid() WHERE learner_id <> auth.uid()$q$,
  '42501', NULL,
  'student cannot transfer or forge enrolment ownership'
);
SELECT throws_ok(
  $q$UPDATE public.task_versions SET release_state = 'published' WHERE id = 'a1111111-1111-4111-8111-111111111111'$q$,
  '42501', NULL,
  'student cannot publish or change task versions'
);
SELECT throws_ok(
  $q$UPDATE public.task_version_prompts SET prompt_text = 'forged prompt' WHERE id = 'b1111111-1111-4111-8111-111111111111'$q$,
  '42501', NULL,
  'student cannot change published task prompts'
);
SELECT throws_ok(
  $q$INSERT INTO private.security_audit_events (action, target_type) VALUES ('forged', 'test')$q$,
  '42501', NULL,
  'student cannot forge private audit events'
);
SELECT throws_ok(
  $$SELECT * FROM private.attempt_response_versions$$,
  '42501', NULL,
  'student cannot read private response history'
);
RESET ROLE;

SELECT * FROM finish();
ROLLBACK;
