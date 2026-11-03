-- Phase 1B: session and role revocation.
-- The application never receives or stores a service-role credential.
-- Account owners may revoke role assignments only from an MFA-verified (AAL2) session.

-- A role revocation must be attributed to the actor performing the revocation,
-- not the original grantor. Keep only a short reason category in the audit row.
CREATE OR REPLACE FUNCTION private.audit_role_assignment_change()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
DECLARE
  action_name text;
  actor uuid;
  reason_category text;
BEGIN
  IF TG_OP = 'INSERT' THEN
    action_name := 'role_granted';
    actor := NEW.granted_by;
    reason_category := left(NEW.reason, 80);
  ELSIF OLD.revoked_at IS NULL AND NEW.revoked_at IS NOT NULL THEN
    action_name := 'role_revoked';
    actor := NEW.revoked_by;
    reason_category := left(NEW.reason, 80);
  ELSE
    action_name := 'role_assignment_updated';
    actor := coalesce(NEW.revoked_by, NEW.granted_by, OLD.revoked_by, OLD.granted_by);
    reason_category := left(coalesce(NEW.reason, OLD.reason), 80);
  END IF;

  INSERT INTO private.security_audit_events (
    actor_id, action, target_type, target_id, outcome, reason_category
  )
  VALUES (
    actor,
    action_name,
    'role_assignment',
    coalesce(NEW.id, OLD.id),
    'success',
    reason_category
  );

  RETURN coalesce(NEW, OLD);
END;
$$;

-- This RPC is the only application-facing role-revocation path. It performs
-- authorization and mutation in one transaction and preserves one active owner.
CREATE OR REPLACE FUNCTION public.revoke_role_assignment(
  target_user_id uuid,
  target_role public.app_role,
  reason_text text
)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
DECLARE
  actor_id uuid := auth.uid();
  assignment_id uuid;
  active_owner_count integer;
BEGIN
  IF actor_id IS NULL OR NOT private.current_account_is_active() THEN
    RAISE EXCEPTION USING
      ERRCODE = '42501',
      MESSAGE = 'role_management_forbidden';
  END IF;

  IF NOT private.current_user_has_role('owner') THEN
    RAISE EXCEPTION USING
      ERRCODE = '42501',
      MESSAGE = 'role_management_forbidden';
  END IF;

  -- Do not expose role-management operations to an owner session that has
  -- only a first-factor JWT. Supabase issues AAL2 only after MFA verification.
  IF coalesce(auth.jwt() ->> 'aal', 'aal1') <> 'aal2' THEN
    RAISE EXCEPTION USING
      ERRCODE = 'P0001',
      MESSAGE = 'mfa_required';
  END IF;

  IF reason_text IS NULL OR char_length(btrim(reason_text)) NOT BETWEEN 3 AND 240 THEN
    RAISE EXCEPTION USING
      ERRCODE = '22023',
      MESSAGE = 'invalid_revocation_reason';
  END IF;

  -- Serialize role revocations so two concurrent requests cannot both remove
  -- the final two active owner grants based on the same pre-update count.
  PERFORM pg_catalog.pg_advisory_xact_lock(7123674591123::bigint);

  SELECT assignment.id
  INTO assignment_id
  FROM public.role_assignments AS assignment
  WHERE assignment.user_id = target_user_id
    AND assignment.role = target_role
    AND assignment.revoked_at IS NULL
  FOR UPDATE;

  IF assignment_id IS NULL THEN
    RAISE EXCEPTION USING
      ERRCODE = 'P0002',
      MESSAGE = 'role_assignment_not_found';
  END IF;

  IF target_role = 'owner' THEN
    SELECT count(*)::integer
    INTO active_owner_count
    FROM public.role_assignments AS assignment
    WHERE assignment.role = 'owner'
      AND assignment.revoked_at IS NULL;

    IF active_owner_count <= 1 THEN
      RAISE EXCEPTION USING
        ERRCODE = '23514',
        MESSAGE = 'last_active_owner_protected';
    END IF;
  END IF;

  UPDATE public.role_assignments
  SET revoked_at = now(),
      revoked_by = actor_id,
      reason = btrim(reason_text)
  WHERE id = assignment_id;
END;
$$;

REVOKE ALL ON FUNCTION public.revoke_role_assignment(uuid, public.app_role, text)
  FROM PUBLIC, anon, authenticated;
GRANT EXECUTE ON FUNCTION public.revoke_role_assignment(uuid, public.app_role, text)
  TO authenticated;
