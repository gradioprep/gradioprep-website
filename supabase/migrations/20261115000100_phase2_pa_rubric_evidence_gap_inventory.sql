-- Owner-only exact-version rubric-evidence reconciliation for Step 8.
-- Founder approval authority is already recorded; these are persisted-evidence
-- checks only. Private teacher-pack correctness and witnessed calibration cannot
-- be inferred from an approval reference or a database row.
CREATE FUNCTION public.inspect_pa_rubric_evidence_gaps(p_diagnostic_version_id uuid)
RETURNS TABLE (
  observation_code text,
  group_code text,
  reviewed_direct_mapping_present boolean,
  learner_capture_enabled boolean,
  numeric_maximum_recorded boolean,
  rubric_reference_recorded boolean,
  calibration_reference_recorded boolean,
  rubric_record_count integer,
  instrument_release_state text
)
LANGUAGE plpgsql SECURITY DEFINER SET search_path=''
AS $$
BEGIN
  -- Reuse the existing inventory's Owner/AAL2, account and instrument checks.
  -- Explicitly perform the call before any private rubric lookup.
  PERFORM 1 FROM public.inspect_pa_academic_readiness(p_diagnostic_version_id);
  RETURN QUERY
  WITH inventory AS (
    SELECT * FROM public.inspect_pa_academic_readiness(p_diagnostic_version_id)
  ), rubric AS (
    SELECT r.id, r.dimension_maxima, r.academic_review_reference,
      r.assessor_calibration_reference,
      (jsonb_array_length(r.dimension_maxima)=30
       AND (SELECT count(DISTINCT d->>'code') FROM
         jsonb_array_elements(r.dimension_maxima) d)=30
       AND NOT EXISTS (
         SELECT 1 FROM jsonb_array_elements(r.dimension_maxima) d
         WHERE jsonb_typeof(d) <> 'object'
           OR jsonb_typeof(d->'code') IS DISTINCT FROM 'string'
           OR jsonb_typeof(d->'max_points') IS DISTINCT FROM 'number'
           OR (d->>'max_points')::numeric <= 0
           OR (d->>'max_points')::numeric > 100
       )) AS valid_maxima
    FROM private.pa_rubric_approvals r
    WHERE r.diagnostic_version_id=p_diagnostic_version_id
  ), counted AS (
    SELECT count(*)::integer AS n FROM rubric
  )
  SELECT i.observation_code,i.group_code,i.reviewed_direct_mapping_present,
    i.learner_capture_enabled,
    EXISTS (
      SELECT 1 FROM rubric r
      JOIN LATERAL jsonb_array_elements(r.dimension_maxima) d ON true
      WHERE r.valid_maxima AND d->>'code'=i.observation_code
        AND EXISTS (
          SELECT 1 FROM public.diagnostic_observations o
          WHERE o.diagnostic_version_id=p_diagnostic_version_id
            AND o.observation_code=d->>'code'
        )
    ),
    EXISTS (SELECT 1 FROM rubric r WHERE length(btrim(r.academic_review_reference))>=12),
    EXISTS (SELECT 1 FROM rubric r WHERE length(btrim(r.assessor_calibration_reference))>=12),
    c.n,i.instrument_release_state
  FROM inventory i CROSS JOIN counted c
  ORDER BY i.group_code,i.observation_code;
END;
$$;
ALTER FUNCTION public.inspect_pa_rubric_evidence_gaps(uuid) OWNER TO postgres;
REVOKE ALL ON FUNCTION public.inspect_pa_rubric_evidence_gaps(uuid)
  FROM PUBLIC,anon,service_role;
GRANT EXECUTE ON FUNCTION public.inspect_pa_rubric_evidence_gaps(uuid) TO authenticated;
COMMENT ON FUNCTION public.inspect_pa_rubric_evidence_gaps(uuid) IS
 'Owner AAL2 only; exact-version 30-dimension numeric rubric completeness and reference presence. Does not attest to source, private teacher-pack review, or witnessed calibration.';
