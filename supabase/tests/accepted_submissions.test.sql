BEGIN;
SELECT no_plan();

SET LOCAL ROLE anon;
SELECT throws_ok($$SELECT * FROM public.assessment_submissions$$, '42501', NULL, 'anonymous cannot read accepted submissions');
SELECT throws_ok($$SELECT * FROM public.submission_versions$$, '42501', NULL, 'anonymous cannot read submission versions');
SELECT throws_ok($$SELECT * FROM public.rubric_versions$$, '42501', NULL, 'anonymous cannot read rubric versions');
RESET ROLE;

-- Student A accepts a typed human-assessment response. Identity, exact rubric,
-- queue state, acceptance time, due time and capacity snapshot are server-owned.
SET LOCAL ROLE authenticated;
SELECT set_config('request.jwt.claim.sub', '11111111-1111-4111-8111-111111111111', true);
SELECT set_config('request.jwt.claims', '{"sub":"11111111-1111-4111-8111-111111111111","role":"authenticated","aal":"aal1"}', true);
SELECT is((SELECT count(*)::integer FROM public.assessment_submissions), 0, 'student A begins with no accepted assessment submissions');
SELECT lives_ok(
  $$SELECT * FROM public.accept_assessment_submission(
    'a1111111-1111-4111-8111-111111111111',
    '10111111-1111-4111-8111-111111111111',
    'This synthetic assessment response explains how a selected textual detail shapes a reader response and supports the interpretation with precise evidence.'
  )$$,
  'enrolled student A can accept a typed human-assessment submission through the protected transaction'
);
SELECT is((SELECT count(*)::integer FROM public.assessment_submissions WHERE learner_id = auth.uid()), 1, 'acceptance creates exactly one owned submission');
SELECT is((SELECT status FROM public.assessment_submissions WHERE learner_id = auth.uid()), 'queued', 'new accepted work enters the queued state');
SELECT is(
  (SELECT extract(epoch FROM grading_due_at - accepted_at)::integer FROM public.assessment_submissions WHERE learner_id = auth.uid()),
  86400,
  'the server fixes the grading deadline at exactly 24 hours after acceptance'
);
SELECT is(
  (SELECT rubric_version_id FROM public.assessment_submissions WHERE learner_id = auth.uid()),
  'f1111111-1111-4111-8111-111111111111'::uuid,
  'the submission snapshots the exact published rubric version mapped to the task'
);
SELECT is(
  (SELECT capacity_limit_snapshot FROM public.assessment_submissions WHERE learner_id = auth.uid()),
  3,
  'the accepted record preserves the configured capacity limit snapshot'
);
SELECT is(
  (SELECT open_submissions_before_acceptance FROM public.assessment_submissions WHERE learner_id = auth.uid()),
  0,
  'the accepted record preserves the queue load before acceptance'
);
SELECT is(
  (SELECT count(*)::integer FROM public.submission_versions WHERE submission_id = (
    SELECT id FROM public.assessment_submissions
    WHERE learner_id = auth.uid() AND idempotency_key = '10111111-1111-4111-8111-111111111111'
  )),
  1,
  'acceptance creates an immutable original response version'
);
SELECT ok(
  (SELECT word_count > 0 FROM public.submission_versions WHERE submission_id = (
    SELECT id FROM public.assessment_submissions
    WHERE learner_id = auth.uid() AND idempotency_key = '10111111-1111-4111-8111-111111111111'
  ) AND version_number = 1),
  'the database calculates word count for the accepted response'
);

-- A retry with the same key and payload returns the existing row and does not
-- consume additional capacity. Reusing the key for altered content is denied.
SELECT is(
  (SELECT submission_id FROM public.accept_assessment_submission(
    'a1111111-1111-4111-8111-111111111111',
    '10111111-1111-4111-8111-111111111111',
    'This synthetic assessment response explains how a selected textual detail shapes a reader response and supports the interpretation with precise evidence.'
  )),
  (SELECT id FROM public.assessment_submissions
   WHERE learner_id = auth.uid()
     AND idempotency_key = '10111111-1111-4111-8111-111111111111'),
  'an idempotent retry returns the original accepted submission ID'
);
SELECT is(
  (SELECT is_replay FROM public.accept_assessment_submission(
    'a1111111-1111-4111-8111-111111111111',
    '10111111-1111-4111-8111-111111111111',
    'This synthetic assessment response explains how a selected textual detail shapes a reader response and supports the interpretation with precise evidence.'
  )),
  true,
  'the database identifies an idempotent replay'
);
SELECT throws_ok(
  $$SELECT * FROM public.accept_assessment_submission(
    'a1111111-1111-4111-8111-111111111111',
    '10111111-1111-4111-8111-111111111111',
    'Altered content must not replace the accepted original submission response.'
  )$$,
  'P0001', 'submission_idempotency_conflict',
  'the same idempotency key cannot be reused with altered response content'
);
SELECT throws_ok(
  $$SELECT * FROM public.accept_assessment_submission(
    'a2222222-2222-4222-8222-222222222222',
    '11111111-1111-4111-8111-111111111111',
    'Student A cannot submit a task outside their active enrolment.'
  )$$,
  'P0002', 'assessment_task_not_available',
  'a learner cannot accept a task outside their active enrolment'
);
SELECT throws_ok(
  $$INSERT INTO public.assessment_submissions (learner_id, task_version_id, rubric_version_id, status, accepted_at, grading_due_at, idempotency_key, capacity_config_version, capacity_limit_snapshot, open_submissions_before_acceptance)
    VALUES ('22222222-2222-4222-8222-222222222222', 'a1111111-1111-4111-8111-111111111111', 'f1111111-1111-4111-8111-111111111111', 'queued', now(), now() + interval '24 hours', gen_random_uuid(), 1, 3, 0)$$,
  '42501', NULL,
  'student cannot bypass the protected submission acceptance transaction'
);
SELECT throws_ok(
  $$UPDATE public.assessment_submissions SET accepted_at = now(), grading_due_at = now() + interval '24 hours' WHERE learner_id = auth.uid()$$,
  '42501', NULL,
  'student cannot forge acceptance or due timestamps'
);
SELECT throws_ok(
  $$DELETE FROM public.assessment_submissions WHERE learner_id = auth.uid()$$,
  '42501', NULL,
  'student cannot delete an accepted submission'
);
SELECT throws_ok(
  $$INSERT INTO public.submission_versions (submission_id, version_number, response_text, created_by)
    VALUES ((SELECT id FROM public.assessment_submissions WHERE learner_id = auth.uid() LIMIT 1), 99, 'forged version', auth.uid())$$,
  '42501', NULL,
  'student cannot inject a submission version directly'
);
SELECT throws_ok(
  $$UPDATE public.submission_versions SET response_text = 'overwritten original' WHERE created_by = auth.uid()$$,
  '42501', NULL,
  'student cannot overwrite the accepted original response'
);
SELECT is((SELECT count(*)::integer FROM public.rubric_versions), 0, 'student cannot inspect restricted rubric versions before grading access is assigned');
SELECT is((SELECT count(*)::integer FROM public.task_rubric_mappings), 0, 'student cannot inspect internal task-to-rubric mappings');
RESET ROLE;

-- Student B is independently enrolled in task B and receives a distinct rubric
-- snapshot. This creates the second open item in the synthetic capacity window.
SET LOCAL ROLE authenticated;
SELECT set_config('request.jwt.claim.sub', '22222222-2222-4222-8222-222222222222', true);
SELECT set_config('request.jwt.claims', '{"sub":"22222222-2222-4222-8222-222222222222","role":"authenticated","aal":"aal1"}', true);
SELECT lives_ok(
  $$SELECT * FROM public.accept_assessment_submission(
    'a2222222-2222-4222-8222-222222222222',
    '20222222-2222-4222-8222-222222222222',
    'This separate synthetic response belongs to student B and explains one word choice with a relevant interpretation.'
  )$$,
  'student B can accept their own enrolled task'
);
SELECT is((SELECT count(*)::integer FROM public.assessment_submissions), 1, 'student B sees only their own accepted submission');
SELECT is((SELECT count(*)::integer FROM public.submission_versions), 1, 'student B sees only their own accepted response version');
SELECT is((SELECT rubric_version_id FROM public.assessment_submissions), 'f2222222-2222-4222-8222-222222222222'::uuid, 'student B submission preserves its mapped rubric version');
SELECT is(
  (SELECT count(*)::integer FROM public.assessment_submissions WHERE learner_id = '11111111-1111-4111-8111-111111111111'),
  0,
  'student B cannot read student A submissions'
);
SELECT throws_ok(
  $$SELECT * FROM public.accept_assessment_submission(
    'a1111111-1111-4111-8111-111111111111',
    '21222222-2222-4222-8222-222222222222',
    'Student B cannot submit a task outside their enrolment.'
  )$$,
  'P0002', 'assessment_task_not_available',
  'student B cannot accept student A task'
);
RESET ROLE;

-- Student A's second distinct acceptance fills the local synthetic capacity.
SET LOCAL ROLE authenticated;
SELECT set_config('request.jwt.claim.sub', '11111111-1111-4111-8111-111111111111', true);
SELECT set_config('request.jwt.claims', '{"sub":"11111111-1111-4111-8111-111111111111","role":"authenticated","aal":"aal1"}', true);
SELECT lives_ok(
  $$SELECT * FROM public.accept_assessment_submission(
    'a1111111-1111-4111-8111-111111111111',
    '30333333-3333-4333-8333-333333333333',
    'A second synthetic assessment submission is a separate accepted item with its own immutable idempotency key and deadline.'
  )$$,
  'a second distinct item is accepted while the configured queue capacity has room'
);
SELECT is((SELECT count(*)::integer FROM public.assessment_submissions), 2, 'student A sees only their two submissions');
SELECT throws_ok(
  $$SELECT * FROM public.accept_assessment_submission(
    'a1111111-1111-4111-8111-111111111111',
    '40444444-4444-4444-8444-444444444444',
    'This fourth synthetic assessment item must be rejected because queue capacity is already full.'
  )$$,
  'P0001', 'submission_capacity_full',
  'acceptance is denied when the open workload reaches its configured capacity'
);
SELECT is(
  (SELECT count(*)::integer FROM public.assessment_submissions),
  2,
  'a denied over-capacity request creates no accepted submission'
);
RESET ROLE;

-- Guardians receive only linked submission access after explicit consent.
SET LOCAL ROLE authenticated;
SELECT set_config('request.jwt.claim.sub', '33333333-3333-4333-8333-333333333333', true);
SELECT set_config('request.jwt.claims', '{"sub":"33333333-3333-4333-8333-333333333333","role":"authenticated","aal":"aal1"}', true);
SELECT is((SELECT count(*)::integer FROM public.assessment_submissions), 0, 'guardian without submission consent cannot read submissions');
RESET ROLE;

UPDATE public.guardian_learner_links
SET can_view_submissions = true
WHERE guardian_id = '33333333-3333-4333-8333-333333333333'
  AND learner_id = '11111111-1111-4111-8111-111111111111';

SET LOCAL ROLE authenticated;
SELECT set_config('request.jwt.claim.sub', '33333333-3333-4333-8333-333333333333', true);
SELECT set_config('request.jwt.claims', '{"sub":"33333333-3333-4333-8333-333333333333","role":"authenticated","aal":"aal1"}', true);
SELECT is((SELECT count(*)::integer FROM public.assessment_submissions), 2, 'guardian with explicit verified consent sees only linked student A submissions');
SELECT is((SELECT count(*)::integer FROM public.submission_versions), 2, 'guardian with explicit consent sees only linked student A response versions');
SELECT is((SELECT count(*)::integer FROM public.assessment_submissions WHERE learner_id = '22222222-2222-4222-8222-222222222222'), 0, 'guardian cannot see student B submission');
RESET ROLE;

-- AAL2 alone does not give graders or admins implicit submission access.
SET LOCAL ROLE authenticated;
SELECT set_config('request.jwt.claim.sub', '55555555-5555-4555-8555-555555555555', true);
SELECT set_config('request.jwt.claims', '{"sub":"55555555-5555-4555-8555-555555555555","role":"authenticated","aal":"aal2"}', true);
SELECT is((SELECT count(*)::integer FROM public.assessment_submissions), 0, 'grader without an active submission assignment cannot read submissions');
RESET ROLE;

SET LOCAL ROLE authenticated;
SELECT set_config('request.jwt.claim.sub', '77777777-7777-4777-8777-777777777777', true);
SELECT set_config('request.jwt.claims', '{"sub":"77777777-7777-4777-8777-777777777777","role":"authenticated","aal":"aal2"}', true);
SELECT is((SELECT count(*)::integer FROM public.assessment_submissions), 0, 'admin does not inherit submission access from the admin role');
RESET ROLE;

-- Owner-wide access is independently protected by AAL2 in PostgreSQL.
SET LOCAL ROLE authenticated;
SELECT set_config('request.jwt.claim.sub', '88888888-8888-4888-8888-888888888888', true);
SELECT set_config('request.jwt.claims', '{"sub":"88888888-8888-4888-8888-888888888888","role":"authenticated","aal":"aal1"}', true);
SELECT is((SELECT count(*)::integer FROM public.assessment_submissions), 0, 'owner at AAL1 cannot inspect assessment submissions');
SELECT is((SELECT count(*)::integer FROM public.submission_versions), 0, 'owner at AAL1 cannot inspect submission response versions');
SELECT is((SELECT count(*)::integer FROM public.rubric_versions), 0, 'owner at AAL1 cannot inspect rubric versions');
SELECT set_config('request.jwt.claims', '{"sub":"88888888-8888-4888-8888-888888888888","role":"authenticated","aal":"aal2"}', true);
SELECT is((SELECT count(*)::integer FROM public.assessment_submissions), 3, 'owner at AAL2 can inspect all synthetic assessment submissions');
SELECT is((SELECT count(*)::integer FROM public.submission_versions), 3, 'owner at AAL2 can inspect all immutable submission versions');
SELECT is((SELECT count(*)::integer FROM public.rubric_versions), 2, 'owner at AAL2 can inspect published rubric versions');
SELECT is((SELECT count(*)::integer FROM public.rubric_criteria), 4, 'owner at AAL2 can inspect rubric criteria');
SELECT ok(
  (
    SELECT array_agg(submission.id ORDER BY submission.accepted_at ASC, submission.id ASC)
    FROM public.assessment_submissions AS submission
  ) = ARRAY[
    (SELECT id FROM public.assessment_submissions WHERE idempotency_key = '10111111-1111-4111-8111-111111111111'),
    (SELECT id FROM public.assessment_submissions WHERE idempotency_key = '20222222-2222-4222-8222-222222222222'),
    (SELECT id FROM public.assessment_submissions WHERE idempotency_key = '30333333-3333-4333-8333-333333333333')
  ],
  'owner assessment queue is ordered by accepted timestamp ascending with deterministic ID tie-break'
);
RESET ROLE;

-- Even privileged database workflows may update status in later phases, but
-- the identity/task/rubric/acceptance/deadline/capacity/idempotency snapshot is
-- immutable after the acceptance transaction. Test the trigger as table owner.
SET LOCAL ROLE postgres;
SELECT throws_ok(
  $q$UPDATE public.assessment_submissions
    SET grading_due_at = grading_due_at + interval '1 hour'
    WHERE idempotency_key = '10111111-1111-4111-8111-111111111111'$q$,
  '42501', 'assessment_submission_snapshot_immutable',
  'accepted 24-hour due time cannot be extended or rewritten by a privileged workflow'
);
SELECT throws_ok(
  $q$UPDATE public.assessment_submissions
    SET rubric_version_id = 'f2222222-2222-4222-8222-222222222222'
    WHERE idempotency_key = '10111111-1111-4111-8111-111111111111'$q$,
  '42501', 'assessment_submission_snapshot_immutable',
  'accepted task/rubric version relationship cannot be rewritten'
);
RESET ROLE;

-- Phase 1C-D: only the owner at AAL2 can withdraw accepted work.
SET LOCAL ROLE authenticated;
SELECT set_config('request.jwt.claim.sub', '88888888-8888-4888-8888-888888888888', true);
SELECT set_config('request.jwt.claims', '{"sub":"88888888-8888-4888-8888-888888888888","role":"authenticated","aal":"aal1"}', true);
SELECT throws_ok(
  $q$SELECT * FROM public.transition_assessment_submission(
    (SELECT id FROM public.assessment_submissions
     WHERE idempotency_key = '20222222-2222-4222-8222-222222222222'),
    'withdrawn', 'Owner AAL1 cannot withdraw accepted work'
  )$q$,
  '42501', 'assessment_transition_forbidden',
  'owner AAL1 cannot withdraw an accepted submission'
);
SELECT set_config('request.jwt.claims', '{"sub":"88888888-8888-4888-8888-888888888888","role":"authenticated","aal":"aal2"}', true);
SELECT lives_ok(
  $q$SELECT * FROM public.transition_assessment_submission(
    (SELECT id FROM public.assessment_submissions
     WHERE idempotency_key = '20222222-2222-4222-8222-222222222222'),
    'withdrawn', 'Synthetic learner request to withdraw this queued assessment'
  )$q$,
  'owner AAL2 can withdraw a queued accepted submission'
);
SELECT is(
  (SELECT status FROM public.assessment_submissions
   WHERE idempotency_key = '20222222-2222-4222-8222-222222222222'),
  'withdrawn',
  'withdrawal preserves the record and marks it terminal'
);
SELECT is(
  (SELECT count(*)::integer FROM public.assessment_submissions
   WHERE status IN ('queued', 'assigned', 'grading')),
  2,
  'withdrawal releases exactly one open capacity slot'
);
SELECT throws_ok(
  $q$SELECT * FROM public.transition_assessment_submission(
    (SELECT id FROM public.assessment_submissions
     WHERE idempotency_key = '20222222-2222-4222-8222-222222222222'),
    'closed', 'Withdrawn records cannot be closed'
  )$q$,
  'P0001', 'invalid_assessment_transition',
  'withdrawn submissions are terminal and cannot be closed'
);
RESET ROLE;

-- Suspension revokes acceptance and read access. Capacity is also fail-closed
-- when disabled; no silent bypass or alternate route may accept work.
SET LOCAL ROLE authenticated;
SELECT set_config('request.jwt.claim.sub', '99999999-9999-4999-8999-999999999999', true);
SELECT set_config('request.jwt.claims', '{"sub":"99999999-9999-4999-8999-999999999999","role":"authenticated","aal":"aal1"}', true);
SELECT throws_ok(
  $$SELECT * FROM public.accept_assessment_submission(
    'a1111111-1111-4111-8111-111111111111',
    '90999999-9999-4999-8999-999999999999',
    'A suspended account cannot accept assessment work.'
  )$$,
  '42501', 'assessment_submission_forbidden',
  'suspended student cannot accept a human-assessment submission'
);
RESET ROLE;

UPDATE private.grading_capacity_config
SET enabled = false
WHERE singleton = true;

SET LOCAL ROLE authenticated;
SELECT set_config('request.jwt.claim.sub', '11111111-1111-4111-8111-111111111111', true);
SELECT set_config('request.jwt.claims', '{"sub":"11111111-1111-4111-8111-111111111111","role":"authenticated","aal":"aal1"}', true);
SELECT throws_ok(
  $$SELECT * FROM public.accept_assessment_submission(
    'a1111111-1111-4111-8111-111111111111',
    '80888888-8888-4888-8888-888888888888',
    'Capacity is deliberately disabled; acceptance must fail closed.'
  )$$,
  'P0001', 'submission_capacity_unavailable',
  'acceptance fails closed when no grading capacity has been enabled'
);
RESET ROLE;

SELECT * FROM finish();
ROLLBACK;
