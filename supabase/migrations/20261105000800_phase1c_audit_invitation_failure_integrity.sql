-- Phase 1C-E: prevent caller-forged staff invitation acceptance failures.
-- Only database-derived denial/state failures are recorded. An otherwise
-- eligible pending invitation returns false and creates no event.

DROP FUNCTION IF EXISTS public.audit_staff_invitation_acceptance_failure(text, text);

CREATE FUNCTION public.audit_staff_invitation_acceptance_failure(p_token_hash text)
RETURNS boolean
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $function$
DECLARE
  actor_id uuid := auth.uid();
  invitation_row private.staff_invitations%ROWTYPE;
  account_email text;
  account_email_confirmed_at timestamptz;
  event_outcome text;
  event_reason text;
BEGIN
  IF actor_id IS NULL
    OR p_token_hash IS NULL
    OR p_token_hash !~ '^[0-9a-f]{64}$' THEN
    RETURN false;
  END IF;

  SELECT invitation.*
  INTO invitation_row
  FROM private.staff_invitations AS invitation
  WHERE invitation.token_hash = p_token_hash;

  IF NOT FOUND THEN
    RETURN false;
  END IF;

  IF NOT private.current_account_is_active() THEN
    event_outcome := 'denied';
    event_reason := 'inactive_account';
  ELSIF coalesce(auth.jwt() ->> 'aal', 'aal1') <> 'aal2' THEN
    event_outcome := 'denied';
    event_reason := 'aal2_required';
  ELSE
    SELECT auth_user.email, auth_user.email_confirmed_at
    INTO account_email, account_email_confirmed_at
    FROM auth.users AS auth_user
    WHERE auth_user.id = actor_id;

    IF account_email IS NULL OR account_email_confirmed_at IS NULL THEN
      event_outcome := 'denied';
      event_reason := 'email_unverified';
    ELSIF pg_catalog.lower(account_email) <> invitation_row.invited_email THEN
      event_outcome := 'denied';
      event_reason := 'email_mismatch';
    ELSIF invitation_row.revoked_at IS NOT NULL
      OR invitation_row.accepted_at IS NOT NULL
      OR invitation_row.expires_at <= pg_catalog.now() THEN
      event_outcome := 'failed';
      event_reason := 'state_conflict';
    ELSIF EXISTS (
      SELECT 1
      FROM public.role_assignments AS assignment
      WHERE assignment.user_id = actor_id
        AND assignment.role = invitation_row.invited_role
        AND assignment.revoked_at IS NULL
    ) THEN
      event_outcome := 'failed';
      event_reason := 'state_conflict';
    ELSE
      -- If the invitee is eligible, a caller cannot invent an operation failure.
      RETURN false;
    END IF;
  END IF;

  INSERT INTO private.security_audit_events (
    actor_id, action, target_type, target_id, outcome, reason_category
  )
  VALUES (
    actor_id, 'staff_invitation_accepted', 'staff_invitation',
    invitation_row.id, event_outcome, event_reason
  );

  RETURN true;
END;
$function$;

ALTER FUNCTION public.audit_staff_invitation_acceptance_failure(text)
  OWNER TO postgres;
REVOKE ALL ON FUNCTION public.audit_staff_invitation_acceptance_failure(text)
  FROM PUBLIC, anon, authenticated;
GRANT EXECUTE ON FUNCTION public.audit_staff_invitation_acceptance_failure(text)
  TO authenticated;

COMMENT ON FUNCTION public.audit_staff_invitation_acceptance_failure(text) IS
  'Records only database-derived invitation acceptance denials/state failures after resolving a SHA-256 hash to a private invitation row. Returns false without an event when acceptance is otherwise eligible. Never stores token hash or email.';
