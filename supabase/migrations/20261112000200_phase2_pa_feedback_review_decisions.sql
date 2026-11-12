-- Private human review decisions for PA Evaluation Report feedback.
-- Decisions are version-bound, append-only, and are not learner publication.
CREATE TABLE private.pa_evaluation_feedback_reviews (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  draft_id uuid NOT NULL REFERENCES private.pa_evaluation_feedback_drafts(id) ON DELETE CASCADE,
  report_version_id uuid NOT NULL REFERENCES public.evaluation_report_versions(id) ON DELETE CASCADE,
  report_record_id uuid NOT NULL REFERENCES public.evaluation_report_records(id) ON DELETE CASCADE,
  reviewer_id uuid NOT NULL REFERENCES auth.users(id) ON DELETE RESTRICT,
  decision text NOT NULL CHECK (decision IN ('changes_requested','approved_for_publication')),
  reviewer_note text NOT NULL CHECK (char_length(btrim(reviewer_note)) BETWEEN 10 AND 1000),
  decided_at timestamptz NOT NULL DEFAULT clock_timestamp(),
  UNIQUE (draft_id)
);
CREATE INDEX pa_evaluation_feedback_reviews_report_idx
  ON private.pa_evaluation_feedback_reviews(report_record_id, decided_at DESC);
ALTER TABLE private.pa_evaluation_feedback_reviews ENABLE ROW LEVEL SECURITY;
REVOKE ALL ON private.pa_evaluation_feedback_reviews FROM PUBLIC,anon,authenticated,service_role;
CREATE TRIGGER pa_feedback_review_immutable
  BEFORE UPDATE OR DELETE ON private.pa_evaluation_feedback_reviews
  FOR EACH ROW EXECUTE FUNCTION private.prevent_pa_feedback_draft_mutation();

CREATE OR REPLACE FUNCTION public.review_pa_evaluation_feedback_draft(
  p_draft_id uuid, p_decision text, p_reviewer_note text
)
RETURNS uuid LANGUAGE plpgsql SECURITY DEFINER SET search_path = ''
AS $$
DECLARE
  selected_draft private.pa_evaluation_feedback_drafts%ROWTYPE;
  selected_version public.evaluation_report_versions%ROWTYPE;
  created_review_id uuid;
BEGIN
  IF auth.uid() IS NULL OR NOT private.current_account_is_active()
    OR NOT private.current_user_has_role('owner'::public.app_role)
    OR coalesce(auth.jwt()->>'aal','aal1') <> 'aal2' THEN
    RAISE EXCEPTION USING ERRCODE='42501', MESSAGE='pa_feedback_review_forbidden';
  END IF;
  IF p_decision IS NULL OR p_decision NOT IN ('changes_requested','approved_for_publication')
    OR p_reviewer_note IS NULL OR char_length(btrim(p_reviewer_note)) NOT BETWEEN 10 AND 1000 THEN
    RAISE EXCEPTION USING ERRCODE='22023', MESSAGE='invalid_pa_feedback_review';
  END IF;
  SELECT d.* INTO selected_draft
    FROM private.pa_evaluation_feedback_drafts AS d WHERE d.id=p_draft_id;
  IF NOT FOUND THEN
    RAISE EXCEPTION USING ERRCODE='P0002', MESSAGE='pa_feedback_draft_not_found';
  END IF;
  SELECT v.* INTO selected_version FROM public.evaluation_report_versions AS v
    WHERE v.id=selected_draft.report_version_id
      AND v.report_record_id=selected_draft.report_record_id AND v.report_scope='pa_baseline';
  IF NOT FOUND THEN
    RAISE EXCEPTION USING ERRCODE='23514', MESSAGE='pa_feedback_report_version_mismatch';
  END IF;
  -- Do not approve a superseded report or an unmapped/insufficient synthetic baseline.
  IF p_decision='approved_for_publication' AND (
    selected_version.curriculum_mapping_status <> 'complete_direct'
    OR selected_version.evidence_sufficiency_status <> 'sufficient'
    OR EXISTS (SELECT 1 FROM public.evaluation_report_versions AS newer
      WHERE newer.report_record_id=selected_draft.report_record_id
        AND newer.version_number>selected_version.version_number)
    OR NOT EXISTS (SELECT 1 FROM jsonb_array_elements(selected_version.curriculum_mapping_snapshot) AS m
      WHERE m->>'mapping_status'='direct')
    OR EXISTS (SELECT 1 FROM jsonb_array_elements(selected_version.curriculum_mapping_snapshot) AS m
      WHERE m->>'mapping_status'<>'direct'
        OR jsonb_array_length(coalesce(m->'direct_outcomes','[]'::jsonb))=0)
    OR EXISTS (SELECT 1 FROM jsonb_array_elements(selected_version.learner_evidence_snapshot) AS e
      WHERE e->>'response_sha256' IS NULL)
  ) THEN
    RAISE EXCEPTION USING ERRCODE='55000', MESSAGE='pa_feedback_review_requires_complete_verified_evidence';
  END IF;
  INSERT INTO private.pa_evaluation_feedback_reviews(
    draft_id,report_version_id,report_record_id,reviewer_id,decision,reviewer_note)
  VALUES (selected_draft.id,selected_version.id,selected_draft.report_record_id,
    auth.uid(),p_decision,btrim(p_reviewer_note))
  RETURNING id INTO created_review_id;
  INSERT INTO private.security_audit_events(
    actor_id,action,target_type,target_id,outcome,reason_category)
  VALUES(auth.uid(),'pa_feedback_review_decided','pa_feedback_review',created_review_id,
    'success',CASE WHEN p_decision='approved_for_publication' THEN 'human_approved_private'
      ELSE 'changes_requested_private' END);
  RETURN created_review_id;
END;
$$;
ALTER FUNCTION public.review_pa_evaluation_feedback_draft(uuid,text,text) OWNER TO postgres;
REVOKE ALL ON FUNCTION public.review_pa_evaluation_feedback_draft(uuid,text,text)
  FROM PUBLIC,anon,service_role;
GRANT EXECUTE ON FUNCTION public.review_pa_evaluation_feedback_draft(uuid,text,text)
  TO authenticated;

CREATE OR REPLACE FUNCTION public.get_pa_evaluation_feedback_reviews(p_report_record_id uuid)
RETURNS TABLE(review_id uuid,draft_id uuid,report_version_id uuid,
  reviewer_id uuid,decision text,reviewer_note text,decided_at timestamptz)
LANGUAGE plpgsql SECURITY DEFINER SET search_path = ''
AS $$
BEGIN
  IF NOT private.can_author_pa_report_draft(p_report_record_id) THEN
    RAISE EXCEPTION USING ERRCODE='42501', MESSAGE='pa_feedback_review_read_forbidden';
  END IF;
  RETURN QUERY SELECT r.id,r.draft_id,r.report_version_id,r.reviewer_id,
    r.decision,r.reviewer_note,r.decided_at
  FROM private.pa_evaluation_feedback_reviews AS r
  WHERE r.report_record_id=p_report_record_id ORDER BY r.decided_at,r.id;
END;
$$;
ALTER FUNCTION public.get_pa_evaluation_feedback_reviews(uuid) OWNER TO postgres;
REVOKE ALL ON FUNCTION public.get_pa_evaluation_feedback_reviews(uuid) FROM PUBLIC,anon,service_role;
GRANT EXECUTE ON FUNCTION public.get_pa_evaluation_feedback_reviews(uuid) TO authenticated;

COMMENT ON TABLE private.pa_evaluation_feedback_reviews IS
  'Private append-only human decisions on exact PA report draft/version; approvals do not publish learner feedback. Only Owner AAL2 may decide.';
