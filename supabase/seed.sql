-- Entirely fictional test fixtures. These credentials work only in the local Supabase stack.
-- Never apply this seed to a hosted or production project.
INSERT INTO auth.users (
  id, aud, role, email, encrypted_password, email_confirmed_at,
  raw_app_meta_data, raw_user_meta_data, created_at, updated_at,
  is_sso_user, is_anonymous
)
VALUES
  ('11111111-1111-4111-8111-111111111111', 'authenticated', 'authenticated', 'student.a@example.invalid', extensions.crypt('Local-only-GradiPrep-2026!', extensions.gen_salt('bf')), now(), '{"provider":"email","providers":["email"]}'::jsonb, '{"display_name":"Synthetic Student A","role":"owner"}'::jsonb, now(), now(), false, false),
  ('22222222-2222-4222-8222-222222222222', 'authenticated', 'authenticated', 'student.b@example.invalid', extensions.crypt('Local-only-GradiPrep-2026!', extensions.gen_salt('bf')), now(), '{"provider":"email","providers":["email"]}'::jsonb, '{"display_name":"Synthetic Student B"}'::jsonb, now(), now(), false, false),
  ('33333333-3333-4333-8333-333333333333', 'authenticated', 'authenticated', 'guardian.a@example.invalid', extensions.crypt('Local-only-GradiPrep-2026!', extensions.gen_salt('bf')), now(), '{"provider":"email","providers":["email"]}'::jsonb, '{"display_name":"Synthetic Guardian A","role":"owner"}'::jsonb, now(), now(), false, false),
  ('44444444-4444-4444-8444-444444444444', 'authenticated', 'authenticated', 'guardian.b@example.invalid', extensions.crypt('Local-only-GradiPrep-2026!', extensions.gen_salt('bf')), now(), '{"provider":"email","providers":["email"]}'::jsonb, '{"display_name":"Synthetic Guardian B"}'::jsonb, now(), now(), false, false),
  ('55555555-5555-4555-8555-555555555555', 'authenticated', 'authenticated', 'grader.a@example.invalid', extensions.crypt('Local-only-GradiPrep-2026!', extensions.gen_salt('bf')), now(), '{"provider":"email","providers":["email"]}'::jsonb, '{"display_name":"Synthetic Grader A"}'::jsonb, now(), now(), false, false),
  ('66666666-6666-4666-8666-666666666666', 'authenticated', 'authenticated', 'grader.b@example.invalid', extensions.crypt('Local-only-GradiPrep-2026!', extensions.gen_salt('bf')), now(), '{"provider":"email","providers":["email"]}'::jsonb, '{"display_name":"Synthetic Grader B"}'::jsonb, now(), now(), false, false),
  ('77777777-7777-4777-8777-777777777777', 'authenticated', 'authenticated', 'admin@example.invalid', extensions.crypt('Local-only-GradiPrep-2026!', extensions.gen_salt('bf')), now(), '{"provider":"email","providers":["email"]}'::jsonb, '{"display_name":"Synthetic Admin"}'::jsonb, now(), now(), false, false),
  ('88888888-8888-4888-8888-888888888888', 'authenticated', 'authenticated', 'owner@example.invalid', extensions.crypt('Local-only-GradiPrep-2026!', extensions.gen_salt('bf')), now(), '{"provider":"email","providers":["email"]}'::jsonb, '{"display_name":"Synthetic Owner"}'::jsonb, now(), now(), false, false),
  ('99999999-9999-4999-8999-999999999999', 'authenticated', 'authenticated', 'suspended.student@example.invalid', extensions.crypt('Local-only-GradiPrep-2026!', extensions.gen_salt('bf')), now(), '{"provider":"email","providers":["email"]}'::jsonb, '{"display_name":"Synthetic Suspended Student"}'::jsonb, now(), now(), false, false)
ON CONFLICT (id) DO NOTHING;

-- Supabase runs auth-schema migrations before this seed file. The built-in
-- email-identity backfill has therefore already run before these synthetic
-- auth.users rows are inserted. Create the matching GoTrue identities here so
-- the seeded email/password accounts can authenticate in local tests.
INSERT INTO auth.identities (
  id, provider_id, user_id, identity_data, provider, created_at, updated_at
)
SELECT
  gen_random_uuid(),
  users.id::text,
  users.id,
  jsonb_build_object(
    'sub', users.id::text,
    'email', users.email,
    'email_verified', true
  ),
  'email',
  now(),
  now()
FROM auth.users AS users
WHERE users.email IN (
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
AND users.encrypted_password <> ''
ON CONFLICT (provider_id, provider) DO NOTHING;

-- Seed is run as the local database owner. Remove default student role from synthetic staff.
DELETE FROM public.role_assignments
WHERE user_id IN (
  '33333333-3333-4333-8333-333333333333',
  '44444444-4444-4444-8444-444444444444',
  '55555555-5555-4555-8555-555555555555',
  '66666666-6666-4666-8666-666666666666',
  '77777777-7777-4777-8777-777777777777',
  '88888888-8888-4888-8888-888888888888'
)
AND role = 'student';

INSERT INTO public.role_assignments (user_id, role, granted_by, reason)
VALUES
  ('33333333-3333-4333-8333-333333333333', 'guardian', '88888888-8888-4888-8888-888888888888', 'synthetic_local_fixture'),
  ('44444444-4444-4444-8444-444444444444', 'guardian', '88888888-8888-4888-8888-888888888888', 'synthetic_local_fixture'),
  ('55555555-5555-4555-8555-555555555555', 'grader', '88888888-8888-4888-8888-888888888888', 'synthetic_local_fixture'),
  ('66666666-6666-4666-8666-666666666666', 'grader', '88888888-8888-4888-8888-888888888888', 'synthetic_local_fixture'),
  ('77777777-7777-4777-8777-777777777777', 'admin', '88888888-8888-4888-8888-888888888888', 'synthetic_local_fixture'),
  ('88888888-8888-4888-8888-888888888888', 'owner', NULL, 'synthetic_local_fixture')
ON CONFLICT DO NOTHING;

UPDATE public.guardian_learner_links
SET status = 'revoked', updated_at = now()
WHERE guardian_id = '44444444-4444-4444-8444-444444444444'
  AND learner_id = '22222222-2222-4222-8222-222222222222';

INSERT INTO public.guardian_learner_links (
  guardian_id, learner_id, status, consent_verified_at, verified_by,
  can_view_profile, can_view_learning_progress, can_view_submissions
)
VALUES
  ('33333333-3333-4333-8333-333333333333', '11111111-1111-4111-8111-111111111111', 'verified', now(), '88888888-8888-4888-8888-888888888888', true, true, false),
  ('44444444-4444-4444-8444-444444444444', '22222222-2222-4222-8222-222222222222', 'revoked', NULL, NULL, false, false, false)
ON CONFLICT (guardian_id, learner_id) DO UPDATE
SET status = EXCLUDED.status,
    consent_verified_at = EXCLUDED.consent_verified_at,
    verified_by = EXCLUDED.verified_by,
    can_view_profile = EXCLUDED.can_view_profile,
    can_view_learning_progress = EXCLUDED.can_view_learning_progress,
    can_view_submissions = EXCLUDED.can_view_submissions;

INSERT INTO public.course_enrolments (learner_id, pathway_id, status)
VALUES
  ('11111111-1111-4111-8111-111111111111', 'synthetic-ib-myp-year-4', 'active'),
  ('22222222-2222-4222-8222-222222222222', 'synthetic-cambridge-grade-6', 'active')
ON CONFLICT (learner_id, pathway_id) DO NOTHING;

-- An otherwise valid Auth identity with a suspended application profile.
UPDATE public.profiles
SET account_status = 'suspended'
WHERE user_id = '99999999-9999-4999-8999-999999999999';
