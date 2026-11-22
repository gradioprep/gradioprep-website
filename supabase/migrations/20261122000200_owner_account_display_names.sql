-- Owner-managed display names: authentic account data remains in existing profiles.
-- Caller identity and AAL2 are enforced inside the audited SQL transaction.
CREATE OR REPLACE FUNCTION public.owner_update_account_display_name(
  target_user_id uuid, new_display_name text
) RETURNS void LANGUAGE plpgsql SECURITY DEFINER SET search_path = ''
AS $$
DECLARE
  actor_id uuid := auth.uid();
  normalized text := btrim(new_display_name);
BEGIN
  IF actor_id IS NULL OR NOT private.current_account_is_active()
    OR NOT private.current_user_has_role('owner'::public.app_role) THEN
    RAISE EXCEPTION USING ERRCODE='42501', MESSAGE='owner_required';
  END IF;
  IF coalesce(auth.jwt()->>'aal','aal1') <> 'aal2' THEN
    RAISE EXCEPTION USING ERRCODE='P0001', MESSAGE='mfa_required';
  END IF;
  IF new_display_name IS NULL OR char_length(normalized) NOT BETWEEN 2 AND 80
    OR normalized ~ '[[:cntrl:]]' THEN
    RAISE EXCEPTION USING ERRCODE='22023', MESSAGE='invalid_display_name';
  END IF;
  UPDATE public.profiles
    SET display_name=normalized, updated_at=now()
    WHERE user_id=target_user_id AND account_status <> 'closed'::public.account_status
      AND display_name IS DISTINCT FROM normalized;
  IF NOT FOUND THEN
    IF NOT EXISTS (SELECT 1 FROM public.profiles
      WHERE user_id=target_user_id AND account_status <> 'closed'::public.account_status) THEN
      RAISE EXCEPTION USING ERRCODE='P0002', MESSAGE='account_not_found';
    END IF;
    RETURN;
  END IF;
  INSERT INTO private.security_audit_events
    (actor_id,action,target_type,target_id,outcome,reason_category)
  VALUES (actor_id,'owner_account_name_changed','profile',target_user_id,
    'success','display_name_update');
END;
$$;
ALTER FUNCTION public.owner_update_account_display_name(uuid,text) OWNER TO postgres;
REVOKE ALL ON FUNCTION public.owner_update_account_display_name(uuid,text)
 FROM PUBLIC,anon,authenticated;
GRANT EXECUTE ON FUNCTION public.owner_update_account_display_name(uuid,text) TO authenticated;
