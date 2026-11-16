-- Step 8: atomic exact-version curriculum mapping handoff using genuine
-- already-reviewed route/unit/outcome records. No inferred source or approval.
CREATE FUNCTION public.record_pa_verified_direct_crosswalk(
  p_diagnostic_version_id uuid, p_mappings jsonb
) RETURNS integer LANGUAGE plpgsql SECURITY DEFINER SET search_path=''
AS $$
DECLARE
  instrument public.diagnostic_versions%ROWTYPE;
  item jsonb;
  code text;
  outcome_id uuid;
  note text;
  count_written integer := 0;
BEGIN
  IF auth.uid() IS NULL OR NOT private.current_account_is_active()
    OR NOT private.current_user_has_role('owner'::public.app_role)
    OR coalesce(auth.jwt()->>'aal','aal1') <> 'aal2' THEN
    RAISE EXCEPTION USING ERRCODE='42501', MESSAGE='pa_mapping_handoff_forbidden';
  END IF;
  IF p_diagnostic_version_id IS NULL OR jsonb_typeof(p_mappings) IS DISTINCT FROM 'array'
    OR jsonb_array_length(p_mappings)<>30 THEN
    RAISE EXCEPTION USING ERRCODE='22023', MESSAGE='pa_crosswalk_requires_30_links';
  END IF;
  SELECT * INTO instrument FROM public.diagnostic_versions
    WHERE id=p_diagnostic_version_id AND diagnostic_code='ib-myp-g9-cycle1'
      AND release_state='draft' FOR UPDATE;
  IF NOT FOUND OR NOT EXISTS(
    SELECT 1 FROM public.curriculum_route_versions r
    WHERE r.id=instrument.route_version_id
      AND r.route_key=instrument.pathway_id AND r.review_state='verified'
  ) OR (SELECT count(*) FROM public.diagnostic_observations o
        WHERE o.diagnostic_version_id=instrument.id AND o.group_code<>'L')<>30
    OR EXISTS(SELECT 1 FROM public.diagnostic_observations o
        WHERE o.diagnostic_version_id=instrument.id AND (o.group_code='L'
          OR NOT o.learner_capture_enabled))
    OR EXISTS(SELECT 1 FROM public.diagnostic_observation_outcome_mappings m
        WHERE m.diagnostic_version_id=instrument.id) THEN
    RAISE EXCEPTION USING ERRCODE='55000', MESSAGE='pa_crosswalk_route_or_version_not_ready';
  END IF;
  IF (SELECT count(DISTINCT entry->>'code') FROM jsonb_array_elements(p_mappings) entry)<>30 THEN
    RAISE EXCEPTION USING ERRCODE='22023', MESSAGE='pa_crosswalk_duplicate_codes';
  END IF;
  FOR item IN SELECT value FROM jsonb_array_elements(p_mappings)
  LOOP
    IF jsonb_typeof(item) IS DISTINCT FROM 'object'
      OR (SELECT count(*) FROM jsonb_object_keys(item))<>3
      OR jsonb_typeof(item->'code') IS DISTINCT FROM 'string'
      OR jsonb_typeof(item->'outcome_mapping_id') IS DISTINCT FROM 'string'
      OR jsonb_typeof(item->'rationale') IS DISTINCT FROM 'string'
      OR (item->>'outcome_mapping_id') !~
        '^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$'
      OR char_length(btrim(item->>'rationale')) NOT BETWEEN 20 AND 2000 THEN
      RAISE EXCEPTION USING ERRCODE='22023', MESSAGE='pa_crosswalk_invalid_link';
    END IF;
    code := item->>'code';
    outcome_id := (item->>'outcome_mapping_id')::uuid;
    note := btrim(item->>'rationale');
    INSERT INTO public.diagnostic_observation_outcome_mappings(
      diagnostic_version_id,diagnostic_observation_id,route_version_id,
      curriculum_unit_version_id,curriculum_unit_outcome_mapping_id,
      mapping_status,mapping_rationale,reviewed_by,reviewed_at
    )
    SELECT instrument.id,o.id,instrument.route_version_id,
      u.id,outcome.id,'direct',note,auth.uid(),clock_timestamp()
    FROM public.diagnostic_observations o
    JOIN public.curriculum_unit_outcome_mappings outcome ON outcome.id=outcome_id
      AND outcome.mapping_status='direct' AND outcome.reviewed_by IS NOT NULL
      AND outcome.reviewed_at IS NOT NULL
      AND char_length(btrim(outcome.source_locator))>0
    JOIN public.curriculum_unit_versions u
      ON u.id=outcome.curriculum_unit_version_id
      AND u.route_version_id=instrument.route_version_id AND u.release_state='published'
    WHERE o.diagnostic_version_id=instrument.id AND o.observation_code=code
      AND o.learner_capture_enabled AND o.group_code<>'L';
    IF NOT FOUND THEN
      RAISE EXCEPTION USING ERRCODE='55000', MESSAGE='pa_crosswalk_requires_verified_exact_route_outcome';
    END IF;
    count_written := count_written+1;
  END LOOP;
  IF count_written<>30 OR
    (SELECT count(*) FROM public.inspect_pa_academic_readiness(instrument.id)
      WHERE learner_capture_enabled AND reviewed_direct_mapping_present)<>30 THEN
    RAISE EXCEPTION USING ERRCODE='55000', MESSAGE='pa_crosswalk_incomplete';
  END IF;
  RETURN count_written;
END;
$$;
ALTER FUNCTION public.record_pa_verified_direct_crosswalk(uuid,jsonb) OWNER TO postgres;
REVOKE ALL ON FUNCTION public.record_pa_verified_direct_crosswalk(uuid,jsonb)
  FROM PUBLIC,anon,service_role;
GRANT EXECUTE ON FUNCTION public.record_pa_verified_direct_crosswalk(uuid,jsonb)
  TO authenticated;
COMMENT ON FUNCTION public.record_pa_verified_direct_crosswalk(uuid,jsonb) IS
 'Owner AAL2 only; atomic 30 direct links to pre-existing verified route outcomes, never fabricated outcomes or duplicate academic approval.';
