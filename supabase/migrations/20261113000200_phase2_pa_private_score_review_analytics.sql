-- Private human review of PA rubric-dimension scoring and restricted analytics.
-- No score is released or transformed into an IB grade, percentile or rank.
CREATE TABLE private.pa_scoring_reviews (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  scoring_draft_id uuid NOT NULL UNIQUE REFERENCES private.pa_scoring_drafts(id) ON DELETE RESTRICT,
  report_record_id uuid NOT NULL REFERENCES public.evaluation_report_records(id) ON DELETE CASCADE,
  report_version_id uuid NOT NULL,
  rubric_approval_id uuid NOT NULL REFERENCES private.pa_rubric_approvals(id) ON DELETE RESTRICT,
  reviewed_by uuid NOT NULL REFERENCES auth.users(id) ON DELETE RESTRICT,
  decision text NOT NULL CHECK (decision IN ('changes_requested','approved_private')),
  review_note text NOT NULL CHECK (char_length(btrim(review_note)) BETWEEN 12 AND 1000),
  points_awarded numeric(10,3),
  points_possible numeric(10,3),
  attainment_percent numeric(6,3),
  reviewed_at timestamptz NOT NULL DEFAULT clock_timestamp(),
  FOREIGN KEY (report_version_id,report_record_id)
    REFERENCES public.evaluation_report_versions(id,report_record_id) ON DELETE RESTRICT,
  CHECK ((decision='approved_private' AND points_awarded IS NOT NULL
    AND points_possible > 0 AND attainment_percent IS NOT NULL
    AND points_awarded BETWEEN 0 AND points_possible
    AND attainment_percent BETWEEN 0 AND 100)
    OR (decision='changes_requested' AND points_awarded IS NULL
      AND points_possible IS NULL AND attainment_percent IS NULL))
);
ALTER TABLE private.pa_scoring_reviews ENABLE ROW LEVEL SECURITY;
REVOKE ALL ON private.pa_scoring_reviews FROM PUBLIC,anon,authenticated,service_role;
CREATE TRIGGER pa_scoring_review_immutable
  BEFORE UPDATE OR DELETE ON private.pa_scoring_reviews
  FOR EACH ROW EXECUTE FUNCTION private.prevent_pa_feedback_draft_mutation();

CREATE OR REPLACE FUNCTION public.review_pa_scoring_draft(
  p_scoring_draft_id uuid,p_decision text,p_review_note text
) RETURNS uuid LANGUAGE plpgsql SECURITY DEFINER SET search_path=''
AS $$
DECLARE
  d private.pa_scoring_drafts%ROWTYPE;
  r private.pa_rubric_approvals%ROWTYPE;
  v public.evaluation_report_versions%ROWTYPE;
  audit record;
  created uuid;
  awarded numeric(10,3);
  possible numeric(10,3);
BEGIN
  IF auth.uid() IS NULL OR NOT private.current_account_is_active()
    OR NOT private.current_user_has_role('owner'::public.app_role)
    OR coalesce(auth.jwt()->>'aal','aal1') <> 'aal2' THEN
    RAISE EXCEPTION USING ERRCODE='42501', MESSAGE='pa_scoring_review_forbidden';
  END IF;
  IF p_decision NOT IN ('changes_requested','approved_private')
    OR char_length(btrim(coalesce(p_review_note,''))) NOT BETWEEN 12 AND 1000 THEN
    RAISE EXCEPTION USING ERRCODE='22023',MESSAGE='invalid_pa_scoring_review';
  END IF;
  SELECT * INTO d FROM private.pa_scoring_drafts WHERE id=p_scoring_draft_id;
  IF NOT FOUND THEN
    RAISE EXCEPTION USING ERRCODE='P0002',MESSAGE='pa_scoring_draft_not_found';
  END IF;
  SELECT * INTO v FROM public.evaluation_report_versions
    WHERE id=d.report_version_id AND report_record_id=d.report_record_id
      AND report_scope='pa_baseline';
  SELECT * INTO r FROM private.pa_rubric_approvals WHERE id=d.rubric_approval_id;
  IF v.id IS NULL OR r.id IS NULL
    OR r.diagnostic_version_id::text IS DISTINCT FROM v.content_snapshot->>'diagnostic_version_id'
    OR d.response_evidence_sha256 IS DISTINCT FROM
      encode(extensions.digest(v.learner_evidence_snapshot::text,'sha256'),'hex') THEN
    RAISE EXCEPTION USING ERRCODE='55000',MESSAGE='pa_scoring_review_lineage_invalid';
  END IF;
  -- Serialize against other reviews of the same report and reject supersession.
  PERFORM 1 FROM public.evaluation_report_records
    WHERE id=d.report_record_id FOR UPDATE;
  IF EXISTS (SELECT 1 FROM public.evaluation_report_versions newer
    WHERE newer.report_record_id=d.report_record_id
      AND newer.version_number>v.version_number) THEN
    RAISE EXCEPTION USING ERRCODE='55000',MESSAGE='pa_scoring_review_report_superseded';
  END IF;
  IF p_decision='approved_private' THEN
    SELECT * INTO audit FROM public.inspect_pa_scoring_evidence(d.report_record_id);
    IF NOT FOUND OR audit.report_version_id IS DISTINCT FROM v.id
      OR audit.mapping_and_evidence_complete IS DISTINCT FROM true THEN
      RAISE EXCEPTION USING ERRCODE='55000',MESSAGE='pa_scoring_review_requires_complete_evidence';
    END IF;
    IF jsonb_array_length(d.dimension_marks)<>30
      OR jsonb_array_length(r.dimension_maxima)<>30
      OR (SELECT count(DISTINCT mark->>'code')
          FROM jsonb_array_elements(d.dimension_marks) mark)<>30
      OR EXISTS (
        SELECT 1 FROM jsonb_array_elements(d.dimension_marks) mark
        WHERE jsonb_typeof(mark->'points') IS DISTINCT FROM 'number'
          OR (mark->>'points')::numeric < 0
          OR (SELECT count(*) FROM jsonb_array_elements(r.dimension_maxima) criterion
            WHERE criterion->>'code'=mark->>'code'
              AND jsonb_typeof(criterion->'max_points')='number'
              AND (criterion->>'max_points')::numeric>0
              AND (mark->>'points')::numeric<=(criterion->>'max_points')::numeric)<>1
      ) THEN
      RAISE EXCEPTION USING ERRCODE='55000',MESSAGE='pa_scoring_review_dimensions_invalid';
    END IF;
    SELECT sum((mark->>'points')::numeric) INTO awarded
      FROM jsonb_array_elements(d.dimension_marks) mark;
    SELECT sum((criterion->>'max_points')::numeric) INTO possible
      FROM jsonb_array_elements(r.dimension_maxima) criterion;
    IF possible IS NULL OR possible<=0 OR awarded IS NULL OR awarded>possible THEN
      RAISE EXCEPTION USING ERRCODE='55000',MESSAGE='pa_scoring_review_dimensions_invalid';
    END IF;
  END IF;
  INSERT INTO private.pa_scoring_reviews(
    scoring_draft_id,report_record_id,report_version_id,rubric_approval_id,
    reviewed_by,decision,review_note,points_awarded,points_possible,attainment_percent)
  VALUES (d.id,d.report_record_id,v.id,r.id,auth.uid(),p_decision,btrim(p_review_note),
    CASE WHEN p_decision='approved_private' THEN awarded ELSE NULL END,
    CASE WHEN p_decision='approved_private' THEN possible ELSE NULL END,
    CASE WHEN p_decision='approved_private' THEN round((awarded/possible)*100,3) ELSE NULL END)
  RETURNING id INTO created;
  INSERT INTO private.security_audit_events(
    actor_id,action,target_type,target_id,outcome,reason_category)
  VALUES(auth.uid(),'pa_scoring_review_decided','pa_scoring_review',created,
    'success',CASE WHEN p_decision='approved_private'
      THEN 'human_approved_private' ELSE 'changes_requested_private' END);
  RETURN created;
END;
$$;
ALTER FUNCTION public.review_pa_scoring_draft(uuid,text,text) OWNER TO postgres;
REVOKE ALL ON FUNCTION public.review_pa_scoring_draft(uuid,text,text)
  FROM PUBLIC,anon,service_role;
GRANT EXECUTE ON FUNCTION public.review_pa_scoring_draft(uuid,text,text) TO authenticated;

-- Owner-only explicit internal analytics inspection; never used by public
-- report-read RPC, learner dashboard, or report publication procedure.
CREATE OR REPLACE FUNCTION public.get_private_pa_scoring_review(p_review_id uuid)
RETURNS TABLE(report_version_id uuid,scoring_draft_id uuid,rubric_digest text,
  decision text,points_awarded numeric,points_possible numeric,
  attainment_percent numeric,reviewed_at timestamptz)
LANGUAGE plpgsql SECURITY DEFINER SET search_path=''
AS $$
BEGIN
  IF auth.uid() IS NULL OR NOT private.current_account_is_active()
    OR NOT private.current_user_has_role('owner'::public.app_role)
    OR coalesce(auth.jwt()->>'aal','aal1') <> 'aal2' THEN
    RAISE EXCEPTION USING ERRCODE='42501',MESSAGE='pa_scoring_review_read_forbidden';
  END IF;
  RETURN QUERY SELECT rev.report_version_id,rev.scoring_draft_id,rubric.rubric_sha256,
    rev.decision,rev.points_awarded,rev.points_possible,rev.attainment_percent,rev.reviewed_at
  FROM private.pa_scoring_reviews rev JOIN private.pa_rubric_approvals rubric
    ON rubric.id=rev.rubric_approval_id
  WHERE rev.id=p_review_id;
END;
$$;
ALTER FUNCTION public.get_private_pa_scoring_review(uuid) OWNER TO postgres;
REVOKE ALL ON FUNCTION public.get_private_pa_scoring_review(uuid)
  FROM PUBLIC,anon,service_role;
GRANT EXECUTE ON FUNCTION public.get_private_pa_scoring_review(uuid) TO authenticated;
COMMENT ON TABLE private.pa_scoring_reviews IS
  'Immutable human-reviewed internal PA evidence/attainment only. No official IB grade, ranking, automatic score, or learner publication.';
