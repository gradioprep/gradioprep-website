BEGIN;
SELECT no_plan();

-- The private material and server functions are unavailable to learners.
SELECT ok(
  NOT has_table_privilege('authenticated', 'private.assessment_response_analytics', 'SELECT'),
  'authenticated users have no direct access to derived analytics'
);
SELECT ok(
  NOT has_table_privilege('service_role', 'private.assessment_response_analytics', 'SELECT'),
  'the Worker service role has no direct access to derived analytics'
);
SELECT ok(
  has_function_privilege('authenticated',
    'public.get_assigned_assessment_response_analytics(uuid)', 'EXECUTE'),
  'authenticated requests can use only the narrowly guarded assigned-Grader read RPC'
);
SELECT ok(
  NOT has_function_privilege('anon',
    'public.get_assigned_assessment_response_analytics(uuid)', 'EXECUTE'),
  'anonymous callers cannot execute the analytics read RPC'
);
SET LOCAL ROLE anon;
SELECT throws_ok(
  $$SELECT * FROM private.assessment_response_analytics$$,
  '42501', NULL, 'anonymous callers cannot inspect derived analytics'
);
RESET ROLE;

CREATE TEMP TABLE analytics_test_context (
  kind text PRIMARY KEY,
  attempt_id uuid,
  submission_id uuid
);
INSERT INTO analytics_test_context (kind) VALUES ('unlinked'), ('unpublished');
GRANT SELECT, INSERT, UPDATE ON analytics_test_context TO authenticated;

-- Provide only synthetic CI queue capacity and a known timed task allowance.
-- All changes remain in this test transaction and are rolled back at the end.
SET LOCAL ROLE postgres;
UPDATE public.task_versions
SET time_allowance_seconds = 600, timer_policy_version = 1
WHERE id = 'a3333333-3333-4333-8333-333333333333';
UPDATE private.grading_capacity_config
SET max_open_submissions = 10,
    config_version = config_version + 1,
    updated_at = clock_timestamp()
WHERE singleton = true;
RESET ROLE;

-- Create three attempts and a fourth assessment without a timer link. The
-- task allowance and timer clock are snapshotted by the database on creation.
SET LOCAL ROLE authenticated;
SELECT set_config('request.jwt.claims',
  '{"sub":"11111111-1111-4111-8111-111111111111","role":"authenticated","aal":"aal1"}', true);

INSERT INTO analytics_test_context (kind, attempt_id)
SELECT 'regular', attempt_id
FROM public.create_attempt('a3333333-3333-4333-8333-333333333333');

INSERT INTO analytics_test_context (kind, attempt_id)
SELECT 'extended', attempt_id
FROM public.create_attempt('a3333333-3333-4333-8333-333333333333');

INSERT INTO analytics_test_context (kind, attempt_id)
SELECT 'untimed', attempt_id
FROM public.create_attempt('a3333333-3333-4333-8333-333333333333');

SELECT lives_ok(
  $$SELECT * FROM public.save_attempt_response(
    (SELECT attempt_id FROM analytics_test_context WHERE kind = 'regular'),
    'b3333333-3333-4333-8333-333333333333',
    'Synthetic regular timed response with sufficient evidence for rubric scoring.'
  )$$,
  'regular timed response is saved through the learner RPC'
);
SELECT lives_ok(
  $$SELECT * FROM public.save_attempt_response(
    (SELECT attempt_id FROM analytics_test_context WHERE kind = 'extended'),
    'b3333333-3333-4333-8333-333333333333',
    'Synthetic extended timed response with sufficient evidence for rubric scoring.'
  )$$,
  'extended response is saved through the learner RPC'
);
SELECT lives_ok(
  $$SELECT * FROM public.save_attempt_response(
    (SELECT attempt_id FROM analytics_test_context WHERE kind = 'untimed'),
    'b3333333-3333-4333-8333-333333333333',
    'Synthetic accommodated untimed response with sufficient evidence for rubric scoring.'
  )$$,
  'untimed accommodated response is saved through the learner RPC'
);
RESET ROLE;

-- The original session snapshot remains immutable. Adjustments are a separate
-- append-only history and the latest effective allowance determines the label.
SET LOCAL ROLE authenticated;
SELECT set_config('request.jwt.claims',
  '{"sub":"88888888-8888-4888-8888-888888888888","role":"authenticated","aal":"aal2"}', true);
SELECT lives_ok(
  $$SELECT * FROM public.authorise_attempt_timer_adjustment(
    (SELECT attempt_id FROM analytics_test_context WHERE kind = 'extended'),
    'extended', 120, 'approved_extension'
  )$$,
  'Owner AAL2 authorises a bounded synthetic extension'
);
SELECT lives_ok(
  $$SELECT * FROM public.authorise_attempt_timer_adjustment(
    (SELECT attempt_id FROM analytics_test_context WHERE kind = 'untimed'),
    'untimed', NULL, 'accessibility_accommodation'
  )$$,
  'Owner AAL2 authorises a synthetic untimed accommodation'
);
RESET ROLE;

SET LOCAL ROLE authenticated;
SELECT set_config('request.jwt.claims',
  '{"sub":"11111111-1111-4111-8111-111111111111","role":"authenticated","aal":"aal1"}', true);
SELECT lives_ok(
  $$SELECT * FROM public.submit_attempt(
    (SELECT attempt_id FROM analytics_test_context WHERE kind = 'regular')
  )$$,
  'regular timed attempt is submitted'
);
SELECT lives_ok(
  $$SELECT * FROM public.submit_attempt(
    (SELECT attempt_id FROM analytics_test_context WHERE kind = 'extended')
  )$$,
  'extended timed attempt is submitted'
);
SELECT lives_ok(
  $$SELECT * FROM public.submit_attempt(
    (SELECT attempt_id FROM analytics_test_context WHERE kind = 'untimed')
  )$$,
  'untimed accommodated attempt is submitted'
);

UPDATE analytics_test_context SET submission_id = (
  SELECT submission_id FROM public.accept_assessment_submission(
    'a3333333-3333-4333-8333-333333333333',
    'a1010101-1010-4101-8101-101010101010',
    'Synthetic regular human assessment response for rubric-bound analytics.'
  )
) WHERE kind = 'regular';
UPDATE analytics_test_context SET submission_id = (
  SELECT submission_id FROM public.accept_assessment_submission(
    'a3333333-3333-4333-8333-333333333333',
    'a2020202-2020-4202-8202-202020202020',
    'Synthetic extended human assessment response for rubric-bound analytics.'
  )
) WHERE kind = 'extended';
UPDATE analytics_test_context SET submission_id = (
  SELECT submission_id FROM public.accept_assessment_submission(
    'a3333333-3333-4333-8333-333333333333',
    'a3030303-3030-4303-8303-303030303030',
    'Synthetic untimed human assessment response for rubric-bound analytics.'
  )
) WHERE kind = 'untimed';
UPDATE analytics_test_context SET submission_id = (
  SELECT submission_id FROM public.accept_assessment_submission(
    'a3333333-3333-4333-8333-333333333333',
    'a4040404-4040-4404-8404-404040404040',
    'Synthetic unlinked human assessment response with no timed practice attempt.'
  )
) WHERE kind = 'unlinked';
UPDATE analytics_test_context SET submission_id = (
  SELECT submission_id FROM public.accept_assessment_submission(
    'a3333333-3333-4333-8333-333333333333',
    'a5050505-5050-4505-8505-505050505050',
    'Synthetic unpublished grading draft used for analytics privacy regression.'
  )
) WHERE kind = 'unpublished';

SELECT lives_ok(
  $$SELECT * FROM public.link_timed_attempt_assessment_submission(
    (SELECT attempt_id FROM analytics_test_context WHERE kind = 'regular'),
    (SELECT submission_id FROM analytics_test_context WHERE kind = 'regular'),
    'a1111111-1111-4111-8111-111111111111'
  )$$,
  'regular timed attempt links to the same learner and task-version assessment'
);
SELECT lives_ok(
  $$SELECT * FROM public.link_timed_attempt_assessment_submission(
    (SELECT attempt_id FROM analytics_test_context WHERE kind = 'extended'),
    (SELECT submission_id FROM analytics_test_context WHERE kind = 'extended'),
    'a2222222-2222-4222-8222-222222222222'
  )$$,
  'extended attempt links to its matching human assessment'
);
SELECT lives_ok(
  $$SELECT * FROM public.link_timed_attempt_assessment_submission(
    (SELECT attempt_id FROM analytics_test_context WHERE kind = 'untimed'),
    (SELECT submission_id FROM analytics_test_context WHERE kind = 'untimed'),
    'a3333333-3333-4333-8333-333333333333'
  )$$,
  'untimed accommodated attempt links to its matching human assessment'
);
RESET ROLE;

-- Owner assignment, then human grader draft/publication. No analytics exist for
-- an unpublished private draft.
SET LOCAL ROLE authenticated;
SELECT set_config('request.jwt.claims',
  '{"sub":"88888888-8888-4888-8888-888888888888","role":"authenticated","aal":"aal2"}', true);
SELECT lives_ok(
  $$SELECT * FROM public.assign_submission_to_grader(
    (SELECT submission_id FROM analytics_test_context WHERE kind = 'regular'),
    '55555555-5555-4555-8555-555555555555',
    'Synthetic analytics regression assignment'
  )$$,
  'Owner AAL2 assigns regular assessment to Grader A'
);
SELECT lives_ok(
  $$SELECT * FROM public.assign_submission_to_grader(
    (SELECT submission_id FROM analytics_test_context WHERE kind = 'extended'),
    '55555555-5555-4555-8555-555555555555',
    'Synthetic analytics regression assignment'
  )$$,
  'Owner AAL2 assigns extended assessment to Grader A'
);
SELECT lives_ok(
  $$SELECT * FROM public.assign_submission_to_grader(
    (SELECT submission_id FROM analytics_test_context WHERE kind = 'untimed'),
    '55555555-5555-4555-8555-555555555555',
    'Synthetic analytics regression assignment'
  )$$,
  'Owner AAL2 assigns untimed assessment to Grader A'
);
SELECT lives_ok(
  $$SELECT * FROM public.assign_submission_to_grader(
    (SELECT submission_id FROM analytics_test_context WHERE kind = 'unlinked'),
    '55555555-5555-4555-8555-555555555555',
    'Synthetic analytics regression assignment'
  )$$,
  'Owner AAL2 assigns unlinked assessment to Grader A'
);
SELECT lives_ok(
  $$SELECT * FROM public.assign_submission_to_grader(
    (SELECT submission_id FROM analytics_test_context WHERE kind = 'unpublished'),
    '55555555-5555-4555-8555-555555555555',
    'Synthetic unpublished analytics privacy assignment'
  )$$,
  'Owner AAL2 assigns unpublished assessment to Grader A'
);
RESET ROLE;

SET LOCAL ROLE authenticated;
SELECT set_config('request.jwt.claims',
  '{"sub":"55555555-5555-4555-8555-555555555555","role":"authenticated","aal":"aal2"}', true);

CREATE TEMP TABLE analytics_test_results (kind text PRIMARY KEY, assessment_version_id uuid);
GRANT SELECT, INSERT ON analytics_test_results TO authenticated;

-- A helper-shaped repeated SQL block intentionally uses only rubric criteria
-- belonging to the exact immutable rubric version on each submission.
SELECT lives_ok(
  $$SELECT * FROM public.save_assessment_draft(
    (SELECT submission_id FROM analytics_test_context WHERE kind = 'regular'),
    'Synthetic human feedback for regular response with evidence-based comments.',
    NULL,
    (SELECT jsonb_agg(jsonb_build_object(
      'criterion_id', criterion.id,
      'points_awarded', least(3::numeric, criterion.max_points),
      'feedback', 'Synthetic criterion feedback grounded in the response.'
    ) ORDER BY criterion.sequence)
    FROM public.rubric_criteria AS criterion
    WHERE criterion.rubric_version_id = (
      SELECT submission.rubric_version_id FROM public.assessment_submissions AS submission
      WHERE submission.id = (SELECT submission_id FROM analytics_test_context WHERE kind = 'regular')
    ))
  )$$,
  'assigned Grader saves private regular draft against exact rubric version'
);
INSERT INTO analytics_test_results (kind, assessment_version_id)
SELECT 'regular', assessment_version_id
FROM public.publish_assessment_feedback(
  (SELECT submission_id FROM analytics_test_context WHERE kind = 'regular')
);
SELECT lives_ok(
  $$SELECT * FROM public.save_assessment_draft(
    (SELECT submission_id FROM analytics_test_context WHERE kind = 'extended'),
    'Synthetic human feedback for extended response with evidence-based comments.',
    NULL,
    (SELECT jsonb_agg(jsonb_build_object(
      'criterion_id', criterion.id,
      'points_awarded', least(3::numeric, criterion.max_points),
      'feedback', 'Synthetic criterion feedback grounded in the response.'
    ) ORDER BY criterion.sequence)
    FROM public.rubric_criteria AS criterion
    WHERE criterion.rubric_version_id = (
      SELECT submission.rubric_version_id FROM public.assessment_submissions AS submission
      WHERE submission.id = (SELECT submission_id FROM analytics_test_context WHERE kind = 'extended')
    ))
  )$$,
  'assigned Grader saves private extended draft against exact rubric version'
);
INSERT INTO analytics_test_results (kind, assessment_version_id)
SELECT 'extended', assessment_version_id
FROM public.publish_assessment_feedback(
  (SELECT submission_id FROM analytics_test_context WHERE kind = 'extended')
);
SELECT lives_ok(
  $$SELECT * FROM public.save_assessment_draft(
    (SELECT submission_id FROM analytics_test_context WHERE kind = 'untimed'),
    'Synthetic human feedback for untimed response with evidence-based comments.',
    NULL,
    (SELECT jsonb_agg(jsonb_build_object(
      'criterion_id', criterion.id,
      'points_awarded', least(3::numeric, criterion.max_points),
      'feedback', 'Synthetic criterion feedback grounded in the response.'
    ) ORDER BY criterion.sequence)
    FROM public.rubric_criteria AS criterion
    WHERE criterion.rubric_version_id = (
      SELECT submission.rubric_version_id FROM public.assessment_submissions AS submission
      WHERE submission.id = (SELECT submission_id FROM analytics_test_context WHERE kind = 'untimed')
    ))
  )$$,
  'assigned Grader saves private untimed draft against exact rubric version'
);
INSERT INTO analytics_test_results (kind, assessment_version_id)
SELECT 'untimed', assessment_version_id
FROM public.publish_assessment_feedback(
  (SELECT submission_id FROM analytics_test_context WHERE kind = 'untimed')
);
SELECT lives_ok(
  $$SELECT * FROM public.save_assessment_draft(
    (SELECT submission_id FROM analytics_test_context WHERE kind = 'unlinked'),
    'Synthetic human feedback for unlinked response with evidence-based comments.',
    NULL,
    (SELECT jsonb_agg(jsonb_build_object(
      'criterion_id', criterion.id,
      'points_awarded', least(3::numeric, criterion.max_points),
      'feedback', 'Synthetic criterion feedback grounded in the response.'
    ) ORDER BY criterion.sequence)
    FROM public.rubric_criteria AS criterion
    WHERE criterion.rubric_version_id = (
      SELECT submission.rubric_version_id FROM public.assessment_submissions AS submission
      WHERE submission.id = (SELECT submission_id FROM analytics_test_context WHERE kind = 'unlinked')
    ))
  )$$,
  'assigned Grader saves private unlinked draft against exact rubric version'
);
INSERT INTO analytics_test_results (kind, assessment_version_id)
SELECT 'unlinked', assessment_version_id
FROM public.publish_assessment_feedback(
  (SELECT submission_id FROM analytics_test_context WHERE kind = 'unlinked')
);
SELECT lives_ok(
  $$SELECT * FROM public.save_assessment_draft(
    (SELECT submission_id FROM analytics_test_context WHERE kind = 'unpublished'),
    'Synthetic unpublished draft stays private and creates no analytics.',
    NULL,
    (SELECT jsonb_agg(jsonb_build_object(
      'criterion_id', criterion.id,
      'points_awarded', least(3::numeric, criterion.max_points),
      'feedback', 'Private draft-only criterion feedback.'
    ) ORDER BY criterion.sequence)
    FROM public.rubric_criteria AS criterion
    WHERE criterion.rubric_version_id = (
      SELECT submission.rubric_version_id FROM public.assessment_submissions AS submission
      WHERE submission.id = (SELECT submission_id FROM analytics_test_context WHERE kind = 'unpublished')
    ))
  )$$,
  'assigned Grader can save an unpublished private draft'
);

RESET ROLE;

-- Deferred analytics derivation waits until all criterion snapshot rows from
-- the publication transaction exist.
SET CONSTRAINTS ALL IMMEDIATE;

SET LOCAL ROLE postgres;
SELECT is(
  (SELECT count(*)::integer FROM private.assessment_response_analytics),
  4,
  'one immutable analytics row is derived for every human-published version'
);
SELECT is(
  (SELECT count(*)::integer FROM information_schema.columns
   WHERE table_schema = 'private'
     AND table_name = 'assessment_response_analytics'
     AND column_name IN (
       'response_text', 'feedback', 'diagnosis', 'keystrokes',
       'focus_events', 'active_attention_seconds', 'speed_rank', 'percentile'
     )),
  0,
  'derived analytics never store response/feedback text, diagnosis, attention or public rank fields'
);
SELECT is(
  (SELECT count(*)::integer FROM private.assessment_response_analytics
   WHERE submission_id = (SELECT submission_id FROM analytics_test_context WHERE kind = 'unpublished')),
  0,
  'an unpublished private draft creates no analytics record'
);
SELECT is(
  (SELECT attainment_status FROM private.assessment_response_analytics
   WHERE assessment_version_id = (SELECT assessment_version_id FROM analytics_test_results WHERE kind = 'regular')),
  'valid',
  'published score is validated against every rubric criterion snapshot'
);
SELECT is(
  (SELECT attainment_percent FROM private.assessment_response_analytics
   WHERE assessment_version_id = (SELECT assessment_version_id FROM analytics_test_results WHERE kind = 'regular')),
  (SELECT round(total_points / max_points * 100, 3)::numeric(6,3)
   FROM public.assessment_versions
   WHERE id = (SELECT assessment_version_id FROM analytics_test_results WHERE kind = 'regular')),
  'attainment is derived using the published assessment score and its exact denominator'
);
SELECT is(
  (SELECT score_awarded FROM private.assessment_response_analytics
   WHERE assessment_version_id = (SELECT assessment_version_id FROM analytics_test_results WHERE kind = 'regular')),
  (SELECT total_points FROM public.assessment_versions
   WHERE id = (SELECT assessment_version_id FROM analytics_test_results WHERE kind = 'regular')),
  'analytics preserve the published awarded-score snapshot'
);
SELECT is(
  (SELECT score_max FROM private.assessment_response_analytics
   WHERE assessment_version_id = (SELECT assessment_version_id FROM analytics_test_results WHERE kind = 'regular')),
  (SELECT max_points FROM public.assessment_versions
   WHERE id = (SELECT assessment_version_id FROM analytics_test_results WHERE kind = 'regular')),
  'analytics preserve the published maximum-score denominator'
);

SELECT is(
  (SELECT elapsed_response_status FROM private.assessment_response_analytics
   WHERE assessment_version_id = (SELECT assessment_version_id FROM analytics_test_results WHERE kind = 'regular')),
  'valid',
  'linked regular attempt has a valid server timer interval'
);
SELECT is(
  (SELECT elapsed_response_seconds FROM private.assessment_response_analytics
   WHERE assessment_version_id = (SELECT assessment_version_id FROM analytics_test_results WHERE kind = 'regular')),
  (SELECT floor(extract(epoch FROM (attempt.submitted_at - timer.started_at)))::bigint
   FROM public.attempts AS attempt
   JOIN private.attempt_timer_sessions AS timer ON timer.attempt_id = attempt.id
   WHERE attempt.id = (SELECT attempt_id FROM analytics_test_context WHERE kind = 'regular')),
  'elapsed response uses only server attempt-start and submit timestamps'
);
SELECT is(
  (SELECT timer_mode FROM private.assessment_response_analytics
   WHERE assessment_version_id = (SELECT assessment_version_id FROM analytics_test_results WHERE kind = 'regular')),
  'timed',
  'regular attempt is labelled timed'
);
SELECT is(
  (SELECT accommodation_mode FROM private.assessment_response_analytics
   WHERE assessment_version_id = (SELECT assessment_version_id FROM analytics_test_results WHERE kind = 'regular')),
  'none',
  'regular attempt is not marked as accommodated'
);
SELECT is(
  (SELECT comparability_status FROM private.assessment_response_analytics
   WHERE assessment_version_id = (SELECT assessment_version_id FROM analytics_test_results WHERE kind = 'regular')),
  'eligible',
  'regular score/time pair is eligible only within an exact context group'
);

SELECT is(
  (SELECT accommodation_mode FROM private.assessment_response_analytics
   WHERE assessment_version_id = (SELECT assessment_version_id FROM analytics_test_results WHERE kind = 'extended')),
  'extended',
  'extended adjustment remains explicitly labelled'
);
SELECT is(
  (SELECT effective_allowance_seconds FROM private.assessment_response_analytics
   WHERE assessment_version_id = (SELECT assessment_version_id FROM analytics_test_results WHERE kind = 'extended')),
  (SELECT allowance_seconds + 120 FROM private.attempt_timer_sessions
   WHERE attempt_id = (SELECT attempt_id FROM analytics_test_context WHERE kind = 'extended')),
  'extended allowance is derived from the immutable base snapshot and adjustment history'
);
SELECT is(
  (SELECT adjustment_count FROM private.assessment_response_analytics
   WHERE assessment_version_id = (SELECT assessment_version_id FROM analytics_test_results WHERE kind = 'extended')),
  1,
  'the append-only adjustment count is retained'
);
SELECT isnt(
  (SELECT comparison_group_key FROM private.assessment_response_analytics
   WHERE assessment_version_id = (SELECT assessment_version_id FROM analytics_test_results WHERE kind = 'regular')),
  (SELECT comparison_group_key FROM private.assessment_response_analytics
   WHERE assessment_version_id = (SELECT assessment_version_id FROM analytics_test_results WHERE kind = 'extended')),
  'regular and extended contexts are never pooled together'
);

SELECT is(
  (SELECT timer_mode FROM private.assessment_response_analytics
   WHERE assessment_version_id = (SELECT assessment_version_id FROM analytics_test_results WHERE kind = 'untimed')),
  'untimed',
  'untimed accommodation has no elapsed countdown mode'
);
SELECT is(
  (SELECT accommodation_mode FROM private.assessment_response_analytics
   WHERE assessment_version_id = (SELECT assessment_version_id FROM analytics_test_results WHERE kind = 'untimed')),
  'untimed',
  'untimed accommodation is distinguished from a task authored as untimed'
);
SELECT is(
  (SELECT effective_allowance_seconds FROM private.assessment_response_analytics
   WHERE assessment_version_id = (SELECT assessment_version_id FROM analytics_test_results WHERE kind = 'untimed')),
  NULL::integer,
  'untimed accommodation has a null effective allowance'
);
SELECT isnt(
  (SELECT comparison_group_key FROM private.assessment_response_analytics
   WHERE assessment_version_id = (SELECT assessment_version_id FROM analytics_test_results WHERE kind = 'regular')),
  (SELECT comparison_group_key FROM private.assessment_response_analytics
   WHERE assessment_version_id = (SELECT assessment_version_id FROM analytics_test_results WHERE kind = 'untimed')),
  'timed and untimed response contexts are never pooled together'
);

SELECT is(
  (SELECT elapsed_response_status FROM private.assessment_response_analytics
   WHERE assessment_version_id = (SELECT assessment_version_id FROM analytics_test_results WHERE kind = 'unlinked')),
  'not_linked',
  'published assessment without a timed-attempt link is explicitly marked missing timing'
);
SELECT is(
  (SELECT comparability_status FROM private.assessment_response_analytics
   WHERE assessment_version_id = (SELECT assessment_version_id FROM analytics_test_results WHERE kind = 'unlinked')),
  'excluded_unlinked',
  'unlinked assessment is excluded from elapsed-time comparison'
);
SELECT is(
  (SELECT elapsed_response_seconds FROM private.assessment_response_analytics
   WHERE assessment_version_id = (SELECT assessment_version_id FROM analytics_test_results WHERE kind = 'unlinked')),
  NULL::bigint,
  'missing elapsed time is never guessed or fabricated'
);
RESET ROLE;

-- Grader A can read only the published result for an active assignment at AAL2.
SET LOCAL ROLE authenticated;
SELECT set_config('request.jwt.claims',
  '{"sub":"55555555-5555-4555-8555-555555555555","role":"authenticated","aal":"aal1"}', true);
SELECT throws_ok(
  $$SELECT * FROM public.get_assigned_assessment_response_analytics(
    (SELECT submission_id FROM analytics_test_context WHERE kind = 'regular')
  )$$,
  '42501', 'assessment_analytics_forbidden',
  'assigned Grader AAL1 cannot retrieve analytics'
);
SELECT set_config('request.jwt.claims',
  '{"sub":"55555555-5555-4555-8555-555555555555","role":"authenticated","aal":"aal2"}', true);
SELECT is(
  (SELECT attainment_status FROM public.get_assigned_assessment_response_analytics(
    (SELECT submission_id FROM analytics_test_context WHERE kind = 'regular')
  )),
  'valid',
  'assigned Grader AAL2 can read the latest published analytics through the guarded RPC'
);
SELECT throws_ok(
  $$SELECT * FROM public.get_assigned_assessment_response_analytics(
    (SELECT submission_id FROM analytics_test_context WHERE kind = 'unpublished')
  )$$,
  'P0002', 'published_assessment_analytics_not_found',
  'an unpublished grader draft never produces a readable analytics result'
);
RESET ROLE;

-- A Student cannot use the Grader analytics RPC or direct private table access.
SET LOCAL ROLE authenticated;
SELECT set_config('request.jwt.claims',
  '{"sub":"11111111-1111-4111-8111-111111111111","role":"authenticated","aal":"aal1"}', true);
SELECT throws_ok(
  $$SELECT * FROM public.get_assigned_assessment_response_analytics(
    (SELECT submission_id FROM analytics_test_context WHERE kind = 'regular')
  )$$,
  '42501', 'assessment_analytics_forbidden',
  'a learner cannot read internal analytics even after publication'
);
SELECT throws_ok(
  $$SELECT * FROM private.assessment_response_analytics$$,
  '42501', NULL,
  'a learner cannot query the private analytics relation'
);
RESET ROLE;

SELECT throws_ok(
  $$DELETE FROM private.assessment_response_analytics$$,
  '42501', 'assessment_response_analytics_immutable',
  'analytics history cannot be directly deleted or rewritten'
);

SELECT * FROM finish();
ROLLBACK;
