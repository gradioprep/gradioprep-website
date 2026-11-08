-- Phase 2 first increment: make optional PDF response eligibility explicit
-- in task metadata and persist the accepted learner response mode.
-- This is the typed-plus-optional-PDF path only; PDF-only submissions and OCR
-- are not introduced by this migration.

ALTER TABLE public.task_versions
  ADD COLUMN pdf_response_enabled boolean NOT NULL DEFAULT false;

ALTER TABLE public.task_versions
  ADD CONSTRAINT task_versions_pdf_response_threshold_check
  CHECK (NOT pdf_response_enabled OR ideal_words > 20);

ALTER TABLE public.assessment_submissions
  ADD COLUMN response_mode text NOT NULL DEFAULT 'typed'
  CHECK (response_mode IN ('typed', 'typed_pdf'));

CREATE OR REPLACE FUNCTION private.guard_assessment_submission_response_mode()
RETURNS trigger
LANGUAGE plpgsql
SET search_path = ''
AS $function$
BEGIN
  IF NEW.response_mode IS NOT DISTINCT FROM OLD.response_mode THEN
    RETURN NEW;
  END IF;

  IF OLD.response_mode <> 'typed'
    OR NEW.response_mode <> 'typed_pdf'
    OR OLD.status <> 'queued'
    OR NEW.status <> 'queued'
    OR NOT EXISTS (
      SELECT 1
      FROM public.task_versions AS task_version
      WHERE task_version.id = OLD.task_version_id
        AND task_version.pdf_response_enabled = true
        AND task_version.ideal_words > 20
    )
    OR NOT EXISTS (
      SELECT 1
      FROM private.submission_files AS file_record
      WHERE file_record.submission_id = OLD.id
        AND file_record.upload_state = 'accepted'
    ) THEN
    RAISE EXCEPTION USING ERRCODE = '42501',
      MESSAGE = 'assessment_submission_response_mode_change_forbidden';
  END IF;

  RETURN NEW;
END;
$function$;

CREATE TRIGGER assessment_submission_response_mode_guard
  BEFORE UPDATE OF response_mode ON public.assessment_submissions
  FOR EACH ROW
  EXECUTE FUNCTION private.guard_assessment_submission_response_mode();

CREATE OR REPLACE FUNCTION public.begin_submission_file_upload(
  p_actor_id uuid,
  p_submission_id uuid
)
RETURNS TABLE(file_id uuid, object_path text, version_number integer, expires_at timestamptz)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $function$
DECLARE
  selected_submission public.assessment_submissions%ROWTYPE;
  created_file private.submission_files%ROWTYPE;
  next_version integer;
BEGIN
  IF coalesce(auth.jwt() ->> 'role', '') <> 'service_role'
    OR p_actor_id IS NULL OR p_submission_id IS NULL
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

  SELECT submission.* INTO selected_submission
  FROM public.assessment_submissions AS submission
  WHERE submission.id = p_submission_id
    AND submission.learner_id = p_actor_id
  FOR UPDATE;

  IF NOT FOUND THEN
    RAISE EXCEPTION USING ERRCODE = 'P0002', MESSAGE = 'submission_file_submission_not_found';
  END IF;
  IF selected_submission.status <> 'queued' THEN
    RAISE EXCEPTION USING ERRCODE = 'P0001', MESSAGE = 'submission_file_submission_not_uploadable';
  END IF;

  IF NOT EXISTS (
    SELECT 1
    FROM public.task_versions AS task_version
    WHERE task_version.id = selected_submission.task_version_id
      AND task_version.pdf_response_enabled = true
      AND task_version.ideal_words > 20
  ) THEN
    RAISE EXCEPTION USING ERRCODE = 'P0001', MESSAGE = 'submission_file_pdf_not_enabled';
  END IF;
  IF EXISTS (
    SELECT 1 FROM private.submission_files AS file_record
    WHERE file_record.submission_id = p_submission_id
      AND file_record.upload_state IN ('pending', 'cleanup_pending')
  ) THEN
    RAISE EXCEPTION USING ERRCODE = 'P0001', MESSAGE = 'submission_file_upload_in_progress';
  END IF;

  SELECT coalesce(max(file_record.version_number), 0) + 1
    INTO next_version
  FROM private.submission_files AS file_record
  WHERE file_record.submission_id = p_submission_id;

  INSERT INTO private.submission_files (
    submission_id, learner_id, version_number, object_path, upload_state, expires_at
  )
  VALUES (
    p_submission_id,
    p_actor_id,
    next_version,
    gen_random_uuid()::text || '/' || gen_random_uuid()::text || '.pdf',
    'pending',
    clock_timestamp() + interval '15 minutes'
  )
  RETURNING * INTO created_file;

  INSERT INTO private.security_audit_events (
    actor_id, action, target_type, target_id, outcome, reason_category
  )
  VALUES (
    p_actor_id, 'submission_file_upload_started', 'submission_file',
    created_file.id, 'success', 'learner_upload'
  );

  RETURN QUERY
    SELECT created_file.id, created_file.object_path,
           created_file.version_number, created_file.expires_at;
END;
$function$;

CREATE OR REPLACE FUNCTION public.finalize_submission_file_upload(
  p_actor_id uuid,
  p_file_id uuid,
  p_sha256 text,
  p_byte_size bigint,
  p_page_count integer,
  p_mime_type text
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
  WHERE file_record.id = p_file_id AND file_record.learner_id = p_actor_id
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
    OR p_mime_type IS DISTINCT FROM 'application/pdf' THEN
    RAISE EXCEPTION USING ERRCODE = '22023', MESSAGE = 'invalid_submission_file_metadata';
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

  IF NOT FOUND OR selected_submission.status <> 'queued' THEN
    RAISE EXCEPTION USING ERRCODE = '42501', MESSAGE = 'submission_file_upload_forbidden';
  END IF;

  IF NOT EXISTS (
    SELECT 1
    FROM public.task_versions AS task_version
    WHERE task_version.id = selected_submission.task_version_id
      AND task_version.pdf_response_enabled = true
      AND task_version.ideal_words > 20
  ) THEN
    RAISE EXCEPTION USING ERRCODE = 'P0001', MESSAGE = 'submission_file_pdf_not_enabled';
  END IF;

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

  UPDATE public.assessment_submissions
  SET response_mode = 'typed_pdf'
  WHERE id = selected_submission.id
    AND response_mode IN ('typed', 'typed_pdf');
  IF NOT FOUND THEN
    RAISE EXCEPTION USING ERRCODE = '42501', MESSAGE = 'assessment_submission_response_mode_change_forbidden';
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

ALTER FUNCTION public.begin_submission_file_upload(uuid,uuid) OWNER TO postgres;
ALTER FUNCTION public.finalize_submission_file_upload(uuid,uuid,text,bigint,integer,text) OWNER TO postgres;
