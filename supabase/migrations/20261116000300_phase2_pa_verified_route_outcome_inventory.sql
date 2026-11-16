-- Owner-only readback for exact school route sources; no extra authoring rights.
CREATE FUNCTION public.list_pa_verified_route_outcomes(p_diagnostic_version_id uuid)
RETURNS TABLE (
  outcome_mapping_id uuid,unit_code text,outcome_reference text,
  outcome_title text,source_locator text
) LANGUAGE plpgsql SECURITY DEFINER SET search_path=''
AS $$
DECLARE
  instrument public.diagnostic_versions%ROWTYPE;
BEGIN
  IF auth.uid() IS NULL OR NOT private.current_account_is_active()
    OR NOT private.current_user_has_role('owner'::public.app_role)
    OR coalesce(auth.jwt()->>'aal','aal1') <> 'aal2' THEN
    RAISE EXCEPTION USING ERRCODE='42501',MESSAGE='pa_outcome_inventory_forbidden';
  END IF;
  SELECT * INTO instrument FROM public.diagnostic_versions
  WHERE id=p_diagnostic_version_id AND diagnostic_code='ib-myp-g9-cycle1';
  IF NOT FOUND THEN
    RAISE EXCEPTION USING ERRCODE='P0002',MESSAGE='pa_instrument_not_found';
  END IF;
  IF NOT EXISTS(SELECT 1 FROM public.curriculum_route_versions r
    WHERE r.id=instrument.route_version_id
      AND r.route_key=instrument.pathway_id AND r.review_state='verified') THEN
    RETURN;
  END IF;
  RETURN QUERY SELECT outcome.id,unit.unit_code::text,
    outcome.outcome_reference::text,outcome.outcome_title::text,
    outcome.source_locator::text
  FROM public.curriculum_unit_versions unit
  JOIN public.curriculum_unit_outcome_mappings outcome
    ON outcome.curriculum_unit_version_id=unit.id
  WHERE unit.route_version_id=instrument.route_version_id
    AND unit.release_state='published' AND outcome.mapping_status='direct'
    AND outcome.reviewed_by IS NOT NULL AND outcome.reviewed_at IS NOT NULL
    AND char_length(btrim(outcome.source_locator))>0
  ORDER BY unit.sequence_number,outcome.outcome_reference,outcome.id
  LIMIT 500;
END;
$$;
ALTER FUNCTION public.list_pa_verified_route_outcomes(uuid) OWNER TO postgres;
REVOKE ALL ON FUNCTION public.list_pa_verified_route_outcomes(uuid)
  FROM PUBLIC,anon,service_role;
GRANT EXECUTE ON FUNCTION public.list_pa_verified_route_outcomes(uuid)
  TO authenticated;
