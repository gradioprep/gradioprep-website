BEGIN;
SELECT no_plan();
-- All content is synthetic. A Founder academic decision is not a database seed.
SET LOCAL ROLE authenticated;
SELECT set_config('request.jwt.claim.sub','11111111-1111-4111-8111-111111111111',true);
SELECT set_config('request.jwt.claims',
 '{"sub":"11111111-1111-4111-8111-111111111111","role":"authenticated","aal":"aal1"}',true);
SELECT throws_ok($q$SELECT * FROM public.inspect_pa_academic_readiness(
 'ed222222-2222-4222-8222-222222222222')$q$,
 '42501','pa_academic_readiness_forbidden',
 'learner cannot read the private readiness inventory');
SELECT set_config('request.jwt.claim.sub','88888888-8888-4888-8888-888888888888',true);
SELECT set_config('request.jwt.claims',
 '{"sub":"88888888-8888-4888-8888-888888888888","role":"authenticated","aal":"aal1"}',true);
SELECT throws_ok($q$SELECT * FROM public.inspect_pa_academic_readiness(
 'ed222222-2222-4222-8222-222222222222')$q$,
 '42501','pa_academic_readiness_forbidden',
 'Owner AAL1 cannot view the inventory');
SELECT set_config('request.jwt.claims',
 '{"sub":"88888888-8888-4888-8888-888888888888","role":"authenticated","aal":"aal2"}',true);
SELECT is((SELECT count(*)::integer FROM public.inspect_pa_academic_readiness(
 'ed222222-2222-4222-8222-222222222222')),30,
 'Owner AAL2 sees all thirty exact instrument dimensions');
SELECT is((SELECT count(*)::integer FROM public.inspect_pa_academic_readiness(
 'ed222222-2222-4222-8222-222222222222')
 WHERE NOT reviewed_direct_mapping_present
   AND NOT approved_rubric_record_present
   AND NOT learner_capture_enabled
   AND instrument_release_state='draft'),30,
 'all thirty unreviewed synthetic records correctly report blocked evidence and capture');
SELECT is((SELECT count(*)::integer FROM public.inspect_pa_academic_readiness(
 'ed222222-2222-4222-8222-222222222222') WHERE group_code='L'),0,
 'Listening remains excluded from the academic inventory');
SELECT throws_ok($q$SELECT * FROM public.inspect_pa_academic_readiness(
 '00000000-0000-0000-0000-000000000000')$q$,
 'P0002','pa_instrument_not_found',
 'Owner cannot infer an academic readiness inventory for an absent instrument');
RESET ROLE;
SELECT * FROM finish();
ROLLBACK;
