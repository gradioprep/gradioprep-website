-- Private Owner/AAL2 lookup of actual PA versions and route readiness.
-- No synthetic, unverified or academic content is promoted by this readback.
CREATE FUNCTION public.list_pa_academic_versions()
RETURNS TABLE(
  diagnostic_version_id uuid,
  instrument_version integer,
  instrument_title text,
  instrument_release_state text,
  route_version_id uuid,
  route_key text,
  route_review_state text,
  route_source_title text,
  route_source_url text,
  total_observations integer,
  direct_mappings integer,
  capture_enabled integer
) LANGUAGE plpgsql SECURITY DEFINER SET search_path=''
AS $$
BEGIN
  IF auth.uid() IS NULL OR NOT private.current_account_is_active()
    OR NOT private.current_user_has_role('owner'::public.app_role)
    OR coalesce(auth.jwt()->>'aal','aal1') <> 'aal2' THEN
    RAISE EXCEPTION USING ERRCODE='42501', MESSAGE='pa_version_inventory_forbidden';
  END IF;
  RETURN QUERY
  SELECT dv.id,dv.version,dv.title::text,dv.release_state::text,
    route.id,route.route_key::text,route.review_state::text,
    route.official_source_title::text,route.official_source_url::text,
    count(o.id)::integer,
    count(o.id) FILTER (WHERE EXISTS(
      SELECT 1 FROM public.diagnostic_observation_outcome_mappings m
      JOIN public.curriculum_unit_versions u ON u.id=m.curriculum_unit_version_id
        AND u.route_version_id=dv.route_version_id AND u.release_state='published'
      JOIN public.curriculum_unit_outcome_mappings om
        ON om.id=m.curriculum_unit_outcome_mapping_id
        AND om.curriculum_unit_version_id=u.id
      WHERE m.diagnostic_version_id=dv.id
        AND m.diagnostic_observation_id=o.id
        AND m.route_version_id=dv.route_version_id
        AND m.mapping_status='direct' AND m.reviewed_by IS NOT NULL
        AND m.reviewed_at IS NOT NULL
        AND om.mapping_status='direct' AND om.reviewed_by IS NOT NULL
        AND om.reviewed_at IS NOT NULL
    ))::integer,
    count(o.id) FILTER (WHERE o.learner_capture_enabled)::integer
  FROM public.diagnostic_versions dv
  JOIN public.curriculum_route_versions route ON route.id=dv.route_version_id
  LEFT JOIN public.diagnostic_observations o ON o.diagnostic_version_id=dv.id
  WHERE dv.diagnostic_code='ib-myp-g9-cycle1'
  GROUP BY dv.id,dv.version,dv.title,dv.release_state,route.id,
    route.route_key,route.review_state,route.official_source_title,route.official_source_url
  ORDER BY dv.version DESC LIMIT 30;
END;
$$;
ALTER FUNCTION public.list_pa_academic_versions() OWNER TO postgres;
REVOKE ALL ON FUNCTION public.list_pa_academic_versions()
  FROM PUBLIC,anon,service_role;
GRANT EXECUTE ON FUNCTION public.list_pa_academic_versions() TO authenticated;
