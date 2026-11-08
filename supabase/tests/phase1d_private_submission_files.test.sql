BEGIN;
SELECT plan(33);

SELECT is(
  (SELECT public FROM storage.buckets WHERE id = 'private-submissions'),
  false,
  'the submission PDF bucket is private'
);
SELECT is(
  (SELECT file_size_limit::bigint FROM storage.buckets WHERE id = 'private-submissions'),
  10485760::bigint,
  'Storage enforces the 10 MiB upload ceiling'
);
SELECT is(
  (SELECT allowed_mime_types FROM storage.buckets WHERE id = 'private-submissions'),
  ARRAY['application/pdf']::text[],
  'Storage bucket accepts only declared PDF MIME'
);
SELECT ok(
  (SELECT relrowsecurity FROM pg_class WHERE oid = 'private.submission_files'::regclass),
  'private file metadata has RLS enabled'
);
SELECT ok(
  NOT has_table_privilege('anon', 'private.submission_files', 'SELECT'),
  'anonymous role has no direct file-metadata read grant'
);
SELECT ok(
  NOT has_table_privilege('authenticated', 'private.submission_files', 'SELECT'),
  'authenticated browser roles have no direct file-metadata read grant'
);
SELECT ok(
  NOT has_table_privilege('service_role', 'private.submission_files', 'SELECT'),
  'Worker service role must use the narrow file RPCs, not direct table reads'
);

SELECT has_column(
  'public', 'task_versions', 'pdf_response_enabled',
  'task versions carry an explicit PDF response opt-in'
);
SELECT has_column(
  'public', 'assessment_submissions', 'response_mode',
  'accepted submissions record their actual response mode'
);
SELECT ok(
  EXISTS (
    SELECT 1 FROM pg_constraint
    WHERE conrelid = 'public.task_versions'::regclass
      AND conname = 'task_versions_pdf_response_threshold_check'
  ),
  'database constraint enforces the greater-than-20-word PDF eligibility threshold'
);
SELECT ok(
  (SELECT pdf_response_enabled AND ideal_words > 20
   FROM public.task_versions
   WHERE id = 'a1111111-1111-4111-8111-111111111111'),
  'the synthetic IB task explicitly enables PDF because its ideal response exceeds 20 words'
);
SELECT ok(
  NOT (SELECT pdf_response_enabled
       FROM public.task_versions
       WHERE id = 'a2222222-2222-4222-8222-222222222222'),
  'the synthetic Cambridge task remains typed-only'
);
SELECT throws_ok(
  $UPDATE public.task_versions
    SET pdf_response_enabled = true, ideal_words = 20
    WHERE id = 'a1111111-1111-4111-8111-111111111111'$,
  '23514',
  'new row for relation "task_versions" violates check constraint "task_versions_pdf_response_threshold_check"',
  'a task at the 20-word boundary cannot enable PDF response'
);
SELECT ok(
  NOT has_function_privilege('anon', 'public.begin_submission_file_upload(uuid,uuid)', 'EXECUTE'),
  'anonymous users cannot begin file uploads'
);
SELECT ok(
  NOT has_function_privilege('authenticated', 'public.begin_submission_file_upload(uuid,uuid)', 'EXECUTE'),
  'browser clients cannot bypass Worker PDF validation through the upload RPC'
);
SELECT ok(
  has_function_privilege('service_role', 'public.begin_submission_file_upload(uuid,uuid)', 'EXECUTE'),
  'only the trusted Worker role can begin an upload'
);

CREATE TEMP TABLE phase1d_submission_context (submission_id uuid);
GRANT SELECT, INSERT ON phase1d_submission_context TO authenticated, service_role;

SET LOCAL ROLE authenticated;
SELECT set_config(
  'request.jwt.claims',
  '{"sub":"11111111-1111-4111-8111-111111111111","role":"authenticated","aal":"aal1"}',
  true
);
INSERT INTO phase1d_submission_context
SELECT submission_id
FROM public.accept_assessment_submission(
  'a1111111-1111-4111-8111-111111111111',
  '1d111111-1111-4111-8111-111111111111',
  'Synthetic Phase 1D file security test response with enough words to satisfy the accepted assessment workflow.'
);
RESET ROLE;

SELECT is(
  (SELECT response_mode
   FROM public.assessment_submissions
   WHERE id = (SELECT submission_id FROM phase1d_submission_context)),
  'typed'::text,
  'a typed text submission starts in typed response mode'
);
SELECT throws_ok(
  format(
    'UPDATE public.assessment_submissions SET response_mode = %L WHERE id = %L',
    'typed_pdf',
    (SELECT submission_id FROM phase1d_submission_context)
  ),
  '42501',
  'assessment_submission_response_mode_change_forbidden',
  'a learner cannot claim PDF mode before an accepted private PDF exists'
);

-- Create a synthetic accepted file version first. The pending upload below
-- must receive version 2; its Worker acceptance is covered end-to-end in Playwright.
INSERT INTO private.submission_files (
  submission_id, learner_id, version_number, object_path,
  sha256, byte_size, mime_type, page_count,
  upload_state, created_at, updated_at, expires_at, accepted_at
)
SELECT
  submission_id,
  '11111111-1111-4111-8111-111111111111',
  1,
  gen_random_uuid()::text || '/' || gen_random_uuid()::text || '.pdf',
  repeat('a', 64),
  4096,
  'application/pdf',
  1,
  'accepted',
  clock_timestamp() - interval '1 minute',
  clock_timestamp(),
  clock_timestamp() + interval '14 minutes',
  clock_timestamp()
FROM phase1d_submission_context;

CREATE TEMP TABLE phase1d_accepted_context (file_id uuid, submission_id uuid);
GRANT SELECT ON phase1d_accepted_context TO service_role;
INSERT INTO phase1d_accepted_context
SELECT id, submission_id
FROM private.submission_files
WHERE upload_state = 'accepted'
  AND submission_id = (SELECT submission_id FROM phase1d_submission_context);

CREATE TEMP TABLE phase1d_pending_context (file_id uuid, object_path text);
GRANT SELECT, INSERT ON phase1d_pending_context TO service_role;
SET LOCAL ROLE service_role;
SELECT set_config(
  'request.jwt.claims',
  '{"sub":"11111111-1111-4111-8111-111111111111","role":"service_role","aal":"aal1"}',
  true
);
INSERT INTO phase1d_pending_context
SELECT file_id, object_path
FROM public.begin_submission_file_upload(
  '11111111-1111-4111-8111-111111111111',
  (SELECT submission_id FROM phase1d_submission_context)
);
RESET ROLE;

SELECT is(
  (SELECT upload_state FROM private.submission_files
   WHERE id = (SELECT file_id FROM phase1d_pending_context)),
  'pending'::text,
  'Worker upload initialization creates a pending opaque-path record'
);

INSERT INTO public.submission_grader_assignments (
  submission_id, grader_user_id, assigned_by, reason
)
SELECT
  submission_id,
  '55555555-5555-4555-8555-555555555555',
  '88888888-8888-4888-8888-888888888888',
  'Synthetic Phase 1D authorization fixture'
FROM phase1d_accepted_context;

SET LOCAL ROLE service_role;
SELECT set_config(
  'request.jwt.claims',
  '{"sub":"88888888-8888-4888-8888-888888888888","role":"service_role","aal":"aal2"}',
  true
);

SELECT is(
  (SELECT count(*)::integer
   FROM public.get_authorized_submission_file(
     '11111111-1111-4111-8111-111111111111',
     'aal1',
     (SELECT submission_id FROM phase1d_accepted_context)
   )),
  1,
  'Student can retrieve own accepted-file metadata'
);
SELECT is(
  (SELECT count(*)::integer
   FROM public.get_authorized_submission_file(
     '22222222-2222-4222-8222-222222222222',
     'aal1',
     (SELECT submission_id FROM phase1d_accepted_context)
   )),
  0,
  'another learner cannot retrieve the file metadata'
);
SELECT is(
  (SELECT count(*)::integer
   FROM public.get_authorized_submission_file(
     '55555555-5555-4555-8555-555555555555',
     'aal1',
     (SELECT submission_id FROM phase1d_accepted_context)
   )),
  0,
  'an assigned Grader at AAL1 cannot retrieve accepted-file metadata'
);
SELECT is(
  (SELECT count(*)::integer
   FROM public.get_authorized_submission_file(
     '55555555-5555-4555-8555-555555555555',
     'aal2',
     (SELECT submission_id FROM phase1d_accepted_context)
   )),
  1,
  'an actively assigned Grader at AAL2 can retrieve accepted-file metadata'
);

RESET ROLE;
UPDATE public.submission_grader_assignments
SET revoked_at = clock_timestamp(),
    revoked_by = '88888888-8888-4888-8888-888888888888'
WHERE submission_id = (SELECT submission_id FROM phase1d_accepted_context)
  AND grader_user_id = '55555555-5555-4555-8555-555555555555'
  AND revoked_at IS NULL;

SET LOCAL ROLE service_role;
SELECT set_config(
  'request.jwt.claims',
  '{"sub":"88888888-8888-4888-8888-888888888888","role":"service_role","aal":"aal2"}',
  true
);
SELECT is(
  (SELECT count(*)::integer
   FROM public.get_authorized_submission_file(
     '55555555-5555-4555-8555-555555555555',
     'aal2',
     (SELECT submission_id FROM phase1d_accepted_context)
   )),
  0,
  'revoked Grader assignment is denied even at AAL2'
);
SELECT is(
  (SELECT count(*)::integer
   FROM public.get_authorized_submission_file(
     '88888888-8888-4888-8888-888888888888',
     'aal1',
     (SELECT submission_id FROM phase1d_accepted_context)
   )),
  0,
  'Owner at AAL1 cannot retrieve accepted-file metadata'
);
SELECT is(
  (SELECT count(*)::integer
   FROM public.get_authorized_submission_file(
     '88888888-8888-4888-8888-888888888888',
     'aal2',
     (SELECT submission_id FROM phase1d_accepted_context)
   )),
  1,
  'Owner at AAL2 can retrieve accepted-file metadata'
);
RESET ROLE;

SELECT throws_ok(
  format(
    'UPDATE private.submission_files SET sha256 = %L WHERE id = %L',
    repeat('b', 64),
    (SELECT file_id FROM phase1d_accepted_context)
  ),
  '42501',
  'accepted_submission_file_immutable',
  'accepted original metadata cannot be changed'
);
SELECT throws_ok(
  format(
    'DELETE FROM private.submission_files WHERE id = %L',
    (SELECT file_id FROM phase1d_accepted_context)
  ),
  '42501',
  'submission_file_delete_requires_retention_workflow',
  'accepted original metadata cannot be deleted directly'
);

-- Deterministically age the pending row in this local-only SQL test.
ALTER TABLE private.submission_files DISABLE TRIGGER submission_file_integrity_guard;
UPDATE private.submission_files
SET created_at = clock_timestamp() - interval '30 minutes',
    expires_at = clock_timestamp() - interval '15 minutes'
WHERE id = (SELECT file_id FROM phase1d_pending_context);
ALTER TABLE private.submission_files ENABLE TRIGGER submission_file_integrity_guard;

SET LOCAL ROLE service_role;
SELECT set_config(
  'request.jwt.claims',
  '{"sub":"11111111-1111-4111-8111-111111111111","role":"service_role","aal":"aal1"}',
  true
);
SELECT throws_ok(
  format(
    'SELECT * FROM public.finalize_submission_file_upload(%L,%L,%L,%s,%s,%L)',
    '11111111-1111-4111-8111-111111111111',
    (SELECT file_id FROM phase1d_pending_context),
    repeat('c', 64),
    1024,
    1,
    'application/pdf'
  ),
  'P0001',
  'submission_file_upload_expired',
  'expired temporary upload cannot be accepted'
);

CREATE TEMP TABLE phase1d_claimed_context (file_id uuid, object_path text);
GRANT SELECT, INSERT ON phase1d_claimed_context TO service_role;
SELECT set_config(
  'request.jwt.claims',
  '{"sub":"88888888-8888-4888-8888-888888888888","role":"service_role","aal":"aal2"}',
  true
);
INSERT INTO phase1d_claimed_context
SELECT file_id, object_path
FROM public.claim_expired_submission_file_uploads(
  '88888888-8888-4888-8888-888888888888',
  'aal2',
  clock_timestamp()
);
RESET ROLE;

SELECT is(
  (SELECT count(*)::integer FROM phase1d_claimed_context),
  1,
  'Owner AAL2 cleanup claims the expired pending object'
);
SELECT is(
  (SELECT upload_state FROM private.submission_files
   WHERE id = (SELECT file_id FROM phase1d_claimed_context)),
  'cleanup_pending'::text,
  'claimed expired upload enters cleanup-pending state'
);

SET LOCAL ROLE service_role;
SELECT set_config(
  'request.jwt.claims',
  '{"sub":"88888888-8888-4888-8888-888888888888","role":"service_role","aal":"aal2"}',
  true
);
SELECT is(
  public.finish_submission_file_cleanup(
    '88888888-8888-4888-8888-888888888888',
    'aal2',
    (SELECT file_id FROM phase1d_claimed_context)
  ),
  true,
  'cleanup completes only after the object is absent from Storage'
);
RESET ROLE;

SELECT is(
  (SELECT upload_state FROM private.submission_files
   WHERE id = (SELECT file_id FROM phase1d_claimed_context)),
  'abandoned'::text,
  'abandoned upload metadata remains as non-content audit evidence'
);

SELECT * FROM finish();
ROLLBACK;
