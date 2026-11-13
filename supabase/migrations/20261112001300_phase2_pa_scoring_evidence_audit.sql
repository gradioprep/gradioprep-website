-- Staff-only PA evidence sufficiency audit. No scoring, grades or publication.
-- Each AW/CW/SP response is collected once; five criterion dimensions require
-- independent, human-approved rubric review, not five copied response records.
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
  expected integer;
  mapped integer;
  evidenced integer;
  witnessed boolean;
  complete boolean;
BEGIN
  IF p_report_record_id IS NULL OR auth.uid() IS NULL
     OR coalesce(auth.jwt()->>'aal','aal1') <> 'aal2'
     OR NOT private.current_account_is_active()
     OR NOT (private.current_user_has_role('owner'::public.app_role)
       OR (private.current_user_has_role('grader'::public.app_role)
         AND EXISTS (
           SELECT 1 FROM private.evaluation_report_teacher_access_grants g
           WHERE g.report_record_id=p_report_record_id
             AND g.teacher_user_id=auth.uid() AND g.revoked_at IS NULL
         ))) THEN
    RAISE EXCEPTION USING ERRCODE='42501', MESSAGE='pa_scoring_evidence_forbidden';
  END IF;
  SELECT * INTO report FROM public.evaluation_report_records r
    WHERE r.id=p_report_record_id AND r.report_scope='pa_baseline';
  IF NOT FOUND THEN
    RAISE EXCEPTION USING ERRCODE='P0002', MESSAGE='pa_report_not_found';
  END IF;
  SELECT * INTO v FROM public.evaluation_report_versions rv
    WHERE rv.report_record_id=report.id
    ORDER BY rv.version_number DESC LIMIT 1;
  IF NOT FOUND THEN
    RAISE EXCEPTION USING ERRCODE='P0002', MESSAGE='pa_report_version_not_found';
  END IF;

  WITH observations AS (
    SELECT entry->>'observation_code' AS code, entry->>'group_code' AS grp
    FROM jsonb_array_elements(coalesce(v.content_snapshot->'observations','[]'::jsonb)) AS entry
    WHERE entry->>'capture_enabled'='true'
  ),
  evidence AS (
    SELECT entry->>'observation_code' AS code
    FROM jsonb_array_elements(v.learner_evidence_snapshot) AS entry
    WHERE entry->>'response_sha256' IS NOT NULL
  ),
  mappings AS (
    SELECT entry->>'observation_code' AS code
    FROM jsonb_array_elements(v.curriculum_mapping_snapshot) AS entry
    WHERE entry->>'mapping_status'='direct'
      AND jsonb_array_length(coalesce(entry->'direct_outcomes','[]'::jsonb)) > 0
  )
  SELECT count(*)::integer,
    count(*) FILTER (WHERE EXISTS (
      SELECT 1 FROM mappings m WHERE m.code=o.code))::integer,
    count(*) FILTER (WHERE EXISTS (
      SELECT 1 FROM evidence e WHERE e.code =
        CASE WHEN o.grp IN ('AW','CW','SP') THEN o.grp || '01' ELSE o.code END))::integer
  INTO expected,mapped,evidenced FROM observations o;

  SELECT EXISTS (
    SELECT 1 FROM private.pa_spoken_performance_evidence spoken
    WHERE spoken.report_record_id=report.id
      AND spoken.report_version_id=v.id AND spoken.observed_live
  ) INTO witnessed;

  -- Historic 15-observation report fixtures must not be scored as a complete PA.
  -- A saved speaking outline alone does not establish oral-performance evidence.
  complete := expected=30 AND mapped=30 AND evidenced=30
    AND witnessed
    AND v.curriculum_mapping_status='complete_direct'
    AND v.evidence_sufficiency_status='sufficient'
    AND NOT EXISTS (
      SELECT 1 FROM jsonb_array_elements(v.content_snapshot->'observations') AS item
      WHERE item->>'group_code'='L'
    );
  RETURN QUERY SELECT v.id,expected,mapped,evidenced,witnessed,complete,
    'human_rubric_approval_required'::text;
END;
$$;
ALTER FUNCTION public.inspect_pa_scoring_evidence(uuid) OWNER TO postgres;
REVOKE ALL ON FUNCTION public.inspect_pa_scoring_evidence(uuid)
  FROM PUBLIC,anon,service_role;
GRANT EXECUTE ON FUNCTION public.inspect_pa_scoring_evidence(uuid) TO authenticated;
COMMENT ON FUNCTION public.inspect_pa_scoring_evidence(uuid) IS
  'Staff AAL2-only evidence and direct-mapping checkpoint. Never certifies rubric approval, calculates scores or publishes learner feedback.';
