-- Staff-only, read-only composition preview joining an approved private human
-- PA score review with a same-version feedback draft. This is NOT publication.
-- No official grade, percentile, learner analytics or external AI is generated.
CREATE OR REPLACE FUNCTION public.get_private_pa_report_composition(
  p_scoring_review_id uuid,p_feedback_draft_id uuid
) RETURNS jsonb LANGUAGE plpgsql SECURITY DEFINER SET search_path=''
AS $$
DECLARE
  chosen private.pa_scoring_reviews%ROWTYPE;
  feedback private.pa_evaluation_feedback_drafts%ROWTYPE;
  report public.evaluation_report_versions%ROWTYPE;
  rubric private.pa_rubric_approvals%ROWTYPE;
  result jsonb;
BEGIN
  IF auth.uid() IS NULL OR NOT private.current_account_is_active()
    OR NOT private.current_user_has_role('owner'::public.app_role)
    OR coalesce(auth.jwt()->>'aal','aal1') <> 'aal2' THEN
    RAISE EXCEPTION USING ERRCODE='42501',MESSAGE='pa_composition_forbidden';
  END IF;
  SELECT * INTO chosen FROM private.pa_scoring_reviews WHERE id=p_scoring_review_id
    AND decision='approved_private';
  IF NOT FOUND THEN
    RAISE EXCEPTION USING ERRCODE='55000',MESSAGE='pa_composition_requires_approved_private_scoring';
  END IF;
  SELECT * INTO feedback FROM private.pa_evaluation_feedback_drafts
    WHERE id=p_feedback_draft_id;
  IF NOT FOUND OR feedback.report_record_id IS DISTINCT FROM chosen.report_record_id
    OR feedback.report_version_id IS DISTINCT FROM chosen.report_version_id THEN
    RAISE EXCEPTION USING ERRCODE='55000',MESSAGE='pa_composition_feedback_version_mismatch';
  END IF;
  SELECT * INTO report FROM public.evaluation_report_versions
    WHERE id=chosen.report_version_id AND report_record_id=chosen.report_record_id
      AND report_scope='pa_baseline';
  IF NOT FOUND OR report.curriculum_mapping_status<>'complete_direct'
    OR report.evidence_sufficiency_status<>'sufficient' THEN
    RAISE EXCEPTION USING ERRCODE='55000',MESSAGE='pa_composition_requires_direct_sufficient_report';
  END IF;
  -- Take the report lock so a new snapshot cannot be inserted while composing.
  PERFORM 1 FROM public.evaluation_report_records
    WHERE id=chosen.report_record_id FOR UPDATE;
  IF EXISTS (SELECT 1 FROM public.evaluation_report_versions newer
    WHERE newer.report_record_id=chosen.report_record_id
      AND newer.version_number>report.version_number) THEN
    RAISE EXCEPTION USING ERRCODE='55000',MESSAGE='pa_composition_report_superseded';
  END IF;
  SELECT * INTO rubric FROM private.pa_rubric_approvals
    WHERE id=chosen.rubric_approval_id;
  IF NOT FOUND OR rubric.diagnostic_version_id::text IS DISTINCT FROM
      report.content_snapshot->>'diagnostic_version_id'
    OR chosen.points_possible IS NULL OR chosen.points_possible<=0
    OR chosen.points_awarded IS NULL OR chosen.attainment_percent IS NULL THEN
    RAISE EXCEPTION USING ERRCODE='55000',MESSAGE='pa_composition_invalid_scoring_lineage';
  END IF;
  result := jsonb_build_object(
    'status','private_composition_pending_teacher_publication_review',
    'report_record_id',chosen.report_record_id,
    'report_version_id',chosen.report_version_id,
    'rubric_sha256',rubric.rubric_sha256,
    'academic_review_reference',rubric.academic_review_reference,
    'assessor_calibration_reference',rubric.assessor_calibration_reference,
    'mapping_status',report.curriculum_mapping_status,
    'evidence_status',report.evidence_sufficiency_status,
    'curriculum_mapping',report.curriculum_mapping_snapshot,
    'scoring_review_id',chosen.id,
    'scoring_draft_id',chosen.scoring_draft_id,
    'private_attainment',jsonb_build_object(
      'points_awarded',chosen.points_awarded,
      'points_possible',chosen.points_possible,
      'attainment_percent',chosen.attainment_percent),
    'feedback_draft_id',feedback.id,
    'feedback_draft_text',feedback.draft_text,
    'learner_visible',false,
    'official_grade',NULL,'cohort_rank',NULL,'percentile',NULL);
  INSERT INTO private.security_audit_events(
    actor_id,action,target_type,target_id,outcome,reason_category)
  VALUES(auth.uid(),'pa_private_report_composition_read',
    'evaluation_report',chosen.report_record_id,'success','owner_aal2_private_handoff');
  RETURN result;
END;
$$;
ALTER FUNCTION public.get_private_pa_report_composition(uuid,uuid) OWNER TO postgres;
REVOKE ALL ON FUNCTION public.get_private_pa_report_composition(uuid,uuid)
  FROM PUBLIC,anon,service_role;
GRANT EXECUTE ON FUNCTION public.get_private_pa_report_composition(uuid,uuid)
  TO authenticated;
COMMENT ON FUNCTION public.get_private_pa_report_composition(uuid,uuid) IS
  'Owner AAL2 private human-approved score and same-version teacher feedback draft handoff; never learner published.';
