-- Phase 1D: private PDF object lifecycle. Raw bytes remain in private Storage;
-- only checksums and lifecycle metadata are stored in PostgreSQL. The trusted
-- Worker is the only Storage client and the only caller of these RPCs.

INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES (
  'private-submissions', 'private-submissions', false, 10485760,
  ARRAY['application/pdf']::text[]
)
ON CONFLICT (id) DO UPDATE
SET name = EXCLUDED.name,
    public = false,
    file_size_limit = EXCLUDED.file_size_limit,
    allowed_mime_types = EXCLUDED.allowed_mime_types;

CREATE TABLE private.submission_files (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  submission_id uuid NOT NULL
    REFERENCES public.assessment_submissions(id) ON DELETE RESTRICT,
  learner_id uuid NOT NULL REFERENCES auth.users(id) ON DELETE RESTRICT,
  version_number integer NOT NULL CHECK (version_number > 0),
  object_path text NOT NULL UNIQUE
    CHECK (object_path ~ '^[0-9a-f-]{36}/[0-9a-f-]{36}\.pdf$'),
  sha256 text,
  byte_size bigint,
  mime_type text,
  page_count integer,
  upload_state text NOT NULL DEFAULT 'pending'
    CHECK (upload_state IN ('pending', 'accepted', 'rejected', 'cleanup_pending', 'abandoned')),
  rejection_category text
    CHECK (rejection_category IS NULL OR rejection_category IN (
      'invalid_extension', 'invalid_mime', 'invalid_signature',
      'malformed_pdf', 'encrypted_pdf', 'page_limit_exceeded',
      'file_too_large', 'storage_error', 'expired_upload'
    )),
  created_at timestamptz NOT NULL DEFAULT clock_timestamp(),
  updated_at timestamptz NOT NULL DEFAULT clock_timestamp(),
  expires_at timestamptz NOT NULL,
  accepted_at timestamptz,
  UNIQUE (submission_id, version_number),
  CHECK (expires_at > created_at),
  CHECK (
    upload_state <> 'accepted'
    OR (
      num_nonnulls(sha256, byte_size, mime_type, page_count, accepted_at) = 5
      AND sha256 ~ '^[a-f0-9]{64}$'
      AND byte_size BETWEEN 1 AND 10485760
      AND mime_type = 'application/pdf'
      AND page_count BETWEEN 1 AND 10
      AND rejection_category IS NULL
    )
  ),
  CHECK (
    upload_state <> 'pending'
    OR (
      sha256 IS NULL AND byte_size IS NULL AND mime_type IS NULL
      AND page_count IS NULL AND accepted_at IS NULL
    )
  )
);

CREATE UNIQUE INDEX submission_files_one_pending_per_submission
  ON private.submission_files (submission_id)
  WHERE upload_state IN ('pending', 'cleanup_pending');
CREATE INDEX submission_files_submission_version_idx
  ON private.submission_files (submission_id, version_number DESC);
CREATE INDEX submission_files_expiry_idx
  ON private.submission_files (expires_at)
  WHERE upload_state IN ('pending', 'cleanup_pending');

ALTER TABLE private.submission_files ENABLE ROW LEVEL SECURITY;
REVOKE ALL ON private.submission_files FROM PUBLIC, anon, authenticated, service_role;

CREATE OR REPLACE FUNCTION private.protect_submission_file_integrity()
RETURNS trigger
LANGUAGE plpgsql
SET search_path = ''
AS $function$
BEGIN
  IF TG_OP = 'DELETE' THEN
    RAISE EXCEPTION USING ERRCODE = '42501', MESSAGE = 'submission_file_delete_requires_retention_workflow';
  END IF;

  IF OLD.upload_state = 'accepted' THEN
    RAISE EXCEPTION USING ERRCODE = '42501', MESSAGE = 'accepted_submission_file_immutable';
  END IF;

  IF ROW(
    NEW.id, NEW.submission_id, NEW.learner_id, NEW.version_number,
    NEW.object_path, NEW.created_at, NEW.expires_at
  ) IS DISTINCT FROM ROW(
    OLD.id, OLD.submission_id, OLD.learner_id, OLD.version_number,
    OLD.object_path, OLD.created_at, OLD.expires_at
  ) THEN
    RAISE EXCEPTION USING ERRCODE = '42501', MESSAGE = 'submission_file_identity_immutable';
  END IF;

  RETURN NEW;
END;
$function$;

CREATE TRIGGER submission_file_integrity_guard
  BEFORE UPDATE OR DELETE ON private.submission_files
  FOR EACH ROW EXECUTE FUNCTION private.protect_submission_file_integrity();

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

CREATE OR REPLACE FUNCTION public.reject_submission_file_upload(
  p_actor_id uuid,
  p_file_id uuid,
  p_reason_category text
)
RETURNS boolean
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $function$
DECLARE
  selected_file private.submission_files%ROWTYPE;
BEGIN
  IF coalesce(auth.jwt() ->> 'role', '') <> 'service_role'
    OR p_actor_id IS NULL
    OR p_reason_category IS NULL
    OR p_reason_category NOT IN (
      'invalid_extension', 'invalid_mime', 'invalid_signature',
      'malformed_pdf', 'encrypted_pdf', 'page_limit_exceeded',
      'file_too_large', 'storage_error', 'expired_upload'
    )
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
    RETURN false;
  END IF;

  SELECT file_record.* INTO selected_file
  FROM private.submission_files AS file_record
  WHERE file_record.id = p_file_id AND file_record.learner_id = p_actor_id
  FOR UPDATE;

  IF NOT FOUND OR selected_file.upload_state <> 'pending' THEN
    RETURN false;
  END IF;

  UPDATE private.submission_files
  SET upload_state = 'rejected',
      rejection_category = p_reason_category,
      updated_at = clock_timestamp()
  WHERE id = p_file_id;

  INSERT INTO private.security_audit_events (
    actor_id, action, target_type, target_id, outcome, reason_category
  )
  VALUES (
    p_actor_id, 'submission_file_upload_rejected', 'submission_file',
    p_file_id, 'denied', p_reason_category
  );
  RETURN true;
END;
$function$;

CREATE OR REPLACE FUNCTION public.mark_submission_file_cleanup_pending(
  p_actor_id uuid,
  p_file_id uuid
)
RETURNS boolean
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $function$
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
    RETURN false;
  END IF;

  UPDATE private.submission_files
  SET upload_state = 'cleanup_pending',
      rejection_category = coalesce(rejection_category, 'storage_error'),
      updated_at = clock_timestamp()
  WHERE id = p_file_id
    AND learner_id = p_actor_id
    AND upload_state = 'pending';

  IF NOT FOUND THEN RETURN false; END IF;

  INSERT INTO private.security_audit_events (
    actor_id, action, target_type, target_id, outcome, reason_category
  )
  VALUES (
    p_actor_id, 'submission_file_cleanup_required', 'submission_file',
    p_file_id, 'failed', 'storage_error'
  );
  RETURN true;
END;
$function$;

CREATE OR REPLACE FUNCTION public.get_authorized_submission_file(
  p_actor_id uuid,
  p_assurance text,
  p_submission_id uuid
)
RETURNS TABLE(
  file_id uuid, submission_id uuid, object_path text,
  version_number integer, sha256 text, byte_size bigint,
  mime_type text, page_count integer, accepted_at timestamptz
)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $function$
DECLARE
  selected_file private.submission_files%ROWTYPE;
  allowed boolean := false;
BEGIN
  IF coalesce(auth.jwt() ->> 'role', '') <> 'service_role'
    OR p_actor_id IS NULL
    OR p_submission_id IS NULL
    OR p_assurance IS NULL
    OR p_assurance NOT IN ('aal1', 'aal2')
    OR NOT EXISTS (
      SELECT 1 FROM public.profiles AS profile
      WHERE profile.user_id = p_actor_id AND profile.account_status = 'active'
    ) THEN
    RETURN;
  END IF;

  SELECT file_record.* INTO selected_file
  FROM private.submission_files AS file_record
  JOIN public.assessment_submissions AS submission
    ON submission.id = file_record.submission_id
  WHERE submission.id = p_submission_id
    AND file_record.upload_state = 'accepted'
  ORDER BY file_record.version_number DESC
  LIMIT 1;

  IF FOUND THEN
    SELECT (
      (
        selected_file.learner_id = p_actor_id
        AND EXISTS (
          SELECT 1 FROM public.role_assignments AS role
          WHERE role.user_id = p_actor_id
            AND role.role = 'student'::public.app_role
            AND role.revoked_at IS NULL
        )
      )
      OR (
        EXISTS (
          SELECT 1 FROM public.role_assignments AS role
          WHERE role.user_id = p_actor_id
            AND role.role = 'guardian'::public.app_role
            AND role.revoked_at IS NULL
        )
        AND EXISTS (
          SELECT 1 FROM public.guardian_learner_links AS link
          WHERE link.guardian_id = p_actor_id
            AND link.learner_id = selected_file.learner_id
            AND link.status = 'verified'
            AND link.consent_verified_at IS NOT NULL
            AND link.can_view_submissions = true
        )
      )
      OR (
        p_assurance = 'aal2'
        AND EXISTS (
          SELECT 1 FROM public.role_assignments AS role
          WHERE role.user_id = p_actor_id
            AND role.role = 'grader'::public.app_role
            AND role.revoked_at IS NULL
        )
        AND EXISTS (
          SELECT 1 FROM public.submission_grader_assignments AS assignment
          WHERE assignment.submission_id = p_submission_id
            AND assignment.grader_user_id = p_actor_id
            AND assignment.revoked_at IS NULL
        )
      )
      OR (
        p_assurance = 'aal2'
        AND EXISTS (
          SELECT 1 FROM public.role_assignments AS role
          WHERE role.user_id = p_actor_id
            AND role.role = 'owner'::public.app_role
            AND role.revoked_at IS NULL
        )
      )
    ) INTO allowed;
  END IF;

  INSERT INTO private.security_audit_events (
    actor_id, action, target_type, target_id, outcome, reason_category
  )
  VALUES (
    p_actor_id,
    CASE WHEN allowed THEN 'submission_file_access_authorized'
         ELSE 'submission_file_access_denied' END,
    'assessment_submission',
    p_submission_id,
    CASE WHEN allowed THEN 'success' ELSE 'denied' END,
    CASE WHEN allowed THEN 'file_access' ELSE 'resource_scope_denied' END
  );

  IF NOT allowed THEN RETURN; END IF;

  RETURN QUERY
    SELECT selected_file.id, selected_file.submission_id, selected_file.object_path,
           selected_file.version_number, selected_file.sha256, selected_file.byte_size,
           selected_file.mime_type, selected_file.page_count, selected_file.accepted_at;
END;
$function$;

CREATE OR REPLACE FUNCTION public.claim_expired_submission_file_uploads(
  p_actor_id uuid,
  p_assurance text,
  p_now timestamptz DEFAULT clock_timestamp()
)
RETURNS TABLE(file_id uuid, object_path text)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $function$
BEGIN
  IF coalesce(auth.jwt() ->> 'role', '') <> 'service_role'
    OR p_actor_id IS NULL
    OR p_assurance IS DISTINCT FROM 'aal2'
    OR NOT EXISTS (
      SELECT 1 FROM public.profiles AS profile
      WHERE profile.user_id = p_actor_id AND profile.account_status = 'active'
    )
    OR NOT EXISTS (
      SELECT 1 FROM public.role_assignments AS role
      WHERE role.user_id = p_actor_id
        AND role.role = 'owner'::public.app_role
        AND role.revoked_at IS NULL
    ) THEN
    RAISE EXCEPTION USING ERRCODE = '42501', MESSAGE = 'submission_file_cleanup_forbidden';
  END IF;

  RETURN QUERY
  WITH candidates AS (
    SELECT file_record.id
    FROM private.submission_files AS file_record
    WHERE file_record.upload_state = 'cleanup_pending'
       OR (file_record.upload_state = 'pending' AND file_record.expires_at <= p_now)
    ORDER BY file_record.expires_at ASC, file_record.id ASC
    FOR UPDATE SKIP LOCKED
    LIMIT 50
  ),
  changed AS (
    UPDATE private.submission_files AS file_record
    SET upload_state = 'cleanup_pending',
        rejection_category = coalesce(file_record.rejection_category, 'expired_upload'),
        updated_at = clock_timestamp()
    FROM candidates
    WHERE file_record.id = candidates.id
    RETURNING file_record.id, file_record.object_path
  ),
  audited AS (
    INSERT INTO private.security_audit_events (
      actor_id, action, target_type, target_id, outcome, reason_category
    )
    SELECT p_actor_id, 'submission_file_cleanup_claimed', 'submission_file',
           changed.id, 'success', 'expired_upload_cleanup'
    FROM changed
    RETURNING target_id
  )
  SELECT changed.id, changed.object_path
  FROM changed
  JOIN audited ON audited.target_id = changed.id;
END;
$function$;

CREATE OR REPLACE FUNCTION public.finish_submission_file_cleanup(
  p_actor_id uuid,
  p_assurance text,
  p_file_id uuid
)
RETURNS boolean
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $function$
DECLARE
  selected_file private.submission_files%ROWTYPE;
BEGIN
  IF coalesce(auth.jwt() ->> 'role', '') <> 'service_role'
    OR p_actor_id IS NULL
    OR p_assurance IS DISTINCT FROM 'aal2'
    OR NOT EXISTS (
      SELECT 1 FROM public.profiles AS profile
      WHERE profile.user_id = p_actor_id AND profile.account_status = 'active'
    )
    OR NOT EXISTS (
      SELECT 1 FROM public.role_assignments AS role
      WHERE role.user_id = p_actor_id
        AND role.role = 'owner'::public.app_role
        AND role.revoked_at IS NULL
    ) THEN
    RETURN false;
  END IF;

  SELECT file_record.* INTO selected_file
  FROM private.submission_files AS file_record
  WHERE file_record.id = p_file_id
    AND file_record.upload_state = 'cleanup_pending'
  FOR UPDATE;

  IF NOT FOUND OR EXISTS (
    SELECT 1 FROM storage.objects AS object_record
    WHERE object_record.bucket_id = 'private-submissions'
      AND object_record.name = selected_file.object_path
  ) THEN
    RETURN false;
  END IF;

  UPDATE private.submission_files
  SET upload_state = 'abandoned',
      updated_at = clock_timestamp()
  WHERE id = p_file_id;

  INSERT INTO private.security_audit_events (
    actor_id, action, target_type, target_id, outcome, reason_category
  )
  VALUES (
    p_actor_id, 'submission_file_upload_abandoned', 'submission_file',
    p_file_id, 'success', 'expired_upload_cleanup'
  );
  RETURN true;
END;
$function$;

-- Extend the existing allowlist for safe Worker-recorded denials/failures.
CREATE OR REPLACE FUNCTION public.record_worker_audit_outcome(
  p_actor_id uuid, p_action text, p_target_id uuid, p_outcome text,
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
    OR NOT EXISTS (SELECT 1 FROM auth.users AS actor WHERE actor.id = p_actor_id) THEN
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
    WHEN 'student_attempt_create' THEN resource_type := 'task_version';
    WHEN 'student_attempt_response_save' THEN resource_type := 'attempt';
    WHEN 'student_attempt_submit' THEN resource_type := 'attempt';
    WHEN 'student_assessment_submission_accept' THEN resource_type := 'task_version';
    WHEN 'student_submission_file_upload' THEN resource_type := 'assessment_submission';
    WHEN 'owner_submission_file_cleanup' THEN resource_type := 'submission_file_collection'; requires_null_target := true;
    WHEN 'staff_invitation_created' THEN resource_type := 'staff_invitation'; requires_null_target := true;
    WHEN 'staff_invitation_revoked' THEN resource_type := 'staff_invitation';
    ELSE RETURN false;
  END CASE;

  IF (requires_null_target AND p_target_id IS NOT NULL)
    OR (NOT requires_null_target AND p_target_id IS NULL) THEN RETURN false; END IF;

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
      ) THEN RETURN false; END IF;
      event_reason := p_failure_category;
    END IF;
  ELSE
    RETURN false;
  END IF;

  INSERT INTO private.security_audit_events(
    actor_id, action, target_type, target_id, outcome, reason_category
  )
  VALUES(p_actor_id,p_action,resource_type,p_target_id,p_outcome,event_reason);
  RETURN true;
END;
$function$;

ALTER FUNCTION public.begin_submission_file_upload(uuid,uuid) OWNER TO postgres;
ALTER FUNCTION public.finalize_submission_file_upload(uuid,uuid,text,bigint,integer,text) OWNER TO postgres;
ALTER FUNCTION public.reject_submission_file_upload(uuid,uuid,text) OWNER TO postgres;
ALTER FUNCTION public.mark_submission_file_cleanup_pending(uuid,uuid) OWNER TO postgres;
ALTER FUNCTION public.get_authorized_submission_file(uuid,text,uuid) OWNER TO postgres;
ALTER FUNCTION public.claim_expired_submission_file_uploads(uuid,text,timestamptz) OWNER TO postgres;
ALTER FUNCTION public.finish_submission_file_cleanup(uuid,text,uuid) OWNER TO postgres;
ALTER FUNCTION public.record_worker_audit_outcome(uuid,text,uuid,text,text) OWNER TO postgres;

REVOKE ALL ON FUNCTION public.begin_submission_file_upload(uuid,uuid) FROM PUBLIC, anon, authenticated;
REVOKE ALL ON FUNCTION public.finalize_submission_file_upload(uuid,uuid,text,bigint,integer,text) FROM PUBLIC, anon, authenticated;
REVOKE ALL ON FUNCTION public.reject_submission_file_upload(uuid,uuid,text) FROM PUBLIC, anon, authenticated;
REVOKE ALL ON FUNCTION public.mark_submission_file_cleanup_pending(uuid,uuid) FROM PUBLIC, anon, authenticated;
REVOKE ALL ON FUNCTION public.get_authorized_submission_file(uuid,text,uuid) FROM PUBLIC, anon, authenticated;
REVOKE ALL ON FUNCTION public.claim_expired_submission_file_uploads(uuid,text,timestamptz) FROM PUBLIC, anon, authenticated;
REVOKE ALL ON FUNCTION public.finish_submission_file_cleanup(uuid,text,uuid) FROM PUBLIC, anon, authenticated;
REVOKE ALL ON FUNCTION public.record_worker_audit_outcome(uuid,text,uuid,text,text) FROM PUBLIC, anon, authenticated;

GRANT EXECUTE ON FUNCTION public.begin_submission_file_upload(uuid,uuid) TO service_role;
GRANT EXECUTE ON FUNCTION public.finalize_submission_file_upload(uuid,uuid,text,bigint,integer,text) TO service_role;
GRANT EXECUTE ON FUNCTION public.reject_submission_file_upload(uuid,uuid,text) TO service_role;
GRANT EXECUTE ON FUNCTION public.mark_submission_file_cleanup_pending(uuid,uuid) TO service_role;
GRANT EXECUTE ON FUNCTION public.get_authorized_submission_file(uuid,text,uuid) TO service_role;
GRANT EXECUTE ON FUNCTION public.claim_expired_submission_file_uploads(uuid,text,timestamptz) TO service_role;
GRANT EXECUTE ON FUNCTION public.finish_submission_file_cleanup(uuid,text,uuid) TO service_role;
GRANT EXECUTE ON FUNCTION public.record_worker_audit_outcome(uuid,text,uuid,text,text) TO service_role;

COMMENT ON TABLE private.submission_files IS
'Metadata-only record for private PDF objects. Only the trusted Worker uses service-role Storage/RPC access after verifying the caller. Browser roles have no direct Storage object policies. Accepted file versions are immutable and replacement uploads create a new version. Temporary uploads expire after 15 minutes.';
COMMENT ON FUNCTION public.get_authorized_submission_file(uuid,text,uuid) IS
'Service-role-only authorization check used by the Worker. Rechecks active account, learner ownership, verified Guardian consent, current assigned Grader role plus AAL2, or Owner plus AAL2 before returning the opaque object path. The Worker issues a 60-second signed URL only after this check.';
