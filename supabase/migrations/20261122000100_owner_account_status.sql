-- Owner-controlled synthetic account suspension/reactivation.
-- Retain Supabase authentication and enforce the action in the same PostgreSQL
-- transaction as the audit. No passwords or email identities are handled here.
CREATE OR REPLACE FUNCTION public.set_owner_account_status(
  target_user_id uuid,
  new_status public.account_status
)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
DECLARE
  actor_id uuid := auth.uid();
  previous_status public.account_status;
BEGIN
  IF actor_id IS NULL OR NOT private.current_account_is_active()
     OR NOT private.current_user_has_role('owner'::public.app_role) THEN
    RAISE EXCEPTION USING ERRCODE = '42501', MESSAGE = 'owner_required';
  END IF;
  IF coalesce(auth.jwt() ->> 'aal', 'aal1') <> 'aal2' THEN
    RAISE EXCEPTION USING ERRCODE = 'P0001', MESSAGE = 'mfa_required';
  END IF;
  IF new_status NOT IN ('active'::public.account_status, 'suspended'::public.account_status) THEN
    RAISE EXCEPTION USING ERRCODE = '22023', MESSAGE = 'invalid_account_status';
  END IF;
  IF target_user_id = actor_id THEN
    RAISE EXCEPTION USING ERRCODE = '23514', MESSAGE = 'own_account_protected';
  END IF;

  -- Serialize with Owner revocation to preserve a viable last Owner.
  PERFORM pg_catalog.pg_advisory_xact_lock(7123674591123::bigint);
  SELECT p.account_status INTO previous_status
    FROM public.profiles AS p WHERE p.user_id = target_user_id FOR UPDATE;
  IF NOT FOUND THEN
    RAISE EXCEPTION USING ERRCODE = 'P0002', MESSAGE = 'account_not_found';
  END IF;
  IF previous_status = 'closed'::public.account_status THEN
    RAISE EXCEPTION USING ERRCODE = '23514', MESSAGE = 'closed_account_protected';
  END IF;
  IF new_status = 'suspended'::public.account_status
     AND EXISTS (SELECT 1 FROM public.role_assignments r
                 WHERE r.user_id = target_user_id AND r.role = 'owner'::public.app_role
                   AND r.revoked_at IS NULL)
     AND (SELECT count(*) FROM public.role_assignments r
          JOIN public.profiles p ON p.user_id = r.user_id
          WHERE r.role = 'owner'::public.app_role AND r.revoked_at IS NULL
            AND p.account_status = 'active'::public.account_status) <= 1 THEN
    RAISE EXCEPTION USING ERRCODE = '23514', MESSAGE = 'last_owner_protected';
  END IF;
  IF previous_status = new_status THEN RETURN; END IF;
  UPDATE public.profiles SET account_status = new_status, updated_at = now()
    WHERE user_id = target_user_id;
  INSERT INTO private.security_audit_events (
    actor_id, action, target_type, target_id, outcome, reason_category)
  VALUES (actor_id, 'owner_account_status_changed', 'profile', target_user_id,
          'success', CASE WHEN new_status = 'suspended' THEN 'account_suspended'
                          ELSE 'account_reactivated' END);
END;
$$;
ALTER FUNCTION public.set_owner_account_status(uuid, public.account_status) OWNER TO postgres;
REVOKE ALL ON FUNCTION public.set_owner_account_status(uuid, public.account_status)
  FROM PUBLIC, anon, authenticated;
GRANT EXECUTE ON FUNCTION public.set_owner_account_status(uuid, public.account_status)
  TO authenticated;
