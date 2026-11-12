-- Full-instrument two-sitting PA timing. The legacy published 15-item slice
-- remains unaffected; timed submission and response guards apply to the
-- approved 30-observation instrument once published.
CREATE TABLE private.pa_sitting_sessions (
  attempt_id uuid NOT NULL REFERENCES public.diagnostic_attempts(id) ON DELETE CASCADE,
  sitting_number integer NOT NULL CHECK (sitting_number IN (1,2)),
  started_at timestamptz NOT NULL DEFAULT clock_timestamp(),
  completed_at timestamptz,
  duration_seconds integer NOT NULL CHECK (duration_seconds BETWEEN 60 AND 14400),
  extra_seconds integer NOT NULL DEFAULT 0 CHECK (extra_seconds BETWEEN 0 AND 7200),
  untimed boolean NOT NULL DEFAULT false,
  PRIMARY KEY(attempt_id,sitting_number),
  CHECK (completed_at IS NULL OR completed_at >= started_at)
);
ALTER TABLE private.pa_sitting_sessions ENABLE ROW LEVEL SECURITY;
REVOKE ALL ON private.pa_sitting_sessions FROM PUBLIC,anon,authenticated,service_role;

CREATE OR REPLACE FUNCTION public.get_pa_sitting_state(p_attempt_id uuid)
RETURNS TABLE(sitting_number integer,started_at timestamptz,completed_at timestamptz,
 duration_seconds integer,extra_seconds integer,untimed boolean,remaining_seconds integer)
LANGUAGE plpgsql SECURITY DEFINER SET search_path=''
AS $$
BEGIN
  IF auth.uid() IS NULL OR NOT private.current_account_is_active()
    OR NOT private.current_user_has_role('student'::public.app_role)
    OR NOT EXISTS(SELECT 1 FROM public.diagnostic_attempts a
      WHERE a.id=p_attempt_id AND a.learner_id=auth.uid()) THEN
    RAISE EXCEPTION USING ERRCODE='42501',MESSAGE='pa_sitting_forbidden';
  END IF;
  RETURN QUERY SELECT s.sitting_number,s.started_at,s.completed_at,
    s.duration_seconds,s.extra_seconds,s.untimed,
    CASE WHEN s.untimed THEN NULL::integer
      ELSE greatest(0,floor(extract(epoch FROM
        (s.started_at + make_interval(secs=>s.duration_seconds+s.extra_seconds) - clock_timestamp())))::integer)
    END
  FROM private.pa_sitting_sessions s WHERE s.attempt_id=p_attempt_id
  ORDER BY s.sitting_number;
END;
$$;
ALTER FUNCTION public.get_pa_sitting_state(uuid) OWNER TO postgres;
REVOKE ALL ON FUNCTION public.get_pa_sitting_state(uuid) FROM PUBLIC,anon,service_role;
GRANT EXECUTE ON FUNCTION public.get_pa_sitting_state(uuid) TO authenticated;

CREATE OR REPLACE FUNCTION public.start_pa_sitting(p_attempt_id uuid,p_sitting_number integer)
RETURNS TABLE(sitting_number integer,started_at timestamptz,completed_at timestamptz,
 duration_seconds integer,extra_seconds integer,untimed boolean,remaining_seconds integer)
LANGUAGE plpgsql SECURITY DEFINER SET search_path=''
AS $$
DECLARE
  attempt public.diagnostic_attempts%ROWTYPE;
  assessment public.diagnostic_versions%ROWTYPE;
  duration integer;
BEGIN
  IF auth.uid() IS NULL OR NOT private.current_account_is_active()
    OR NOT private.current_user_has_role('student'::public.app_role) THEN
    RAISE EXCEPTION USING ERRCODE='42501',MESSAGE='pa_sitting_forbidden';
  END IF;
  SELECT a.* INTO attempt FROM public.diagnostic_attempts a
    WHERE a.id=p_attempt_id AND a.learner_id=auth.uid() FOR UPDATE;
  IF NOT FOUND THEN
    RAISE EXCEPTION USING ERRCODE='P0002',MESSAGE='pa_sitting_not_found';
  END IF;
  IF attempt.status<>'in_progress' OR p_sitting_number NOT IN (1,2) THEN
    RAISE EXCEPTION USING ERRCODE='P0001',MESSAGE='pa_sitting_unavailable';
  END IF;
  SELECT v.* INTO assessment FROM public.diagnostic_versions v
    WHERE v.id=attempt.diagnostic_version_id AND v.release_state='published';
  IF NOT FOUND OR p_sitting_number>assessment.sitting_count
    OR NOT EXISTS(SELECT 1 FROM public.diagnostic_observations o
      WHERE o.diagnostic_version_id=assessment.id AND o.learner_capture_enabled
        AND o.sitting_number=p_sitting_number) THEN
    RAISE EXCEPTION USING ERRCODE='P0001',MESSAGE='pa_sitting_unavailable';
  END IF;
  IF p_sitting_number=2 AND NOT EXISTS(
    SELECT 1 FROM private.pa_sitting_sessions s
    WHERE s.attempt_id=p_attempt_id AND s.sitting_number=1 AND s.completed_at IS NOT NULL
  ) THEN RAISE EXCEPTION USING ERRCODE='P0001',MESSAGE='pa_previous_sitting_incomplete'; END IF;
  duration:=CASE WHEN assessment.sitting_count=2 AND assessment.total_minutes=80
    THEN CASE WHEN p_sitting_number=1 THEN 2100 ELSE 2700 END
    ELSE (assessment.total_minutes*60/assessment.sitting_count) END;
  INSERT INTO private.pa_sitting_sessions(attempt_id,sitting_number,duration_seconds)
    VALUES(p_attempt_id,p_sitting_number,duration)
    ON CONFLICT(attempt_id,sitting_number) DO NOTHING;
  RETURN QUERY SELECT * FROM public.get_pa_sitting_state(p_attempt_id) AS state
    WHERE state.sitting_number=p_sitting_number;
END;
$$;
ALTER FUNCTION public.start_pa_sitting(uuid,integer) OWNER TO postgres;
REVOKE ALL ON FUNCTION public.start_pa_sitting(uuid,integer) FROM PUBLIC,anon,service_role;
GRANT EXECUTE ON FUNCTION public.start_pa_sitting(uuid,integer) TO authenticated;

CREATE OR REPLACE FUNCTION public.complete_pa_sitting(p_attempt_id uuid,p_sitting_number integer)
RETURNS boolean LANGUAGE plpgsql SECURITY DEFINER SET search_path=''
AS $$
DECLARE
  attempt public.diagnostic_attempts%ROWTYPE;
  expected integer;
  saved integer;
BEGIN
  IF auth.uid() IS NULL OR NOT private.current_account_is_active()
    OR NOT private.current_user_has_role('student'::public.app_role) THEN
    RAISE EXCEPTION USING ERRCODE='42501',MESSAGE='pa_sitting_forbidden';
  END IF;
  SELECT a.* INTO attempt FROM public.diagnostic_attempts a
    WHERE a.id=p_attempt_id AND a.learner_id=auth.uid() FOR UPDATE;
  IF NOT FOUND THEN RAISE EXCEPTION USING ERRCODE='P0002',MESSAGE='pa_sitting_not_found'; END IF;
  IF attempt.status<>'in_progress' OR p_sitting_number NOT IN (1,2) THEN
    RAISE EXCEPTION USING ERRCODE='P0001',MESSAGE='pa_sitting_unavailable'; END IF;
  IF NOT EXISTS(SELECT 1 FROM private.pa_sitting_sessions s
    WHERE s.attempt_id=p_attempt_id AND s.sitting_number=p_sitting_number
      AND s.completed_at IS NULL) THEN
    RAISE EXCEPTION USING ERRCODE='P0001',MESSAGE='pa_sitting_not_active';
  END IF;
  SELECT count(*)::integer INTO expected FROM public.diagnostic_observations o
    WHERE o.diagnostic_version_id=attempt.diagnostic_version_id
      AND o.sitting_number=p_sitting_number AND o.learner_capture_enabled;
  SELECT count(DISTINCT r.observation_id)::integer INTO saved
    FROM public.diagnostic_response_versions r
    JOIN public.diagnostic_observations o ON o.id=r.observation_id
    WHERE r.attempt_id=p_attempt_id
      AND o.diagnostic_version_id=attempt.diagnostic_version_id
      AND o.sitting_number=p_sitting_number AND o.learner_capture_enabled;
  IF expected=0 OR saved<>expected THEN
    RAISE EXCEPTION USING ERRCODE='P0001',MESSAGE='pa_sitting_responses_incomplete';
  END IF;
  UPDATE private.pa_sitting_sessions SET completed_at=clock_timestamp()
    WHERE attempt_id=p_attempt_id AND sitting_number=p_sitting_number;
  INSERT INTO private.security_audit_events(actor_id,action,target_type,target_id,outcome,reason_category)
    VALUES(auth.uid(),'pa_sitting_completed','diagnostic_attempt',p_attempt_id,'success','learner_action');
  RETURN true;
END;
$$;
ALTER FUNCTION public.complete_pa_sitting(uuid,integer) OWNER TO postgres;
REVOKE ALL ON FUNCTION public.complete_pa_sitting(uuid,integer) FROM PUBLIC,anon,service_role;
GRANT EXECUTE ON FUNCTION public.complete_pa_sitting(uuid,integer) TO authenticated;

CREATE OR REPLACE FUNCTION public.adjust_pa_sitting_access(
 p_attempt_id uuid,p_sitting_number integer,p_extra_minutes integer,p_untimed boolean,p_reason text
)
RETURNS boolean LANGUAGE plpgsql SECURITY DEFINER SET search_path=''
AS $$
DECLARE actor uuid:=auth.uid();
BEGIN
  IF actor IS NULL OR NOT private.current_account_is_active()
    OR NOT private.current_user_has_role('owner'::public.app_role)
    OR coalesce(auth.jwt()->>'aal','aal1')<>'aal2' THEN
    RAISE EXCEPTION USING ERRCODE='42501',MESSAGE='pa_sitting_adjust_forbidden';
  END IF;
  IF p_attempt_id IS NULL OR p_sitting_number NOT IN(1,2)
    OR p_extra_minutes IS NULL OR p_extra_minutes<0 OR p_extra_minutes>120
    OR p_untimed IS NULL OR p_reason IS NULL OR char_length(btrim(p_reason)) NOT BETWEEN 10 AND 240 THEN
    RAISE EXCEPTION USING ERRCODE='22023',MESSAGE='invalid_pa_sitting_adjustment';
  END IF;
  UPDATE private.pa_sitting_sessions s
    SET extra_seconds=greatest(s.extra_seconds,p_extra_minutes*60),
      untimed=(s.untimed OR p_untimed)
    FROM public.diagnostic_attempts a
    WHERE a.id=s.attempt_id AND a.id=p_attempt_id AND a.status='in_progress'
      AND s.sitting_number=p_sitting_number AND s.completed_at IS NULL
      AND (p_extra_minutes*60>s.extra_seconds OR (p_untimed AND NOT s.untimed));
  IF NOT FOUND THEN RAISE EXCEPTION USING ERRCODE='P0001',MESSAGE='pa_sitting_adjust_unavailable'; END IF;
  INSERT INTO private.security_audit_events(actor_id,action,target_type,target_id,outcome,reason_category)
    VALUES(actor,'pa_sitting_adjusted','diagnostic_attempt',p_attempt_id,'success','owner_accommodation');
  RETURN true;
END;
$$;
ALTER FUNCTION public.adjust_pa_sitting_access(uuid,integer,integer,boolean,text) OWNER TO postgres;
REVOKE ALL ON FUNCTION public.adjust_pa_sitting_access(uuid,integer,integer,boolean,text) FROM PUBLIC,anon,service_role;
GRANT EXECUTE ON FUNCTION public.adjust_pa_sitting_access(uuid,integer,integer,boolean,text) TO authenticated;

CREATE OR REPLACE FUNCTION private.guard_full_pa_sitting_write()
RETURNS trigger LANGUAGE plpgsql SECURITY DEFINER SET search_path=''
AS $$
DECLARE selected_attempt public.diagnostic_attempts%ROWTYPE;
 sitting_number integer; enabled_count integer;
BEGIN
  SELECT a.* INTO selected_attempt FROM public.diagnostic_attempts a WHERE a.id=NEW.attempt_id;
  SELECT o.sitting_number INTO sitting_number FROM public.diagnostic_observations o WHERE o.id=NEW.observation_id;
  SELECT count(*)::integer INTO enabled_count FROM public.diagnostic_observations o
    WHERE o.diagnostic_version_id=selected_attempt.diagnostic_version_id AND o.learner_capture_enabled;
  IF enabled_count>=30 AND NOT EXISTS(
    SELECT 1 FROM private.pa_sitting_sessions s
    WHERE s.attempt_id=NEW.attempt_id AND s.sitting_number=sitting_number
      AND s.completed_at IS NULL
      AND (s.untimed OR clock_timestamp()<s.started_at+make_interval(secs=>s.duration_seconds+s.extra_seconds))
  ) THEN
    RAISE EXCEPTION USING ERRCODE='P0001',MESSAGE='pa_sitting_not_active';
  END IF;
  RETURN NEW;
END;
$$;
ALTER FUNCTION private.guard_full_pa_sitting_write() OWNER TO postgres;
REVOKE ALL ON FUNCTION private.guard_full_pa_sitting_write() FROM PUBLIC,anon,authenticated,service_role;
CREATE TRIGGER guard_full_pa_response_sitting BEFORE INSERT ON public.diagnostic_response_versions
  FOR EACH ROW EXECUTE FUNCTION private.guard_full_pa_sitting_write();

CREATE OR REPLACE FUNCTION private.guard_full_pa_submission()
RETURNS trigger LANGUAGE plpgsql SECURITY DEFINER SET search_path=''
AS $$
DECLARE enabled_count integer;
BEGIN
  IF NEW.status='submitted' AND OLD.status IS DISTINCT FROM 'submitted' THEN
    SELECT count(*)::integer INTO enabled_count FROM public.diagnostic_observations o
      WHERE o.diagnostic_version_id=NEW.diagnostic_version_id AND o.learner_capture_enabled;
    IF enabled_count>=30 AND (SELECT count(*)::integer
      FROM private.pa_sitting_sessions s WHERE s.attempt_id=NEW.id AND s.completed_at IS NOT NULL)<>2 THEN
      RAISE EXCEPTION USING ERRCODE='P0001',MESSAGE='pa_sittings_incomplete';
    END IF;
  END IF;
  RETURN NEW;
END;
$$;
ALTER FUNCTION private.guard_full_pa_submission() OWNER TO postgres;
REVOKE ALL ON FUNCTION private.guard_full_pa_submission() FROM PUBLIC,anon,authenticated,service_role;
CREATE TRIGGER guard_full_pa_submission BEFORE UPDATE OF status ON public.diagnostic_attempts
 FOR EACH ROW EXECUTE FUNCTION private.guard_full_pa_submission();
