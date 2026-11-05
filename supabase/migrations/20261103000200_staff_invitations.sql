-- Phase 1B: secure staff invitation lifecycle.
-- Invitation tokens are one-time bearer secrets. Only their SHA-256 hashes are stored.
-- Privileged assignment is completed only by a verified, AAL2 session matching the invited email.

CREATE TABLE private.staff_invitations (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  invited_email text NOT NULL
    CHECK (
      invited_email = lower(btrim(invited_email))
      AND char_length(invited_email) BETWEEN 6 AND 320
      AND invited_email ~ '^[^[:space:]@]+@[^[:space:]@]+\.[^[:space:]@]+$'
    ),
  invited_role public.app_role NOT NULL
    CHECK (invited_role IN ('grader'::public.app_role, 'admin'::public.app_role)),
  token_hash text NOT NULL UNIQUE
    CHECK (token_hash ~ '^[0-9a-f]{64}$'),
  created_by uuid REFERENCES auth.users (id) ON DELETE SET NULL,
  created_at timestamptz NOT NULL DEFAULT now(),
  expires_at timestamptz NOT NULL DEFAULT (now() + interval '7 days'),
  accepted_by uuid REFERENCES auth.users (id) ON DELETE SET NULL,
  accepted_at timestamptz,
  revoked_by uuid REFERENCES auth.users (id) ON DELETE SET NULL,
  revoked_at timestamptz,
  CHECK (expires_at > created_at AND expires_at <= created_at + interval '7 days'),
  CHECK ((accepted_by IS NULL) = (accepted_at IS NULL)),
  CHECK ((revoked_by IS NULL) = (revoked_at IS NULL)),
  CHECK (accepted_at IS NULL OR revoked_at IS NULL)
);

ALTER TABLE private.staff_invitations ENABLE ROW LEVEL SECURITY;
REVOKE ALL ON TABLE private.staff_invitations FROM PUBLIC, anon, authenticated;

CREATE INDEX staff_invitations_owner_created_idx
  ON private.staff_invitations (created_by, created_at DESC);
CREATE INDEX staff_invitations_pending_email_idx
  ON private.staff_invitations (invited_email, invited_role, expires_at)
  WHERE accepted_at IS NULL AND revoked_at IS NULL;

CREATE OR REPLACE FUNCTION public.create_staff_invitation(
  p_email text,
  p_role public.app_role,
  p_token_hash text
)
RETURNS TABLE (
  invitation_id uuid,
  invited_email text,
  invited_role public.app_role,
  created_at timestamptz,
  expires_at timestamptz
)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
DECLARE
  actor_id uuid := auth.uid();
  normalized_email text := pg_catalog.lower(pg_catalog.btrim(p_email));
  recent_count integer;
  existing_user_id uuid;
  new_invitation_id uuid;
  new_created_at timestamptz;
  new_expires_at timestamptz;
BEGIN
  IF actor_id IS NULL
    OR NOT private.current_account_is_active()
    OR NOT private.current_user_has_role('owner'::public.app_role) THEN
    RAISE EXCEPTION USING ERRCODE = '42501', MESSAGE = 'staff_invitation_forbidden';
  END IF;

  IF COALESCE(auth.jwt() ->> 'aal', 'aal1') <> 'aal2' THEN
    RAISE EXCEPTION USING ERRCODE = 'P0001', MESSAGE = 'mfa_required';
  END IF;

  IF normalized_email IS NULL
    OR pg_catalog.char_length(normalized_email) < 6
    OR pg_catalog.char_length(normalized_email) > 320
    OR normalized_email !~ '^[^[:space:]@]+@[^[:space:]@]+\.[^[:space:]@]+$' THEN
    RAISE EXCEPTION USING ERRCODE = '22023', MESSAGE = 'invalid_invitation_email';
  END IF;

  IF p_role IS NULL
    OR p_role NOT IN ('grader'::public.app_role, 'admin'::public.app_role) THEN
    RAISE EXCEPTION USING ERRCODE = '22023', MESSAGE = 'invalid_invitation_role';
  END IF;

  IF p_token_hash IS NULL OR p_token_hash !~ '^[0-9a-f]{64}$' THEN
    RAISE EXCEPTION USING ERRCODE = '22023', MESSAGE = 'invalid_invitation_token_hash';
  END IF;

  -- Serialize creation so the per-owner rolling limit cannot be raced.
  PERFORM pg_catalog.pg_advisory_xact_lock(7123674591124::bigint);
  SELECT pg_catalog.count(*)::integer
    INTO recent_count
    FROM private.staff_invitations AS invitation
    WHERE invitation.created_by = actor_id
      AND invitation.created_at >= pg_catalog.now() - interval '15 minutes';

  IF recent_count >= 5 THEN
    RAISE EXCEPTION USING ERRCODE = 'P0001', MESSAGE = 'invitation_rate_limited';
  END IF;

  IF EXISTS (
    SELECT 1
    FROM private.staff_invitations AS invitation
    WHERE invitation.invited_email = normalized_email
      AND invitation.invited_role = p_role
      AND invitation.accepted_at IS NULL
      AND invitation.revoked_at IS NULL
      AND invitation.expires_at > pg_catalog.now()
  ) THEN
    RAISE EXCEPTION USING ERRCODE = '23505', MESSAGE = 'invitation_already_pending';
  END IF;

  SELECT auth_user.id
    INTO existing_user_id
    FROM auth.users AS auth_user
    WHERE pg_catalog.lower(auth_user.email) = normalized_email
    LIMIT 1;

  IF existing_user_id IS NOT NULL AND EXISTS (
    SELECT 1
    FROM public.role_assignments AS assignment
    WHERE assignment.user_id = existing_user_id
      AND assignment.role = p_role
      AND assignment.revoked_at IS NULL
  ) THEN
    RAISE EXCEPTION USING ERRCODE = '23505', MESSAGE = 'invitation_role_already_active';
  END IF;

  INSERT INTO private.staff_invitations (
    invited_email, invited_role, token_hash, created_by
  )
  VALUES (
    normalized_email, p_role, p_token_hash, actor_id
  )
  RETURNING id, private.staff_invitations.created_at, private.staff_invitations.expires_at
    INTO new_invitation_id, new_created_at, new_expires_at;

  INSERT INTO private.security_audit_events (
    actor_id, action, target_type, target_id, outcome, reason_category
  )
  VALUES (
    actor_id, 'staff_invitation_created', 'staff_invitation',
    new_invitation_id, 'success', p_role::text
  );

  RETURN QUERY
    SELECT new_invitation_id, normalized_email, p_role, new_created_at, new_expires_at;
END;
$$;

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
STABLE
SECURITY DEFINER
SET search_path = ''
AS $$
DECLARE
  actor_id uuid := auth.uid();
BEGIN
  IF actor_id IS NULL
    OR NOT private.current_account_is_active()
    OR NOT private.current_user_has_role('owner'::public.app_role) THEN
    RAISE EXCEPTION USING ERRCODE = '42501', MESSAGE = 'staff_invitation_forbidden';
  END IF;

  IF COALESCE(auth.jwt() ->> 'aal', 'aal1') <> 'aal2' THEN
    RAISE EXCEPTION USING ERRCODE = 'P0001', MESSAGE = 'mfa_required';
  END IF;

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
$$;

CREATE OR REPLACE FUNCTION public.revoke_staff_invitation(
  p_invitation_id uuid,
  p_reason text
)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
DECLARE
  actor_id uuid := auth.uid();
  invitation_row private.staff_invitations%ROWTYPE;
BEGIN
  IF actor_id IS NULL
    OR NOT private.current_account_is_active()
    OR NOT private.current_user_has_role('owner'::public.app_role) THEN
    RAISE EXCEPTION USING ERRCODE = '42501', MESSAGE = 'staff_invitation_forbidden';
  END IF;

  IF COALESCE(auth.jwt() ->> 'aal', 'aal1') <> 'aal2' THEN
    RAISE EXCEPTION USING ERRCODE = 'P0001', MESSAGE = 'mfa_required';
  END IF;

  IF p_invitation_id IS NULL
    OR p_reason IS NULL
    OR pg_catalog.char_length(pg_catalog.btrim(p_reason)) NOT BETWEEN 3 AND 80 THEN
    RAISE EXCEPTION USING ERRCODE = '22023', MESSAGE = 'invalid_invitation_reason';
  END IF;

  SELECT invitation.*
    INTO invitation_row
    FROM private.staff_invitations AS invitation
    WHERE invitation.id = p_invitation_id
    FOR UPDATE;

  IF NOT FOUND THEN
    RAISE EXCEPTION USING ERRCODE = 'P0002', MESSAGE = 'invitation_not_found';
  END IF;

  IF invitation_row.accepted_at IS NOT NULL
    OR invitation_row.revoked_at IS NOT NULL
    OR invitation_row.expires_at <= pg_catalog.now() THEN
    RAISE EXCEPTION USING ERRCODE = 'P0001', MESSAGE = 'invitation_not_pending';
  END IF;

  UPDATE private.staff_invitations
    SET revoked_by = actor_id, revoked_at = pg_catalog.now()
    WHERE id = invitation_row.id;

  INSERT INTO private.security_audit_events (
    actor_id, action, target_type, target_id, outcome, reason_category
  )
  VALUES (
    actor_id, 'staff_invitation_revoked', 'staff_invitation',
    invitation_row.id, 'success', 'owner_revocation'
  );
END;
$$;

CREATE OR REPLACE FUNCTION public.accept_staff_invitation(p_token_hash text)
RETURNS TABLE (
  accepted_role public.app_role,
  invitation_id uuid
)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
DECLARE
  actor_id uuid := auth.uid();
  invitation_row private.staff_invitations%ROWTYPE;
  account_email text;
  account_email_confirmed_at timestamptz;
BEGIN
  IF actor_id IS NULL OR NOT private.current_account_is_active() THEN
    RAISE EXCEPTION USING ERRCODE = '42501', MESSAGE = 'staff_invitation_forbidden';
  END IF;

  IF COALESCE(auth.jwt() ->> 'aal', 'aal1') <> 'aal2' THEN
    RAISE EXCEPTION USING ERRCODE = 'P0001', MESSAGE = 'mfa_required';
  END IF;

  IF p_token_hash IS NULL OR p_token_hash !~ '^[0-9a-f]{64}$' THEN
    RAISE EXCEPTION USING ERRCODE = '22023', MESSAGE = 'invalid_invitation_token_hash';
  END IF;

  SELECT invitation.*
    INTO invitation_row
    FROM private.staff_invitations AS invitation
    WHERE invitation.token_hash = p_token_hash
    FOR UPDATE;

  IF NOT FOUND THEN
    RAISE EXCEPTION USING ERRCODE = 'P0002', MESSAGE = 'invitation_not_found';
  END IF;

  IF invitation_row.revoked_at IS NOT NULL THEN
    RAISE EXCEPTION USING ERRCODE = 'P0001', MESSAGE = 'invitation_revoked';
  END IF;

  IF invitation_row.accepted_at IS NOT NULL THEN
    RAISE EXCEPTION USING ERRCODE = 'P0001', MESSAGE = 'invitation_already_used';
  END IF;

  IF invitation_row.expires_at <= pg_catalog.now() THEN
    RAISE EXCEPTION USING ERRCODE = 'P0001', MESSAGE = 'invitation_expired';
  END IF;

  SELECT auth_user.email, auth_user.email_confirmed_at
    INTO account_email, account_email_confirmed_at
    FROM auth.users AS auth_user
    WHERE auth_user.id = actor_id;

  IF account_email IS NULL OR account_email_confirmed_at IS NULL THEN
    RAISE EXCEPTION USING ERRCODE = '42501', MESSAGE = 'invitation_email_unverified';
  END IF;

  IF pg_catalog.lower(account_email) <> invitation_row.invited_email THEN
    RAISE EXCEPTION USING ERRCODE = '42501', MESSAGE = 'invitation_email_mismatch';
  END IF;

  -- Prevent concurrent accepts from assigning the same role twice.
  PERFORM pg_catalog.pg_advisory_xact_lock(7123674591125::bigint);

  IF EXISTS (
    SELECT 1
    FROM public.role_assignments AS assignment
    WHERE assignment.user_id = actor_id
      AND assignment.role = invitation_row.invited_role
      AND assignment.revoked_at IS NULL
  ) THEN
    RAISE EXCEPTION USING ERRCODE = '23505', MESSAGE = 'invitation_role_already_active';
  END IF;

  BEGIN
    INSERT INTO public.role_assignments (
      user_id, role, granted_by, reason
    )
    VALUES (
      actor_id, invitation_row.invited_role, invitation_row.created_by,
      'accepted_staff_invitation'
    );
  EXCEPTION WHEN unique_violation THEN
    RAISE EXCEPTION USING ERRCODE = '23505', MESSAGE = 'invitation_role_already_active';
  END;

  UPDATE private.staff_invitations
    SET accepted_by = actor_id, accepted_at = pg_catalog.now()
    WHERE id = invitation_row.id;

  INSERT INTO private.security_audit_events (
    actor_id, action, target_type, target_id, outcome, reason_category
  )
  VALUES (
    actor_id, 'staff_invitation_accepted', 'staff_invitation',
    invitation_row.id, 'success', invitation_row.invited_role::text
  );

  RETURN QUERY SELECT invitation_row.invited_role, invitation_row.id;
END;
$$;

REVOKE ALL ON FUNCTION public.create_staff_invitation(text, public.app_role, text) FROM PUBLIC;
REVOKE ALL ON FUNCTION public.list_staff_invitations() FROM PUBLIC;
REVOKE ALL ON FUNCTION public.revoke_staff_invitation(uuid, text) FROM PUBLIC;
REVOKE ALL ON FUNCTION public.accept_staff_invitation(text) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.create_staff_invitation(text, public.app_role, text) TO authenticated;
GRANT EXECUTE ON FUNCTION public.list_staff_invitations() TO authenticated;
GRANT EXECUTE ON FUNCTION public.revoke_staff_invitation(uuid, text) TO authenticated;
GRANT EXECUTE ON FUNCTION public.accept_staff_invitation(text) TO authenticated;
