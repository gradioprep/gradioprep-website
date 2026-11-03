BEGIN;
SELECT no_plan();

-- No public access to grading assignments, drafts, assessments or marks.
SET LOCAL ROLE anon;
SELECT throws_ok($$SELECT * FROM public.submission_grader_assignments$$, '42501', NULL, 'anonymous cannot read submission grader assignments');
SELECT throws_ok($$SELECT * FROM public.assessment_versions$$, '42501', NULL, 'anonymous cannot read assessment versions');
SELECT throws_ok($$SELECT * FROM public.criterion_results$$, '42501', NULL, 'anonymous cannot read criterion results');
SELECT throws_ok($$SELECT * FROM private.assessment_drafts$$, '42501', NULL, 'anonymous cannot read private grading drafts');
RESET ROLE;

-- Create one accepted synthetic assessment and test owner AAL2 assignment.
SET LOCAL ROLE authenticated;
SELECT set_config('request.jwt.claim.sub', '11111111-1111-4111-8111-111111111111', true);
SELECT set_config('request.jwt.claims', '{"sub":"11111111-1111-4111-8111-111111111111","role":"authenticated","aal":"aal1"}', true);
SELECT lives_ok(
  $$SELECT * FROM public.accept_assessment_submission(
    'a1111111-1111-4111-8111-111111111111',
    'a0111111-1111-4111-8111-111111111111',
    'This synthetic response explains how a selected textual detail shapes a reader response and supports the interpretation with precise textual evidence.'
  )$$,
  'student A can accept an assessment submission for the grading workflow'
);
SELECT is((SELECT count(*)::integer FROM public.assessment_submissions), 1, 'student A sees one accepted assessment submission');
SELECT is((SELECT count(*)::integer FROM public.assessment_versions), 0, 'student A sees no unpublished assessment version');
SELECT is((SELECT count(*)::integer FROM public.criterion_results), 0, 'student A sees no unpublished criterion result');
RESET ROLE;

SET LOCAL ROLE authenticated;
SELECT set_config('request.jwt.claim.sub', '88888888-8888-4888-8888-888888888888', true);
SELECT set_config('request.jwt.claims', '{"sub":"88888888-8888-4888-8888-888888888888","role":"authenticated","aal":"aal1"}', true);
SELECT throws_ok(
  $$SELECT * FROM public.assign_submission_to_grader(
    (SELECT id FROM public.assessment_submissions LIMIT 1),
    '55555555-5555-4555-8555-555555555555',
    'Synthetic initial assignment'
  )$$,
  '42501', 'assessment_assignment_forbidden',
  'owner AAL1 cannot assign an assessment submission'
);
RESET ROLE;

SET LOCAL ROLE authenticated;
SELECT set_config('request.jwt.claim.sub', '88888888-8888-4888-8888-888888888888', true);
SELECT set_config('request.jwt.claims', '{"sub":"88888888-8888-4888-8888-888888888888","role":"authenticated","aal":"aal2"}', true);
SELECT lives_ok(
  $$SELECT * FROM public.assign_submission_to_grader(
    (SELECT id FROM public.assessment_submissions LIMIT 1),
    '55555555-5555-4555-8555-555555555555',
    'Synthetic initial assignment'
  )$$,
  'owner AAL2 can assign the accepted submission to an active grader'
);
SELECT is((SELECT status FROM public.assessment_submissions), 'assigned', 'assignment moves the submission into assigned state');
SELECT is((SELECT count(*)::integer FROM public.submission_grader_assignments), 1, 'one active grader assignment is recorded');
SELECT throws_ok(
  $$SELECT * FROM public.assign_submission_to_grader(
    (SELECT id FROM public.assessment_submissions LIMIT 1),
    '66666666-6666-4666-8666-666666666666',
    'Duplicate active assignment'
  )$$,
  'P0001', 'assessment_submission_not_assignable',
  'an already-assigned submission cannot receive a second active grader'
);
RESET ROLE;

-- Student A cannot see the assignment, rubric or draft, even though this
-- student owns the accepted submission.
SET LOCAL ROLE authenticated;
SELECT set_config('request.jwt.claim.sub', '11111111-1111-4111-8111-111111111111', true);
SELECT set_config('request.jwt.claims', '{"sub":"11111111-1111-4111-8111-111111111111","role":"authenticated","aal":"aal1"}', true);
SELECT is((SELECT count(*)::integer FROM public.submission_grader_assignments), 0, 'student cannot read grader assignment metadata');
SELECT is((SELECT count(*)::integer FROM public.rubric_versions), 0, 'student cannot inspect the internal rubric');
SELECT is((SELECT count(*)::integer FROM public.rubric_criteria), 0, 'student cannot inspect private marking criteria');
SELECT is((SELECT count(*)::integer FROM public.assessment_versions), 0, 'student cannot read or alter unpublished assessment versions');
RESET ROLE;

-- Grader A is denied at AAL1, despite having an active assignment.
SET LOCAL ROLE authenticated;
SELECT set_config('request.jwt.claim.sub', '55555555-5555-4555-8555-555555555555', true);
SELECT set_config('request.jwt.claims', '{"sub":"55555555-5555-4555-8555-555555555555","role":"authenticated","aal":"aal1"}', true);
SELECT is((SELECT count(*)::integer FROM public.assessment_submissions), 0, 'assigned grader at AAL1 cannot read accepted submissions');
SELECT is((SELECT count(*)::integer FROM public.rubric_versions), 0, 'assigned grader at AAL1 cannot read rubric versions');
SELECT throws_ok(
  $$SELECT * FROM public.get_assessment_draft((SELECT id FROM public.assessment_submissions LIMIT 1))$$,
  '42501', 'grader_assessment_forbidden',
  'assigned grader at AAL1 cannot retrieve a private draft'
);
SELECT throws_ok(
  $$SELECT * FROM public.save_assessment_draft(
    (SELECT id FROM public.assessment_submissions LIMIT 1),
    'A sufficiently detailed overall feedback statement.',
    NULL,
    '[{"criterion_id":"f3333333-3333-4333-8333-333333333333","points_awarded":3,"feedback":"Relevant evidence is selected and explained clearly."},{"criterion_id":"f4444444-4444-4444-8444-444444444444","points_awarded":3,"feedback":"The explanation connects the language choice to reader effect."}]'::jsonb
  )$$,
  '42501', 'grader_assessment_forbidden',
  'assigned grader at AAL1 cannot save an assessment draft'
);
RESET ROLE;

-- Grader B has AAL2 but no assignment, so no cross-grader access is granted.
SET LOCAL ROLE authenticated;
SELECT set_config('request.jwt.claim.sub', '66666666-6666-4666-8666-666666666666', true);
SELECT set_config('request.jwt.claims', '{"sub":"66666666-6666-4666-8666-666666666666","role":"authenticated","aal":"aal2"}', true);
SELECT is((SELECT count(*)::integer FROM public.assessment_submissions), 0, 'unassigned grader B cannot read grader A submission');
SELECT is((SELECT count(*)::integer FROM public.rubric_versions), 0, 'unassigned grader B cannot inspect grader A rubric');
SELECT is((SELECT count(*)::integer FROM public.submission_grader_assignments), 0, 'unassigned grader B cannot inspect grader A assignment');
SELECT throws_ok(
  $$SELECT * FROM public.get_assessment_draft((SELECT id FROM public.assessment_submissions LIMIT 1))$$,
  '42501', 'grader_assessment_forbidden',
  'unassigned grader B cannot retrieve grader A draft'
);
RESET ROLE;

-- Admin does not inherit owner or grader access even at AAL2.
SET LOCAL ROLE authenticated;
SELECT set_config('request.jwt.claim.sub', '77777777-7777-4777-8777-777777777777', true);
SELECT set_config('request.jwt.claims', '{"sub":"77777777-7777-4777-8777-777777777777","role":"authenticated","aal":"aal2"}', true);
SELECT is((SELECT count(*)::integer FROM public.assessment_submissions), 0, 'admin cannot inspect assessment submissions by role inheritance');
SELECT is((SELECT count(*)::integer FROM public.assessment_versions), 0, 'admin cannot inspect published assessment feedback');
SELECT is((SELECT count(*)::integer FROM public.submission_grader_assignments), 0, 'admin cannot inspect grader assignments');
RESET ROLE;

-- Grader A at AAL2 sees only the assigned submission and its exact rubric.
SET LOCAL ROLE authenticated;
SELECT set_config('request.jwt.claim.sub', '55555555-5555-4555-8555-555555555555', true);
SELECT set_config('request.jwt.claims', '{"sub":"55555555-5555-4555-8555-555555555555","role":"authenticated","aal":"aal2"}', true);
SELECT is((SELECT count(*)::integer FROM public.assessment_submissions), 1, 'assigned grader A at AAL2 can read only the assigned submission');
SELECT is((SELECT count(*)::integer FROM public.submission_grader_assignments), 1, 'assigned grader A at AAL2 can read their active assignment');
SELECT is((SELECT count(*)::integer FROM public.rubric_versions), 1, 'assigned grader A at AAL2 can read the mapped rubric version');
SELECT is((SELECT count(*)::integer FROM public.rubric_criteria), 2, 'assigned grader A at AAL2 can read the two criteria for the mapped rubric');
SELECT is((SELECT count(*)::integer FROM public.task_versions), 1, 'assigned grader A can read the exact task version');
SELECT is((SELECT count(*)::integer FROM public.task_version_prompts), 1, 'assigned grader A can read the exact task prompt');
SELECT is((SELECT count(*)::integer FROM public.assessment_versions), 0, 'no published assessment exists before the grader publishes');
SELECT throws_ok(
  $$SELECT * FROM private.assessment_drafts$$,
  '42501', NULL,
  'grader cannot query the private draft table directly'
);
SELECT lives_ok(
  $$SELECT * FROM public.save_assessment_draft(
    (SELECT id FROM public.assessment_submissions LIMIT 1),
    'The response selects a relevant detail and explains how the writer shapes a reader response.',
    NULL,
    '[{"criterion_id":"f3333333-3333-4333-8333-333333333333","points_awarded":3,"feedback":"A relevant detail is selected and integrated into the interpretation."},{"criterion_id":"f4444444-4444-4444-8444-444444444444","points_awarded":3,"feedback":"The explanation links the language choice to a clear reader effect."}]'::jsonb
  )$$,
  'assigned grader A at AAL2 can save a criterion-level private draft'
);
SELECT is((SELECT count(*)::integer FROM public.assessment_versions), 0, 'saving a draft does not publish feedback');
SELECT is((SELECT count(*)::integer FROM public.criterion_results), 0, 'saving a draft does not expose criterion marks');
SELECT is((SELECT draft_revision FROM public.get_assessment_draft((SELECT id FROM public.assessment_submissions LIMIT 1))), 1, 'assigned grader can resume their private first draft');

SELECT throws_ok(
  $$SELECT * FROM public.save_assessment_draft(
    (SELECT id FROM public.assessment_submissions LIMIT 1),
    'This draft contains a scalar instead of the required criterion result array.',
    NULL,
    '"not an array"'::jsonb
  )$$,
  '22023', 'invalid_assessment_draft',
  'scalar criterion payload is rejected without leaking a database array error'
);
SELECT throws_ok(
  $$SELECT * FROM public.save_assessment_draft(
    (SELECT id FROM public.assessment_submissions LIMIT 1),
    'This draft omits a required criterion.',
    NULL,
    '[{"criterion_id":"f3333333-3333-4333-8333-333333333333","points_awarded":3,"feedback":"The evidence is selected and explained clearly."}]'::jsonb
  )$$,
  '22023', 'invalid_assessment_criteria',
  'draft must include every criterion in the immutable rubric'
);
SELECT throws_ok(
  $$SELECT * FROM public.save_assessment_draft(
    (SELECT id FROM public.assessment_submissions LIMIT 1),
    'This draft repeats a criterion and omits the other criterion.',
    NULL,
    '[{"criterion_id":"f3333333-3333-4333-8333-333333333333","points_awarded":3,"feedback":"The evidence is selected and explained clearly."},{"criterion_id":"f3333333-3333-4333-8333-333333333333","points_awarded":2,"feedback":"The same criterion cannot be repeated."}]'::jsonb
  )$$,
  '22023', 'invalid_assessment_criteria',
  'draft cannot repeat one criterion to bypass the exact rubric'
);
SELECT throws_ok(
  $$SELECT * FROM public.save_assessment_draft(
    (SELECT id FROM public.assessment_submissions LIMIT 1),
    'This draft awards more points than the rubric permits.',
    NULL,
    '[{"criterion_id":"f3333333-3333-4333-8333-333333333333","points_awarded":5,"feedback":"The evidence is selected and explained clearly."},{"criterion_id":"f4444444-4444-4444-8444-444444444444","points_awarded":2,"feedback":"The language effect is described clearly."}]'::jsonb
  )$$,
  '22023', 'invalid_assessment_criteria',
  'draft cannot award more points than the criterion maximum'
);
RESET ROLE;

-- Learners and guardians cannot see drafts or unpublished criterion outcomes.
SET LOCAL ROLE authenticated;
SELECT set_config('request.jwt.claim.sub', '11111111-1111-4111-8111-111111111111', true);
SELECT set_config('request.jwt.claims', '{"sub":"11111111-1111-4111-8111-111111111111","role":"authenticated","aal":"aal1"}', true);
SELECT is((SELECT count(*)::integer FROM public.assessment_versions), 0, 'learner cannot see the grader draft');
SELECT is((SELECT count(*)::integer FROM public.criterion_results), 0, 'learner cannot see draft criterion outcomes');
RESET ROLE;

SET LOCAL ROLE authenticated;
SELECT set_config('request.jwt.claim.sub', '33333333-3333-4333-8333-333333333333', true);
SELECT set_config('request.jwt.claims', '{"sub":"33333333-3333-4333-8333-333333333333","role":"authenticated","aal":"aal1"}', true);
SELECT is((SELECT count(*)::integer FROM public.assessment_submissions), 0, 'guardian without submission consent cannot read accepted submissions');
SELECT is((SELECT count(*)::integer FROM public.assessment_versions), 0, 'guardian without consent cannot read assessment feedback');
RESET ROLE;

-- Explicitly enable the synthetic guardian's submission consent.
UPDATE public.guardian_learner_links
SET can_view_submissions = true
WHERE guardian_id = '33333333-3333-4333-8333-333333333333'
  AND learner_id = '11111111-1111-4111-8111-111111111111';

-- Human publication creates immutable version 1 and criterion outcomes.
SET LOCAL ROLE authenticated;
SELECT set_config('request.jwt.claim.sub', '55555555-5555-4555-8555-555555555555', true);
SELECT set_config('request.jwt.claims', '{"sub":"55555555-5555-4555-8555-555555555555","role":"authenticated","aal":"aal2"}', true);
SELECT lives_ok(
  $$SELECT * FROM public.publish_assessment_feedback((SELECT id FROM public.assessment_submissions LIMIT 1))$$,
  'assigned human grader explicitly publishes feedback version 1'
);
SELECT is((SELECT status FROM public.assessment_submissions), 'feedback_published', 'successful publication moves submission to feedback-published state');
SELECT is((SELECT count(*)::integer FROM public.assessment_versions), 1, 'grader can read published version 1');
SELECT is((SELECT count(*)::integer FROM public.criterion_results), 2, 'published version contains one result for every rubric criterion');
SELECT is((SELECT total_points FROM public.assessment_versions), 6::numeric, 'versioned total is calculated from criterion marks');
SELECT is((SELECT max_points FROM public.assessment_versions), 8::numeric, 'versioned maximum is calculated from rubric criteria');
SELECT ok((SELECT first_turnaround_seconds >= 0 FROM public.assessment_versions), 'first publication records actual elapsed turnaround');
SELECT ok((SELECT seconds_to_due_at_first_publish > 0 FROM public.assessment_versions), 'first publication preserves time remaining before the 24-hour deadline');
SELECT is((SELECT sla_met FROM public.assessment_versions), true, 'first publication within 24 hours records SLA met');
SELECT is((SELECT count(*)::integer FROM public.get_assessment_draft((SELECT id FROM public.assessment_submissions LIMIT 1))), 0, 'publishing consumes the private draft and the assigned grader can no longer resume it');
RESET ROLE;

-- Only the latest published version is learner-visible; guardians require
-- explicit consent, while the grader and owner retain the version history.
SET LOCAL ROLE authenticated;
SELECT set_config('request.jwt.claim.sub', '11111111-1111-4111-8111-111111111111', true);
SELECT set_config('request.jwt.claims', '{"sub":"11111111-1111-4111-8111-111111111111","role":"authenticated","aal":"aal1"}', true);
SELECT is((SELECT count(*)::integer FROM public.assessment_versions), 1, 'learner sees published version 1 only');
SELECT is((SELECT count(*)::integer FROM public.criterion_results), 2, 'learner sees the published criterion results only');
SELECT is((SELECT version_number FROM public.assessment_versions), 1, 'learner sees the current published version');
RESET ROLE;

SET LOCAL ROLE authenticated;
SELECT set_config('request.jwt.claim.sub', '33333333-3333-4333-8333-333333333333', true);
SELECT set_config('request.jwt.claims', '{"sub":"33333333-3333-4333-8333-333333333333","role":"authenticated","aal":"aal1"}', true);
SELECT is((SELECT count(*)::integer FROM public.assessment_versions), 1, 'consented guardian sees the current published feedback');
SELECT is((SELECT count(*)::integer FROM public.criterion_results), 2, 'consented guardian sees the published criterion results');
RESET ROLE;

-- Editing feedback after first publication requires a reason. A second version
-- is written, while the first publication SLA snapshot stays unchanged.
SET LOCAL ROLE authenticated;
SELECT set_config('request.jwt.claim.sub', '55555555-5555-4555-8555-555555555555', true);
SELECT set_config('request.jwt.claims', '{"sub":"55555555-5555-4555-8555-555555555555","role":"authenticated","aal":"aal2"}', true);
SELECT throws_ok(
  $$SELECT * FROM public.save_assessment_draft(
    (SELECT id FROM public.assessment_submissions LIMIT 1),
    'The revised feedback provides a stronger explanation of the evidence and effect.',
    NULL,
    '[{"criterion_id":"f3333333-3333-4333-8333-333333333333","points_awarded":4,"feedback":"The chosen detail is now integrated into a precise interpretation."},{"criterion_id":"f4444444-4444-4444-8444-444444444444","points_awarded":3,"feedback":"The language effect is explained with clearer reasoning."}]'::jsonb
  )$$,
  '22023', 'assessment_change_reason_required',
  'editing previously published feedback requires a change reason'
);
SELECT lives_ok(
  $$SELECT * FROM public.save_assessment_draft(
    (SELECT id FROM public.assessment_submissions LIMIT 1),
    'The revised feedback provides a stronger explanation of the evidence and effect.',
    'Corrected the criterion explanation after checking the response again.',
    '[{"criterion_id":"f3333333-3333-4333-8333-333333333333","points_awarded":4,"feedback":"The chosen detail is now integrated into a precise interpretation."},{"criterion_id":"f4444444-4444-4444-8444-444444444444","points_awarded":3,"feedback":"The language effect is explained with clearer reasoning."}]'::jsonb
  )$$,
  'assigned grader can save a reasoned feedback revision'
);
SELECT is((SELECT count(*)::integer FROM public.assessment_versions), 1, 'saving feedback revision does not publish version 2 automatically');
RESET ROLE;

SET LOCAL ROLE authenticated;
SELECT set_config('request.jwt.claim.sub', '11111111-1111-4111-8111-111111111111', true);
SELECT set_config('request.jwt.claims', '{"sub":"11111111-1111-4111-8111-111111111111","role":"authenticated","aal":"aal1"}', true);
SELECT is((SELECT count(*)::integer FROM public.assessment_versions), 1, 'learner continues to see the previous publication until a human republishes');
SELECT is((SELECT version_number FROM public.assessment_versions), 1, 'learner is not shown an unpublished revision');
RESET ROLE;

SET LOCAL ROLE authenticated;
SELECT set_config('request.jwt.claim.sub', '55555555-5555-4555-8555-555555555555', true);
SELECT set_config('request.jwt.claims', '{"sub":"55555555-5555-4555-8555-555555555555","role":"authenticated","aal":"aal2"}', true);
SELECT lives_ok(
  $$SELECT * FROM public.publish_assessment_feedback((SELECT id FROM public.assessment_submissions LIMIT 1))$$,
  'assigned human grader explicitly publishes feedback version 2'
);
SELECT is((SELECT count(*)::integer FROM public.assessment_versions), 2, 'grader retains both immutable published versions');
SELECT is(
  (SELECT count(DISTINCT first_published_at)::integer FROM public.assessment_versions),
  1,
  'feedback edit preserves the original first-publication timestamp'
);
SELECT is(
  (SELECT count(DISTINCT first_turnaround_seconds)::integer FROM public.assessment_versions),
  1,
  'feedback edit preserves the original 24-hour turnaround measurement'
);
SELECT is(
  (SELECT count(DISTINCT seconds_to_due_at_first_publish)::integer FROM public.assessment_versions),
  1,
  'feedback edit preserves the original time remaining or overdue measurement'
);
SELECT is((SELECT count(*)::integer FROM public.criterion_results), 4, 'both immutable versions retain their criterion outcomes');
RESET ROLE;

SET LOCAL ROLE authenticated;
SELECT set_config('request.jwt.claim.sub', '11111111-1111-4111-8111-111111111111', true);
SELECT set_config('request.jwt.claims', '{"sub":"11111111-1111-4111-8111-111111111111","role":"authenticated","aal":"aal1"}', true);
SELECT is((SELECT count(*)::integer FROM public.assessment_versions), 1, 'learner sees only the latest published feedback version after an edit');
SELECT is((SELECT version_number FROM public.assessment_versions), 2, 'learner sees feedback version 2 after explicit publication');
SELECT is((SELECT count(*)::integer FROM public.criterion_results), 2, 'learner sees only the latest version criterion results');
SELECT is((SELECT overall_feedback FROM public.assessment_versions), 'The revised feedback provides a stronger explanation of the evidence and effect.', 'learner sees the exact latest human-published feedback');
RESET ROLE;

-- The owner can inspect all versions only at AAL2; AAL1 sees no global records.
SET LOCAL ROLE authenticated;
SELECT set_config('request.jwt.claim.sub', '88888888-8888-4888-8888-888888888888', true);
SELECT set_config('request.jwt.claims', '{"sub":"88888888-8888-4888-8888-888888888888","role":"authenticated","aal":"aal1"}', true);
SELECT is((SELECT count(*)::integer FROM public.assessment_versions), 0, 'owner AAL1 cannot inspect assessment history');
RESET ROLE;

SET LOCAL ROLE authenticated;
SELECT set_config('request.jwt.claim.sub', '88888888-8888-4888-8888-888888888888', true);
SELECT set_config('request.jwt.claims', '{"sub":"88888888-8888-4888-8888-888888888888","role":"authenticated","aal":"aal2"}', true);
SELECT is((SELECT count(*)::integer FROM public.assessment_versions), 2, 'owner AAL2 can inspect the complete published version history');
SELECT is((SELECT count(*)::integer FROM public.criterion_results), 4, 'owner AAL2 can inspect all immutable criterion outcomes');
SELECT is((SELECT count(*)::integer FROM public.submission_grader_assignments), 1, 'owner AAL2 can inspect assignment history');
RESET ROLE;

-- Published assessment/criterion rows and published rubric criteria cannot
-- be altered, including by a privileged database operator.
SET LOCAL ROLE postgres;
SELECT throws_ok(
  $$UPDATE public.assessment_versions SET overall_feedback = 'overwritten published feedback' WHERE version_number = 1$$,
  '42501', 'assessment_version_immutable',
  'published assessment version cannot be overwritten'
);
SELECT throws_ok(
  $$DELETE FROM public.assessment_versions WHERE version_number = 1$$,
  '42501', 'assessment_version_immutable',
  'published assessment version cannot be deleted'
);
SELECT throws_ok(
  $$UPDATE public.criterion_results SET feedback = 'overwritten criterion feedback'$$,
  '42501', 'criterion_result_immutable',
  'published criterion outcome cannot be overwritten'
);
SELECT throws_ok(
  $$UPDATE public.rubric_criteria SET max_points = 99 WHERE id = 'f3333333-3333-4333-8333-333333333333'$$,
  '42501', 'published_rubric_immutable',
  'published rubric criterion cannot be changed after use'
);
RESET ROLE;

-- Audit only action metadata, never learner response text or the content of
-- private grading drafts.
SELECT ok(
  (SELECT count(*)::integer FROM private.security_audit_events
   WHERE target_type = 'assessment_submission'
     AND action IN ('assessment_submission_accepted','assessment_submission_assigned',
                    'assessment_draft_saved','assessment_feedback_published','assessment_feedback_edited')) >= 5,
  'assignment, draft saves, publication and edits create attributable audit events'
);

-- Revocation removes grader read/save/publish access; student keeps only the
-- latest already-published feedback.
-- Preserve the real submission identifier before revocation changes grader RLS visibility.
SELECT set_config(
  'test.assessment_submission_id',
  (SELECT id::text FROM public.assessment_submissions LIMIT 1),
  true
);
SELECT is(
  (SELECT count(*)::integer FROM public.assessment_submissions
   WHERE id = current_setting('test.assessment_submission_id')::uuid),
  1,
  'revocation checks retain the identifier of the existing synthetic submission'
);

UPDATE public.submission_grader_assignments
SET revoked_by = '88888888-8888-4888-8888-888888888888',
    revoked_at = now()
WHERE submission_id = current_setting('test.assessment_submission_id')::uuid
  AND revoked_at IS NULL;

SET LOCAL ROLE authenticated;
SELECT set_config('request.jwt.claim.sub', '55555555-5555-4555-8555-555555555555', true);
SELECT set_config('request.jwt.claims', '{"sub":"55555555-5555-4555-8555-555555555555","role":"authenticated","aal":"aal2"}', true);
SELECT is((SELECT count(*)::integer FROM public.assessment_submissions), 0, 'revoked grader immediately loses submission read access');
SELECT is((SELECT count(*)::integer FROM public.submission_grader_assignments), 0, 'revoked grader loses assignment metadata access');
SELECT is((SELECT count(*)::integer FROM public.rubric_versions), 0, 'revoked grader loses rubric and criterion access');
SELECT throws_ok(
  $$SELECT * FROM public.get_assessment_draft(current_setting('test.assessment_submission_id')::uuid)$$,
  '42501', 'grader_assessment_forbidden',
  'revoked grader cannot retrieve a draft'
);
SELECT throws_ok(
  $$SELECT * FROM public.publish_assessment_feedback(current_setting('test.assessment_submission_id')::uuid)$$,
  '42501', 'grader_assessment_forbidden',
  'revoked grader cannot publish feedback'
);
RESET ROLE;

SELECT * FROM finish();
ROLLBACK;
