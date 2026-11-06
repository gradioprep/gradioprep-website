-- Phase 1E: verified account-deletion request ledger and legal-hold controls.
-- This slice records and governs requests only. It does not delete accounts,
-- assessments, feedback, submission files, Storage objects or processor copies.
-- Destructive execution requires a later, separately tested workflow.

CREATE TABLE private.account_deletion_requests (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  subject_user_id uuid REFERENCES auth.users(id) ON DELETE SET NULL,
  request_scope text NOT NULL DEFAULT 'account_and_associated_learning_records'
    CHECK (request_scope = 'account_and_associated_learning_records'),
  request_reason_category text NOT NULL
    CHECK (request_reason_category IN ('account_closure', 'data_erasure')),
  status text NOT NULL DEFAULT 'under_review'
    CHECK (status IN (
      'under_review', 'on_hold', 'approved', 'executing',
      'completed', 'rejected', 'cancelled'
    )),
  identity_verification_method text NOT NULL
    CHECK (identity_verification_method = 'authenticated_confirmed_email'),
  identity_verified_at timestamptz NOT NULL,
  requester_email_confirmed_at timestamptz NOT NULL,
  requested_at timestamptz NOT NULL,
  response_due_at timestamptz NOT NULL,
  reviewed_by uuid, -- retain only the staff UUID as minimal, non-content decision evidence
  reviewed_at timestamptz,
  decision_reason_category text
    CHECK (decision_reason_category IS NULL OR decision_reason_category IN (
      'retention_review_complete', 'legal_retention_required',
      'identity_mismatch', 'request_out_of_scope', 'other_review'
    )),
  completed_at timestamptz,
  CHECK (identity_verified_at = requested_at),
  CHECK (response_due_at = requested_at + interval '30 days'),
  CHECK (
    (reviewed_at IS NULL AND reviewed_by IS NULL AND decision_reason_category IS NULL)
    OR
    (reviewed_at IS NOT NULL AND reviewed_by IS NOT NULL AND decision_reason_category IS NOT NULL)
  ),
  CHECK ((status = 'completed') = (completed_at IS NOT NULL))
);

CREATE UNIQUE INDEX account_deletion_one_open_request_per_subject
  ON private.account_deletion_requests (subject_user_id)
  WHERE status IN ('under_review', 'on_hold', 'approved', 'executing');
CREATE INDEX account_deletion_request_status_due_idx
  ON private.account_deletion_requests (status, response_due_at);

CREATE TABLE private.account_deletion_legal_holds (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  request_id uuid NOT NULL
    REFERENCES private.account_deletion_requests(id) ON DELETE RESTRICT,
  subject_user_id uuid REFERENCES auth.users(id) ON DELETE SET NULL,
  prior_request_status text NOT NULL CHECK (prior_request_status IN ('under_review', 'approved')),
  authority_category text NOT NULL
    CHECK (authority_category IN (
      'court_order', 'statutory_requirement', 'safeguarding',
      'active_dispute', 'regulatory_request', 'other_approved'
    )),
  authority_reference text NOT NULL
    CHECK (char_length(btrim(authority_reference)) BETWEEN 3 AND 120),
  reason_summary text NOT NULL
    CHECK (char_length(btrim(reason_summary)) BETWEEN 12 AND 500),
  placed_by uuid, -- minimal non-content actor reference survives account closure
  placed_at timestamptz NOT NULL DEFAULT clock_timestamp(),
  review_due_at timestamptz NOT NULL CHECK (review_due_at > placed_at),
  released_by uuid, -- minimal non-content actor reference survives account closure
  released_at timestamptz,
  release_reason_category text
    CHECK (release_reason_category IS NULL OR release_reason_category IN (
      'authority_expired', 'authority_withdrawn', 'review_cleared', 'other_release'
    )),
  CHECK (
    (released_at IS NULL AND released_by IS NULL AND release_reason_category IS NULL)
    OR
    (released_at IS NOT NULL AND released_by IS NOT NULL AND release_reason_category IS NOT NULL)
  )
);

CREATE UNIQUE INDEX account_deletion_one_active_hold_per_request
  ON private.account_deletion_legal_holds (request_id)
  WHERE released_at IS NULL;
CREATE INDEX account_deletion_holds_review_due_idx
  ON private.account_deletion_legal_holds (review_due_at)
  WHERE released_at IS NULL;

ALTER TABLE private.account_deletion_requests ENABLE ROW LEVEL SECURITY;
ALTER TABLE private.account_deletion_legal_holds ENABLE ROW LEVEL SECURITY;
REVOKE ALL ON private.account_deletion_requests,
  private.account_deletion_legal_holds FROM PUBLIC, anon, authenticated, service_role;

CREATE OR REPLACE FUNCTION private.protect_account_deletion_request()
RETURNS trigger
LANGUAGE plpgsql
SET search_path = ''
AS $function$
BEGIN
  IF TG_OP = 'DELETE' THEN
    RAISE EXCEPTION USING ERRCODE = '42501', MESSAGE = 'account_deletion_request_delete_requires_retention_workflow';
  END IF;

  IF ROW(
    NEW.id, NEW.request_scope, NEW.request_reason_category,
    NEW.identity_verification_method, NEW.identity_verified_at,
    NEW.requester_email_confirmed_at, NEW.requested_at, NEW.response_due_at
  ) IS DISTINCT FROM ROW(
    OLD.id, OLD.request_scope, OLD.request_reason_category,
    OLD.identity_verification_method, OLD.identity_verified_at,
    OLD.requester_email_confirmed_at, OLD.requested_at, OLD.response_due_at
  )
  OR (NEW.subject_user_id IS DISTINCT FROM OLD.subject_user_id AND NEW.subject_user_id IS NOT NULL) THEN
    RAISE EXCEPTION USING ERRCODE = '42501', MESSAGE = 'account_deletion_request_identity_immutable';
  END IF;

  IF NEW.status IS DISTINCT FROM OLD.status AND NOT (
    (OLD.status = 'under_review' AND NEW.status IN ('on_hold', 'approved', 'rejected'))
    OR (OLD.status = 'approved' AND NEW.status IN ('on_hold', 'executing'))
    OR (OLD.status = 'on_hold' AND NEW.status IN ('under_review', 'approved'))
    OR (OLD.status = 'executing' AND NEW.status = 'completed')
  ) THEN
    RAISE EXCEPTION USING ERRCODE = '42501', MESSAGE = 'account_deletion_request_invalid_transition';
  END IF;

  IF OLD.reviewed_at IS NOT NULL AND ROW(
    NEW.reviewed_by, NEW.reviewed_at, NEW.decision_reason_category
  ) IS DISTINCT FROM ROW(
    OLD.reviewed_by, OLD.reviewed_at, OLD.decision_reason_category
  ) THEN
    RAISE EXCEPTION USING ERRCODE = '42501', MESSAGE = 'account_deletion_review_evidence_immutable';
  END IF;

  IF OLD.completed_at IS NOT NULL AND NEW.completed_at IS DISTINCT FROM OLD.completed_at THEN
    RAISE EXCEPTION USING ERRCODE = '42501', MESSAGE = 'account_deletion_completion_evidence_immutable';
  END IF;

  RETURN NEW;
END;
$function$;

CREATE TRIGGER account_deletion_request_integrity
  BEFORE UPDATE OR DELETE ON private.account_deletion_requests
  FOR EACH ROW EXECUTE FUNCTION private.protect_account_deletion_request();

CREATE OR REPLACE FUNCTION private.protect_account_deletion_legal_hold()
RETURNS trigger
LANGUAGE plpgsql
SET search_path = ''
AS $function$
BEGIN
  IF TG_OP = 'DELETE' THEN
    RAISE EXCEPTION USING ERRCODE = '42501', MESSAGE = 'account_deletion_legal_hold_delete_forbidden';
  END IF;

  IF OLD.released_at IS NOT NULL THEN
    RAISE EXCEPTION USING ERRCODE = '42501', MESSAGE = 'account_deletion_legal_hold_release_immutable';
  END IF;

  IF ROW(
    NEW.id, NEW.request_id, NEW.prior_request_status, NEW.authority_category, NEW.authority_reference,
    NEW.reason_summary, NEW.placed_by, NEW.placed_at, NEW.review_due_at
  ) IS DISTINCT FROM ROW(
    OLD.id, OLD.request_id, OLD.prior_request_status, OLD.authority_category, OLD.authority_reference,
    OLD.reason_summary, OLD.placed_by, OLD.placed_at, OLD.review_due_at
  )
  OR (NEW.subject_user_id IS DISTINCT FROM OLD.subject_user_id AND NEW.subject_user_id IS NOT NULL) THEN
    RAISE EXCEPTION USING ERRCODE = '42501', MESSAGE = 'account_deletion_legal_hold_evidence_immutable';
  END IF;

  IF NEW.released_at IS NULL OR NEW.released_by IS NULL
    OR NEW.release_reason_category IS NULL THEN
    RAISE EXCEPTION USING ERRCODE = '42501', MESSAGE = 'account_deletion_legal_hold_release_incomplete';
  END IF;

  RETURN NEW;
END;
$function$;

CREATE TRIGGER account_deletion_legal_hold_integrity
  BEFORE UPDATE OR DELETE ON private.account_deletion_legal_holds
  FOR EACH ROW EXECUTE FUNCTION private.protect_account_deletion_legal_hold();

CREATE OR REPLACE FUNCTION public.request_account_deletion(
  p_reason_category text DEFAULT 'account_closure'
)
RETURNS TABLE(
  request_id uuid,
  request_status text,
  requested_at timestamptz,
  response_due_at timestamptz,
  is_replay boolean
)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $function$
DECLARE
  actor_id uuid := auth.uid();
  confirmed_at timestamptz;
  selected_profile_id uuid;
  existing_request private.account_deletion_requests%ROWTYPE;
  created_request private.account_deletion_requests%ROWTYPE;
  request_time timestamptz;
BEGIN
  IF coalesce(auth.jwt() ->> 'role', '') <> 'authenticated'
    OR actor_id IS NULL
    OR p_reason_category IS NULL
    OR p_reason_category NOT IN ('account_closure', 'data_erasure') THEN
    RAISE EXCEPTION USING ERRCODE = '42501', MESSAGE = 'account_deletion_request_forbidden';
  END IF;

  SELECT profile.user_id, auth_user.email_confirmed_at
    INTO selected_profile_id, confirmed_at
  FROM public.profiles AS profile
  JOIN auth.users AS auth_user ON auth_user.id = profile.user_id
  WHERE profile.user_id = actor_id
    AND profile.account_status = 'active'
  FOR UPDATE OF profile;

  IF NOT FOUND OR confirmed_at IS NULL THEN
    RAISE EXCEPTION USING ERRCODE = '42501', MESSAGE = 'account_deletion_request_forbidden';
  END IF;

  SELECT request.* INTO existing_request
  FROM private.account_deletion_requests AS request
  WHERE request.subject_user_id = actor_id
    AND request.status IN ('under_review', 'on_hold', 'approved', 'executing');

  IF FOUND THEN
    RETURN QUERY SELECT existing_request.id, existing_request.status,
      existing_request.requested_at, existing_request.response_due_at, true;
    RETURN;
  END IF;

  request_time := clock_timestamp();
  INSERT INTO private.account_deletion_requests (
    subject_user_id, request_reason_category, status,
    identity_verification_method, identity_verified_at,
    requester_email_confirmed_at, requested_at, response_due_at
  )
  VALUES (
    actor_id, p_reason_category, 'under_review',
    'authenticated_confirmed_email', request_time,
    confirmed_at, request_time, request_time + interval '30 days'
  )
  RETURNING * INTO created_request;

  INSERT INTO private.security_audit_events (
    actor_id, action, target_type, target_id, outcome, reason_category
  )
  VALUES (
    actor_id, 'account_deletion_request_submitted',
    'account_deletion_request', created_request.id,
    'success', p_reason_category
  );

  RETURN QUERY SELECT created_request.id, created_request.status,
    created_request.requested_at, created_request.response_due_at, false;
END;
$function$;

CREATE OR REPLACE FUNCTION public.list_account_deletion_requests()
RETURNS TABLE(
  request_id uuid,
  subject_user_id uuid,
  request_reason_category text,
  request_status text,
  requested_at timestamptz,
  response_due_at timestamptz,
  identity_verified_at timestamptz,
  reviewed_at timestamptz,
  decision_reason_category text,
  has_active_legal_hold boolean
)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $function$
DECLARE
  actor_id uuid := auth.uid();
BEGIN
  IF coalesce(auth.jwt() ->> 'role', '') <> 'authenticated'
    OR actor_id IS NULL
    OR NOT private.current_account_is_active()
    OR NOT private.current_user_has_role('owner'::public.app_role)
    OR coalesce(auth.jwt() ->> 'aal', 'aal1') <> 'aal2' THEN
    RAISE EXCEPTION USING ERRCODE = '42501', MESSAGE = 'account_deletion_owner_aal2_required';
  END IF;

  INSERT INTO private.security_audit_events (
    actor_id, action, target_type, target_id, outcome, reason_category
  )
  VALUES (
    actor_id, 'account_deletion_requests_listed',
    'account_deletion_request_collection', NULL, 'success', 'owner_aal2'
  );

  RETURN QUERY
  SELECT request.id, request.subject_user_id,
    request.request_reason_category, request.status, request.requested_at,
    request.response_due_at, request.identity_verified_at, request.reviewed_at,
    request.decision_reason_category,
    EXISTS (
      SELECT 1 FROM private.account_deletion_legal_holds AS legal_hold
      WHERE legal_hold.request_id = request.id AND legal_hold.released_at IS NULL
    )
  FROM private.account_deletion_requests AS request
  ORDER BY request.requested_at ASC, request.id ASC;
END;
$function$;

CREATE OR REPLACE FUNCTION public.place_account_deletion_legal_hold(
  p_request_id uuid,
  p_authority_category text,
  p_authority_reference text,
  p_reason_summary text,
  p_review_due_at timestamptz
)
RETURNS uuid
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $function$
DECLARE
  actor_id uuid := auth.uid();
  selected_request private.account_deletion_requests%ROWTYPE;
  created_hold private.account_deletion_legal_holds%ROWTYPE;
BEGIN
  IF coalesce(auth.jwt() ->> 'role', '') <> 'authenticated'
    OR actor_id IS NULL
    OR NOT private.current_account_is_active()
    OR NOT private.current_user_has_role('owner'::public.app_role)
    OR coalesce(auth.jwt() ->> 'aal', 'aal1') <> 'aal2' THEN
    RAISE EXCEPTION USING ERRCODE = '42501', MESSAGE = 'account_deletion_owner_aal2_required';
  END IF;

  IF p_request_id IS NULL
    OR p_authority_category IS NULL OR p_authority_category NOT IN (
      'court_order', 'statutory_requirement', 'safeguarding',
      'active_dispute', 'regulatory_request', 'other_approved'
    )
    OR p_authority_reference IS NULL
    OR char_length(btrim(p_authority_reference)) NOT BETWEEN 3 AND 120
    OR p_reason_summary IS NULL
    OR char_length(btrim(p_reason_summary)) NOT BETWEEN 12 AND 500
    OR p_review_due_at IS NULL OR p_review_due_at <= clock_timestamp() THEN
    RAISE EXCEPTION USING ERRCODE = '22023', MESSAGE = 'invalid_account_deletion_legal_hold';
  END IF;

  SELECT request.* INTO selected_request
  FROM private.account_deletion_requests AS request
  WHERE request.id = p_request_id
  FOR UPDATE;

  IF NOT FOUND OR selected_request.status IN ('completed', 'rejected', 'cancelled') THEN
    RAISE EXCEPTION USING ERRCODE = 'P0002', MESSAGE = 'account_deletion_request_not_open';
  END IF;
  IF EXISTS (
    SELECT 1 FROM private.account_deletion_legal_holds AS legal_hold
    WHERE legal_hold.request_id = p_request_id AND legal_hold.released_at IS NULL
  ) THEN
    RAISE EXCEPTION USING ERRCODE = 'P0001', MESSAGE = 'account_deletion_legal_hold_already_active';
  END IF;

  INSERT INTO private.account_deletion_legal_holds (
    request_id, subject_user_id, prior_request_status, authority_category, authority_reference,
    reason_summary, placed_by, review_due_at
  )
  VALUES (
    p_request_id, selected_request.subject_user_id, selected_request.status, p_authority_category,
    btrim(p_authority_reference), btrim(p_reason_summary), actor_id, p_review_due_at
  )
  RETURNING * INTO created_hold;

  UPDATE private.account_deletion_requests
  SET status = 'on_hold'
  WHERE id = p_request_id;

  INSERT INTO private.security_audit_events (
    actor_id, action, target_type, target_id, outcome, reason_category
  )
  VALUES (
    actor_id, 'account_deletion_legal_hold_placed',
    'account_deletion_legal_hold', created_hold.id, 'success', p_authority_category
  );

  RETURN created_hold.id;
END;
$function$;

CREATE OR REPLACE FUNCTION public.release_account_deletion_legal_hold(
  p_hold_id uuid,
  p_release_reason_category text
)
RETURNS boolean
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $function$
DECLARE
  actor_id uuid := auth.uid();
  selected_hold private.account_deletion_legal_holds%ROWTYPE;
BEGIN
  IF coalesce(auth.jwt() ->> 'role', '') <> 'authenticated'
    OR actor_id IS NULL
    OR NOT private.current_account_is_active()
    OR NOT private.current_user_has_role('owner'::public.app_role)
    OR coalesce(auth.jwt() ->> 'aal', 'aal1') <> 'aal2' THEN
    RAISE EXCEPTION USING ERRCODE = '42501', MESSAGE = 'account_deletion_owner_aal2_required';
  END IF;

  IF p_hold_id IS NULL OR p_release_reason_category IS NULL OR p_release_reason_category NOT IN (
    'authority_expired', 'authority_withdrawn', 'review_cleared', 'other_release'
  ) THEN
    RAISE EXCEPTION USING ERRCODE = '22023', MESSAGE = 'invalid_account_deletion_hold_release';
  END IF;

  SELECT legal_hold.* INTO selected_hold
  FROM private.account_deletion_legal_holds AS legal_hold
  WHERE legal_hold.id = p_hold_id AND legal_hold.released_at IS NULL
  FOR UPDATE;

  IF NOT FOUND THEN RETURN false; END IF;

  UPDATE private.account_deletion_legal_holds
  SET released_by = actor_id,
      released_at = clock_timestamp(),
      release_reason_category = p_release_reason_category
  WHERE id = p_hold_id;

  UPDATE private.account_deletion_requests
  SET status = selected_hold.prior_request_status
  WHERE id = selected_hold.request_id AND status = 'on_hold';

  INSERT INTO private.security_audit_events (
    actor_id, action, target_type, target_id, outcome, reason_category
  )
  VALUES (
    actor_id, 'account_deletion_legal_hold_released',
    'account_deletion_legal_hold', p_hold_id, 'success', p_release_reason_category
  );

  RETURN true;
END;
$function$;

CREATE OR REPLACE FUNCTION public.review_account_deletion_request(
  p_request_id uuid,
  p_decision text,
  p_reason_category text
)
RETURNS text
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $function$
DECLARE
  actor_id uuid := auth.uid();
  selected_request private.account_deletion_requests%ROWTYPE;
  resulting_status text;
BEGIN
  IF coalesce(auth.jwt() ->> 'role', '') <> 'authenticated'
    OR actor_id IS NULL
    OR NOT private.current_account_is_active()
    OR NOT private.current_user_has_role('owner'::public.app_role)
    OR coalesce(auth.jwt() ->> 'aal', 'aal1') <> 'aal2' THEN
    RAISE EXCEPTION USING ERRCODE = '42501', MESSAGE = 'account_deletion_owner_aal2_required';
  END IF;

  IF p_request_id IS NULL OR p_decision IS NULL OR p_decision NOT IN ('approve', 'reject')
    OR p_reason_category IS NULL OR p_reason_category NOT IN (
      'retention_review_complete', 'legal_retention_required',
      'identity_mismatch', 'request_out_of_scope', 'other_review'
    ) THEN
    RAISE EXCEPTION USING ERRCODE = '22023', MESSAGE = 'invalid_account_deletion_review';
  END IF;

  SELECT request.* INTO selected_request
  FROM private.account_deletion_requests AS request
  WHERE request.id = p_request_id
  FOR UPDATE;

  IF NOT FOUND THEN
    RAISE EXCEPTION USING ERRCODE = 'P0001', MESSAGE = 'account_deletion_request_not_reviewable';
  END IF;
  IF EXISTS (
    SELECT 1 FROM private.account_deletion_legal_holds AS legal_hold
    WHERE legal_hold.request_id = p_request_id AND legal_hold.released_at IS NULL
  ) THEN
    RAISE EXCEPTION USING ERRCODE = 'P0001', MESSAGE = 'account_deletion_request_on_legal_hold';
  END IF;
  IF selected_request.status <> 'under_review' THEN
    RAISE EXCEPTION USING ERRCODE = 'P0001', MESSAGE = 'account_deletion_request_not_reviewable';
  END IF;

  resulting_status := CASE WHEN p_decision = 'approve' THEN 'approved' ELSE 'rejected' END;
  UPDATE private.account_deletion_requests
  SET status = resulting_status,
      reviewed_by = actor_id,
      reviewed_at = clock_timestamp(),
      decision_reason_category = p_reason_category
  WHERE id = p_request_id;

  INSERT INTO private.security_audit_events (
    actor_id, action, target_type, target_id, outcome, reason_category
  )
  VALUES (
    actor_id, 'account_deletion_request_reviewed',
    'account_deletion_request', p_request_id, 'success', p_reason_category
  );

  RETURN resulting_status;
END;
$function$;

ALTER FUNCTION private.protect_account_deletion_request() OWNER TO postgres;
ALTER FUNCTION private.protect_account_deletion_legal_hold() OWNER TO postgres;
ALTER FUNCTION public.request_account_deletion(text) OWNER TO postgres;
ALTER FUNCTION public.list_account_deletion_requests() OWNER TO postgres;
ALTER FUNCTION public.place_account_deletion_legal_hold(uuid,text,text,text,timestamptz) OWNER TO postgres;
ALTER FUNCTION public.release_account_deletion_legal_hold(uuid,text) OWNER TO postgres;
ALTER FUNCTION public.review_account_deletion_request(uuid,text,text) OWNER TO postgres;

REVOKE ALL ON FUNCTION private.protect_account_deletion_request() FROM PUBLIC, anon, authenticated;
REVOKE ALL ON FUNCTION private.protect_account_deletion_legal_hold() FROM PUBLIC, anon, authenticated;
REVOKE ALL ON FUNCTION public.request_account_deletion(text) FROM PUBLIC, anon, service_role;
REVOKE ALL ON FUNCTION public.list_account_deletion_requests() FROM PUBLIC, anon, service_role;
REVOKE ALL ON FUNCTION public.place_account_deletion_legal_hold(uuid,text,text,text,timestamptz) FROM PUBLIC, anon, service_role;
REVOKE ALL ON FUNCTION public.release_account_deletion_legal_hold(uuid,text) FROM PUBLIC, anon, service_role;
REVOKE ALL ON FUNCTION public.review_account_deletion_request(uuid,text,text) FROM PUBLIC, anon, service_role;

GRANT EXECUTE ON FUNCTION public.request_account_deletion(text) TO authenticated;
GRANT EXECUTE ON FUNCTION public.list_account_deletion_requests() TO authenticated;
GRANT EXECUTE ON FUNCTION public.place_account_deletion_legal_hold(uuid,text,text,text,timestamptz) TO authenticated;
GRANT EXECUTE ON FUNCTION public.release_account_deletion_legal_hold(uuid,text) TO authenticated;
GRANT EXECUTE ON FUNCTION public.review_account_deletion_request(uuid,text,text) TO authenticated;

COMMENT ON TABLE private.account_deletion_requests IS
'Metadata-only account-deletion request ledger. Self-service requests require an active account and confirmed email. The request is not a deletion operation; approval is a precondition for a later retention-aware execution workflow.';
COMMENT ON TABLE private.account_deletion_legal_holds IS
'Owner AAL2 legal-hold evidence attached to an account-deletion request. Every active hold requires an authority category/reference, a reason summary and a scheduled review date. Hold evidence is immutable and release is audited.';
COMMENT ON FUNCTION public.request_account_deletion(text) IS
'Creates or replays the signed-in user own account-deletion request after active-account and confirmed-email verification. Records the 30-day action target. Does not erase account or learning data.';
