-- Private, append-only PA teacher feedback drafts. This is not publication or approval.
-- Neither the learner report RPC nor its public snapshot reads this table.
CREATE TABLE private.pa_evaluation_feedback_drafts (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  report_version_id uuid NOT NULL REFERENCES public.evaluation_report_versions(id) ON DELETE CASCADE,
  report_record_id uuid NOT NULL REFERENCES public.evaluation_report_records(id) ON DELETE CASCADE,
  author_id uuid NOT NULL REFERENCES auth.users(id) ON DELETE RESTRICT,
  draft_text text NOT NULL CHECK (char_length(btrim(draft_text)) BETWEEN 20 AND 5000),
  created_at timestamptz NOT NULL DEFAULT clock_timestamp(),
  UNIQUE (id, report_record_id)
);
CREATE INDEX pa_evaluation_feedback_drafts_report_idx
  ON private.pa_evaluation_feedback_drafts(report_record_id, created_at DESC);
ALTER TABLE private.pa_evaluation_feedback_drafts ENABLE ROW LEVEL SECURITY;
REVOKE ALL ON TABLE private.pa_evaluation_feedback_drafts FROM PUBLIC, anon, authenticated, service_role;

CREATE OR REPLACE FUNCTION private.prevent_pa_feedback_draft_mutation()
RETURNS trigger LANGUAGE plpgsql SET search_path = ''
AS $$
BEGIN
  IF TG_OP = 'DELETE' AND pg_catalog.pg_trigger_depth() > 1 THEN RETURN OLD; END IF;
  RAISE EXCEPTION USING ERRCODE='42501', MESSAGE='pa_feedback_draft_immutable';
END;
$$;
ALTER FUNCTION private.prevent_pa_feedback_draft_mutation() OWNER TO postgres;
REVOKE ALL ON FUNCTION private.prevent_pa_feedback_draft_mutation() FROM PUBLIC,anon,authenticated,service_role;
CREATE TRIGGER pa_feedback_draft_immutable BEFORE UPDATE OR DELETE ON private.pa_evaluation_feedback_drafts
FOR EACH ROW EXECUTE FUNCTION private.prevent_pa_feedback_draft_mutation();

CREATE OR REPLACE FUNCTION private.can_author_pa_report_draft(p_report_record_id uuid)
RETURNS boolean LANGUAGE sql STABLE SECURITY DEFINER SET search_path = ''
AS $$
  SELECT private.current_account_is_active()
    AND coalesce(auth.jwt()->>'aal','aal1') = 'aal2'
    AND EXISTS (SELECT 1 FROM public.evaluation_report_records AS r
      WHERE r.id=p_report_record_id AND r.report_scope='pa_baseline')
    AND (
      private.current_user_has_role('owner'::public.app_role)
      OR (private.current_user_has_role('grader'::public.app_role)
        AND EXISTS (SELECT 1 FROM private.evaluation_report_teacher_access_grants AS g
          WHERE g.report_record_id=p_report_record_id AND g.teacher_user_id=auth.uid()
            AND g.revoked_at IS NULL))
    );
$$;
ALTER FUNCTION private.can_author_pa_report_draft(uuid) OWNER TO postgres;
REVOKE ALL ON FUNCTION private.can_author_pa_report_draft(uuid) FROM PUBLIC,anon,authenticated,service_role;

CREATE OR REPLACE FUNCTION public.create_pa_evaluation_feedback_draft(
  p_report_version_id uuid, p_draft_text text
)
RETURNS uuid LANGUAGE plpgsql SECURITY DEFINER SET search_path = ''
AS $$
DECLARE
  selected_report_id uuid;
  created_draft_id uuid;
BEGIN
  SELECT v.report_record_id INTO selected_report_id
  FROM public.evaluation_report_versions AS v
  WHERE v.id=p_report_version_id AND v.report_scope='pa_baseline';
  IF selected_report_id IS NULL OR NOT private.can_author_pa_report_draft(selected_report_id) THEN
    RAISE EXCEPTION USING ERRCODE='42501', MESSAGE='pa_feedback_draft_forbidden';
  END IF;
  IF p_draft_text IS NULL OR char_length(btrim(p_draft_text)) NOT BETWEEN 20 AND 5000 THEN
    RAISE EXCEPTION USING ERRCODE='22023', MESSAGE='invalid_pa_feedback_draft';
  END IF;
  INSERT INTO private.pa_evaluation_feedback_drafts(report_version_id,report_record_id,author_id,draft_text)
  VALUES(p_report_version_id,selected_report_id,auth.uid(),btrim(p_draft_text))
  RETURNING id INTO created_draft_id;
  INSERT INTO private.security_audit_events(actor_id,action,target_type,target_id,outcome,reason_category)
  VALUES(auth.uid(),'pa_feedback_draft_created','pa_feedback_draft',created_draft_id,'success','private_unapproved');
  RETURN created_draft_id;
END;
$$;
ALTER FUNCTION public.create_pa_evaluation_feedback_draft(uuid,text) OWNER TO postgres;
REVOKE ALL ON FUNCTION public.create_pa_evaluation_feedback_draft(uuid,text) FROM PUBLIC,anon,service_role;
GRANT EXECUTE ON FUNCTION public.create_pa_evaluation_feedback_draft(uuid,text) TO authenticated;

CREATE OR REPLACE FUNCTION public.get_pa_evaluation_feedback_drafts(p_report_record_id uuid)
RETURNS TABLE(draft_id uuid,report_version_id uuid,author_id uuid,draft_text text,created_at timestamptz)
LANGUAGE plpgsql SECURITY DEFINER SET search_path = ''
AS $$
BEGIN
  IF NOT private.can_author_pa_report_draft(p_report_record_id) THEN
    RAISE EXCEPTION USING ERRCODE='42501', MESSAGE='pa_feedback_draft_forbidden';
  END IF;
  RETURN QUERY SELECT d.id,d.report_version_id,d.author_id,d.draft_text,d.created_at
  FROM private.pa_evaluation_feedback_drafts AS d
  WHERE d.report_record_id=p_report_record_id ORDER BY d.created_at,d.id;
END;
$$;
ALTER FUNCTION public.get_pa_evaluation_feedback_drafts(uuid) OWNER TO postgres;
REVOKE ALL ON FUNCTION public.get_pa_evaluation_feedback_drafts(uuid) FROM PUBLIC,anon,service_role;
GRANT EXECUTE ON FUNCTION public.get_pa_evaluation_feedback_drafts(uuid) TO authenticated;

COMMENT ON TABLE private.pa_evaluation_feedback_drafts IS
  'Unapproved append-only staff feedback drafts, not learner report content or review decisions. No publish or approval operation exists in this increment.';
