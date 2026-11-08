BEGIN;
SELECT plan(17);

SELECT ok(
  (SELECT relrowsecurity FROM pg_class WHERE oid = 'private.pdf_submission_reservations'::regclass),
  'temporary PDF reservations are protected by RLS'
);
SELECT ok(
  NOT has_table_privilege('anon', 'private.pdf_submission_reservations', 'SELECT')
  AND NOT has_table_privilege('authenticated', 'private.pdf_submission_reservations', 'SELECT')
  AND NOT has_table_privilege('service_role', 'private.pdf_submission_reservations', 'SELECT'),
  'all browser and Worker roles are denied direct reservation-table reads'
);
SELECT ok(
  NOT has_table_privilege('authenticated', 'private.submission_transcript_versions', 'SELECT')
  AND NOT has_table_privilege('service_role', 'private.submission_transcript_versions', 'SELECT'),
  'transcript versions are accessible only through the narrow authorization RPC'
);
SELECT ok(
  has_function_privilege('authenticated',
    'public.begin_pdf_assessment_submission(uuid,uuid,text,text)', 'EXECUTE'),
  'an authenticated learner can request a PDF reservation through the protected RPC'
);
SELECT ok(
  NOT has_function_privilege('authenticated',
    'public.finalize_pdf_assessment_submission(uuid,uuid,text,bigint,integer,text,jsonb)', 'EXECUTE')
  AND has_function_privilege('service_role',
    'public.finalize_pdf_assessment_submission(uuid,uuid,text,bigint,integer,text,jsonb)', 'EXECUTE'),
  'only the trusted Worker can finalize a PDF submission'
);
SELECT ok(
  has_function_privilege('service_role',
    'public.get_authorized_submission_transcript(uuid,text,uuid)', 'EXECUTE'),
  'the Worker can read transcripts only through the authorization RPC'
);
SELECT ok(
  EXISTS (
    SELECT 1 FROM pg_constraint
    WHERE conrelid = 'public.assessment_submissions'::regclass
      AND conname = 'assessment_submissions_response_mode_check'
      AND pg_get_constraintdef(oid) LIKE '%pdf_only%'
  ),
  'accepted response modes now include PDF-only submissions'
);
SELECT ok(
  (SELECT pdf_response_enabled AND ideal_words > 20
   FROM public.task_versions
   WHERE id = 'a1111111-1111-4111-8111-111111111111'),
  'the synthetic opted-in task remains eligible for PDF submissions'
);
SELECT ok(
  NOT (SELECT pdf_response_enabled
       FROM public.task_versions
       WHERE id = 'a3333333-3333-4333-8333-333333333333'),
  'the synthetic typed-only task cannot begin a PDF reservation'
);
SELECT ok(
  EXISTS (
    SELECT 1 FROM pg_trigger
    WHERE tgrelid = 'public.assessment_submissions'::regclass
      AND tgname = 'assessment_submission_capacity_with_pdf_reservations'
      AND NOT tgisinternal
  ),
  'typed acceptance and PDF reservations share the same serialized capacity check'
);
SELECT ok(
  EXISTS (
    SELECT 1 FROM pg_trigger
    WHERE tgrelid = 'private.submission_transcript_versions'::regclass
      AND tgname = 'submission_transcript_versions_immutable'
      AND NOT tgisinternal
  ),
  'transcript records have an append-only integrity trigger'
);

CREATE TEMP TABLE phase2_pdf_reservation_context (
  reservation_id uuid,
  object_path text,
  reservation_state text,
  expires_at timestamptz
);
GRANT SELECT, INSERT ON phase2_pdf_reservation_context TO authenticated, service_role;

SET LOCAL ROLE authenticated;
SELECT set_config(
  'request.jwt.claims',
  '{"sub":"11111111-1111-4111-8111-111111111111","role":"authenticated","aal":"aal1"}',
  true
);
INSERT INTO phase2_pdf_reservation_context
SELECT reservation_id, object_path, reservation_state, expires_at
FROM public.begin_pdf_assessment_submission(
  'a1111111-1111-4111-8111-111111111111',
  '5d111111-1111-4111-8111-111111111111',
  'pdf_only',
  NULL
);
RESET ROLE;

SELECT is(
  (SELECT reservation_state FROM phase2_pdf_reservation_context LIMIT 1),
  'reserved'::text,
  'an eligible PDF-only response first creates a temporary reservation'
);
SELECT ok(
  (SELECT expires_at > clock_timestamp()
      AND expires_at <= clock_timestamp() + interval '15 minutes'
   FROM phase2_pdf_reservation_context LIMIT 1),
  'a reservation has a bounded 15-minute expiry'
);
SELECT is(
  (SELECT count(*)::integer
   FROM public.assessment_submissions
   WHERE idempotency_key = '5d111111-1111-4111-8111-111111111111'),
  0,
  'a PDF reservation does not create an accepted submission or start the SLA'
);
SELECT throws_ok(
  'SELECT * FROM public.begin_pdf_assessment_submission(
    ''a1111111-1111-4111-8111-111111111111'',
    ''5d111111-1111-4111-8111-111111111111'',
    ''pdf_only'',
    NULL
  )',
  'P0001',
  'pdf_submission_in_progress',
  'a concurrent retry with the same idempotency key cannot create a second reservation'
);

SET LOCAL ROLE authenticated;
INSERT INTO phase2_pdf_reservation_context
SELECT reservation_id, object_path, reservation_state, expires_at
FROM public.begin_pdf_assessment_submission(
  'a1111111-1111-4111-8111-111111111111',
  '5d222222-2222-4222-8222-222222222222',
  'typed_pdf',
  'Synthetic typed-plus-PDF response text for the eligible task.'
);
RESET ROLE;

SELECT is(
  (SELECT count(*)::integer FROM phase2_pdf_reservation_context),
  2,
  'typed-plus-PDF and PDF-only both reserve capacity without accepting early'
);

SET LOCAL ROLE authenticated;
SELECT throws_ok(
  'SELECT * FROM public.begin_pdf_assessment_submission(
    ''a3333333-3333-4333-8333-333333333333'',
    ''5d333333-3333-4333-8333-333333333333'',
    ''pdf_only'',
    NULL
  )',
  'P0002',
  'assessment_task_not_available',
  'PDF-disabled tasks cannot reserve queue capacity'
);
RESET ROLE;

SELECT * FROM finish();
ROLLBACK;
