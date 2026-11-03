BEGIN;
SELECT no_plan();

SET LOCAL ROLE anon;
SELECT throws_ok($$SELECT * FROM public.task_versions$$, '42501', NULL, 'anonymous users cannot read task versions');
SELECT throws_ok($$SELECT * FROM public.task_version_prompts$$, '42501', NULL, 'anonymous users cannot read task prompts');
SELECT throws_ok($$SELECT * FROM public.attempts$$, '42501', NULL, 'anonymous users cannot read learner attempts');
SELECT throws_ok($$SELECT * FROM public.attempt_responses$$, '42501', NULL, 'anonymous users cannot read learner responses');
SELECT throws_ok($$SELECT * FROM public.grader_assignments$$, '42501', NULL, 'anonymous users cannot read grader assignments');
RESET ROLE;

-- Student A can read only their own attempts and response content.
SET LOCAL ROLE authenticated;
SELECT set_config('request.jwt.claim.sub', '11111111-1111-4111-8111-111111111111', true);
SELECT set_config('request.jwt.claims', '{"sub":"11111111-1111-4111-8111-111111111111","role":"authenticated","aal":"aal1"}', true);
SELECT is((SELECT count(*)::integer FROM public.attempts), 2, 'student A sees only their two seeded attempts');
SELECT is((SELECT count(*)::integer FROM public.attempts WHERE id = 'c2222222-2222-4222-8222-222222222222'), 0, 'student A cannot see student B attempt');
SELECT is((SELECT count(*)::integer FROM public.attempt_responses WHERE attempt_id = 'c2222222-2222-4222-8222-222222222222'), 0, 'student A cannot see student B response content');
SELECT is((SELECT count(*)::integer FROM public.grader_assignments), 0, 'students cannot read grader assignment records');
SELECT throws_ok(
  $$INSERT INTO public.attempts (learner_id, task_version_id) VALUES ('22222222-2222-4222-8222-222222222222', 'a1111111-1111-4111-8111-111111111111')$$,
  '42501', NULL, 'student cannot create an attempt for another learner'
);
SELECT throws_ok(
  $$SELECT * FROM public.create_attempt('a2222222-2222-4222-8222-222222222222')$$,
  'P0002', 'attempt_task_not_available',
  'student cannot create an attempt without an active enrolment in the task pathway'
);
SELECT lives_ok(
  $$SELECT * FROM public.create_attempt('a1111111-1111-4111-8111-111111111111')$$,
  'student can start an in-progress attempt for an enrolled published typed task through the narrow RPC'
);
SELECT throws_ok(
  $$INSERT INTO public.attempts (learner_id, task_version_id) VALUES (auth.uid(), 'a1111111-1111-4111-8111-111111111111')$$,
  '42501', NULL, 'student cannot bypass the attempt-creation RPC'
);
SELECT is(
  (SELECT count(*)::integer FROM public.attempts WHERE learner_id = auth.uid() AND status = 'in_progress'),
  1,
  'new student attempt starts in progress'
);
SELECT lives_ok(
  $query$
    SELECT * FROM public.save_attempt_response(
      (SELECT id FROM public.attempts WHERE learner_id = auth.uid() AND status = 'in_progress'),
      'b1111111-1111-4111-8111-111111111111',
      'A first synthetic response with enough words to test versioning.'
    )
  $query$,
  'student can save a response to their own in-progress attempt through the narrow RPC'
);
SELECT is(
  (SELECT word_count FROM public.attempt_responses
   WHERE attempt_id = (SELECT id FROM public.attempts WHERE learner_id = auth.uid() AND status = 'in_progress')),
  10,
  'response word count is calculated by the database'
);
SELECT lives_ok(
  $query$
    SELECT * FROM public.save_attempt_response(
      (SELECT id FROM public.attempts WHERE learner_id = auth.uid() AND status = 'in_progress'),
      'b1111111-1111-4111-8111-111111111111',
      'A revised synthetic response increments the version without accepting a client version.'
    )
  $query$,
  'student can revise their own response through the narrow RPC while the attempt is in progress'
);
SELECT is(
  (SELECT version FROM public.attempt_responses
   WHERE attempt_id = (SELECT id FROM public.attempts WHERE learner_id = auth.uid() AND status = 'in_progress')),
  2,
  'response version is incremented by the database trigger'
);
SELECT throws_ok(
  $$UPDATE public.attempts SET status = 'submitted', submitted_at = now() WHERE learner_id = auth.uid() AND status = 'in_progress'$$,
  '42501', NULL, 'student cannot directly set submission status or timestamp'
);
SELECT throws_ok(
  $$INSERT INTO public.attempt_responses (attempt_id, task_version_id, prompt_id, response_text) VALUES ('c1111111-1111-4111-8111-111111111111', 'a1111111-1111-4111-8111-111111111111', 'b1111111-1111-4111-8111-111111111111', 'Direct response write')$$,
  '42501', NULL, 'student cannot bypass the response-save RPC'
);
SELECT throws_ok(
  $$SELECT * FROM private.attempt_response_versions$$,
  '42501', NULL, 'student cannot read private response version snapshots'
);
SELECT throws_ok(
  $$INSERT INTO public.grader_assignments (attempt_id, grader_user_id, assigned_by, reason) VALUES ('c3333333-3333-4333-8333-333333333333', '55555555-5555-4555-8555-555555555555', auth.uid(), 'Direct assignment attempt')$$,
  '42501', NULL, 'student cannot create grader assignments directly'
);
SELECT lives_ok(
  $$SELECT * FROM public.submit_attempt((SELECT id FROM public.attempts WHERE learner_id = auth.uid() AND status = 'in_progress'))$$,
  'student submits through the server-timestamped database operation'
);
SELECT is(
  (SELECT status FROM public.attempts WHERE learner_id = auth.uid() AND submitted_at > now() - interval '1 minute' ORDER BY submitted_at DESC LIMIT 1),
  'submitted',
  'server operation stamps the submitted state'
);
SELECT throws_ok(
  $$SELECT * FROM public.submit_attempt('c3333333-3333-4333-8333-333333333333')$$,
  'P0001', 'attempt_not_in_progress', 'student cannot submit an already submitted attempt again'
);
SELECT is(
  (SELECT count(*)::integer FROM public.attempts WHERE learner_id = auth.uid()),
  3,
  'student attempt count includes the newly created attempt'
);
RESET ROLE;

-- The verified guardian fixture has no submission-view consent; a revoked guardian link is also denied.
SET LOCAL ROLE authenticated;
SELECT set_config('request.jwt.claim.sub', '33333333-3333-4333-8333-333333333333', true);
SELECT set_config('request.jwt.claims', '{"sub":"33333333-3333-4333-8333-333333333333","role":"authenticated","aal":"aal1"}', true);
SELECT is((SELECT count(*)::integer FROM public.attempts), 0, 'guardian without submission consent cannot read learner attempts');
SELECT is((SELECT count(*)::integer FROM public.attempt_responses), 0, 'guardian without submission consent cannot read learner responses');
RESET ROLE;

SET LOCAL ROLE authenticated;
SELECT set_config('request.jwt.claim.sub', '44444444-4444-4444-8444-444444444444', true);
SELECT set_config('request.jwt.claims', '{"sub":"44444444-4444-4444-8444-444444444444","role":"authenticated","aal":"aal1"}', true);
SELECT is((SELECT count(*)::integer FROM public.attempts), 0, 'guardian with a revoked learner link cannot read attempts');
RESET ROLE;

-- Grader A receives only their assigned attempt, and only with AAL2.
SET LOCAL ROLE authenticated;
SELECT set_config('request.jwt.claim.sub', '55555555-5555-4555-8555-555555555555', true);
SELECT set_config('request.jwt.claims', '{"sub":"55555555-5555-4555-8555-555555555555","role":"authenticated","aal":"aal1"}', true);
SELECT is((SELECT count(*)::integer FROM public.attempts), 0, 'grader A at AAL1 cannot read assigned attempts');
SELECT is((SELECT count(*)::integer FROM public.attempt_responses), 0, 'grader A at AAL1 cannot read learner response content');
SELECT is((SELECT count(*)::integer FROM public.grader_assignments), 0, 'grader A at AAL1 cannot read assignment metadata');
SELECT set_config('request.jwt.claims', '{"sub":"55555555-5555-4555-8555-555555555555","role":"authenticated","aal":"aal2"}', true);
SELECT is((SELECT count(*)::integer FROM public.attempts), 1, 'grader A at AAL2 sees only their assigned submitted attempt');
SELECT is((SELECT count(*)::integer FROM public.attempts WHERE id = 'c2222222-2222-4222-8222-222222222222'), 0, 'grader A cannot see grader B assigned attempt');
SELECT is((SELECT count(*)::integer FROM public.attempt_responses), 1, 'grader A at AAL2 sees only the assigned response');
SELECT is((SELECT count(*)::integer FROM public.grader_assignments), 1, 'grader A at AAL2 sees only their assignment');
SELECT throws_ok(
  $$UPDATE public.attempts SET status = 'withdrawn' WHERE id = 'c1111111-1111-4111-8111-111111111111'$$,
  '42501', NULL, 'grader cannot directly change learner attempt status'
);
RESET ROLE;

-- Grader B cannot read grader A work.
SET LOCAL ROLE authenticated;
SELECT set_config('request.jwt.claim.sub', '66666666-6666-4666-8666-666666666666', true);
SELECT set_config('request.jwt.claims', '{"sub":"66666666-6666-4666-8666-666666666666","role":"authenticated","aal":"aal2"}', true);
SELECT is((SELECT count(*)::integer FROM public.attempts), 1, 'grader B sees only their assigned submitted attempt');
SELECT is((SELECT count(*)::integer FROM public.attempts WHERE id = 'c1111111-1111-4111-8111-111111111111'), 0, 'grader B cannot read grader A assigned attempt');
RESET ROLE;

-- Admin is not implicitly a grader or submission reader, even at AAL2.
SET LOCAL ROLE authenticated;
SELECT set_config('request.jwt.claim.sub', '77777777-7777-4777-8777-777777777777', true);
SELECT set_config('request.jwt.claims', '{"sub":"77777777-7777-4777-8777-777777777777","role":"authenticated","aal":"aal2"}', true);
SELECT is((SELECT count(*)::integer FROM public.attempts), 0, 'admin does not inherit grader or learner access');
SELECT is((SELECT count(*)::integer FROM public.grader_assignments), 0, 'admin cannot read grader assignment records by default');
RESET ROLE;

-- Owner access to learner work and assignment mutation both require AAL2.
SET LOCAL ROLE authenticated;
SELECT set_config('request.jwt.claim.sub', '88888888-8888-4888-8888-888888888888', true);
SELECT set_config('request.jwt.claims', '{"sub":"88888888-8888-4888-8888-888888888888","role":"authenticated","aal":"aal1"}', true);
SELECT is((SELECT count(*)::integer FROM public.attempts), 0, 'owner at AAL1 cannot read learner attempts');
SELECT throws_ok(
  $$SELECT * FROM public.assign_attempt_to_grader('c3333333-3333-4333-8333-333333333333', '55555555-5555-4555-8555-555555555555', 'Synthetic assignment test')$$,
  'P0001', 'mfa_required', 'owner at AAL1 cannot assign submitted attempts'
);
SELECT set_config('request.jwt.claims', '{"sub":"88888888-8888-4888-8888-888888888888","role":"authenticated","aal":"aal2"}', true);
SELECT is((SELECT count(*)::integer FROM public.attempts), 4, 'owner at AAL2 can inspect the seeded and newly submitted attempts');
SELECT lives_ok(
  $$SELECT * FROM public.assign_attempt_to_grader('c3333333-3333-4333-8333-333333333333', '55555555-5555-4555-8555-555555555555', 'Synthetic assignment test')$$,
  'owner at AAL2 can assign a submitted attempt to an active grader'
);
SELECT throws_ok(
  $$SELECT * FROM public.assign_attempt_to_grader('c3333333-3333-4333-8333-333333333333', '55555555-5555-4555-8555-555555555555', 'Duplicate assignment test')$$,
  'P0001', 'attempt_already_assigned', 'duplicate active assignments are rejected'
);
SELECT is(
  (SELECT count(*)::integer FROM public.grader_assignments WHERE attempt_id = 'c3333333-3333-4333-8333-333333333333' AND revoked_at IS NULL),
  1,
  'exactly one active assignment is retained for the attempt'
);
RESET ROLE;

SELECT is(
  (SELECT count(*)::integer
   FROM private.attempt_response_versions AS saved_version
   JOIN public.attempt_responses AS response ON response.id = saved_version.response_id
   JOIN public.attempts AS attempt ON attempt.id = response.attempt_id
   WHERE attempt.learner_id = '11111111-1111-4111-8111-111111111111'
     AND attempt.status = 'submitted'
     AND response.version = 2
     AND saved_version.attempt_id = attempt.id),
  2,
  'both meaningful versions of the new attempt response are preserved privately'
);

SELECT * FROM finish();
ROLLBACK;
