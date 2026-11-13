-- Exact per-dimension evidence audit for full MYP Year 4 PA.
-- The five AW/CW/SP dimensions each point to their shared AW01/CW01/SP01
-- response, but the immutable snapshot has a distinct row for EACH dimension.
-- A matching response code alone is not proof of complete evidence.
CREATE OR REPLACE FUNCTION public.inspect_pa_scoring_evidence(p_report_record_id uuid)
RETURNS TABLE (
  report_version_id uuid,
  expected_dimensions integer,
  directly_mapped_dimensions integer,
  evidenced_dimensions integer,
  oral_performance_witnessed boolean,
  mapping_and_evidence_complete boolean,
  scoring_state text
)
LANGUAGE plpgsql SECURITY DEFINER SET search_path = ''
AS $$
DECLARE
  v public.evaluation_report_versions%ROWTYPE;
  report public.evaluation_report_records%ROWTYPE;
  expected integer; mapped integer; evidenced integer;
  distinct_dimensions integer; expected_sources integer;
  group_structure_valid boolean; evidence_lineage_valid boolean;
  witnessed boolean; complete boolean;
BEGIN
  IF p_report_record_id IS NULL OR auth.uid() IS NULL
    OR coalesce(auth.jwt()->>'aal','aal1') <> 'aal2'
    OR NOT private.current_account_is_active()
    OR NOT (private.current_user_has_role('owner'::public.app_role)
      OR (private.current_user_has_role('grader'::public.app_role)
        AND EXISTS (SELECT 1 FROM private.evaluation_report_teacher_access_grants g
          WHERE g.report_record_id=p_report_record_id
            AND g.teacher_user_id=auth.uid() AND g.revoked_at IS NULL))) THEN
    RAISE EXCEPTION USING ERRCODE='42501',MESSAGE='pa_scoring_evidence_forbidden';
  END IF;
  SELECT * INTO report FROM public.evaluation_report_records r
    WHERE r.id=p_report_record_id AND r.report_scope='pa_baseline';
  IF NOT FOUND THEN
    RAISE EXCEPTION USING ERRCODE='P0002',MESSAGE='pa_report_not_found';
  END IF;
  SELECT * INTO v FROM public.evaluation_report_versions rv
    WHERE rv.report_record_id=report.id
    ORDER BY rv.version_number DESC LIMIT 1;
  IF NOT FOUND THEN
    RAISE EXCEPTION USING ERRCODE='P0002',MESSAGE='pa_report_version_not_found';
  END IF;

  WITH obs AS (
    SELECT entry->>'observation_code' code, entry->>'group_code' grp
    FROM jsonb_array_elements(coalesce(v.content_snapshot->'observations','[]'::jsonb)) entry
    WHERE entry->>'capture_enabled'='true'
  ),
  mappings AS (
    SELECT entry->>'observation_code' code, entry->>'mapping_status' status,
      coalesce(entry->'direct_outcomes','[]'::jsonb) outcomes
    FROM jsonb_array_elements(v.curriculum_mapping_snapshot) entry
  ),
  evidence AS (
    SELECT entry->>'observation_code' code,
      entry->>'source_response_observation_code' source_code,
      entry->>'response_sha256' digest
    FROM jsonb_array_elements(v.learner_evidence_snapshot) entry
  )
  SELECT count(*)::integer,count(DISTINCT o.code)::integer,
    count(DISTINCT CASE WHEN o.grp IN ('AW','CW','SP') THEN o.grp||'01' ELSE o.code END)::integer,
    count(*) FILTER (WHERE (SELECT count(*) FROM mappings m
      WHERE m.code=o.code AND m.status='direct' AND jsonb_typeof(m.outcomes)='array'
        AND jsonb_array_length(m.outcomes)>0)=1)::integer,
    count(*) FILTER (WHERE (SELECT count(*) FROM evidence e
      WHERE e.code=o.code AND e.digest ~ '^[a-f0-9]{64}$'
        AND (e.source_code IS NULL AND o.grp NOT IN ('AW','CW','SP')
          OR e.source_code=CASE WHEN o.grp IN ('AW','CW','SP')
            THEN o.grp||'01' ELSE o.code END))=1)::integer
  INTO expected,distinct_dimensions,expected_sources,mapped,evidenced
  FROM obs o;

  SELECT
    (SELECT count(*) FROM jsonb_array_elements(v.content_snapshot->'observations') entry
      WHERE entry->>'group_code'='RV' AND entry->>'capture_enabled'='true')=10
    AND (SELECT count(*) FROM jsonb_array_elements(v.content_snapshot->'observations') entry
      WHERE entry->>'group_code'='LC' AND entry->>'capture_enabled'='true')=5
    AND (SELECT count(*) FROM jsonb_array_elements(v.content_snapshot->'observations') entry
      WHERE entry->>'group_code'='AW' AND entry->>'capture_enabled'='true')=5
    AND (SELECT count(*) FROM jsonb_array_elements(v.content_snapshot->'observations') entry
      WHERE entry->>'group_code'='CW' AND entry->>'capture_enabled'='true')=5
    AND (SELECT count(*) FROM jsonb_array_elements(v.content_snapshot->'observations') entry
      WHERE entry->>'group_code'='SP' AND entry->>'capture_enabled'='true')=5
    AND NOT EXISTS (SELECT 1 FROM jsonb_array_elements(v.content_snapshot->'observations') entry
      WHERE entry->>'group_code'='L')
  INTO group_structure_valid;

  SELECT
    jsonb_array_length(v.curriculum_mapping_snapshot)=expected
    AND jsonb_array_length(v.learner_evidence_snapshot)=expected
    AND NOT EXISTS (
      SELECT 1 FROM jsonb_array_elements(v.content_snapshot->'observations') AS o
      WHERE o->>'capture_enabled' IS DISTINCT FROM 'true'
    )
  INTO evidence_lineage_valid;

  SELECT EXISTS (SELECT 1 FROM private.pa_spoken_performance_evidence spoken
    WHERE spoken.report_record_id=report.id AND spoken.report_version_id=v.id
      AND spoken.observed_live) INTO witnessed;

  complete := expected=30 AND distinct_dimensions=30 AND expected_sources=18
    AND mapped=30 AND evidenced=30 AND group_structure_valid
    AND evidence_lineage_valid AND witnessed
    AND v.curriculum_mapping_status='complete_direct'
    AND v.evidence_sufficiency_status='sufficient';
  RETURN QUERY SELECT v.id,expected,mapped,evidenced,witnessed,complete,
    'human_rubric_approval_required'::text;
END;
$$;
ALTER FUNCTION public.inspect_pa_scoring_evidence(uuid) OWNER TO postgres;
REVOKE ALL ON FUNCTION public.inspect_pa_scoring_evidence(uuid)
  FROM PUBLIC,anon,service_role;
GRANT EXECUTE ON FUNCTION public.inspect_pa_scoring_evidence(uuid) TO authenticated;
COMMENT ON FUNCTION public.inspect_pa_scoring_evidence(uuid) IS
  'AAL2 staff audit: validates all 30 distinct mapped dimensions, 18 response sources and witnessed oral work. Does not certify academic rubric approval or release scores.';
