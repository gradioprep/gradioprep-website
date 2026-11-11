-- Remove provisional Listening capture from the Preliminary Assessment.
-- Listening is reserved for a later milestone-specific Summative Assessment 3 design.
-- Preserve history: do not delete observations or rewrite the prior Listening migration.

CREATE OR REPLACE FUNCTION private.valid_diagnostic_response(p_code text,p_value jsonb)
RETURNS boolean
LANGUAGE plpgsql IMMUTABLE SET search_path = ''
AS $$
BEGIN
  IF p_value IS NULL OR jsonb_typeof(p_value) <> 'object'
    OR octet_length(p_value::text) > 16000 THEN
    RETURN false;
  END IF;

  -- Delegate only to the pre-Listening RV + LC contract.
  -- This helper has no L01-L05 cases, so Listening cannot be persisted by PA RPCs.
  RETURN private.valid_diagnostic_response_pre_listening(p_code,p_value);
END;
$$;

ALTER FUNCTION private.valid_diagnostic_response(text,jsonb) OWNER TO postgres;
REVOKE ALL ON FUNCTION private.valid_diagnostic_response(text,jsonb) FROM PUBLIC, anon, authenticated;
REVOKE ALL ON FUNCTION private.valid_diagnostic_response_pre_listening(text,jsonb) FROM PUBLIC, anon, authenticated;

-- Any Listening rows already present for a PA version remain as history but are no longer learner-capturable.
UPDATE public.diagnostic_observations
SET learner_capture_enabled = false
WHERE group_code = 'L'
  AND learner_capture_enabled = true;

-- PA duration is 25 min RV + 10 min LC in Sitting 1, plus the existing 45 min Sitting 2.
UPDATE public.diagnostic_versions
SET total_minutes = 80
WHERE diagnostic_code = 'ib-myp-g9-cycle1'
  AND version = 1;
