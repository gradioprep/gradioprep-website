-- Allow an Owner to pause an executing account-closure retention plan
-- when a legal authority arises after closure has begun. The preceding
-- retention migration already permits 'executing' in prior_request_status;
-- this replaces the earlier RPC guard so the function and constraint agree.

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

  -- A new hold may be placed while a closure request is being executed.
  -- Keep the allow-list explicit so rejected/released/other terminal states
  -- cannot be reopened by a legal-hold operation.
  IF NOT FOUND OR selected_request.status NOT IN ('under_review', 'approved', 'executing') THEN
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

ALTER FUNCTION public.place_account_deletion_legal_hold(uuid,text,text,text,timestamptz) OWNER TO postgres;
REVOKE ALL ON FUNCTION public.place_account_deletion_legal_hold(uuid,text,text,text,timestamptz) FROM PUBLIC, anon, service_role;
GRANT EXECUTE ON FUNCTION public.place_account_deletion_legal_hold(uuid,text,text,text,timestamptz) TO authenticated;
