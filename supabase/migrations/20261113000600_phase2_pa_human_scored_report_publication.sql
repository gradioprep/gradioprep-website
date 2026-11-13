-- Explicit Owner+AAL2 publication of an academically and human-reviewed PA result.
-- Unlike the feedback-only publication RPC, this requires joint score+feedback
-- approval, complete 30-observation evidence and a reconciled private manifest.
-- It never calculates official IB grades, rank, cut scores, or AI explanations.
CREATE OR REPLACE FUNCTION public.publish_approved_pa_scored_report(
  p_composition_approval_id uuid,p_idempotency_key uuid
) RETURNS TABLE(report_record_id uuid,report_version_id uuid,version_number integer,is_replay boolean)
LANGUAGE plpgsql SECURITY DEFINER SET search_path=''
AS $$
DECLARE
  chosen private.pa_report_composition_approvals%ROWTYPE;
  source_version public.evaluation_report_versions%ROWTYPE;
  existing_version public.evaluation_report_versions%ROWTYPE;
  created_version public.evaluation_report_versions%ROWTYPE;
  manifest jsonb;
  source_learner uuid;
BEGIN
  IF auth.uid() IS NULL OR NOT private.current_account_is_active()
    OR NOT private.current_user_has_role('owner'::public.app_role)
    OR coalesce(auth.jwt()->>'aal','aal1') <> 'aal2' THEN
    RAISE EXCEPTION USING ERRCODE='42501',MESSAGE='pa_scored_publication_forbidden';
  END IF;
  IF p_composition_approval_id IS NULL OR p_idempotency_key IS NULL THEN
    RAISE EXCEPTION USING ERRCODE='22023',MESSAGE='invalid_pa_scored_publication';
  END IF;
  SELECT * INTO chosen FROM private.pa_report_composition_approvals
    WHERE id=p_composition_approval_id;
  IF NOT FOUND THEN
    RAISE EXCEPTION USING ERRCODE='55000',MESSAGE='pa_scored_publication_requires_joint_approval';
  END IF;
  SELECT learner_id INTO source_learner FROM public.evaluation_report_records
    WHERE id=chosen.report_record_id AND report_scope='pa_baseline' FOR UPDATE;
  IF source_learner IS NULL THEN
    RAISE EXCEPTION USING ERRCODE='55000',MESSAGE='pa_scored_publication_invalid_report';
  END IF;
  SELECT * INTO source_version FROM public.evaluation_report_versions
    WHERE id=chosen.report_version_id AND report_record_id=chosen.report_record_id
      AND learner_id=source_learner AND report_scope='pa_baseline';
  IF NOT FOUND THEN
    RAISE EXCEPTION USING ERRCODE='55000',MESSAGE='pa_scored_publication_invalid_lineage';
  END IF;
  SELECT * INTO existing_version FROM public.evaluation_report_versions
    WHERE learner_id=source_learner AND idempotency_key=p_idempotency_key;
  IF FOUND THEN
    IF existing_version.report_record_id IS DISTINCT FROM source_version.report_record_id
      OR existing_version.eligible_analytics_snapshot->'pa_human_scoring'->>'composition_approval_id'
         IS DISTINCT FROM chosen.id::text
      OR existing_version.published_feedback_snapshot->>'status'<>'human_approved_published' THEN
      RAISE EXCEPTION USING ERRCODE='P0001',MESSAGE='pa_scored_publication_idempotency_conflict';
    END IF;
    RETURN QUERY SELECT existing_version.report_record_id,existing_version.id,
      existing_version.version_number,true;
    RETURN;
  END IF;
  IF EXISTS (SELECT 1 FROM public.evaluation_report_versions v
    WHERE v.report_record_id=chosen.report_record_id
      AND v.version_number>source_version.version_number) THEN
    RAISE EXCEPTION USING ERRCODE='55000',MESSAGE='pa_scored_publication_report_superseded';
  END IF;
  -- Recompute every dimension and revalidate version/evidence under the same lock.
  manifest := public.get_private_pa_scored_report_review_manifest(chosen.id);
  IF manifest->>'source_report_version_id' IS DISTINCT FROM source_version.id::text
    OR (manifest->>'dimension_count')::integer<>30
    OR manifest->>'learner_visible'<>'false'
    OR manifest->>'curriculum_mapping_status'<>'complete_direct'
    OR manifest->>'evidence_sufficiency_status'<>'sufficient'
    OR jsonb_array_length(manifest->'dimensions')<>30 THEN
    RAISE EXCEPTION USING ERRCODE='55000',MESSAGE='pa_scored_publication_manifest_invalid';
  END IF;
  IF EXISTS(SELECT 1 FROM public.evaluation_report_versions v
    WHERE v.report_record_id=chosen.report_record_id AND
      v.eligible_analytics_snapshot->'pa_human_scoring'->>'composition_approval_id'=chosen.id::text) THEN
    RAISE EXCEPTION USING ERRCODE='P0001',MESSAGE='pa_scored_publication_already_published';
  END IF;
  INSERT INTO public.evaluation_report_versions(
    report_record_id,report_scope,learner_id,version_number,idempotency_key,supersedes_version_id,
    curriculum_mapping_status,evidence_sufficiency_status,scope_snapshot,content_snapshot,
    unit_set_snapshot,curriculum_mapping_snapshot,learner_evidence_snapshot,
    published_feedback_snapshot,eligible_analytics_snapshot,created_by)
  VALUES(
    source_version.report_record_id,source_version.report_scope,source_version.learner_id,
    source_version.version_number+1,p_idempotency_key,source_version.id,
    source_version.curriculum_mapping_status,source_version.evidence_sufficiency_status,
    source_version.scope_snapshot,source_version.content_snapshot,source_version.unit_set_snapshot,
    source_version.curriculum_mapping_snapshot,source_version.learner_evidence_snapshot,
    jsonb_build_object('status','human_approved_published',
      'review_id',chosen.feedback_review_id,'feedback_text',manifest->>'teacher_feedback',
      'approved_at',chosen.approved_at,
      'source_report_version_id',source_version.id),
    source_version.eligible_analytics_snapshot || jsonb_build_object(
      'pa_human_scoring',jsonb_build_object(
        'status','human_approved',
        'source_report_version_id',source_version.id,
        'composition_approval_id',chosen.id,
        'rubric_sha256',manifest->>'rubric_sha256',
        'dimension_count',30,
        'dimensions',manifest->'dimensions',
        'points_awarded',manifest->'private_attainment'->'points_awarded',
        'points_possible',manifest->'private_attainment'->'points_possible',
        'attainment_percent',manifest->'private_attainment'->'attainment_percent',
        'official_ib_grade',NULL,'percentile',NULL,'rank',NULL)),auth.uid()
  ) RETURNING * INTO created_version;
  INSERT INTO private.security_audit_events(
    actor_id,action,target_type,target_id,outcome,reason_category)
  VALUES(auth.uid(),'pa_scored_report_published','evaluation_report_version',
    created_version.id,'success','owner_joint_approved_report');
  RETURN QUERY SELECT created_version.report_record_id,created_version.id,
    created_version.version_number,false;
END;
$$;
ALTER FUNCTION public.publish_approved_pa_scored_report(uuid,uuid) OWNER TO postgres;
REVOKE ALL ON FUNCTION public.publish_approved_pa_scored_report(uuid,uuid)
 FROM PUBLIC,anon,service_role;
GRANT EXECUTE ON FUNCTION public.publish_approved_pa_scored_report(uuid,uuid)
 TO authenticated;
COMMENT ON FUNCTION public.publish_approved_pa_scored_report(uuid,uuid) IS
 'Owner+AAL2 joint human-approved PA scored report publication; immutable learner report version, rubric-bound attainment only, no official grade or ranking.';
