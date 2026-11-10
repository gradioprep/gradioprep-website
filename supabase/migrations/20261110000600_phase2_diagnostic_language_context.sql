-- Extend the synthetic Cycle 1 Diagnostic capture slice to Language in Context (LC01-LC05).
-- Preserve bounded validation, caller-scoped authorization, immutable revisions and audit attribution.

CREATE OR REPLACE FUNCTION private.valid_diagnostic_response(p_code text, p_value jsonb)
RETURNS boolean
LANGUAGE plpgsql IMMUTABLE SET search_path = ''
AS $$
BEGIN
  IF p_value IS NULL OR jsonb_typeof(p_value) <> 'object'
    OR octet_length(p_value::text) > 16000 THEN RETURN false; END IF;
  CASE p_code
    WHEN 'RV01' THEN
      RETURN COALESCE(((SELECT count(*) FROM jsonb_object_keys(p_value))=2 AND p_value ?& ARRAY['a','b']
        AND p_value->>'a' IN ('A','B','C','D')
        AND jsonb_typeof(p_value->'b')='array'
        AND jsonb_array_length(p_value->'b')=2
        AND p_value->'b'->>0 IN ('A','B','C','D')
        AND p_value->'b'->>1 IN ('A','B','C','D')
        AND p_value->'b'->>0 <> p_value->'b'->>1), false);
    WHEN 'RV02','RV03','RV06','RV07a','RV07b' THEN
      RETURN COALESCE(((SELECT count(*) FROM jsonb_object_keys(p_value))=1 AND p_value ? 'text'
        AND jsonb_typeof(p_value->'text')='string'
        AND char_length(btrim(p_value->>'text')) BETWEEN 5 AND 12000), false);
    WHEN 'RV04','RV05' THEN
      RETURN COALESCE(((SELECT count(*) FROM jsonb_object_keys(p_value))=1 AND p_value ? 'choice'
        AND p_value->>'choice' IN ('A','B','C','D')), false);
    WHEN 'RV08' THEN
      RETURN COALESCE(((SELECT count(*) FROM jsonb_object_keys(p_value))=2 AND p_value ?& ARRAY['order','explanation']
        AND jsonb_typeof(p_value->'order')='array'
        AND jsonb_array_length(p_value->'order')=5
        AND (SELECT count(*)::integer FROM jsonb_array_elements(p_value->'order') AS item(value)
             WHERE jsonb_typeof(item.value)='string' AND item.value #>> '{}' IN ('1','2','3','4','5'))=5
        AND (SELECT count(DISTINCT item.value #>> '{}')::integer FROM jsonb_array_elements(p_value->'order') AS item(value)
             WHERE jsonb_typeof(item.value)='string' AND item.value #>> '{}' IN ('1','2','3','4','5'))=5
        AND jsonb_typeof(p_value->'explanation')='string'
        AND char_length(btrim(p_value->>'explanation')) BETWEEN 5 AND 12000), false);
    WHEN 'RV09' THEN
      RETURN COALESCE(((SELECT count(*) FROM jsonb_object_keys(p_value))=2 AND p_value ?& ARRAY['choice','explanation']
        AND jsonb_typeof(p_value->'choice')='string' AND p_value->>'choice' IN ('A','B','C','D')
        AND jsonb_typeof(p_value->'explanation')='string'
        AND char_length(btrim(p_value->>'explanation')) BETWEEN 5 AND 12000), false);
    WHEN 'LC01','LC02','LC03','LC04' THEN
      RETURN COALESCE(((SELECT count(*) FROM jsonb_object_keys(p_value))=1 AND p_value ? 'choice'
        AND p_value->>'choice' IN ('A','B','C','D')), false);
    WHEN 'LC05' THEN
      RETURN COALESCE(((SELECT count(*) FROM jsonb_object_keys(p_value))=1 AND p_value ? 'text'
        AND jsonb_typeof(p_value->'text')='string'
        AND char_length(btrim(p_value->>'text')) BETWEEN 5 AND 12000), false);
    ELSE RETURN false;
  END CASE;
END;
$$;
REVOKE ALL ON FUNCTION private.valid_diagnostic_response(text,jsonb) FROM PUBLIC, anon, authenticated;

CREATE OR REPLACE FUNCTION public.save_diagnostic_response(p_attempt_id uuid,p_observation_code text,p_response jsonb)
RETURNS TABLE(observation_code text,revision_number integer,saved_at timestamptz)
LANGUAGE plpgsql SECURITY DEFINER SET search_path = ''
AS $$
DECLARE
  actor uuid := auth.uid();
  attempt public.diagnostic_attempts%ROWTYPE;
  observation public.diagnostic_observations%ROWTYPE;
  previous public.diagnostic_response_versions%ROWTYPE;
  next_revision integer;
  saved_time timestamptz;
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
  IF NOT FOUND OR NOT private.valid_diagnostic_response(p_observation_code,p_response) THEN
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

CREATE OR REPLACE FUNCTION public.submit_diagnostic_attempt(p_attempt_id uuid)
RETURNS TABLE(attempt_id uuid,status text,submitted_at timestamptz,saved_observations integer,expected_observations integer)
LANGUAGE plpgsql SECURITY DEFINER SET search_path = ''
AS $$
DECLARE
  actor uuid := auth.uid();
  attempt public.diagnostic_attempts%ROWTYPE;
  expected integer;
  saved integer;
  submitted_time timestamptz;
BEGIN
  IF actor IS NULL OR NOT private.current_account_is_active()
    OR NOT private.current_user_has_role('student'::public.app_role) THEN
    RAISE EXCEPTION USING ERRCODE='42501', MESSAGE='diagnostic_attempt_forbidden';
  END IF;
  SELECT a.* INTO attempt FROM public.diagnostic_attempts a
    WHERE a.id=p_attempt_id AND a.learner_id=actor FOR UPDATE;
  IF NOT FOUND THEN RAISE EXCEPTION USING ERRCODE='P0002', MESSAGE='diagnostic_attempt_not_found'; END IF;
  IF attempt.status <> 'in_progress' THEN RAISE EXCEPTION USING ERRCODE='P0001', MESSAGE='diagnostic_attempt_not_editable'; END IF;
  SELECT count(*)::integer INTO expected FROM public.diagnostic_observations o
    WHERE o.diagnostic_version_id=attempt.diagnostic_version_id AND o.learner_capture_enabled;
  SELECT count(DISTINCT r.observation_id)::integer INTO saved
    FROM public.diagnostic_response_versions r JOIN public.diagnostic_observations o ON o.id=r.observation_id
    WHERE r.attempt_id=p_attempt_id AND o.diagnostic_version_id=attempt.diagnostic_version_id
       AND o.learner_capture_enabled;
  IF expected=0 OR saved<>expected THEN
    RAISE EXCEPTION USING ERRCODE='P0001', MESSAGE='diagnostic_responses_incomplete';
  END IF;
  submitted_time := clock_timestamp();
  UPDATE public.diagnostic_attempts SET status='submitted',submitted_at=submitted_time WHERE id=p_attempt_id;
  INSERT INTO private.security_audit_events(actor_id,action,target_type,target_id,outcome,reason_category)
    VALUES(actor,'diagnostic_attempt_submitted','diagnostic_attempt',p_attempt_id,'success','learner_action');
  RETURN QUERY SELECT p_attempt_id,'submitted'::text,submitted_time,saved,expected;
END;
$$;


ALTER FUNCTION public.save_diagnostic_response(uuid,text,jsonb) OWNER TO postgres;
ALTER FUNCTION public.submit_diagnostic_attempt(uuid) OWNER TO postgres;
REVOKE ALL ON FUNCTION public.save_diagnostic_response(uuid,text,jsonb) FROM PUBLIC,anon,authenticated;
REVOKE ALL ON FUNCTION public.submit_diagnostic_attempt(uuid) FROM PUBLIC,anon,authenticated;
GRANT EXECUTE ON FUNCTION public.save_diagnostic_response(uuid,text,jsonb) TO authenticated;
GRANT EXECUTE ON FUNCTION public.submit_diagnostic_attempt(uuid) TO authenticated;
