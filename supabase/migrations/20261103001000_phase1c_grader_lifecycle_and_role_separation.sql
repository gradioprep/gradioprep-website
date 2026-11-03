-- Phase 1C-D: safe submission grader reassignment, work-state transitions,
-- private draft preservation and automatic assignment revocation on role removal.
-- All operations remain local-Supabase/synthetic-data only.

CREATE TABLE private.assessment_draft_history (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  submission_id uuid NOT NULL
    REFERENCES public.assessment_submissions(id) ON DELETE RESTRICT,
  grader_user_id uuid NOT NULL REFERENCES auth.users(id) ON DELETE RESTRICT,
  rubric_version_id uuid NOT NULL REFERENCES public.rubric_versions(id) ON DELETE RESTRICT,
  overall_feedback text NOT NULL
    CHECK (char_length(btrim(overall_feedback)) BETWEEN 5 AND 8000),
  change_reason text
    CHECK (change_reason IS NULL OR char_length(btrim(change_reason)) BETWEEN 3 AND 240),
  criterion_results jsonb NOT NULL CHECK (jsonb_typeof(criterion_results) = 'array'),
  draft_revision integer NOT NULL CHECK (draft_revision > 0),
  created_at timestamptz NOT NULL,
  updated_at timestamptz NOT NULL,
  archived_by uuid NOT NULL REFERENCES auth.users(id) ON DELETE RESTRICT,
  archived_at timestamptz NOT NULL DEFAULT clock_timestamp(),
  archive_reason text NOT NULL
    CHECK (char_length(btrim(archive_reason)) BETWEEN 3 AND 240)
);

CREATE INDEX assessment_draft_history_submission_idx
  ON private.assessment_draft_history (submission_id, archived_at DESC);

ALTER TABLE private.assessment_draft_history ENABLE ROW LEVEL SECURITY;
REVOKE ALL ON private.assessment_draft_history FROM PUBLIC, anon, authenticated;

CREATE OR REPLACE FUNCTION private.prevent_assessment_draft_history_mutation()
RETURNS trigger
LANGUAGE plpgsql
SET search_path = ''
AS $$
BEGIN
  RAISE EXCEPTION USING ERRCODE = '42501', MESSAGE = 'assessment_draft_history_immutable';
END;
$$;

CREATE TRIGGER assessment_draft_history_immutable
  BEFORE UPDATE OR DELETE ON private.assessment_draft_history
  FOR EACH ROW EXECUTE FUNCTION private.prevent_assessment_draft_history_mutation();

-- Archive the current private draft before its grader loses access. The archive
-- is append-only and remains inaccessible through direct browser table access.
CREATE OR REPLACE FUNCTION private.archive_assessment_draft(
  p_submission_id uuid,
  p_archived_by uuid,
  p_archive_reason text
)
RETURNS boolean
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
DECLARE
  selected_draft private.assessment_drafts%ROWTYPE;
BEGIN
  IF p_submission_id IS NULL OR p_archived_by IS NULL
    OR p_archive_reason IS NULL
    OR char_length(btrim(p_archive_reason)) NOT BETWEEN 3 AND 240 THEN
    RAISE EXCEPTION USING ERRCODE = '22023', MESSAGE = 'invalid_assessment_draft_archive';
  END IF;

  SELECT draft.* INTO selected_draft
  FROM private.assessment_drafts AS draft
  WHERE draft.submission_id = p_submission_id
  FOR UPDATE;

  IF NOT FOUND THEN
    RETURN false;
  END IF;

  INSERT INTO private.assessment_draft_history (
    submission_id, grader_user_id, rubric_version_id, overall_feedback,
    change_reason, criterion_results, draft_revision, created_at, updated_at,
    archived_by, archive_reason
  )
  VALUES (
    selected_draft.submission_id, selected_draft.grader_user_id,
    selected_draft.rubric_version_id, selected_draft.overall_feedback,
    selected_draft.change_reason, selected_draft.criterion_results,
    selected_draft.draft_revision, selected_draft.created_at,
    selected_draft.updated_at, p_archived_by, btrim(p_archive_reason)
  );

  DELETE FROM private.assessment_drafts
  WHERE submission_id = p_submission_id;

  INSERT INTO private.security_audit_events (
    actor_id, action, target_type, target_id, outcome, reason_category
  )
  VALUES (
    p_archived_by, 'assessment_draft_archived', 'assessment_submission',
    p_submission_id, 'success', left(btrim(p_archive_reason), 80)
  );

  RETURN true;
END;
$$;

ALTER FUNCTION private.archive_assessment_draft(uuid, uuid, text) OWNER TO postgres;
REVOKE ALL ON FUNCTION private.archive_assessment_draft(uuid, uuid, text)
  FROM PUBLIC, anon, authenticated;

-- Reassignment is one transaction: lock the submission, revoke the previous
-- assignment, archive its private draft, and grant exactly one new assignment.
CREATE OR REPLACE FUNCTION public.reassign_submission_grader(
  p_submission_id uuid,
  p_new_grader_user_id uuid,
  p_reason text
)
RETURNS TABLE (
  new_assignment_id uuid,
  submission_id uuid,
  previous_grader_user_id uuid,
  new_grader_user_id uuid,
  submission_status text,
  previous_draft_archived boolean
)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
DECLARE
  actor_id uuid := auth.uid();
  selected_submission public.assessment_submissions%ROWTYPE;
  current_assignment public.submission_grader_assignments%ROWTYPE;
  created_assignment public.submission_grader_assignments%ROWTYPE;
  draft_was_archived boolean := false;
BEGIN
  IF actor_id IS NULL OR NOT private.current_account_is_active()
    OR NOT private.current_user_has_role('owner'::public.app_role)
    OR coalesce(auth.jwt() ->> 'aal', 'aal1') <> 'aal2' THEN
    RAISE EXCEPTION USING ERRCODE = '42501', MESSAGE = 'assessment_assignment_forbidden';
  END IF;

  IF p_submission_id IS NULL OR p_new_grader_user_id IS NULL
    OR p_reason IS NULL OR char_length(btrim(p_reason)) NOT BETWEEN 3 AND 240 THEN
    RAISE EXCEPTION USING ERRCODE = '22023', MESSAGE = 'invalid_assessment_assignment';
  END IF;

  SELECT submission.* INTO selected_submission
  FROM public.assessment_submissions AS submission
  WHERE submission.id = p_submission_id
  FOR UPDATE;

  IF NOT FOUND THEN
    RAISE EXCEPTION USING ERRCODE = 'P0002', MESSAGE = 'assessment_submission_not_found';
  END IF;

  IF selected_submission.status NOT IN ('assigned', 'grading') THEN
    RAISE EXCEPTION USING ERRCODE = 'P0001', MESSAGE = 'assessment_submission_not_reassignable';
  END IF;

  SELECT assignment.* INTO current_assignment
  FROM public.submission_grader_assignments AS assignment
  WHERE assignment.submission_id = p_submission_id
    AND assignment.revoked_at IS NULL
  FOR UPDATE;

  IF NOT FOUND THEN
    RAISE EXCEPTION USING ERRCODE = 'P0001', MESSAGE = 'assessment_assignment_not_found';
  END IF;

  IF current_assignment.grader_user_id = p_new_grader_user_id THEN
    RAISE EXCEPTION USING ERRCODE = 'P0001', MESSAGE = 'grader_already_assigned';
  END IF;

  IF NOT EXISTS (
    SELECT 1
    FROM public.role_assignments AS role
    JOIN public.profiles AS profile ON profile.user_id = role.user_id
    WHERE role.user_id = p_new_grader_user_id
      AND role.role = 'grader'::public.app_role
      AND role.revoked_at IS NULL
      AND profile.account_status = 'active'
  ) THEN
    RAISE EXCEPTION USING ERRCODE = '22023', MESSAGE = 'grader_not_available';
  END IF;

  draft_was_archived := private.archive_assessment_draft(
    p_submission_id, actor_id, 'grader_reassignment'
  );

  UPDATE public.submission_grader_assignments
  SET revoked_by = actor_id, revoked_at = clock_timestamp()
  WHERE id = current_assignment.id
    AND revoked_at IS NULL;

  INSERT INTO public.submission_grader_assignments (
    submission_id, grader_user_id, assigned_by, reason
  )
  VALUES (
    p_submission_id, p_new_grader_user_id, actor_id, btrim(p_reason)
  )
  RETURNING * INTO created_assignment;

  UPDATE public.assessment_submissions
  SET status = 'assigned'
  WHERE id = p_submission_id;

  INSERT INTO private.security_audit_events (
    actor_id, action, target_type, target_id, outcome, reason_category
  )
  VALUES (
    actor_id, 'assessment_submission_reassigned', 'assessment_submission',
    p_submission_id, 'success', 'owner_reassignment'
  );

  RETURN QUERY SELECT
    created_assignment.id, p_submission_id, current_assignment.grader_user_id,
    p_new_grader_user_id, 'assigned'::text, draft_was_archived;
END;
$$;

ALTER FUNCTION public.reassign_submission_grader(uuid, uuid, text) OWNER TO postgres;
REVOKE ALL ON FUNCTION public.reassign_submission_grader(uuid, uuid, text)
  FROM PUBLIC, anon, authenticated;
GRANT EXECUTE ON FUNCTION public.reassign_submission_grader(uuid, uuid, text)
  TO authenticated;

-- The allowed state changes are deliberately finite:
-- assigned/grading -> queued (remove assignment), assigned/grading/queued ->
-- withdrawn, and feedback_published -> closed. Closed/withdrawn are terminal.
CREATE OR REPLACE FUNCTION public.transition_assessment_submission(
  p_submission_id uuid,
  p_target_status text,
  p_reason text
)
RETURNS TABLE (
  submission_id uuid,
  previous_status text,
  status text,
  active_assignment_revoked boolean,
  draft_archived boolean
)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
DECLARE
  actor_id uuid := auth.uid();
  selected_submission public.assessment_submissions%ROWTYPE;
  assignment_rows integer := 0;
  archived_draft boolean := false;
BEGIN
  IF actor_id IS NULL OR NOT private.current_account_is_active()
    OR NOT private.current_user_has_role('owner'::public.app_role)
    OR coalesce(auth.jwt() ->> 'aal', 'aal1') <> 'aal2' THEN
    RAISE EXCEPTION USING ERRCODE = '42501', MESSAGE = 'assessment_transition_forbidden';
  END IF;

  IF p_submission_id IS NULL
    OR p_target_status NOT IN ('queued', 'withdrawn', 'closed')
    OR p_reason IS NULL OR char_length(btrim(p_reason)) NOT BETWEEN 3 AND 240 THEN
    RAISE EXCEPTION USING ERRCODE = '22023', MESSAGE = 'invalid_assessment_transition';
  END IF;

  SELECT submission.* INTO selected_submission
  FROM public.assessment_submissions AS submission
  WHERE submission.id = p_submission_id
  FOR UPDATE;

  IF NOT FOUND THEN
    RAISE EXCEPTION USING ERRCODE = 'P0002', MESSAGE = 'assessment_submission_not_found';
  END IF;

  IF NOT (
    (p_target_status = 'queued' AND selected_submission.status IN ('assigned', 'grading'))
    OR (p_target_status = 'withdrawn' AND selected_submission.status IN ('queued', 'assigned', 'grading'))
    OR (p_target_status = 'closed' AND selected_submission.status = 'feedback_published')
  ) THEN
    RAISE EXCEPTION USING ERRCODE = 'P0001', MESSAGE = 'invalid_assessment_transition';
  END IF;

  archived_draft := private.archive_assessment_draft(
    p_submission_id, actor_id, btrim(p_reason)
  );

  UPDATE public.submission_grader_assignments
  SET revoked_by = actor_id, revoked_at = clock_timestamp()
  WHERE submission_id = p_submission_id
    AND revoked_at IS NULL;
  GET DIAGNOSTICS assignment_rows = ROW_COUNT;

  UPDATE public.assessment_submissions
  SET status = p_target_status
  WHERE id = p_submission_id;

  INSERT INTO private.security_audit_events (
    actor_id, action, target_type, target_id, outcome, reason_category
  )
  VALUES (
    actor_id,
    CASE p_target_status
      WHEN 'queued' THEN 'assessment_submission_unassigned'
      WHEN 'withdrawn' THEN 'assessment_submission_withdrawn'
      ELSE 'assessment_submission_closed'
    END,
    'assessment_submission', p_submission_id, 'success',
    CASE p_target_status
      WHEN 'queued' THEN 'owner_requeue'
      WHEN 'withdrawn' THEN 'owner_withdrawal'
      ELSE 'owner_closure'
    END
  );

  RETURN QUERY SELECT p_submission_id, selected_submission.status,
    p_target_status, assignment_rows > 0, archived_draft;
END;
$$;

ALTER FUNCTION public.transition_assessment_submission(uuid, text, text) OWNER TO postgres;
REVOKE ALL ON FUNCTION public.transition_assessment_submission(uuid, text, text)
  FROM PUBLIC, anon, authenticated;
GRANT EXECUTE ON FUNCTION public.transition_assessment_submission(uuid, text, text)
  TO authenticated;

-- A grader whose application role is revoked must lose every active submission
-- assignment in the same transaction. Unpublished work is archived and returned
-- to the queue; already-published learner feedback remains published.
CREATE OR REPLACE FUNCTION private.invalidate_submission_assignments_after_grader_revocation()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
DECLARE
  selected_assignment record;
  selected_status text;
  archived_draft boolean;
BEGIN
  IF NEW.revoked_by IS NULL THEN
    RAISE EXCEPTION USING ERRCODE = '23514', MESSAGE = 'grader_role_revocation_actor_required';
  END IF;

  FOR selected_assignment IN
    SELECT assignment.id, assignment.submission_id
    FROM public.submission_grader_assignments AS assignment
    WHERE assignment.grader_user_id = NEW.user_id
      AND assignment.revoked_at IS NULL
    ORDER BY assignment.assigned_at, assignment.id
    FOR UPDATE
  LOOP
    SELECT submission.status INTO selected_status
    FROM public.assessment_submissions AS submission
    WHERE submission.id = selected_assignment.submission_id
    FOR UPDATE;

    archived_draft := private.archive_assessment_draft(
      selected_assignment.submission_id, NEW.revoked_by, 'grader_role_revoked'
    );

    UPDATE public.submission_grader_assignments
    SET revoked_by = NEW.revoked_by, revoked_at = clock_timestamp()
    WHERE id = selected_assignment.id
      AND revoked_at IS NULL;

    IF selected_status IN ('assigned', 'grading') THEN
      UPDATE public.assessment_submissions
      SET status = 'queued'
      WHERE id = selected_assignment.submission_id;
    END IF;

    INSERT INTO private.security_audit_events (
      actor_id, action, target_type, target_id, outcome, reason_category
    )
    VALUES (
      NEW.revoked_by, 'assessment_assignment_revoked', 'assessment_submission',
      selected_assignment.submission_id, 'success', 'grader_role_revoked'
    );
  END LOOP;

  RETURN NEW;
END;
$$;

ALTER FUNCTION private.invalidate_submission_assignments_after_grader_revocation()
  OWNER TO postgres;
REVOKE ALL ON FUNCTION private.invalidate_submission_assignments_after_grader_revocation()
  FROM PUBLIC, anon, authenticated;

CREATE TRIGGER role_assignments_invalidate_submission_grader
  AFTER UPDATE OF revoked_at ON public.role_assignments
  FOR EACH ROW
  WHEN (OLD.revoked_at IS NULL AND NEW.revoked_at IS NOT NULL AND NEW.role = 'grader')
  EXECUTE FUNCTION private.invalidate_submission_assignments_after_grader_revocation();
