-- Publish only an explicitly Founder-approved, sufficiently evidenced PA draft.
-- This creates a new immutable learner-readable report version, never mutates its source.
CREATE OR REPLACE FUNCTION public.publish_pa_evaluation_feedback(
  p_review_id uuid, p_idempotency_key uuid
)
RETURNS TABLE(report_record_id uuid,report_version_id uuid,version_number integer,is_replay boolean)
LANGUAGE plpgsql SECURITY DEFINER SET search_path = ''
AS $$
DECLARE
  selected_review private.pa_evaluation_feedback_reviews%ROWTYPE;
  selected_draft private.pa_evaluation_feedback_drafts%ROWTYPE;
  base_version public.evaluation_report_versions%ROWTYPE;
  prior_version public.evaluation_report_versions%ROWTYPE;
  result_version public.evaluation_report_versions%ROWTYPE;
  report_learner_id uuid;
BEGIN
  IF auth.uid() IS NULL OR NOT private.current_account_is_active()
    OR NOT private.current_user_has_role('owner'::public.app_role)
    OR coalesce(auth.jwt()->>'aal','aal1') <> 'aal2' THEN
    RAISE EXCEPTION USING ERRCODE='42501',MESSAGE='pa_feedback_publication_forbidden';
  END IF;
  IF p_review_id IS NULL OR p_idempotency_key IS NULL THEN
    RAISE EXCEPTION USING ERRCODE='22023',MESSAGE='invalid_pa_feedback_publication';
  END IF;
  SELECT r.* INTO selected_review FROM private.pa_evaluation_feedback_reviews AS r
    WHERE r.id=p_review_id AND r.decision='approved_for_publication';
  IF NOT FOUND THEN
    RAISE EXCEPTION USING ERRCODE='55000',MESSAGE='pa_feedback_not_approved';
  END IF;
  SELECT d.* INTO selected_draft FROM private.pa_evaluation_feedback_drafts AS d
    WHERE d.id=selected_review.draft_id
      AND d.report_record_id=selected_review.report_record_id
      AND d.report_version_id=selected_review.report_version_id;
  SELECT v.* INTO base_version FROM public.evaluation_report_versions AS v
    WHERE v.id=selected_review.report_version_id
      AND v.report_record_id=selected_review.report_record_id AND v.report_scope='pa_baseline';
  IF selected_draft.id IS NULL OR base_version.id IS NULL THEN
    RAISE EXCEPTION USING ERRCODE='55000',MESSAGE='pa_feedback_publication_lineage_invalid';
  END IF;
  -- Lock the report series, serialize competing publications, preserve exact snapshot lineage.
  SELECT r.learner_id INTO report_learner_id
  FROM public.evaluation_report_records AS r
  WHERE r.id=base_version.report_record_id AND r.report_scope='pa_baseline' FOR UPDATE;
  IF report_learner_id IS NULL OR report_learner_id IS DISTINCT FROM base_version.learner_id THEN
    RAISE EXCEPTION USING ERRCODE='55000',MESSAGE='pa_feedback_publication_lineage_invalid';
  END IF;
  SELECT v.* INTO result_version FROM public.evaluation_report_versions AS v
    WHERE v.learner_id=report_learner_id AND v.idempotency_key=p_idempotency_key;
  IF FOUND THEN
    IF result_version.report_record_id IS DISTINCT FROM base_version.report_record_id
      OR result_version.published_feedback_snapshot->>'review_id' IS DISTINCT FROM p_review_id::text
      OR result_version.published_feedback_snapshot->>'status' <> 'human_approved_published' THEN
      RAISE EXCEPTION USING ERRCODE='P0001',MESSAGE='pa_feedback_publication_idempotency_conflict';
    END IF;
    RETURN QUERY SELECT result_version.report_record_id,result_version.id,result_version.version_number,true;
    RETURN;
  END IF;
  SELECT v.* INTO prior_version FROM public.evaluation_report_versions AS v
    WHERE v.report_record_id=base_version.report_record_id ORDER BY v.version_number DESC LIMIT 1;
  IF prior_version.id IS DISTINCT FROM base_version.id
    OR base_version.curriculum_mapping_status <> 'complete_direct'
    OR base_version.evidence_sufficiency_status <> 'sufficient'
    OR jsonb_array_length(base_version.curriculum_mapping_snapshot)=0
    OR jsonb_array_length(base_version.learner_evidence_snapshot)=0
    OR jsonb_array_length(base_version.curriculum_mapping_snapshot)
       <> jsonb_array_length(base_version.learner_evidence_snapshot)
    OR EXISTS (SELECT 1 FROM jsonb_array_elements(base_version.curriculum_mapping_snapshot) AS m
      WHERE m->>'mapping_status'<>'direct'
        OR jsonb_array_length(coalesce(m->'direct_outcomes','[]'::jsonb))=0)
    OR EXISTS (SELECT 1 FROM jsonb_array_elements(base_version.learner_evidence_snapshot) AS e
      WHERE e->>'response_sha256' IS NULL)
  THEN
    RAISE EXCEPTION USING ERRCODE='55000',MESSAGE='pa_feedback_publication_requirements_not_met';
  END IF;
  IF EXISTS (SELECT 1 FROM public.evaluation_report_versions AS v
    WHERE v.report_record_id=base_version.report_record_id
      AND v.published_feedback_snapshot->>'review_id'=p_review_id::text) THEN
    RAISE EXCEPTION USING ERRCODE='P0001',MESSAGE='pa_feedback_already_published';
  END IF;

  INSERT INTO public.evaluation_report_versions(
    report_record_id,report_scope,learner_id,version_number,idempotency_key,supersedes_version_id,
    curriculum_mapping_status,evidence_sufficiency_status,scope_snapshot,content_snapshot,
    unit_set_snapshot,curriculum_mapping_snapshot,learner_evidence_snapshot,
    published_feedback_snapshot,eligible_analytics_snapshot,created_by)
  VALUES (
    base_version.report_record_id,base_version.report_scope,base_version.learner_id,
    base_version.version_number+1,p_idempotency_key,base_version.id,
    base_version.curriculum_mapping_status,base_version.evidence_sufficiency_status,
    base_version.scope_snapshot,base_version.content_snapshot,base_version.unit_set_snapshot,
    base_version.curriculum_mapping_snapshot,base_version.learner_evidence_snapshot,
    jsonb_build_object('status','human_approved_published',
      'review_id',selected_review.id,'approved_at',selected_review.decided_at,
      'feedback_text',selected_draft.draft_text,'source_report_version_id',base_version.id),
    base_version.eligible_analytics_snapshot,auth.uid()
  ) RETURNING * INTO result_version;
  INSERT INTO private.security_audit_events(actor_id,action,target_type,target_id,outcome,reason_category)
  VALUES(auth.uid(),'pa_feedback_published','evaluation_report_version',result_version.id,
    'success','owner_approved_report');
  RETURN QUERY SELECT result_version.report_record_id,result_version.id,result_version.version_number,false;
END;
$$;
ALTER FUNCTION public.publish_pa_evaluation_feedback(uuid,uuid) OWNER TO postgres;
REVOKE ALL ON FUNCTION public.publish_pa_evaluation_feedback(uuid,uuid) FROM PUBLIC,anon,service_role;
GRANT EXECUTE ON FUNCTION public.publish_pa_evaluation_feedback(uuid,uuid) TO authenticated;
COMMENT ON FUNCTION public.publish_pa_evaluation_feedback(uuid,uuid) IS
  'Owner+AAL2-only exact-review publication. Requires verified evidence and prior human decision. Creates a new immutable report snapshot without fabricating scores or AI feedback.';
