BEGIN;
SELECT no_plan();
-- No approved school route/outcome records are manufactured here.
SET LOCAL ROLE authenticated;
SELECT set_config('request.jwt.claim.sub','11111111-1111-4111-8111-111111111111',true);
SELECT set_config('request.jwt.claims',
 '{"sub":"11111111-1111-4111-8111-111111111111","role":"authenticated","aal":"aal2"}',true);
SELECT throws_ok($q$SELECT public.record_pa_verified_direct_crosswalk(
 'ed222222-2222-4222-8222-222222222222','[]'::jsonb)$q$,
 '42501','pa_mapping_handoff_forbidden',
 'student cannot write any academic curriculum crosswalk');
SELECT set_config('request.jwt.claim.sub','88888888-8888-4888-8888-888888888888',true);
SELECT set_config('request.jwt.claims',
 '{"sub":"88888888-8888-4888-8888-888888888888","role":"authenticated","aal":"aal1"}',true);
SELECT throws_ok($q$SELECT public.record_pa_verified_direct_crosswalk(
 'ed222222-2222-4222-8222-222222222222','[]'::jsonb)$q$,
 '42501','pa_mapping_handoff_forbidden',
 'qualified Owner must complete AAL2 before recording mapping evidence');
SELECT set_config('request.jwt.claims',
 '{"sub":"88888888-8888-4888-8888-888888888888","role":"authenticated","aal":"aal2"}',true);
SELECT throws_ok($q$SELECT public.record_pa_verified_direct_crosswalk(
 'ed222222-2222-4222-8222-222222222222','[]'::jsonb)$q$,
 '22023','pa_crosswalk_requires_30_links',
 'Owner cannot record partial or empty crosswalk');
SELECT throws_ok($q$SELECT public.record_pa_verified_direct_crosswalk(
 'ed222222-2222-4222-8222-222222222222',
 (SELECT jsonb_agg(jsonb_build_object('code',o.observation_code,
   'outcome_mapping_id','00000000-0000-0000-0000-000000000000',
   'rationale','Synthetic placeholder not a verified mapping.'))
 FROM public.diagnostic_observations o
 WHERE o.diagnostic_version_id='ed222222-2222-4222-8222-222222222222'))$q$,
 '55000','pa_crosswalk_route_or_version_not_ready',
 'Owner cannot authorise mappings against an unverified school route');
RESET ROLE;
SELECT is((SELECT count(*)::integer FROM public.diagnostic_observation_outcome_mappings
 WHERE diagnostic_version_id='ed222222-2222-4222-8222-222222222222'),0,
 'rejected crosswalk requests leave the full instrument unchanged');
SELECT * FROM finish();
ROLLBACK;
