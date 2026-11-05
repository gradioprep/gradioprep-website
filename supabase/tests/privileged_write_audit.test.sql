BEGIN;
SELECT no_plan();

SELECT ok(
  NOT has_function_privilege(
    'anon',
    'public.audit_privileged_write_outcome(text,uuid,text,text)',
    'EXECUTE'
  ),
  'anonymous callers cannot invoke the privileged write audit RPC'
);
SELECT ok(
  has_function_privilege(
    'authenticated',
    'public.audit_privileged_write_outcome(text,uuid,text,text)',
    'EXECUTE'
  ),
  'authenticated callers can invoke only the allowlisted privileged write audit RPC'
);

-- A student cannot label an Owner operation as an authorised failure.
SET LOCAL ROLE authenticated;
SELECT set_config('request.jwt.claim.sub', '11111111-1111-4111-8111-111111111111', true);
SELECT set_config(
  'request.jwt.claims',
  '{"sub":"11111111-1111-4111-8111-111111111111","role":"authenticated","aal":"aal2"}',
  true
);
SELECT set_config(
  'request.headers',
  '{"x-request-id":"11111111-1111-4111-8111-111111111111"}',
  true
);
SELECT ok(
  NOT public.audit_privileged_write_outcome(
    'owner_submission_transition',
    'd3333333-3333-4333-8333-333333333333',
    'failed',
    'state_conflict'
  ),
  'a student is denied when attempting to record an Owner-only write failure'
);
RESET ROLE;
SELECT is(
  (SELECT count(*)::integer
   FROM private.security_audit_events
   WHERE actor_id = '11111111-1111-4111-8111-111111111111'
     AND action = 'owner_submission_transition'
     AND target_id = 'd3333333-3333-4333-8333-333333333333'
     AND outcome = 'denied'
     AND reason_category = 'role_required'
     AND actor_roles @> ARRAY['student'::public.app_role]
     AND request_id = '11111111-1111-4111-8111-111111111111'
     AND transaction_id IS NOT NULL),
  1,
  'unauthorised Owner-write attempts are recorded with database-derived role and request context'
);

-- Owner at AAL1 is recorded as denied, even if the Worker called the operation.
SET LOCAL ROLE authenticated;
SELECT set_config('request.jwt.claim.sub', '88888888-8888-4888-8888-888888888888', true);
SELECT set_config(
  'request.jwt.claims',
  '{"sub":"88888888-8888-4888-8888-888888888888","role":"authenticated","aal":"aal1"}',
  true
);
SELECT set_config(
  'request.headers',
  '{"x-request-id":"22222222-2222-4222-8222-222222222222"}',
  true
);
SELECT ok(
  NOT public.audit_privileged_write_outcome(
    'owner_submission_transition',
    'd3333333-3333-4333-8333-333333333333',
    'failed',
    'state_conflict'
  ),
  'Owner at AAL1 cannot be recorded as an authorised write failure'
);
RESET ROLE;
SELECT is(
  (SELECT count(*)::integer
   FROM private.security_audit_events
   WHERE actor_id = '88888888-8888-4888-8888-888888888888'
     AND action = 'owner_submission_transition'
     AND target_id = 'd3333333-3333-4333-8333-333333333333'
     AND outcome = 'denied'
     AND reason_category = 'aal2_required'
     AND request_id = '22222222-2222-4222-8222-222222222222'),
  1,
  'Owner AAL2 denials are distinguished from authorised operation failures'
);

-- An Owner at AAL2 may record a safe failure category after its write RPC fails.
SET LOCAL ROLE authenticated;
SELECT set_config('request.jwt.claim.sub', '88888888-8888-4888-8888-888888888888', true);
SELECT set_config(
  'request.jwt.claims',
  '{"sub":"88888888-8888-4888-8888-888888888888","role":"authenticated","aal":"aal2"}',
  true
);
SELECT set_config(
  'request.headers',
  '{"x-request-id":"33333333-3333-4333-8333-333333333333"}',
  true
);
SELECT ok(
  public.audit_privileged_write_outcome(
    'owner_submission_transition',
    'd3333333-3333-4333-8333-333333333333',
    'failed',
    'state_conflict'
  ),
  'Owner at AAL2 can record an authorised transition failure'
);
RESET ROLE;
SELECT is(
  (SELECT count(*)::integer
   FROM private.security_audit_events
   WHERE actor_id = '88888888-8888-4888-8888-888888888888'
     AND action = 'owner_submission_transition'
     AND target_id = 'd3333333-3333-4333-8333-333333333333'
     AND outcome = 'failed'
     AND reason_category = 'state_conflict'
     AND actor_roles @> ARRAY['owner'::public.app_role]
     AND request_id = '33333333-3333-4333-8333-333333333333'),
  1,
  'authorised Owner failures are recorded with a safe failure class and correlation context'
);

-- Admin AAL2 does not inherit Owner authority.
SET LOCAL ROLE authenticated;
SELECT set_config('request.jwt.claim.sub', '77777777-7777-4777-8777-777777777777', true);
SELECT set_config(
  'request.jwt.claims',
  '{"sub":"77777777-7777-4777-8777-777777777777","role":"authenticated","aal":"aal2"}',
  true
);
SELECT set_config(
  'request.headers',
  '{"x-request-id":"44444444-4444-4444-8444-444444444444"}',
  true
);
SELECT ok(
  NOT public.audit_privileged_write_outcome(
    'owner_attempt_assignment',
    'c1111111-1111-4111-8111-111111111111',
    'denied',
    NULL
  ),
  'Admin at AAL2 cannot create an Owner-attributed denial for an Owner operation'
);
RESET ROLE;
SELECT is(
  (SELECT count(*)::integer
   FROM private.security_audit_events
   WHERE actor_id = '77777777-7777-4777-8777-777777777777'
     AND action = 'owner_attempt_assignment'
     AND target_id = 'c1111111-1111-4111-8111-111111111111'
     AND outcome = 'denied'
     AND reason_category = 'role_required'),
  1,
  'Admin attempts against Owner-only writes are retained as role denials'
);

-- A grader without an active submission assignment cannot record an authorised
-- draft/publication failure, even at AAL2.
SET LOCAL ROLE authenticated;
SELECT set_config('request.jwt.claim.sub', '55555555-5555-4555-8555-555555555555', true);
SELECT set_config(
  'request.jwt.claims',
  '{"sub":"55555555-5555-4555-8555-555555555555","role":"authenticated","aal":"aal2"}',
  true
);
SELECT set_config(
  'request.headers',
  '{"x-request-id":"55555555-5555-4555-8555-555555555555"}',
  true
);
SELECT ok(
  NOT public.audit_privileged_write_outcome(
    'grader_assessment_draft_save',
    'd3333333-3333-4333-8333-333333333333',
    'failed',
    'validation_failed'
  ),
  'an unassigned grader cannot record an authorised assessment draft failure'
);
RESET ROLE;
SELECT is(
  (SELECT count(*)::integer
   FROM private.security_audit_events
   WHERE actor_id = '55555555-5555-4555-8555-555555555555'
     AND action = 'grader_assessment_draft_save'
     AND target_id = 'd3333333-3333-4333-8333-333333333333'
     AND outcome = 'denied'
     AND reason_category = 'assignment_required'),
  1,
  'unassigned Grader access is recorded as denied instead of a failure'
);

-- Unknown actions and caller-supplied "success" events are never accepted.
SET LOCAL ROLE authenticated;
SELECT set_config('request.jwt.claim.sub', '88888888-8888-4888-8888-888888888888', true);
SELECT set_config(
  'request.jwt.claims',
  '{"sub":"88888888-8888-4888-8888-888888888888","role":"authenticated","aal":"aal2"}',
  true
);
SELECT ok(
  NOT public.audit_privileged_write_outcome(
    'arbitrary_write_action', 'd3333333-3333-4333-8333-333333333333', 'failed', 'operation_failed'
  ),
  'unknown privileged write action names are rejected'
);
SELECT ok(
  NOT public.audit_privileged_write_outcome(
    'owner_submission_transition', 'd3333333-3333-4333-8333-333333333333', 'success', NULL
  ),
  'callers cannot manufacture success audit events'
);
RESET ROLE;

SELECT * FROM finish();
ROLLBACK;
