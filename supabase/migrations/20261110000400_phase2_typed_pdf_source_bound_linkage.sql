-- Phase 2: typed-plus-PDF submissions remain linkable when earlier rejected
-- upload attempts consumed file-version numbers. The accepted file is paired
-- to its immutable transcript by source_file_id, not by assuming either record
-- must be version 1. Rejected upload history remains immutable and auditable.

CREATE OR REPLACE FUNCTION public.link_timed_attempt_assessment_submission(
  p_attempt_id uuid,
  p_assessment_submission_id uuid,
  p_idempotency_key uuid
)
RETURNS TABLE (
  link_id uuid,
  attempt_id uuid,
  assessment_submission_id uuid,
  learner_id uuid,
  task_version_id uuid,
  linked_at timestamptz,
  is_replay boolean
)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $function$
DECLARE
  v_actor_id uuid := auth.uid();
  selected_attempt public.attempts%ROWTYPE;
  selected_submission public.assessment_submissions%ROWTYPE;
  existing_link private.timed_attempt_assessment_links%ROWTYPE;
  created_link private.timed_attempt_assessment_links%ROWTYPE;
BEGIN
  IF v_actor_id IS NULL
    OR NOT private.current_account_is_active()
    OR NOT private.current_user_has_role('student'::public.app_role) THEN
    RAISE EXCEPTION USING ERRCODE = '42501', MESSAGE = 'timed_attempt_assessment_link_forbidden';
  END IF;

  IF p_attempt_id IS NULL
    OR p_assessment_submission_id IS NULL
    OR p_idempotency_key IS NULL THEN
    RAISE EXCEPTION USING ERRCODE = '22023', MESSAGE = 'invalid_timed_attempt_assessment_link';
  END IF;

  -- Serialize reuse of an idempotency key even when requests target different rows.
  PERFORM pg_catalog.pg_advisory_xact_lock(
    pg_catalog.hashtextextended(v_actor_id::text || ':' || p_idempotency_key::text, 0)
  );

  -- Parent-row locks and unique constraints make competing link requests safe.
  SELECT attempt.*
    INTO selected_attempt
  FROM public.attempts AS attempt
  WHERE attempt.id = p_attempt_id
    AND attempt.learner_id = v_actor_id
  FOR UPDATE;

  IF NOT FOUND THEN
    RAISE EXCEPTION USING ERRCODE = 'P0002', MESSAGE = 'attempt_not_found';
  END IF;

  SELECT submission.*
    INTO selected_submission
  FROM public.assessment_submissions AS submission
  WHERE submission.id = p_assessment_submission_id
    AND submission.learner_id = v_actor_id
  FOR UPDATE;

  IF NOT FOUND THEN
    RAISE EXCEPTION USING ERRCODE = 'P0002', MESSAGE = 'assessment_submission_not_found';
  END IF;

  IF selected_attempt.task_version_id IS DISTINCT FROM selected_submission.task_version_id THEN
    RAISE EXCEPTION USING ERRCODE = 'P0001', MESSAGE = 'attempt_task_version_mismatch';
  END IF;

  -- An identical learner/pair/key retry returns the original row. A key cannot
  -- be repurposed for a different pair.
  SELECT link.*
    INTO existing_link
  FROM private.timed_attempt_assessment_links AS link
  WHERE link.learner_id = v_actor_id
    AND link.idempotency_key = p_idempotency_key
  FOR UPDATE;

  IF FOUND THEN
    IF existing_link.attempt_id = p_attempt_id
      AND existing_link.assessment_submission_id = p_assessment_submission_id THEN
      RETURN QUERY SELECT existing_link.id, existing_link.attempt_id,
        existing_link.assessment_submission_id, existing_link.learner_id,
        existing_link.task_version_id, existing_link.linked_at, true;
      RETURN;
    END IF;
    RAISE EXCEPTION USING ERRCODE = 'P0001',
      MESSAGE = 'timed_attempt_assessment_link_idempotency_conflict';
  END IF;

  IF EXISTS (
    SELECT 1
    FROM private.timed_attempt_assessment_links AS link
    WHERE link.attempt_id = p_attempt_id
       OR link.assessment_submission_id = p_assessment_submission_id
  ) THEN
    RAISE EXCEPTION USING ERRCODE = 'P0001',
      MESSAGE = 'timed_attempt_assessment_link_conflict';
  END IF;

  IF selected_attempt.status <> 'submitted' OR selected_attempt.submitted_at IS NULL THEN
    RAISE EXCEPTION USING ERRCODE = 'P0001', MESSAGE = 'attempt_not_submitted';
  END IF;

  IF selected_submission.status NOT IN ('queued', 'assigned', 'grading')
    OR selected_submission.response_mode NOT IN ('typed', 'typed_pdf', 'pdf_only') THEN
    RAISE EXCEPTION USING ERRCODE = 'P0001', MESSAGE = 'assessment_submission_not_linkable';
  END IF;

  -- Recheck active enrolment, published task, exact mapped published rubric,
  -- response mode and submission eligibility inside the same transaction.
  IF NOT EXISTS (
    SELECT 1
    FROM public.task_versions AS task_version
    JOIN public.course_enrolments AS enrolment
      ON enrolment.pathway_id = task_version.pathway_id
     AND enrolment.learner_id = v_actor_id
     AND enrolment.status = 'active'
    JOIN public.task_rubric_mappings AS mapping
      ON mapping.task_version_id = task_version.id
     AND mapping.rubric_version_id = selected_submission.rubric_version_id
    JOIN public.rubric_versions AS rubric_version
      ON rubric_version.id = mapping.rubric_version_id
     AND rubric_version.release_state = 'published'
    WHERE task_version.id = selected_attempt.task_version_id
      AND task_version.release_state = 'published'
      AND task_version.response_mode = 'typed'
      AND (
        selected_submission.response_mode = 'typed'
        OR (task_version.pdf_response_enabled AND task_version.ideal_words > 20)
      )
  ) THEN
    RAISE EXCEPTION USING ERRCODE = 'P0001', MESSAGE = 'assessment_submission_not_linkable';
  END IF;

  -- Require the appropriate immutable evidence for the accepted response mode.
  -- Typed submissions retain response version 1. PDF-backed submissions require
  -- an accepted private original and its immutable page-aligned transcript v1;
  -- PDF-only submissions deliberately have no public submission_versions row.
  -- The timed attempt independently requires a non-empty response and a
  -- database-recorded submitted event by the learner.
  IF NOT (
    (
      selected_submission.response_mode = 'typed'
      AND EXISTS (
        SELECT 1
        FROM public.submission_versions AS version
        WHERE version.submission_id = selected_submission.id
          AND version.version_number = 1
          AND btrim(version.response_text) <> ''
      )
    )
    OR
    (
      selected_submission.response_mode = 'typed_pdf'
      AND EXISTS (
        SELECT 1
        FROM public.submission_versions AS version
        WHERE version.submission_id = selected_submission.id
          AND version.version_number = 1
          AND btrim(version.response_text) <> ''
      )
      AND EXISTS (
        SELECT 1
        FROM private.submission_files AS file_record
        JOIN private.submission_transcript_versions AS transcript
          ON transcript.submission_id = file_record.submission_id
         AND transcript.source_file_id = file_record.id
        WHERE file_record.submission_id = selected_submission.id
          AND file_record.learner_id = v_actor_id
          AND file_record.upload_state = 'accepted'
          AND file_record.accepted_at IS NOT NULL
      )
    )
    OR
    (
      selected_submission.response_mode = 'pdf_only'
      AND EXISTS (
        SELECT 1
        FROM private.submission_files AS file_record
        JOIN private.submission_transcript_versions AS transcript
          ON transcript.submission_id = file_record.submission_id
         AND transcript.source_file_id = file_record.id
         AND transcript.version_number = 1
        WHERE file_record.submission_id = selected_submission.id
          AND file_record.learner_id = v_actor_id
          AND file_record.version_number = 1
          AND file_record.upload_state = 'accepted'
          AND file_record.accepted_at IS NOT NULL
      )
    )
  ) OR NOT EXISTS (
    SELECT 1
    FROM public.attempt_responses AS response
    WHERE response.attempt_id = selected_attempt.id
      AND btrim(response.response_text) <> ''
  ) OR NOT EXISTS (
    SELECT 1
    FROM private.attempt_timer_sessions AS timer_session
    JOIN private.attempt_timer_events AS timer_event
      ON timer_event.attempt_id = timer_session.attempt_id
     AND timer_event.event_type = 'submitted'
    WHERE timer_session.attempt_id = selected_attempt.id
      AND timer_session.learner_id = v_actor_id
      AND timer_session.task_version_id = selected_attempt.task_version_id
      AND timer_event.actor_id = v_actor_id
  ) THEN
    RAISE EXCEPTION USING ERRCODE = 'P0001', MESSAGE = 'attempt_not_linkable';
  END IF;

  INSERT INTO private.timed_attempt_assessment_links (
    attempt_id, assessment_submission_id, learner_id, task_version_id, idempotency_key
  )
  VALUES (
    selected_attempt.id, selected_submission.id, v_actor_id,
    selected_attempt.task_version_id, p_idempotency_key
  )
  RETURNING * INTO created_link;

  INSERT INTO private.security_audit_events (
    actor_id, action, target_type, target_id, outcome, reason_category
  )
  VALUES (
    v_actor_id, 'student_timed_attempt_assessment_linked',
    'timed_attempt_assessment_link', created_link.id, 'success', 'learner_action'
  );

  RETURN QUERY SELECT created_link.id, created_link.attempt_id,
    created_link.assessment_submission_id, created_link.learner_id,
    created_link.task_version_id, created_link.linked_at, false;
END;
$function$;

ALTER FUNCTION public.link_timed_attempt_assessment_submission(uuid, uuid, uuid)
  OWNER TO postgres;
REVOKE ALL ON FUNCTION public.link_timed_attempt_assessment_submission(uuid, uuid, uuid)
  FROM PUBLIC, anon, service_role;
GRANT EXECUTE ON FUNCTION public.link_timed_attempt_assessment_submission(uuid, uuid, uuid)
  TO authenticated;

COMMENT ON FUNCTION public.link_timed_attempt_assessment_submission(uuid, uuid, uuid) IS
  'Atomically links one learner-owned submitted attempt to one matching eligible human-assessment submission. Enforces same learner/task, published task/rubric, submission/response/timer state, accepted private PDF and transcript bound by source_file_id (without assuming rejected upload attempts did not consume file versions), one-to-one uniqueness and exact-pair idempotency.';

