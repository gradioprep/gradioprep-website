BEGIN;
SELECT no_plan();

SELECT ok(
  NOT has_function_privilege('anon', 'public.create_private_qa_record(uuid,jsonb,text,text,text,text)', 'EXECUTE')
  AND NOT has_function_privilege('anon', 'public.get_private_qa_records(uuid)', 'EXECUTE'),
  'anonymous callers cannot execute private academic-QA operations'
);
SELECT ok(
  has_function_privilege('authenticated', 'public.create_private_qa_record(uuid,jsonb,text,text,text,text)', 'EXECUTE')
  AND has_function_privilege('authenticated', 'public.get_private_qa_records(uuid)', 'EXECUTE'),
  'authenticated callers reach only narrow QA RPCs, each of which enforces Owner AAL2 internally'
);
SELECT ok(
  NOT has_table_privilege('authenticated', 'private.private_qa_records', 'SELECT')
  AND NOT has_table_privilege('authenticated', 'private.private_qa_records', 'INSERT')
  AND NOT has_table_privilege('authenticated', 'private.private_qa_records', 'UPDATE')
  AND NOT has_table_privilege('authenticated', 'private.private_qa_records', 'DELETE'),
  'no authenticated role has direct table access to private QA records'
);
SELECT ok(
  (SELECT relrowsecurity FROM pg_class WHERE oid = 'private.private_qa_records'::regclass),
  'RLS is enabled on the private QA record table'
);

-- Create one synthetic accepted submission and a published assessment-version
-- fixture. The version row is inserted by the database test role so this suite
-- isolates QA access from the separate human-grader publication workflow.
SET LOCAL ROLE authenticated;
SELECT set_config('request.jwt.claim.sub', '11111111-1111-4111-8111-111111111111', true);
SELECT set_config('request.jwt.claims', '{"sub":"11111111-1111-4111-8111-111111111111","role":"authenticated","aal":"aal1"}', true);
SELECT set_config(
  'test.private_qa_submission_id',
  (SELECT submission_id::text
   FROM public.accept_assessment_submission(
     'a1111111-1111-4111-8111-111111111111',
     '91919191-9191-4191-8191-919191919191',
     'Synthetic accepted response used only to validate private QA ownership, revision and access controls.'
   )),
  true
);
RESET ROLE;

WITH created_version AS (
  INSERT INTO public.assessment_versions (
    submission_id, version_number, rubric_version_id, total_points, max_points,
    overall_feedback, published_by, published_at, first_published_at,
    first_turnaround_seconds, seconds_to_due_at_first_publish, sla_met
  )
  SELECT
    submission.id, 1, submission.rubric_version_id, 5, 8,
    'Synthetic published feedback for private QA access testing.',
    '88888888-8888-4888-8888-888888888888',
    now(), now(), 60, 86_000, true
  FROM public.assessment_submissions AS submission
  WHERE submission.id = current_setting('test.private_qa_submission_id')::uuid
  RETURNING id
)
SELECT set_config('test.private_qa_assessment_version_id', id::text, true)
FROM created_version;

SET LOCAL ROLE authenticated;
SELECT set_config('request.jwt.claim.sub', '11111111-1111-4111-8111-111111111111', true);
SELECT set_config('request.jwt.claims', '{"sub":"11111111-1111-4111-8111-111111111111","role":"authenticated","aal":"aal2"}', true);
SELECT throws_ok(
  $$SELECT * FROM public.get_private_qa_records(current_setting('test.private_qa_assessment_version_id')::uuid)$$,
  '42501', 'private_qa_forbidden',
  'student cannot read private QA records even at AAL2'
);
SELECT throws_ok(
  $$SELECT * FROM public.create_private_qa_record(
    current_setting('test.private_qa_assessment_version_id')::uuid,
    '{"rubric_alignment":true}',
    'passed', 'Synthetic QA explanation for denial test.', '', 'No change required.'
  )$$,
  '42501', 'private_qa_forbidden',
  'student cannot create private QA records'
);
RESET ROLE;

SET LOCAL ROLE authenticated;
SELECT set_config('request.jwt.claim.sub', '55555555-5555-4555-8555-555555555555', true);
SELECT set_config('request.jwt.claims', '{"sub":"55555555-5555-4555-8555-555555555555","role":"authenticated","aal":"aal2"}', true);
SELECT throws_ok(
  $$SELECT * FROM public.get_private_qa_records(current_setting('test.private_qa_assessment_version_id')::uuid)$$,
  '42501', 'private_qa_forbidden',
  'grader at AAL2 cannot read private QA records'
);
RESET ROLE;

-- A verified guardian link is intentionally insufficient for private academic QA.
SET LOCAL ROLE authenticated;
SELECT set_config('request.jwt.claim.sub', '33333333-3333-4333-8333-333333333333', true);
SELECT set_config('request.jwt.claims', '{"sub":"33333333-3333-4333-8333-333333333333","role":"authenticated","aal":"aal2"}', true);
SELECT throws_ok(
  $$SELECT * FROM public.get_private_qa_records(current_setting('test.private_qa_assessment_version_id')::uuid)$$,
  '42501', 'private_qa_forbidden',
  'verified linked guardian at AAL2 cannot read private academic-QA records'
);
SELECT throws_ok(
  $$SELECT * FROM public.create_private_qa_record(
    current_setting('test.private_qa_assessment_version_id')::uuid,
    '{"rubric_alignment":true}',
    'passed', 'Synthetic QA explanation for guardian denial test.', '',
    'Guardian access must not include private academic QA.'
  )$$,
  '42501', 'private_qa_forbidden',
  'verified linked guardian at AAL2 cannot create private academic-QA records'
);
RESET ROLE;

SET LOCAL ROLE authenticated;
SELECT set_config('request.jwt.claim.sub', '77777777-7777-4777-8777-777777777777', true);
SELECT set_config('request.jwt.claims', '{"sub":"77777777-7777-4777-8777-777777777777","role":"authenticated","aal":"aal2"}', true);
SELECT throws_ok(
  $$SELECT * FROM public.get_private_qa_records(current_setting('test.private_qa_assessment_version_id')::uuid)$$,
  '42501', 'private_qa_forbidden',
  'Admin at AAL2 cannot read private QA records'
);
SELECT throws_ok(
  $$SELECT * FROM public.create_private_qa_record(
    current_setting('test.private_qa_assessment_version_id')::uuid,
    '{"rubric_alignment":true}',
    'passed', 'Synthetic QA explanation for denial test.', '', 'No change required.'
  )$$,
  '42501', 'private_qa_forbidden',
  'Admin at AAL2 cannot create private QA records'
);
RESET ROLE;

SET LOCAL ROLE authenticated;
SELECT set_config('request.jwt.claim.sub', '88888888-8888-4888-8888-888888888888', true);
SELECT set_config('request.jwt.claims', '{"sub":"88888888-8888-4888-8888-888888888888","role":"authenticated","aal":"aal1"}', true);
SELECT throws_ok(
  $$SELECT * FROM public.get_private_qa_records(current_setting('test.private_qa_assessment_version_id')::uuid)$$,
  '42501', 'private_qa_forbidden',
  'Owner at AAL1 cannot read private QA records'
);
SELECT throws_ok(
  $$SELECT * FROM public.create_private_qa_record(
    current_setting('test.private_qa_assessment_version_id')::uuid,
    '{"rubric_alignment":true}',
    'passed', 'Synthetic QA explanation for denial test.', '', 'No change required.'
  )$$,
  '42501', 'private_qa_forbidden',
  'Owner at AAL1 cannot create private QA records'
);

SELECT set_config('request.jwt.claims', '{"sub":"88888888-8888-4888-8888-888888888888","role":"authenticated","aal":"aal2"}', true);
SELECT is(
  (SELECT qa_revision FROM public.create_private_qa_record(
    current_setting('test.private_qa_assessment_version_id')::uuid,
    '{"rubric_alignment":true,"assessment_accuracy":"checked","uncertainty":"none"}',
    'passed',
    'Synthetic QA checks confirm the published assessment uses the mapped rubric and preserves its version context.',
    'No material uncertainty identified in this synthetic review.',
    'No change required; retain the published human assessment.'
  )),
  1,
  'Owner AAL2 creates the first private QA revision through the protected RPC'
);
SELECT is(
  (SELECT qa_revision FROM public.create_private_qa_record(
    current_setting('test.private_qa_assessment_version_id')::uuid,
    '{"rubric_alignment":true,"assessment_accuracy":"checked","learner_visibility":"verified"}',
    'passed',
    'A second synthetic QA review records an additional visibility check without altering the prior review.',
    '',
    'Retain both QA revisions as the review history.'
  )),
  2,
  'a subsequent private QA review appends a new revision rather than overwriting the prior record'
);
SELECT is(
  (SELECT count(*)::integer FROM public.get_private_qa_records(
    current_setting('test.private_qa_assessment_version_id')::uuid
  )),
  2,
  'Owner AAL2 can read the complete private QA revision history through the protected RPC'
);
SELECT is(
  (SELECT qa_revision FROM public.get_private_qa_records(
    current_setting('test.private_qa_assessment_version_id')::uuid
  ) LIMIT 1),
  2,
  'private QA history is returned newest revision first'
);
RESET ROLE;
SELECT is(
  (SELECT count(*)::integer FROM private.private_qa_records
   WHERE assessment_version_id = current_setting('test.private_qa_assessment_version_id')::uuid),
  2,
  'two append-only private QA rows exist for the synthetic assessment version'
);
SELECT is(
  (SELECT count(*)::integer FROM private.security_audit_events
   WHERE action = 'private_qa_record_created'
     AND target_id = current_setting('test.private_qa_assessment_version_id')::uuid),
  2,
  'each QA revision creation is auditable without copying QA payload into the audit stream'
);
SELECT is(
  (SELECT count(*)::integer FROM private.security_audit_events
   WHERE action = 'private_qa_records_read'
     AND target_id = current_setting('test.private_qa_assessment_version_id')::uuid),
  2,
  'each privileged QA history read is auditable'
);
SELECT throws_ok(
  $$UPDATE private.private_qa_records SET status = 'action_required'
    WHERE assessment_version_id = current_setting('test.private_qa_assessment_version_id')::uuid$$,
  '42501', 'private QA records are append-only',
  'private QA records cannot be updated in place'
);
SELECT throws_ok(
  $$DELETE FROM private.private_qa_records
    WHERE assessment_version_id = current_setting('test.private_qa_assessment_version_id')::uuid$$,
  '42501', 'private QA records are append-only',
  'private QA history cannot be deleted'
);

SELECT is(
  (SELECT count(*)::integer FROM information_schema.columns
   WHERE table_schema = 'private'
     AND table_name = 'security_audit_events'
     AND column_name IN ('checks', 'explanation', 'uncertainty', 'reviewer_action')),
  0,
  'security audit rows contain no QA check, explanation or reviewer-action payload columns'
);

-- Phase 1C-E: denied and failed Owner-only private-QA history read outcomes.
SET LOCAL ROLE authenticated;
SELECT set_config('request.jwt.claim.sub', '11111111-1111-4111-8111-111111111111', true);
SELECT set_config('request.jwt.claims', '{"sub":"11111111-1111-4111-8111-111111111111","role":"authenticated","aal":"aal2"}', true);
SELECT set_config('request.headers', '{"x-request-id":"abababab-abab-4bab-8bab-abababababab"}', true);
SELECT ok(
  NOT public.audit_protected_read_outcome(
    'private_qa_records_read',
    current_setting('test.private_qa_assessment_version_id')::uuid,
    'success'
  ),
  'a learner cannot claim a successful Owner-only private-QA read'
);
RESET ROLE;
SELECT is(
  (SELECT count(*)::integer FROM private.security_audit_events
   WHERE actor_id = '11111111-1111-4111-8111-111111111111'
     AND action = 'private_qa_records_read'
     AND outcome = 'denied'
     AND reason_category = 'role_required'
     AND request_id = 'abababab-abab-4bab-8bab-abababababab'),
  1,
  'learner private-QA attempts are recorded as denied metadata'
);

SET LOCAL ROLE authenticated;
SELECT set_config('request.jwt.claim.sub', '88888888-8888-4888-8888-888888888888', true);
SELECT set_config('request.jwt.claims', '{"sub":"88888888-8888-4888-8888-888888888888","role":"authenticated","aal":"aal2"}', true);
SELECT set_config('request.headers', '{"x-request-id":"cdcdcdcd-cdcd-4dcd-8dcd-cdcdcdcdcdcd"}', true);
SELECT ok(
  public.audit_protected_read_outcome(
    'private_qa_records_read',
    current_setting('test.private_qa_assessment_version_id')::uuid,
    'failed'
  ),
  'Owner AAL2 can append a failed private-QA history read outcome'
);
RESET ROLE;
SELECT is(
  (SELECT count(*)::integer FROM private.security_audit_events
   WHERE actor_id = '88888888-8888-4888-8888-888888888888'
     AND action = 'private_qa_records_read'
     AND outcome = 'failed'
     AND reason_category = 'database_read_failed'
     AND target_type = 'assessment_version'
     AND request_id = 'cdcdcdcd-cdcd-4dcd-8dcd-cdcdcdcdcdcd'),
  1,
  'failed private-QA reads keep actor/request context and no QA payload'
);

SELECT * FROM finish();
ROLLBACK;
