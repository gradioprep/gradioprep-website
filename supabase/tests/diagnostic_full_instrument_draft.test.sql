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

-- The content-owner-adopted v2 questions require a selected option AND an
-- observable contextual explanation. They remain unreleased and unscored.
SELECT is((SELECT count(*)::integer FROM public.diagnostic_observations
  WHERE diagnostic_version_id='ed222222-2222-4222-8222-222222222222'
    AND observation_code IN ('RV04','RV05','LC01','LC02')
    AND response_kind='choice_and_text'),4,
  'all four revised draft observations declare choice-plus-explanation evidence');
SELECT is((SELECT count(*)::integer FROM public.diagnostic_observations
  WHERE diagnostic_version_id='ed111111-1111-4111-8111-111111111111'
    AND observation_code IN ('RV04','RV05','LC01','LC02')
    AND response_kind='single_choice'),4,
  'previous synthetic published v1 observations preserve their original response schema');
SELECT is((SELECT count(*)::integer FROM public.diagnostic_observations
  WHERE diagnostic_version_id='ed222222-2222-4222-8222-222222222222'
    AND observation_code IN ('RV04','RV05','LC01','LC02')
    AND learner_capture_enabled),0,
  'content-owner adoption does not enable revised questions for students');
SELECT is((SELECT count(*)::integer FROM public.diagnostic_observation_outcome_mappings
  WHERE diagnostic_version_id='ed222222-2222-4222-8222-222222222222'
    AND mapping_status='direct'),0,
  'content-owner adoption creates no fictional directly reviewed Year 4 mappings');

-- Validate the new shape independently of access: v2 still cannot start.
SELECT ok(private.valid_pa_choice_and_explanation(
  '{"choice":"A","explanation":"The poster groups repaired and unfinished items clearly."}'::jsonb),
  'v2 draft validator accepts a selected option and meaningful explanation');
SELECT ok(NOT private.valid_pa_choice_and_explanation('{"choice":"A"}'::jsonb),
  'selection alone cannot satisfy the revised v2 evidence construct');
SELECT ok(NOT private.valid_pa_choice_and_explanation(
  '{"choice":"A","explanation":"  "}'::jsonb),
  'blank reasoning is rejected');
SELECT ok(NOT private.valid_pa_choice_and_explanation(
  '{"choice":"X","explanation":"The sentence emphasises the time."}'::jsonb),
  'unknown choice is rejected');
SELECT ok(NOT private.valid_pa_choice_and_explanation(
  '{"choice":"A","explanation":"Reasoned reply","key":"extra"}'::jsonb),
  'extra response fields are rejected');
SELECT ok(NOT private.valid_pa_choice_and_explanation(
  '{"choice":"A","explanation":123}'::jsonb),
  'non-text explanation is rejected');
SELECT ok(private.valid_diagnostic_response('RV04','{"choice":"A"}'::jsonb),
  'existing published v1 answer contract remains valid');
SELECT ok(NOT private.valid_diagnostic_response('RV04',
  '{"choice":"A","explanation":"Reasoned reply"}'::jsonb),
  'published v1 remains strict selection-only and does not silently adopt the draft version');

-- The complete blueprint has distinct dimension identities, but no independent approvals.
SELECT is((SELECT count(DISTINCT observation_code)::integer FROM public.diagnostic_observations
 WHERE diagnostic_version_id='ed222222-2222-4222-8222-222222222222'),30,
 'thirty distinct academic dimension identities remain individually reviewable');
SELECT is((SELECT count(*)::integer FROM private.pa_rubric_approvals
 WHERE diagnostic_version_id='ed222222-2222-4222-8222-222222222222'),0,
 'content-owner approval has not manufactured a numerical rubric sign-off');
SELECT is((SELECT count(*)::integer FROM public.diagnostic_observation_outcome_mappings
 WHERE diagnostic_version_id='ed222222-2222-4222-8222-222222222222'
 AND reviewed_by IS NOT NULL AND reviewed_at IS NOT NULL),0,
 'independent official outcome reviews cannot be inferred from Founder approval');

-- Publication may not be forced merely by changing a draft's state.
SELECT throws_ok($q$UPDATE public.diagnostic_versions
  SET release_state='published'
  WHERE id='ed222222-2222-4222-8222-222222222222'$q$,
  '55000','pa_publication_requires_reviewed_direct_mapping',
  'unreviewed thirty-observation PA cannot be published by changing release state');
SELECT is((SELECT release_state FROM public.diagnostic_versions
  WHERE id='ed222222-2222-4222-8222-222222222222'),'draft',
  'rejected publication leaves the full PA blueprint as a draft');

-- Even enabling every observation does not turn missing curriculum review into approval.
UPDATE public.diagnostic_observations SET learner_capture_enabled=true
WHERE diagnostic_version_id='ed222222-2222-4222-8222-222222222222';
SELECT throws_ok($q$UPDATE public.diagnostic_versions
  SET release_state='published'
  WHERE id='ed222222-2222-4222-8222-222222222222'$q$,
  '55000','pa_publication_requires_reviewed_direct_mapping',
  'all thirty enabled items still cannot publish without reviewed direct mappings');
UPDATE public.diagnostic_observations SET learner_capture_enabled=false
WHERE diagnostic_version_id='ed222222-2222-4222-8222-222222222222';

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
