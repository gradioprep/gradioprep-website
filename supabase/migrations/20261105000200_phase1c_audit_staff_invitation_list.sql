-- Phase 1C-E: audit privileged reads of the staff-invitation collection.
-- The event is inserted transactionally by the Owner+AAL2 read RPC and stores
-- no invitation email, token, or other invitation payload.

CREATE OR REPLACE FUNCTION public.list_staff_invitations()
RETURNS TABLE (
  invitation_id uuid,
  invited_email text,
  invited_role public.app_role,
  created_at timestamptz,
  expires_at timestamptz,
  accepted_at timestamptz,
  revoked_at timestamptz,
  status text
)
LANGUAGE plpgsql
VOLATILE
SECURITY DEFINER
SET search_path = ''
AS $function$
DECLARE
  actor_id uuid := auth.uid();
BEGIN
  IF actor_id IS NULL
    OR NOT private.current_account_is_active()
    OR NOT private.current_user_has_role('owner'::public.app_role) THEN
    RAISE EXCEPTION USING ERRCODE = '42501', MESSAGE = 'staff_invitation_forbidden';
  END IF;

  IF coalesce(auth.jwt() ->> 'aal', 'aal1') <> 'aal2' THEN
    RAISE EXCEPTION USING ERRCODE = 'P0001', MESSAGE = 'mfa_required';
  END IF;

  INSERT INTO private.security_audit_events (
    actor_id, action, target_type, target_id, outcome, reason_category
  )
  VALUES (
    actor_id, 'staff_invitations_listed', 'staff_invitation_collection',
    NULL, 'success', 'owner_aal2'
  );

  RETURN QUERY
    SELECT
      invitation.id,
      invitation.invited_email,
      invitation.invited_role,
      invitation.created_at,
      invitation.expires_at,
      invitation.accepted_at,
      invitation.revoked_at,
      CASE
        WHEN invitation.revoked_at IS NOT NULL THEN 'revoked'
        WHEN invitation.accepted_at IS NOT NULL THEN 'accepted'
        WHEN invitation.expires_at <= pg_catalog.now() THEN 'expired'
        ELSE 'pending'
      END
    FROM private.staff_invitations AS invitation
    ORDER BY invitation.created_at DESC
    LIMIT 100;
END;
$function$;

ALTER FUNCTION public.list_staff_invitations() OWNER TO postgres;
REVOKE ALL ON FUNCTION public.list_staff_invitations() FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.list_staff_invitations() TO authenticated;
