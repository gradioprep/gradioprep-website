-- Phase 1C hardening: explicitly enable RLS on the private security audit
-- table and remove revoked assignments from a grader's active read scope.
-- Private audit writes remain limited to SECURITY DEFINER trigger/RPC paths;
-- there is deliberately no browser-facing table policy.

ALTER TABLE private.security_audit_events ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS grader_assignments_select_assigned_or_owner
  ON public.grader_assignments;

CREATE POLICY grader_assignments_select_active_or_owner
  ON public.grader_assignments FOR SELECT TO authenticated
  USING (
    private.current_account_is_active()
    AND (
      (
        grader_user_id = (SELECT auth.uid())
        AND revoked_at IS NULL
        AND private.current_user_has_role('grader'::public.app_role)
        AND coalesce(auth.jwt() ->> 'aal', 'aal1') = 'aal2'
      )
      OR (
        private.current_user_has_role('owner'::public.app_role)
        AND coalesce(auth.jwt() ->> 'aal', 'aal1') = 'aal2'
      )
    )
  );
