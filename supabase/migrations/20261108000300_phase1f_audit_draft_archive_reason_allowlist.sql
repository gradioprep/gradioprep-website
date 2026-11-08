-- Phase 1F: keep free-text draft archive explanations out of audit metadata.
-- The full explanation remains in private, immutable draft history.
CREATE OR REPLACE FUNCTION private.archive_assessment_draft(
  p_submission_id uuid,
  p_archived_by uuid,
  p_archive_reason text
)
RETURNS boolean
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $function$
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
    p_submission_id, 'success', 'draft_archived'
  );

  RETURN true;
END;
$function$;

ALTER FUNCTION private.archive_assessment_draft(uuid, uuid, text) OWNER TO postgres;
REVOKE ALL ON FUNCTION private.archive_assessment_draft(uuid, uuid, text)
  FROM PUBLIC, anon, authenticated;

COMMENT ON FUNCTION private.archive_assessment_draft(uuid, uuid, text) IS
'Archives the private grading draft with its full bounded explanation in immutable private history. The corresponding security audit event stores only the fixed draft_archived category and never copies free-text archive_reason into audit metadata.';
