BEGIN;
CREATE EXTENSION IF NOT EXISTS pgtap WITH SCHEMA extensions;
SELECT no_plan();
SET LOCAL ROLE authenticated;
SELECT set_config('request.jwt.claim.sub','11111111-1111-4111-8111-111111111111',true);
SELECT set_config('request.jwt.claims','{"sub":"11111111-1111-4111-8111-111111111111","role":"authenticated","aal":"aal2"}',true);
SELECT throws_ok($$SELECT public.owner_update_account_display_name(
 '66666666-6666-4666-8666-666666666666','Unauthorised Name')$$,
 '42501','owner_required','student cannot rename another account');
RESET ROLE;
SET LOCAL ROLE authenticated;
SELECT set_config('request.jwt.claim.sub','88888888-8888-4888-8888-888888888888',true);
SELECT set_config('request.jwt.claims','{"sub":"88888888-8888-4888-8888-888888888888","role":"authenticated","aal":"aal1"}',true);
SELECT throws_ok($$SELECT public.owner_update_account_display_name(
 '66666666-6666-4666-8666-666666666666','Unauthorised Name')$$,
 'P0001','mfa_required','owner without MFA cannot rename account');
RESET ROLE;
SET LOCAL ROLE authenticated;
SELECT set_config('request.jwt.claim.sub','88888888-8888-4888-8888-888888888888',true);
SELECT set_config('request.jwt.claims','{"sub":"88888888-8888-4888-8888-888888888888","role":"authenticated","aal":"aal2"}',true);
SELECT throws_ok($$SELECT public.owner_update_account_display_name(
 '66666666-6666-4666-8666-666666666666',' ')$$,
 '22023','invalid_display_name','blank name cannot be saved');
SELECT lives_ok($$SELECT public.owner_update_account_display_name(
 '66666666-6666-4666-8666-666666666666','Synthetic Learner Assigned')$$,
 'owner can assign a display name');
SELECT is((SELECT display_name FROM public.profiles
 WHERE user_id='66666666-6666-4666-8666-666666666666'),
 'Synthetic Learner Assigned','name persists');
RESET ROLE;
SELECT is((SELECT count(*)::integer FROM private.security_audit_events
 WHERE action='owner_account_name_changed'
 AND actor_id='88888888-8888-4888-8888-888888888888'
 AND target_id='66666666-6666-4666-8666-666666666666'),1,
 'display name change has one immutable audit row');
SELECT * FROM finish();
ROLLBACK;
