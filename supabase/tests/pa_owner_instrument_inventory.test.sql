BEGIN;
SELECT no_plan();
SET LOCAL ROLE authenticated;
SELECT set_config('request.jwt.claim.sub','11111111-1111-4111-8111-111111111111',true);
SELECT set_config('request.jwt.claims',
 '{"sub":"11111111-1111-4111-8111-111111111111","role":"authenticated","aal":"aal2"}',true);
SELECT throws_ok($q$SELECT * FROM public.list_pa_academic_versions()$q$,
 '42501','pa_version_inventory_forbidden',
 'student is denied private Year 4 academic instrument inventory');
SELECT set_config('request.jwt.claim.sub','88888888-8888-4888-8888-888888888888',true);
SELECT set_config('request.jwt.claims',
 '{"sub":"88888888-8888-4888-8888-888888888888","role":"authenticated","aal":"aal1"}',true);
SELECT throws_ok($q$SELECT * FROM public.list_pa_academic_versions()$q$,
 '42501','pa_version_inventory_forbidden',
 'Owner without second factor cannot see private academic inventory');
SELECT set_config('request.jwt.claims',
 '{"sub":"88888888-8888-4888-8888-888888888888","role":"authenticated","aal":"aal2"}',true);
SELECT ok(EXISTS(SELECT 1 FROM public.list_pa_academic_versions()
 WHERE instrument_version=2 AND instrument_release_state='draft'
 AND total_observations=30 AND direct_mappings=0),
 'Owner sees actual hidden 30-observation version without invented mapping acceptance');
RESET ROLE;
SELECT * FROM finish();
ROLLBACK;
