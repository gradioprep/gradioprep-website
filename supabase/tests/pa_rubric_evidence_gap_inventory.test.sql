BEGIN;
SELECT no_plan();
-- Draft evidence is deliberately incomplete. No approval, maximum or score is seeded.
SET LOCAL ROLE authenticated;
SELECT set_config('request.jwt.claim.sub','11111111-1111-4111-8111-111111111111',true);
SELECT set_config('request.jwt.claims','{"sub":"11111111-1111-4111-8111-111111111111","role":"authenticated","aal":"aal1"}',true);
SELECT throws_ok($q$SELECT * FROM public.inspect_pa_rubric_evidence_gaps('ed222222-2222-4222-8222-222222222222')$q$,
 '42501','pa_academic_readiness_forbidden','learner cannot read private rubric reconciliation');
SELECT set_config('request.jwt.claim.sub','88888888-8888-4888-8888-888888888888',true);
SELECT set_config('request.jwt.claims','{"sub":"88888888-8888-4888-8888-888888888888","role":"authenticated","aal":"aal1"}',true);
SELECT throws_ok($q$SELECT * FROM public.inspect_pa_rubric_evidence_gaps('ed222222-2222-4222-8222-222222222222')$q$,
 '42501','pa_academic_readiness_forbidden','Owner AAL1 cannot read rubric evidence');
SELECT set_config('request.jwt.claims','{"sub":"88888888-8888-4888-8888-888888888888","role":"authenticated","aal":"aal2"}',true);
SELECT is((SELECT count(*)::integer FROM public.inspect_pa_rubric_evidence_gaps('ed222222-2222-4222-8222-222222222222')),30,
 'qualified Owner sees thirty exact-version evidence gaps');
SELECT is((SELECT count(*)::integer FROM public.inspect_pa_rubric_evidence_gaps('ed222222-2222-4222-8222-222222222222')
 WHERE NOT reviewed_direct_mapping_present AND NOT learner_capture_enabled
   AND NOT numeric_maximum_recorded AND NOT rubric_reference_recorded
   AND NOT calibration_reference_recorded AND rubric_record_count=0
   AND instrument_release_state='draft'),30,
 'all missing evidence remains explicitly missing despite Founder approval');
SELECT is((SELECT count(*)::integer FROM public.inspect_pa_rubric_evidence_gaps('ed222222-2222-4222-8222-222222222222')
 WHERE group_code='L'),0,'no PA Listening dimensions');
SELECT throws_ok($q$SELECT * FROM public.inspect_pa_rubric_evidence_gaps('00000000-0000-0000-0000-000000000000')$q$,
 'P0002','pa_instrument_not_found','unknown version cannot reveal evidence');
RESET ROLE;
SELECT * FROM finish();
ROLLBACK;
