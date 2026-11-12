BEGIN;
SELECT no_plan();

-- AW01 holds a single learner performance; AW02–AW05 are rubric dimensions,
-- never separately submitted answers.
SELECT ok(private.valid_diagnostic_response('AW01',jsonb_build_object('text','An analytical claim supported by evidence.')),
  'AW01 accepts one bounded response');
SELECT ok(private.valid_diagnostic_response('AW01',jsonb_build_object('text',repeat('word ',220))),
  'a response exceeding the 180-word guidance remains valid');
SELECT ok(NOT private.valid_diagnostic_response('AW01','{"text":"  "}'::jsonb),
  'AW01 rejects blank content');
SELECT ok(NOT private.valid_diagnostic_response('AW01','{"text":"valid response","score":7}'::jsonb),
  'AW01 rejects injected grades and unsupported extra fields');
SELECT ok(NOT private.valid_diagnostic_response('AW01',jsonb_build_object('text',repeat('x',12001))),
  'AW01 enforces transport size bounds, not word-guidance restrictions');
SELECT ok(NOT private.valid_diagnostic_response('AW02','{"text":"another answer"}'::jsonb),
  'AW02 cannot pretend to be an independent essay submission');
SELECT ok(NOT private.valid_diagnostic_response('AW05','{"text":"another answer"}'::jsonb),
  'AW05 is rubric evidence only, not a separate learner answer');

SELECT is((SELECT count(*)::integer FROM public.diagnostic_observations
  WHERE diagnostic_version_id='ed222222-2222-4222-8222-222222222222'
  AND group_code='AW' AND learner_capture_enabled),0,
  'all AW draft observations remain uncapturable before academic approval');
SELECT is((SELECT release_state FROM public.diagnostic_versions
  WHERE id='ed222222-2222-4222-8222-222222222222'),'draft',
  'the full PA remains draft');
SELECT * FROM finish();
ROLLBACK;
