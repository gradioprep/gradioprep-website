-- Step 8 private academic-evidence reconciliation inventory. The Founder is
-- the qualified IB MYP reviewer; no duplicate human approval is imposed.
-- This read-only inventory tests persisted version-specific evidence, not
-- reviewer authority or subjective teacher-pack quality.
CREATE OR REPLACE FUNCTION public.inspect_pa_academic_readiness(p_diagnostic_version_id uuid)
RETURNS TABLE (
  observation_code text,
  group_code text,
  learner_capture_enabled boolean,
  reviewed_direct_mapping_present boolean,
  approved_rubric_record_present boolean,
  instrument_release_state text
)
LANGUAGE plpgsql SECURITY DEFINER SET search_path = ''
AS $$
DECLARE
  selected public.diagnostic_versions%ROWTYPE;
BEGIN
  IF auth.uid() IS NULL OR NOT private.current_account_is_active()
    OR NOT private.current_user_has_role('owner'::public.app_role)
    OR coalesce(auth.jwt()->>'aal','aal1') <> 'aal2' THEN
    RAISE EXCEPTION USING ERRCODE='42501', MESSAGE='pa_academic_readiness_forbidden';
  END IF;
  SELECT * INTO selected FROM public.diagnostic_versions
  WHERE id=p_diagnostic_version_id AND diagnostic_code='ib-myp-g9-cycle1';
  IF NOT FOUND THEN
    RAISE EXCEPTION USING ERRCODE='P0002', MESSAGE='pa_instrument_not_found';
  END IF;

  RETURN QUERY
  SELECT o.observation_code::text, o.group_code::text,
    o.learner_capture_enabled,
    EXISTS (
      SELECT 1
      FROM public.diagnostic_observation_outcome_mappings m
      JOIN public.curriculum_unit_versions u
        ON u.id=m.curriculum_unit_version_id
       AND u.route_version_id=selected.route_version_id
       AND u.release_state='published'
      JOIN public.curriculum_unit_outcome_mappings outcome
        ON outcome.id=m.curriculum_unit_outcome_mapping_id
       AND outcome.curriculum_unit_version_id=u.id
      WHERE m.diagnostic_version_id=selected.id
        AND m.diagnostic_observation_id=o.id
        AND m.route_version_id=selected.route_version_id
        AND m.mapping_status='direct'
        AND m.reviewed_by IS NOT NULL AND m.reviewed_at IS NOT NULL
        AND outcome.mapping_status='direct'
        AND outcome.reviewed_by IS NOT NULL AND outcome.reviewed_at IS NOT NULL
    ),
    EXISTS (
      SELECT 1 FROM private.pa_rubric_approvals ra
      WHERE ra.diagnostic_version_id=selected.id
    ),
    selected.release_state::text
  FROM public.diagnostic_observations o
  WHERE o.diagnostic_version_id=selected.id
  ORDER BY o.group_code, o.observation_code;
END;
$$;
ALTER FUNCTION public.inspect_pa_academic_readiness(uuid) OWNER TO postgres;
REVOKE ALL ON FUNCTION public.inspect_pa_academic_readiness(uuid) FROM PUBLIC, anon, service_role;
GRANT EXECUTE ON FUNCTION public.inspect_pa_academic_readiness(uuid) TO authenticated;
COMMENT ON FUNCTION public.inspect_pa_academic_readiness(uuid) IS
 'Owner AAL2 only; 30 version-scoped mapping and rubric evidence flags, not human approval, calibration or publication.';
