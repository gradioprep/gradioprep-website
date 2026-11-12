-- AAL2 staff-only PA baseline review queue. No learner identity or private draft text
-- is returned. Owner sees PA reports; graders see only active report grants.
CREATE OR REPLACE FUNCTION public.list_pa_evaluation_review_queue(p_limit integer DEFAULT 25)
RETURNS TABLE(
  report_record_id uuid,
  created_at timestamptz,
  version_number integer,
  curriculum_mapping_status text,
  evidence_sufficiency_status text
)
LANGUAGE plpgsql SECURITY DEFINER SET search_path = ''
AS $$
DECLARE
  actor_id uuid := auth.uid();
  is_owner boolean;
  is_grader boolean;
BEGIN
  IF actor_id IS NULL OR NOT private.current_account_is_active()
    OR coalesce(auth.jwt()->>'aal','aal1') <> 'aal2' THEN
    RAISE EXCEPTION USING ERRCODE='42501', MESSAGE='pa_report_queue_forbidden';
  END IF;
  is_owner := private.current_user_has_role('owner'::public.app_role);
  is_grader := private.current_user_has_role('grader'::public.app_role);
  IF NOT (is_owner OR is_grader) THEN
    RAISE EXCEPTION USING ERRCODE='42501', MESSAGE='pa_report_queue_forbidden';
  END IF;
  IF p_limit IS NULL OR p_limit < 1 OR p_limit > 50 THEN
    RAISE EXCEPTION USING ERRCODE='22023', MESSAGE='invalid_pa_report_queue_limit';
  END IF;

  RETURN QUERY
  SELECT r.id,r.created_at,v.version_number,
    v.curriculum_mapping_status,v.evidence_sufficiency_status
  FROM public.evaluation_report_records AS r
  JOIN LATERAL (
    SELECT latest.version_number,latest.curriculum_mapping_status,latest.evidence_sufficiency_status
    FROM public.evaluation_report_versions AS latest
    WHERE latest.report_record_id=r.id
    ORDER BY latest.version_number DESC LIMIT 1
  ) AS v ON true
  WHERE r.report_scope='pa_baseline'
    AND (is_owner OR (is_grader AND EXISTS (
      SELECT 1 FROM private.evaluation_report_teacher_access_grants AS g
      WHERE g.report_record_id=r.id AND g.teacher_user_id=actor_id AND g.revoked_at IS NULL
    )))
  ORDER BY r.created_at ASC,r.id ASC
  LIMIT p_limit;
END;
$$;
ALTER FUNCTION public.list_pa_evaluation_review_queue(integer) OWNER TO postgres;
REVOKE ALL ON FUNCTION public.list_pa_evaluation_review_queue(integer)
  FROM PUBLIC,anon,service_role;
GRANT EXECUTE ON FUNCTION public.list_pa_evaluation_review_queue(integer) TO authenticated;
COMMENT ON FUNCTION public.list_pa_evaluation_review_queue(integer) IS
  'AAL2 Owner or actively granted Grader PA review queue, earliest first, with minimal report metadata.';
