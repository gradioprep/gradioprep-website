BEGIN;
CREATE EXTENSION IF NOT EXISTS pgtap WITH SCHEMA extensions;
SELECT no_plan();

SELECT is(
  (
    SELECT count(*)::integer
    FROM auth.users
    WHERE instance_id = '00000000-0000-0000-0000-000000000000'::uuid
      AND email IN (
        'student.a@example.invalid',
        'student.b@example.invalid',
        'guardian.a@example.invalid',
        'guardian.b@example.invalid',
        'grader.a@example.invalid',
        'grader.b@example.invalid',
        'admin@example.invalid',
        'owner@example.invalid',
        'suspended.student@example.invalid'
      )
  ),
  9,
  'all seeded synthetic users belong to GoTrue local instance zero UUID'
);
SELECT is(
  (
    SELECT count(*)::integer
    FROM auth.identities AS identity
    JOIN auth.users AS auth_user ON auth_user.id = identity.user_id
    WHERE identity.provider = 'email'
      AND identity.provider_id = auth_user.id::text
      AND auth_user.email IN (
        'student.a@example.invalid',
        'student.b@example.invalid',
        'guardian.a@example.invalid',
        'guardian.b@example.invalid',
        'grader.a@example.invalid',
        'grader.b@example.invalid',
        'admin@example.invalid',
        'owner@example.invalid',
        'suspended.student@example.invalid'
      )
  ),
  9,
  'all seeded synthetic email/password users have matching GoTrue email identities'
);
SELECT is(
  (
    SELECT count(*)::integer
    FROM auth.identities
    WHERE provider = 'email'
      AND user_id = '99999999-9999-4999-8999-999999999999'::uuid
      AND provider_id = '99999999-9999-4999-8999-999999999999'
  ),
  1,
  'suspended synthetic user has a valid email identity for password authentication'
);

SET LOCAL ROLE anon;
SELECT throws_ok(
  $$SELECT * FROM public.profiles$$,
  '42501',
  NULL,
  'anonymous users cannot read profiles'
);
SELECT throws_ok($$SELECT * FROM public.role_assignments$$, '42501', NULL, 'anonymous users cannot read role assignments');
SELECT throws_ok($$SELECT * FROM public.guardian_learner_links$$, '42501', NULL, 'anonymous users cannot read guardian links');
SELECT throws_ok($$SELECT * FROM public.course_enrolments$$, '42501', NULL, 'anonymous users cannot read course enrolments');
RESET ROLE;

SET LOCAL ROLE authenticated;
SELECT set_config('request.jwt.claim.sub', '11111111-1111-4111-8111-111111111111', true);
SELECT set_config(
  'request.jwt.claims',
  '{"sub":"11111111-1111-4111-8111-111111111111","role":"authenticated"}',
  true
);
SELECT is((SELECT count(*)::integer FROM public.profiles), 1, 'student sees only their own profile');
SELECT is((SELECT count(*)::integer FROM public.profiles WHERE user_id = '22222222-2222-4222-8222-222222222222'), 0, 'student cannot read another student profile');
SELECT is((SELECT count(*)::integer FROM public.role_assignments WHERE user_id = auth.uid() AND role = 'student'), 1, 'signup grants the default student role');
SELECT is((SELECT count(*)::integer FROM public.role_assignments WHERE user_id = auth.uid() AND role = 'owner'), 0, 'untrusted signup metadata cannot assign an owner role');
UPDATE public.profiles SET display_name = 'Synthetic Student A Updated' WHERE user_id = auth.uid();
SELECT is((SELECT display_name FROM public.profiles WHERE user_id = auth.uid()), 'Synthetic Student A Updated', 'student can update their own display name');
SELECT throws_ok(
  $$UPDATE public.profiles SET account_status = 'suspended' WHERE user_id = auth.uid()$$,
  '42501', NULL, 'student cannot change account status'
);
SELECT throws_ok(
  $$INSERT INTO public.role_assignments (user_id, role) VALUES (auth.uid(), 'owner')$$,
  '42501', NULL, 'student cannot grant themselves an owner role'
);
RESET ROLE;

SET LOCAL ROLE authenticated;
SELECT set_config('request.jwt.claim.sub', '33333333-3333-4333-8333-333333333333', true);
SELECT set_config('request.jwt.claims', '{"sub":"33333333-3333-4333-8333-333333333333","role":"authenticated"}', true);
SELECT is((SELECT count(*)::integer FROM public.profiles), 2, 'verified guardian can see own profile and the linked learner profile');
SELECT is((SELECT count(*)::integer FROM public.profiles WHERE user_id = '22222222-2222-4222-8222-222222222222'), 0, 'verified guardian cannot see an unrelated learner profile');
SELECT is((SELECT count(*)::integer FROM public.course_enrolments), 1, 'verified guardian sees only the linked learner enrolment when progress scope is granted');
RESET ROLE;

SET LOCAL ROLE authenticated;
SELECT set_config('request.jwt.claim.sub', '44444444-4444-4444-8444-444444444444', true);
SELECT set_config('request.jwt.claims', '{"sub":"44444444-4444-4444-8444-444444444444","role":"authenticated"}', true);
SELECT is((SELECT count(*)::integer FROM public.profiles), 1, 'revoked guardian can see only the guardian profile');
SELECT is((SELECT count(*)::integer FROM public.course_enrolments), 0, 'revoked guardian cannot see learner enrolments');
RESET ROLE;


SET LOCAL ROLE authenticated;
SELECT set_config('request.jwt.claim.sub', '99999999-9999-4999-8999-999999999999', true);
SELECT set_config('request.jwt.claims', '{"sub":"99999999-9999-4999-8999-999999999999","role":"authenticated"}', true);
SELECT is((SELECT count(*)::integer FROM public.profiles), 0, 'suspended user cannot read their own profile');
SELECT is((SELECT count(*)::integer FROM public.role_assignments), 0, 'suspended user cannot read role assignments');
SELECT is((SELECT count(*)::integer FROM public.guardian_learner_links), 0, 'suspended user cannot read guardian links');
SELECT is((SELECT count(*)::integer FROM public.course_enrolments), 0, 'suspended user cannot read course enrolments');
UPDATE public.profiles
SET display_name = 'Should Not Be Saved'
WHERE user_id = auth.uid();
RESET ROLE;

SET LOCAL ROLE authenticated;
SELECT set_config('request.jwt.claim.sub', '55555555-5555-4555-8555-555555555555', true);
SELECT set_config('request.jwt.claims', '{"sub":"55555555-5555-4555-8555-555555555555","role":"authenticated"}', true);
SELECT is((SELECT count(*)::integer FROM public.profiles), 1, 'grader sees only the grader own profile before assignment-scoped grading tables exist');
RESET ROLE;

SET LOCAL ROLE authenticated;
SELECT set_config('request.jwt.claim.sub', '77777777-7777-4777-8777-777777777777', true);
SELECT set_config('request.jwt.claims', '{"sub":"77777777-7777-4777-8777-777777777777","role":"authenticated"}', true);
SELECT is((SELECT count(*)::integer FROM public.profiles), 1, 'admin does not inherit owner access');
SELECT throws_ok(
  $$INSERT INTO public.role_assignments (user_id, role) VALUES (auth.uid(), 'owner')$$,
  '42501', NULL, 'admin cannot promote themselves to owner'
);
RESET ROLE;

SET LOCAL ROLE authenticated;
SELECT set_config('request.jwt.claim.sub', '88888888-8888-4888-8888-888888888888', true);
SELECT set_config('request.jwt.claims', '{"sub":"88888888-8888-4888-8888-888888888888","role":"authenticated"}', true);
SELECT is((SELECT count(*)::integer FROM public.profiles), 9, 'active owner can read all synthetic profiles including suspended accounts');
SELECT is((SELECT count(*)::integer FROM public.profiles WHERE user_id = '99999999-9999-4999-8999-999999999999'), 1, 'active owner can inspect a suspended account');
SELECT is((SELECT display_name FROM public.profiles WHERE user_id = '99999999-9999-4999-8999-999999999999'), 'Synthetic Suspended Student', 'suspended profile display name remains unchanged after blocked update');
SELECT is((SELECT count(*)::integer FROM public.role_assignments WHERE role = 'owner'), 1, 'only the explicitly seeded owner has the owner role');
RESET ROLE;

SELECT * FROM finish();
ROLLBACK;
