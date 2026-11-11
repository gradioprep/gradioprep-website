-- Entirely fictional test fixtures. These credentials work only in the local Supabase stack.
-- GoTrue password lookups scope users to instance_id = the zero UUID; keep
-- that Auth-owned fixture field explicit rather than relying on its NULL default.
-- GoTrue scans its token/change string columns and change-status integer as
-- non-null values. Empty strings/zero represent the unused state for fixtures.
-- Never apply this seed to a hosted or production project.
INSERT INTO auth.users (
  instance_id, id, aud, role, email, encrypted_password, email_confirmed_at,
  confirmation_token, recovery_token, email_change_token_current,
  email_change_token_new, email_change, phone_change_token, phone_change,
  reauthentication_token, email_change_confirm_status,
  raw_app_meta_data, raw_user_meta_data, created_at, updated_at,
  is_sso_user, is_anonymous
)
VALUES
  ('00000000-0000-0000-0000-000000000000', '11111111-1111-4111-8111-111111111111', 'authenticated', 'authenticated', 'student.a@example.invalid', extensions.crypt(('Local-only-' || 'GradiPrep-2026!'), extensions.gen_salt('bf')), now(), '', '', '', '', '', '', '', '', 0, '{"provider":"email","providers":["email"]}'::jsonb, '{"display_name":"Synthetic Student A","role":"owner"}'::jsonb, now(), now(), false, false),
  ('00000000-0000-0000-0000-000000000000', '22222222-2222-4222-8222-222222222222', 'authenticated', 'authenticated', 'student.b@example.invalid', extensions.crypt(('Local-only-' || 'GradiPrep-2026!'), extensions.gen_salt('bf')), now(), '', '', '', '', '', '', '', '', 0, '{"provider":"email","providers":["email"]}'::jsonb, '{"display_name":"Synthetic Student B"}'::jsonb, now(), now(), false, false),
  ('00000000-0000-0000-0000-000000000000', 'cccccccc-cccc-4ccc-8ccc-cccccccccccc', 'authenticated', 'authenticated', 'student.c@example.invalid', extensions.crypt(('Local-only-' || 'GradiPrep-2026!'), extensions.gen_salt('bf')), now(), '', '', '', '', '', '', '', '', 0, '{"provider":"email","providers":["email"]}'::jsonb, '{"display_name":"Synthetic Student C"}'::jsonb, now(), now(), false, false),
  ('00000000-0000-0000-0000-000000000000', '33333333-3333-4333-8333-333333333333', 'authenticated', 'authenticated', 'guardian.a@example.invalid', extensions.crypt(('Local-only-' || 'GradiPrep-2026!'), extensions.gen_salt('bf')), now(), '', '', '', '', '', '', '', '', 0, '{"provider":"email","providers":["email"]}'::jsonb, '{"display_name":"Synthetic Guardian A","role":"owner"}'::jsonb, now(), now(), false, false),
  ('00000000-0000-0000-0000-000000000000', '44444444-4444-4444-8444-444444444444', 'authenticated', 'authenticated', 'guardian.b@example.invalid', extensions.crypt(('Local-only-' || 'GradiPrep-2026!'), extensions.gen_salt('bf')), now(), '', '', '', '', '', '', '', '', 0, '{"provider":"email","providers":["email"]}'::jsonb, '{"display_name":"Synthetic Guardian B"}'::jsonb, now(), now(), false, false),
  ('00000000-0000-0000-0000-000000000000', 'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa', 'authenticated', 'authenticated', 'guardian.c@example.invalid', extensions.crypt(('Local-only-' || 'GradiPrep-2026!'), extensions.gen_salt('bf')), now(), '', '', '', '', '', '', '', '', 0, '{"provider":"email","providers":["email"]}'::jsonb, '{"display_name":"Synthetic Guardian C"}'::jsonb, now(), now(), false, false),
  ('00000000-0000-0000-0000-000000000000', '55555555-5555-4555-8555-555555555555', 'authenticated', 'authenticated', 'grader.a@example.invalid', extensions.crypt(('Local-only-' || 'GradiPrep-2026!'), extensions.gen_salt('bf')), now(), '', '', '', '', '', '', '', '', 0, '{"provider":"email","providers":["email"]}'::jsonb, '{"display_name":"Synthetic Grader A"}'::jsonb, now(), now(), false, false),
  ('00000000-0000-0000-0000-000000000000', '66666666-6666-4666-8666-666666666666', 'authenticated', 'authenticated', 'grader.b@example.invalid', extensions.crypt(('Local-only-' || 'GradiPrep-2026!'), extensions.gen_salt('bf')), now(), '', '', '', '', '', '', '', '', 0, '{"provider":"email","providers":["email"]}'::jsonb, '{"display_name":"Synthetic Grader B"}'::jsonb, now(), now(), false, false),
  ('00000000-0000-0000-0000-000000000000', 'bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbbb', 'authenticated', 'authenticated', 'grader.c@example.invalid', extensions.crypt(('Local-only-' || 'GradiPrep-2026!'), extensions.gen_salt('bf')), now(), '', '', '', '', '', '', '', '', 0, '{"provider":"email","providers":["email"]}'::jsonb, '{"display_name":"Synthetic Grader C"}'::jsonb, now(), now(), false, false),
  ('00000000-0000-0000-0000-000000000000', 'dddddddd-dddd-4ddd-8ddd-dddddddddddd', 'authenticated', 'authenticated', 'guardian.d@example.invalid', extensions.crypt(('Local-only-' || 'GradiPrep-2026!'), extensions.gen_salt('bf')), now(), '', '', '', '', '', '', '', '', 0, '{"provider":"email","providers":["email"]}'::jsonb, '{"display_name":"Synthetic Guardian D"}'::jsonb, now(), now(), false, false),
  ('00000000-0000-0000-0000-000000000000', '77777777-7777-4777-8777-777777777777', 'authenticated', 'authenticated', 'admin@example.invalid', extensions.crypt(('Local-only-' || 'GradiPrep-2026!'), extensions.gen_salt('bf')), now(), '', '', '', '', '', '', '', '', 0, '{"provider":"email","providers":["email"]}'::jsonb, '{"display_name":"Synthetic Admin"}'::jsonb, now(), now(), false, false),
  ('00000000-0000-0000-0000-000000000000', '88888888-8888-4888-8888-888888888888', 'authenticated', 'authenticated', 'owner@example.invalid', extensions.crypt(('Local-only-' || 'GradiPrep-2026!'), extensions.gen_salt('bf')), now(), '', '', '', '', '', '', '', '', 0, '{"provider":"email","providers":["email"]}'::jsonb, '{"display_name":"Synthetic Owner"}'::jsonb, now(), now(), false, false),
  ('00000000-0000-0000-0000-000000000000', '99999999-9999-4999-8999-999999999999', 'authenticated', 'authenticated', 'suspended.student@example.invalid', extensions.crypt(('Local-only-' || 'GradiPrep-2026!'), extensions.gen_salt('bf')), now(), '', '', '', '', '', '', '', '', 0, '{"provider":"email","providers":["email"]}'::jsonb, '{"display_name":"Synthetic Suspended Student"}'::jsonb, now(), now(), false, false)
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
  'student.c@example.invalid',
  'guardian.a@example.invalid',
  'guardian.b@example.invalid',
  'guardian.c@example.invalid',
  'grader.a@example.invalid',
  'grader.b@example.invalid',
  'grader.c@example.invalid',
  'guardian.d@example.invalid',
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
  'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa',
  '55555555-5555-4555-8555-555555555555',
  '66666666-6666-4666-8666-666666666666',
  'bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbbb',
  'dddddddd-dddd-4ddd-8ddd-dddddddddddd',
  '77777777-7777-4777-8777-777777777777',
  '88888888-8888-4888-8888-888888888888'
)
AND role = 'student';

INSERT INTO public.role_assignments (user_id, role, granted_by, reason)
VALUES
  ('33333333-3333-4333-8333-333333333333', 'guardian', '88888888-8888-4888-8888-888888888888', 'synthetic_local_fixture'),
  ('44444444-4444-4444-8444-444444444444', 'guardian', '88888888-8888-4888-8888-888888888888', 'synthetic_local_fixture'),
  ('aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa', 'guardian', '88888888-8888-4888-8888-888888888888', 'synthetic_local_fixture'),
  ('55555555-5555-4555-8555-555555555555', 'grader', '88888888-8888-4888-8888-888888888888', 'synthetic_local_fixture'),
  ('66666666-6666-4666-8666-666666666666', 'grader', '88888888-8888-4888-8888-888888888888', 'synthetic_local_fixture'),
  ('bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbbb', 'grader', '88888888-8888-4888-8888-888888888888', 'synthetic_local_fixture'),
  ('dddddddd-dddd-4ddd-8ddd-dddddddddddd', 'guardian', '88888888-8888-4888-8888-888888888888', 'synthetic_local_fixture'),
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

-- Phase 1C synthetic typed-task and attempt fixtures. These are not learner records
-- or released curriculum content. All IDs and response text are fictional test data.
INSERT INTO public.task_versions (
  id, task_code, pathway_id, title, version, response_mode,
  expected_min_words, ideal_words, release_state
)
VALUES
  ('a1111111-1111-4111-8111-111111111111', 'synthetic-phase1c-ib', 'synthetic-ib-myp-year-4',
   'Synthetic Phase 1C response task A', 1, 'typed', 15, 80, 'published'),
  ('a2222222-2222-4222-8222-222222222222', 'synthetic-phase1c-cambridge', 'synthetic-cambridge-grade-6',
   'Synthetic Phase 1C response task B', 1, 'typed', 15, 80, 'published'),
  ('a3333333-3333-4333-8333-333333333333', 'synthetic-phase2-typed-only', 'synthetic-ib-myp-year-4',
   'Synthetic Phase 2 typed-only task', 1, 'typed', 15, 80, 'published')
ON CONFLICT (id) DO NOTHING;

-- The Phase 1C IB task opts into typed-plus-optional-PDF. The Cambridge and
-- Phase 2 IB tasks remain typed-only.
UPDATE public.task_versions
SET pdf_response_enabled = true
WHERE id = 'a1111111-1111-4111-8111-111111111111'
  AND ideal_words > 20;

UPDATE public.task_versions
SET pdf_response_enabled = false
WHERE id IN (
  'a2222222-2222-4222-8222-222222222222',
  'a3333333-3333-4333-8333-333333333333'
);

-- One synthetic practice task exercises the advisory countdown in CI.
-- NULL remains the default for every other task version (untimed).
UPDATE public.task_versions
SET time_allowance_seconds = 600,
    timer_policy_version = 1
WHERE id = 'a3333333-3333-4333-8333-333333333333';

INSERT INTO public.task_version_prompts (id, task_version_id, sequence, prompt_text)
VALUES
  ('b1111111-1111-4111-8111-111111111111', 'a1111111-1111-4111-8111-111111111111', 1,
   'Synthetic test prompt: explain how one selected detail shapes a reader''s understanding.'),
  ('b2222222-2222-4222-8222-222222222222', 'a2222222-2222-4222-8222-222222222222', 1,
   'Synthetic test prompt: explain the effect of one word choice in a short passage.'),
  ('b3333333-3333-4333-8333-333333333333', 'a3333333-3333-4333-8333-333333333333', 1,
   'Synthetic test prompt: explain how one selected textual detail supports an interpretation.')
ON CONFLICT (id) DO NOTHING;

-- Phase 1C-B synthetic rubric snapshots and local-only grading capacity.
-- The migration leaves capacity disabled in a fresh/hosted database. This
-- explicit fixture enables only the local synthetic CI workflow.
INSERT INTO public.rubrics (id, rubric_code, title)
VALUES
  ('e1111111-1111-4111-8111-111111111111', 'synthetic-analysis-a', 'Synthetic Analytical Response Rubric A'),
  ('e2222222-2222-4222-8222-222222222222', 'synthetic-analysis-b', 'Synthetic Analytical Response Rubric B')
ON CONFLICT (id) DO NOTHING;

INSERT INTO public.rubric_versions (id, rubric_id, version, title, release_state)
VALUES
  ('f1111111-1111-4111-8111-111111111111', 'e1111111-1111-4111-8111-111111111111', 1, 'Synthetic Rubric A — Version 1', 'draft'),
  ('f2222222-2222-4222-8222-222222222222', 'e2222222-2222-4222-8222-222222222222', 1, 'Synthetic Rubric B — Version 1', 'draft')
ON CONFLICT (id) DO NOTHING;

INSERT INTO public.rubric_criteria (
  id, rubric_version_id, criterion_code, sequence, title, descriptor, max_points
)
VALUES
  ('f3333333-3333-4333-8333-333333333333', 'f1111111-1111-4111-8111-111111111111',
   'evidence', 1, 'Use of evidence', 'Selects relevant details and integrates them accurately.', 4),
  ('f4444444-4444-4444-8444-444444444444', 'f1111111-1111-4111-8111-111111111111',
   'analysis', 2, 'Analysis of effect', 'Explains how language or structure shapes meaning.', 4),
  ('f5555555-5555-4555-8555-555555555555', 'f2222222-2222-4222-8222-222222222222',
   'interpretation', 1, 'Interpretation', 'Explains a supported interpretation of the selected detail.', 4),
  ('f6666666-6666-4666-8666-666666666666', 'f2222222-2222-4222-8222-222222222222',
   'clarity', 2, 'Clarity', 'Communicates the explanation clearly and coherently.', 4)
ON CONFLICT (id) DO NOTHING;

-- Publish only after the immutable criterion rows exist for each version.
UPDATE public.rubric_versions
SET release_state = 'published'
WHERE id IN (
  'f1111111-1111-4111-8111-111111111111',
  'f2222222-2222-4222-8222-222222222222'
);

INSERT INTO public.task_rubric_mappings (id, task_version_id, rubric_version_id)
VALUES
  ('f7777777-7777-4777-8777-777777777777', 'a1111111-1111-4111-8111-111111111111', 'f1111111-1111-4111-8111-111111111111'),
  ('f8888888-8888-4888-8888-888888888888', 'a2222222-2222-4222-8222-222222222222', 'f2222222-2222-4222-8222-222222222222'),
  ('f9999999-9999-4999-8999-999999999999', 'a3333333-3333-4333-8333-333333333333', 'f1111111-1111-4111-8111-111111111111')
ON CONFLICT (task_version_id) DO NOTHING;

UPDATE private.grading_capacity_config
SET enabled = true,
    max_open_submissions = 3,
    config_version = 1,
    updated_at = now()
WHERE singleton = true;

INSERT INTO public.attempts (
  id, learner_id, task_version_id, status, started_at, submitted_at, created_at, updated_at
)
VALUES
  ('c1111111-1111-4111-8111-111111111111', '11111111-1111-4111-8111-111111111111',
   'a1111111-1111-4111-8111-111111111111', 'submitted', now() - interval '3 hours',
   now() - interval '2 hours 55 minutes', now() - interval '3 hours', now() - interval '2 hours 55 minutes'),
  ('c2222222-2222-4222-8222-222222222222', '22222222-2222-4222-8222-222222222222',
   'a2222222-2222-4222-8222-222222222222', 'submitted', now() - interval '2 hours',
   now() - interval '1 hour 55 minutes', now() - interval '2 hours', now() - interval '1 hour 55 minutes'),
  ('c3333333-3333-4333-8333-333333333333', '11111111-1111-4111-8111-111111111111',
   'a1111111-1111-4111-8111-111111111111', 'submitted', now() - interval '1 hour',
   now() - interval '55 minutes', now() - interval '1 hour', now() - interval '55 minutes')
ON CONFLICT (id) DO NOTHING;

INSERT INTO public.attempt_responses (attempt_id, task_version_id, prompt_id, response_text)
VALUES
  ('c1111111-1111-4111-8111-111111111111', 'a1111111-1111-4111-8111-111111111111',
   'b1111111-1111-4111-8111-111111111111',
   'This synthetic response uses a detail to explain how a reader understands the passage.'),
  ('c2222222-2222-4222-8222-222222222222', 'a2222222-2222-4222-8222-222222222222',
   'b2222222-2222-4222-8222-222222222222',
   'This separate synthetic response belongs only to synthetic student B.')
ON CONFLICT (attempt_id, prompt_id) DO NOTHING;

INSERT INTO public.grader_assignments (
  id, attempt_id, grader_user_id, assigned_by, assigned_at, reason
)
VALUES
  ('d1111111-1111-4111-8111-111111111111', 'c1111111-1111-4111-8111-111111111111',
   '55555555-5555-4555-8555-555555555555', '88888888-8888-4888-8888-888888888888',
   now() - interval '2 hours 50 minutes', 'Synthetic seeded grader assignment A'),
  ('d2222222-2222-4222-8222-222222222222', 'c2222222-2222-4222-8222-222222222222',
   '66666666-6666-4666-8666-666666666666', '88888888-8888-4888-8888-888888888888',
   now() - interval '1 hour 50 minutes', 'Synthetic seeded grader assignment B')
ON CONFLICT (id) DO NOTHING;

-- An otherwise valid Auth identity with a suspended application profile.
UPDATE public.profiles
SET account_status = 'suspended'
WHERE user_id = '99999999-9999-4999-8999-999999999999';


-- Synthetic-only Cycle 1 Diagnostic fixture; no live learners or hosted services.
INSERT INTO public.diagnostic_versions (
  id, diagnostic_code, pathway_id, title, version, release_state, total_minutes, sitting_count
)
VALUES (
  'ed111111-1111-4111-8111-111111111111',
  'ib-myp-g9-cycle1',
  'synthetic-ib-myp-year-4',
  'IB MYP Year 4 Preliminary Assessment — Read & View and Language in Context (synthetic partial slice)',
  1, 'published', 80, 2
)
ON CONFLICT (id) DO NOTHING;

INSERT INTO public.diagnostic_observations (
  id, diagnostic_version_id, observation_code, group_code,
  sitting_number, sequence_number, response_kind, learner_capture_enabled
)
VALUES
  ('ee000001-0000-4000-8000-000000000001','ed111111-1111-4111-8111-111111111111','RV01','RV',1,1,'structured_selection',true),
  ('ee000002-0000-4000-8000-000000000002','ed111111-1111-4111-8111-111111111111','RV02','RV',1,2,'text',true),
  ('ee000003-0000-4000-8000-000000000003','ed111111-1111-4111-8111-111111111111','RV03','RV',1,3,'text',true),
  ('ee000004-0000-4000-8000-000000000004','ed111111-1111-4111-8111-111111111111','RV04','RV',1,4,'single_choice',true),
  ('ee000005-0000-4000-8000-000000000005','ed111111-1111-4111-8111-111111111111','RV05','RV',1,5,'single_choice',true),
  ('ee000006-0000-4000-8000-000000000006','ed111111-1111-4111-8111-111111111111','RV06','RV',1,6,'text',true),
  ('ee000007-0000-4000-8000-000000000007','ed111111-1111-4111-8111-111111111111','RV07a','RV',1,7,'text',true),
  ('ee000008-0000-4000-8000-000000000008','ed111111-1111-4111-8111-111111111111','RV07b','RV',1,8,'text',true),
  ('ee000009-0000-4000-8000-000000000009','ed111111-1111-4111-8111-111111111111','RV08','RV',1,9,'ordered_sequence',true),
  ('ee000010-0000-4000-8000-000000000010','ed111111-1111-4111-8111-111111111111','RV09','RV',1,10,'choice_and_text',true),
  ('ee000016-0000-4000-8000-000000000016','ed111111-1111-4111-8111-111111111111','LC01','LC',1,11,'single_choice',true),
  ('ee000017-0000-4000-8000-000000000017','ed111111-1111-4111-8111-111111111111','LC02','LC',1,12,'single_choice',true),
  ('ee000018-0000-4000-8000-000000000018','ed111111-1111-4111-8111-111111111111','LC03','LC',1,13,'single_choice',true),
  ('ee000019-0000-4000-8000-000000000019','ed111111-1111-4111-8111-111111111111','LC04','LC',1,14,'single_choice',true),
  ('ee000020-0000-4000-8000-000000000020','ed111111-1111-4111-8111-111111111111','LC05','LC',1,15,'text',true)
ON CONFLICT (id) DO NOTHING;
