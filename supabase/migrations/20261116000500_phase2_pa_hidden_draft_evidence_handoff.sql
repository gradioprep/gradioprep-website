-- Academic evidence is prepared against an unpublished, non-capturing PA draft.
-- Keep learner capture disabled until verified records and separate publication gates
-- are complete. No synthetic mappings or academic approvals are generated here.
-- Owner+AAL2, 30 DIRECT links, exact route, rubric hashes and private receipts
-- remain required; this migration only removes the unsafe circular dependency.

CREATE OR REPLACE FUNCTION public.approve_pa_scoring_rubric(
  p_diagnostic_version_id uuid,p_rubric_sha256 text,p_dimension_maxima jsonb,
  p_academic_review_reference text,p_assessor_calibration_reference text,p_approval_note text
) RETURNS uuid LANGUAGE plpgsql SECURITY DEFINER SET search_path=''
AS $$
DECLARE
  selected public.diagnostic_versions%ROWTYPE;
  approved_id uuid;
BEGIN
  IF auth.uid() IS NULL OR NOT private.current_account_is_active()
    OR NOT private.current_user_has_role('owner'::public.app_role)
    OR coalesce(auth.jwt()->>'aal','aal1') <> 'aal2' THEN
    RAISE EXCEPTION USING ERRCODE='42501',MESSAGE='pa_rubric_approval_forbidden';
  END IF;
  IF p_diagnostic_version_id IS NULL OR p_rubric_sha256 IS NULL
    OR p_rubric_sha256 !~ '^[a-f0-9]{64}$'
    OR jsonb_typeof(p_dimension_maxima) IS DISTINCT FROM 'array'
    OR jsonb_array_length(p_dimension_maxima) <> 30
    OR char_length(btrim(coalesce(p_academic_review_reference,''))) NOT BETWEEN 12 AND 500
    OR char_length(btrim(coalesce(p_assessor_calibration_reference,''))) NOT BETWEEN 12 AND 500
    OR char_length(btrim(coalesce(p_approval_note,''))) NOT BETWEEN 20 AND 1000 THEN
    RAISE EXCEPTION USING ERRCODE='22023',MESSAGE='invalid_pa_rubric_approval';
  END IF;
  SELECT * INTO selected FROM public.diagnostic_versions
    WHERE id=p_diagnostic_version_id AND release_state IN ('draft','published')
      AND diagnostic_code='ib-myp-g9-cycle1';
  IF NOT FOUND THEN
    RAISE EXCEPTION USING ERRCODE='55000',MESSAGE='pa_rubric_requires_published_reviewed_instrument';
  END IF;
  -- Allow an exact, privately reviewed 30-dimension rubric to be entered
  -- BEFORE the instrument is published. Otherwise requiring a published
  -- instrument would make a safe prepublication evidence gate impossible.
  IF selected.release_state='draft' AND (
    NOT EXISTS (SELECT 1 FROM public.curriculum_route_versions r
      WHERE r.id=selected.route_version_id AND r.review_state='verified'
        AND r.route_key=selected.pathway_id)
    OR (SELECT count(*) FROM public.inspect_pa_academic_readiness(selected.id))<>30
    OR (SELECT count(*) FROM public.inspect_pa_academic_readiness(selected.id)
      WHERE reviewed_direct_mapping_present)<>30
  ) THEN
    RAISE EXCEPTION USING ERRCODE='55000',
      MESSAGE='pa_rubric_requires_published_reviewed_instrument';
  END IF;
  IF EXISTS (
    SELECT 1 FROM jsonb_array_elements(p_dimension_maxima) AS dim
    WHERE jsonb_typeof(dim) <> 'object'
       OR jsonb_typeof(dim->'code') IS DISTINCT FROM 'string'
       OR jsonb_typeof(dim->'max_points') IS DISTINCT FROM 'number'
       OR (dim->>'max_points')::numeric <= 0
       OR (dim->>'max_points')::numeric > 100
  ) OR (
    SELECT count(DISTINCT dim->>'code') FROM jsonb_array_elements(p_dimension_maxima) AS dim
  ) <> 30 OR EXISTS (
    SELECT 1 FROM jsonb_array_elements(p_dimension_maxima) AS dim
    WHERE NOT EXISTS (
      SELECT 1 FROM public.diagnostic_observations AS o
      WHERE o.diagnostic_version_id=selected.id
        AND o.observation_code=dim->>'code'
        AND o.group_code<>'L'
    )
  ) THEN
    RAISE EXCEPTION USING ERRCODE='22023',MESSAGE='pa_rubric_dimensions_invalid';
  END IF;
  INSERT INTO private.pa_rubric_approvals(
    diagnostic_version_id,rubric_sha256,dimension_maxima,academic_review_reference,
    assessor_calibration_reference,approval_note,approved_by)
  VALUES(p_diagnostic_version_id,p_rubric_sha256,p_dimension_maxima,
    btrim(p_academic_review_reference),btrim(p_assessor_calibration_reference),
    btrim(p_approval_note),auth.uid())
  RETURNING id INTO approved_id;
  INSERT INTO private.security_audit_events(actor_id,action,target_type,target_id,outcome,reason_category)
  VALUES(auth.uid(),'pa_rubric_approved','pa_rubric_approval',approved_id,'success','human_approved_private');
  RETURN approved_id;
END;
$$;

CREATE OR REPLACE FUNCTION public.record_pa_release_evidence(
  p_diagnostic_version_id uuid,
  p_rubric_approval_id uuid,
  p_route_source_reference text,
  p_review_bundle_sha256 text,
  p_direct_mapping_sha256 text,
  p_restricted_teacher_packs_sha256 text,
  p_calibration_evidence_sha256 text,
  p_evidence_note text
) RETURNS uuid
LANGUAGE plpgsql SECURITY DEFINER SET search_path=''
AS $$
DECLARE
  rub private.pa_rubric_approvals%ROWTYPE;
  version public.diagnostic_versions%ROWTYPE;
  recorded_id uuid;
BEGIN
  IF auth.uid() IS NULL OR NOT private.current_account_is_active()
    OR NOT private.current_user_has_role('owner'::public.app_role)
    OR coalesce(auth.jwt()->>'aal','aal1') <> 'aal2' THEN
    RAISE EXCEPTION USING ERRCODE='42501',MESSAGE='pa_release_evidence_forbidden';
  END IF;
  IF p_diagnostic_version_id IS NULL OR p_rubric_approval_id IS NULL
    OR char_length(btrim(coalesce(p_route_source_reference,''))) NOT BETWEEN 20 AND 500
    OR p_review_bundle_sha256 IS NULL OR p_review_bundle_sha256 !~ '^[a-f0-9]{64}$'
    OR p_direct_mapping_sha256 IS NULL OR p_direct_mapping_sha256 !~ '^[a-f0-9]{64}$'
    OR p_restricted_teacher_packs_sha256 IS NULL OR p_restricted_teacher_packs_sha256 !~ '^[a-f0-9]{64}$'
    OR p_calibration_evidence_sha256 IS NULL OR p_calibration_evidence_sha256 !~ '^[a-f0-9]{64}$'
    OR char_length(btrim(coalesce(p_evidence_note,''))) NOT BETWEEN 30 AND 1000 THEN
    RAISE EXCEPTION USING ERRCODE='22023',MESSAGE='invalid_pa_release_evidence';
  END IF;
  SELECT * INTO version FROM public.diagnostic_versions
    WHERE id=p_diagnostic_version_id AND diagnostic_code='ib-myp-g9-cycle1'
      AND release_state='draft' FOR UPDATE;
  IF NOT FOUND THEN
    RAISE EXCEPTION USING ERRCODE='55000',MESSAGE='pa_release_requires_unpublished_instrument';
  END IF;
  SELECT * INTO rub FROM private.pa_rubric_approvals
    WHERE id=p_rubric_approval_id AND diagnostic_version_id=version.id;
  IF NOT FOUND THEN
    RAISE EXCEPTION USING ERRCODE='55000',MESSAGE='pa_release_requires_exact_rubric';
  END IF;
  IF NOT EXISTS(SELECT 1 FROM public.curriculum_route_versions r
      WHERE r.id=version.route_version_id AND r.review_state='verified'
        AND r.route_key=version.pathway_id)
    OR (SELECT count(*) FROM public.inspect_pa_academic_readiness(version.id))<>30
    OR (SELECT count(*) FROM public.inspect_pa_academic_readiness(version.id)
      WHERE reviewed_direct_mapping_present
        AND group_code <> 'L')<>30
    OR jsonb_array_length(rub.dimension_maxima)<>30
    OR (SELECT count(DISTINCT elem->>'code')
      FROM jsonb_array_elements(rub.dimension_maxima) elem)<>30
    OR EXISTS(SELECT 1 FROM public.diagnostic_observations o
      WHERE o.diagnostic_version_id=version.id AND NOT EXISTS(
        SELECT 1 FROM jsonb_array_elements(rub.dimension_maxima) dim
        WHERE dim->>'code'=o.observation_code
          AND jsonb_typeof(dim->'max_points')='number'
          AND (dim->>'max_points')::numeric>0
          AND (dim->>'max_points')::numeric<=100
      )) THEN
    RAISE EXCEPTION USING ERRCODE='55000',MESSAGE='pa_release_requires_complete_academic_evidence';
  END IF;
  INSERT INTO private.pa_release_evidence_receipts(
    diagnostic_version_id,rubric_approval_id,route_source_reference,
    review_bundle_sha256,direct_mapping_sha256,restricted_teacher_packs_sha256,
    calibration_evidence_sha256,evidence_note,recorded_by)
  VALUES (version.id,rub.id,btrim(p_route_source_reference),
    p_review_bundle_sha256,p_direct_mapping_sha256,
    p_restricted_teacher_packs_sha256,p_calibration_evidence_sha256,
    btrim(p_evidence_note),auth.uid())
  RETURNING id INTO recorded_id;
  INSERT INTO private.security_audit_events(
    actor_id,action,target_type,target_id,outcome,reason_category)
  VALUES (auth.uid(),'pa_release_evidence_recorded','pa_release_evidence_receipt',
    recorded_id,'success','qualified_founder_exact_version_evidence');
  RETURN recorded_id;
END;
$$;
