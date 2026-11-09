-- Phase 2: controlled teacher review and append-only transcript corrections.
-- The original private PDF remains authoritative. Review creates a new immutable
-- transcript version; no existing transcript row or source file is modified.

ALTER TABLE private.submission_transcript_versions
  DROP CONSTRAINT IF EXISTS submission_transcript_versions_extraction_method_check;

ALTER TABLE private.submission_transcript_versions
  ADD CONSTRAINT submission_transcript_versions_extraction_method_check
  CHECK (extraction_method IN ('pdfjs', 'teacher_review'));

ALTER TABLE private.submission_transcript_versions
  ADD COLUMN review_note text;

ALTER TABLE private.submission_transcript_versions
  ADD CONSTRAINT submission_transcript_versions_review_note_check
  CHECK (
    review_note IS NULL
    OR char_length(btrim(review_note)) BETWEEN 3 AND 240
  );

COMMENT ON COLUMN private.submission_transcript_versions.review_note IS
  'Private, teacher-entered explanation attached to this immutable review version. Never copied into audit metadata.';

CREATE OR REPLACE FUNCTION public.record_worker_audit_outcome(
  p_actor_id uuid,
  p_action text,
  p_target_id uuid,
  p_outcome text,
  p_failure_category text DEFAULT NULL
)
RETURNS boolean
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $function$
DECLARE
  resource_type text;
  success_reason text;
  requires_null_target boolean := false;
  is_protected_read boolean := false;
  event_reason text;
BEGIN
  IF coalesce(auth.jwt() ->> 'role', '') <> 'service_role'
    OR p_actor_id IS NULL
    OR NOT EXISTS (
      SELECT 1 FROM auth.users AS actor WHERE actor.id = p_actor_id
    ) THEN
    RETURN false;
  END IF;

  CASE p_action
    WHEN 'student_attempt_list_authorized' THEN resource_type := 'attempt_collection'; success_reason := 'student_self'; requires_null_target := true; is_protected_read := true;
    WHEN 'student_attempt_read_authorized' THEN resource_type := 'attempt'; success_reason := 'student_self'; is_protected_read := true;
    WHEN 'grader_attempt_queue_authorized' THEN resource_type := 'attempt_queue'; success_reason := 'assigned_grader_aal2'; requires_null_target := true; is_protected_read := true;
    WHEN 'grader_attempt_read_authorized' THEN resource_type := 'attempt'; success_reason := 'active_grader_assignment_aal2'; is_protected_read := true;
    WHEN 'student_submission_list_authorized' THEN resource_type := 'assessment_submission_collection'; success_reason := 'student_self'; requires_null_target := true; is_protected_read := true;
    WHEN 'student_submission_read_authorized' THEN resource_type := 'assessment_submission'; success_reason := 'student_self'; is_protected_read := true;
    WHEN 'grader_submission_queue_authorized' THEN resource_type := 'assessment_submission_queue'; success_reason := 'assigned_grader_aal2'; requires_null_target := true; is_protected_read := true;
    WHEN 'grader_submission_read_authorized' THEN resource_type := 'assessment_submission'; success_reason := 'active_grader_assignment_aal2'; is_protected_read := true;
    WHEN 'owner_submission_queue_authorized' THEN resource_type := 'assessment_submission_queue'; success_reason := 'owner_aal2'; requires_null_target := true; is_protected_read := true;
    WHEN 'staff_invitations_listed' THEN resource_type := 'staff_invitation_collection'; success_reason := 'owner_aal2'; requires_null_target := true; is_protected_read := true;
    WHEN 'private_qa_records_read' THEN resource_type := 'assessment_version'; success_reason := 'owner_qa_review'; is_protected_read := true;
    WHEN 'owner_role_revocation' THEN resource_type := 'role_assignment_subject';
    WHEN 'owner_attempt_assignment' THEN resource_type := 'attempt';
    WHEN 'owner_submission_assignment' THEN resource_type := 'assessment_submission';
    WHEN 'owner_submission_reassignment' THEN resource_type := 'assessment_submission';
    WHEN 'owner_submission_transition' THEN resource_type := 'assessment_submission';
    WHEN 'owner_private_qa_record_create' THEN resource_type := 'assessment_version';
    WHEN 'grader_assessment_draft_save' THEN resource_type := 'assessment_submission';
    WHEN 'grader_assessment_feedback_publish' THEN resource_type := 'assessment_submission';
    WHEN 'staff_submission_transcript_review' THEN resource_type := 'assessment_submission';
    WHEN 'student_submission_file_upload' THEN resource_type := 'assessment_submission';
    WHEN 'owner_submission_file_cleanup' THEN resource_type := 'submission_file_collection'; requires_null_target := true;
    WHEN 'student_attempt_create' THEN resource_type := 'task_version';
    WHEN 'student_attempt_response_save' THEN resource_type := 'attempt';
    WHEN 'student_attempt_submit' THEN resource_type := 'attempt';
    WHEN 'student_assessment_submission_accept' THEN resource_type := 'task_version';
    WHEN 'staff_invitation_created' THEN resource_type := 'staff_invitation'; requires_null_target := true;
    WHEN 'staff_invitation_revoked' THEN resource_type := 'staff_invitation';
    ELSE RETURN false;
  END CASE;

  IF (requires_null_target AND p_target_id IS NOT NULL)
    OR (NOT requires_null_target AND p_target_id IS NULL) THEN
    RETURN false;
  END IF;

  IF p_outcome = 'success' THEN
    IF NOT is_protected_read OR p_failure_category IS NOT NULL THEN RETURN false; END IF;
    event_reason := success_reason;
  ELSIF p_outcome = 'denied' THEN
    IF p_failure_category IS NOT NULL THEN RETURN false; END IF;
    event_reason := 'resource_scope_denied';
  ELSIF p_outcome = 'failed' THEN
    IF is_protected_read THEN
      IF p_failure_category IS NOT NULL THEN RETURN false; END IF;
      event_reason := 'database_read_failed';
    ELSE
      IF p_failure_category IS NULL OR p_failure_category NOT IN (
        'resource_not_found','state_conflict','validation_failed',
        'last_owner_protected','capacity_unavailable','operation_failed'
      ) THEN
        RETURN false;
      END IF;
      event_reason := p_failure_category;
    END IF;
  ELSE
    RETURN false;
  END IF;

  INSERT INTO private.security_audit_events(
    actor_id, action, target_type, target_id, outcome, reason_category
  )
  VALUES (
    p_actor_id, p_action, resource_type, p_target_id, p_outcome, event_reason
  );
  RETURN true;
END;
$function$;

ALTER FUNCTION public.record_worker_audit_outcome(uuid,text,uuid,text,text) OWNER TO postgres;
REVOKE ALL ON FUNCTION public.record_worker_audit_outcome(uuid,text,uuid,text,text)
  FROM PUBLIC, anon, authenticated;
GRANT EXECUTE ON FUNCTION public.record_worker_audit_outcome(uuid,text,uuid,text,text)
  TO service_role;

CREATE OR REPLACE FUNCTION public.append_submission_transcript_version(
  p_actor_id uuid,
  p_assurance text,
  p_submission_id uuid,
  p_expected_version integer,
  p_pages jsonb,
  p_review_note text
)
RETURNS TABLE(
  transcript_id uuid,
  transcript_version integer,
  source_file_id uuid,
  extraction_method text,
  extraction_state text,
  verification_state text,
  page_count integer,
  pages jsonb,
  content_text text,
  review_note text,
  created_at timestamptz
)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $function$
DECLARE
  selected_submission public.assessment_submissions%ROWTYPE;
  selected_file private.submission_files%ROWTYPE;
  latest_transcript private.submission_transcript_versions%ROWTYPE;
  new_transcript_id uuid;
  next_version integer;
  expected_page integer := 0;
  digital_or_transcribed_pages integer := 0;
  extracted_content text := '';
  page_entry jsonb;
  page_text text;
  page_status text;
  next_extraction_state text;
  next_verification_state text;
BEGIN
  IF coalesce(auth.jwt() ->> 'role', '') <> 'service_role'
    OR p_actor_id IS NULL
    OR p_assurance IS DISTINCT FROM 'aal2'
    OR NOT EXISTS (
      SELECT 1 FROM public.profiles AS profile
      WHERE profile.user_id = p_actor_id
        AND profile.account_status = 'active'
    )
    OR NOT (
      EXISTS (
        SELECT 1 FROM public.role_assignments AS role
        WHERE role.user_id = p_actor_id
          AND role.role = 'owner'::public.app_role
          AND role.revoked_at IS NULL
      )
      OR EXISTS (
        SELECT 1 FROM public.role_assignments AS role
        JOIN public.submission_grader_assignments AS assignment
          ON assignment.grader_user_id = role.user_id
        WHERE role.user_id = p_actor_id
          AND role.role = 'grader'::public.app_role
          AND role.revoked_at IS NULL
          AND assignment.submission_id = p_submission_id
          AND assignment.revoked_at IS NULL
      )
    ) THEN
    RAISE EXCEPTION USING ERRCODE = '42501', MESSAGE = 'submission_transcript_review_forbidden';
  END IF;

  IF p_submission_id IS NULL
    OR p_expected_version IS NULL OR p_expected_version < 1
    OR jsonb_typeof(p_pages) IS DISTINCT FROM 'array'
    OR char_length(btrim(coalesce(p_review_note, ''))) NOT BETWEEN 3 AND 240 THEN
    RAISE EXCEPTION USING ERRCODE = '22023', MESSAGE = 'invalid_submission_transcript_review';
  END IF;

  -- Serialize all transcript versions for this submission and recheck the
  -- active assignment after taking the lock, so revocation cannot race a save.
  SELECT submission.* INTO selected_submission
  FROM public.assessment_submissions AS submission
  WHERE submission.id = p_submission_id
  FOR UPDATE;

  IF NOT FOUND OR selected_submission.status NOT IN ('assigned', 'grading', 'feedback_published') THEN
    RAISE EXCEPTION USING ERRCODE = 'P0002', MESSAGE = 'assessment_submission_not_reviewable';
  END IF;

  IF EXISTS (
    SELECT 1 FROM public.role_assignments AS role
    WHERE role.user_id = p_actor_id
      AND role.role = 'grader'::public.app_role
      AND role.revoked_at IS NULL
  ) AND NOT EXISTS (
    SELECT 1 FROM public.submission_grader_assignments AS assignment
    WHERE assignment.submission_id = p_submission_id
      AND assignment.grader_user_id = p_actor_id
      AND assignment.revoked_at IS NULL
  ) AND NOT EXISTS (
    SELECT 1 FROM public.role_assignments AS owner_role
    WHERE owner_role.user_id = p_actor_id
      AND owner_role.role = 'owner'::public.app_role
      AND owner_role.revoked_at IS NULL
  ) THEN
    RAISE EXCEPTION USING ERRCODE = '42501', MESSAGE = 'submission_transcript_review_forbidden';
  END IF;

  SELECT file_record.* INTO selected_file
  FROM private.submission_files AS file_record
  WHERE file_record.submission_id = p_submission_id
    AND file_record.upload_state = 'accepted'
  ORDER BY file_record.version_number DESC
  LIMIT 1;

  IF NOT FOUND THEN
    RAISE EXCEPTION USING ERRCODE = 'P0002', MESSAGE = 'submission_file_not_found';
  END IF;

  SELECT transcript.* INTO latest_transcript
  FROM private.submission_transcript_versions AS transcript
  WHERE transcript.submission_id = p_submission_id
    AND transcript.source_file_id = selected_file.id
  ORDER BY transcript.version_number DESC
  LIMIT 1
  FOR UPDATE;

  IF NOT FOUND THEN
    RAISE EXCEPTION USING ERRCODE = 'P0002', MESSAGE = 'submission_transcript_not_found';
  END IF;
  IF latest_transcript.version_number <> p_expected_version THEN
    RAISE EXCEPTION USING ERRCODE = 'P0001', MESSAGE = 'submission_transcript_version_conflict';
  END IF;
  IF jsonb_array_length(p_pages) <> latest_transcript.page_count THEN
    RAISE EXCEPTION USING ERRCODE = '22023', MESSAGE = 'invalid_submission_transcript_pages';
  END IF;

  FOR page_entry IN
    SELECT item.value
    FROM jsonb_array_elements(p_pages) WITH ORDINALITY AS item(value, ordinal)
    ORDER BY item.ordinal
  LOOP
    expected_page := expected_page + 1;
    IF jsonb_typeof(page_entry) IS DISTINCT FROM 'object'
      OR (SELECT count(*) FROM jsonb_object_keys(page_entry)) <> 3
      OR NOT (page_entry ?& ARRAY['page_number', 'text', 'status'])
      OR jsonb_typeof(page_entry -> 'page_number') IS DISTINCT FROM 'number'
      OR jsonb_typeof(page_entry -> 'text') IS DISTINCT FROM 'string'
      OR jsonb_typeof(page_entry -> 'status') IS DISTINCT FROM 'string' THEN
      RAISE EXCEPTION USING ERRCODE = '22023', MESSAGE = 'invalid_submission_transcript_page';
    END IF;

    page_text := page_entry ->> 'text';
    page_status := page_entry ->> 'status';
    IF page_entry ->> 'page_number' IS DISTINCT FROM expected_page::text
      OR char_length(page_text) > 12000
      OR page_status NOT IN ('digital_text', 'no_text_layer', 'teacher_transcribed')
      OR (page_status = 'no_text_layer' AND page_text <> '')
      OR (page_status IN ('digital_text', 'teacher_transcribed')
          AND char_length(btrim(page_text)) = 0) THEN
      RAISE EXCEPTION USING ERRCODE = '22023', MESSAGE = 'invalid_submission_transcript_page';
    END IF;

    IF page_status IN ('digital_text', 'teacher_transcribed') THEN
      digital_or_transcribed_pages := digital_or_transcribed_pages + 1;
      extracted_content := extracted_content ||
        CASE WHEN expected_page = 1 THEN '' ELSE E'\n\n' END || page_text;
    ELSE
      extracted_content := extracted_content ||
        CASE WHEN expected_page = 1 THEN '' ELSE E'\n\n' END;
    END IF;
  END LOOP;

  IF char_length(extracted_content) > 120000 THEN
    RAISE EXCEPTION USING ERRCODE = '22023', MESSAGE = 'submission_transcript_too_large';
  END IF;

  next_extraction_state := CASE
    WHEN digital_or_transcribed_pages = latest_transcript.page_count THEN 'complete'
    WHEN digital_or_transcribed_pages = 0 THEN 'none'
    ELSE 'partial'
  END;
  next_verification_state := CASE
    WHEN p_pages = latest_transcript.pages THEN 'teacher_verified'
    ELSE 'teacher_corrected'
  END;
  next_version := latest_transcript.version_number + 1;

  INSERT INTO private.submission_transcript_versions (
    submission_id, source_file_id, version_number, extraction_method,
    extraction_state, verification_state, page_count, pages,
    content_text, created_by, review_note
  )
  VALUES (
    p_submission_id, selected_file.id, next_version, 'teacher_review',
    next_extraction_state, next_verification_state, latest_transcript.page_count,
    p_pages, extracted_content, p_actor_id, btrim(p_review_note)
  )
  RETURNING id INTO new_transcript_id;

  INSERT INTO private.security_audit_events (
    actor_id, action, target_type, target_id, outcome, reason_category
  )
  VALUES (
    p_actor_id, 'submission_transcript_version_appended',
    'submission_transcript_version', new_transcript_id, 'success',
    next_verification_state
  );

  RETURN QUERY SELECT
    new_transcript_id, next_version, selected_file.id, 'teacher_review'::text,
    next_extraction_state, next_verification_state,
    latest_transcript.page_count, p_pages, extracted_content,
    btrim(p_review_note), clock_timestamp();
END;
$function$;

ALTER FUNCTION public.append_submission_transcript_version(uuid,text,uuid,integer,jsonb,text)
  OWNER TO postgres;
REVOKE ALL ON FUNCTION public.append_submission_transcript_version(uuid,text,uuid,integer,jsonb,text)
  FROM PUBLIC, anon, authenticated;
GRANT EXECUTE ON FUNCTION public.append_submission_transcript_version(uuid,text,uuid,integer,jsonb,text)
  TO service_role;

COMMENT ON FUNCTION public.append_submission_transcript_version(uuid,text,uuid,integer,jsonb,text) IS
'Service-role-only transcript review RPC. It requires active Grader assignment or Owner role at AAL2, serializes by submission, checks the expected version, validates page alignment and appends an immutable teacher-review version with a private review note and server-side audit event.';
