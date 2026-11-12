BEGIN;
SELECT no_plan();
-- SP01 holds only a prepared outline, never a recorded or inferred oral score.
SELECT ok(private.valid_diagnostic_response('SP01',jsonb_build_object(
  'title','Reading corner','opening','I recommend a reading corner.',
  'development','A reading corner gives people quiet time.',
  'consideration','Some prefer games; both options can exist.',
  'closing','Please trial the idea for a month.')),
  'SP01 accepts a complete five-part outline card');
SELECT ok(NOT private.valid_diagnostic_response('SP01',jsonb_build_object(
  'title','Reading corner','opening','I recommend a reading corner.',
  'development','A reading corner gives people quiet time.',
  'closing','Please trial it.')),
  'outline missing alternative-perspective consideration is rejected');
SELECT ok(NOT private.valid_diagnostic_response('SP01',jsonb_build_object(
  'title','Reading corner','opening','I recommend a reading corner.',
  'development','A reading corner gives people quiet time.',
  'consideration','Some prefer games; both can exist.',
  'closing','Please trial it.','spoken_score',7)),
  'learner cannot inject spoken scores or extra fields');
SELECT ok(NOT private.valid_diagnostic_response('SP01',jsonb_build_object(
  'title','Reading corner','opening','I recommend a reading corner.',
  'development',repeat('a',1001),
  'consideration','Some prefer games; both can exist.',
  'closing','Please trial it.')),
  'overlong card field is rejected');
SELECT ok(NOT private.valid_diagnostic_response('SP02','{"text":"I gave a great presentation."}'::jsonb),
 'SP02 cannot masquerade as independently typed speaking evidence');
SELECT ok(NOT private.valid_diagnostic_response('SP05','{"score":7}'::jsonb),
 'SP05 cannot be self-scored');
SELECT is((SELECT count(*)::integer FROM public.diagnostic_observations
 WHERE diagnostic_version_id='ed222222-2222-4222-8222-222222222222'
 AND group_code='SP' AND learner_capture_enabled),0,
 'full SP group remains disabled until academic approval');
SELECT is((SELECT release_state FROM public.diagnostic_versions
 WHERE id='ed222222-2222-4222-8222-222222222222'),'draft',
 'full 30-observation PA remains draft');
SELECT * FROM finish();
ROLLBACK;
