-- Phase 2: completing an optional PDF attachment must atomically switch an
-- existing accepted typed response to typed_pdf. The accepted mode is exposed
-- only after private original-file metadata and its immutable PDF.js transcript
-- have both been written. No OCR or transcript guesses are permitted.

CREATE OR REPLACE FUNCTION public.finalize_submission_file_upload(
  p_actor_id uuid,
  p_file_id uuid,
  p_sha256 text,
  p_byte_size bigint,
  p_page_count integer,
  p_mime_type text,
  p_transcript_pages jsonb
)
RETURNS TABLE(
  file_id uuid, submission_id uuid, version_number integer,
  sha256 text, byte_size bigint, mime_type text,
  page_count integer, upload_state text, accepted_at timestamptz
)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $function$
DECLARE
  selected_file private.submission_files%ROWTYPE;
  selected_submission public.assessment_submissions%ROWTYPE;
  accepted_time timestamptz;
  expected_page integer := 0;
  digital_page_count integer := 0;
  extracted_text text := '';
  transcript_state text;
  transcript_version integer;
  page_entry jsonb;
  page_text text;
  page_status text;
BEGIN
  IF coalesce(auth.jwt() ->> 'role', '') <> 'service_role'
    OR p_actor_id IS NULL
    OR NOT EXISTS (
      SELECT 1 FROM public.profiles AS profile
      WHERE profile.user_id = p_actor_id AND profile.account_status = 'active'
    )
    OR NOT EXISTS (
      SELECT 1 FROM public.role_assignments AS role
      WHERE role.user_id = p_actor_id
        AND role.role = 'student'::public.app_role
        AND role.revoked_at IS NULL
    ) THEN
    RAISE EXCEPTION USING ERRCODE = '42501', MESSAGE = 'submission_file_upload_forbidden';
  END IF;

  SELECT file_record.* INTO selected_file
  FROM private.submission_files AS file_record
  WHERE file_record.id = p_file_id
    AND file_record.learner_id = p_actor_id
  FOR UPDATE;
  IF NOT FOUND THEN
    RAISE EXCEPTION USING ERRCODE = 'P0002', MESSAGE = 'submission_file_not_found';
  END IF;
  IF selected_file.upload_state <> 'pending' THEN
    RAISE EXCEPTION USING ERRCODE = 'P0001', MESSAGE = 'submission_file_not_pending';
  END IF;
  IF selected_file.expires_at <= clock_timestamp() THEN
    RAISE EXCEPTION USING ERRCODE = 'P0001', MESSAGE = 'submission_file_upload_expired';
  END IF;

  IF p_sha256 IS NULL OR p_sha256 !~ '^[a-f0-9]{64}$'
    OR p_byte_size IS NULL OR p_byte_size NOT BETWEEN 1 AND 10485760
    OR p_page_count IS NULL OR p_page_count NOT BETWEEN 1 AND 10
    OR p_mime_type IS DISTINCT FROM 'application/pdf'
    OR jsonb_typeof(p_transcript_pages) IS DISTINCT FROM 'array' THEN
    RAISE EXCEPTION USING ERRCODE = '22023', MESSAGE = 'invalid_submission_file_metadata';
  END IF;
  IF jsonb_array_length(p_transcript_pages) <> p_page_count THEN
    RAISE EXCEPTION USING ERRCODE = '22023', MESSAGE = 'invalid_pdf_transcript_pages';
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM storage.objects AS object_record
    WHERE object_record.bucket_id = 'private-submissions'
      AND object_record.name = selected_file.object_path
  ) THEN
    RAISE EXCEPTION USING ERRCODE = 'P0002', MESSAGE = 'submission_file_object_missing';
  END IF;

  SELECT submission.* INTO selected_submission
  FROM public.assessment_submissions AS submission
  WHERE submission.id = selected_file.submission_id
    AND submission.learner_id = p_actor_id
  FOR UPDATE;
  IF NOT FOUND
    OR selected_submission.status <> 'queued'
    OR selected_submission.response_mode NOT IN ('typed', 'typed_pdf') THEN
    RAISE EXCEPTION USING ERRCODE = '42501', MESSAGE = 'submission_file_upload_forbidden';
  END IF;

  -- A typed submission may transition to typed-plus-PDF only when its original
  -- accepted typed response is present. Preserve the response and its version.
  IF selected_submission.response_mode = 'typed'
    AND NOT EXISTS (
      SELECT 1
      FROM public.submission_versions AS response_version
      WHERE response_version.submission_id = selected_submission.id
        AND response_version.version_number = 1
        AND char_length(btrim(response_version.response_text)) > 0
    ) THEN
    RAISE EXCEPTION USING ERRCODE = 'P0001', MESSAGE = 'submission_file_typed_response_missing';
  END IF;

  -- Validate every page in order. A missing digital text layer is represented
  -- explicitly; neither the browser nor server invents text for that page.
  FOR page_entry IN
    SELECT value
    FROM jsonb_array_elements(p_transcript_pages) WITH ORDINALITY AS item(value, ordinal)
    ORDER BY ordinal
  LOOP
    expected_page := expected_page + 1;
    IF jsonb_typeof(page_entry) IS DISTINCT FROM 'object'
      OR (SELECT count(*) FROM jsonb_object_keys(page_entry)) <> 3
      OR NOT (page_entry ?& ARRAY['page_number', 'text', 'status'])
      OR jsonb_typeof(page_entry -> 'page_number') IS DISTINCT FROM 'number'
      OR jsonb_typeof(page_entry -> 'text') IS DISTINCT FROM 'string'
      OR jsonb_typeof(page_entry -> 'status') IS DISTINCT FROM 'string'
      OR (page_entry ->> 'page_number') !~ '^[1-9][0-9]*$' THEN
      RAISE EXCEPTION USING ERRCODE = '22023', MESSAGE = 'invalid_pdf_transcript_page';
    END IF;

    page_text := page_entry ->> 'text';
    page_status := page_entry ->> 'status';
    IF (page_entry ->> 'page_number')::integer IS DISTINCT FROM expected_page
      OR char_length(page_text) > 12000
      OR page_status NOT IN ('digital_text', 'no_text_layer')
      OR (page_status = 'no_text_layer' AND page_text <> '')
      OR (page_status = 'digital_text' AND char_length(btrim(page_text)) = 0) THEN
      RAISE EXCEPTION USING ERRCODE = '22023', MESSAGE = 'invalid_pdf_transcript_page';
    END IF;

    IF page_status = 'digital_text' THEN
      digital_page_count := digital_page_count + 1;
    END IF;
    extracted_text := extracted_text ||
      CASE WHEN expected_page = 1 THEN '' ELSE E'\n\n' END ||
      CASE WHEN page_status = 'digital_text' THEN page_text ELSE '' END;
  END LOOP;

  IF char_length(extracted_text) > 120000 THEN
    RAISE EXCEPTION USING ERRCODE = '22023', MESSAGE = 'pdf_transcript_too_large';
  END IF;
  transcript_state := CASE
    WHEN digital_page_count = p_page_count THEN 'complete'
    WHEN digital_page_count = 0 THEN 'none'
    ELSE 'partial'
  END;

  accepted_time := clock_timestamp();
  UPDATE private.submission_files AS file_record
  SET sha256 = p_sha256,
      byte_size = p_byte_size,
      mime_type = p_mime_type,
      page_count = p_page_count,
      upload_state = 'accepted',
      accepted_at = accepted_time,
      updated_at = accepted_time,
      rejection_category = NULL
  WHERE file_record.id = p_file_id
  RETURNING * INTO selected_file;

  SELECT coalesce(max(transcript.version_number), 0) + 1
    INTO transcript_version
  FROM private.submission_transcript_versions AS transcript
  WHERE transcript.submission_id = selected_submission.id;

  INSERT INTO private.submission_transcript_versions (
    submission_id, source_file_id, version_number, extraction_method,
    extraction_state, verification_state, page_count, pages,
    content_text, created_by, created_at
  )
  VALUES (
    selected_submission.id, selected_file.id, transcript_version, 'pdfjs',
    transcript_state, 'unverified', p_page_count, p_transcript_pages,
    extracted_text, p_actor_id, accepted_time
  );

  -- Publish the accepted response mode only when its original typed response,
  -- private PDF and immutable transcript have all been persisted successfully.
  -- The submission row lock above serializes competing attachment attempts.
  IF selected_submission.response_mode = 'typed' THEN
    UPDATE public.assessment_submissions
    SET response_mode = 'typed_pdf'
    WHERE id = selected_submission.id
      AND response_mode = 'typed';
    IF NOT FOUND THEN
      RAISE EXCEPTION USING ERRCODE = 'P0001', MESSAGE = 'submission_file_response_mode_transition_failed';
    END IF;
  END IF;

  INSERT INTO private.security_audit_events (
    actor_id, action, target_type, target_id, outcome, reason_category
  )
  VALUES (
    p_actor_id, 'submission_file_upload_accepted', 'submission_file',
    selected_file.id, 'success', 'learner_upload'
  );

  RETURN QUERY
    SELECT selected_file.id, selected_file.submission_id, selected_file.version_number,
           selected_file.sha256, selected_file.byte_size, selected_file.mime_type,
           selected_file.page_count, selected_file.upload_state, selected_file.accepted_at;
END;
$function$;

COMMENT ON FUNCTION public.finalize_submission_file_upload(
  uuid, uuid, text, bigint, integer, text, jsonb
) IS
  'Atomically accepts private optional PDF metadata and its immutable page-aligned PDF.js transcript, and transitions an eligible existing typed submission to typed_pdf. No OCR or public transcript writes are permitted.';
