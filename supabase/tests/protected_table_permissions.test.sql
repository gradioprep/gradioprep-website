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
        'attempt_response_versions'
      )
  ),
  12,
  'all twelve currently protected application tables are present'
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
        'attempt_response_versions'
      )
      AND relation.relrowsecurity
  ),
  12,
  'RLS is enabled on every protected application table'
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
        'attempt_response_versions'
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
        'attempt_response_versions'
      )
  ),
  'authenticated has no direct table privilege on private audit, invitation or response-history records'
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
    )
  ),
  'authenticated users cannot directly mutate roles, links, enrolments, assignments, attempts or responses'
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
  AND has_table_privilege('authenticated', 'public.grader_assignments', 'SELECT'),
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
  $$UPDATE public.grader_assignments SET grader_user_id = auth.uid()$$,
  '42501', NULL,
  'student cannot directly alter grader assignments'
);
SELECT throws_ok(
  $$INSERT INTO private.security_audit_events (action, target_type) VALUES ('forged', 'test')$$,
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
