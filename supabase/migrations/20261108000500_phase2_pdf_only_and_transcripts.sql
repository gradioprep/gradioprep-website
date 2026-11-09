-- Phase 2: PDF-only acceptance, private queue reservations and digital-text transcripts.
-- The original uploaded PDF remains the authoritative source document. PDF.js
-- extraction is performed locally in the learner's browser; submitted text is
-- treated as unverified evidence, never as OCR or as a replacement for the PDF.

ALTER TABLE public.assessment_submissions
  DROP CONSTRAINT IF EXISTS assessment_submissions_response_mode_check;
ALTER TABLE public.assessment_submissions
  ADD CONSTRAINT assessment_submissions_response_mode_check
  CHECK (response_mode IN ('typed', 'typed_pdf', 'pdf_only'));

CREATE TABLE private.pdf_submission_reservations (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  learner_id uuid NOT NULL REFERENCES auth.users(id) ON DELETE RESTRICT,
  task_version_id uuid NOT NULL REFERENCES public.task_versions(id) ON DELETE RESTRICT,
  rubric_version_id uuid NOT NULL REFERENCES public.rubric_versions(id) ON DELETE RESTRICT,
  response_mode text NOT NULL CHECK (response_mode IN ('typed_pdf', 'pdf_only')),
  response_text text,
  idempotency_key uuid NOT NULL,
  object_path text NOT NULL UNIQUE
    CHECK (object_path ~ '^[0-9a-f-]{36}/[0-9a-f-]{36}\.pdf$'),
  status text NOT NULL DEFAULT 'reserved'
    CHECK (status IN ('reserved', 'accepted', 'released', 'cleanup_pending', 'expired')),
  accepted_submission_id uuid REFERENCES public.assessment_submissions(id) ON DELETE RESTRICT,
  sha256 text CHECK (sha256 IS NULL OR sha256 ~ '^[a-f0-9]{64}$'),
  byte_size bigint CHECK (byte_size IS NULL OR byte_size BETWEEN 1 AND 10485760),
  page_count integer CHECK (page_count IS NULL OR page_count BETWEEN 1 AND 10),
  capacity_config_version integer NOT NULL CHECK (capacity_config_version > 0),
  capacity_limit_snapshot integer NOT NULL CHECK (capacity_limit_snapshot > 0),
  open_submissions_before_reservation integer NOT NULL CHECK (open_submissions_before_reservation >= 0),
  created_at timestamptz NOT NULL DEFAULT clock_timestamp(),
  updated_at timestamptz NOT NULL DEFAULT clock_timestamp(),
  expires_at timestamptz NOT NULL,
  UNIQUE (learner_id, idempotency_key),
  CHECK (expires_at > created_at),
  CHECK (
    (response_mode = 'typed_pdf' AND response_text IS NOT NULL
      AND char_length(btrim(response_text)) BETWEEN 1 AND 12000)
    OR (response_mode = 'pdf_only' AND response_text IS NULL)
  ),
  CHECK (
    status <> 'accepted'
    OR (accepted_submission_id IS NOT NULL AND sha256 IS NOT NULL
      AND byte_size IS NOT NULL AND page_count IS NOT NULL)
  )
);

CREATE INDEX pdf_submission_reservations_capacity_idx
  ON private.pdf_submission_reservations (expires_at, id)
  WHERE status = 'reserved';

ALTER TABLE private.pdf_submission_reservations ENABLE ROW LEVEL SECURITY;
REVOKE ALL ON private.pdf_submission_reservations FROM PUBLIC, anon, authenticated, service_role;

CREATE OR REPLACE FUNCTION private.protect_pdf_submission_reservation()
RETURNS trigger
LANGUAGE plpgsql
SET search_path = ''
AS $function$
BEGIN
  IF TG_OP = 'DELETE' THEN
    RAISE EXCEPTION USING ERRCODE = '42501', MESSAGE = 'pdf_submission_reservation_delete_forbidden';
  END IF;
  IF ROW(
    NEW.id, NEW.learner_id, NEW.task_version_id, NEW.rubric_version_id,
    NEW.response_mode, NEW.response_text, NEW.idempotency_key, NEW.object_path,
    NEW.capacity_config_version, NEW.capacity_limit_snapshot,
    NEW.open_submissions_before_reservation, NEW.created_at, NEW.expires_at
  ) IS DISTINCT FROM ROW(
    OLD.id, OLD.learner_id, OLD.task_version_id, OLD.rubric_version_id,
    OLD.response_mode, OLD.response_text, OLD.idempotency_key, OLD.object_path,
    OLD.capacity_config_version, OLD.capacity_limit_snapshot,
    OLD.open_submissions_before_reservation, OLD.created_at, OLD.expires_at
  ) THEN
    RAISE EXCEPTION USING ERRCODE = '42501', MESSAGE = 'pdf_submission_reservation_identity_immutable';
  END IF;
  IF OLD.status IN ('accepted', 'released', 'expired')
    AND NEW IS DISTINCT FROM OLD THEN
    RAISE EXCEPTION USING ERRCODE = '42501', MESSAGE = 'pdf_submission_reservation_terminal';
  END IF;
  RETURN NEW;
END;
$function$;

CREATE TRIGGER pdf_submission_reservation_integrity_guard
  BEFORE UPDATE OR DELETE ON private.pdf_submission_reservations
  FOR EACH ROW EXECUTE FUNCTION private.protect_pdf_submission_reservation();

CREATE TABLE private.submission_transcript_versions (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  submission_id uuid NOT NULL
    REFERENCES public.assessment_submissions(id) ON DELETE RESTRICT,
  source_file_id uuid NOT NULL
    REFERENCES private.submission_files(id) ON DELETE RESTRICT,
  version_number integer NOT NULL CHECK (version_number > 0),
  extraction_method text NOT NULL DEFAULT 'pdfjs' CHECK (extraction_method = 'pdfjs'),
  extraction_state text NOT NULL CHECK (extraction_state IN ('complete', 'partial', 'none')),
  verification_state text NOT NULL DEFAULT 'unverified'
    CHECK (verification_state IN ('unverified', 'teacher_verified', 'teacher_corrected')),
  page_count integer NOT NULL CHECK (page_count BETWEEN 1 AND 10),
  pages jsonb NOT NULL CHECK (jsonb_typeof(pages) = 'array'),
  content_text text NOT NULL CHECK (char_length(content_text) <= 120000),
  created_by uuid NOT NULL REFERENCES auth.users(id) ON DELETE RESTRICT,
  created_at timestamptz NOT NULL DEFAULT clock_timestamp(),
  UNIQUE (submission_id, version_number),
  UNIQUE (source_file_id, version_number)
);

CREATE INDEX submission_transcript_versions_latest_idx
  ON private.submission_transcript_versions (submission_id, version_number DESC);

ALTER TABLE private.submission_transcript_versions ENABLE ROW LEVEL SECURITY;
REVOKE ALL ON private.submission_transcript_versions FROM PUBLIC, anon, authenticated, service_role;

CREATE OR REPLACE FUNCTION private.prevent_submission_transcript_mutation()
RETURNS trigger
LANGUAGE plpgsql
SET search_path = ''
AS $function$
BEGIN
  RAISE EXCEPTION USING ERRCODE = '42501', MESSAGE = 'submission_transcript_version_immutable';
END;
$function$;

CREATE TRIGGER submission_transcript_versions_immutable
  BEFORE UPDATE OR DELETE ON private.submission_transcript_versions
  FOR EACH ROW EXECUTE FUNCTION private.prevent_submission_transcript_mutation();

-- The existing typed acceptance RPC already serializes on this singleton
-- capacity row. This trigger makes it account for unexpired PDF reservations
-- too, so a typed request cannot consume a slot held by an uploading PDF.
CREATE OR REPLACE FUNCTION private.enforce_submission_capacity_with_pdf_reservations()
RETURNS trigger
LANGUAGE plpgsql
SET search_path = ''
AS $function$
DECLARE
  capacity private.grading_capacity_config%ROWTYPE;
  open_count integer;
  reserved_count integer;
BEGIN
  SELECT config.* INTO capacity
  FROM private.grading_capacity_config AS config
  WHERE config.singleton = true
  FOR UPDATE;

  IF NOT FOUND OR NOT capacity.enabled THEN
    RAISE EXCEPTION USING ERRCODE = 'P0001', MESSAGE = 'submission_capacity_unavailable';
  END IF;

  SELECT count(*)::integer INTO open_count
  FROM public.assessment_submissions AS submission
  WHERE submission.status IN ('queued', 'assigned', 'grading');

  IF NEW.response_mode = 'typed' AND EXISTS (
    SELECT 1
    FROM private.pdf_submission_reservations AS reservation
    WHERE reservation.learner_id = NEW.learner_id
      AND reservation.idempotency_key = NEW.idempotency_key
      AND reservation.status IN ('reserved', 'accepted', 'cleanup_pending')
  ) THEN
    RAISE EXCEPTION USING ERRCODE = 'P0001', MESSAGE = 'submission_idempotency_conflict';
  END IF;

  SELECT count(*)::integer INTO reserved_count
  FROM private.pdf_submission_reservations AS reservation
  WHERE reservation.status = 'reserved'
    AND reservation.expires_at > clock_timestamp()
    AND NOT (
      NEW.response_mode IN ('typed_pdf', 'pdf_only')
      AND reservation.idempotency_key = NEW.idempotency_key
    );

  IF open_count + reserved_count >= capacity.max_open_submissions THEN
    RAISE EXCEPTION USING ERRCODE = 'P0001', MESSAGE = 'submission_capacity_full';
  END IF;
  RETURN NEW;
END;
$function$;

CREATE TRIGGER assessment_submission_capacity_with_pdf_reservations
  BEFORE INSERT ON public.assessment_submissions
  FOR EACH ROW EXECUTE FUNCTION private.enforce_submission_capacity_with_pdf_reservations();

CREATE OR REPLACE FUNCTION public.begin_pdf_assessment_submission(
  p_task_version_id uuid,
  p_idempotency_key uuid,
  p_response_mode text,
  p_response_text text DEFAULT NULL
)
RETURNS TABLE(
  reservation_id uuid,
  object_path text,
  expires_at timestamptz,
  reservation_state text,
  submission_id uuid,
  sha256 text,
  is_replay boolean
)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $function$
DECLARE
  actor_id uuid := auth.uid();
  selected_pathway_id text;
  selected_rubric_version_id uuid;
  capacity private.grading_capacity_config%ROWTYPE;
  existing_reservation private.pdf_submission_reservations%ROWTYPE;
  open_count integer;
  reserved_count integer;
  created_reservation private.pdf_submission_reservations%ROWTYPE;
BEGIN
  IF actor_id IS NULL
    OR NOT private.current_account_is_active()
    OR NOT private.current_user_has_role('student'::public.app_role) THEN
    RAISE EXCEPTION USING ERRCODE = '42501', MESSAGE = 'assessment_submission_forbidden';
  END IF;

  IF p_task_version_id IS NULL OR p_idempotency_key IS NULL
    OR p_response_mode NOT IN ('typed_pdf', 'pdf_only')
    OR (p_response_mode = 'typed_pdf' AND
        (p_response_text IS NULL OR char_length(btrim(p_response_text)) = 0
          OR char_length(p_response_text) > 12000))
    OR (p_response_mode = 'pdf_only' AND p_response_text IS NOT NULL) THEN
    RAISE EXCEPTION USING ERRCODE = '22023', MESSAGE = 'invalid_pdf_assessment_submission';
  END IF;

  SELECT task_version.pathway_id, mapping.rubric_version_id
    INTO selected_pathway_id, selected_rubric_version_id
  FROM public.task_versions AS task_version
  JOIN public.course_enrolments AS enrolment
    ON enrolment.pathway_id = task_version.pathway_id
   AND enrolment.learner_id = actor_id
   AND enrolment.status = 'active'
  JOIN public.task_rubric_mappings AS mapping
    ON mapping.task_version_id = task_version.id
  JOIN public.rubric_versions AS rubric_version
    ON rubric_version.id = mapping.rubric_version_id
   AND rubric_version.release_state = 'published'
  WHERE task_version.id = p_task_version_id
    AND task_version.release_state = 'published'
    AND task_version.response_mode = 'typed'
    AND task_version.pdf_response_enabled = true
    AND task_version.ideal_words > 20;

  IF NOT FOUND OR NOT EXISTS (
    SELECT 1 FROM public.task_version_prompts AS prompt
    WHERE prompt.task_version_id = p_task_version_id
  ) THEN
    RAISE EXCEPTION USING ERRCODE = 'P0002', MESSAGE = 'assessment_task_not_available';
  END IF;

  SELECT reservation.* INTO existing_reservation
  FROM private.pdf_submission_reservations AS reservation
  WHERE reservation.learner_id = actor_id
    AND reservation.idempotency_key = p_idempotency_key;

  IF FOUND THEN
    IF existing_reservation.task_version_id <> p_task_version_id
      OR existing_reservation.response_mode <> p_response_mode
      OR existing_reservation.response_text IS DISTINCT FROM p_response_text THEN
      RAISE EXCEPTION USING ERRCODE = 'P0001', MESSAGE = 'submission_idempotency_conflict';
    END IF;
    IF existing_reservation.status = 'accepted' THEN
      RETURN QUERY SELECT existing_reservation.id, existing_reservation.object_path,
        existing_reservation.expires_at, existing_reservation.status,
        existing_reservation.accepted_submission_id, existing_reservation.sha256, true;
      RETURN;
    END IF;
    IF existing_reservation.status = 'reserved'
      AND existing_reservation.expires_at > clock_timestamp() THEN
      RAISE EXCEPTION USING ERRCODE = 'P0001', MESSAGE = 'pdf_submission_in_progress';
    END IF;
    RAISE EXCEPTION USING ERRCODE = 'P0001', MESSAGE = 'submission_idempotency_conflict';
  END IF;

  IF EXISTS (
    SELECT 1 FROM public.assessment_submissions AS submission
    WHERE submission.learner_id = actor_id
      AND submission.idempotency_key = p_idempotency_key
  ) THEN
    RAISE EXCEPTION USING ERRCODE = 'P0001', MESSAGE = 'submission_idempotency_conflict';
  END IF;

  SELECT config.* INTO capacity
  FROM private.grading_capacity_config AS config
  WHERE config.singleton = true
  FOR UPDATE;

  IF NOT FOUND OR NOT capacity.enabled THEN
    RAISE EXCEPTION USING ERRCODE = 'P0001', MESSAGE = 'submission_capacity_unavailable';
  END IF;

  -- Recheck the idempotency key after taking the same serialization lock used
  -- by typed acceptance and other PDF reservations.
  SELECT reservation.* INTO existing_reservation
  FROM private.pdf_submission_reservations AS reservation
  WHERE reservation.learner_id = actor_id
    AND reservation.idempotency_key = p_idempotency_key
  FOR UPDATE;

  IF FOUND THEN
    IF existing_reservation.task_version_id <> p_task_version_id
      OR existing_reservation.response_mode <> p_response_mode
      OR existing_reservation.response_text IS DISTINCT FROM p_response_text THEN
      RAISE EXCEPTION USING ERRCODE = 'P0001', MESSAGE = 'submission_idempotency_conflict';
    END IF;
    IF existing_reservation.status = 'accepted' THEN
      RETURN QUERY SELECT existing_reservation.id, existing_reservation.object_path,
        existing_reservation.expires_at, existing_reservation.status,
        existing_reservation.accepted_submission_id, existing_reservation.sha256, true;
      RETURN;
    END IF;
    RAISE EXCEPTION USING ERRCODE = 'P0001', MESSAGE = 'pdf_submission_in_progress';
  END IF;

  SELECT count(*)::integer INTO open_count
  FROM public.assessment_submissions AS submission
  WHERE submission.status IN ('queued', 'assigned', 'grading');

  SELECT count(*)::integer INTO reserved_count
  FROM private.pdf_submission_reservations AS reservation
  WHERE reservation.status = 'reserved'
    AND reservation.expires_at > clock_timestamp();

  IF open_count + reserved_count >= capacity.max_open_submissions THEN
    RAISE EXCEPTION USING ERRCODE = 'P0001', MESSAGE = 'submission_capacity_full';
  END IF;

  INSERT INTO private.pdf_submission_reservations (
    learner_id, task_version_id, rubric_version_id, response_mode,
    response_text, idempotency_key, object_path, status,
    capacity_config_version, capacity_limit_snapshot,
    open_submissions_before_reservation, expires_at
  )
  VALUES (
    actor_id, p_task_version_id, selected_rubric_version_id, p_response_mode,
    p_response_text, p_idempotency_key,
    gen_random_uuid()::text || '/' || gen_random_uuid()::text || '.pdf',
    'reserved', capacity.config_version, capacity.max_open_submissions,
    open_count, clock_timestamp() + interval '15 minutes'
  )
  RETURNING * INTO created_reservation;

  INSERT INTO private.security_audit_events (
    actor_id, action, target_type, target_id, outcome, reason_category
  )
  VALUES (
    actor_id, 'pdf_assessment_reservation_started', 'pdf_submission_reservation',
    created_reservation.id, 'success', 'learner_action'
  );

  RETURN QUERY SELECT created_reservation.id, created_reservation.object_path,
    created_reservation.expires_at, created_reservation.status, NULL::uuid, NULL::text, false;
END;
$function$;

CREATE OR REPLACE FUNCTION public.mark_pdf_submission_reservation_cleanup_pending(
  p_actor_id uuid,
  p_reservation_id uuid
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

  UPDATE private.pdf_submission_reservations
  SET status = 'cleanup_pending', updated_at = clock_timestamp()
  WHERE id = p_reservation_id
    AND learner_id = p_actor_id
    AND status = 'reserved';

  IF NOT FOUND THEN RETURN false; END IF;
  INSERT INTO private.security_audit_events (
    actor_id, action, target_type, target_id, outcome, reason_category
  )
  VALUES (
    p_actor_id, 'pdf_assessment_reservation_cleanup_required',
    'pdf_submission_reservation', p_reservation_id, 'failed', 'storage_error'
  );
  RETURN true;
END;
$function$;

CREATE OR REPLACE FUNCTION public.release_pdf_submission_reservation(
  p_actor_id uuid,
  p_reservation_id uuid
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

  UPDATE private.pdf_submission_reservations
  SET status = 'released', updated_at = clock_timestamp()
  WHERE id = p_reservation_id
    AND learner_id = p_actor_id
    AND status = 'reserved';

  IF NOT FOUND THEN RETURN false; END IF;
  INSERT INTO private.security_audit_events (
    actor_id, action, target_type, target_id, outcome, reason_category
  )
  VALUES (
    p_actor_id, 'pdf_assessment_reservation_released',
    'pdf_submission_reservation', p_reservation_id, 'success', 'learner_action'
  );
  RETURN true;
END;
$function$;

CREATE OR REPLACE FUNCTION public.finalize_pdf_assessment_submission(
  p_actor_id uuid,
  p_reservation_id uuid,
  p_sha256 text,
  p_byte_size bigint,
  p_page_count integer,
  p_mime_type text,
  p_transcript_pages jsonb
)
RETURNS TABLE(
  submission_id uuid,
  learner_id uuid,
  task_version_id uuid,
  response_mode text,
  status text,
  accepted_at timestamptz,
  grading_due_at timestamptz,
  sla_target_seconds integer,
  file_id uuid,
  transcript_version_id uuid,
  is_replay boolean
)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $function$
DECLARE
  selected_reservation private.pdf_submission_reservations%ROWTYPE;
  capacity private.grading_capacity_config%ROWTYPE;
  created_submission public.assessment_submissions%ROWTYPE;
  created_file private.submission_files%ROWTYPE;
  accepted_time timestamptz;
  open_count integer;
  other_reserved_count integer;
  digital_page_count integer;
  extracted_text text;
  transcript_state text;
  page_entry jsonb;
  created_transcript_id uuid;
  expected_number integer;
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
    RAISE EXCEPTION USING ERRCODE = '42501', MESSAGE = 'assessment_submission_forbidden';
  END IF;

  IF p_sha256 IS NULL OR p_sha256 !~ '^[a-f0-9]{64}$'
    OR p_byte_size IS NULL OR p_byte_size NOT BETWEEN 1 AND 10485760
    OR p_page_count IS NULL OR p_page_count NOT BETWEEN 1 AND 10
    OR p_mime_type IS DISTINCT FROM 'application/pdf'
    OR jsonb_typeof(p_transcript_pages) IS DISTINCT FROM 'array'
    OR jsonb_array_length(p_transcript_pages) <> p_page_count THEN
    RAISE EXCEPTION USING ERRCODE = '22023', MESSAGE = 'invalid_pdf_assessment_metadata';
  END IF;

  -- Validate that every supplied transcript entry corresponds to exactly one
  -- physical PDF page. Empty/no-text pages are explicitly marked, never guessed.
  expected_number := 0;
  digital_page_count := 0;
  extracted_text := '';
  FOR page_entry IN
    SELECT value FROM jsonb_array_elements(p_transcript_pages) WITH ORDINALITY AS item(value, ordinal)
    ORDER BY ordinal
  LOOP
    expected_number := expected_number + 1;
    IF jsonb_typeof(page_entry) IS DISTINCT FROM 'object'
      OR (SELECT count(*) FROM jsonb_object_keys(page_entry)) <> 3
      OR NOT (page_entry ?& ARRAY['page_number', 'text', 'status']) THEN
      RAISE EXCEPTION USING ERRCODE = '22023', MESSAGE = 'invalid_pdf_transcript_page';
    END IF;
    page_text := page_entry ->> 'text';
    page_status := page_entry ->> 'status';
    IF (page_entry ->> 'page_number')::integer IS DISTINCT FROM expected_number
      OR page_text IS NULL OR char_length(page_text) > 12000
      OR page_status IS NULL
      OR page_status NOT IN ('digital_text', 'no_text_layer')
      OR (page_status = 'no_text_layer' AND page_text <> '')
      OR (page_status = 'digital_text' AND char_length(btrim(page_text)) = 0) THEN
      RAISE EXCEPTION USING ERRCODE = '22023', MESSAGE = 'invalid_pdf_transcript_page';
    END IF;
    IF page_status = 'digital_text' THEN digital_page_count := digital_page_count + 1; END IF;
    extracted_text := extracted_text ||
      CASE WHEN expected_number = 1 THEN '' ELSE E'\n\n' END ||
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

  -- Match the lock order used at reservation time: capacity singleton, then
  -- reservation. This keeps competing accept/reserve/finalise calls serialised.
  SELECT config.* INTO capacity
  FROM private.grading_capacity_config AS config
  WHERE config.singleton = true
  FOR UPDATE;
  IF NOT FOUND OR NOT capacity.enabled THEN
    RAISE EXCEPTION USING ERRCODE = 'P0001', MESSAGE = 'submission_capacity_unavailable';
  END IF;

  SELECT reservation.* INTO selected_reservation
  FROM private.pdf_submission_reservations AS reservation
  WHERE reservation.id = p_reservation_id
    AND reservation.learner_id = p_actor_id
  FOR UPDATE;
  IF NOT FOUND THEN
    RAISE EXCEPTION USING ERRCODE = 'P0002', MESSAGE = 'pdf_submission_reservation_not_found';
  END IF;

  IF selected_reservation.status = 'accepted' THEN
    IF selected_reservation.sha256 IS DISTINCT FROM p_sha256
      OR selected_reservation.byte_size IS DISTINCT FROM p_byte_size
      OR selected_reservation.page_count IS DISTINCT FROM p_page_count
      OR NOT EXISTS (
        SELECT 1 FROM private.submission_transcript_versions AS transcript
        WHERE transcript.submission_id = selected_reservation.accepted_submission_id
          AND transcript.pages = p_transcript_pages
      ) THEN
      RAISE EXCEPTION USING ERRCODE = 'P0001', MESSAGE = 'submission_idempotency_conflict';
    END IF;
    RETURN QUERY
      SELECT submission.id, submission.learner_id, submission.task_version_id,
        submission.response_mode, submission.status, submission.accepted_at,
        submission.grading_due_at, submission.sla_target_seconds,
        file_record.id, transcript.id, true
      FROM public.assessment_submissions AS submission
      JOIN private.submission_files AS file_record
        ON file_record.submission_id = submission.id AND file_record.upload_state = 'accepted'
      JOIN private.submission_transcript_versions AS transcript
        ON transcript.submission_id = submission.id
      WHERE submission.id = selected_reservation.accepted_submission_id
      ORDER BY file_record.version_number DESC, transcript.version_number DESC
      LIMIT 1;
    RETURN;
  END IF;

  IF selected_reservation.status <> 'reserved'
    OR selected_reservation.expires_at <= clock_timestamp() THEN
    RAISE EXCEPTION USING ERRCODE = 'P0001', MESSAGE = 'pdf_submission_reservation_expired';
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM storage.objects AS object_record
    WHERE object_record.bucket_id = 'private-submissions'
      AND object_record.name = selected_reservation.object_path
  ) THEN
    RAISE EXCEPTION USING ERRCODE = 'P0002', MESSAGE = 'submission_file_object_missing';
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM public.task_versions AS task_version
    JOIN public.course_enrolments AS enrolment
      ON enrolment.pathway_id = task_version.pathway_id
     AND enrolment.learner_id = p_actor_id
     AND enrolment.status = 'active'
    JOIN public.task_rubric_mappings AS mapping
      ON mapping.task_version_id = task_version.id
    JOIN public.rubric_versions AS rubric_version
      ON rubric_version.id = mapping.rubric_version_id
     AND rubric_version.id = selected_reservation.rubric_version_id
     AND rubric_version.release_state = 'published'
    WHERE task_version.id = selected_reservation.task_version_id
      AND task_version.release_state = 'published'
      AND task_version.response_mode = 'typed'
      AND task_version.pdf_response_enabled = true
      AND task_version.ideal_words > 20
  ) THEN
    RAISE EXCEPTION USING ERRCODE = 'P0002', MESSAGE = 'assessment_task_not_available';
  END IF;

  SELECT count(*)::integer INTO open_count
  FROM public.assessment_submissions AS submission
  WHERE submission.status IN ('queued', 'assigned', 'grading');

  SELECT count(*)::integer INTO other_reserved_count
  FROM private.pdf_submission_reservations AS reservation
  WHERE reservation.status = 'reserved'
    AND reservation.expires_at > clock_timestamp()
    AND reservation.id <> selected_reservation.id;

  IF open_count + other_reserved_count >= capacity.max_open_submissions THEN
    RAISE EXCEPTION USING ERRCODE = 'P0001', MESSAGE = 'submission_capacity_full';
  END IF;

  accepted_time := clock_timestamp();

  -- The INSERT trigger excludes this reservation by idempotency key, while
  -- retaining its capacity hold for all competing transactions. The state is
  -- changed to accepted only once all linked rows are ready in this transaction.
  INSERT INTO public.assessment_submissions (
    learner_id, task_version_id, rubric_version_id, status,
    accepted_at, grading_due_at, sla_target_seconds,
    capacity_config_version, capacity_limit_snapshot,
    open_submissions_before_acceptance, idempotency_key, response_mode
  )
  VALUES (
    p_actor_id, selected_reservation.task_version_id,
    selected_reservation.rubric_version_id, 'queued',
    accepted_time, accepted_time + interval '24 hours', 86400,
    capacity.config_version, capacity.max_open_submissions,
    open_count, selected_reservation.idempotency_key,
    selected_reservation.response_mode
  )
  RETURNING * INTO created_submission;

  INSERT INTO private.submission_files (
    submission_id, learner_id, version_number, object_path,
    sha256, byte_size, mime_type, page_count, upload_state,
    created_at, updated_at, expires_at, accepted_at
  )
  VALUES (
    created_submission.id, p_actor_id, 1, selected_reservation.object_path,
    p_sha256, p_byte_size, p_mime_type, p_page_count, 'accepted',
    accepted_time, accepted_time, accepted_time + interval '100 years', accepted_time
  )
  RETURNING * INTO created_file;

  IF selected_reservation.response_mode = 'typed_pdf' THEN
    INSERT INTO public.submission_versions (
      submission_id, version_number, response_text, created_by
    )
    VALUES (
      created_submission.id, 1, selected_reservation.response_text, p_actor_id
    );
  END IF;

  INSERT INTO private.submission_transcript_versions (
    submission_id, source_file_id, version_number, extraction_method,
    extraction_state, verification_state, page_count, pages, content_text, created_by, created_at
  )
  VALUES (
    created_submission.id, created_file.id, 1, 'pdfjs',
    transcript_state, 'unverified', p_page_count, p_transcript_pages,
    extracted_text, p_actor_id, accepted_time
  )
  RETURNING id INTO created_transcript_id;

  UPDATE private.pdf_submission_reservations
  SET status = 'accepted',
      accepted_submission_id = created_submission.id,
      sha256 = p_sha256,
      byte_size = p_byte_size,
      page_count = p_page_count,
      updated_at = accepted_time
  WHERE id = selected_reservation.id;

  INSERT INTO private.security_audit_events (
    actor_id, action, target_type, target_id, outcome, reason_category
  )
  VALUES (
    p_actor_id, 'assessment_submission_accepted', 'assessment_submission',
    created_submission.id, 'success', 'learner_action'
  );

  RETURN QUERY SELECT
    created_submission.id, created_submission.learner_id,
    created_submission.task_version_id, created_submission.response_mode,
    created_submission.status, created_submission.accepted_at,
    created_submission.grading_due_at, created_submission.sla_target_seconds,
    created_file.id,
    (SELECT transcript.id FROM private.submission_transcript_versions AS transcript
      WHERE transcript.submission_id = created_submission.id
      AND transcript.version_number = 1),
    false;
END;
$function$;

-- The transcript is available only where the existing private-file permission
-- RPC grants access (learner, consented guardian, active assigned Grader+AAL2,
-- or Owner+AAL2). The original PDF remains the source of truth.
CREATE OR REPLACE FUNCTION public.get_authorized_submission_transcript(
  p_actor_id uuid,
  p_assurance text,
  p_submission_id uuid
)
RETURNS TABLE(
  transcript_version integer,
  extraction_method text,
  extraction_state text,
  verification_state text,
  page_count integer,
  pages jsonb,
  content_text text,
  created_at timestamptz
)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $function$
BEGIN
  IF coalesce(auth.jwt() ->> 'role', '') <> 'service_role' THEN RETURN; END IF;
  IF NOT EXISTS (
    SELECT 1 FROM public.get_authorized_submission_file(
      p_actor_id, p_assurance, p_submission_id
    )
  ) THEN
    RETURN;
  END IF;
  RETURN QUERY
  SELECT transcript.version_number, transcript.extraction_method,
    transcript.extraction_state, transcript.verification_state,
    transcript.page_count, transcript.pages, transcript.content_text,
    transcript.created_at
  FROM private.submission_transcript_versions AS transcript
  WHERE transcript.submission_id = p_submission_id
  ORDER BY transcript.version_number DESC
  LIMIT 1;
END;
$function$;

CREATE OR REPLACE FUNCTION public.claim_expired_pdf_submission_reservations(
  p_actor_id uuid,
  p_assurance text,
  p_now timestamptz DEFAULT clock_timestamp()
)
RETURNS TABLE(reservation_id uuid, object_path text)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $function$
BEGIN
  IF coalesce(auth.jwt() ->> 'role', '') <> 'service_role'
    OR p_actor_id IS NULL OR p_assurance IS DISTINCT FROM 'aal2'
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
    SELECT reservation.id
    FROM private.pdf_submission_reservations AS reservation
    WHERE reservation.status = 'cleanup_pending'
       OR (reservation.status = 'reserved' AND reservation.expires_at <= p_now)
    ORDER BY reservation.expires_at ASC, reservation.id ASC
    FOR UPDATE SKIP LOCKED
    LIMIT 50
  ),
  changed AS (
    UPDATE private.pdf_submission_reservations AS reservation
    SET status = 'cleanup_pending', updated_at = clock_timestamp()
    FROM candidates
    WHERE reservation.id = candidates.id
    RETURNING reservation.id, reservation.object_path
  )
  SELECT changed.id, changed.object_path FROM changed;
END;
$function$;

CREATE OR REPLACE FUNCTION public.finish_expired_pdf_submission_reservation_cleanup(
  p_actor_id uuid,
  p_assurance text,
  p_reservation_id uuid
)
RETURNS boolean
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $function$
BEGIN
  IF coalesce(auth.jwt() ->> 'role', '') <> 'service_role'
    OR p_actor_id IS NULL OR p_assurance IS DISTINCT FROM 'aal2'
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

  UPDATE private.pdf_submission_reservations AS reservation
  SET status = 'expired', updated_at = clock_timestamp()
  WHERE reservation.id = p_reservation_id
    AND reservation.status = 'cleanup_pending'
    AND NOT EXISTS (
      SELECT 1 FROM storage.objects AS object_record
      WHERE object_record.bucket_id = 'private-submissions'
        AND object_record.name = reservation.object_path
    );
  RETURN FOUND;
END;
$function$;

ALTER FUNCTION public.begin_pdf_assessment_submission(uuid,uuid,text,text) OWNER TO postgres;
ALTER FUNCTION public.mark_pdf_submission_reservation_cleanup_pending(uuid,uuid) OWNER TO postgres;
ALTER FUNCTION public.release_pdf_submission_reservation(uuid,uuid) OWNER TO postgres;
ALTER FUNCTION public.finalize_pdf_assessment_submission(uuid,uuid,text,bigint,integer,text,jsonb) OWNER TO postgres;
ALTER FUNCTION public.get_authorized_submission_transcript(uuid,text,uuid) OWNER TO postgres;
ALTER FUNCTION public.claim_expired_pdf_submission_reservations(uuid,text,timestamptz) OWNER TO postgres;
ALTER FUNCTION public.finish_expired_pdf_submission_reservation_cleanup(uuid,text,uuid) OWNER TO postgres;

REVOKE ALL ON FUNCTION public.begin_pdf_assessment_submission(uuid,uuid,text,text)
  FROM PUBLIC, anon, service_role;
GRANT EXECUTE ON FUNCTION public.begin_pdf_assessment_submission(uuid,uuid,text,text)
  TO authenticated;
REVOKE ALL ON FUNCTION public.mark_pdf_submission_reservation_cleanup_pending(uuid,uuid)
  FROM PUBLIC, anon, authenticated;
GRANT EXECUTE ON FUNCTION public.mark_pdf_submission_reservation_cleanup_pending(uuid,uuid)
  TO service_role;
REVOKE ALL ON FUNCTION public.release_pdf_submission_reservation(uuid,uuid)
  FROM PUBLIC, anon, authenticated;
GRANT EXECUTE ON FUNCTION public.release_pdf_submission_reservation(uuid,uuid)
  TO service_role;
REVOKE ALL ON FUNCTION public.finalize_pdf_assessment_submission(uuid,uuid,text,bigint,integer,text,jsonb)
  FROM PUBLIC, anon, authenticated;
GRANT EXECUTE ON FUNCTION public.finalize_pdf_assessment_submission(uuid,uuid,text,bigint,integer,text,jsonb)
  TO service_role;
REVOKE ALL ON FUNCTION public.get_authorized_submission_transcript(uuid,text,uuid)
  FROM PUBLIC, anon, authenticated;
GRANT EXECUTE ON FUNCTION public.get_authorized_submission_transcript(uuid,text,uuid)
  TO service_role;
REVOKE ALL ON FUNCTION public.claim_expired_pdf_submission_reservations(uuid,text,timestamptz)
  FROM PUBLIC, anon, authenticated;
GRANT EXECUTE ON FUNCTION public.claim_expired_pdf_submission_reservations(uuid,text,timestamptz)
  TO service_role;
REVOKE ALL ON FUNCTION public.finish_expired_pdf_submission_reservation_cleanup(uuid,text,uuid)
  FROM PUBLIC, anon, authenticated;
GRANT EXECUTE ON FUNCTION public.finish_expired_pdf_submission_reservation_cleanup(uuid,text,uuid)
  TO service_role;

-- Preserve the legacy typed-then-attach route, but prevent a second file
-- or any attachment after a PDF-only/PDF-first acceptance.
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
  IF selected_submission.status <> 'queued'
    OR selected_submission.response_mode <> 'typed' THEN
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
      AND file_record.upload_state IN ('pending', 'cleanup_pending', 'accepted')
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

  IF NOT FOUND OR selected_submission.status <> 'queued'
    OR selected_submission.response_mode <> 'typed' THEN
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

  UPDATE public.assessment_submissions
  SET response_mode = 'typed_pdf'
  WHERE id = selected_submission.id
    AND response_mode = 'typed';
  IF NOT FOUND THEN
    RAISE EXCEPTION USING ERRCODE = '42501',
      MESSAGE = 'assessment_submission_response_mode_change_forbidden';
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
