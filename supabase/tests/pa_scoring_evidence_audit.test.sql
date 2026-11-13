BEGIN;
SELECT no_plan();
-- Fixture is the 15-observation synthetic report from evaluation_reports.test.sql;
-- this test is self-contained and uses the existing seeded PA blueprint for
-- the unauthorised / missing-record boundary.
SET LOCAL ROLE authenticated;
SELECT set_config('request.jwt.claim.sub','11111111-1111-4111-8111-111111111111',true);
SELECT set_config('request.jwt.claims','{"sub":"11111111-1111-4111-8111-111111111111","role":"authenticated","aal":"aal1"}',true);
SELECT throws_ok(
  $$SELECT * FROM public.inspect_pa_scoring_evidence('00000000-0000-0000-0000-000000000000')$$,
  '42501','pa_scoring_evidence_forbidden',
  'learner cannot inspect private PA scoring evidence');
RESET ROLE;

SET LOCAL ROLE authenticated;
SELECT set_config('request.jwt.claim.sub','88888888-8888-4888-8888-888888888888',true);
SELECT set_config('request.jwt.claims','{"sub":"88888888-8888-4888-8888-888888888888","role":"authenticated","aal":"aal1"}',true);
SELECT throws_ok(
  $$SELECT * FROM public.inspect_pa_scoring_evidence('00000000-0000-0000-0000-000000000000')$$,
  '42501','pa_scoring_evidence_forbidden',
  'Owner without AAL2 cannot access PA scoring audit');
SELECT set_config('request.jwt.claims','{"sub":"88888888-8888-4888-8888-888888888888","role":"authenticated","aal":"aal2"}',true);
SELECT throws_ok(
  $$SELECT * FROM public.inspect_pa_scoring_evidence('00000000-0000-0000-0000-000000000000')$$,
  'P0002','pa_report_not_found',
  'authorised Owner cannot invent a missing report');
RESET ROLE;
-- The blueprint has thirty scoring dimensions but only eighteen source
-- response codes: RV(10) + LC(5) + AW01/CW01/SP01(3).
SELECT is((SELECT count(*)::integer FROM public.diagnostic_observations
  WHERE diagnostic_version_id='ed222222-2222-4222-8222-222222222222'),30,
  'PA rubric blueprint retains thirty distinct observations');
SELECT is((SELECT count(DISTINCT CASE WHEN group_code IN ('AW','CW','SP')
    THEN group_code || '01' ELSE observation_code END)::integer
  FROM public.diagnostic_observations
  WHERE diagnostic_version_id='ed222222-2222-4222-8222-222222222222'),18,
  'thirty dimensions correctly resolve to eighteen source response slots');
SELECT is((SELECT count(*)::integer FROM public.diagnostic_observations o
  WHERE diagnostic_version_id='ed222222-2222-4222-8222-222222222222'
    AND EXISTS (
      SELECT 1 FROM public.diagnostic_observations src
      WHERE src.diagnostic_version_id=o.diagnostic_version_id
        AND src.observation_code=CASE WHEN o.group_code IN ('AW','CW','SP')
          THEN o.group_code || '01' ELSE o.observation_code END
    )),30,
  'each rubric dimension has a valid source observation within its version');
SELECT * FROM finish();
ROLLBACK;
