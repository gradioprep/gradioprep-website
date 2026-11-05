BEGIN;
SELECT no_plan();

SELECT has_column(
  'private', 'security_audit_events', 'actor_roles',
  'private audit events store a server-derived active-role snapshot'
);
SELECT has_column(
  'private', 'security_audit_events', 'request_id',
  'private audit events store a request correlation UUID'
);
SELECT has_column(
  'private', 'security_audit_events', 'transaction_id',
  'private audit events store the PostgreSQL transaction identifier'
);

-- Student list operations use a Worker-generated request ID. Their role
-- snapshot is read from active database role assignments, not JWT metadata.
SET LOCAL ROLE authenticated;
SELECT set_config('request.jwt.claim.sub', '11111111-1111-4111-8111-111111111111', true);
SELECT set_config(
  'request.jwt.claims',
  '{"sub":"11111111-1111-4111-8111-111111111111","role":"authenticated","aal":"aal1"}',
  true
);
SELECT set_config(
  'request.headers',
  '{"x-request-id":"aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa"}',
  true
);
SELECT ok(
  public.audit_authorized_protected_read('student_attempt_list_authorized', NULL),
  'an active student can record an authorized attempt-list read'
);
SELECT ok(
  public.audit_authorized_protected_read('student_submission_list_authorized', NULL),
  'an active student can record an authorized submission-list read'
);
RESET ROLE;

SELECT is(
  (SELECT count(*)::integer
   FROM private.security_audit_events
   WHERE actor_id = '11111111-1111-4111-8111-111111111111'
     AND request_id = 'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa'),
  2,
  'all audit events from one Worker request retain its correlation UUID'
);
SELECT ok(
  (SELECT bool_and(actor_roles @> ARRAY['student'::public.app_role])
   FROM private.security_audit_events
   WHERE actor_id = '11111111-1111-4111-8111-111111111111'
     AND request_id = 'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa'),
  'audit actor roles are derived from active database role assignments'
);
SELECT is(
  (SELECT count(DISTINCT transaction_id)::integer
   FROM private.security_audit_events
   WHERE request_id = 'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa'),
  1,
  'audit events written in the same database transaction share its transaction ID'
);

-- Owner and Admin share AAL2 but the snapshot must retain their distinct
-- application roles; the correlation ID is independent of authorization.
SET LOCAL ROLE authenticated;
SELECT set_config('request.jwt.claim.sub', '88888888-8888-4888-8888-888888888888', true);
SELECT set_config(
  'request.jwt.claims',
  '{"sub":"88888888-8888-4888-8888-888888888888","role":"authenticated","aal":"aal2"}',
  true
);
SELECT set_config(
  'request.headers',
  '{"x-request-id":"bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbbb"}',
  true
);
SELECT ok(
  public.audit_authorized_protected_read('owner_submission_queue_authorized', NULL),
  'an active Owner at AAL2 can record an authorized protected queue read'
);
RESET ROLE;

SELECT ok(
  (SELECT actor_roles @> ARRAY['owner'::public.app_role]
          AND transaction_id IS NOT NULL
   FROM private.security_audit_events
   WHERE request_id = 'bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbbb'
   LIMIT 1),
  'Owner audit events record the Owner role and a database transaction ID'
);

-- Invalid caller-supplied correlation text cannot be stored as an ID. The
-- trigger generates a valid UUID while preserving the database actor snapshot.
SET LOCAL ROLE authenticated;
SELECT set_config('request.jwt.claim.sub', '11111111-1111-4111-8111-111111111111', true);
SELECT set_config(
  'request.jwt.claims',
  '{"sub":"11111111-1111-4111-8111-111111111111","role":"authenticated","aal":"aal1"}',
  true
);
SELECT set_config(
  'request.headers',
  '{"x-request-id":"not-a-uuid"}',
  true
);
SELECT ok(
  public.audit_authorized_protected_read('student_attempt_list_authorized', NULL),
  'an invalid correlation header does not prevent a valid protected read'
);
RESET ROLE;

SELECT is(
  (SELECT count(*)::integer
   FROM private.security_audit_events
   WHERE actor_id = '11111111-1111-4111-8111-111111111111'
     AND action = 'student_attempt_list_authorized'
     AND request_id IS NOT NULL
     AND request_id <> 'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa'),
  1,
  'an invalid or absent correlation header is replaced with a database-generated UUID'
);

-- Context enrichment does not widen access to the private audit table.
SET LOCAL ROLE authenticated;
SELECT set_config('request.jwt.claim.sub', '11111111-1111-4111-8111-111111111111', true);
SELECT set_config(
  'request.jwt.claims',
  '{"sub":"11111111-1111-4111-8111-111111111111","role":"authenticated","aal":"aal1"}',
  true
);
SELECT throws_ok(
  $$SELECT * FROM private.security_audit_events$$,
  '42501', NULL,
  'authenticated users still cannot read the private audit table directly'
);
RESET ROLE;


-- The outcome parameter is required and arbitrary actions remain rejected.
SET LOCAL ROLE authenticated;
SELECT set_config('request.jwt.claim.sub', '11111111-1111-4111-8111-111111111111', true);
SELECT set_config(
  'request.jwt.claims',
  '{"sub":"11111111-1111-4111-8111-111111111111","role":"authenticated","aal":"aal1"}',
  true
);
SELECT ok(
  NOT public.audit_protected_read_outcome('student_attempt_list_authorized', NULL, NULL),
  'a null audit outcome is rejected'
);
SELECT ok(
  NOT public.audit_protected_read_outcome('arbitrary_protected_read', NULL, 'success'),
  'an unknown protected-read action is rejected'
);
RESET ROLE;

-- A database read that fails after authorization is recorded as failed, not success.
SET LOCAL ROLE authenticated;
SELECT set_config('request.jwt.claim.sub', '11111111-1111-4111-8111-111111111111', true);
SELECT set_config(
  'request.jwt.claims',
  '{"sub":"11111111-1111-4111-8111-111111111111","role":"authenticated","aal":"aal1"}',
  true
);
SELECT set_config(
  'request.headers',
  '{"x-request-id":"cccccccc-cccc-4ccc-8ccc-cccccccccccc"}',
  true
);
SELECT ok(
  public.audit_protected_read_outcome('student_attempt_list_authorized', NULL, 'failed'),
  'an authorised student read failure is recorded as a failed outcome'
);
RESET ROLE;
SELECT is(
  (SELECT count(*)::integer
   FROM private.security_audit_events
   WHERE actor_id = '11111111-1111-4111-8111-111111111111'
     AND action = 'student_attempt_list_authorized'
     AND outcome = 'failed'
     AND reason_category = 'database_read_failed'
     AND request_id = 'cccccccc-cccc-4ccc-8ccc-cccccccccccc'),
  1,
  'failed read audit records retain actor, request, transaction and safe reason metadata'
);

-- Cross-learner access is recorded as denied even when the Worker read returned no row.
SET LOCAL ROLE authenticated;
SELECT set_config('request.jwt.claim.sub', '11111111-1111-4111-8111-111111111111', true);
SELECT set_config(
  'request.jwt.claims',
  '{"sub":"11111111-1111-4111-8111-111111111111","role":"authenticated","aal":"aal1"}',
  true
);
SELECT set_config(
  'request.headers',
  '{"x-request-id":"dddddddd-dddd-4ddd-8ddd-dddddddddddd"}',
  true
);
SELECT ok(
  NOT public.audit_protected_read_outcome(
    'student_attempt_read_authorized',
    'c2222222-2222-4222-8222-222222222222',
    'success'
  ),
  'a student cannot mark another learner attempt read as successful'
);
RESET ROLE;
SELECT is(
  (SELECT count(*)::integer
   FROM private.security_audit_events
   WHERE actor_id = '11111111-1111-4111-8111-111111111111'
     AND action = 'student_attempt_read_authorized'
     AND target_id = 'c2222222-2222-4222-8222-222222222222'
     AND outcome = 'denied'
     AND reason_category = 'resource_scope_denied'
     AND request_id = 'dddddddd-dddd-4ddd-8ddd-dddddddddddd'),
  1,
  'cross-learner read denial is retained without learner-content data'
);

-- A grader at AAL1 is denied at the database boundary and cannot be logged as failed.
SET LOCAL ROLE authenticated;
SELECT set_config('request.jwt.claim.sub', '55555555-5555-4555-8555-555555555555', true);
SELECT set_config(
  'request.jwt.claims',
  '{"sub":"55555555-5555-4555-8555-555555555555","role":"authenticated","aal":"aal1"}',
  true
);
SELECT set_config(
  'request.headers',
  '{"x-request-id":"eeeeeeee-eeee-4eee-8eee-eeeeeeeeeeee"}',
  true
);
SELECT ok(
  NOT public.audit_protected_read_outcome(
    'grader_submission_queue_authorized', NULL, 'failed'
  ),
  'a grader at AAL1 is denied rather than recorded as an authorised query failure'
);
RESET ROLE;
SELECT is(
  (SELECT count(*)::integer
   FROM private.security_audit_events
   WHERE actor_id = '55555555-5555-4555-8555-555555555555'
     AND action = 'grader_submission_queue_authorized'
     AND outcome = 'denied'
     AND reason_category = 'aal2_required'
     AND request_id = 'eeeeeeee-eeee-4eee-8eee-eeeeeeeeeeee'),
  1,
  'AAL2 denials are recorded distinctly from authorised query failures'
);

SELECT * FROM finish();
ROLLBACK;
