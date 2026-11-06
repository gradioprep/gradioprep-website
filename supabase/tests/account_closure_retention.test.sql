BEGIN;
SELECT plan(42);

SELECT ok(
  (SELECT relrowsecurity FROM pg_class WHERE oid = 'private.retention_items'::regclass),
  'retention inventory has RLS enabled'
);
SELECT ok(
  (SELECT relrowsecurity FROM pg_class WHERE oid = 'private.retention_backup_objects'::regclass),
  'backup-expiry inventory has RLS enabled'
);
SELECT ok(
  NOT has_table_privilege('authenticated', 'private.retention_items', 'SELECT'),
  'browser roles cannot directly read retention items'
);
SELECT ok(
  NOT has_table_privilege('service_role', 'private.retention_items', 'SELECT'),
  'Worker service role cannot bypass the retention-plan RPC'
);
SELECT ok(
  NOT has_table_privilege('authenticated', 'private.retention_backup_objects', 'SELECT'),
  'browser roles cannot directly read backup references'
);
SELECT ok(
  NOT has_table_privilege('service_role', 'private.retention_backup_objects', 'INSERT'),
  'Worker service role cannot invent backup references'
);
SELECT ok(
  NOT has_function_privilege('anon', 'public.close_account_for_deletion(uuid)', 'EXECUTE'),
  'anonymous users cannot close accounts'
);
SELECT ok(
  has_function_privilege('authenticated', 'public.close_account_for_deletion(uuid)', 'EXECUTE'),
  'authenticated role can invoke the Owner-protected closure RPC'
);
SELECT ok(
  NOT has_function_privilege('service_role', 'public.close_account_for_deletion(uuid)', 'EXECUTE'),
  'service role cannot impersonate the Owner closure decision'
);
SELECT ok(
  NOT has_function_privilege('anon', 'public.list_account_retention_plan(uuid)', 'EXECUTE'),
  'anonymous users cannot inspect retention schedules'
);

CREATE TEMP TABLE closure_request_context (
  request_id uuid,
  request_status text,
  requested_at timestamptz,
  response_due_at timestamptz,
  is_replay boolean
);
GRANT SELECT, INSERT ON closure_request_context TO authenticated;

SET LOCAL ROLE authenticated;
SELECT set_config(
  'request.jwt.claims',
  '{"sub":"11111111-1111-4111-8111-111111111111","role":"authenticated","aal":"aal1"}',
  true
);
INSERT INTO closure_request_context
SELECT request_id, request_status, requested_at, response_due_at, is_replay
FROM public.request_account_deletion('account_closure');
RESET ROLE;

-- The test fixtures are intentionally synthetic and are rolled back below.
INSERT INTO public.assessment_submissions (
  id, learner_id, task_version_id, rubric_version_id, status,
  accepted_at, grading_due_at, sla_target_seconds,
  capacity_config_version, capacity_limit_snapshot,
  open_submissions_before_acceptance, idempotency_key
)
VALUES (
  'eeeeeeee-eeee-4eee-8eee-eeeeeeeeeee1',
  '11111111-1111-4111-8111-111111111111',
  'a1111111-1111-4111-8111-111111111111',
  'f1111111-1111-4111-8111-111111111111',
  'feedback_published',
  clock_timestamp() - interval '2 hours',
  clock_timestamp() + interval '22 hours',
  86400, 1, 10, 0,
  'eeeeeeee-eeee-4eee-8eee-eeeeeeeeeee2'
);

INSERT INTO public.submission_versions (
  id, submission_id, version_number, response_text, created_by
)
VALUES (
  'eeeeeeee-eeee-4eee-8eee-eeeeeeeeeee3',
  'eeeeeeee-eeee-4eee-8eee-eeeeeeeeeee1',
  1,
  'Synthetic accepted response retained under the source-content policy.',
  '11111111-1111-4111-8111-111111111111'
);

INSERT INTO public.assessment_versions (
  id, submission_id, version_number, rubric_version_id,
  total_points, max_points, overall_feedback, published_by,
  published_at, first_published_at, first_turnaround_seconds,
  seconds_to_due_at_first_publish, sla_met
)
VALUES (
  'eeeeeeee-eeee-4eee-8eee-eeeeeeeeeee4',
  'eeeeeeee-eeee-4eee-8eee-eeeeeeeeeee1',
  1,
  'f1111111-1111-4111-8111-111111111111',
  6, 8,
  'Synthetic published feedback retained for the approved period.',
  '88888888-8888-4888-8888-888888888888',
  clock_timestamp() - interval '1 hour',
  clock_timestamp() - interval '1 hour',
  3600, 3600, true
);

INSERT INTO public.criterion_results (
  id, assessment_version_id, rubric_criterion_id,
  criterion_code_snapshot, criterion_title_snapshot, descriptor_snapshot,
  points_awarded, max_points_snapshot, feedback
)
VALUES (
  'eeeeeeee-eeee-4eee-8eee-eeeeeeeeeee5',
  'eeeeeeee-eeee-4eee-8eee-eeeeeeeeeee4',
  'f3333333-3333-4333-8333-333333333333',
  'evidence', 'Use of evidence',
  'Selects relevant details and integrates them accurately.',
  3, 4, 'Synthetic criterion feedback with a retained source reference.'
);

-- Insert one disposable session and MFA factor so closure verifies that they
-- are expired/deactivated without deleting the account's historical records.
INSERT INTO auth.sessions (id, user_id, created_at, updated_at, not_after)
VALUES (
  'eeeeeeee-eeee-4eee-8eee-eeeeeeeeeee6',
  '11111111-1111-4111-8111-111111111111',
  clock_timestamp(), clock_timestamp(), NULL
);
INSERT INTO auth.mfa_factors (
  id, user_id, friendly_name, factor_type, status, created_at, updated_at, secret
)
VALUES (
  'eeeeeeee-eeee-4eee-8eee-eeeeeeeeeee7',
  '11111111-1111-4111-8111-111111111111',
  'Synthetic test factor', 'totp', 'verified',
  clock_timestamp(), clock_timestamp(), 'synthetic-secret-not-real'
);

CREATE TEMP TABLE closure_execution_context (
  request_id uuid,
  account_closed_at timestamptz,
  retention_items_created integer,
  is_replay boolean
);
GRANT SELECT, INSERT ON closure_execution_context TO authenticated;

SET LOCAL ROLE authenticated;
SELECT set_config(
  'request.jwt.claims',
  '{"sub":"88888888-8888-4888-8888-888888888888","role":"authenticated","aal":"aal2"}',
  true
);

SELECT is(
  (SELECT public.place_account_deletion_legal_hold(
    request_id,
    'court_order',
    'SYNTHETIC-CLOSURE-01',
    'Synthetic closure legal hold to test the protected close path',
    clock_timestamp() + interval '30 days'
  ) IS NOT NULL FROM closure_request_context LIMIT 1),
  true,
  'Owner AAL2 can place a legal hold before closure'
);

SELECT throws_ok(
  format(
    'SELECT * FROM public.close_account_for_deletion(%L)',
    (SELECT request_id FROM closure_request_context LIMIT 1)
  ),
  'P0001',
  'account_deletion_request_on_legal_hold',
  'active legal hold blocks account closure'
);

SELECT is(
  public.release_account_deletion_legal_hold(
    (SELECT id FROM private.account_deletion_legal_holds
     WHERE request_id = (SELECT request_id FROM closure_request_context LIMIT 1)
       AND released_at IS NULL),
    'review_cleared'
  ),
  true,
  'Owner AAL2 can release the synthetic legal hold with a reason'
);

SELECT is(
  public.review_account_deletion_request(
    (SELECT request_id FROM closure_request_context LIMIT 1),
    'approve',
    'retention_review_complete'
  ),
  'approved'::text,
  'Owner AAL2 approves closure after the hold is released'
);

INSERT INTO closure_execution_context
SELECT request_id, account_closed_at, retention_items_created, is_replay
FROM public.close_account_for_deletion(
  (SELECT request_id FROM closure_request_context LIMIT 1)
);

SELECT is(
  (SELECT is_replay FROM closure_execution_context),
  false,
  'first closure execution is recorded as a new operation'
);
SELECT ok(
  (SELECT retention_items_created >= 7 FROM closure_execution_context),
  'closure creates a retention item for each seeded and synthetic source record'
);
SELECT ok(
  (SELECT account_closed_at IS NOT NULL FROM closure_execution_context),
  'closure records its timestamp'
);

INSERT INTO closure_execution_context
SELECT request_id, account_closed_at, retention_items_created, is_replay
FROM public.close_account_for_deletion(
  (SELECT request_id FROM closure_request_context LIMIT 1)
);

SELECT ok(
  (SELECT is_replay FROM closure_execution_context ORDER BY is_replay DESC LIMIT 1),
  'repeated closure call is idempotent and does not rebuild the retention plan'
);
SELECT is(
  (SELECT count(*)::integer
   FROM public.list_account_retention_plan(
     (SELECT request_id FROM closure_request_context LIMIT 1)
   )),
  (SELECT retention_items_created
   FROM closure_execution_context
   WHERE is_replay = false),
  'Owner retention plan returns exactly the closure inventory count'
);

SELECT is(
  (SELECT count(*)::integer
   FROM public.list_account_retention_plan(
     (SELECT request_id FROM closure_request_context LIMIT 1)
   )
   WHERE source_table = 'attempts'
     AND retention_class = 'timer_event_12m'
     AND eligible_after = source_end_event_at + interval '12 months'),
  2,
  'attempt/timer records use their own 12-month retention clock'
);
SELECT is(
  (SELECT count(*)::integer
   FROM public.list_account_retention_plan(
     (SELECT request_id FROM closure_request_context LIMIT 1)
   )
   WHERE source_table = 'attempt_responses'
     AND retention_class = 'source_content_12m'
     AND eligible_after = source_end_event_at + interval '12 months'),
  1,
  'typed attempt responses receive the source-content 12-month schedule'
);
SELECT is(
  (SELECT count(*)::integer
   FROM public.list_account_retention_plan(
     (SELECT request_id FROM closure_request_context LIMIT 1)
   )
   WHERE source_table = 'assessment_versions'
     AND retention_class = 'feedback_history_24m'
     AND eligible_after = source_end_event_at + interval '24 months'),
  1,
  'published feedback receives the 24-month retention schedule'
);
SELECT is(
  (SELECT count(*)::integer
   FROM public.list_account_retention_plan(
     (SELECT request_id FROM closure_request_context LIMIT 1)
   )
   WHERE source_table = 'criterion_results'
     AND retention_class = 'feedback_history_24m'
     AND eligible_after = source_end_event_at + interval '24 months'),
  1,
  'published rubric outcomes receive the 24-month retention schedule'
);

RESET ROLE;

SELECT is(
  (SELECT account_status::text FROM public.profiles
   WHERE user_id = '11111111-1111-4111-8111-111111111111'),
  'closed',
  'account closure disables the application profile'
);
SELECT is(
  (SELECT display_name FROM public.profiles
   WHERE user_id = '11111111-1111-4111-8111-111111111111'),
  'Closed account'::text,
  'account closure removes the learner display name from the active profile'
);
SELECT is(
  (SELECT count(*)::integer FROM public.role_assignments
   WHERE user_id = '11111111-1111-4111-8111-111111111111'
     AND revoked_at IS NULL),
  0,
  'all application roles are revoked at account closure'
);
SELECT is(
  (SELECT status::text FROM public.guardian_learner_links
   WHERE guardian_id = '33333333-3333-4333-8333-333333333333'
     AND learner_id = '11111111-1111-4111-8111-111111111111'),
  'revoked',
  'guardian access is revoked when the learner account closes'
);
SELECT is(
  (SELECT status::text FROM public.course_enrolments
   WHERE learner_id = '11111111-1111-4111-8111-111111111111'
     AND pathway_id = 'synthetic-ib-myp-year-4'),
  'withdrawn',
  'active enrolment is converted to an administrative withdrawal'
);
SELECT ok(
  (SELECT ends_at IS NOT NULL FROM public.course_enrolments
   WHERE learner_id = '11111111-1111-4111-8111-111111111111'
     AND pathway_id = 'synthetic-ib-myp-year-4'),
  'administrative closure records the course-end event used by retention dates'
);
SELECT is(
  (SELECT status FROM public.assessment_submissions
   WHERE id = 'eeeeeeee-eeee-4eee-8eee-eeeeeeeeeee1'),
  'closed'::text,
  'published assessment work is closed through the existing submission lifecycle RPC'
);
SELECT ok(
  (SELECT email LIKE 'closed+11111111111141118111111111111111@invalid.invalid'
          AND email_confirmed_at IS NULL
          AND encrypted_password = ''
          AND banned_until > clock_timestamp()
   FROM auth.users
   WHERE id = '11111111-1111-4111-8111-111111111111'),
  'Auth sign-in identifier is replaced, credentials are cleared and sign-in is banned'
);
SELECT ok(
  (SELECT identity_data = '{}'::jsonb AND provider_id LIKE 'closed-%'
   FROM auth.identities
   WHERE user_id = '11111111-1111-4111-8111-111111111111'
   LIMIT 1),
  'Auth identity metadata is de-identified rather than deleting the retained user row'
);
SELECT ok(
  (SELECT not_after <= clock_timestamp()
   FROM auth.sessions
   WHERE id = 'eeeeeeee-eeee-4eee-8eee-eeeeeeeeeee6'),
  'existing Auth session is expired for refresh after account closure'
);
SELECT ok(
  (SELECT secret IS NULL AND status = 'unverified'
   FROM auth.mfa_factors
   WHERE id = 'eeeeeeee-eeee-4eee-8eee-eeeeeeeeeee7'),
  'MFA secret is cleared and the factor is deactivated'
);
SELECT ok(
  EXISTS (SELECT 1 FROM auth.users
          WHERE id = '11111111-1111-4111-8111-111111111111'),
  'Auth user UUID remains so retained academic records keep referential integrity'
);

SELECT ok(
  EXISTS (SELECT 1 FROM public.attempt_responses
          WHERE attempt_id = 'c1111111-1111-4111-8111-111111111111'),
  'source learning content is retained rather than prematurely erased'
);
SELECT ok(
  EXISTS (SELECT 1 FROM public.submission_versions
          WHERE submission_id = 'eeeeeeee-eeee-4eee-8eee-eeeeeeeeeee1'),
  'typed submission versions remain intact through the approved retention period'
);
SELECT ok(
  EXISTS (SELECT 1 FROM public.assessment_versions
          WHERE id = 'eeeeeeee-eeee-4eee-8eee-eeeeeeeeeee4'),
  'published feedback remains intact through the approved retention period'
);

-- Add a synthetic off-site copy reference to verify that source deletion starts
-- an exact 30-day expiry window. No R2 bucket/service is provisioned by this test.
INSERT INTO private.retention_items (
  deletion_request_id, subject_user_id, source_schema, source_table,
  source_record_id, retention_class, source_end_event_at, eligible_after
)
VALUES (
  (SELECT request_id FROM closure_request_context LIMIT 1),
  '11111111-1111-4111-8111-111111111111',
  'public', 'attempts',
  'eeeeeeee-eeee-4eee-8eee-eeeeeeeeeee8',
  'timer_event_12m',
  '2024-01-01T00:00:00Z',
  '2025-01-01T00:00:00Z'
);

INSERT INTO private.retention_backup_objects (
  retention_item_id, backup_provider, backup_object_ref
)
SELECT item.id, 'cloudflare_r2', 'synthetic-local-only/' || item.id::text
FROM private.retention_items AS item
WHERE item.deletion_request_id = (SELECT request_id FROM closure_request_context LIMIT 1)
  AND item.source_record_id = 'eeeeeeee-eeee-4eee-8eee-eeeeeeeeeee8';

UPDATE private.retention_items
SET state = 'claimed', claimed_at = clock_timestamp()
WHERE source_record_id = 'eeeeeeee-eeee-4eee-8eee-eeeeeeeeeee8'
  AND deletion_request_id = (SELECT request_id FROM closure_request_context LIMIT 1);
UPDATE private.retention_items
SET state = 'deleted', deleted_at = clock_timestamp()
WHERE source_record_id = 'eeeeeeee-eeee-4eee-8eee-eeeeeeeeeee8'
  AND deletion_request_id = (SELECT request_id FROM closure_request_context LIMIT 1);

SELECT is(
  (SELECT state FROM private.retention_backup_objects
   WHERE backup_object_ref LIKE 'synthetic-local-only/%'),
  'expiry_due'::text,
  'source deletion moves its off-site copy into expiry due'
);
SELECT ok(
  (SELECT expires_at = source_deleted_at + interval '30 days'
   FROM private.retention_backup_objects
   WHERE backup_object_ref LIKE 'synthetic-local-only/%'),
  'off-site backup expires no later than 30 days after source deletion'
);

SELECT is(
  (SELECT status FROM private.account_deletion_requests
   WHERE id = (SELECT request_id FROM closure_request_context LIMIT 1)),
  'executing'::text,
  'closure remains executing while retained records and backup copies await expiry'
);
SELECT ok(
  (SELECT closure_executed_at IS NOT NULL AND retention_items_created >= 7
   FROM private.account_deletion_requests
   WHERE id = (SELECT request_id FROM closure_request_context LIMIT 1)),
  'minimal closure evidence and retention inventory count are retained'
);

SELECT * FROM finish();
ROLLBACK;
