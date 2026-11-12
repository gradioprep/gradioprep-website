-- Owner-only AAL2 lookup of active report-specific teacher grants.
-- Private grant identities are never accessible through learner/report APIs.
CREATE OR REPLACE FUNCTION public.list_pa_evaluation_teacher_grants(p_report_record_id uuid)
RETURNS TABLE(access_grant_id uuid,teacher_user_id uuid,granted_at timestamptz)
LANGUAGE plpgsql SECURITY DEFINER SET search_path = ''
AS $$
BEGIN
  IF auth.uid() IS NULL OR NOT private.current_account_is_active()
    OR NOT private.current_user_has_role('owner'::public.app_role)
    OR coalesce(auth.jwt()->>'aal','aal1') <> 'aal2' THEN
    RAISE EXCEPTION USING ERRCODE='42501',MESSAGE='pa_report_grants_forbidden';
  END IF;
  IF p_report_record_id IS NULL OR NOT EXISTS (
    SELECT 1 FROM public.evaluation_report_records AS r
    WHERE r.id=p_report_record_id AND r.report_scope='pa_baseline'
  ) THEN
    RAISE EXCEPTION USING ERRCODE='P0002',MESSAGE='pa_report_not_found';
  END IF;
  RETURN QUERY SELECT g.id,g.teacher_user_id,g.granted_at
    FROM private.evaluation_report_teacher_access_grants AS g
    WHERE g.report_record_id=p_report_record_id AND g.revoked_at IS NULL
    ORDER BY g.granted_at,g.id;
END;
$$;
ALTER FUNCTION public.list_pa_evaluation_teacher_grants(uuid) OWNER TO postgres;
REVOKE ALL ON FUNCTION public.list_pa_evaluation_teacher_grants(uuid)
  FROM PUBLIC,anon,service_role;
GRANT EXECUTE ON FUNCTION public.list_pa_evaluation_teacher_grants(uuid) TO authenticated;
