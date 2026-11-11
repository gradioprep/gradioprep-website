-- Phase 2: immutable, versioned Evaluation Report snapshots for PA and completed SA segments.
-- Generic schema only. No live curriculum mapping, score, feedback or learner content is seeded.

ALTER TABLE public.milestone_assessment_task_mappings
  ADD COLUMN report_required boolean NOT NULL DEFAULT true;

ALTER TABLE public.diagnostic_versions
  ADD COLUMN route_version_id uuid REFERENCES public.curriculum_route_versions(id) ON DELETE RESTRICT;

ALTER TABLE public.curriculum_unit_outcome_mappings
  ADD CONSTRAINT curriculum_unit_outcome_mappings_id_unit_unique
  UNIQUE (id, curriculum_unit_version_id);

CREATE OR REPLACE FUNCTION private.validate_diagnostic_route_lineage()
RETURNS trigger LANGUAGE plpgsql SECURITY DEFINER SET search_path = ''
AS $function$
DECLARE selected_route_key text;
BEGIN
  IF TG_OP = 'UPDATE' AND OLD.release_state IN ('published','retired')
    AND NEW.route_version_id IS DISTINCT FROM OLD.route_version_id THEN
    RAISE EXCEPTION USING ERRCODE='55000', MESSAGE='published_diagnostic_route_immutable';
  END IF;
  IF NEW.route_version_id IS NOT NULL THEN
    SELECT route.route_key INTO selected_route_key
    FROM public.curriculum_route_versions AS route WHERE route.id=NEW.route_version_id;
    IF selected_route_key IS NULL OR selected_route_key IS DISTINCT FROM NEW.pathway_id THEN
      RAISE EXCEPTION USING ERRCODE='23514', MESSAGE='diagnostic_route_pathway_mismatch';
    END IF;
  END IF;
  RETURN NEW;
END;
$function$;
ALTER FUNCTION private.validate_diagnostic_route_lineage() OWNER TO postgres;
REVOKE ALL ON FUNCTION private.validate_diagnostic_route_lineage() FROM PUBLIC,anon,authenticated,service_role;
CREATE TRIGGER diagnostic_versions_route_lineage
  BEFORE INSERT OR UPDATE ON public.diagnostic_versions
  FOR EACH ROW EXECUTE FUNCTION private.validate_diagnostic_route_lineage();

CREATE TABLE public.diagnostic_observation_outcome_mappings (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  diagnostic_version_id uuid NOT NULL,
  diagnostic_observation_id uuid NOT NULL,
  route_version_id uuid NOT NULL REFERENCES public.curriculum_route_versions(id) ON DELETE RESTRICT,
  curriculum_unit_version_id uuid NOT NULL REFERENCES public.curriculum_unit_versions(id) ON DELETE RESTRICT,
  curriculum_unit_outcome_mapping_id uuid NOT NULL,
  mapping_status text NOT NULL DEFAULT 'pending_review'
    CHECK (mapping_status IN ('pending_review', 'direct', 'unmapped')),
  mapping_rationale text NOT NULL CHECK (char_length(btrim(mapping_rationale)) BETWEEN 1 AND 2000),
  reviewed_by uuid REFERENCES auth.users(id) ON DELETE RESTRICT,
  reviewed_at timestamptz,
  created_at timestamptz NOT NULL DEFAULT now(),
  FOREIGN KEY (diagnostic_observation_id, diagnostic_version_id)
    REFERENCES public.diagnostic_observations(id, diagnostic_version_id) ON DELETE RESTRICT,
  FOREIGN KEY (curriculum_unit_outcome_mapping_id, curriculum_unit_version_id)
    REFERENCES public.curriculum_unit_outcome_mappings(id, curriculum_unit_version_id) ON DELETE RESTRICT,
  UNIQUE (diagnostic_observation_id, curriculum_unit_outcome_mapping_id),
  CHECK (mapping_status NOT IN ('direct', 'unmapped') OR (reviewed_by IS NOT NULL AND reviewed_at IS NOT NULL))
);

CREATE INDEX diagnostic_observation_outcome_mappings_observation_idx
  ON public.diagnostic_observation_outcome_mappings(diagnostic_version_id, diagnostic_observation_id, mapping_status);

CREATE OR REPLACE FUNCTION private.validate_diagnostic_observation_outcome_mapping()
RETURNS trigger LANGUAGE plpgsql SECURITY DEFINER SET search_path = ''
AS $$
DECLARE
  selected_pathway text; route_key text; route_state text; unit_route_id uuid; unit_state text;
  outcome_state text; outcome_reviewer uuid; outcome_reviewed_at timestamptz; listening_observation boolean;
BEGIN
  IF TG_OP = 'DELETE' THEN
    IF OLD.mapping_status IN ('direct', 'unmapped') THEN
      RAISE EXCEPTION USING ERRCODE = '55000', MESSAGE = 'diagnostic_outcome_mapping_immutable';
    END IF;
    RETURN OLD;
  END IF;
  IF TG_OP = 'UPDATE' AND OLD.mapping_status IN ('direct', 'unmapped') THEN
    RAISE EXCEPTION USING ERRCODE = '55000', MESSAGE = 'diagnostic_outcome_mapping_immutable';
  END IF;
  SELECT diagnostic.pathway_id, route.route_key, route.review_state, unit.route_version_id,
         unit.release_state, outcome.mapping_status, outcome.reviewed_by, outcome.reviewed_at,
         (observation.group_code = 'L')
    INTO selected_pathway, route_key, route_state, unit_route_id, unit_state,
         outcome_state, outcome_reviewer, outcome_reviewed_at, listening_outcome
  FROM public.diagnostic_versions AS diagnostic
  JOIN public.curriculum_route_versions AS route ON route.id = NEW.route_version_id
  JOIN public.curriculum_unit_versions AS unit ON unit.id = NEW.curriculum_unit_version_id
  JOIN public.curriculum_unit_outcome_mappings AS outcome
    ON outcome.id = NEW.curriculum_unit_outcome_mapping_id
   AND outcome.curriculum_unit_version_id = unit.id
  JOIN public.diagnostic_observations AS observation
    ON observation.id = NEW.diagnostic_observation_id
   AND observation.diagnostic_version_id = NEW.diagnostic_version_id
  WHERE diagnostic.id = NEW.diagnostic_version_id;
  IF NOT FOUND OR selected_pathway IS DISTINCT FROM route_key OR unit_route_id IS DISTINCT FROM NEW.route_version_id THEN
    RAISE EXCEPTION USING ERRCODE = '23514', MESSAGE = 'diagnostic_outcome_mapping_route_mismatch';
  END IF;
  IF NEW.mapping_status = 'direct' AND (
    route_state <> 'verified' OR unit_state <> 'published' OR outcome_state <> 'direct'
    OR outcome_reviewer IS NULL OR outcome_reviewed_at IS NULL
    OR NEW.reviewed_by IS NULL OR NEW.reviewed_at IS NULL OR coalesce(listening_observation, false)
  ) THEN
    RAISE EXCEPTION USING ERRCODE = '55000', MESSAGE = 'diagnostic_outcome_mapping_requires_direct_non_listening_outcome';
  END IF;
  RETURN NEW;
END;
$$;
ALTER FUNCTION private.validate_diagnostic_observation_outcome_mapping() OWNER TO postgres;
REVOKE ALL ON FUNCTION private.validate_diagnostic_observation_outcome_mapping() FROM PUBLIC, anon, authenticated, service_role;
CREATE TRIGGER diagnostic_observation_outcome_mappings_validate
  BEFORE INSERT OR UPDATE OR DELETE ON public.diagnostic_observation_outcome_mappings
  FOR EACH ROW EXECUTE FUNCTION private.validate_diagnostic_observation_outcome_mapping();

CREATE TABLE public.evaluation_report_records (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  report_scope text NOT NULL CHECK (report_scope IN ('pa_baseline', 'sa_segment')),
  learner_id uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  course_enrolment_id uuid NOT NULL,
  route_version_id uuid NOT NULL REFERENCES public.curriculum_route_versions(id) ON DELETE RESTRICT,
  diagnostic_attempt_id uuid REFERENCES public.diagnostic_attempts(id) ON DELETE CASCADE,
  milestone_cycle_version_id uuid,
  milestone_segment_id uuid,
  created_at timestamptz NOT NULL DEFAULT now(),
  FOREIGN KEY (course_enrolment_id, learner_id) REFERENCES public.course_enrolments(id, learner_id) ON DELETE CASCADE,
  FOREIGN KEY (milestone_cycle_version_id, route_version_id)
    REFERENCES public.milestone_cycle_versions(id, route_version_id) ON DELETE RESTRICT,
  FOREIGN KEY (milestone_segment_id, milestone_cycle_version_id, route_version_id)
    REFERENCES public.milestone_segments(id, milestone_cycle_version_id, route_version_id) ON DELETE RESTRICT,
  CHECK (
    (report_scope = 'pa_baseline' AND diagnostic_attempt_id IS NOT NULL
      AND milestone_cycle_version_id IS NULL AND milestone_segment_id IS NULL)
    OR (report_scope = 'sa_segment' AND diagnostic_attempt_id IS NULL
      AND milestone_cycle_version_id IS NOT NULL AND milestone_segment_id IS NOT NULL)
  ),
  UNIQUE (id, report_scope, learner_id)
);
CREATE UNIQUE INDEX evaluation_report_records_pa_attempt_unique
  ON public.evaluation_report_records(diagnostic_attempt_id) WHERE report_scope = 'pa_baseline';
CREATE UNIQUE INDEX evaluation_report_records_sa_segment_unique
  ON public.evaluation_report_records(learner_id, course_enrolment_id, milestone_cycle_version_id, milestone_segment_id)
  WHERE report_scope = 'sa_segment';

CREATE TABLE public.evaluation_report_versions (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  report_record_id uuid NOT NULL,
  report_scope text NOT NULL CHECK (report_scope IN ('pa_baseline', 'sa_segment')),
  learner_id uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  version_number integer NOT NULL CHECK (version_number > 0),
  idempotency_key uuid NOT NULL,
  supersedes_version_id uuid,
  curriculum_mapping_status text NOT NULL CHECK (curriculum_mapping_status IN ('complete_direct', 'pending_review', 'contains_unmapped')),
  evidence_sufficiency_status text NOT NULL CHECK (evidence_sufficiency_status IN ('sufficient', 'insufficient')),
  scope_snapshot jsonb NOT NULL CHECK (jsonb_typeof(scope_snapshot) = 'object'),
  content_snapshot jsonb NOT NULL CHECK (jsonb_typeof(content_snapshot) = 'object'),
  unit_set_snapshot jsonb NOT NULL CHECK (jsonb_typeof(unit_set_snapshot) = 'object'),
  curriculum_mapping_snapshot jsonb NOT NULL CHECK (jsonb_typeof(curriculum_mapping_snapshot) = 'array'),
  learner_evidence_snapshot jsonb NOT NULL CHECK (jsonb_typeof(learner_evidence_snapshot) = 'array'),
  published_feedback_snapshot jsonb NOT NULL CHECK (jsonb_typeof(published_feedback_snapshot) = 'object'),
  eligible_analytics_snapshot jsonb NOT NULL CHECK (jsonb_typeof(eligible_analytics_snapshot) = 'object'),
  created_by uuid NOT NULL REFERENCES auth.users(id) ON DELETE RESTRICT,
  created_at timestamptz NOT NULL DEFAULT clock_timestamp(),
  FOREIGN KEY (report_record_id, report_scope, learner_id)
    REFERENCES public.evaluation_report_records(id, report_scope, learner_id) ON DELETE CASCADE,
  FOREIGN KEY (supersedes_version_id, report_record_id)
    REFERENCES public.evaluation_report_versions(id, report_record_id) ON DELETE RESTRICT,
  UNIQUE (report_record_id, version_number),
  UNIQUE (learner_id, idempotency_key),
  UNIQUE (id, report_record_id),
  CHECK ((version_number = 1 AND supersedes_version_id IS NULL) OR (version_number > 1 AND supersedes_version_id IS NOT NULL))
);
CREATE INDEX evaluation_report_versions_record_idx ON public.evaluation_report_versions(report_record_id, version_number DESC);

CREATE TABLE private.evaluation_report_teacher_access_grants (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  report_record_id uuid NOT NULL REFERENCES public.evaluation_report_records(id) ON DELETE CASCADE,
  teacher_user_id uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  granted_by uuid NOT NULL REFERENCES auth.users(id) ON DELETE RESTRICT,
  granted_at timestamptz NOT NULL DEFAULT clock_timestamp(),
  reason text NOT NULL CHECK (char_length(btrim(reason)) BETWEEN 3 AND 240),
  revoked_by uuid REFERENCES auth.users(id) ON DELETE SET NULL,
  revoked_at timestamptz,
  CHECK ((revoked_by IS NULL) = (revoked_at IS NULL))
);
CREATE UNIQUE INDEX evaluation_report_teacher_access_active_unique
  ON private.evaluation_report_teacher_access_grants(report_record_id, teacher_user_id) WHERE revoked_at IS NULL;
CREATE INDEX evaluation_report_teacher_access_teacher_idx
  ON private.evaluation_report_teacher_access_grants(teacher_user_id, granted_at DESC) WHERE revoked_at IS NULL;

ALTER TABLE public.diagnostic_observation_outcome_mappings ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.evaluation_report_records ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.evaluation_report_versions ENABLE ROW LEVEL SECURITY;
ALTER TABLE private.evaluation_report_teacher_access_grants ENABLE ROW LEVEL SECURITY;
REVOKE ALL ON public.diagnostic_observation_outcome_mappings, public.evaluation_report_records, public.evaluation_report_versions
  FROM PUBLIC, anon, authenticated, service_role;
REVOKE ALL ON private.evaluation_report_teacher_access_grants FROM PUBLIC, anon, authenticated, service_role;
GRANT SELECT ON public.diagnostic_observation_outcome_mappings TO authenticated;
CREATE POLICY diagnostic_observation_outcome_mappings_owner_read ON public.diagnostic_observation_outcome_mappings
  FOR SELECT TO authenticated USING (
    private.current_account_is_active() AND private.current_user_has_role('owner'::public.app_role)
    AND coalesce(auth.jwt() ->> 'aal', 'aal1') = 'aal2'
  );

CREATE OR REPLACE FUNCTION private.prevent_evaluation_report_mutation()
RETURNS trigger LANGUAGE plpgsql SET search_path = ''
AS $$
BEGIN
  IF TG_OP = 'DELETE' AND pg_catalog.pg_trigger_depth() > 1 THEN RETURN OLD; END IF;
  RAISE EXCEPTION USING ERRCODE = '42501', MESSAGE = 'evaluation_report_immutable';
END;
$$;
REVOKE ALL ON FUNCTION private.prevent_evaluation_report_mutation() FROM PUBLIC, anon, authenticated, service_role;
CREATE TRIGGER evaluation_report_records_immutable BEFORE UPDATE OR DELETE ON public.evaluation_report_records
  FOR EACH ROW EXECUTE FUNCTION private.prevent_evaluation_report_mutation();
CREATE TRIGGER evaluation_report_versions_immutable BEFORE UPDATE OR DELETE ON public.evaluation_report_versions
  FOR EACH ROW EXECUTE FUNCTION private.prevent_evaluation_report_mutation();

CREATE OR REPLACE FUNCTION private.can_read_evaluation_report(p_report_record_id uuid)
RETURNS boolean LANGUAGE sql STABLE SECURITY DEFINER SET search_path = ''
AS $$
  SELECT EXISTS (
    SELECT 1 FROM public.evaluation_report_records AS report
    WHERE report.id = p_report_record_id AND private.current_account_is_active()
      AND (
        (report.learner_id = (SELECT auth.uid()) AND private.current_user_has_role('student'::public.app_role))
        OR (private.current_user_has_role('guardian'::public.app_role)
          AND private.can_view_learner(report.learner_id, 'progress'))
        OR (private.current_user_has_role('grader'::public.app_role)
          AND coalesce(auth.jwt() ->> 'aal', 'aal1') = 'aal2'
          AND EXISTS (SELECT 1 FROM private.evaluation_report_teacher_access_grants AS g
            WHERE g.report_record_id = report.id AND g.teacher_user_id = (SELECT auth.uid()) AND g.revoked_at IS NULL))
        OR (private.current_user_has_role('owner'::public.app_role)
          AND coalesce(auth.jwt() ->> 'aal', 'aal1') = 'aal2')
      )
  );
$$;
ALTER FUNCTION private.can_read_evaluation_report(uuid) OWNER TO postgres;
REVOKE ALL ON FUNCTION private.can_read_evaluation_report(uuid) FROM PUBLIC, anon, authenticated, service_role;
GRANT EXECUTE ON FUNCTION private.can_read_evaluation_report(uuid) TO authenticated;
CREATE POLICY evaluation_report_records_select_scoped ON public.evaluation_report_records
  FOR SELECT TO authenticated USING (private.can_read_evaluation_report(id));
CREATE POLICY evaluation_report_versions_select_scoped ON public.evaluation_report_versions
  FOR SELECT TO authenticated USING (private.can_read_evaluation_report(report_record_id));

CREATE OR REPLACE FUNCTION public.create_preliminary_evaluation_report(
  p_diagnostic_attempt_id uuid, p_course_enrolment_id uuid, p_route_version_id uuid, p_idempotency_key uuid
)
RETURNS TABLE(report_record_id uuid, report_version_id uuid, version_number integer,
  curriculum_mapping_status text, evidence_sufficiency_status text, is_replay boolean)
LANGUAGE plpgsql SECURITY DEFINER SET search_path = ''
AS $$
DECLARE
  actor_id uuid := auth.uid();
  selected_attempt public.diagnostic_attempts%ROWTYPE;
  selected_version public.diagnostic_versions%ROWTYPE;
  selected_enrolment public.course_enrolments%ROWTYPE;
  selected_route public.curriculum_route_versions%ROWTYPE;
  selected_report public.evaluation_report_records%ROWTYPE;
  previous_version public.evaluation_report_versions%ROWTYPE;
  created_version public.evaluation_report_versions%ROWTYPE;
  expected_observations integer; evidenced_observations integer; directly_mapped_observations integer;
  pending_observations integer; mapping_state text; evidence_state text;
  content_snapshot jsonb; mapping_snapshot jsonb; evidence_snapshot jsonb; next_version integer;
BEGIN
  IF actor_id IS NULL OR p_diagnostic_attempt_id IS NULL OR p_course_enrolment_id IS NULL
    OR p_route_version_id IS NULL OR p_idempotency_key IS NULL
    OR NOT private.current_account_is_active() OR NOT private.current_user_has_role('student'::public.app_role) THEN
    RAISE EXCEPTION USING ERRCODE = '42501', MESSAGE = 'preliminary_evaluation_report_forbidden';
  END IF;
  PERFORM pg_catalog.pg_advisory_xact_lock(pg_catalog.hashtextextended(actor_id::text || ':pa-report:' || p_idempotency_key::text, 0));
  SELECT attempt.* INTO selected_attempt FROM public.diagnostic_attempts AS attempt
    WHERE attempt.id = p_diagnostic_attempt_id AND attempt.learner_id = actor_id AND attempt.status = 'submitted' FOR SHARE;
  IF NOT FOUND THEN RAISE EXCEPTION USING ERRCODE = '42501', MESSAGE = 'preliminary_evaluation_report_attempt_forbidden'; END IF;
  SELECT version.* INTO selected_version FROM public.diagnostic_versions AS version WHERE version.id = selected_attempt.diagnostic_version_id;
  SELECT enrolment.* INTO selected_enrolment FROM public.course_enrolments AS enrolment
    WHERE enrolment.id = p_course_enrolment_id AND enrolment.learner_id = actor_id AND enrolment.status = 'active';
  SELECT route.* INTO selected_route FROM public.curriculum_route_versions AS route
    WHERE route.id = p_route_version_id AND route.review_state = 'verified';
  IF selected_enrolment.id IS NULL OR selected_version.id IS NULL OR selected_route.id IS NULL
    OR selected_enrolment.pathway_id IS DISTINCT FROM selected_route.route_key
    OR selected_version.pathway_id IS DISTINCT FROM selected_route.route_key
    OR selected_version.route_version_id IS DISTINCT FROM selected_route.id THEN
    RAISE EXCEPTION USING ERRCODE = '42501', MESSAGE = 'preliminary_evaluation_report_route_forbidden';
  END IF;
  SELECT count(*)::integer INTO expected_observations FROM public.diagnostic_observations AS o
    WHERE o.diagnostic_version_id = selected_version.id AND o.learner_capture_enabled;
  SELECT count(*)::integer INTO evidenced_observations FROM public.diagnostic_observations AS o
    WHERE o.diagnostic_version_id = selected_version.id AND o.learner_capture_enabled
      AND EXISTS (SELECT 1 FROM public.diagnostic_response_versions AS r WHERE r.attempt_id = selected_attempt.id AND r.observation_id = o.id);
  SELECT count(*)::integer INTO directly_mapped_observations FROM public.diagnostic_observations AS o
    WHERE o.diagnostic_version_id = selected_version.id AND o.learner_capture_enabled
      AND EXISTS (SELECT 1 FROM public.diagnostic_observation_outcome_mappings AS m
        WHERE m.diagnostic_observation_id = o.id AND m.diagnostic_version_id = selected_version.id
          AND m.route_version_id = selected_route.id AND m.mapping_status = 'direct'
          AND m.reviewed_by IS NOT NULL AND m.reviewed_at IS NOT NULL);
  SELECT count(*)::integer INTO pending_observations FROM public.diagnostic_observations AS o
    WHERE o.diagnostic_version_id = selected_version.id AND o.learner_capture_enabled
      AND EXISTS (SELECT 1 FROM public.diagnostic_observation_outcome_mappings AS m
        WHERE m.diagnostic_observation_id = o.id AND m.route_version_id = selected_route.id AND m.mapping_status = 'pending_review')
      AND NOT EXISTS (SELECT 1 FROM public.diagnostic_observation_outcome_mappings AS m
        WHERE m.diagnostic_observation_id = o.id AND m.route_version_id = selected_route.id AND m.mapping_status = 'direct');
  mapping_state := CASE WHEN expected_observations > 0 AND directly_mapped_observations = expected_observations THEN 'complete_direct'
    WHEN pending_observations > 0 THEN 'pending_review' ELSE 'contains_unmapped' END;
  evidence_state := CASE WHEN expected_observations > 0 AND evidenced_observations = expected_observations
    AND directly_mapped_observations = expected_observations THEN 'sufficient' ELSE 'insufficient' END;
  SELECT jsonb_build_object(
    'diagnostic_version_id', selected_version.id, 'diagnostic_code', selected_version.diagnostic_code,
    'diagnostic_title', selected_version.title, 'diagnostic_version', selected_version.version,
    'pathway_id', selected_version.pathway_id, 'total_minutes', selected_version.total_minutes,
    'sitting_count', selected_version.sitting_count,
    'observations', coalesce((SELECT jsonb_agg(jsonb_build_object('observation_id', o.id,
      'observation_code', o.observation_code, 'group_code', o.group_code, 'sitting_number', o.sitting_number,
      'sequence_number', o.sequence_number, 'response_kind', o.response_kind, 'capture_enabled', o.learner_capture_enabled)
      ORDER BY o.sequence_number) FROM public.diagnostic_observations AS o WHERE o.diagnostic_version_id = selected_version.id),'[]'::jsonb)
  ) INTO content_snapshot;
  SELECT coalesce(jsonb_agg(jsonb_build_object(
    'observation_id', o.id, 'observation_code', o.observation_code,
    'mapping_status', CASE WHEN EXISTS (SELECT 1 FROM public.diagnostic_observation_outcome_mappings AS m
      WHERE m.diagnostic_observation_id=o.id AND m.route_version_id=selected_route.id AND m.mapping_status='direct') THEN 'direct'
      WHEN EXISTS (SELECT 1 FROM public.diagnostic_observation_outcome_mappings AS m
      WHERE m.diagnostic_observation_id=o.id AND m.route_version_id=selected_route.id AND m.mapping_status='pending_review') THEN 'pending_review'
      ELSE 'unmapped' END,
    'direct_outcomes', coalesce((SELECT jsonb_agg(jsonb_build_object(
      'mapping_id',m.id,'unit_version_id',u.id,'unit_code',u.unit_code,'unit_version',u.version,
      'outcome_mapping_id',outcome.id,'outcome_reference',outcome.outcome_reference,
      'outcome_title',outcome.outcome_title,'source_locator',outcome.source_locator) ORDER BY outcome.outcome_reference)
      FROM public.diagnostic_observation_outcome_mappings AS m
      JOIN public.curriculum_unit_versions AS u ON u.id=m.curriculum_unit_version_id
      JOIN public.curriculum_unit_outcome_mappings AS outcome ON outcome.id=m.curriculum_unit_outcome_mapping_id
      WHERE m.diagnostic_observation_id=o.id AND m.route_version_id=selected_route.id AND m.mapping_status='direct'
        AND m.reviewed_by IS NOT NULL AND m.reviewed_at IS NOT NULL),'[]'::jsonb)
  ) ORDER BY o.sequence_number),'[]'::jsonb) INTO mapping_snapshot
  FROM public.diagnostic_observations AS o WHERE o.diagnostic_version_id=selected_version.id AND o.learner_capture_enabled;
  SELECT coalesce(jsonb_agg(jsonb_build_object('observation_id',o.id,'observation_code',o.observation_code,
    'response_version_id',r.id,'response_revision',r.revision_number,'response_saved_at',r.saved_at,
    'response_sha256',CASE WHEN r.id IS NULL THEN NULL ELSE encode(extensions.digest(r.response_json::text,'sha256'),'hex') END)
    ORDER BY o.sequence_number),'[]'::jsonb) INTO evidence_snapshot
  FROM public.diagnostic_observations AS o
  LEFT JOIN LATERAL (SELECT rv.* FROM public.diagnostic_response_versions AS rv
    WHERE rv.attempt_id=selected_attempt.id AND rv.observation_id=o.id ORDER BY rv.revision_number DESC LIMIT 1) AS r ON true
  WHERE o.diagnostic_version_id=selected_version.id AND o.learner_capture_enabled;
  INSERT INTO public.evaluation_report_records(report_scope,learner_id,course_enrolment_id,route_version_id,diagnostic_attempt_id)
    VALUES('pa_baseline',actor_id,selected_enrolment.id,selected_route.id,selected_attempt.id) ON CONFLICT DO NOTHING;
  SELECT report.* INTO selected_report FROM public.evaluation_report_records AS report
    WHERE report.report_scope='pa_baseline' AND report.diagnostic_attempt_id=selected_attempt.id FOR UPDATE;
  SELECT version.* INTO created_version FROM public.evaluation_report_versions AS version
    WHERE version.learner_id=actor_id AND version.idempotency_key=p_idempotency_key;
  IF FOUND THEN
    IF created_version.report_record_id IS DISTINCT FROM selected_report.id THEN
      RAISE EXCEPTION USING ERRCODE='P0001', MESSAGE='evaluation_report_idempotency_conflict';
    END IF;
    RETURN QUERY SELECT selected_report.id,created_version.id,created_version.version_number,
      created_version.curriculum_mapping_status,created_version.evidence_sufficiency_status,true;
    RETURN;
  END IF;
  SELECT coalesce(max(v.version_number),0)+1 INTO next_version FROM public.evaluation_report_versions AS v WHERE v.report_record_id=selected_report.id;
  SELECT v.* INTO previous_version FROM public.evaluation_report_versions AS v
    WHERE v.report_record_id=selected_report.id ORDER BY v.version_number DESC LIMIT 1;
  INSERT INTO public.evaluation_report_versions(report_record_id,report_scope,learner_id,version_number,idempotency_key,
    supersedes_version_id,curriculum_mapping_status,evidence_sufficiency_status,scope_snapshot,content_snapshot,
    unit_set_snapshot,curriculum_mapping_snapshot,learner_evidence_snapshot,published_feedback_snapshot,
    eligible_analytics_snapshot,created_by)
  VALUES(selected_report.id,'pa_baseline',actor_id,next_version,p_idempotency_key,previous_version.id,mapping_state,evidence_state,
    jsonb_build_object('scope','preliminary_assessment_baseline','course_enrolment_id',selected_enrolment.id,
      'route_version_id',selected_route.id,'route_key',selected_route.route_key,'awarding_body',selected_route.awarding_body,
      'programme_code',selected_route.programme_code,'subject_code',selected_route.subject_code,'course_code',selected_route.course_code,
      'level_code',selected_route.level_code,'academic_session',selected_route.academic_session,'syllabus_edition',selected_route.syllabus_edition,
      'official_source_title',selected_route.official_source_title,'official_source_url',selected_route.official_source_url,
      'source_checked_at',selected_route.source_checked_at,'diagnostic_attempt_id',selected_attempt.id,
      'attempt_submitted_at',selected_attempt.submitted_at,'report_scoring_state','unscored_baseline','official_grade_conversion','not_applicable'),
    content_snapshot,jsonb_build_object('scope','entry_baseline','milestone_unit_set',NULL),mapping_snapshot,evidence_snapshot,
    jsonb_build_object('status','not_applicable_unscored_preliminary_assessment','human_feedback_references','[]'::jsonb),
    jsonb_build_object('status','not_available_for_unscored_preliminary_assessment','score',NULL,'official_grade',NULL,'percentile_or_rank',NULL),actor_id)
  RETURNING * INTO created_version;
  INSERT INTO private.security_audit_events(actor_id,action,target_type,target_id,outcome,reason_category)
    VALUES(actor_id,'evaluation_report_created','evaluation_report_version',created_version.id,'success','pa_baseline');
  RETURN QUERY SELECT selected_report.id,created_version.id,created_version.version_number,mapping_state,evidence_state,false;
END;
$$;
ALTER FUNCTION public.create_preliminary_evaluation_report(uuid,uuid,uuid,uuid) OWNER TO postgres;
REVOKE ALL ON FUNCTION public.create_preliminary_evaluation_report(uuid,uuid,uuid,uuid) FROM PUBLIC,anon,service_role;
GRANT EXECUTE ON FUNCTION public.create_preliminary_evaluation_report(uuid,uuid,uuid,uuid) TO authenticated;

-- SA report creation below is a bounded report-finalisation operation: it requires every
-- required unit complete and every required task linked, submitted and human-feedback-published.
CREATE OR REPLACE FUNCTION public.create_sa_segment_evaluation_report(p_attempt_id uuid,p_idempotency_key uuid)
RETURNS TABLE(report_record_id uuid,report_version_id uuid,version_number integer,
  curriculum_mapping_status text,evidence_sufficiency_status text,is_replay boolean)
LANGUAGE plpgsql SECURITY DEFINER SET search_path = ''
AS $$
DECLARE
  actor_id uuid := auth.uid(); selected_link private.milestone_assessment_attempt_links%ROWTYPE;
  selected_attempt public.attempts%ROWTYPE; selected_mapping public.milestone_assessment_task_mappings%ROWTYPE;
  selected_enrolment public.course_enrolments%ROWTYPE; selected_route public.curriculum_route_versions%ROWTYPE;
  selected_cycle public.milestone_cycle_versions%ROWTYPE; selected_segment public.milestone_segments%ROWTYPE;
  selected_report public.evaluation_report_records%ROWTYPE; previous_version public.evaluation_report_versions%ROWTYPE;
  created_version public.evaluation_report_versions%ROWTYPE;
  required_units integer; completed_units integer; required_tasks integer; completed_tasks integer;
  complete_prompt_evidence boolean; valid_attainment_rows integer; mapping_state text; evidence_state text;
  content_snapshot jsonb; unit_snapshot jsonb; mapping_snapshot jsonb; evidence_snapshot jsonb;
  feedback_snapshot jsonb; analytics_snapshot jsonb; next_version integer;
BEGIN
  IF actor_id IS NULL OR p_attempt_id IS NULL OR p_idempotency_key IS NULL
    OR NOT private.current_account_is_active() OR NOT private.current_user_has_role('student'::public.app_role) THEN
    RAISE EXCEPTION USING ERRCODE='42501', MESSAGE='sa_evaluation_report_forbidden';
  END IF;
  PERFORM pg_catalog.pg_advisory_xact_lock(pg_catalog.hashtextextended(actor_id::text||':sa-report:'||p_idempotency_key::text,0));
  SELECT link.* INTO selected_link FROM private.milestone_assessment_attempt_links AS link
    WHERE link.attempt_id=p_attempt_id AND link.learner_id=actor_id;
  IF NOT FOUND THEN RAISE EXCEPTION USING ERRCODE='42501', MESSAGE='sa_evaluation_report_attempt_link_forbidden'; END IF;
  SELECT attempt.* INTO selected_attempt FROM public.attempts AS attempt
    WHERE attempt.id=selected_link.attempt_id AND attempt.learner_id=actor_id
      AND attempt.task_version_id=selected_link.task_version_id AND attempt.status='submitted';
  IF NOT FOUND THEN RAISE EXCEPTION USING ERRCODE='P0001', MESSAGE='sa_evaluation_report_requires_submitted_attempt'; END IF;
  SELECT m.* INTO selected_mapping FROM public.milestone_assessment_task_mappings AS m
    WHERE m.id=selected_link.task_mapping_id AND m.review_state='approved';
  SELECT e.* INTO selected_enrolment FROM public.course_enrolments AS e
    WHERE e.id=selected_link.enrolment_id AND e.learner_id=actor_id AND e.status='active';
  SELECT r.* INTO selected_route FROM public.curriculum_route_versions AS r
    WHERE r.id=selected_link.route_version_id AND r.review_state='verified';
  SELECT c.* INTO selected_cycle FROM public.milestone_cycle_versions AS c
    WHERE c.id=selected_link.milestone_cycle_version_id AND c.release_state='published' AND c.route_version_id=selected_link.route_version_id;
  SELECT s.* INTO selected_segment FROM public.milestone_segments AS s
    WHERE s.id=selected_link.milestone_segment_id AND s.milestone_cycle_version_id=selected_link.milestone_cycle_version_id AND s.route_version_id=selected_link.route_version_id;
  IF selected_mapping.id IS NULL OR selected_enrolment.id IS NULL OR selected_route.id IS NULL
    OR selected_cycle.id IS NULL OR selected_segment.id IS NULL
    OR selected_enrolment.pathway_id IS DISTINCT FROM selected_route.route_key THEN
    RAISE EXCEPTION USING ERRCODE='42501', MESSAGE='sa_evaluation_report_lineage_forbidden';
  END IF;
  SELECT count(*)::integer INTO required_units FROM public.milestone_unit_memberships AS m
    WHERE m.milestone_cycle_version_id=selected_cycle.id AND m.milestone_segment_id=selected_segment.id AND m.is_required;
  SELECT count(*)::integer INTO completed_units FROM public.milestone_unit_memberships AS m
    JOIN public.learner_unit_progress AS p ON p.milestone_unit_membership_id=m.id
      AND p.enrolment_id=selected_enrolment.id AND p.learner_id=actor_id AND p.status='completed'
    WHERE m.milestone_cycle_version_id=selected_cycle.id AND m.milestone_segment_id=selected_segment.id AND m.is_required;
  SELECT count(*)::integer INTO required_tasks FROM public.milestone_assessment_task_mappings AS m
    WHERE m.milestone_cycle_version_id=selected_cycle.id AND m.milestone_segment_id=selected_segment.id
      AND m.review_state='approved' AND m.report_required;
  SELECT count(DISTINCT m.id)::integer INTO completed_tasks FROM public.milestone_assessment_task_mappings AS m
    JOIN private.milestone_assessment_attempt_links AS link ON link.task_mapping_id=m.id
      AND link.learner_id=actor_id AND link.enrolment_id=selected_enrolment.id
    JOIN public.attempts AS attempt ON attempt.id=link.attempt_id AND attempt.status='submitted'
    JOIN private.timed_attempt_assessment_links AS timed_link ON timed_link.attempt_id=attempt.id
    JOIN public.assessment_submissions AS submission ON submission.id=timed_link.assessment_submission_id AND submission.status='feedback_published'
    WHERE m.milestone_cycle_version_id=selected_cycle.id AND m.milestone_segment_id=selected_segment.id
      AND m.review_state='approved' AND m.report_required
      AND EXISTS(SELECT 1 FROM public.assessment_versions AS v WHERE v.submission_id=submission.id);
  SELECT NOT EXISTS (
    SELECT 1 FROM public.milestone_assessment_task_mappings AS m
    JOIN public.milestone_assessment_prompt_outcome_mappings AS pm ON pm.task_mapping_id=m.id
    LEFT JOIN private.milestone_assessment_attempt_links AS link ON link.task_mapping_id=m.id
      AND link.learner_id=actor_id AND link.enrolment_id=selected_enrolment.id
    LEFT JOIN public.attempt_responses AS response ON response.attempt_id=link.attempt_id AND response.prompt_id=pm.task_version_prompt_id
    WHERE m.milestone_cycle_version_id=selected_cycle.id AND m.milestone_segment_id=selected_segment.id
      AND m.review_state='approved' AND m.report_required
      AND (link.attempt_id IS NULL OR response.id IS NULL OR btrim(response.response_text)='')
  ) INTO complete_prompt_evidence;
  SELECT count(*)::integer INTO valid_attainment_rows
  FROM private.milestone_assessment_attempt_links AS link
  JOIN public.milestone_assessment_task_mappings AS m ON m.id=link.task_mapping_id
  JOIN public.attempts AS attempt ON attempt.id=link.attempt_id AND attempt.status='submitted'
  JOIN private.timed_attempt_assessment_links AS timed_link ON timed_link.attempt_id=attempt.id
  JOIN public.assessment_submissions AS submission ON submission.id=timed_link.assessment_submission_id AND submission.status='feedback_published'
  JOIN LATERAL (SELECT v.id FROM public.assessment_versions AS v WHERE v.submission_id=submission.id ORDER BY v.version_number DESC LIMIT 1) AS latest ON true
  JOIN private.assessment_response_analytics AS analytics ON analytics.assessment_version_id=latest.id AND analytics.attainment_status='valid'
  WHERE link.learner_id=actor_id AND link.enrolment_id=selected_enrolment.id
    AND link.milestone_cycle_version_id=selected_cycle.id AND link.milestone_segment_id=selected_segment.id AND m.report_required;
  IF required_units=0 OR completed_units<>required_units OR required_tasks=0 OR completed_tasks<>required_tasks OR NOT complete_prompt_evidence THEN
    RAISE EXCEPTION USING ERRCODE='P0001', MESSAGE='sa_evaluation_report_segment_not_complete';
  END IF;
  mapping_state := 'complete_direct';
  evidence_state := CASE WHEN valid_attainment_rows=required_tasks THEN 'sufficient' ELSE 'insufficient' END;

  SELECT jsonb_build_object('assessment_code','SA'||selected_segment.segment_number::text,'segment_number',selected_segment.segment_number,
    'segment_title',selected_segment.title,'cycle_id',selected_cycle.id,'cycle_version',selected_cycle.version,
    'route_version_id',selected_route.id,'tasks',coalesce((SELECT jsonb_agg(jsonb_build_object(
      'task_mapping_id',m.id,'task_version_id',t.id,'task_code',t.task_code,'task_title',t.title,'task_version',t.version,
      'report_required',m.report_required,'prompts',(SELECT coalesce(jsonb_agg(jsonb_build_object('prompt_id',p.id,'sequence',p.sequence,'prompt_text',p.prompt_text) ORDER BY p.sequence),'[]'::jsonb)
        FROM public.task_version_prompts AS p WHERE p.task_version_id=t.id),
      'attempt_ids',(SELECT coalesce(jsonb_agg(l.attempt_id ORDER BY l.linked_at),'[]'::jsonb)
        FROM private.milestone_assessment_attempt_links AS l JOIN public.attempts AS a ON a.id=l.attempt_id
        WHERE l.task_mapping_id=m.id AND l.learner_id=actor_id AND l.enrolment_id=selected_enrolment.id AND a.status='submitted')
    ) ORDER BY t.task_code) FROM public.milestone_assessment_task_mappings AS m
      JOIN public.task_versions AS t ON t.id=m.task_version_id
      WHERE m.milestone_cycle_version_id=selected_cycle.id AND m.milestone_segment_id=selected_segment.id
        AND m.review_state='approved' AND m.report_required),'[]'::jsonb)) INTO content_snapshot;

  SELECT jsonb_build_object('cycle_id',selected_cycle.id,'cycle_version',selected_cycle.version,'segment_id',selected_segment.id,
    'segment_number',selected_segment.segment_number,'segment_title',selected_segment.title,'required_units',required_units,
    'completed_required_units',completed_units,'units',coalesce((SELECT jsonb_agg(jsonb_build_object(
      'membership_id',m.id,'unit_version_id',u.id,'unit_code',u.unit_code,'unit_version',u.version,'unit_title',u.title,
      'sequence_number',m.sequence_number,'is_required',m.is_required,'progress_status',coalesce(p.status,'not_started'),'completed_at',p.completed_at)
      ORDER BY m.sequence_number) FROM public.milestone_unit_memberships AS m
      JOIN public.curriculum_unit_versions AS u ON u.id=m.curriculum_unit_version_id
      LEFT JOIN public.learner_unit_progress AS p ON p.milestone_unit_membership_id=m.id AND p.enrolment_id=selected_enrolment.id AND p.learner_id=actor_id
      WHERE m.milestone_cycle_version_id=selected_cycle.id AND m.milestone_segment_id=selected_segment.id),'[]'::jsonb)) INTO unit_snapshot;

  SELECT coalesce(jsonb_agg(jsonb_build_object('task_mapping_id',m.id,'task_version_id',m.task_version_id,'assessment_code',m.assessment_code,
    'task_review_state',m.review_state,'prompts',coalesce((SELECT jsonb_agg(jsonb_build_object(
      'prompt_id',pm.task_version_prompt_id,'prompt_outcome_mapping_id',pm.id,'mapping_status',pm.mapping_status,
      'unit_membership_id',pm.milestone_unit_membership_id,'unit_version_id',pm.curriculum_unit_version_id,
      'outcome_mapping_id',pm.curriculum_unit_outcome_mapping_id,'outcome_reference',o.outcome_reference,'outcome_title',o.outcome_title,'source_locator',o.source_locator)
      ORDER BY p.sequence) FROM public.milestone_assessment_prompt_outcome_mappings AS pm
      JOIN public.task_version_prompts AS p ON p.id=pm.task_version_prompt_id
      JOIN public.curriculum_unit_outcome_mappings AS o ON o.id=pm.curriculum_unit_outcome_mapping_id
      WHERE pm.task_mapping_id=m.id AND pm.mapping_status='direct' AND pm.reviewed_by IS NOT NULL AND pm.reviewed_at IS NOT NULL),'[]'::jsonb)
    ) ORDER BY m.assessment_code),'[]'::jsonb) INTO mapping_snapshot
  FROM public.milestone_assessment_task_mappings AS m
  WHERE m.milestone_cycle_version_id=selected_cycle.id AND m.milestone_segment_id=selected_segment.id
    AND m.review_state='approved' AND m.report_required;

  SELECT coalesce(jsonb_agg(jsonb_build_object('attempt_id',link.attempt_id,'task_mapping_id',link.task_mapping_id,
    'task_version_id',link.task_version_id,'attempt_status',attempt.status,'submitted_at',attempt.submitted_at,
    'responses',coalesce((SELECT jsonb_agg(jsonb_build_object('response_id',response.id,'prompt_id',response.prompt_id,
      'response_version',response.version,'word_count',response.word_count,
      'response_sha256',encode(extensions.digest(response.response_text,'sha256'),'hex'),'updated_at',response.updated_at)
      ORDER BY prompt.sequence) FROM public.attempt_responses AS response
      JOIN public.task_version_prompts AS prompt ON prompt.id=response.prompt_id WHERE response.attempt_id=link.attempt_id),'[]'::jsonb)
  ) ORDER BY link.linked_at),'[]'::jsonb) INTO evidence_snapshot
  FROM private.milestone_assessment_attempt_links AS link JOIN public.attempts AS attempt ON attempt.id=link.attempt_id
  WHERE link.learner_id=actor_id AND link.enrolment_id=selected_enrolment.id
    AND link.milestone_cycle_version_id=selected_cycle.id AND link.milestone_segment_id=selected_segment.id AND attempt.status='submitted';

  SELECT jsonb_build_object('source','human_published_feedback_only','assessments',coalesce(jsonb_agg(jsonb_build_object(
    'attempt_id',link.attempt_id,'submission_id',submission.id,'assessment_version_id',latest.id,'assessment_version',latest.version_number,
    'published_at',latest.published_at,'published_by',latest.published_by,'rubric_version_id',latest.rubric_version_id,
    'overall_feedback',latest.overall_feedback,'criterion_results',coalesce((SELECT jsonb_agg(jsonb_build_object(
      'criterion_result_id',cr.id,'criterion_id',cr.rubric_criterion_id,'criterion_code',cr.criterion_code_snapshot,
      'criterion_title',cr.criterion_title_snapshot,'descriptor',cr.descriptor_snapshot,'points_awarded',cr.points_awarded,
      'max_points',cr.max_points_snapshot,'feedback',cr.feedback) ORDER BY cr.criterion_code_snapshot)
      FROM public.criterion_results AS cr WHERE cr.assessment_version_id=latest.id),'[]'::jsonb)
  ) ORDER BY link.linked_at),'[]'::jsonb)) INTO feedback_snapshot
  FROM private.milestone_assessment_attempt_links AS link
  JOIN public.milestone_assessment_task_mappings AS task_mapping ON task_mapping.id=link.task_mapping_id AND task_mapping.report_required
  JOIN public.attempts AS attempt ON attempt.id=link.attempt_id
  JOIN private.timed_attempt_assessment_links AS timed_link ON timed_link.attempt_id=attempt.id
  JOIN public.assessment_submissions AS submission ON submission.id=timed_link.assessment_submission_id AND submission.status='feedback_published'
  JOIN LATERAL (SELECT v.* FROM public.assessment_versions AS v WHERE v.submission_id=submission.id ORDER BY v.version_number DESC LIMIT 1) AS latest ON true
  WHERE link.learner_id=actor_id AND link.enrolment_id=selected_enrolment.id
    AND link.milestone_cycle_version_id=selected_cycle.id AND link.milestone_segment_id=selected_segment.id;

  SELECT jsonb_build_object('aggregation','none_per_task_only','cohort_rank_or_percentile',NULL,
    'assessments',coalesce(jsonb_agg(jsonb_build_object('assessment_version_id',analytics.assessment_version_id,
      'submission_id',analytics.submission_id,'rubric_version_id',analytics.rubric_version_id,
      'attainment_status',analytics.attainment_status,'score_awarded',CASE WHEN analytics.attainment_status='valid' THEN analytics.score_awarded ELSE NULL END,
      'score_max',CASE WHEN analytics.attainment_status='valid' THEN analytics.score_max ELSE NULL END,
      'attainment_percent',CASE WHEN analytics.attainment_status='valid' THEN analytics.attainment_percent ELSE NULL END,
      'elapsed_response_status',analytics.elapsed_response_status,
      'elapsed_response_seconds',CASE WHEN analytics.comparability_status='eligible' AND analytics.elapsed_response_status='valid' THEN analytics.elapsed_response_seconds ELSE NULL END,
      'comparability_status',analytics.comparability_status) ORDER BY analytics.assessment_version_id),'[]'::jsonb)) INTO analytics_snapshot
  FROM private.milestone_assessment_attempt_links AS link
  JOIN public.milestone_assessment_task_mappings AS task_mapping ON task_mapping.id=link.task_mapping_id AND task_mapping.report_required
  JOIN public.attempts AS attempt ON attempt.id=link.attempt_id
  JOIN private.timed_attempt_assessment_links AS timed_link ON timed_link.attempt_id=attempt.id
  JOIN public.assessment_submissions AS submission ON submission.id=timed_link.assessment_submission_id
  JOIN LATERAL (SELECT v.id FROM public.assessment_versions AS v WHERE v.submission_id=submission.id ORDER BY v.version_number DESC LIMIT 1) AS latest ON true
  JOIN private.assessment_response_analytics AS analytics ON analytics.assessment_version_id=latest.id
  WHERE link.learner_id=actor_id AND link.enrolment_id=selected_enrolment.id
    AND link.milestone_cycle_version_id=selected_cycle.id AND link.milestone_segment_id=selected_segment.id;

  INSERT INTO public.evaluation_report_records(report_scope,learner_id,course_enrolment_id,route_version_id,milestone_cycle_version_id,milestone_segment_id)
    VALUES('sa_segment',actor_id,selected_enrolment.id,selected_route.id,selected_cycle.id,selected_segment.id) ON CONFLICT DO NOTHING;
  SELECT report.* INTO selected_report FROM public.evaluation_report_records AS report
    WHERE report.report_scope='sa_segment' AND report.learner_id=actor_id AND report.course_enrolment_id=selected_enrolment.id
      AND report.milestone_cycle_version_id=selected_cycle.id AND report.milestone_segment_id=selected_segment.id FOR UPDATE;
  SELECT v.* INTO created_version FROM public.evaluation_report_versions AS v WHERE v.learner_id=actor_id AND v.idempotency_key=p_idempotency_key;
  IF FOUND THEN
    IF created_version.report_record_id IS DISTINCT FROM selected_report.id THEN
      RAISE EXCEPTION USING ERRCODE='P0001', MESSAGE='evaluation_report_idempotency_conflict';
    END IF;
    RETURN QUERY SELECT selected_report.id,created_version.id,created_version.version_number,created_version.curriculum_mapping_status,created_version.evidence_sufficiency_status,true;
    RETURN;
  END IF;
  SELECT coalesce(max(v.version_number),0)+1 INTO next_version FROM public.evaluation_report_versions AS v WHERE v.report_record_id=selected_report.id;
  SELECT v.* INTO previous_version FROM public.evaluation_report_versions AS v WHERE v.report_record_id=selected_report.id ORDER BY v.version_number DESC LIMIT 1;
  INSERT INTO public.evaluation_report_versions(report_record_id,report_scope,learner_id,version_number,idempotency_key,supersedes_version_id,
    curriculum_mapping_status,evidence_sufficiency_status,scope_snapshot,content_snapshot,unit_set_snapshot,curriculum_mapping_snapshot,
    learner_evidence_snapshot,published_feedback_snapshot,eligible_analytics_snapshot,created_by)
  VALUES(selected_report.id,'sa_segment',actor_id,next_version,p_idempotency_key,previous_version.id,mapping_state,evidence_state,
    jsonb_build_object('scope','summative_assessment_milestone_segment','assessment_code','SA'||selected_segment.segment_number::text,
      'learner_id',actor_id,'course_enrolment_id',selected_enrolment.id,'route_version_id',selected_route.id,'route_key',selected_route.route_key,
      'cycle_version_id',selected_cycle.id,'segment_id',selected_segment.id,'segment_number',selected_segment.segment_number,
      'segment_title',selected_segment.title,'anchor_attempt_id',selected_attempt.id,'required_task_mappings',required_tasks,
      'completed_required_task_mappings',completed_tasks,'required_unit_memberships',required_units,'completed_required_unit_memberships',completed_units),
    content_snapshot,unit_snapshot,mapping_snapshot,evidence_snapshot,feedback_snapshot,analytics_snapshot,actor_id)
  RETURNING * INTO created_version;
  INSERT INTO private.security_audit_events(actor_id,action,target_type,target_id,outcome,reason_category)
    VALUES(actor_id,'evaluation_report_created','evaluation_report_version',created_version.id,'success','sa_segment');
  RETURN QUERY SELECT selected_report.id,created_version.id,created_version.version_number,mapping_state,evidence_state,false;
END;
$$;
ALTER FUNCTION public.create_sa_segment_evaluation_report(uuid,uuid) OWNER TO postgres;
REVOKE ALL ON FUNCTION public.create_sa_segment_evaluation_report(uuid,uuid) FROM PUBLIC,anon,service_role;
GRANT EXECUTE ON FUNCTION public.create_sa_segment_evaluation_report(uuid,uuid) TO authenticated;

CREATE OR REPLACE FUNCTION public.get_evaluation_report(p_report_record_id uuid,p_version_number integer DEFAULT NULL)
RETURNS SETOF public.evaluation_report_versions LANGUAGE plpgsql SECURITY DEFINER SET search_path = ''
AS $$
DECLARE actor_id uuid:=auth.uid(); selected_version public.evaluation_report_versions%ROWTYPE;
BEGIN
  IF actor_id IS NULL OR NOT private.current_account_is_active() OR NOT private.can_read_evaluation_report(p_report_record_id) THEN
    RAISE EXCEPTION USING ERRCODE='42501', MESSAGE='evaluation_report_read_forbidden';
  END IF;
  SELECT v.* INTO selected_version FROM public.evaluation_report_versions AS v
    WHERE v.report_record_id=p_report_record_id AND (p_version_number IS NULL OR v.version_number=p_version_number)
    ORDER BY v.version_number DESC LIMIT 1;
  IF NOT FOUND THEN RAISE EXCEPTION USING ERRCODE='P0002', MESSAGE='evaluation_report_version_not_found'; END IF;
  INSERT INTO private.security_audit_events(actor_id,action,target_type,target_id,outcome,reason_category)
    VALUES(actor_id,'evaluation_report_read','evaluation_report_version',selected_version.id,'success',selected_version.report_scope);
  RETURN NEXT selected_version; RETURN;
END;
$$;
ALTER FUNCTION public.get_evaluation_report(uuid,integer) OWNER TO postgres;
REVOKE ALL ON FUNCTION public.get_evaluation_report(uuid,integer) FROM PUBLIC,anon,service_role;
GRANT EXECUTE ON FUNCTION public.get_evaluation_report(uuid,integer) TO authenticated;

CREATE OR REPLACE FUNCTION public.grant_evaluation_report_teacher_access(p_report_record_id uuid,p_teacher_user_id uuid,p_reason text)
RETURNS TABLE(access_grant_id uuid,granted_at timestamptz)
LANGUAGE plpgsql SECURITY DEFINER SET search_path = ''
AS $$
DECLARE actor_id uuid:=auth.uid(); created_grant private.evaluation_report_teacher_access_grants%ROWTYPE;
BEGIN
  IF actor_id IS NULL OR NOT private.current_account_is_active() OR NOT private.current_user_has_role('owner'::public.app_role)
    OR coalesce(auth.jwt()->>'aal','aal1')<>'aal2' THEN
    RAISE EXCEPTION USING ERRCODE='42501', MESSAGE='evaluation_report_teacher_grant_forbidden';
  END IF;
  IF p_reason IS NULL OR char_length(btrim(p_reason)) NOT BETWEEN 3 AND 240 THEN
    RAISE EXCEPTION USING ERRCODE='22023', MESSAGE='invalid_evaluation_report_teacher_grant_reason';
  END IF;
  IF NOT EXISTS(SELECT 1 FROM public.evaluation_report_records WHERE id=p_report_record_id)
    OR NOT EXISTS(SELECT 1 FROM public.profiles AS profile JOIN public.role_assignments AS assignment ON assignment.user_id=profile.user_id
      WHERE profile.user_id=p_teacher_user_id AND profile.account_status='active'
        AND assignment.role='grader'::public.app_role AND assignment.revoked_at IS NULL) THEN
    RAISE EXCEPTION USING ERRCODE='P0002', MESSAGE='evaluation_report_teacher_or_report_not_found';
  END IF;
  INSERT INTO private.evaluation_report_teacher_access_grants(report_record_id,teacher_user_id,granted_by,reason)
    VALUES(p_report_record_id,p_teacher_user_id,actor_id,btrim(p_reason))
    ON CONFLICT(report_record_id,teacher_user_id) WHERE revoked_at IS NULL DO NOTHING RETURNING * INTO created_grant;
  IF created_grant.id IS NULL THEN
    SELECT g.* INTO created_grant FROM private.evaluation_report_teacher_access_grants AS g
      WHERE g.report_record_id=p_report_record_id AND g.teacher_user_id=p_teacher_user_id AND g.revoked_at IS NULL;
  END IF;
  INSERT INTO private.security_audit_events(actor_id,action,target_type,target_id,outcome,reason_category)
    VALUES(actor_id,'evaluation_report_teacher_access_granted','evaluation_report',p_report_record_id,'success','owner_authorization');
  RETURN QUERY SELECT created_grant.id,created_grant.granted_at;
END;
$$;
ALTER FUNCTION public.grant_evaluation_report_teacher_access(uuid,uuid,text) OWNER TO postgres;
REVOKE ALL ON FUNCTION public.grant_evaluation_report_teacher_access(uuid,uuid,text) FROM PUBLIC,anon,service_role;
GRANT EXECUTE ON FUNCTION public.grant_evaluation_report_teacher_access(uuid,uuid,text) TO authenticated;

CREATE OR REPLACE FUNCTION public.revoke_evaluation_report_teacher_access(p_access_grant_id uuid,p_reason text)
RETURNS boolean LANGUAGE plpgsql SECURITY DEFINER SET search_path = ''
AS $$
DECLARE actor_id uuid:=auth.uid(); selected_grant private.evaluation_report_teacher_access_grants%ROWTYPE;
BEGIN
  IF actor_id IS NULL OR NOT private.current_account_is_active() OR NOT private.current_user_has_role('owner'::public.app_role)
    OR coalesce(auth.jwt()->>'aal','aal1')<>'aal2' THEN
    RAISE EXCEPTION USING ERRCODE='42501', MESSAGE='evaluation_report_teacher_revoke_forbidden';
  END IF;
  IF p_reason IS NULL OR char_length(btrim(p_reason)) NOT BETWEEN 3 AND 240 THEN
    RAISE EXCEPTION USING ERRCODE='22023', MESSAGE='invalid_evaluation_report_teacher_revoke_reason';
  END IF;
  SELECT g.* INTO selected_grant FROM private.evaluation_report_teacher_access_grants AS g
    WHERE g.id=p_access_grant_id AND g.revoked_at IS NULL FOR UPDATE;
  IF NOT FOUND THEN RAISE EXCEPTION USING ERRCODE='P0002', MESSAGE='evaluation_report_teacher_grant_not_found'; END IF;
  UPDATE private.evaluation_report_teacher_access_grants SET revoked_by=actor_id,revoked_at=clock_timestamp(),reason=btrim(p_reason)
    WHERE id=p_access_grant_id;
  INSERT INTO private.security_audit_events(actor_id,action,target_type,target_id,outcome,reason_category)
    VALUES(actor_id,'evaluation_report_teacher_access_revoked','evaluation_report',selected_grant.report_record_id,'success','owner_authorization');
  RETURN true;
END;
$$;
ALTER FUNCTION public.revoke_evaluation_report_teacher_access(uuid,text) OWNER TO postgres;
REVOKE ALL ON FUNCTION public.revoke_evaluation_report_teacher_access(uuid,text) FROM PUBLIC,anon,service_role;
GRANT EXECUTE ON FUNCTION public.revoke_evaluation_report_teacher_access(uuid,text) TO authenticated;

COMMENT ON TABLE public.diagnostic_observation_outcome_mappings IS
  'Exact PA observation-to-verified-route-outcome mappings; only reviewed DIRECT non-Listening mappings support claims.';
COMMENT ON TABLE public.evaluation_report_records IS
  'Separate report series per submitted PA baseline attempt or learner/enrolment/milestone SA segment; never the cumulative Overall Progress Tracker.';
COMMENT ON TABLE public.evaluation_report_versions IS
  'Immutable versioned report snapshots. Evidence is referenced by immutable IDs and hashes, never copied response text; no aggregate or official grade is invented.';
COMMENT ON TABLE private.evaluation_report_teacher_access_grants IS
  'Owner+AAL2 report-specific grants for active graders; revocable, audited and inaccessible directly to browser roles.';
