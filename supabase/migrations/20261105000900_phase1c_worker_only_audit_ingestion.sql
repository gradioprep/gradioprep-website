-- Phase 1C-E: Worker-only ingestion for protected API audit outcomes.
-- Browser-authenticated users cannot submit their own success/failure claims.
-- The Worker calls this RPC only after verifying the caller and executing or
-- receiving a failure from the corresponding protected operation.
CREATE OR REPLACE FUNCTION public.record_worker_audit_outcome(
  p_actor_id uuid, p_action text, p_target_id uuid, p_outcome text,
  p_failure_category text DEFAULT NULL
)
RETURNS boolean LANGUAGE plpgsql SECURITY DEFINER SET search_path = ''
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
    event_reason := 'worker_precheck_denied';
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
  ELSE RETURN false;
  END IF;

  INSERT INTO private.security_audit_events(actor_id,action,target_type,target_id,outcome,reason_category)
  VALUES(p_actor_id,p_action,resource_type,p_target_id,p_outcome,event_reason);
  RETURN true;
END;
$function$;

ALTER FUNCTION public.record_worker_audit_outcome(uuid,text,uuid,text,text) OWNER TO postgres;
REVOKE ALL ON FUNCTION public.record_worker_audit_outcome(uuid,text,uuid,text,text) FROM PUBLIC, anon, authenticated;
GRANT EXECUTE ON FUNCTION public.record_worker_audit_outcome(uuid,text,uuid,text,text) TO service_role;

REVOKE ALL ON FUNCTION public.audit_protected_read_outcome(text,uuid,text) FROM PUBLIC, anon, authenticated, service_role;
REVOKE ALL ON FUNCTION public.audit_authorized_protected_read(text,uuid) FROM PUBLIC, anon, authenticated, service_role;
REVOKE ALL ON FUNCTION public.audit_privileged_write_outcome(text,uuid,text,text) FROM PUBLIC, anon, authenticated, service_role;

COMMENT ON FUNCTION public.record_worker_audit_outcome(uuid,text,uuid,text,text) IS
'Service-role-only audit ingestion called by the trusted Worker after its protected operation. Browser roles cannot forge outcome events; outcomes and failure categories are allowlisted and no learner, feedback, QA, token or credential payload is stored.';
