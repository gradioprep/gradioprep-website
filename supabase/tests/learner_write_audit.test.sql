BEGIN;
SELECT no_plan();

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
  public.audit_privileged_write_outcome(
    'student_attempt_create',
    'a1111111-1111-4111-8111-111111111111',
    'failed',
    'operation_failed'
  ),
  'student can record an attempt-creation failure for their enrolled published task'
);
SELECT ok(
  public.audit_privileged_write_outcome(
    'student_attempt_response_save',
    'c1111111-1111-4111-8111-111111111111',
    'failed',
    'state_conflict'
  ),
  'student can record a response-save conflict on their own attempt'
);
SELECT ok(
  public.audit_privileged_write_outcome(
    'student_attempt_submit',
    'c1111111-1111-4111-8111-111111111111',
    'failed',
    'state_conflict'
  ),
  'student can record a submit conflict on their own attempt'
);
SELECT ok(
  public.audit_privileged_write_outcome(
    'student_assessment_submission_accept',
    'a1111111-1111-4111-8111-111111111111',
    'failed',
    'capacity_unavailable'
  ),
  'student can record a capacity failure for their enrolled published assessment task'
);
RESET ROLE;

SELECT is(
  (SELECT count(*)::integer
   FROM private.security_audit_events
   WHERE actor_id = '11111111-1111-4111-8111-111111111111'
     AND request_id = 'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa'
     AND outcome = 'failed'),
  4,
  'all four learner write failures retain their outcome and request context'
);

SET LOCAL ROLE authenticated;
SELECT set_config('request.jwt.claim.sub', '11111111-1111-4111-8111-111111111111', true);
SELECT set_config(
  'request.jwt.claims',
  '{"sub":"11111111-1111-4111-8111-111111111111","role":"authenticated","aal":"aal1"}',
  true
);
SELECT set_config(
  'request.headers',
  '{"x-request-id":"bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbbb"}',
  true
);
SELECT ok(
  public.audit_privileged_write_outcome(
    'student_attempt_response_save',
    'c2222222-2222-4222-8222-222222222222',
    'failed',
    'state_conflict'
  ),
  'learner cannot log a failed write against another student attempt'
);
SELECT ok(
  public.audit_privileged_write_outcome(
    'student_attempt_create',
    'a2222222-2222-4222-8222-222222222222',
    'failed',
    'operation_failed'
  ),
  'learner cannot log an attempt create for a pathway without enrolment'
);
RESET ROLE;
SELECT is(
  (SELECT count(*)::integer
   FROM private.security_audit_events
   WHERE actor_id = '11111111-1111-4111-8111-111111111111'
     AND request_id = 'bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbbb'
     AND outcome = 'denied'
     AND reason_category = 'resource_scope_denied'),
  2,
  'cross-learner and unenrolled task writes are retained as denials'
);

SET LOCAL ROLE authenticated;
SELECT set_config('request.jwt.claim.sub', '88888888-8888-4888-8888-888888888888', true);
SELECT set_config(
  'request.jwt.claims',
  '{"sub":"88888888-8888-4888-8888-888888888888","role":"authenticated","aal":"aal2"}',
  true
);
SELECT ok(
  public.audit_privileged_write_outcome(
    'student_attempt_submit',
    'c1111111-1111-4111-8111-111111111111',
    'failed',
    'state_conflict'
  ),
  'Owner cannot record a learner-attributed attempt failure'
);
RESET ROLE;

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
  NOT public.audit_privileged_write_outcome(
    'student_attempt_submit',
    'c1111111-1111-4111-8111-111111111111',
    'denied',
    NULL
  ),
  'an authorised learner cannot forge a Worker-denial event through the browser-callable audit RPC'
);
RESET ROLE;
SELECT is(
  (SELECT count(*)::integer
   FROM private.security_audit_events
   WHERE actor_id = '11111111-1111-4111-8111-111111111111'
     AND action = 'student_attempt_submit'
     AND target_id = 'c1111111-1111-4111-8111-111111111111'
     AND outcome = 'denied'
     AND request_id = 'cccccccc-cccc-4ccc-8ccc-cccccccccccc'),
  0,
  'authorised callers cannot create false denied audit events for their own valid operations'
);

SET LOCAL ROLE authenticated;
SELECT set_config('request.jwt.claim.sub', '11111111-1111-4111-8111-111111111111', true);
SELECT set_config(
  'request.jwt.claims',
  '{"sub":"11111111-1111-4111-8111-111111111111","role":"authenticated","aal":"aal1"}',
  true
);
SELECT throws_ok(
  $$SELECT public.audit_privileged_write_outcome(
    'student_attempt_submit',
    'c1111111-1111-4111-8111-111111111111',
    'failed',
    'raw SQL error supplied by a client'
  )$$,
  '22023',
  'invalid_privileged_write_failure_category',
  'arbitrary failure details are not copied into audit records'
);
RESET ROLE;

SELECT * FROM finish();
ROLLBACK;
