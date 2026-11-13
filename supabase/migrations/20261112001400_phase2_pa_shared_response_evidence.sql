-- Correct PA 30-dimension evidence accounting: AW/CW/SP each have one source
-- response supporting five distinct rubric dimensions, not five submissions.
-- Preserve the exact source response identity and SHA-256 per dimension.
-- This changes evidence accounting only; it does not approve scoring or publish grades.
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
      AND EXISTS (
        SELECT 1 FROM public.diagnostic_response_versions AS r
        JOIN public.diagnostic_observations AS source
          ON source.id=r.observation_id AND source.diagnostic_version_id=o.diagnostic_version_id
        WHERE r.attempt_id=selected_attempt.id
          AND source.observation_code=CASE
            WHEN o.group_code IN ('AW','CW','SP') THEN o.group_code || '01'
            ELSE o.observation_code END
      );
  SELECT count(*)::integer INTO directly_mapped_observations FROM public.diagnostic_observations AS o
    WHERE o.diagnostic_version_id = selected_version.id AND o.learner_capture_enabled
      AND EXISTS (SELECT 1 FROM public.diagnostic_observation_outcome_mappings AS m
        JOIN public.curriculum_unit_versions AS unit ON unit.id=m.curriculum_unit_version_id
        WHERE m.diagnostic_observation_id = o.id AND m.diagnostic_version_id = selected_version.id
          AND m.route_version_id = selected_route.id AND m.mapping_status = 'direct'
          AND unit.release_state='published' AND m.reviewed_by IS NOT NULL AND m.reviewed_at IS NOT NULL);
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
      JOIN public.curriculum_unit_versions AS unit ON unit.id=m.curriculum_unit_version_id
      WHERE m.diagnostic_observation_id=o.id AND m.route_version_id=selected_route.id AND m.mapping_status='direct'
        AND unit.release_state='published') THEN 'direct'
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
        AND u.release_state='published' AND m.reviewed_by IS NOT NULL AND m.reviewed_at IS NOT NULL),'[]'::jsonb)
  ) ORDER BY o.sequence_number),'[]'::jsonb) INTO mapping_snapshot
  FROM public.diagnostic_observations AS o WHERE o.diagnostic_version_id=selected_version.id AND o.learner_capture_enabled;
  SELECT coalesce(jsonb_agg(jsonb_build_object('observation_id',o.id,'observation_code',o.observation_code,
    'source_response_observation_code',CASE WHEN r.id IS NULL THEN NULL ELSE source.observation_code END,
    'response_version_id',r.id,'response_revision',r.revision_number,'response_saved_at',r.saved_at,
    'response_sha256',CASE WHEN r.id IS NULL THEN NULL ELSE encode(extensions.digest(r.response_json::text,'sha256'),'hex') END)
    ORDER BY o.sequence_number),'[]'::jsonb) INTO evidence_snapshot
  FROM public.diagnostic_observations AS o
  LEFT JOIN public.diagnostic_observations AS source
    ON source.diagnostic_version_id=o.diagnostic_version_id
   AND source.observation_code=CASE
     WHEN o.group_code IN ('AW','CW','SP') THEN o.group_code || '01'
     ELSE o.observation_code END
  LEFT JOIN LATERAL (SELECT rv.* FROM public.diagnostic_response_versions AS rv
    WHERE rv.attempt_id=selected_attempt.id AND rv.observation_id=source.id
    ORDER BY rv.revision_number DESC LIMIT 1) AS r ON true
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

