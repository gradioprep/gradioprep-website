-- Learner response cardinality is not the same as the 30 rubric observations.
-- The three five-dimensional writing/speaking tasks each have one captured answer.
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
    WHERE o.diagnostic_version_id=attempt.diagnostic_version_id AND o.learner_capture_enabled
      AND (o.group_code NOT IN ('AW','CW','SP') OR o.observation_code IN ('AW01','CW01','SP01'));
  SELECT count(DISTINCT r.observation_id)::integer INTO saved
    FROM public.diagnostic_response_versions r JOIN public.diagnostic_observations o ON o.id=r.observation_id
    WHERE r.attempt_id=p_attempt_id AND o.diagnostic_version_id=attempt.diagnostic_version_id
       AND o.learner_capture_enabled
       AND (o.group_code NOT IN ('AW','CW','SP') OR o.observation_code IN ('AW01','CW01','SP01'));
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
ALTER FUNCTION public.submit_diagnostic_attempt(uuid) OWNER TO postgres;
REVOKE ALL ON FUNCTION public.submit_diagnostic_attempt(uuid) FROM PUBLIC,anon,service_role;
GRANT EXECUTE ON FUNCTION public.submit_diagnostic_attempt(uuid) TO authenticated;
