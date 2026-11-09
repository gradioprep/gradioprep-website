BEGIN;
SELECT plan(20);

SELECT ok(
  EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_schema = 'private'
      AND table_name = 'submission_transcript_versions'
      AND column_name = 'review_note'
  ),
  'teacher review notes are stored with the immutable transcript version'
);
SELECT ok(
  EXISTS (
    SELECT 1 FROM pg_constraint
    WHERE conrelid = 'private.submission_transcript_versions'::regclass
      AND conname = 'submission_transcript_versions_extraction_method_check'
      AND pg_get_constraintdef(oid) LIKE '%teacher_review%'
  ),
  'transcript versions distinguish PDF.js extraction from teacher-reviewed versions'
);
SELECT ok(
  (SELECT relrowsecurity FROM pg_class WHERE oid = 'private.submission_transcript_versions'::regclass),
  'transcript versions remain protected by RLS'
);
SELECT ok(
  NOT has_table_privilege('authenticated', 'private.submission_transcript_versions', 'SELECT')
  AND NOT has_table_privilege('service_role', 'private.submission_transcript_versions', 'UPDATE'),
  'browser and Worker roles cannot directly read or mutate transcript versions'
);
SELECT ok(
  NOT has_function_privilege('authenticated',
    'public.append_submission_transcript_version(uuid,text,uuid,integer,jsonb,text)', 'EXECUTE')
  AND has_function_privilege('service_role',
    'public.append_submission_transcript_version(uuid,text,uuid,integer,jsonb,text)', 'EXECUTE'),
  'only the trusted Worker can append a transcript review version'
);

CREATE TEMP TABLE phase2_review_submission_context (submission_id uuid);
GRANT SELECT, INSERT ON phase2_review_submission_context TO authenticated, service_role;

SET LOCAL ROLE authenticated;
SELECT set_config(
  'request.jwt.claims',
  '{"sub":"11111111-1111-4111-8111-111111111111","role":"authenticated","aal":"aal1"}',
  true
);
INSERT INTO phase2_review_submission_context
SELECT submission_id
FROM public.accept_assessment_submission(
  'a1111111-1111-4111-8111-111111111111',
  'd1111111-1111-4111-8111-111111111111',
  'Synthetic transcript review test response with enough words to be accepted.'
);
RESET ROLE;

INSERT INTO private.submission_files (
  submission_id, learner_id, version_number, object_path, sha256,
  byte_size, mime_type, page_count, upload_state,
  created_at, updated_at, expires_at, accepted_at
)
SELECT
  submission_id, '11111111-1111-4111-8111-111111111111', 1,
  gen_random_uuid()::text || '/' || gen_random_uuid()::text || '.pdf',
  repeat('a', 64), 4096, 'application/pdf', 2, 'accepted',
  clock_timestamp(), clock_timestamp(), clock_timestamp() + interval '100 years',
  clock_timestamp()
FROM phase2_review_submission_context;

INSERT INTO private.submission_transcript_versions (
  submission_id, source_file_id, version_number, extraction_method,
  extraction_state, verification_state, page_count, pages, content_text, created_by
)
SELECT
  file_record.submission_id, file_record.id, 1, 'pdfjs',
  'partial', 'unverified', 2,
  '[
    {"page_number":1,"text":"Synthetic extracted text from page one.","status":"digital_text"},
    {"page_number":2,"text":"","status":"no_text_layer"}
  ]'::jsonb,
  'Synthetic extracted text from page one.',
  '11111111-1111-4111-8111-111111111111'
FROM private.submission_files AS file_record
WHERE file_record.submission_id = (SELECT submission_id FROM phase2_review_submission_context);

SET LOCAL ROLE authenticated;
SELECT set_config(
  'request.jwt.claims',
  '{"sub":"88888888-8888-4888-8888-888888888888","role":"authenticated","aal":"aal2"}',
  true
);
SELECT lives_ok(
  format(
    'SELECT * FROM public.assign_submission_to_grader(%L,%L,%L)',
    (SELECT submission_id FROM phase2_review_submission_context),
    '55555555-5555-4555-8555-555555555555',
    'Synthetic transcript review assignment'
  ),
  'Owner AAL2 assigns the synthetic PDF submission to Grader A'
);
RESET ROLE;

SELECT is(
  (SELECT count(*)::integer
   FROM private.submission_transcript_versions AS transcript
   WHERE transcript.submission_id = (SELECT submission_id FROM phase2_review_submission_context)
     AND transcript.version_number = 1
     AND transcript.verification_state = 'unverified'),
  1,
  'the original extracted transcript remains version 1 and unverified'
);

SET LOCAL ROLE service_role;
SELECT set_config(
  'request.jwt.claims',
  '{"sub":"55555555-5555-4555-8555-555555555555","role":"service_role","aal":"aal1"}',
  true
);
SELECT throws_ok(
  format(
    $sql$SELECT * FROM public.append_submission_transcript_version(
      '55555555-5555-4555-8555-555555555555','aal1',%L,1,
      '[{"page_number":1,"text":"Synthetic corrected text from page one.","status":"teacher_transcribed"},{"page_number":2,"text":"Human transcription from page two.","status":"teacher_transcribed"}]'::jsonb,
      'Compared the transcript with the original PDF.'
    )$sql$,
    (SELECT submission_id FROM phase2_review_submission_context)
  ),
  '42501',
  'submission_transcript_review_forbidden',
  'AAL1 Grader is denied transcript review'
);
SELECT set_config(
  'request.jwt.claims',
  '{"sub":"11111111-1111-4111-8111-111111111111","role":"service_role","aal":"aal2"}',
  true
);
SELECT throws_ok(
  format(
    $sql$SELECT * FROM public.append_submission_transcript_version(
      '11111111-1111-4111-8111-111111111111','aal2',%L,1,
      '[{"page_number":1,"text":"Synthetic corrected text from page one.","status":"teacher_transcribed"},{"page_number":2,"text":"Human transcription from page two.","status":"teacher_transcribed"}]'::jsonb,
      'Compared the transcript with the original PDF.'
    )$sql$,
    (SELECT submission_id FROM phase2_review_submission_context)
  ),
  '42501',
  'submission_transcript_review_forbidden',
  'Student A is denied transcript review even at AAL2'
);
SELECT set_config(
  'request.jwt.claims',
  '{"sub":"66666666-6666-4666-8666-666666666666","role":"service_role","aal":"aal2"}',
  true
);
SELECT throws_ok(
  format(
    $sql$SELECT * FROM public.append_submission_transcript_version(
      '66666666-6666-4666-8666-666666666666','aal2',%L,1,
      '[{"page_number":1,"text":"Synthetic corrected text from page one.","status":"teacher_transcribed"},{"page_number":2,"text":"Human transcription from page two.","status":"teacher_transcribed"}]'::jsonb,
      'Compared the transcript with the original PDF.'
    )$sql$,
    (SELECT submission_id FROM phase2_review_submission_context)
  ),
  '42501',
  'submission_transcript_review_forbidden',
  'an unassigned active Grader cannot review another Grader submission'
);

CREATE TEMP TABLE phase2_review_version_context (
  transcript_id uuid,
  transcript_version integer,
  source_file_id uuid,
  verification_state text,
  pages jsonb,
  content_text text
);
GRANT SELECT, INSERT ON phase2_review_version_context TO service_role;

SELECT set_config(
  'request.jwt.claims',
  '{"sub":"55555555-5555-4555-8555-555555555555","role":"service_role","aal":"aal2"}',
  true
);
INSERT INTO phase2_review_version_context
SELECT transcript_id, transcript_version, source_file_id,
       verification_state, pages, content_text
FROM public.append_submission_transcript_version(
  '55555555-5555-4555-8555-555555555555',
  'aal2',
  (SELECT submission_id FROM phase2_review_submission_context),
  1,
  '[
    {"page_number":1,"text":"Synthetic corrected text from page one.","status":"teacher_transcribed"},
    {"page_number":2,"text":"Human transcription from page two.","status":"teacher_transcribed"}
  ]'::jsonb,
  'Compared both pages with the original PDF and transcribed page two.'
);
RESET ROLE;

SELECT is(
  (SELECT transcript_version FROM phase2_review_version_context),
  2,
  'the Grader A review appends version 2 rather than editing version 1'
);
SELECT is(
  (SELECT verification_state FROM phase2_review_version_context),
  'teacher_corrected'::text,
  'a changed transcript version is marked teacher_corrected'
);
SELECT ok(
  (SELECT pages @> '[{"page_number":2,"status":"teacher_transcribed"}]'::jsonb
   AND content_text LIKE '%Human transcription from page two%'
   FROM phase2_review_version_context),
  'a page with no original text layer can receive an explicit human transcription'
);
SELECT is(
  (SELECT verification_state
   FROM private.submission_transcript_versions
   WHERE submission_id = (SELECT submission_id FROM phase2_review_submission_context)
     AND version_number = 1),
  'unverified'::text,
  'the original transcript remains unchanged after a corrected version is appended'
);
SELECT throws_ok(
  format(
    $sql$SELECT * FROM public.append_submission_transcript_version(
      '55555555-5555-4555-8555-555555555555','aal2',%L,1,
      '[{"page_number":1,"text":"Synthetic stale edit.","status":"teacher_transcribed"},{"page_number":2,"text":"Human transcription from page two.","status":"teacher_transcribed"}]'::jsonb,
      'This stale edit must conflict with version 2.'
    )$sql$,
    (SELECT submission_id FROM phase2_review_submission_context)
  ),
  'P0001',
  'submission_transcript_version_conflict',
  'a stale editor cannot overwrite a newer transcript version'
);

SELECT set_config(
  'request.jwt.claims',
  '{"sub":"88888888-8888-4888-8888-888888888888","role":"service_role","aal":"aal2"}',
  true
);
SELECT is(
  (SELECT transcript_version
   FROM public.append_submission_transcript_version(
     '88888888-8888-4888-8888-888888888888',
     'aal2',
     (SELECT submission_id FROM phase2_review_submission_context),
     2,
     '[
       {"page_number":1,"text":"Synthetic corrected text from page one.","status":"teacher_transcribed"},
       {"page_number":2,"text":"Human transcription from page two.","status":"teacher_transcribed"}
     ]'::jsonb,
     'Owner independently verified the saved page-aligned transcript.'
   )),
  3,
  'Owner AAL2 can append an independent verification version'
);
SELECT is(
  (SELECT verification_state
   FROM private.submission_transcript_versions
   WHERE submission_id = (SELECT submission_id FROM phase2_review_submission_context)
     AND version_number = 3),
  'teacher_verified'::text,
  'an unchanged reviewed transcript is marked teacher_verified'
);

SELECT is(
  (SELECT count(*)::integer
   FROM private.security_audit_events AS event
   WHERE event.action = 'submission_transcript_version_appended'
     AND event.target_type = 'submission_transcript_version'
     AND event.outcome = 'success'),
  2,
  'each successful transcript version append creates a server-side audit event'
);

SET LOCAL ROLE service_role;
SELECT set_config(
  'request.jwt.claims',
  '{"sub":"11111111-1111-4111-8111-111111111111","role":"service_role","aal":"aal1"}',
  true
);
SELECT is(
  public.record_worker_audit_outcome(
    '11111111-1111-4111-8111-111111111111',
    'student_submission_file_upload',
    (SELECT submission_id FROM phase2_review_submission_context),
    'failed',
    'resource_not_found'
  ),
  true,
  'the legacy private-PDF upload denial action remains in the Worker audit allowlist'
);
SELECT is(
  public.record_worker_audit_outcome(
    '88888888-8888-4888-8888-888888888888',
    'owner_submission_file_cleanup',
    NULL,
    'failed',
    'operation_failed'
  ),
  true,
  'the Owner private-PDF cleanup failure action remains in the Worker audit allowlist'
);
RESET ROLE;

SELECT * FROM finish();
ROLLBACK;
