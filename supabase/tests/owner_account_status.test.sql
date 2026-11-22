BEGIN;
CREATE EXTENSION IF NOT EXISTS pgtap WITH SCHEMA extensions;
SELECT no_plan();
SET LOCAL ROLE authenticated;
SELECT set_config('request.jwt.claim.sub', '11111111-1111-4111-8111-111111111111', true);
SELECT set_config('request.jwt.claims', '{"sub":"11111111-1111-4111-8111-111111111111","role":"authenticated","aal":"aal2"}', true);
SELECT throws_ok($$SELECT public.set_owner_account_status('66666666-6666-4666-8666-666666666666', 'suspended')$$,
  '42501', 'owner_required', 'student cannot suspend an account');
RESET ROLE;
SET LOCAL ROLE authenticated;
SELECT set_config('request.jwt.claim.sub', '88888888-8888-4888-8888-888888888888', true);
SELECT set_config('request.jwt.claims', '{"sub":"88888888-8888-4888-8888-888888888888","role":"authenticated","aal":"aal1"}', true);
SELECT throws_ok($$SELECT public.set_owner_account_status('66666666-6666-4666-8666-666666666666', 'suspended')$$,
  'P0001', 'mfa_required', 'Owner must verify authenticator');
RESET ROLE;
SET LOCAL ROLE authenticated;
SELECT set_config('request.jwt.claim.sub', '88888888-8888-4888-8888-888888888888', true);
SELECT set_config('request.jwt.claims', '{"sub":"88888888-8888-4888-8888-888888888888","role":"authenticated","aal":"aal2"}', true);
SELECT throws_ok($$SELECT public.set_owner_account_status('88888888-8888-4888-8888-888888888888', 'suspended')$$,
  '23514', 'own_account_protected', 'Owner cannot suspend own account');
SELECT lives_ok($$SELECT public.set_owner_account_status('66666666-6666-4666-8666-666666666666', 'suspended')$$,
  'Owner can suspend synthetic account');
SELECT is((SELECT account_status::text FROM public.profiles
           WHERE user_id='66666666-6666-4666-8666-666666666666'),
          'suspended', 'account is suspended in PostgreSQL');
SELECT lives_ok($$SELECT public.set_owner_account_status('66666666-6666-4666-8666-666666666666', 'active')$$,
  'Owner can reactivate synthetic account');
SELECT is((SELECT account_status::text FROM public.profiles
           WHERE user_id='66666666-6666-4666-8666-666666666666'),
          'active', 'account is reactivated in PostgreSQL');
RESET ROLE;
SELECT is((SELECT count(*)::integer FROM private.security_audit_events
 WHERE action='owner_account_status_changed'
   AND actor_id='88888888-8888-4888-8888-888888888888'
   AND target_id='66666666-6666-4666-8666-666666666666'), 2,
  'both status changes are audited');
SELECT * FROM finish();
ROLLBACK;
