-- Block new PA publication until its exact instrument has verified direct mappings.
-- Existing synthetic published partial slices are unaffected; this runs on draft -> published only.
-- This is a technical safeguard, not an academic approval or release.
CREATE OR REPLACE FUNCTION private.guard_pa_version_publication()
RETURNS trigger LANGUAGE plpgsql SECURITY DEFINER SET search_path = ''
AS $$
DECLARE
  total_observations integer;
  enabled_observations integer;
  directly_mapped_observations integer;
  listening_observations integer;
  route_verified boolean;
BEGIN
  IF NEW.release_state <> 'published' OR OLD.release_state IS NOT DISTINCT FROM 'published' THEN
    RETURN NEW;
  END IF;

  SELECT route.review_state = 'verified' AND route.id = NEW.route_version_id
  INTO route_verified
  FROM public.curriculum_route_versions AS route
  WHERE route.id = NEW.route_version_id AND route.route_key = NEW.pathway_id;

  SELECT count(*)::integer,
    count(*) FILTER (WHERE o.learner_capture_enabled)::integer,
    count(*) FILTER (WHERE o.group_code = 'L')::integer,
    count(*) FILTER (WHERE EXISTS (
      SELECT 1 FROM public.diagnostic_observation_outcome_mappings AS mapping
      JOIN public.curriculum_unit_versions AS unit
        ON unit.id = mapping.curriculum_unit_version_id
        AND unit.route_version_id = NEW.route_version_id
        AND unit.release_state = 'published'
      JOIN public.curriculum_unit_outcome_mappings AS outcome
        ON outcome.id = mapping.curriculum_unit_outcome_mapping_id
        AND outcome.curriculum_unit_version_id = unit.id
      WHERE mapping.diagnostic_version_id = NEW.id
        AND mapping.diagnostic_observation_id = o.id
        AND mapping.route_version_id = NEW.route_version_id
        AND mapping.mapping_status = 'direct'
        AND mapping.reviewed_by IS NOT NULL AND mapping.reviewed_at IS NOT NULL
        AND outcome.mapping_status = 'direct'
        AND outcome.reviewed_by IS NOT NULL AND outcome.reviewed_at IS NOT NULL
    ))::integer
  INTO total_observations, enabled_observations, listening_observations,
       directly_mapped_observations
  FROM public.diagnostic_observations AS o
  WHERE o.diagnostic_version_id = NEW.id;

  IF NOT coalesce(route_verified, false)
    OR total_observations = 0
    OR enabled_observations <> total_observations
    OR directly_mapped_observations <> total_observations
    OR listening_observations <> 0
    OR (NEW.diagnostic_code = 'ib-myp-g9-cycle1' AND total_observations <> 30)
  THEN
    RAISE EXCEPTION USING ERRCODE = '55000',
      MESSAGE = 'pa_publication_requires_reviewed_direct_mapping';
  END IF;
  RETURN NEW;
END;
$$;
ALTER FUNCTION private.guard_pa_version_publication() OWNER TO postgres;
REVOKE ALL ON FUNCTION private.guard_pa_version_publication() FROM PUBLIC, anon, authenticated, service_role;

CREATE TRIGGER pa_version_publication_gate
BEFORE UPDATE OF release_state ON public.diagnostic_versions
FOR EACH ROW EXECUTE FUNCTION private.guard_pa_version_publication();
