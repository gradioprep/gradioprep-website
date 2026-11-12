BEGIN;
SELECT no_plan();
CREATE TEMP TABLE pa_sitting_test_state (attempt_id uuid) ON COMMIT DROP;
GRANT SELECT, INSERT ON pa_sitting_test_state TO authenticated;
SET LOCAL ROLE authenticated;
SELECT set_config('request.jwt.claim.sub','11111111-1111-4111-8111-111111111111',true);
SELECT set_config('request.jwt.claims','{"sub":"11111111-1111-4111-8111-111111111111","role":"authenticated","aal":"aal1"}',true);
INSERT INTO pa_sitting_test_state SELECT attempt_id FROM public.create_diagnostic_attempt(
 'ed111111-1111-4111-8111-111111111111','edaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa');
SELECT is((SELECT count(*)::integer FROM public.get_pa_sitting_state(
 (SELECT attempt_id FROM pa_sitting_test_state))),0,'new attempt has no started sitting');
SELECT throws_ok($q$SELECT * FROM public.start_pa_sitting(
 (SELECT attempt_id FROM pa_sitting_test_state),2)$q$,
 'P0001','pa_sitting_unavailable','second sitting cannot start without enabled content');
SELECT is((SELECT duration_seconds FROM public.start_pa_sitting(
 (SELECT attempt_id FROM pa_sitting_test_state),1)),2100,'first sitting uses 35 minutes');
SELECT is((SELECT count(*)::integer FROM public.start_pa_sitting(
 (SELECT attempt_id FROM pa_sitting_test_state),1)),1,'repeated start resumes the same sitting');
SELECT is((SELECT count(*)::integer FROM private.pa_sitting_sessions),1,
 'idempotent start never resets the sitting clock');
SELECT throws_ok($q$SELECT public.complete_pa_sitting(
 (SELECT attempt_id FROM pa_sitting_test_state),1)$q$,
 'P0001','pa_sitting_responses_incomplete','cannot finish without evidence');
SELECT throws_ok($q$SELECT public.adjust_pa_sitting_access(
 (SELECT attempt_id FROM pa_sitting_test_state),1,5,false,'Reason authorised by staff')$q$,
 '42501','pa_sitting_adjust_forbidden','student cannot extend own sitting');
RESET ROLE;
SET LOCAL ROLE authenticated;
SELECT set_config('request.jwt.claim.sub','22222222-2222-4222-8222-222222222222',true);
SELECT set_config('request.jwt.claims','{"sub":"22222222-2222-4222-8222-222222222222","role":"authenticated","aal":"aal1"}',true);
SELECT throws_ok($q$SELECT * FROM public.get_pa_sitting_state(
 (SELECT attempt_id FROM pa_sitting_test_state))$q$,
 '42501','pa_sitting_forbidden','another learner cannot see sitting clock');
RESET ROLE;
SET LOCAL ROLE authenticated;
SELECT set_config('request.jwt.claim.sub','88888888-8888-4888-8888-888888888888',true);
SELECT set_config('request.jwt.claims','{"sub":"88888888-8888-4888-8888-888888888888","role":"authenticated","aal":"aal1"}',true);
SELECT throws_ok($q$SELECT public.adjust_pa_sitting_access(
 (SELECT attempt_id FROM pa_sitting_test_state),1,5,false,'Documented access arrangement')$q$,
 '42501','pa_sitting_adjust_forbidden','owner without MFA cannot extend clock');
RESET ROLE;
SET LOCAL ROLE authenticated;
SELECT set_config('request.jwt.claim.sub','88888888-8888-4888-8888-888888888888',true);
SELECT set_config('request.jwt.claims','{"sub":"88888888-8888-4888-8888-888888888888","role":"authenticated","aal":"aal2"}',true);
SELECT is(public.adjust_pa_sitting_access(
 (SELECT attempt_id FROM pa_sitting_test_state),1,5,false,'Documented access arrangement'),true,
 'MFA-verified owner grants approved extension');
SELECT is(public.adjust_pa_sitting_access(
 (SELECT attempt_id FROM pa_sitting_test_state),1,0,true,'Approved untimed arrangement'),true,
 'MFA-verified owner grants untimed accommodation');
SELECT is((SELECT extra_seconds FROM private.pa_sitting_sessions),300,
 'an untimed adjustment never removes an earlier extension');
SELECT is((SELECT untimed FROM private.pa_sitting_sessions),true,
 'untimed arrangement persists');
SELECT is((SELECT count(*)::integer FROM private.security_audit_events
 WHERE action='pa_sitting_adjusted' AND reason_category='owner_accommodation'),2,
 'both arrangements are audit recorded');
RESET ROLE;
SELECT * FROM finish();
ROLLBACK;
