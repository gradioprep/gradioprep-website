-- Prepare one Analytical Writing learner response for the five AW rubric dimensions.
-- This is schema validation only: the full Year 4 PA remains draft, with all
-- learner capture disabled pending exact-route mapping and academic approval.
-- AW02-AW05 are dimensions of the same performance, NOT four extra answers.
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
    WHEN 'RV02','RV03','RV06','RV07a','RV07b','LC05','AW01' THEN
      RETURN COALESCE(((SELECT count(*) FROM jsonb_object_keys(p_value))=1 AND p_value ? 'text'
        AND jsonb_typeof(p_value->'text')='string'
        AND char_length(btrim(p_value->>'text')) BETWEEN 5 AND 12000), false);
    WHEN 'RV04','RV05','LC01','LC02','LC03','LC04' THEN
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
    ELSE RETURN false;
  END CASE;
END;
$$;
ALTER FUNCTION private.valid_diagnostic_response(text,jsonb) OWNER TO postgres;
REVOKE ALL ON FUNCTION private.valid_diagnostic_response(text,jsonb) FROM PUBLIC, anon, authenticated, service_role;
