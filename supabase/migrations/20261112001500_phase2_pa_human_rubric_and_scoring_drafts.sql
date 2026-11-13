-- PA human rubric approval and private, append-only scoring worksheets.
-- Academic review references and criterion maxima must be supplied by a human.
-- No rubric, approval, scores, or curriculum mappings are seeded by this migration.
-- No learner/guardian RPC can read these records. No marks are published.
CREATE TABLE private.pa_rubric_approvals (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  diagnostic_version_id uuid NOT NULL REFERENCES public.diagnostic_versions(id) ON DELETE RESTRICT,
  rubric_sha256 text NOT NULL CHECK (rubric_sha256 ~ '^[a-f0-9]{64}$'),
  dimension_maxima jsonb NOT NULL CHECK (jsonb_typeof(dimension_maxima)='array'),
  academic_review_reference text NOT NULL
    CHECK (char_length(btrim(academic_review_reference)) BETWEEN 12 AND 500),
  assessor_calibration_reference text NOT NULL
    CHECK (char_length(btrim(assessor_calibration_reference)) BETWEEN 12 AND 500),
  approval_note text NOT NULL CHECK (char_length(btrim(approval_note)) BETWEEN 20 AND 1000),
  approved_by uuid NOT NULL REFERENCES auth.users(id) ON DELETE RESTRICT,
  approved_at timestamptz NOT NULL DEFAULT clock_timestamp(),
  UNIQUE (diagnostic_version_id,rubric_sha256)
);
CREATE TABLE private.pa_scoring_drafts (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  report_record_id uuid NOT NULL REFERENCES public.evaluation_report_records(id) ON DELETE CASCADE,
  report_version_id uuid NOT NULL,
  rubric_approval_id uuid NOT NULL REFERENCES private.pa_rubric_approvals(id) ON DELETE RESTRICT,
  scorer_id uuid NOT NULL REFERENCES auth.users(id) ON DELETE RESTRICT,
  dimension_marks jsonb NOT NULL CHECK (jsonb_typeof(dimension_marks)='array'),
  response_evidence_sha256 text NOT NULL CHECK (response_evidence_sha256 ~ '^[a-f0-9]{64}$'),
  created_at timestamptz NOT NULL DEFAULT clock_timestamp(),
  FOREIGN KEY(report_version_id,report_record_id)
    REFERENCES public.evaluation_report_versions(id,report_record_id) ON DELETE RESTRICT
);
CREATE INDEX pa_scoring_drafts_report_idx
  ON private.pa_scoring_drafts(report_record_id,created_at,id);
ALTER TABLE private.pa_rubric_approvals ENABLE ROW LEVEL SECURITY;
ALTER TABLE private.pa_scoring_drafts ENABLE ROW LEVEL SECURITY;
REVOKE ALL ON private.pa_rubric_approvals,private.pa_scoring_drafts
  FROM PUBLIC,anon,authenticated,service_role;
CREATE TRIGGER pa_rubric_approval_immutable
  BEFORE UPDATE OR DELETE ON private.pa_rubric_approvals
  FOR EACH ROW EXECUTE FUNCTION private.prevent_pa_feedback_draft_mutation();
CREATE TRIGGER pa_scoring_draft_immutable
  BEFORE UPDATE OR DELETE ON private.pa_scoring_drafts
  FOR EACH ROW EXECUTE FUNCTION private.prevent_pa_feedback_draft_mutation();

-- An Owner must enter real, reviewed, criterion-specific maximum scores.
-- The published instrument must already have passed its direct-mapping gate.
CREATE OR REPLACE FUNCTION public.approve_pa_scoring_rubric(
  p_diagnostic_version_id uuid,p_rubric_sha256 text,p_dimension_maxima jsonb,
  p_academic_review_reference text,p_assessor_calibration_reference text,p_approval_note text
) RETURNS uuid LANGUAGE plpgsql SECURITY DEFINER SET search_path=''
AS $$
DECLARE
  selected public.diagnostic_versions%ROWTYPE;
  approved_id uuid;
BEGIN
  IF auth.uid() IS NULL OR NOT private.current_account_is_active()
    OR NOT private.current_user_has_role('owner'::public.app_role)
    OR coalesce(auth.jwt()->>'aal','aal1') <> 'aal2' THEN
    RAISE EXCEPTION USING ERRCODE='42501',MESSAGE='pa_rubric_approval_forbidden';
  END IF;
  IF p_diagnostic_version_id IS NULL OR p_rubric_sha256 IS NULL
    OR p_rubric_sha256 !~ '^[a-f0-9]{64}$'
    OR jsonb_typeof(p_dimension_maxima) IS DISTINCT FROM 'array'
    OR jsonb_array_length(p_dimension_maxima) <> 30
    OR char_length(btrim(coalesce(p_academic_review_reference,''))) NOT BETWEEN 12 AND 500
    OR char_length(btrim(coalesce(p_assessor_calibration_reference,''))) NOT BETWEEN 12 AND 500
    OR char_length(btrim(coalesce(p_approval_note,''))) NOT BETWEEN 20 AND 1000 THEN
    RAISE EXCEPTION USING ERRCODE='22023',MESSAGE='invalid_pa_rubric_approval';
  END IF;
  SELECT * INTO selected FROM public.diagnostic_versions
    WHERE id=p_diagnostic_version_id AND release_state='published'
      AND diagnostic_code='ib-myp-g9-cycle1';
  IF NOT FOUND THEN
    RAISE EXCEPTION USING ERRCODE='55000',MESSAGE='pa_rubric_requires_published_reviewed_instrument';
  END IF;
  IF EXISTS (
    SELECT 1 FROM jsonb_array_elements(p_dimension_maxima) AS dim
    WHERE jsonb_typeof(dim) <> 'object'
       OR jsonb_typeof(dim->'code') IS DISTINCT FROM 'string'
       OR jsonb_typeof(dim->'max_points') IS DISTINCT FROM 'number'
       OR (dim->>'max_points')::numeric <= 0
       OR (dim->>'max_points')::numeric > 100
  ) OR (
    SELECT count(DISTINCT dim->>'code') FROM jsonb_array_elements(p_dimension_maxima) AS dim
  ) <> 30 OR EXISTS (
    SELECT 1 FROM jsonb_array_elements(p_dimension_maxima) AS dim
    WHERE NOT EXISTS (
      SELECT 1 FROM public.diagnostic_observations AS o
      WHERE o.diagnostic_version_id=selected.id
        AND o.observation_code=dim->>'code'
        AND o.learner_capture_enabled AND o.group_code<>'L'
    )
  ) THEN
    RAISE EXCEPTION USING ERRCODE='22023',MESSAGE='pa_rubric_dimensions_invalid';
  END IF;
  INSERT INTO private.pa_rubric_approvals(
    diagnostic_version_id,rubric_sha256,dimension_maxima,academic_review_reference,
    assessor_calibration_reference,approval_note,approved_by)
  VALUES(p_diagnostic_version_id,p_rubric_sha256,p_dimension_maxima,
    btrim(p_academic_review_reference),btrim(p_assessor_calibration_reference),
    btrim(p_approval_note),auth.uid())
  RETURNING id INTO approved_id;
  INSERT INTO private.security_audit_events(actor_id,action,target_type,target_id,outcome,reason_category)
  VALUES(auth.uid(),'pa_rubric_approved','pa_rubric_approval',approved_id,'success','human_approved_private');
  RETURN approved_id;
END;
$$;
ALTER FUNCTION public.approve_pa_scoring_rubric(uuid,text,jsonb,text,text,text) OWNER TO postgres;
REVOKE ALL ON FUNCTION public.approve_pa_scoring_rubric(uuid,text,jsonb,text,text,text)
  FROM PUBLIC,anon,service_role;
GRANT EXECUTE ON FUNCTION public.approve_pa_scoring_rubric(uuid,text,jsonb,text,text,text)
  TO authenticated;

-- Each human score draft is bound to the exact report version, approved rubric,
-- and 30 individual dimensions. Never convert to an official IB grade or
-- copy draft marks into a learner report before independent review/publication.
CREATE OR REPLACE FUNCTION public.create_pa_scoring_draft(
  p_report_version_id uuid,p_rubric_approval_id uuid,p_dimension_marks jsonb
) RETURNS uuid LANGUAGE plpgsql SECURITY DEFINER SET search_path=''
AS $$
DECLARE
  selected public.evaluation_report_versions%ROWTYPE;
  rubric private.pa_rubric_approvals%ROWTYPE;
  stored_id uuid;
  audit record;
BEGIN
  SELECT * INTO selected FROM public.evaluation_report_versions
    WHERE id=p_report_version_id AND report_scope='pa_baseline';
  IF NOT FOUND OR NOT private.can_author_pa_report_draft(selected.report_record_id) THEN
    RAISE EXCEPTION USING ERRCODE='42501',MESSAGE='pa_scoring_draft_forbidden';
  END IF;
  SELECT * INTO rubric FROM private.pa_rubric_approvals WHERE id=p_rubric_approval_id;
  IF NOT FOUND OR rubric.diagnostic_version_id::text
      IS DISTINCT FROM selected.content_snapshot->>'diagnostic_version_id' THEN
    RAISE EXCEPTION USING ERRCODE='55000',MESSAGE='pa_scoring_rubric_version_mismatch';
  END IF;
  IF EXISTS (SELECT 1 FROM public.evaluation_report_versions newer
    WHERE newer.report_record_id=selected.report_record_id
      AND newer.version_number>selected.version_number) THEN
    RAISE EXCEPTION USING ERRCODE='55000',MESSAGE='pa_scoring_report_superseded';
  END IF;
  SELECT * INTO audit FROM public.inspect_pa_scoring_evidence(selected.report_record_id);
  IF NOT FOUND OR audit.report_version_id IS DISTINCT FROM selected.id
    OR audit.mapping_and_evidence_complete IS DISTINCT FROM true THEN
    RAISE EXCEPTION USING ERRCODE='55000',MESSAGE='pa_scoring_requires_complete_evidence';
  END IF;
  IF jsonb_typeof(p_dimension_marks) IS DISTINCT FROM 'array'
    OR jsonb_array_length(p_dimension_marks) <> 30 THEN
    RAISE EXCEPTION USING ERRCODE='22023',MESSAGE='pa_scoring_dimensions_invalid';
  END IF;
  IF EXISTS (
    SELECT 1 FROM jsonb_array_elements(p_dimension_marks) AS mark
    WHERE jsonb_typeof(mark) <> 'object'
       OR jsonb_typeof(mark->'code') IS DISTINCT FROM 'string'
       OR jsonb_typeof(mark->'points') IS DISTINCT FROM 'number'
       OR (mark->>'points')::numeric < 0
       OR NOT EXISTS (
         SELECT 1 FROM jsonb_array_elements(rubric.dimension_maxima) AS dim
         WHERE dim->>'code'=mark->>'code'
           AND (mark->>'points')::numeric <= (dim->>'max_points')::numeric
       )
  ) OR (SELECT count(DISTINCT mark->>'code')
    FROM jsonb_array_elements(p_dimension_marks) AS mark) <> 30 THEN
    RAISE EXCEPTION USING ERRCODE='22023',MESSAGE='pa_scoring_dimensions_invalid';
  END IF;
  INSERT INTO private.pa_scoring_drafts(
    report_record_id,report_version_id,rubric_approval_id,scorer_id,
    dimension_marks,response_evidence_sha256)
  VALUES(selected.report_record_id,selected.id,rubric.id,auth.uid(),
    p_dimension_marks,
    encode(extensions.digest(selected.learner_evidence_snapshot::text,'sha256'),'hex'))
  RETURNING id INTO stored_id;
  INSERT INTO private.security_audit_events(actor_id,action,target_type,target_id,outcome,reason_category)
  VALUES(auth.uid(),'pa_scoring_draft_created','pa_scoring_draft',stored_id,'success','private_human_unpublished');
  RETURN stored_id;
END;
$$;
ALTER FUNCTION public.create_pa_scoring_draft(uuid,uuid,jsonb) OWNER TO postgres;
REVOKE ALL ON FUNCTION public.create_pa_scoring_draft(uuid,uuid,jsonb)
  FROM PUBLIC,anon,service_role;
GRANT EXECUTE ON FUNCTION public.create_pa_scoring_draft(uuid,uuid,jsonb) TO authenticated;
COMMENT ON TABLE private.pa_scoring_drafts IS
  'Private human rubric-dimension score drafts only. Not reviewed for publication, not a learner grade, no scores seeded.';
