BEGIN;
CREATE EXTENSION IF NOT EXISTS pgtap WITH SCHEMA extensions;
SELECT no_plan();

-- Student A: self-scope and active enrolment permit only the matching task.
SET LOCAL ROLE authenticated;
SELECT set_config('request.jwt.claim.sub', '11111111-1111-4111-8111-111111111111', true);
SELECT set_config('request.jwt.claims', '{"sub":"11111111-1111-4111-8111-111111111111","role":"authenticated","aal":"aal1"}', true);
SELECT is((SELECT count(*)::integer FROM public.profiles), 1, 'student reads only their own profile');
SELECT is((SELECT count(*)::integer FROM public.role_assignments), 1, 'student reads only their own role assignments');
SELECT is((SELECT count(*)::integer FROM public.course_enrolments), 1, 'student reads only their own enrolment');
SELECT is((SELECT count(*)::integer FROM public.task_versions), 1, 'student sees only published task versions for an active enrolment');
SELECT is((SELECT count(*)::integer FROM public.task_version_prompts), 1, 'student sees only prompts for an enrolled published task');
SELECT is((SELECT count(*)::integer FROM public.attempts), 2, 'student reads only their own attempts');
SELECT is((SELECT count(*)::integer FROM public.attempt_responses), 1, 'student reads only responses belonging to their attempts');
SELECT is((SELECT count(*)::integer FROM public.grader_assignments), 0, 'student cannot read grader assignment records');
SELECT is((SELECT count(*)::integer FROM public.attempts WHERE learner_id = '22222222-2222-4222-8222-222222222222'), 0, 'student cannot read another learner attempt');
SELECT is((SELECT count(*)::integer FROM public.task_versions WHERE id = 'a2222222-2222-4222-8222-222222222222'), 0, 'student cannot read a task outside their enrolment');
RESET ROLE;

-- Student B sees only their own pathway/task and attempt.
SET LOCAL ROLE authenticated;
SELECT set_config('request.jwt.claim.sub', '22222222-2222-4222-8222-222222222222', true);
SELECT set_config('request.jwt.claims', '{"sub":"22222222-2222-4222-8222-222222222222","role":"authenticated","aal":"aal1"}', true);
SELECT is((SELECT count(*)::integer FROM public.task_versions), 1, 'second student sees only their own enrolled task');
SELECT is((SELECT count(*)::integer FROM public.task_version_prompts), 1, 'second student sees only their own task prompt');
SELECT is((SELECT count(*)::integer FROM public.attempts), 1, 'second student sees only their own attempt');
SELECT is((SELECT count(*)::integer FROM public.attempt_responses), 1, 'second student sees only their own response');
SELECT is((SELECT count(*)::integer FROM public.grader_assignments), 0, 'second student cannot inspect grader assignments');
RESET ROLE;

-- Guardian A has profile/progress consent but not submission consent yet.
SET LOCAL ROLE authenticated;
SELECT set_config('request.jwt.claim.sub', '33333333-3333-4333-8333-333333333333', true);
SELECT set_config('request.jwt.claims', '{"sub":"33333333-3333-4333-8333-333333333333","role":"authenticated","aal":"aal1"}', true);
SELECT is((SELECT count(*)::integer FROM public.profiles), 2, 'guardian reads own and explicitly linked learner profiles');
SELECT is((SELECT count(*)::integer FROM public.course_enrolments), 1, 'guardian reads only the linked learner enrolment with progress consent');
SELECT is((SELECT count(*)::integer FROM public.task_versions), 0, 'guardian without submission consent cannot read task versions');
SELECT is((SELECT count(*)::integer FROM public.task_version_prompts), 0, 'guardian without submission consent cannot read task prompts');
SELECT is((SELECT count(*)::integer FROM public.attempts), 0, 'guardian without submission consent cannot read learner attempts');
RESET ROLE;

-- Grant the synthetic guardian explicit submission-view consent for learner A.
UPDATE public.guardian_learner_links
SET can_view_submissions = true
WHERE guardian_id = '33333333-3333-4333-8333-333333333333'
  AND learner_id = '11111111-1111-4111-8111-111111111111';

SET LOCAL ROLE authenticated;
SELECT set_config('request.jwt.claim.sub', '33333333-3333-4333-8333-333333333333', true);
SELECT set_config('request.jwt.claims', '{"sub":"33333333-3333-4333-8333-333333333333","role":"authenticated","aal":"aal1"}', true);
SELECT is((SELECT count(*)::integer FROM public.task_versions), 1, 'guardian with active verified submission consent sees only the linked learner task');
SELECT is((SELECT count(*)::integer FROM public.task_version_prompts), 1, 'guardian with submission consent sees that task prompt');
SELECT is((SELECT count(*)::integer FROM public.attempts), 2, 'guardian with submission consent sees the linked learner attempts only');
SELECT is((SELECT count(*)::integer FROM public.attempt_responses), 1, 'guardian with submission consent sees only linked learner responses');
SELECT is((SELECT count(*)::integer FROM public.task_versions WHERE id = 'a2222222-2222-4222-8222-222222222222'), 0, 'guardian cannot see another learner pathway task');
RESET ROLE;

-- Guardian B has a revoked link and must not see the associated learner work.
SET LOCAL ROLE authenticated;
SELECT set_config('request.jwt.claim.sub', '44444444-4444-4444-8444-444444444444', true);
SELECT set_config('request.jwt.claims', '{"sub":"44444444-4444-4444-8444-444444444444","role":"authenticated","aal":"aal2"}', true);
SELECT is((SELECT count(*)::integer FROM public.task_versions), 0, 'guardian with revoked link cannot read task versions even at AAL2');
SELECT is((SELECT count(*)::integer FROM public.task_version_prompts), 0, 'guardian with revoked link cannot read task prompts');
SELECT is((SELECT count(*)::integer FROM public.attempts), 0, 'guardian with revoked link cannot read attempts');
RESET ROLE;

-- Grader A at AAL1 receives no task, prompt, assignment or submission data.
SET LOCAL ROLE authenticated;
SELECT set_config('request.jwt.claim.sub', '55555555-5555-4555-8555-555555555555', true);
SELECT set_config('request.jwt.claims', '{"sub":"55555555-5555-4555-8555-555555555555","role":"authenticated","aal":"aal1"}', true);
SELECT is((SELECT count(*)::integer FROM public.task_versions), 0, 'grader at AAL1 cannot read task versions');
SELECT is((SELECT count(*)::integer FROM public.task_version_prompts), 0, 'grader at AAL1 cannot read task prompts');
SELECT is((SELECT count(*)::integer FROM public.attempts), 0, 'grader at AAL1 cannot read assigned attempts');
SELECT is((SELECT count(*)::integer FROM public.grader_assignments), 0, 'grader at AAL1 cannot read assignment metadata');
SELECT set_config('request.jwt.claims', '{"sub":"55555555-5555-4555-8555-555555555555","role":"authenticated","aal":"aal2"}', true);
SELECT is((SELECT count(*)::integer FROM public.task_versions), 1, 'grader at AAL2 sees only the task version for an active assignment');
SELECT is((SELECT count(*)::integer FROM public.task_version_prompts), 1, 'grader at AAL2 sees the prompt for an active assignment');
SELECT is((SELECT count(*)::integer FROM public.attempts), 1, 'grader at AAL2 sees only their assigned submitted attempt');
SELECT is((SELECT count(*)::integer FROM public.attempt_responses), 1, 'grader at AAL2 sees only the assigned learner response');
SELECT is((SELECT count(*)::integer FROM public.grader_assignments), 1, 'grader at AAL2 sees only their active assignment');
RESET ROLE;

-- Grader B cannot cross into grader A's task, attempt or response.
SET LOCAL ROLE authenticated;
SELECT set_config('request.jwt.claim.sub', '66666666-6666-4666-8666-666666666666', true);
SELECT set_config('request.jwt.claims', '{"sub":"66666666-6666-4666-8666-666666666666","role":"authenticated","aal":"aal2"}', true);
SELECT is((SELECT count(*)::integer FROM public.task_versions), 1, 'grader B sees only their assigned task');
SELECT is((SELECT count(*)::integer FROM public.attempts), 1, 'grader B sees only their assigned attempt');
SELECT is((SELECT count(*)::integer FROM public.attempts WHERE id = 'c1111111-1111-4111-8111-111111111111'), 0, 'grader B cannot inspect grader A attempt');
SELECT is((SELECT count(*)::integer FROM public.attempt_responses), 1, 'grader B sees only their assigned response');
SELECT is((SELECT count(*)::integer FROM public.grader_assignments), 1, 'grader B sees only their own assignment');
RESET ROLE;

-- Revoking an assignment removes both task metadata and attempt visibility.
UPDATE public.grader_assignments
SET revoked_by = '88888888-8888-4888-8888-888888888888',
    revoked_at = now()
WHERE id = 'd1111111-1111-4111-8111-111111111111'
  AND revoked_at IS NULL;
SET LOCAL ROLE authenticated;
SELECT set_config('request.jwt.claim.sub', '55555555-5555-4555-8555-555555555555', true);
SELECT set_config('request.jwt.claims', '{"sub":"55555555-5555-4555-8555-555555555555","role":"authenticated","aal":"aal2"}', true);
SELECT is((SELECT count(*)::integer FROM public.task_versions), 0, 'grader whose assignment is revoked loses task metadata access');
SELECT is((SELECT count(*)::integer FROM public.task_version_prompts), 0, 'grader whose assignment is revoked loses prompt access');
SELECT is((SELECT count(*)::integer FROM public.attempts), 0, 'grader whose assignment is revoked loses attempt access');
SELECT is((SELECT count(*)::integer FROM public.grader_assignments), 0, 'grader whose assignment is revoked loses assignment access');
RESET ROLE;

-- Admin permissions are not promoted to grader/owner by the admin role or AAL2.
SET LOCAL ROLE authenticated;
SELECT set_config('request.jwt.claim.sub', '77777777-7777-4777-8777-777777777777', true);
SELECT set_config('request.jwt.claims', '{"sub":"77777777-7777-4777-8777-777777777777","role":"authenticated","aal":"aal2"}', true);
SELECT is((SELECT count(*)::integer FROM public.profiles), 1, 'admin reads only their own profile');
SELECT is((SELECT count(*)::integer FROM public.role_assignments), 1, 'admin reads only their own role assignment');
SELECT is((SELECT count(*)::integer FROM public.task_versions), 0, 'admin cannot read learner task versions by role inheritance');
SELECT is((SELECT count(*)::integer FROM public.task_version_prompts), 0, 'admin cannot read learner task prompts by role inheritance');
SELECT is((SELECT count(*)::integer FROM public.attempts), 0, 'admin cannot read learner attempts by role inheritance');
SELECT is((SELECT count(*)::integer FROM public.grader_assignments), 0, 'admin cannot read grader assignments by role inheritance');
RESET ROLE;

-- Owner-wide access to identity and learning records is privileged at the
-- database boundary, independent of the Worker AAL2 checks.
SET LOCAL ROLE authenticated;
SELECT set_config('request.jwt.claim.sub', '88888888-8888-4888-8888-888888888888', true);
SELECT set_config('request.jwt.claims', '{"sub":"88888888-8888-4888-8888-888888888888","role":"authenticated","aal":"aal1"}', true);
SELECT is((SELECT count(*)::integer FROM public.profiles), 1, 'owner at AAL1 reads only own profile');
SELECT is((SELECT count(*)::integer FROM public.role_assignments), 1, 'owner at AAL1 reads only own role assignment');
SELECT is((SELECT count(*)::integer FROM public.guardian_learner_links), 0, 'owner at AAL1 cannot inspect guardian links');
SELECT is((SELECT count(*)::integer FROM public.course_enrolments), 0, 'owner at AAL1 cannot inspect learner enrolments');
SELECT is((SELECT count(*)::integer FROM public.task_versions), 0, 'owner at AAL1 cannot inspect task versions');
SELECT is((SELECT count(*)::integer FROM public.task_version_prompts), 0, 'owner at AAL1 cannot inspect task prompts');
SELECT is((SELECT count(*)::integer FROM public.attempts), 0, 'owner at AAL1 cannot inspect learner attempts');
SELECT is((SELECT count(*)::integer FROM public.attempt_responses), 0, 'owner at AAL1 cannot inspect learner responses');
SELECT is((SELECT count(*)::integer FROM public.grader_assignments), 0, 'owner at AAL1 cannot inspect grader assignments');
SELECT set_config('request.jwt.claims', '{"sub":"88888888-8888-4888-8888-888888888888","role":"authenticated","aal":"aal2"}', true);
SELECT is((SELECT count(*)::integer FROM public.profiles), 11, 'owner at AAL2 can inspect all eleven synthetic profiles');
SELECT is((SELECT count(*)::integer FROM public.role_assignments), 11, 'owner at AAL2 can inspect all eleven role assignments');
SELECT is((SELECT count(*)::integer FROM public.guardian_learner_links), 2, 'owner at AAL2 can inspect all guardian links');
SELECT is((SELECT count(*)::integer FROM public.course_enrolments), 2, 'owner at AAL2 can inspect all enrolments');
SELECT is((SELECT count(*)::integer FROM public.task_versions), 2, 'owner at AAL2 can inspect all task versions');
SELECT is((SELECT count(*)::integer FROM public.task_version_prompts), 2, 'owner at AAL2 can inspect all task prompts');
SELECT is((SELECT count(*)::integer FROM public.attempts), 3, 'owner at AAL2 can inspect all seeded attempts');
SELECT is((SELECT count(*)::integer FROM public.attempt_responses), 2, 'owner at AAL2 can inspect all response records');
SELECT is((SELECT count(*)::integer FROM public.grader_assignments), 2, 'owner at AAL2 can inspect all grader assignments');
RESET ROLE;

-- A suspended account remains denied even with a forged high-assurance claim.
SET LOCAL ROLE authenticated;
SELECT set_config('request.jwt.claim.sub', '99999999-9999-4999-8999-999999999999', true);
SELECT set_config('request.jwt.claims', '{"sub":"99999999-9999-4999-8999-999999999999","role":"authenticated","aal":"aal2"}', true);
SELECT is((SELECT count(*)::integer FROM public.profiles), 0, 'suspended account cannot read its profile at AAL2');
SELECT is((SELECT count(*)::integer FROM public.task_versions), 0, 'suspended account cannot read task versions');
SELECT is((SELECT count(*)::integer FROM public.attempts), 0, 'suspended account cannot read attempts');
RESET ROLE;

SELECT * FROM finish();
ROLLBACK;
