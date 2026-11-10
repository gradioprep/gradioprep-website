-- Phase 2: secure, unscored Diagnostic attempt capture (Cycle 1 Read & View).
-- Separate from practice attempts and human-grading submissions. No scoring, AI service or answer key.

CREATE TABLE public.diagnostic_versions (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  diagnostic_code text NOT NULL CHECK (char_length(btrim(diagnostic_code)) BETWEEN 1 AND 120),
  pathway_id text NOT NULL CHECK (char_length(btrim(pathway_id)) BETWEEN 1 AND 120),
  title text NOT NULL CHECK (char_length(btrim(title)) BETWEEN 1 AND 240),
  version integer NOT NULL CHECK (version > 0),
  release_state text NOT NULL DEFAULT 'draft' CHECK (release_state IN ('draft','published','retired')),
  total_minutes integer NOT NULL CHECK (total_minutes BETWEEN 1 AND 240),
  sitting_count integer NOT NULL CHECK (sitting_count BETWEEN 1 AND 4),
  created_at timestamptz NOT NULL DEFAULT now(),
  UNIQUE (diagnostic_code, version)
);

CREATE TABLE public.diagnostic_observations (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  diagnostic_version_id uuid NOT NULL REFERENCES public.diagnostic_versions(id) ON DELETE RESTRICT,
  observation_code text NOT NULL CHECK (observation_code ~ '^[A-Z]{1,3}[0-9]{2}[a-z]?$'),
  group_code text NOT NULL CHECK (group_code IN ('RV','L','LC','AW','CW','SP')),
  sitting_number integer NOT NULL CHECK (sitting_number BETWEEN 1 AND 2),
  sequence_number integer NOT NULL CHECK (sequence_number > 0),
  response_kind text NOT NULL CHECK (response_kind IN ('structured_selection','text','single_choice','ordered_sequence','choice_and_text')),
  learner_capture_enabled boolean NOT NULL DEFAULT false,
  UNIQUE (diagnostic_version_id, observation_code),
  UNIQUE (diagnostic_version_id, sequence_number),
  UNIQUE (id, diagnostic_version_id)
);

CREATE TABLE public.diagnostic_attempts (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  learner_id uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  diagnostic_version_id uuid NOT NULL REFERENCES public.diagnostic_versions(id) ON DELETE RESTRICT,
  status text NOT NULL DEFAULT 'in_progress' CHECK (status IN ('in_progress','submitted','withdrawn')),
  idempotency_key uuid NOT NULL,
  started_at timestamptz NOT NULL DEFAULT clock_timestamp(),
  submitted_at timestamptz,
  created_at timestamptz NOT NULL DEFAULT now(),
  CHECK ((status = 'submitted') = (submitted_at IS NOT NULL)),
  UNIQUE (learner_id, diagnostic_version_id),
  UNIQUE (learner_id, idempotency_key),
  UNIQUE (id, diagnostic_version_id)
);

CREATE TABLE public.diagnostic_response_versions (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  attempt_id uuid NOT NULL REFERENCES public.diagnostic_attempts(id) ON DELETE RESTRICT,
  observation_id uuid NOT NULL REFERENCES public.diagnostic_observations(id) ON DELETE RESTRICT,
  revision_number integer NOT NULL CHECK (revision_number > 0),
  response_json jsonb NOT NULL CHECK (jsonb_typeof(response_json) = 'object' AND octet_length(response_json::text) <= 16000),
  saved_at timestamptz NOT NULL DEFAULT clock_timestamp(),
  UNIQUE (attempt_id, observation_id, revision_number)
);

CREATE INDEX diagnostic_response_versions_latest_idx
  ON public.diagnostic_response_versions (attempt_id, observation_id, revision_number DESC);

ALTER TABLE public.diagnostic_versions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.diagnostic_observations ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.diagnostic_attempts ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.diagnostic_response_versions ENABLE ROW LEVEL SECURITY;

REVOKE ALL ON public.diagnostic_versions, public.diagnostic_observations,
  public.diagnostic_attempts, public.diagnostic_response_versions FROM PUBLIC, anon, authenticated;
GRANT SELECT ON public.diagnostic_versions, public.diagnostic_observations,
  public.diagnostic_attempts, public.diagnostic_response_versions TO authenticated;

CREATE POLICY diagnostic_versions_select_published_enrolled
  ON public.diagnostic_versions FOR SELECT TO authenticated
  USING (
    private.current_account_is_active()
    AND (
      (release_state = 'published'
       AND private.current_user_has_role('student'::public.app_role)
       AND EXISTS (
         SELECT 1 FROM public.course_enrolments e
         WHERE e.learner_id = (SELECT auth.uid())
           AND e.pathway_id = diagnostic_versions.pathway_id AND e.status = 'active'
       ))
      OR (private.current_user_has_role('owner'::public.app_role)
          AND coalesce(auth.jwt() ->> 'aal','aal1') = 'aal2')
    )
  );

CREATE POLICY diagnostic_observations_select_version_scope
  ON public.diagnostic_observations FOR SELECT TO authenticated
  USING (
    private.current_account_is_active()
    AND EXISTS (
      SELECT 1 FROM public.diagnostic_versions v
      WHERE v.id = diagnostic_version_id
        AND (
          (v.release_state = 'published'
           AND private.current_user_has_role('student'::public.app_role)
           AND EXISTS (
             SELECT 1 FROM public.course_enrolments e
             WHERE e.learner_id = (SELECT auth.uid())
               AND e.pathway_id = v.pathway_id AND e.status = 'active'
           ))
          OR (private.current_user_has_role('owner'::public.app_role)
              AND coalesce(auth.jwt() ->> 'aal','aal1') = 'aal2')
        )
    )
  );

CREATE POLICY diagnostic_attempts_select_own_student
  ON public.diagnostic_attempts FOR SELECT TO authenticated
  USING (learner_id = (SELECT auth.uid())
    AND private.current_account_is_active()
    AND private.current_user_has_role('student'::public.app_role));

CREATE POLICY diagnostic_response_versions_select_own_student
  ON public.diagnostic_response_versions FOR SELECT TO authenticated
  USING (private.current_account_is_active()
    AND private.current_user_has_role('student'::public.app_role)
    AND EXISTS (
      SELECT 1 FROM public.diagnostic_attempts a
      WHERE a.id = attempt_id AND a.learner_id = (SELECT auth.uid())
    ));

CREATE OR REPLACE FUNCTION private.valid_diagnostic_response(p_code text, p_value jsonb)
RETURNS boolean
LANGUAGE plpgsql IMMUTABLE SET search_path = ''
AS $$
BEGIN
  IF p_value IS NULL OR jsonb_typeof(p_value) <> 'object'
    OR octet_length(p_value::text) > 16000 THEN RETURN false; END IF;
  CASE p_code
    WHEN 'RV01' THEN
      RETURN jsonb_object_length(p_value)=2 AND p_value ?& ARRAY['a','b']
        AND p_value->>'a' IN ('A','B','C','D')
        AND jsonb_typeof(p_value->'b')='array'
        AND jsonb_array_length(p_value->'b')=2
        AND p_value->'b'->>0 IN ('A','B','C','D')
        AND p_value->'b'->>1 IN ('A','B','C','D')
        AND p_value->'b'->>0 <> p_value->'b'->>1;
    WHEN 'RV02','RV03','RV06','RV07a','RV07b' THEN
      RETURN jsonb_object_length(p_value)=1 AND p_value ? 'text'
        AND char_length(btrim(p_value->>'text')) BETWEEN 5 AND 12000;
    WHEN 'RV04','RV05' THEN
      RETURN jsonb_object_length(p_value)=1 AND p_value ? 'choice'
        AND p_value->>'choice' IN ('A','B','C','D');
    WHEN 'RV08' THEN
      RETURN jsonb_object_length(p_value)=2 AND p_value ?& ARRAY['order','explanation']
        AND jsonb_typeof(p_value->'order')='array'
        AND jsonb_array_length(p_value->'order')=5
        AND (SELECT count(DISTINCT x)::integer FROM jsonb_array_elements_text(p_value->'order') x
             WHERE x IN ('1','2','3','4','5'))=5
        AND char_length(btrim(p_value->>'explanation')) BETWEEN 5 AND 12000;
    WHEN 'RV09' THEN
      RETURN jsonb_object_length(p_value)=2 AND p_value ?& ARRAY['choice','explanation']
        AND p_value->>'choice' IN ('A','B','C','D')
        AND char_length(btrim(p_value->>'explanation')) BETWEEN 5 AND 12000;
    ELSE RETURN false;
  END CASE;
END;
$$;
REVOKE ALL ON FUNCTION private.valid_diagnostic_response(text,jsonb) FROM PUBLIC, anon, authenticated;

CREATE OR REPLACE FUNCTION private.reject_diagnostic_response_mutation()
RETURNS trigger LANGUAGE plpgsql SET search_path = ''
AS $$ BEGIN
  RAISE EXCEPTION 'diagnostic response versions are append-only' USING ERRCODE = '42501';
END; $$;
CREATE TRIGGER diagnostic_response_versions_append_only
  BEFORE UPDATE OR DELETE ON public.diagnostic_response_versions
  FOR EACH ROW EXECUTE FUNCTION private.reject_diagnostic_response_mutation();

CREATE OR REPLACE FUNCTION private.audit_diagnostic_response_insert()
RETURNS trigger LANGUAGE plpgsql SECURITY DEFINER SET search_path = ''
AS $$
BEGIN
  INSERT INTO private.security_audit_events(actor_id,action,target_type,target_id,outcome,reason_category)
  VALUES(auth.uid(),'diagnostic_response_saved','diagnostic_attempt',NEW.attempt_id,'success','learner_action');
  RETURN NEW;
END;
$$;
CREATE TRIGGER diagnostic_response_versions_audit
  AFTER INSERT ON public.diagnostic_response_versions
  FOR EACH ROW EXECUTE FUNCTION private.audit_diagnostic_response_insert();

CREATE OR REPLACE FUNCTION public.create_diagnostic_attempt(p_version_id uuid,p_idempotency_key uuid)
RETURNS TABLE(attempt_id uuid,learner_id uuid,diagnostic_version_id uuid,status text,started_at timestamptz,submitted_at timestamptz,is_replay boolean)
LANGUAGE plpgsql SECURITY DEFINER SET search_path = ''
AS $$
DECLARE
  actor uuid := auth.uid();
  selected_version public.diagnostic_versions%ROWTYPE;
  existing public.diagnostic_attempts%ROWTYPE;
  created public.diagnostic_attempts%ROWTYPE;
BEGIN
  IF actor IS NULL OR p_idempotency_key IS NULL OR NOT private.current_account_is_active()
    OR NOT private.current_user_has_role('student'::public.app_role) THEN
    RAISE EXCEPTION USING ERRCODE='42501', MESSAGE='diagnostic_attempt_forbidden';
  END IF;
  SELECT v.* INTO selected_version FROM public.diagnostic_versions v WHERE v.id=p_version_id FOR UPDATE;
  IF NOT FOUND OR selected_version.release_state <> 'published'
    OR NOT EXISTS(SELECT 1 FROM public.course_enrolments e
      WHERE e.learner_id=actor AND e.pathway_id=selected_version.pathway_id AND e.status='active') THEN
    RAISE EXCEPTION USING ERRCODE='P0002', MESSAGE='diagnostic_not_available';
  END IF;
  SELECT a.* INTO existing FROM public.diagnostic_attempts a
    WHERE a.learner_id=actor AND a.diagnostic_version_id=p_version_id FOR UPDATE;
  IF FOUND THEN
    INSERT INTO private.security_audit_events(actor_id,action,target_type,target_id,outcome,reason_category)
    VALUES(actor,'diagnostic_attempt_resumed','diagnostic_attempt',existing.id,'success','learner_action');
    RETURN QUERY SELECT existing.id,existing.learner_id,existing.diagnostic_version_id,
      existing.status,existing.started_at,existing.submitted_at,true;
    RETURN;
  END IF;
  INSERT INTO public.diagnostic_attempts(learner_id,diagnostic_version_id,idempotency_key)
    VALUES(actor,p_version_id,p_idempotency_key) RETURNING * INTO created;
  INSERT INTO private.security_audit_events(actor_id,action,target_type,target_id,outcome,reason_category)
    VALUES(actor,'diagnostic_attempt_started','diagnostic_attempt',created.id,'success','learner_action');
  RETURN QUERY SELECT created.id,created.learner_id,created.diagnostic_version_id,
    created.status,created.started_at,created.submitted_at,false;
END;
$$;

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
      AND o.observation_code=p_observation_code AND o.group_code='RV'
      AND o.learner_capture_enabled FOR SHARE;
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
    WHERE o.diagnostic_version_id=attempt.diagnostic_version_id AND o.group_code='RV' AND o.learner_capture_enabled;
  SELECT count(DISTINCT r.observation_id)::integer INTO saved
    FROM public.diagnostic_response_versions r JOIN public.diagnostic_observations o ON o.id=r.observation_id
    WHERE r.attempt_id=p_attempt_id AND o.group_code='RV';
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

ALTER FUNCTION public.create_diagnostic_attempt(uuid,uuid) OWNER TO postgres;
ALTER FUNCTION public.save_diagnostic_response(uuid,text,jsonb) OWNER TO postgres;
ALTER FUNCTION public.submit_diagnostic_attempt(uuid) OWNER TO postgres;
REVOKE ALL ON FUNCTION public.create_diagnostic_attempt(uuid,uuid) FROM PUBLIC,anon,authenticated;
REVOKE ALL ON FUNCTION public.save_diagnostic_response(uuid,text,jsonb) FROM PUBLIC,anon,authenticated;
REVOKE ALL ON FUNCTION public.submit_diagnostic_attempt(uuid) FROM PUBLIC,anon,authenticated;
GRANT EXECUTE ON FUNCTION public.create_diagnostic_attempt(uuid,uuid) TO authenticated;
GRANT EXECUTE ON FUNCTION public.save_diagnostic_response(uuid,text,jsonb) TO authenticated;
GRANT EXECUTE ON FUNCTION public.submit_diagnostic_attempt(uuid) TO authenticated;

CREATE OR REPLACE FUNCTION public.record_worker_diagnostic_failure(
  p_actor_id uuid,p_action text,p_target_id uuid,p_outcome text,p_failure_category text DEFAULT NULL
)
RETURNS boolean LANGUAGE plpgsql SECURITY DEFINER SET search_path = ''
AS $$
DECLARE resource_type text; reason text;
BEGIN
  IF coalesce(auth.jwt()->>'role','') <> 'service_role' OR p_actor_id IS NULL
    OR NOT EXISTS(SELECT 1 FROM auth.users u WHERE u.id=p_actor_id) THEN RETURN false; END IF;
  CASE p_action
    WHEN 'student_diagnostic_attempt_start' THEN resource_type:='diagnostic_version';
    WHEN 'student_diagnostic_response_save' THEN resource_type:='diagnostic_attempt';
    WHEN 'student_diagnostic_attempt_submit' THEN resource_type:='diagnostic_attempt';
    ELSE RETURN false;
  END CASE;
  IF p_outcome='denied' AND p_failure_category IS NULL THEN reason:='resource_scope_denied';
  ELSIF p_outcome='failed' AND p_failure_category IN ('resource_not_found','state_conflict','validation_failed','operation_failed') THEN reason:=p_failure_category;
  ELSE RETURN false;
  END IF;
  IF p_action <> 'student_diagnostic_attempt_start' AND p_target_id IS NULL THEN RETURN false; END IF;
  INSERT INTO private.security_audit_events(actor_id,action,target_type,target_id,outcome,reason_category)
    VALUES(p_actor_id,p_action,resource_type,p_target_id,p_outcome,reason);
  RETURN true;
END;
$$;
ALTER FUNCTION public.record_worker_diagnostic_failure(uuid,text,uuid,text,text) OWNER TO postgres;
REVOKE ALL ON FUNCTION public.record_worker_diagnostic_failure(uuid,text,uuid,text,text) FROM PUBLIC,anon,authenticated;
GRANT EXECUTE ON FUNCTION public.record_worker_diagnostic_failure(uuid,text,uuid,text,text) TO service_role;

COMMENT ON TABLE public.diagnostic_attempts IS
  'Student-owned Diagnostic attempts; separate from practice attempts and human-grading submissions.';
COMMENT ON TABLE public.diagnostic_response_versions IS
  'Append-only, unscored Diagnostic evidence; no teacher-only marking content is stored here.';
