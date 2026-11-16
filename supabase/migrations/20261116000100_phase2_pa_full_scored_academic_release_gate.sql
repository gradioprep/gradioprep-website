-- Step 8 full-PA defence in depth: an approved scored-report manifest is
-- insufficient unless the exact released Year 4 instrument has its own
-- authorised academic release receipt and matching thirty-number rubric.
-- No curriculum records, teacher keys, score anchors or calibration examples
-- are inferred or seeded. This is a pre-publication assertion only.
CREATE FUNCTION private.assert_pa_full_scored_release_ready(
  p_diagnostic_version_id uuid, p_rubric_sha256 text
) RETURNS void LANGUAGE plpgsql SECURITY DEFINER SET search_path=''
AS $$
DECLARE
  instrument public.diagnostic_versions%ROWTYPE;
  mapped_count integer;
  observation_count integer;
BEGIN
  SELECT * INTO instrument FROM public.diagnostic_versions
    WHERE id=p_diagnostic_version_id AND diagnostic_code='ib-myp-g9-cycle1';
  IF NOT FOUND OR instrument.release_state<>'published'
    OR p_rubric_sha256 !~ '^[a-f0-9]{64}$' THEN
    RAISE EXCEPTION USING ERRCODE='55000',
      MESSAGE='pa_full_scored_report_requires_academic_evidence';
  END IF;
  SELECT count(*)::integer,
    count(*) FILTER (WHERE o.learner_capture_enabled AND o.group_code<>'L'
      AND EXISTS(
        SELECT 1 FROM public.diagnostic_observation_outcome_mappings m
        JOIN public.curriculum_unit_versions u ON u.id=m.curriculum_unit_version_id
          AND u.route_version_id=instrument.route_version_id AND u.release_state='published'
        JOIN public.curriculum_unit_outcome_mappings outcome
          ON outcome.id=m.curriculum_unit_outcome_mapping_id
            AND outcome.curriculum_unit_version_id=u.id
        WHERE m.diagnostic_observation_id=o.id
          AND m.diagnostic_version_id=instrument.id
          AND m.route_version_id=instrument.route_version_id
          AND m.mapping_status='direct' AND m.reviewed_by IS NOT NULL
          AND m.reviewed_at IS NOT NULL AND outcome.mapping_status='direct'
          AND outcome.reviewed_by IS NOT NULL AND outcome.reviewed_at IS NOT NULL
      ))::integer
    INTO observation_count,mapped_count
  FROM public.diagnostic_observations o
  WHERE o.diagnostic_version_id=instrument.id;
  IF observation_count<>30 OR mapped_count<>30
    OR NOT EXISTS(SELECT 1 FROM public.curriculum_route_versions route
      WHERE route.id=instrument.route_version_id
        AND route.route_key=instrument.pathway_id AND route.review_state='verified')
    OR NOT EXISTS(
      SELECT 1 FROM private.pa_release_evidence_receipts receipt
      JOIN private.pa_rubric_approvals rub ON rub.id=receipt.rubric_approval_id
      WHERE receipt.diagnostic_version_id=instrument.id
        AND rub.diagnostic_version_id=instrument.id
        AND rub.rubric_sha256=p_rubric_sha256
        AND jsonb_array_length(rub.dimension_maxima)=30
        AND (SELECT count(DISTINCT item->>'code')
          FROM jsonb_array_elements(rub.dimension_maxima) item)=30
    ) THEN
    RAISE EXCEPTION USING ERRCODE='55000',
      MESSAGE='pa_full_scored_report_requires_academic_evidence';
  END IF;
END;
$$;
ALTER FUNCTION private.assert_pa_full_scored_release_ready(uuid,text) OWNER TO postgres;
REVOKE ALL ON FUNCTION private.assert_pa_full_scored_release_ready(uuid,text)
  FROM PUBLIC,anon,authenticated,service_role;

-- Bind scored publication to the submitted learner instrument, not to a
-- potentially incomplete, stale or mislabeled report snapshot. The exact
-- 30 distinct observation codes must match the instrument's own catalogue.
-- This is a pure validation helper; it does not create academic evidence.
CREATE FUNCTION private.assert_pa_myp4_scored_snapshot(
  p_attempt_version_id uuid,p_snapshot_version_id uuid,p_observations jsonb
) RETURNS void LANGUAGE plpgsql SECURITY DEFINER SET search_path=''
AS $$
DECLARE
  actual_codes integer;
  snapshot_codes integer;
  matching_codes integer;
BEGIN
  IF p_attempt_version_id IS DISTINCT FROM p_snapshot_version_id
    OR jsonb_typeof(p_observations) IS DISTINCT FROM 'array' THEN
    RAISE EXCEPTION USING ERRCODE='55000',
      MESSAGE='pa_full_scored_report_instrument_lineage_mismatch';
  END IF;
  SELECT count(*)::integer INTO actual_codes
  FROM public.diagnostic_observations
  WHERE diagnostic_version_id=p_attempt_version_id;
  SELECT count(DISTINCT item->>'observation_code')::integer,
    count(*) FILTER (WHERE EXISTS (
      SELECT 1 FROM public.diagnostic_observations obs
      WHERE obs.diagnostic_version_id=p_attempt_version_id
        AND obs.observation_code=item->>'observation_code'
    ))::integer
    INTO snapshot_codes,matching_codes
  FROM jsonb_array_elements(p_observations) AS item;
  IF actual_codes<>30 OR jsonb_array_length(p_observations)<>30
     OR snapshot_codes<>30 OR matching_codes<>30 THEN
    RAISE EXCEPTION USING ERRCODE='55000',
      MESSAGE='pa_full_scored_report_instrument_lineage_mismatch';
  END IF;
END;
$$;
ALTER FUNCTION private.assert_pa_myp4_scored_snapshot(uuid,uuid,jsonb)
  OWNER TO postgres;
REVOKE ALL ON FUNCTION private.assert_pa_myp4_scored_snapshot(uuid,uuid,jsonb)
  FROM PUBLIC,anon,authenticated,service_role;

-- Preserve the existing human-scoring, joint approval and immutable publishing
-- implementation; insert only the exact-version academic release assertions.
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
  actual_instrument_id uuid;
  actual_instrument_code text;
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
  SELECT v.* INTO source_version FROM public.evaluation_report_versions AS v
    WHERE v.id=chosen.report_version_id AND v.report_record_id=chosen.report_record_id
      AND v.learner_id=source_learner AND v.report_scope='pa_baseline';
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
  -- Resolve the source instrument from the immutable submitted attempt, not
  -- from user-facing report JSON. This check also catches missing/altered
  -- observation lists and a misleading diagnostic_version_id snapshot.
  SELECT a.diagnostic_version_id,dv.diagnostic_code
    INTO actual_instrument_id,actual_instrument_code
  FROM public.evaluation_report_records er
  JOIN public.diagnostic_attempts a ON a.id=er.diagnostic_attempt_id
  JOIN public.diagnostic_versions dv ON dv.id=a.diagnostic_version_id
  WHERE er.id=source_version.report_record_id
    AND er.report_scope='pa_baseline'
    AND a.learner_id=source_version.learner_id;
  IF NOT FOUND THEN
    RAISE EXCEPTION USING ERRCODE='55000',
      MESSAGE='pa_full_scored_report_instrument_lineage_mismatch';
  END IF;
  IF actual_instrument_code='ib-myp-g9-cycle1' THEN
    PERFORM private.assert_pa_myp4_scored_snapshot(
      actual_instrument_id,
      CASE WHEN (source_version.content_snapshot->>'diagnostic_version_id')
         ~* '^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$'
        THEN (source_version.content_snapshot->>'diagnostic_version_id')::uuid
        ELSE NULL END,
      source_version.content_snapshot->'observations');
  END IF;
  -- Recompute every dimension and revalidate version/evidence under the same lock.
  manifest := public.get_private_pa_scored_report_review_manifest(chosen.id);
  IF actual_instrument_code='ib-myp-g9-cycle1' THEN
    PERFORM private.assert_pa_full_scored_release_ready(
      actual_instrument_id,manifest->>'rubric_sha256');
  END IF;
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
