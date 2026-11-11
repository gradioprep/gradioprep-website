-- Phase 2: extend the secure Diagnostic response validator for Listening L01-L05.
-- The VOA Learning English asset is streamed from its public source; the database stores learner evidence only.

ALTER FUNCTION private.valid_diagnostic_response(text,jsonb)
  RENAME TO valid_diagnostic_response_pre_listening;

CREATE FUNCTION private.valid_diagnostic_response(p_code text,p_value jsonb)
RETURNS boolean
LANGUAGE plpgsql IMMUTABLE SET search_path = ''
AS $$
BEGIN
  IF p_value IS NULL OR jsonb_typeof(p_value) <> 'object'
    OR octet_length(p_value::text) > 16000 THEN RETURN false; END IF;
  CASE p_code
    WHEN 'L01' THEN
      RETURN COALESCE(((SELECT count(*) FROM jsonb_object_keys(p_value))=2 AND p_value ?& ARRAY['a','b']
        AND p_value->>'a' IN ('A','B','C','D')
        AND jsonb_typeof(p_value->'b')='array'
        AND jsonb_array_length(p_value->'b')=2
        AND p_value->'b'->>0 IN ('A','B','C','D')
        AND p_value->'b'->>1 IN ('A','B','C','D')
        AND p_value->'b'->>0 <> p_value->'b'->>1), false);
    WHEN 'L02','L04','L05' THEN
      RETURN COALESCE(((SELECT count(*) FROM jsonb_object_keys(p_value))=1 AND p_value ? 'text'
        AND jsonb_typeof(p_value->'text')='string'
        AND char_length(btrim(p_value->>'text')) BETWEEN 5 AND 12000), false);
    WHEN 'L03' THEN
      RETURN COALESCE(((SELECT count(*) FROM jsonb_object_keys(p_value))=1 AND p_value ? 'choice'
        AND jsonb_typeof(p_value->'choice')='string' AND p_value->>'choice' IN ('A','B','C','D')), false);
    ELSE
      RETURN private.valid_diagnostic_response_pre_listening(p_code,p_value);
  END CASE;
END;
$$;

ALTER FUNCTION private.valid_diagnostic_response(text,jsonb) OWNER TO postgres;
REVOKE ALL ON FUNCTION private.valid_diagnostic_response(text,jsonb) FROM PUBLIC, anon, authenticated;
REVOKE ALL ON FUNCTION private.valid_diagnostic_response_pre_listening(text,jsonb) FROM PUBLIC, anon, authenticated;
