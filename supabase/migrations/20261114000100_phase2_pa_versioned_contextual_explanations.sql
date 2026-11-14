-- Prepare the Founder-adopted contextual-answer shape for UNRELEASED MYP4 PA v2.
-- Preserve existing published v1 selection-only responses and release controls.
-- Nothing here approves mappings, keys, rubrics, calibration or learner release.
CREATE OR REPLACE FUNCTION private.valid_pa_choice_and_explanation(p_value jsonb)
RETURNS boolean LANGUAGE plpgsql IMMUTABLE SET search_path = ''
AS $$
BEGIN
  IF p_value IS NULL OR jsonb_typeof(p_value) <> 'object'
    OR octet_length(p_value::text) > 16000 THEN
    RETURN false;
  END IF;
  RETURN coalesce(
    (SELECT count(*) FROM jsonb_object_keys(p_value)) = 2
    AND p_value ?& ARRAY['choice','explanation']
    AND jsonb_typeof(p_value->'choice') = 'string'
    AND p_value->>'choice' IN ('A','B','C','D')
    AND jsonb_typeof(p_value->'explanation') = 'string'
    AND char_length(btrim(p_value->>'explanation')) BETWEEN 5 AND 12000,
    false
  );
END;
$$;
ALTER FUNCTION private.valid_pa_choice_and_explanation(jsonb) OWNER TO postgres;
REVOKE ALL ON FUNCTION private.valid_pa_choice_and_explanation(jsonb)
  FROM PUBLIC,anon,authenticated,service_role;

-- Pick the validation policy by immutable instrument version; never silently
-- change the existing RV04/RV05/LC01/LC02 v1 selection-only contract.
CREATE OR REPLACE FUNCTION public.save_diagnostic_response(
  p_attempt_id uuid,p_observation_code text,p_response jsonb
) RETURNS TABLE(observation_code text,revision_number integer,saved_at timestamptz)
LANGUAGE plpgsql SECURITY DEFINER SET search_path = ''
AS $$
DECLARE
  actor uuid := auth.uid();
  attempt public.diagnostic_attempts%ROWTYPE;
  observation public.diagnostic_observations%ROWTYPE;
  pa_version public.diagnostic_versions%ROWTYPE;
  previous public.diagnostic_response_versions%ROWTYPE;
  next_revision integer;
  saved_time timestamptz;
  response_valid boolean;
BEGIN
  IF actor IS NULL OR NOT private.current_account_is_active()
    OR NOT private.current_user_has_role('student'::public.app_role) THEN
    RAISE EXCEPTION USING ERRCODE='42501', MESSAGE='diagnostic_response_forbidden';
  END IF;
  SELECT a.* INTO attempt FROM public.diagnostic_attempts a
    WHERE a.id=p_attempt_id AND a.learner_id=actor FOR UPDATE;
  IF NOT FOUND THEN RAISE EXCEPTION USING ERRCODE='P0002', MESSAGE='diagnostic_attempt_not_found'; END IF;
  IF attempt.status <> 'in_progress' THEN RAISE EXCEPTION USING ERRCODE='P0001', MESSAGE='diagnostic_attempt_not_editable'; END IF;
  SELECT o.* INTO observation FROM public.diagnostic_observations o
    WHERE o.diagnostic_version_id=attempt.diagnostic_version_id
      AND o.observation_code=p_observation_code AND o.learner_capture_enabled FOR SHARE;
  IF NOT FOUND THEN
    RAISE EXCEPTION USING ERRCODE='22023', MESSAGE='invalid_diagnostic_response';
  END IF;
  SELECT v.* INTO pa_version FROM public.diagnostic_versions v
    WHERE v.id=attempt.diagnostic_version_id;
  IF NOT FOUND THEN
    RAISE EXCEPTION USING ERRCODE='22023', MESSAGE='invalid_diagnostic_response';
  END IF;
  IF pa_version.diagnostic_code='ib-myp-g9-cycle1' AND pa_version.version>=2
    AND p_observation_code IN ('RV04','RV05','LC01','LC02') THEN
    response_valid := observation.response_kind='choice_and_text'
      AND private.valid_pa_choice_and_explanation(p_response);
  ELSE
    response_valid := private.valid_diagnostic_response(p_observation_code,p_response);
  END IF;
  IF response_valid IS DISTINCT FROM true THEN
    RAISE EXCEPTION USING ERRCODE='22023', MESSAGE='invalid_diagnostic_response';
  END IF;
  SELECT r.* INTO previous FROM public.diagnostic_response_versions r
    WHERE r.attempt_id=p_attempt_id AND r.observation_id=observation.id
    ORDER BY r.revision_number DESC LIMIT 1 FOR UPDATE;
  IF FOUND AND previous.response_json=p_response THEN
    RETURN QUERY SELECT p_observation_code,previous.revision_number,previous.saved_at;
    RETURN;
  END IF;
  next_revision := coalesce(previous.revision_number,0)+1;
  saved_time := clock_timestamp();
  INSERT INTO public.diagnostic_response_versions(attempt_id,observation_id,revision_number,response_json,saved_at)
    VALUES(p_attempt_id,observation.id,next_revision,p_response,saved_time);
  RETURN QUERY SELECT p_observation_code,next_revision,saved_time;
END;
$$;
ALTER FUNCTION public.save_diagnostic_response(uuid,text,jsonb) OWNER TO postgres;
REVOKE ALL ON FUNCTION public.save_diagnostic_response(uuid,text,jsonb)
  FROM PUBLIC,anon,authenticated,service_role;
GRANT EXECUTE ON FUNCTION public.save_diagnostic_response(uuid,text,jsonb) TO authenticated;
