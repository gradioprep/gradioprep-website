-- Step 8: joint human approval of exact-version PA scoring and feedback.
-- Append-only private gate; never publishes or alters a learner report.
CREATE TABLE private.pa_report_composition_approvals (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  report_record_id uuid NOT NULL REFERENCES public.evaluation_report_records(id) ON DELETE RESTRICT,
  report_version_id uuid NOT NULL REFERENCES public.evaluation_report_versions(id) ON DELETE RESTRICT,
  scoring_review_id uuid NOT NULL UNIQUE REFERENCES private.pa_scoring_reviews(id) ON DELETE RESTRICT,
  feedback_review_id uuid NOT NULL UNIQUE REFERENCES private.pa_evaluation_feedback_reviews(id) ON DELETE RESTRICT,
  approved_by uuid NOT NULL REFERENCES auth.users(id) ON DELETE RESTRICT,
  approval_note text NOT NULL CHECK (char_length(btrim(approval_note)) BETWEEN 20 AND 1000),
  approved_at timestamptz NOT NULL DEFAULT clock_timestamp()
);
ALTER TABLE private.pa_report_composition_approvals ENABLE ROW LEVEL SECURITY;
REVOKE ALL ON private.pa_report_composition_approvals FROM PUBLIC,anon,authenticated,service_role;
CREATE TRIGGER pa_report_composition_approval_immutable
  BEFORE UPDATE OR DELETE ON private.pa_report_composition_approvals
  FOR EACH ROW EXECUTE FUNCTION private.prevent_pa_feedback_draft_mutation();

CREATE OR REPLACE FUNCTION public.approve_private_pa_report_composition(
  p_scoring_review_id uuid,p_feedback_review_id uuid,p_approval_note text
) RETURNS uuid LANGUAGE plpgsql SECURITY DEFINER SET search_path=''
AS $$
DECLARE
  chosen_score private.pa_scoring_reviews%ROWTYPE;
  chosen_feedback private.pa_evaluation_feedback_reviews%ROWTYPE;
  selected_draft private.pa_evaluation_feedback_drafts%ROWTYPE;
  selected_report public.evaluation_report_versions%ROWTYPE;
  evidence record;
  created uuid;
BEGIN
  IF auth.uid() IS NULL OR NOT private.current_account_is_active()
    OR NOT private.current_user_has_role('owner'::public.app_role)
    OR coalesce(auth.jwt()->>'aal','aal1') <> 'aal2' THEN
    RAISE EXCEPTION USING ERRCODE='42501',MESSAGE='pa_joint_composition_approval_forbidden';
  END IF;
  IF p_scoring_review_id IS NULL OR p_feedback_review_id IS NULL
    OR char_length(btrim(coalesce(p_approval_note,''))) NOT BETWEEN 20 AND 1000 THEN
    RAISE EXCEPTION USING ERRCODE='22023',MESSAGE='invalid_pa_joint_composition_approval';
  END IF;
  SELECT * INTO chosen_score FROM private.pa_scoring_reviews
    WHERE id=p_scoring_review_id AND decision='approved_private';
  SELECT * INTO chosen_feedback FROM private.pa_evaluation_feedback_reviews
    WHERE id=p_feedback_review_id AND decision='approved_for_publication';
  IF chosen_score.id IS NULL OR chosen_feedback.id IS NULL
    OR chosen_score.report_record_id IS DISTINCT FROM chosen_feedback.report_record_id
    OR chosen_score.report_version_id IS DISTINCT FROM chosen_feedback.report_version_id THEN
    RAISE EXCEPTION USING ERRCODE='55000',MESSAGE='pa_joint_composition_requires_matching_human_approvals';
  END IF;
  SELECT * INTO selected_draft FROM private.pa_evaluation_feedback_drafts
    WHERE id=chosen_feedback.draft_id;
  IF selected_draft.id IS NULL
    OR selected_draft.report_record_id IS DISTINCT FROM chosen_score.report_record_id
    OR selected_draft.report_version_id IS DISTINCT FROM chosen_score.report_version_id THEN
    RAISE EXCEPTION USING ERRCODE='55000',MESSAGE='pa_joint_composition_feedback_lineage_invalid';
  END IF;
  -- Serialize against newer report versions and prevent stale approval.
  PERFORM 1 FROM public.evaluation_report_records
    WHERE id=chosen_score.report_record_id AND report_scope='pa_baseline' FOR UPDATE;
  IF NOT FOUND THEN
    RAISE EXCEPTION USING ERRCODE='55000',MESSAGE='pa_joint_composition_report_invalid';
  END IF;
  SELECT * INTO selected_report FROM public.evaluation_report_versions
    WHERE id=chosen_score.report_version_id
      AND report_record_id=chosen_score.report_record_id
      AND report_scope='pa_baseline';
  IF selected_report.id IS NULL
    OR selected_report.curriculum_mapping_status<>'complete_direct'
    OR selected_report.evidence_sufficiency_status<>'sufficient'
    OR EXISTS(SELECT 1 FROM public.evaluation_report_versions newer
      WHERE newer.report_record_id=chosen_score.report_record_id
        AND newer.version_number>selected_report.version_number) THEN
    RAISE EXCEPTION USING ERRCODE='55000',MESSAGE='pa_joint_composition_report_not_current_or_complete';
  END IF;
  SELECT * INTO evidence FROM public.inspect_pa_scoring_evidence(chosen_score.report_record_id);
  IF NOT FOUND OR evidence.report_version_id IS DISTINCT FROM selected_report.id
    OR evidence.mapping_and_evidence_complete IS DISTINCT FROM true
    OR chosen_score.points_possible IS NULL OR chosen_score.points_possible<=0
    OR chosen_score.points_awarded IS NULL OR chosen_score.attainment_percent IS NULL THEN
    RAISE EXCEPTION USING ERRCODE='55000',MESSAGE='pa_joint_composition_evidence_incomplete';
  END IF;
  INSERT INTO private.pa_report_composition_approvals(
    report_record_id,report_version_id,scoring_review_id,feedback_review_id,
    approved_by,approval_note)
  VALUES(chosen_score.report_record_id,chosen_score.report_version_id,
    chosen_score.id,chosen_feedback.id,auth.uid(),btrim(p_approval_note))
  RETURNING id INTO created;
  INSERT INTO private.security_audit_events(
    actor_id,action,target_type,target_id,outcome,reason_category)
  VALUES(auth.uid(),'pa_private_composition_approved','pa_composition_approval',
    created,'success','human_approved_private');
  RETURN created;
END;
$$;
ALTER FUNCTION public.approve_private_pa_report_composition(uuid,uuid,text) OWNER TO postgres;
REVOKE ALL ON FUNCTION public.approve_private_pa_report_composition(uuid,uuid,text)
  FROM PUBLIC,anon,service_role;
GRANT EXECUTE ON FUNCTION public.approve_private_pa_report_composition(uuid,uuid,text)
  TO authenticated;
COMMENT ON TABLE private.pa_report_composition_approvals IS
  'Immutable Owner+AAL2 joint approval linking independently reviewed human PA score and feedback at one report version; internal only, not learner publication.';
