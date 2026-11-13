-- Owner-only 30-dimension PA report acceptance manifest; never a learner response.
-- Requires immutable joint human approval and verifies rubric, evidence and totals.
CREATE OR REPLACE FUNCTION public.get_private_pa_scored_report_review_manifest(
  p_composition_approval_id uuid
) RETURNS jsonb LANGUAGE plpgsql SECURITY DEFINER SET search_path=''
AS $$
DECLARE
  approval private.pa_report_composition_approvals%ROWTYPE;
  score private.pa_scoring_reviews%ROWTYPE;
  draft private.pa_scoring_drafts%ROWTYPE;
  rubric private.pa_rubric_approvals%ROWTYPE;
  feedback_review private.pa_evaluation_feedback_reviews%ROWTYPE;
  feedback private.pa_evaluation_feedback_drafts%ROWTYPE;
  version_record public.evaluation_report_versions%ROWTYPE;
  observation_audit record;
  dimensions jsonb;
  awarded numeric;
  possible numeric;
BEGIN
  IF auth.uid() IS NULL OR NOT private.current_account_is_active()
    OR NOT private.current_user_has_role('owner'::public.app_role)
    OR coalesce(auth.jwt()->>'aal','aal1') <> 'aal2' THEN
    RAISE EXCEPTION USING ERRCODE='42501',MESSAGE='pa_scored_manifest_forbidden';
  END IF;
  SELECT * INTO approval FROM private.pa_report_composition_approvals
    WHERE id=p_composition_approval_id;
  IF NOT FOUND THEN
    RAISE EXCEPTION USING ERRCODE='P0002',MESSAGE='pa_scored_manifest_approval_not_found';
  END IF;
  SELECT * INTO score FROM private.pa_scoring_reviews WHERE id=approval.scoring_review_id;
  SELECT * INTO draft FROM private.pa_scoring_drafts WHERE id=score.scoring_draft_id;
  SELECT * INTO rubric FROM private.pa_rubric_approvals WHERE id=score.rubric_approval_id;
  SELECT * INTO feedback_review FROM private.pa_evaluation_feedback_reviews
    WHERE id=approval.feedback_review_id;
  SELECT * INTO feedback FROM private.pa_evaluation_feedback_drafts
    WHERE id=feedback_review.draft_id;
  SELECT * INTO version_record FROM public.evaluation_report_versions
    WHERE id=approval.report_version_id AND report_record_id=approval.report_record_id
      AND report_scope='pa_baseline';
  IF score.id IS NULL OR draft.id IS NULL OR rubric.id IS NULL
    OR feedback_review.id IS NULL OR feedback.id IS NULL OR version_record.id IS NULL
    OR score.decision<>'approved_private'
    OR feedback_review.decision<>'approved_for_publication'
    OR score.report_record_id IS DISTINCT FROM approval.report_record_id
    OR score.report_version_id IS DISTINCT FROM approval.report_version_id
    OR draft.report_record_id IS DISTINCT FROM approval.report_record_id
    OR draft.report_version_id IS DISTINCT FROM approval.report_version_id
    OR draft.rubric_approval_id IS DISTINCT FROM rubric.id
    OR feedback_review.report_record_id IS DISTINCT FROM approval.report_record_id
    OR feedback_review.report_version_id IS DISTINCT FROM approval.report_version_id
    OR feedback.report_record_id IS DISTINCT FROM approval.report_record_id
    OR feedback.report_version_id IS DISTINCT FROM approval.report_version_id
    OR rubric.diagnostic_version_id::text IS DISTINCT FROM
       version_record.content_snapshot->>'diagnostic_version_id'
    OR draft.response_evidence_sha256 IS DISTINCT FROM
       encode(extensions.digest(version_record.learner_evidence_snapshot::text,'sha256'),'hex')
    OR version_record.curriculum_mapping_status<>'complete_direct'
    OR version_record.evidence_sufficiency_status<>'sufficient'
  THEN
    RAISE EXCEPTION USING ERRCODE='55000',MESSAGE='pa_scored_manifest_lineage_invalid';
  END IF;
  -- Lock the series for a consistent latest-version/evidence snapshot.
  PERFORM 1 FROM public.evaluation_report_records
    WHERE id=approval.report_record_id AND report_scope='pa_baseline' FOR UPDATE;
  IF NOT FOUND OR EXISTS (
    SELECT 1 FROM public.evaluation_report_versions newer
    WHERE newer.report_record_id=approval.report_record_id
      AND newer.version_number>version_record.version_number
  ) THEN
    RAISE EXCEPTION USING ERRCODE='55000',MESSAGE='pa_scored_manifest_superseded';
  END IF;
  SELECT * INTO observation_audit
    FROM public.inspect_pa_scoring_evidence(approval.report_record_id);
  IF NOT FOUND OR observation_audit.report_version_id IS DISTINCT FROM version_record.id
    OR observation_audit.mapping_and_evidence_complete IS DISTINCT FROM true THEN
    RAISE EXCEPTION USING ERRCODE='55000',MESSAGE='pa_scored_manifest_evidence_incomplete';
  END IF;
  IF jsonb_array_length(draft.dimension_marks)<>30
    OR jsonb_array_length(rubric.dimension_maxima)<>30
    OR (SELECT count(DISTINCT elem->>'code')
      FROM jsonb_array_elements(draft.dimension_marks) elem)<>30
    OR (SELECT count(DISTINCT elem->>'code')
      FROM jsonb_array_elements(rubric.dimension_maxima) elem)<>30
  THEN
    RAISE EXCEPTION USING ERRCODE='55000',MESSAGE='pa_scored_manifest_dimensions_invalid';
  END IF;
  SELECT jsonb_agg(jsonb_build_object(
     'observation_code',mark.elem->>'code',
     'points_awarded',(mark.elem->>'points')::numeric,
     'points_possible',(maxima.elem->>'max_points')::numeric,
     'attainment_percent',round(100*(mark.elem->>'points')::numeric/
       (maxima.elem->>'max_points')::numeric,3))
     ORDER BY mark.ordinality),
     sum((mark.elem->>'points')::numeric),
     sum((maxima.elem->>'max_points')::numeric)
  INTO dimensions,awarded,possible
  FROM jsonb_array_elements(draft.dimension_marks) WITH ORDINALITY AS mark(elem,ordinality)
  JOIN jsonb_array_elements(rubric.dimension_maxima) maxima(elem)
    ON maxima.elem->>'code'=mark.elem->>'code'
  WHERE jsonb_typeof(mark.elem->'points')='number'
    AND jsonb_typeof(maxima.elem->'max_points')='number'
    AND (maxima.elem->>'max_points')::numeric>0
    AND (mark.elem->>'points')::numeric BETWEEN 0 AND (maxima.elem->>'max_points')::numeric;
  IF jsonb_array_length(coalesce(dimensions,'[]'::jsonb))<>30
    OR awarded IS DISTINCT FROM score.points_awarded
    OR possible IS DISTINCT FROM score.points_possible
    OR round(100*awarded/nullif(possible,0),3) IS DISTINCT FROM score.attainment_percent THEN
    RAISE EXCEPTION USING ERRCODE='55000',MESSAGE='pa_scored_manifest_totals_invalid';
  END IF;
  INSERT INTO private.security_audit_events(
    actor_id,action,target_type,target_id,outcome,reason_category)
  VALUES(auth.uid(),'pa_private_scored_manifest_read','pa_composition_approval',
    approval.id,'success','owner_aal2_private_review');
  RETURN jsonb_build_object(
    'status','private_review_only',
    'learner_visible',false,
    'report_record_id',approval.report_record_id,
    'source_report_version_id',version_record.id,
    'composition_approval_id',approval.id,
    'scoring_review_id',score.id,
    'feedback_review_id',feedback_review.id,
    'rubric_sha256',rubric.rubric_sha256,
    'academic_review_reference',rubric.academic_review_reference,
    'assessor_calibration_reference',rubric.assessor_calibration_reference,
    'curriculum_mapping_status',version_record.curriculum_mapping_status,
    'evidence_sufficiency_status',version_record.evidence_sufficiency_status,
    'dimensions',dimensions,
    'dimension_count',30,
    'private_attainment',jsonb_build_object(
      'points_awarded',awarded,'points_possible',possible,
      'attainment_percent',score.attainment_percent),
    'teacher_feedback',feedback.draft_text,
    'official_grade',NULL,'cohort_rank',NULL,'percentile',NULL);
END;
$$;
ALTER FUNCTION public.get_private_pa_scored_report_review_manifest(uuid) OWNER TO postgres;
REVOKE ALL ON FUNCTION public.get_private_pa_scored_report_review_manifest(uuid)
  FROM PUBLIC,anon,service_role;
GRANT EXECUTE ON FUNCTION public.get_private_pa_scored_report_review_manifest(uuid)
  TO authenticated;
COMMENT ON FUNCTION public.get_private_pa_scored_report_review_manifest(uuid) IS
  'Owner+AAL2-only exact-version rubric and feedback reconciliation for private PA report review, never learner publication.';
