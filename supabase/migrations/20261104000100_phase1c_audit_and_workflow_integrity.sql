-- Phase 1C-E: append-oriented workflow audit and replay-safe saves.
-- Local Supabase and synthetic data only. No external service or hosted resource.

-- Successful typed-response changes are recorded as metadata only. Learner
-- response content and word counts are never copied into the audit stream.
CREATE OR REPLACE FUNCTION private.audit_attempt_response_change()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
BEGIN
  IF TG_OP = 'UPDATE'
    AND NEW.response_text IS NOT DISTINCT FROM OLD.response_text THEN
    RETURN NEW;
  END IF;

  INSERT INTO private.security_audit_events (
    actor_id, action, target_type, target_id, outcome, reason_category
  )
  VALUES (
    auth.uid(), 'attempt_response_saved', 'attempt', NEW.attempt_id,
    'success', 'learner_action'
  );
  RETURN NEW;
END;
$$;

ALTER FUNCTION private.audit_attempt_response_change() OWNER TO postgres;
REVOKE ALL ON FUNCTION private.audit_attempt_response_change() FROM PUBLIC, anon, authenticated;

CREATE TRIGGER attempt_responses_audit_insert
  AFTER INSERT ON public.attempt_responses
  FOR EACH ROW EXECUTE FUNCTION private.audit_attempt_response_change();

CREATE TRIGGER attempt_responses_audit_update
  AFTER UPDATE OF response_text ON public.attempt_responses
  FOR EACH ROW EXECUTE FUNCTION private.audit_attempt_response_change();

-- Worker-facing, action-allowlisted audit RPC for authorised reads. It performs
-- the same actor/role/AAL/resource checks itself and records metadata only.
CREATE OR REPLACE FUNCTION public.audit_authorized_protected_read(
  p_action text,
  p_target_id uuid DEFAULT NULL
)
RETURNS boolean
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
DECLARE
  actor_id uuid := auth.uid();
  allowed boolean := false;
  resource_type text;
  reason text;
BEGIN
  IF actor_id IS NULL OR NOT private.current_account_is_active() THEN
    RETURN false;
  END IF;

  CASE p_action
    WHEN 'student_attempt_list_authorized' THEN
      resource_type := 'attempt_collection';
      reason := 'student_self';
      allowed := p_target_id IS NULL
        AND private.current_user_has_role('student'::public.app_role);

    WHEN 'student_attempt_read_authorized' THEN
      resource_type := 'attempt';
      reason := 'student_self';
      allowed := p_target_id IS NOT NULL
        AND private.current_user_has_role('student'::public.app_role)
        AND EXISTS (
          SELECT 1 FROM public.attempts AS attempt
          WHERE attempt.id = p_target_id AND attempt.learner_id = actor_id
        );

    WHEN 'grader_attempt_queue_authorized' THEN
      resource_type := 'attempt_queue';
      reason := 'assigned_grader_aal2';
      allowed := p_target_id IS NULL
        AND private.current_user_has_role('grader'::public.app_role)
        AND coalesce(auth.jwt() ->> 'aal', 'aal1') = 'aal2';

    WHEN 'grader_attempt_read_authorized' THEN
      resource_type := 'attempt';
      reason := 'active_grader_assignment_aal2';
      allowed := p_target_id IS NOT NULL
        AND private.current_user_has_role('grader'::public.app_role)
        AND coalesce(auth.jwt() ->> 'aal', 'aal1') = 'aal2'
        AND EXISTS (
          SELECT 1
          FROM public.attempts AS attempt
          JOIN public.grader_assignments AS assignment
            ON assignment.attempt_id = attempt.id
          WHERE attempt.id = p_target_id
            AND attempt.status = 'submitted'
            AND assignment.grader_user_id = actor_id
            AND assignment.revoked_at IS NULL
        );

    WHEN 'student_submission_list_authorized' THEN
      resource_type := 'assessment_submission_collection';
      reason := 'student_self';
      allowed := p_target_id IS NULL
        AND private.current_user_has_role('student'::public.app_role);

    WHEN 'student_submission_read_authorized' THEN
      resource_type := 'assessment_submission';
      reason := 'student_self';
      allowed := p_target_id IS NOT NULL
        AND private.current_user_has_role('student'::public.app_role)
        AND EXISTS (
          SELECT 1 FROM public.assessment_submissions AS submission
          WHERE submission.id = p_target_id AND submission.learner_id = actor_id
        );

    WHEN 'grader_submission_queue_authorized' THEN
      resource_type := 'assessment_submission_queue';
      reason := 'assigned_grader_aal2';
      allowed := p_target_id IS NULL
        AND private.current_user_has_role('grader'::public.app_role)
        AND coalesce(auth.jwt() ->> 'aal', 'aal1') = 'aal2';

    WHEN 'grader_submission_read_authorized' THEN
      resource_type := 'assessment_submission';
      reason := 'active_grader_assignment_aal2';
      allowed := p_target_id IS NOT NULL
        AND private.current_user_has_role('grader'::public.app_role)
        AND coalesce(auth.jwt() ->> 'aal', 'aal1') = 'aal2'
        AND EXISTS (
          SELECT 1
          FROM public.assessment_submissions AS submission
          JOIN public.submission_grader_assignments AS assignment
            ON assignment.submission_id = submission.id
          WHERE submission.id = p_target_id
            AND submission.status IN ('assigned', 'grading', 'feedback_published')
            AND assignment.grader_user_id = actor_id
            AND assignment.revoked_at IS NULL
        );

    WHEN 'owner_submission_queue_authorized' THEN
      resource_type := 'assessment_submission_queue';
      reason := 'owner_aal2';
      allowed := p_target_id IS NULL
        AND private.current_user_has_role('owner'::public.app_role)
        AND coalesce(auth.jwt() ->> 'aal', 'aal1') = 'aal2';

    ELSE
      RETURN false;
  END CASE;

  IF NOT allowed THEN
    RETURN false;
  END IF;

  INSERT INTO private.security_audit_events (
    actor_id, action, target_type, target_id, outcome, reason_category
  )
  VALUES (actor_id, p_action, resource_type, p_target_id, 'success', reason);

  RETURN true;
END;
$$;

ALTER FUNCTION public.audit_authorized_protected_read(text, uuid) OWNER TO postgres;
REVOKE ALL ON FUNCTION public.audit_authorized_protected_read(text, uuid)
  FROM PUBLIC, anon, authenticated;
GRANT EXECUTE ON FUNCTION public.audit_authorized_protected_read(text, uuid)
  TO authenticated;

-- A byte-identical retry acknowledges the saved version without advancing it.
CREATE OR REPLACE FUNCTION public.save_attempt_response(
  p_attempt_id uuid,
  p_prompt_id uuid,
  p_response_text text
)
RETURNS TABLE (
  id uuid,
  attempt_id uuid,
  prompt_id uuid,
  response_text text,
  word_count integer,
  version integer,
  updated_at timestamptz
)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
DECLARE
  actor_id uuid := auth.uid();
  selected_task_version_id uuid;
  current_status text;
  existing_response public.attempt_responses%ROWTYPE;
BEGIN
  IF actor_id IS NULL
    OR NOT private.current_account_is_active()
    OR NOT private.current_user_has_role('student'::public.app_role) THEN
    RAISE EXCEPTION USING ERRCODE = '42501', MESSAGE = 'attempt_response_forbidden';
  END IF;

  IF p_response_text IS NULL OR char_length(p_response_text) > 12000 THEN
    RAISE EXCEPTION USING ERRCODE = '22023', MESSAGE = 'invalid_attempt_response';
  END IF;

  SELECT attempt.task_version_id, attempt.status
    INTO selected_task_version_id, current_status
    FROM public.attempts AS attempt
    WHERE attempt.id = p_attempt_id
      AND attempt.learner_id = actor_id
    FOR UPDATE;

  IF NOT FOUND THEN
    RAISE EXCEPTION USING ERRCODE = 'P0002', MESSAGE = 'attempt_not_found';
  END IF;

  IF current_status <> 'in_progress' THEN
    RAISE EXCEPTION USING ERRCODE = 'P0001', MESSAGE = 'attempt_not_editable';
  END IF;

  IF NOT EXISTS (
    SELECT 1
    FROM public.task_version_prompts AS prompt
    WHERE prompt.id = p_prompt_id
      AND prompt.task_version_id = selected_task_version_id
  ) THEN
    RAISE EXCEPTION USING ERRCODE = '22023', MESSAGE = 'invalid_attempt_prompt';
  END IF;

  SELECT response.* INTO existing_response
  FROM public.attempt_responses AS response
  WHERE response.attempt_id = p_attempt_id
    AND response.prompt_id = p_prompt_id
  FOR UPDATE;

  -- An identical retry acknowledges the existing version without creating
  -- another version or a redundant private archive snapshot.
  IF FOUND AND existing_response.response_text IS NOT DISTINCT FROM p_response_text THEN
    RETURN QUERY SELECT
      existing_response.id,
      existing_response.attempt_id,
      existing_response.prompt_id,
      existing_response.response_text,
      existing_response.word_count,
      existing_response.version,
      existing_response.updated_at;
    RETURN;
  END IF;

  RETURN QUERY
    INSERT INTO public.attempt_responses AS saved_response (
      attempt_id, task_version_id, prompt_id, response_text
    )
    VALUES (
      p_attempt_id, selected_task_version_id, p_prompt_id, p_response_text
    )
    ON CONFLICT ON CONSTRAINT attempt_responses_attempt_id_prompt_id_key
    DO UPDATE SET response_text = EXCLUDED.response_text
    RETURNING
      saved_response.id,
      saved_response.attempt_id,
      saved_response.prompt_id,
      saved_response.response_text,
      saved_response.word_count,
      saved_response.version,
      saved_response.updated_at;
END;
$$;

ALTER FUNCTION public.save_attempt_response(uuid, uuid, text) OWNER TO postgres;
REVOKE ALL ON FUNCTION public.save_attempt_response(uuid, uuid, text)
  FROM PUBLIC, anon, authenticated;
GRANT EXECUTE ON FUNCTION public.save_attempt_response(uuid, uuid, text)
  TO authenticated;

-- A byte/JSONB-identical grader draft retry does not advance the draft revision.
CREATE OR REPLACE FUNCTION public.save_assessment_draft(
  p_submission_id uuid,
  p_overall_feedback text,
  p_change_reason text,
  p_criterion_results jsonb
)
RETURNS TABLE (
  submission_id uuid,
  grader_user_id uuid,
  draft_revision integer,
  updated_at timestamptz
)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
DECLARE
  actor_id uuid := auth.uid();
  selected_submission public.assessment_submissions%ROWTYPE;
  existing_draft private.assessment_drafts%ROWTYPE;
  expected_criteria integer;
  supplied_criteria integer;
  distinct_criteria integer;
  published_count integer;
  next_revision integer;
  saved_at timestamptz;
  result_item jsonb;
BEGIN
  IF actor_id IS NULL OR NOT private.current_account_is_active()
    OR NOT private.current_user_has_role('grader'::public.app_role)
    OR coalesce(auth.jwt() ->> 'aal', 'aal1') <> 'aal2' THEN
    RAISE EXCEPTION USING ERRCODE = '42501', MESSAGE = 'grader_assessment_forbidden';
  END IF;

  IF p_submission_id IS NULL OR p_overall_feedback IS NULL
    OR char_length(btrim(p_overall_feedback)) NOT BETWEEN 5 AND 8000
    OR p_criterion_results IS NULL
    OR (p_change_reason IS NOT NULL AND char_length(btrim(p_change_reason)) NOT BETWEEN 3 AND 240) THEN
    RAISE EXCEPTION USING ERRCODE = '22023', MESSAGE = 'invalid_assessment_draft';
  END IF;

  IF jsonb_typeof(p_criterion_results) <> 'array' THEN
    RAISE EXCEPTION USING ERRCODE = '22023', MESSAGE = 'invalid_assessment_draft';
  END IF;

  IF jsonb_array_length(p_criterion_results) = 0 THEN
    RAISE EXCEPTION USING ERRCODE = '22023', MESSAGE = 'invalid_assessment_draft';
  END IF;

  SELECT submission.* INTO selected_submission
  FROM public.assessment_submissions AS submission
  WHERE submission.id = p_submission_id
  FOR UPDATE;

  IF NOT FOUND THEN
    RAISE EXCEPTION USING ERRCODE = 'P0002', MESSAGE = 'assessment_submission_not_found';
  END IF;

  IF selected_submission.status NOT IN ('assigned', 'grading', 'feedback_published') OR NOT EXISTS (
    SELECT 1 FROM public.submission_grader_assignments AS assignment
    WHERE assignment.submission_id = p_submission_id
      AND assignment.grader_user_id = actor_id
      AND assignment.revoked_at IS NULL
  ) THEN
    RAISE EXCEPTION USING ERRCODE = '42501', MESSAGE = 'grader_assessment_forbidden';
  END IF;

  SELECT draft.* INTO existing_draft
  FROM private.assessment_drafts AS draft
  WHERE draft.submission_id = p_submission_id
  FOR UPDATE;

  IF FOUND AND existing_draft.grader_user_id <> actor_id THEN
    RAISE EXCEPTION USING ERRCODE = '42501', MESSAGE = 'grader_assessment_forbidden';
  END IF;

  SELECT count(*)::integer INTO expected_criteria
  FROM public.rubric_criteria AS criterion
  WHERE criterion.rubric_version_id = selected_submission.rubric_version_id;

  IF expected_criteria = 0 THEN
    RAISE EXCEPTION USING ERRCODE = 'P0001', MESSAGE = 'invalid_assessment_criteria';
  END IF;

  FOR result_item IN SELECT value FROM jsonb_array_elements(p_criterion_results)
  LOOP
    IF jsonb_typeof(result_item) <> 'object' THEN
      RAISE EXCEPTION USING ERRCODE = '22023', MESSAGE = 'invalid_assessment_criteria';
    END IF;

    IF (SELECT count(*)::integer FROM jsonb_object_keys(result_item)) <> 3
      OR NOT (result_item ?& ARRAY['criterion_id', 'points_awarded', 'feedback'])
      OR jsonb_typeof(result_item -> 'criterion_id') <> 'string'
      OR (result_item ->> 'criterion_id') !~* '^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$'
      OR jsonb_typeof(result_item -> 'points_awarded') <> 'number'
      OR (result_item ->> 'points_awarded') !~ '^[0-9]{1,5}(\.[0-9]{1,2})?$'
      OR jsonb_typeof(result_item -> 'feedback') <> 'string'
      OR char_length(btrim(result_item ->> 'feedback')) NOT BETWEEN 5 AND 3000 THEN
      RAISE EXCEPTION USING ERRCODE = '22023', MESSAGE = 'invalid_assessment_criteria';
    END IF;
  END LOOP;

  SELECT
    count(*)::integer,
    count(DISTINCT (item.value ->> 'criterion_id'))::integer
  INTO supplied_criteria, distinct_criteria
  FROM jsonb_array_elements(p_criterion_results) AS item(value);

  IF supplied_criteria <> expected_criteria OR distinct_criteria <> expected_criteria THEN
    RAISE EXCEPTION USING ERRCODE = '22023', MESSAGE = 'invalid_assessment_criteria';
  END IF;

  IF EXISTS (
    SELECT 1
    FROM jsonb_array_elements(p_criterion_results) AS item(value)
    LEFT JOIN public.rubric_criteria AS criterion
      ON criterion.id = (item.value ->> 'criterion_id')::uuid
     AND criterion.rubric_version_id = selected_submission.rubric_version_id
    WHERE criterion.id IS NULL
      OR (item.value ->> 'points_awarded')::numeric > criterion.max_points
  ) THEN
    RAISE EXCEPTION USING ERRCODE = '22023', MESSAGE = 'invalid_assessment_criteria';
  END IF;

  SELECT count(*)::integer INTO published_count
  FROM public.assessment_versions AS version
  WHERE version.submission_id = p_submission_id;

  IF published_count > 0 AND char_length(btrim(coalesce(p_change_reason, ''))) < 3 THEN
    RAISE EXCEPTION USING ERRCODE = '22023', MESSAGE = 'assessment_change_reason_required';
  END IF;

  -- An identical retry is acknowledged without creating another draft revision.
  IF existing_draft.submission_id IS NOT NULL
    AND existing_draft.rubric_version_id = selected_submission.rubric_version_id
    AND existing_draft.overall_feedback = btrim(p_overall_feedback)
    AND existing_draft.change_reason IS NOT DISTINCT FROM
      nullif(btrim(coalesce(p_change_reason, '')), '')
    AND existing_draft.criterion_results = p_criterion_results THEN
    INSERT INTO private.security_audit_events (
      actor_id, action, target_type, target_id, outcome, reason_category
    )
    VALUES (
      actor_id, 'assessment_draft_save_replayed', 'assessment_submission',
      p_submission_id, 'success', 'idempotent_retry'
    );

    RETURN QUERY SELECT
      p_submission_id, actor_id, existing_draft.draft_revision, existing_draft.updated_at;
    RETURN;
  END IF;

  next_revision := CASE WHEN existing_draft.submission_id IS NULL
    THEN 1 ELSE existing_draft.draft_revision + 1 END;
  saved_at := clock_timestamp();

  INSERT INTO private.assessment_drafts (
    submission_id, grader_user_id, rubric_version_id, overall_feedback,
    change_reason, criterion_results, draft_revision, created_at, updated_at
  )
  VALUES (
    p_submission_id, actor_id, selected_submission.rubric_version_id,
    btrim(p_overall_feedback), nullif(btrim(coalesce(p_change_reason, '')), ''),
    p_criterion_results, next_revision, saved_at, saved_at
  )
  ON CONFLICT ON CONSTRAINT assessment_drafts_pkey DO UPDATE
  SET grader_user_id = EXCLUDED.grader_user_id,
      rubric_version_id = EXCLUDED.rubric_version_id,
      overall_feedback = EXCLUDED.overall_feedback,
      change_reason = EXCLUDED.change_reason,
      criterion_results = EXCLUDED.criterion_results,
      draft_revision = EXCLUDED.draft_revision,
      updated_at = EXCLUDED.updated_at;

  IF selected_submission.status = 'assigned' THEN
    UPDATE public.assessment_submissions
    SET status = 'grading'
    WHERE id = p_submission_id;
  END IF;

  INSERT INTO private.security_audit_events (
    actor_id, action, target_type, target_id, outcome, reason_category
  )
  VALUES (
    actor_id, 'assessment_draft_saved', 'assessment_submission',
    p_submission_id, 'success', 'grader_action'
  );

  RETURN QUERY SELECT p_submission_id, actor_id, next_revision, saved_at;
END;
$$;

ALTER FUNCTION public.save_assessment_draft(uuid, text, text, jsonb) OWNER TO postgres;
REVOKE ALL ON FUNCTION public.save_assessment_draft(uuid, text, text, jsonb)
  FROM PUBLIC, anon, authenticated;
GRANT EXECUTE ON FUNCTION public.save_assessment_draft(uuid, text, text, jsonb)
  TO authenticated;
