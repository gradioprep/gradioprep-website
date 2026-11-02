BEGIN;
CREATE EXTENSION IF NOT EXISTS pgtap WITH SCHEMA extensions;
SELECT no_plan();

-- Anonymous callers cannot read protected profile data.
SET LOCAL ROLE anon;
SELECT throws_ok(
  $SELECT * FROM public.profiles$,
  '42501',
  NULL,
  'anonymous users cannot read profiles'
);
RESET ROLE;

-- Student A can read and update only the student's own display name.
SET LOCAL ROLE authenticated;
SELECT set_config('request.jwt.claim.sub', '11111111-1111-4111-8111-111111111111', true);
SELECT set_config(
  'request.jwt.claims',
  '{"sub":"11111111-1111-4111-8111-111111111111","role":"authenticated"}',
  true
);
SELECT is(
  (SELECT count(*)::integer FROM public.profiles),
  1,
  'student sees only their own profile'
);
SELECT is(
  (SELECT count(*)::integer FROM public.profiles WHERE user_id = '22222222-2222-4222-8222-222222222222'),
  0,
  'student cannot read another student profile'
);
SELECT is(
  (SELECT count(*)::integer FROM public.role_assignments WHERE user_id = auth.uid() AND role = 'student'),
  1,
  'signup grants the default student role'
);
SELECT is(
  (SELECT count(*)::integer FROM public.role_assignments WHERE user_id = auth.uid() AND role = 'owner'),
  0,
  'untrusted signup metadata cannot assign an owner role'
);
UPDATE public.profiles
SET display_name = 'Synthetic Student A Updated'
WHERE user_id = auth.uid();
SELECT is(
  (SELECT display_name FROM public.profiles WHERE user_id = auth.uid()),
  'Synthetic Student A Updated',
  'student can update their own display name'
);
SELECT throws_ok(
  $$UPDATE public.profiles SET account_status = 'suspended' WHERE user_id = auth.uid()$$,
  '42501',
  NULL,
  'student cannot change account status'
);
SELECT throws_ok(
  $$INSERT INTO public.role_assignments (user_id, role) VALUES (auth.uid(), 'owner')$$,
  '42501',
  NULL,
  'student cannot grant themselves an owner role'
);
RESET ROLE;

-- Guardian A has a verified profile-view relationship to Student A only.
SET LOCAL ROLE authenticated;
SELECT set_config('request.jwt.claim.sub', '33333333-3333-4333-8333-333333333333', true);
SELECT set_config(
  'request.jwt.claims',
  '{"sub":"33333333-3333-4333-8333-333333333333","role":"authenticated"}',
  true
);
SELECT is(
  (SELECT count(*)::integer FROM public.profiles),
  2,
  'verified guardian can see own profile and the linked learner profile'
);
SELECT is(
  (SELECT count(*)::integer FROM public.profiles WHERE user_id = '22222222-2222-4222-8222-222222222222'),
  0,
  'verified guardian cannot see an unrelated learner profile'
);
SELECT is(
  (SELECT count(*)::integer FROM public.course_enrolments),
  1,
  'verified guardian sees only the linked learner enrolment when progress scope is granted'
);
RESET ROLE;

-- Guardian B's revoked relationship grants no access to the learner.
SET LOCAL ROLE authenticated;
SELECT set_config('request.jwt.claim.sub', '44444444-4444-4444-8444-444444444444', true);
SELECT set_config(
  'request.jwt.claims',
  '{"sub":"44444444-4444-4444-8444-444444444444","role":"authenticated"}',
  true
);
SELECT is(
  (SELECT count(*)::integer FROM public.profiles),
  1,
  'revoked guardian can see only the guardian profile'
);
SELECT is(
  (SELECT count(*)::integer FROM public.course_enrolments),
  0,
  'revoked guardian cannot see learner enrolments'
);
RESET ROLE;

-- Graders and admins do not inherit owner privileges.
SET LOCAL ROLE authenticated;
SELECT set_config('request.jwt.claim.sub', '55555555-5555-4555-8555-555555555555', true);
SELECT set_config(
  'request.jwt.claims',
  '{"sub":"55555555-5555-4555-8555-555555555555","role":"authenticated"}',
  true
);
SELECT is(
  (SELECT count(*)::integer FROM public.profiles),
  1,
  'grader sees only the grader own profile before assignment-scoped grading tables exist'
);
RESET ROLE;

SET LOCAL ROLE authenticated;
SELECT set_config('request.jwt.claim.sub', '77777777-7777-4777-8777-777777777777', true);
SELECT set_config(
  'request.jwt.claims',
  '{"sub":"77777777-7777-4777-8777-777777777777","role":"authenticated"}',
  true
);
SELECT is(
  (SELECT count(*)::integer FROM public.profiles),
  1,
  'admin does not inherit owner access'
);
SELECT throws_ok(
  $$INSERT INTO public.role_assignments (user_id, role) VALUES (auth.uid(), 'owner')$$,
  '42501',
  NULL,
  'admin cannot promote themselves to owner'
);
RESET ROLE;

-- Owner can inspect all protected identity rows through the authenticated RLS path.
SET LOCAL ROLE authenticated;
SELECT set_config('request.jwt.claim.sub', '88888888-8888-4888-8888-888888888888', true);
SELECT set_config(
  'request.jwt.claims',
  '{"sub":"88888888-8888-4888-8888-888888888888","role":"authenticated"}',
  true
);
SELECT is(
  (SELECT count(*)::integer FROM public.profiles),
  8,
  'owner can read all synthetic profiles'
);
SELECT is(
  (SELECT count(*)::integer FROM public.role_assignments WHERE role = 'owner'),
  1,
  'only the explicitly seeded owner has the owner role'
);
RESET ROLE;

SELECT * FROM finish();
ROLLBACK;
