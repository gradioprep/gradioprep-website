BEGIN;
CREATE EXTENSION IF NOT EXISTS pgtap WITH SCHEMA extensions;
SELECT no_plan();

-- A student cannot revoke roles even if an access token contains an AAL2 claim.
SET LOCAL ROLE authenticated;
SELECT set_config('request.jwt.claim.sub', '11111111-1111-4111-8111-111111111111', true);
SELECT set_config(
  'request.jwt.claims',
  '{"sub":"11111111-1111-4111-8111-111111111111","role":"authenticated","aal":"aal2"}',
  true
);
SELECT throws_ok(
  $$SELECT public.revoke_role_assignment(
    '66666666-6666-4666-8666-666666666666',
    'grader',
    'synthetic test revocation'
  )$$,
  '42501',
  'role_management_forbidden',
  'student cannot revoke a grader role'
);
RESET ROLE;

-- Admin is not implicitly a role administrator.
SET LOCAL ROLE authenticated;
SELECT set_config('request.jwt.claim.sub', '77777777-7777-4777-8777-777777777777', true);
SELECT set_config(
  'request.jwt.claims',
  '{"sub":"77777777-7777-4777-8777-777777777777","role":"authenticated","aal":"aal2"}',
  true
);
SELECT throws_ok(
  $$SELECT public.revoke_role_assignment(
    '66666666-6666-4666-8666-666666666666',
    'grader',
    'synthetic test revocation'
  )$$,
  '42501',
  'role_management_forbidden',
  'admin cannot revoke a grader role without a separately delegated permission'
);
RESET ROLE;

-- An owner with only first-factor assurance must not manage roles.
SET LOCAL ROLE authenticated;
SELECT set_config('request.jwt.claim.sub', '88888888-8888-4888-8888-888888888888', true);
SELECT set_config(
  'request.jwt.claims',
  '{"sub":"88888888-8888-4888-8888-888888888888","role":"authenticated","aal":"aal1"}',
  true
);
SELECT throws_ok(
  $$SELECT public.revoke_role_assignment(
    '66666666-6666-4666-8666-666666666666',
    'grader',
    'synthetic test revocation'
  )$$,
  'P0001',
  'mfa_required',
  'owner session must have completed MFA before role revocation'
);
RESET ROLE;

-- Deliberately make the original grantor differ from the revoking owner so
-- the audit event must attribute the current actor, not the historical grantor.
UPDATE public.role_assignments
SET granted_by = '11111111-1111-4111-8111-111111111111'
WHERE user_id = '66666666-6666-4666-8666-666666666666'
  AND role = 'grader'
  AND revoked_at IS NULL;

SET LOCAL ROLE authenticated;
SELECT set_config('request.jwt.claim.sub', '88888888-8888-4888-8888-888888888888', true);
SELECT set_config(
  'request.jwt.claims',
  '{"sub":"88888888-8888-4888-8888-888888888888","role":"authenticated","aal":"aal2"}',
  true
);
SELECT lives_ok(
  $$SELECT public.revoke_role_assignment(
    '66666666-6666-4666-8666-666666666666',
    'grader',
    'synthetic test revocation'
  )$$,
  'MFA-verified owner can revoke an active grader role'
);
SELECT is(
  (SELECT count(*)::integer FROM public.role_assignments
   WHERE user_id = '66666666-6666-4666-8666-666666666666'
     AND role = 'grader' AND revoked_at IS NULL),
  0,
  'revoked grader role is no longer active'
);
RESET ROLE;

SELECT is(
  (SELECT count(*)::integer FROM private.security_audit_events
   WHERE action = 'role_revoked'
     AND actor_id = '88888888-8888-4888-8888-888888888888'
     AND target_id = (
       SELECT id FROM public.role_assignments
       WHERE user_id = '66666666-6666-4666-8666-666666666666'
         AND role = 'grader'
     )),
  1,
  'role revocation audit records the actual revoking owner'
);
SELECT is(
  (SELECT reason_category FROM private.security_audit_events
   WHERE action = 'role_revoked'
     AND actor_id = '88888888-8888-4888-8888-888888888888'
     AND target_id = (
       SELECT id FROM public.role_assignments
       WHERE user_id = '66666666-6666-4666-8666-666666666666'
         AND role = 'grader'
     )
   ORDER BY occurred_at DESC LIMIT 1),
  'role_revoked'::text,
  'role revocation audit uses the fixed action category'
);
SELECT ok(
  NOT EXISTS (
    SELECT 1 FROM private.security_audit_events
    WHERE action = 'role_revoked'
      AND reason_category = 'synthetic test revocation'
  ),
  'free-text revocation reason is not copied into audit metadata'
);

SET LOCAL ROLE authenticated;
SELECT set_config('request.jwt.claim.sub', '88888888-8888-4888-8888-888888888888', true);
SELECT set_config(
  'request.jwt.claims',
  '{"sub":"88888888-8888-4888-8888-888888888888","role":"authenticated","aal":"aal2"}',
  true
);
SELECT throws_ok(
  $$SELECT public.revoke_role_assignment(
    '88888888-8888-4888-8888-888888888888',
    'owner',
    'protect the final owner'
  )$$,
  '23514',
  'last_active_owner_protected',
  'the final active owner role cannot be revoked'
);
SELECT throws_ok(
  $$SELECT public.revoke_role_assignment(
    '55555555-5555-4555-8555-555555555555',
    'grader',
    ' '
  )$$,
  '22023',
  'invalid_revocation_reason',
  'a revocation requires a meaningful reason'
);
RESET ROLE;

SELECT is(
  (SELECT count(*)::integer FROM public.role_assignments
   WHERE user_id = '88888888-8888-4888-8888-888888888888'
     AND role = 'owner' AND revoked_at IS NULL),
  1,
  'the project retains its final active owner'
);
SELECT is(
  (SELECT count(*)::integer FROM public.role_assignments
   WHERE user_id = '55555555-5555-4555-8555-555555555555'
     AND role = 'grader' AND revoked_at IS NULL),
  1,
  'invalid revocation attempts leave the target role unchanged'
);

SELECT * FROM finish();
ROLLBACK;
