BEGIN;
SELECT no_plan();

-- The private timer history is unavailable to browser roles.
SET LOCAL ROLE anon;
SELECT throws_ok(
  $$SELECT * FROM private.attempt_timer_sessions$$,
  '42501', NULL, 'anonymous users cannot read timer session snapshots'
);
SELECT throws_ok(
  $$SELECT * FROM private.attempt_timer_events$$,
  '42501', NULL, 'anonymous users cannot read timer event history'
);
RESET ROLE;

-- Create an intentionally old synthetic attempt as the database owner so the
-- test can check the zero-time boundary without sleeping or trusting a client clock.
SET LOCAL ROLE postgres;
UPDATE public.task_versions
SET time_allowance_seconds = 60, timer_policy_version = 1
WHERE id = 'a3333333-3333-4333-8333-333333333333';

INSERT INTO public.attempts (
  id, learner_id, task_version_id, status, started_at, created_at, updated_at
)
VALUES (
  'c4444444-4444-4444-8444-444444444444',
  '11111111-1111-4111-8111-111111111111',
  'a3333333-3333-4333-8333-333333333333',
  'in_progress',
  clock_timestamp() - interval '5 minutes',
  clock_timestamp() - interval '5 minutes',
  clock_timestamp()
);
RESET ROLE;

-- The learner can read their own server-derived timer state, but cannot supply
-- or influence the server clock, deadline, allowance or task-policy snapshot.
SET LOCAL ROLE authenticated;
SELECT set_config('request.jwt.claim.sub', '11111111-1111-4111-8111-111111111111', true);
SELECT set_config('request.jwt.claims', '{"sub":"11111111-1111-4111-8111-111111111111","role":"authenticated","aal":"aal1"}', true);
SELECT is(
  (SELECT allowance_seconds FROM public.get_learner_attempt_timer('c4444444-4444-4444-8444-444444444444')),
  60,
  'attempt timer snapshots the task-version allowance at server-recorded start'
);
SELECT is(
  (SELECT timer_policy_version FROM public.get_learner_attempt_timer('c4444444-4444-4444-8444-444444444444')),
  1::smallint,
  'attempt timer snapshots the task-policy version'
);
SELECT is(
  (SELECT is_expired FROM public.get_learner_attempt_timer('c4444444-4444-4444-8444-444444444444')),
  true,
  'database clock reports the old synthetic attempt as expired'
);
SELECT is(
  (SELECT remaining_seconds FROM public.get_learner_attempt_timer('c4444444-4444-4444-8444-444444444444')),
  0,
  'remaining time is clamped to zero after expiry'
);
SELECT is(
  (SELECT status FROM public.attempts WHERE id = 'c4444444-4444-4444-8444-444444444444'),
  'in_progress',
  'timer expiry does not auto-submit or change attempt state'
);

-- A different learner and a guardian cannot use the learner timer function.
SELECT set_config('request.jwt.claim.sub', '22222222-2222-4222-8222-222222222222', true);
SELECT set_config('request.jwt.claims', '{"sub":"22222222-2222-4222-8222-222222222222","role":"authenticated","aal":"aal1"}', true);
SELECT throws_ok(
  $$SELECT * FROM public.get_learner_attempt_timer('c4444444-4444-4444-8444-444444444444')$$,
  'P0002', 'attempt_not_found', 'another student cannot read the private timer state'
);
SELECT set_config('request.jwt.claim.sub', '33333333-3333-4333-8333-333333333333', true);
SELECT set_config('request.jwt.claims', '{"sub":"33333333-3333-4333-8333-333333333333","role":"authenticated","aal":"aal1"}', true);
SELECT throws_ok(
  $$SELECT * FROM public.get_learner_attempt_timer('c4444444-4444-4444-8444-444444444444')$$,
  '42501', 'attempt_timer_forbidden', 'guardian cannot read the learner timer state'
);

-- Returning to the learner, saving remains available after the advisory limit.
SELECT set_config('request.jwt.claim.sub', '11111111-1111-4111-8111-111111111111', true);
SELECT set_config('request.jwt.claims', '{"sub":"11111111-1111-4111-8111-111111111111","role":"authenticated","aal":"aal1"}', true);
SELECT lives_ok(
  $$SELECT * FROM public.save_attempt_response(
    'c4444444-4444-4444-8444-444444444444',
    'b3333333-3333-4333-8333-333333333333',
    'This synthetic response is deliberately saved after the advisory timer has reached zero.'
  )$$,
  'learner can save a response after the advisory timer expires'
);
SELECT lives_ok(
  $$SELECT * FROM public.submit_attempt('c4444444-4444-4444-8444-444444444444')$$,
  'learner can submit after the advisory timer expires'
);

RESET ROLE;
SET LOCAL ROLE postgres;
SELECT is(
  (SELECT count(*)::integer FROM private.attempt_timer_events
   WHERE attempt_id = 'c4444444-4444-4444-8444-444444444444' AND event_type = 'started'),
  1,
  'start event is recorded exactly once'
);
SELECT is(
  (SELECT count(*)::integer FROM private.attempt_timer_events
   WHERE attempt_id = 'c4444444-4444-4444-8444-444444444444' AND event_type = 'expired'),
  1,
  'repeated timer reads record expiry only once'
);
SELECT is(
  (SELECT count(*)::integer FROM private.attempt_timer_events
   WHERE attempt_id = 'c4444444-4444-4444-8444-444444444444' AND event_type = 'response_saved'),
  1,
  'a response_saved event contains timing metadata only'
);
SELECT is(
  (SELECT count(*)::integer FROM private.attempt_timer_events
   WHERE attempt_id = 'c4444444-4444-4444-8444-444444444444' AND event_type = 'submitted'),
  1,
  'submission event is recorded exactly once'
);
SELECT is(
  (SELECT count(*)::integer FROM private.attempt_timer_events
   WHERE attempt_id = 'c4444444-4444-4444-8444-444444444444'),
  4,
  'event stream contains only start, expiry, save and submission events'
);
SELECT is(
  (SELECT count(*)::integer FROM information_schema.columns
   WHERE table_schema = 'private' AND table_name = 'attempt_timer_events'
     AND column_name IN ('response_text', 'keystrokes', 'focus_events')),
  0,
  'timer events do not store response text, keystrokes or attention signals'
);
RESET ROLE;

SELECT * FROM finish();
ROLLBACK;
