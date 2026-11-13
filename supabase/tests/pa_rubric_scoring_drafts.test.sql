BEGIN;
SELECT no_plan();
-- The Year 4 blueprint is draft. No criterion maxima, rubric sign-off,
-- calibration, scores or learner-visible PA grades are created by migration.
SELECT is((SELECT count(*)::integer FROM private.pa_rubric_approvals),0,
  'no human rubric approvals fabricated');
SELECT is((SELECT count(*)::integer FROM private.pa_scoring_drafts),0,
  'no learner scores or private score drafts fabricated');

SET LOCAL ROLE authenticated;
SELECT set_config('request.jwt.claim.sub','11111111-1111-4111-8111-111111111111',true);
SELECT set_config('request.jwt.claims',
  '{"sub":"11111111-1111-4111-8111-111111111111","role":"authenticated","aal":"aal1"}',true);
SELECT throws_ok($q$SELECT * FROM private.pa_rubric_approvals$q$,
  '42501',NULL,'learner cannot directly inspect approved staff rubrics');
SELECT throws_ok($q$SELECT * FROM private.pa_scoring_drafts$q$,
  '42501',NULL,'learner cannot directly inspect score drafts');
SELECT throws_ok($q$SELECT public.create_pa_scoring_draft(
  '00000000-0000-0000-0000-000000000000',
  '00000000-0000-0000-0000-000000000000','[]'::jsonb)$q$,
  '42501','pa_scoring_draft_forbidden','learner cannot create a PA scoring draft');
SELECT throws_ok($q$SELECT public.approve_pa_scoring_rubric(
  'ed222222-2222-4222-8222-222222222222',
  repeat('a',64),'[]'::jsonb,'Academic source reference',
  'Calibrated assessor reference','This is a forbidden learner approval.')$q$,
  '42501','pa_rubric_approval_forbidden','learner cannot approve rubric');

SELECT set_config('request.jwt.claim.sub','55555555-5555-4555-8555-555555555555',true);
SELECT set_config('request.jwt.claims',
  '{"sub":"55555555-5555-4555-8555-555555555555","role":"authenticated","aal":"aal2"}',true);
SELECT throws_ok($q$SELECT public.approve_pa_scoring_rubric(
  'ed222222-2222-4222-8222-222222222222',
  repeat('a',64),'[]'::jsonb,'Academic source reference',
  'Calibrated assessor reference','This is a forbidden grader approval.')$q$,
  '42501','pa_rubric_approval_forbidden','assigned Grader cannot approve rubric');

SELECT set_config('request.jwt.claim.sub','88888888-8888-4888-8888-888888888888',true);
SELECT set_config('request.jwt.claims',
  '{"sub":"88888888-8888-4888-8888-888888888888","role":"authenticated","aal":"aal1"}',true);
SELECT throws_ok($q$SELECT public.approve_pa_scoring_rubric(
  'ed222222-2222-4222-8222-222222222222',
  repeat('a',64),'[]'::jsonb,'Academic source reference',
  'Calibrated assessor reference','This is a forbidden low assurance approval.')$q$,
  '42501','pa_rubric_approval_forbidden','Owner without AAL2 cannot approve rubric');

SELECT set_config('request.jwt.claims',
  '{"sub":"88888888-8888-4888-8888-888888888888","role":"authenticated","aal":"aal2"}',true);
SELECT throws_ok($q$SELECT public.approve_pa_scoring_rubric(
  'ed222222-2222-4222-8222-222222222222',
  repeat('a',64),'[]'::jsonb,'Academic source reference',
  'Calibrated assessor reference','Thirty distinct maxima not supplied.')$q$,
  '22023','invalid_pa_rubric_approval','Owner cannot approve empty rubric dimensions');
SELECT throws_ok($q$SELECT public.approve_pa_scoring_rubric(
  'ed222222-2222-4222-8222-222222222222',
  repeat('a',64),
  (SELECT jsonb_agg(jsonb_build_object('code',observation_code,'max_points',5))
   FROM public.diagnostic_observations
   WHERE diagnostic_version_id='ed222222-2222-4222-8222-222222222222'),
  'Academic source reference','Calibrated assessor reference',
  'Blueprint lacks approved publication and human mapping.')$q$,
  '55000','pa_rubric_requires_published_reviewed_instrument',
  'even complete synthetic maxima cannot approve an unreleased blueprint');
RESET ROLE;
SELECT is((SELECT count(*)::integer FROM private.pa_rubric_approvals),0,
  'failed attempts leave no invented academic approval');
SELECT is((SELECT count(*)::integer FROM private.pa_scoring_drafts),0,
  'failed attempts leave private scoring drafts empty');
SELECT * FROM finish();
ROLLBACK;
