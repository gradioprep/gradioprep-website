BEGIN;
SELECT no_plan();

SELECT ok(
  has_function_privilege('authenticated',
    'public.link_timed_attempt_assessment_submission(uuid,uuid,uuid)', 'EXECUTE'),
  'authenticated learners can execute the narrow linkage RPC'
);
SELECT ok(
  NOT has_function_privilege('anon',
    'public.link_timed_attempt_assessment_submission(uuid,uuid,uuid)', 'EXECUTE'),
  'anonymous callers cannot execute the linkage RPC'
);
SELECT ok(
  NOT has_table_privilege('authenticated',
    'private.timed_attempt_assessment_links', 'SELECT'),
  'learners cannot directly read the private link table'
);
SET LOCAL ROLE anon;
SELECT throws_ok(
  $$SELECT * FROM private.timed_attempt_assessment_links$$,
  '42501', NULL, 'anonymous users cannot inspect private link rows'
);
RESET ROLE;

SET LOCAL ROLE postgres;
INSERT INTO public.course_enrolments (learner_id, pathway_id, status)
VALUES ('22222222-2222-4222-8222-222222222222',
        'synthetic-ib-myp-year-4', 'active')
ON CONFLICT (learner_id, pathway_id) DO UPDATE SET status = 'active';
RESET ROLE;

CREATE TEMP TABLE timed_link_test_context (
  kind text PRIMARY KEY,
  attempt_id uuid,
  submission_id uuid,
  idempotency_key uuid
);
CREATE TEMP TABLE timed_link_test_results (
  kind text PRIMARY KEY,
  link_id uuid,
  attempt_id uuid,
  submission_id uuid,
  is_replay boolean
);
GRANT SELECT, INSERT, UPDATE ON timed_link_test_context TO authenticated;
GRANT SELECT, INSERT ON timed_link_test_results TO authenticated;

SET LOCAL ROLE authenticated;
SELECT set_config('request.jwt.claims',
  '{"sub":"11111111-1111-4111-8111-111111111111","role":"authenticated","aal":"aal1"}', true);

INSERT INTO timed_link_test_context (kind, attempt_id)
SELECT 'attempt_primary', attempt_id
FROM public.create_attempt('a3333333-3333-4333-8333-333333333333');
SELECT lives_ok(
  $$SELECT * FROM public.save_attempt_response(
    (SELECT attempt_id FROM timed_link_test_context WHERE kind = 'attempt_primary'),
    'b3333333-3333-4333-8333-333333333333',
    'Synthetic timed response for the one-to-one assessment linkage regression test.'
  )$$,
  'student A can save a response for a synthetic timed attempt'
);
SELECT lives_ok(
  $$SELECT * FROM public.submit_attempt(
    (SELECT attempt_id FROM timed_link_test_context WHERE kind = 'attempt_primary')
  )$$,
  'student A can submit the timed attempt through the protected RPC'
);

INSERT INTO timed_link_test_context (kind, submission_id, idempotency_key)
SELECT 'submission_primary', submission_id, 'a0111111-1111-4111-8111-111111111111'
FROM public.accept_assessment_submission(
  'a3333333-3333-4333-8333-333333333333',
  'a0111111-1111-4111-8111-111111111111',
  'Synthetic human-assessment response for the matching published task and rubric.'
);

INSERT INTO timed_link_test_context (kind, attempt_id)
SELECT 'attempt_secondary', attempt_id
FROM public.create_attempt('a3333333-3333-4333-8333-333333333333');
SELECT lives_ok(
  $$SELECT * FROM public.save_attempt_response(
    (SELECT attempt_id FROM timed_link_test_context WHERE kind = 'attempt_secondary'),
    'b3333333-3333-4333-8333-333333333333',
    'Another synthetic timed response used only to test one-to-one linkage.'
  )$$,
  'a second synthetic attempt can save a response'
);
SELECT lives_ok(
  $$SELECT * FROM public.submit_attempt(
    (SELECT attempt_id FROM timed_link_test_context WHERE kind = 'attempt_secondary')
  )$$,
  'the second synthetic attempt is submitted'
);

INSERT INTO timed_link_test_context (kind, attempt_id)
SELECT 'attempt_pending', attempt_id
FROM public.create_attempt('a3333333-3333-4333-8333-333333333333');
SELECT lives_ok(
  $$SELECT * FROM public.save_attempt_response(
    (SELECT attempt_id FROM timed_link_test_context WHERE kind = 'attempt_pending'),
    'b3333333-3333-4333-8333-333333333333',
    'This saved response intentionally remains an in-progress attempt.'
  )$$,
  'the pending attempt has a saved response but is not submitted'
);

INSERT INTO timed_link_test_context (kind, attempt_id)
SELECT 'attempt_other_task', attempt_id
FROM public.create_attempt('a1111111-1111-4111-8111-111111111111');
SELECT lives_ok(
  $$SELECT * FROM public.save_attempt_response(
    (SELECT attempt_id FROM timed_link_test_context WHERE kind = 'attempt_other_task'),
    'b1111111-1111-4111-8111-111111111111',
    'Synthetic response for the different published task version.'
  )$$,
  'the different-task attempt has a saved response'
);
SELECT lives_ok(
  $$SELECT * FROM public.submit_attempt(
    (SELECT attempt_id FROM timed_link_test_context WHERE kind = 'attempt_other_task')
  )$$,
  'the different-task synthetic attempt is submitted'
);

INSERT INTO timed_link_test_context (kind, submission_id, idempotency_key)
SELECT 'submission_secondary', submission_id, 'a0222222-2222-4222-8222-222222222222'
FROM public.accept_assessment_submission(
  'a3333333-3333-4333-8333-333333333333',
  'a0222222-2222-4222-8222-222222222222',
  'A second synthetic human-assessment response for replay and withdrawn-state tests.'
);

SELECT lives_ok(
  $$INSERT INTO timed_link_test_results
    SELECT 'primary', link_id, attempt_id, assessment_submission_id, is_replay
    FROM public.link_timed_attempt_assessment_submission(
      (SELECT attempt_id FROM timed_link_test_context WHERE kind = 'attempt_primary'),
      (SELECT submission_id FROM timed_link_test_context WHERE kind = 'submission_primary'),
      'a0333333-3333-4333-8333-333333333333'
    )$$,
  'submitted same-learner same-task attempt links to its eligible human submission'
);
SELECT is(
  (SELECT is_replay FROM timed_link_test_results WHERE kind = 'primary'),
  false, 'the first linkage is not a replay'
);
RESET ROLE;
SET LOCAL ROLE postgres;
SELECT is(
  (SELECT count(*)::integer FROM private.timed_attempt_assessment_links),
  1, 'one private link row is created (checked as database owner)'
);
RESET ROLE;
SET LOCAL ROLE authenticated;
SELECT lives_ok(
  $$INSERT INTO timed_link_test_results
    SELECT 'replay', link_id, attempt_id, assessment_submission_id, is_replay
    FROM public.link_timed_attempt_assessment_submission(
      (SELECT attempt_id FROM timed_link_test_context WHERE kind = 'attempt_primary'),
      (SELECT submission_id FROM timed_link_test_context WHERE kind = 'submission_primary'),
      'a0333333-3333-4333-8333-333333333333'
    )$$,
  'an identical request can be retried'
);
SELECT is(
  (SELECT is_replay FROM timed_link_test_results WHERE kind = 'replay'),
  true, 'an identical retry is reported as a replay'
);
SELECT is(
  (SELECT link_id FROM timed_link_test_results WHERE kind = 'replay'),
  (SELECT link_id FROM timed_link_test_results WHERE kind = 'primary'),
  'an identical retry returns the original link ID'
);

SELECT throws_ok(
  $$SELECT * FROM public.link_timed_attempt_assessment_submission(
    (SELECT attempt_id FROM timed_link_test_context WHERE kind = 'attempt_primary'),
    (SELECT submission_id FROM timed_link_test_context WHERE kind = 'submission_secondary'),
    'a0444444-4444-4444-8444-444444444444'
  )$$,
  'P0001', 'timed_attempt_assessment_link_conflict',
  'one attempt cannot link to a second assessment'
);
SELECT throws_ok(
  $$SELECT * FROM public.link_timed_attempt_assessment_submission(
    (SELECT attempt_id FROM timed_link_test_context WHERE kind = 'attempt_secondary'),
    (SELECT submission_id FROM timed_link_test_context WHERE kind = 'submission_primary'),
    'a0555555-5555-4555-8555-555555555555'
  )$$,
  'P0001', 'timed_attempt_assessment_link_conflict',
  'one assessment cannot link to a second attempt'
);
SELECT throws_ok(
  $$SELECT * FROM public.link_timed_attempt_assessment_submission(
    (SELECT attempt_id FROM timed_link_test_context WHERE kind = 'attempt_secondary'),
    (SELECT submission_id FROM timed_link_test_context WHERE kind = 'submission_secondary'),
    'a0333333-3333-4333-8333-333333333333'
  )$$,
  'P0001', 'timed_attempt_assessment_link_idempotency_conflict',
  'an idempotency key cannot be reused for a different pair'
);
SELECT throws_ok(
  $$SELECT * FROM public.link_timed_attempt_assessment_submission(
    (SELECT attempt_id FROM timed_link_test_context WHERE kind = 'attempt_pending'),
    (SELECT submission_id FROM timed_link_test_context WHERE kind = 'submission_primary'),
    'a0666666-6666-4666-8666-666666666666'
  )$$,
  'P0001', 'attempt_not_submitted',
  'an in-progress attempt cannot be linked before submission'
);
SELECT throws_ok(
  $$SELECT * FROM public.link_timed_attempt_assessment_submission(
    (SELECT attempt_id FROM timed_link_test_context WHERE kind = 'attempt_other_task'),
    (SELECT submission_id FROM timed_link_test_context WHERE kind = 'submission_primary'),
    'a0777777-7777-4777-8777-777777777777'
  )$$,
  'P0001', 'attempt_task_version_mismatch',
  'different task versions cannot be linked'
);

RESET ROLE;
SET LOCAL ROLE authenticated;
SELECT set_config('request.jwt.claims',
  '{"sub":"22222222-2222-4222-8222-222222222222","role":"authenticated","aal":"aal1"}', true);
INSERT INTO timed_link_test_context (kind, submission_id, idempotency_key)
SELECT 'submission_other_learner', submission_id, 'a0888888-8888-4888-8888-888888888888'
FROM public.accept_assessment_submission(
  'a3333333-3333-4333-8333-333333333333',
  'a0888888-8888-4888-8888-888888888888',
  'Synthetic response owned only by Student B for cross-learner denial coverage.'
);
SELECT throws_ok(
  $$SELECT * FROM public.link_timed_attempt_assessment_submission(
    (SELECT attempt_id FROM timed_link_test_context WHERE kind = 'attempt_primary'),
    (SELECT submission_id FROM timed_link_test_context WHERE kind = 'submission_other_learner'),
    'a0999999-9999-4999-8999-999999999999'
  )$$,
  'P0002', 'attempt_not_found',
  'another learner cannot link using Student A attempt ID'
);

RESET ROLE;
SET LOCAL ROLE authenticated;
SELECT set_config('request.jwt.claims',
  '{"sub":"11111111-1111-4111-8111-111111111111","role":"authenticated","aal":"aal1"}', true);
SELECT throws_ok(
  $$SELECT * FROM public.link_timed_attempt_assessment_submission(
    (SELECT attempt_id FROM timed_link_test_context WHERE kind = 'attempt_primary'),
    (SELECT submission_id FROM timed_link_test_context WHERE kind = 'submission_other_learner'),
    'a0aaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa'
  )$$,
  'P0002', 'assessment_submission_not_found',
  'a learner cannot link their attempt to another learner submission'
);

RESET ROLE;
SET LOCAL ROLE postgres;
UPDATE public.assessment_submissions
SET status = 'withdrawn'
WHERE id = (SELECT submission_id FROM timed_link_test_context WHERE kind = 'submission_secondary');
RESET ROLE;
SET LOCAL ROLE authenticated;
SELECT set_config('request.jwt.claims',
  '{"sub":"11111111-1111-4111-8111-111111111111","role":"authenticated","aal":"aal1"}', true);
SELECT throws_ok(
  $$SELECT * FROM public.link_timed_attempt_assessment_submission(
    (SELECT attempt_id FROM timed_link_test_context WHERE kind = 'attempt_secondary'),
    (SELECT submission_id FROM timed_link_test_context WHERE kind = 'submission_secondary'),
    'a0bbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbbb'
  )$$,
  'P0001', 'assessment_submission_not_linkable',
  'withdrawn assessment submissions cannot be linked'
);

RESET ROLE;
SET LOCAL ROLE postgres;
SELECT is(
  (SELECT count(*)::integer FROM private.timed_attempt_assessment_links),
  1, 'rejected and replay-conflict requests leave only the original link'
);
SELECT throws_ok(
  $$DELETE FROM private.timed_attempt_assessment_links$$,
  '42501', 'timed_attempt_assessment_link_immutable',
  'direct deletion cannot rewrite immutable link history'
);
RESET ROLE;

SELECT * FROM finish();
ROLLBACK;
