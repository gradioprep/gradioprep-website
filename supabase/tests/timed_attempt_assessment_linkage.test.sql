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

RESET ROLE;
SET LOCAL ROLE postgres;
WITH accepted AS (
  SELECT clock_timestamp() AS accepted_at
)
INSERT INTO public.assessment_submissions (
  id, learner_id, task_version_id, rubric_version_id, status,
  accepted_at, grading_due_at, sla_target_seconds,
  capacity_config_version, capacity_limit_snapshot,
  open_submissions_before_acceptance, idempotency_key, response_mode
)
SELECT
  'd3333333-3333-4333-8333-333333333333',
  '11111111-1111-4111-8111-111111111111',
  'a1111111-1111-4111-8111-111111111111',
  'f1111111-1111-4111-8111-111111111111',
  'queued', accepted.accepted_at,
  accepted.accepted_at + interval '24 hours', 86400,
  capacity.config_version, capacity.max_open_submissions,
  2, 'a0c0c0c0-0c0c-40c0-80c0-c0c0c0c0c0c0', 'pdf_only'
FROM accepted
CROSS JOIN private.grading_capacity_config AS capacity
WHERE capacity.singleton = true;

INSERT INTO timed_link_test_context (kind, submission_id, idempotency_key)
VALUES (
  'submission_pdf_only',
  'd3333333-3333-4333-8333-333333333333',
  'a0c0c0c0-0c0c-40c0-80c0-c0c0c0c0c0c0'
);

INSERT INTO private.submission_files (
  id, submission_id, learner_id, version_number, object_path,
  sha256, byte_size, mime_type, page_count, upload_state,
  created_at, updated_at, expires_at, accepted_at
)
VALUES (
  'd4444444-4444-4444-8444-444444444444',
  'd3333333-3333-4333-8333-333333333333',
  '11111111-1111-4111-8111-111111111111',
  1,
  'd4444444-4444-4444-8444-444444444444/d5555555-5555-4555-8555-555555555555.pdf',
  repeat('a', 64), 256, 'application/pdf', 1, 'accepted',
  clock_timestamp(), clock_timestamp(), clock_timestamp() + interval '100 years',
  clock_timestamp()
);

INSERT INTO private.submission_transcript_versions (
  id, submission_id, source_file_id, version_number, extraction_method,
  extraction_state, verification_state, page_count, pages, content_text,
  created_by, created_at
)
VALUES (
  'd6666666-6666-4666-8666-666666666666',
  'd3333333-3333-4333-8333-333333333333',
  'd4444444-4444-4444-8444-444444444444',
  1, 'pdfjs', 'none', 'unverified', 1,
  '[{"page_number":1,"text":"","status":"no_text_layer"}]'::jsonb,
  '', '11111111-1111-4111-8111-111111111111', clock_timestamp()
);
RESET ROLE;
SET LOCAL ROLE authenticated;
SELECT set_config('request.jwt.claims',
  '{"sub":"11111111-1111-4111-8111-111111111111","role":"authenticated","aal":"aal1"}',
  true);

-- Eligibility is rechecked during linkage, not trusted from the earlier acceptance.
RESET ROLE;
SET LOCAL ROLE postgres;
UPDATE public.course_enrolments
SET status = 'inactive'
WHERE learner_id = '11111111-1111-4111-8111-111111111111'
  AND pathway_id = 'synthetic-ib-myp-year-4';
RESET ROLE;
SET LOCAL ROLE authenticated;
SELECT set_config('request.jwt.claims',
  '{"sub":"11111111-1111-4111-8111-111111111111","role":"authenticated","aal":"aal1"}',
  true);
SELECT throws_ok(
  $SELECT * FROM public.link_timed_attempt_assessment_submission(
    (SELECT attempt_id FROM timed_link_test_context WHERE kind = 'attempt_primary'),
    (SELECT submission_id FROM timed_link_test_context WHERE kind = 'submission_primary'),
    'a0cccccc-cccc-4ccc-8ccc-cccccccccccc'
  )$,
  'P0001', 'assessment_submission_not_linkable',
  'an inactive course enrolment makes an otherwise matching attempt ineligible'
);
RESET ROLE;
SET LOCAL ROLE postgres;
UPDATE public.course_enrolments
SET status = 'active'
WHERE learner_id = '11111111-1111-4111-8111-111111111111'
  AND pathway_id = 'synthetic-ib-myp-year-4';
UPDATE public.task_versions
SET release_state = 'retired'
WHERE id = 'a3333333-3333-4333-8333-333333333333';
RESET ROLE;
SET LOCAL ROLE authenticated;
SELECT set_config('request.jwt.claims',
  '{"sub":"11111111-1111-4111-8111-111111111111","role":"authenticated","aal":"aal1"}',
  true);
SELECT throws_ok(
  $SELECT * FROM public.link_timed_attempt_assessment_submission(
    (SELECT attempt_id FROM timed_link_test_context WHERE kind = 'attempt_primary'),
    (SELECT submission_id FROM timed_link_test_context WHERE kind = 'submission_primary'),
    'a0dddddd-dddd-4ddd-8ddd-dddddddddddd'
  )$,
  'P0001', 'assessment_submission_not_linkable',
  'a retired task version cannot be linked'
);
RESET ROLE;
SET LOCAL ROLE postgres;
UPDATE public.task_versions
SET release_state = 'published'
WHERE id = 'a3333333-3333-4333-8333-333333333333';
UPDATE public.rubric_versions
SET release_state = 'retired'
WHERE id = 'f1111111-1111-4111-8111-111111111111';
RESET ROLE;
SET LOCAL ROLE authenticated;
SELECT set_config('request.jwt.claims',
  '{"sub":"11111111-1111-4111-8111-111111111111","role":"authenticated","aal":"aal1"}',
  true);
SELECT throws_ok(
  $SELECT * FROM public.link_timed_attempt_assessment_submission(
    (SELECT attempt_id FROM timed_link_test_context WHERE kind = 'attempt_primary'),
    (SELECT submission_id FROM timed_link_test_context WHERE kind = 'submission_primary'),
    'a0eeeeee-eeee-4eee-8eee-eeeeeeeeeeee'
  )$,
  'P0001', 'assessment_submission_not_linkable',
  'an unpublished or retired mapped rubric cannot be linked'
);
RESET ROLE;
SET LOCAL ROLE postgres;
UPDATE public.rubric_versions
SET release_state = 'published'
WHERE id = 'f1111111-1111-4111-8111-111111111111';
RESET ROLE;
SET LOCAL ROLE authenticated;
SELECT set_config('request.jwt.claims',
  '{"sub":"11111111-1111-4111-8111-111111111111","role":"authenticated","aal":"aal1"}',
  true);

SELECT lives_ok(
  $INSERT INTO timed_link_test_results
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
  1, 'one private typed-response link row is created (checked as database owner)'
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
    (SELECT submission_id FROM timed_link_test_context WHERE kind = 'submission_secondary'),
    'a0666666-6666-4666-8666-666666666666'
  )$$,
  'P0001', 'attempt_not_submitted',
  'an in-progress attempt cannot be linked before submission'
);
SELECT throws_ok(
  $q$SELECT * FROM public.link_timed_attempt_assessment_submission(
    (SELECT attempt_id FROM timed_link_test_context WHERE kind = 'attempt_other_task'),
    (SELECT submission_id FROM timed_link_test_context WHERE kind = 'submission_primary'),
    'a0777777-7777-4777-8777-777777777777'
  )$q$,
  'P0001', 'attempt_task_version_mismatch',
  'different task versions cannot be linked'
);

SELECT lives_ok(
  $q$INSERT INTO timed_link_test_results
    SELECT 'pdf_only', link_id, attempt_id, assessment_submission_id, is_replay
    FROM public.link_timed_attempt_assessment_submission(
      (SELECT attempt_id FROM timed_link_test_context WHERE kind = 'attempt_other_task'),
      (SELECT submission_id FROM timed_link_test_context WHERE kind = 'submission_pdf_only'),
      'a0d0d0d0-0d0d-40d0-80d0-d0d0d0d0d0d0'
    )$q$,
  'submitted matching attempt can link to an accepted PDF-only assessment with an original and transcript'
);
SELECT is(
  (SELECT is_replay FROM timed_link_test_results WHERE kind = 'pdf_only'),
  false, 'the PDF-only linkage is a first-time link'
);

RESET ROLE;
SET LOCAL ROLE postgres;
UPDATE public.assessment_submissions
SET status = 'feedback_published'
WHERE id = (SELECT submission_id FROM timed_link_test_context WHERE kind = 'submission_secondary');
RESET ROLE;
SET LOCAL ROLE authenticated;
SELECT set_config('request.jwt.claims',
  '{"sub":"11111111-1111-4111-8111-111111111111","role":"authenticated","aal":"aal1"}', true);
SELECT throws_ok(
  $SELECT * FROM public.link_timed_attempt_assessment_submission(
    (SELECT attempt_id FROM timed_link_test_context WHERE kind = 'attempt_secondary'),
    (SELECT submission_id FROM timed_link_test_context WHERE kind = 'submission_secondary'),
    'a0f0f0f0-f0f0-40f0-80f0-f0f0f0f0f0f0'
  )$,
  'P0001', 'assessment_submission_not_linkable',
  'a feedback-published submission is already graded and cannot be newly linked'
);
RESET ROLE;
SET LOCAL ROLE postgres;
UPDATE public.assessment_submissions
SET status = 'closed'
WHERE id = (SELECT submission_id FROM timed_link_test_context WHERE kind = 'submission_secondary');
RESET ROLE;
SET LOCAL ROLE authenticated;
SELECT set_config('request.jwt.claims',
  '{"sub":"11111111-1111-4111-8111-111111111111","role":"authenticated","aal":"aal1"}', true);
SELECT throws_ok(
  $SELECT * FROM public.link_timed_attempt_assessment_submission(
    (SELECT attempt_id FROM timed_link_test_context WHERE kind = 'attempt_secondary'),
    (SELECT submission_id FROM timed_link_test_context WHERE kind = 'submission_secondary'),
    'a0f1f1f1-f1f1-41f1-81f1-f1f1f1f1f1f1'
  )$,
  'P0001', 'assessment_submission_not_linkable',
  'a closed submission cannot be newly linked'
);
RESET ROLE;
SET LOCAL ROLE postgres;
UPDATE public.assessment_submissions
SET status = 'withdrawn'
WHERE id = (SELECT submission_id FROM timed_link_test_context WHERE kind = 'submission_secondary');
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
  2, 'only the accepted typed and PDF-only one-to-one links persist'
);
SELECT throws_ok(
  $$DELETE FROM private.timed_attempt_assessment_links$$,
  '42501', 'timed_attempt_assessment_link_immutable',
  'direct deletion cannot rewrite immutable link history'
);
RESET ROLE;

SELECT * FROM finish();
ROLLBACK;
