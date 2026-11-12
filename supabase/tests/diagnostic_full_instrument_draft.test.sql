BEGIN;
SELECT no_plan();

-- The 30-observation Year 4 instrument is a non-released, synthetic-only
-- authoring blueprint. It does not represent approved curriculum mapping or
-- fifteen new learner questions.
SELECT is((SELECT release_state FROM public.diagnostic_versions
  WHERE id='ed222222-2222-4222-8222-222222222222'), 'draft',
  'full thirty-observation blueprint remains draft');
SELECT is((SELECT count(*)::integer FROM public.diagnostic_observations
  WHERE diagnostic_version_id='ed222222-2222-4222-8222-222222222222'), 30,
  'full blueprint contains exactly thirty evidence observations');
SELECT is((SELECT count(*)::integer FROM public.diagnostic_observations
  WHERE diagnostic_version_id='ed222222-2222-4222-8222-222222222222'
    AND group_code='RV'),10,'ten Read & View observations');
SELECT is((SELECT count(*)::integer FROM public.diagnostic_observations
  WHERE diagnostic_version_id='ed222222-2222-4222-8222-222222222222'
    AND group_code='LC'),5,'five Language in Context observations');
SELECT is((SELECT count(*)::integer FROM public.diagnostic_observations
  WHERE diagnostic_version_id='ed222222-2222-4222-8222-222222222222'
    AND group_code='AW' AND sitting_number=2),5,'five analytical writing dimensions in sitting two');
SELECT is((SELECT count(*)::integer FROM public.diagnostic_observations
  WHERE diagnostic_version_id='ed222222-2222-4222-8222-222222222222'
    AND group_code='CW' AND sitting_number=2),5,'five creative writing dimensions in sitting two');
SELECT is((SELECT count(*)::integer FROM public.diagnostic_observations
  WHERE diagnostic_version_id='ed222222-2222-4222-8222-222222222222'
    AND group_code='SP' AND sitting_number=2),5,'five speaking/presenting dimensions in sitting two');
SELECT is((SELECT count(*)::integer FROM public.diagnostic_observations
  WHERE diagnostic_version_id='ed222222-2222-4222-8222-222222222222'
    AND group_code='L'),0,'Listening remains excluded from PA');
SELECT is((SELECT count(*)::integer FROM public.diagnostic_observations
  WHERE diagnostic_version_id='ed222222-2222-4222-8222-222222222222'
    AND learner_capture_enabled),0,'no unreviewed draft observation is learner-capturable');
SELECT ok((SELECT total_minutes=80 AND sitting_count=2 FROM public.diagnostic_versions
  WHERE id='ed222222-2222-4222-8222-222222222222'),
  'full draft retains planned two sittings and eighty-minute envelope');
SELECT is((SELECT count(*)::integer FROM public.diagnostic_observation_outcome_mappings
  WHERE diagnostic_version_id='ed222222-2222-4222-8222-222222222222'),0,
  'draft blueprint cannot invent reviewed official-outcome mappings');

SET LOCAL ROLE authenticated;
SELECT set_config('request.jwt.claim.sub','11111111-1111-4111-8111-111111111111',true);
SELECT set_config('request.jwt.claims','{"sub":"11111111-1111-4111-8111-111111111111","role":"authenticated","aal":"aal1"}',true);
SELECT is((SELECT count(*)::integer FROM public.diagnostic_versions
  WHERE id='ed222222-2222-4222-8222-222222222222'),0,
  'student cannot read draft version through RLS');
SELECT is((SELECT count(*)::integer FROM public.diagnostic_observations
  WHERE diagnostic_version_id='ed222222-2222-4222-8222-222222222222'),0,
  'student cannot read unapproved observation metadata');
SELECT throws_ok($q$SELECT * FROM public.create_diagnostic_attempt(
 'ed222222-2222-4222-8222-222222222222','ed222222-0000-4000-8000-000000000001')$q$,
 'P0002','diagnostic_not_available','student cannot begin unreleased full instrument');
RESET ROLE;
SELECT * FROM finish();
ROLLBACK;
