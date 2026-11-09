-- Phase 2: fail closed for NULL adjustment fields when the RPC is called directly.
CREATE OR REPLACE FUNCTION public.authorise_attempt_timer_adjustment(
  p_attempt_id uuid,
  p_mode text,
  p_extension_seconds integer DEFAULT NULL,
  p_reason_category text DEFAULT NULL
)
RETURNS TABLE (
  attempt_id uuid,
  accommodation_mode text,
  effective_allowance_seconds integer,
  adjusted_at timestamptz
)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $function$
DECLARE
  actor_id uuid := auth.uid();
  selected_attempt public.attempts%ROWTYPE;
  selected_session private.attempt_timer_sessions%ROWTYPE;
  selected_allowance integer;
  adjustment_time timestamptz := clock_timestamp();
BEGIN
  IF actor_id IS NULL OR NOT private.current_account_is_active()
    OR coalesce(auth.jwt() ->> 'aal', 'aal1') <> 'aal2'
    OR NOT (
      private.current_user_has_role('owner'::public.app_role)
      OR private.current_user_has_role('admin'::public.app_role)
      OR (
        private.current_user_has_role('grader'::public.app_role)
        AND EXISTS (
          SELECT 1 FROM public.grader_assignments AS assignment
          WHERE assignment.attempt_id = p_attempt_id
            AND assignment.grader_user_id = actor_id
            AND assignment.revoked_at IS NULL
        )
      )
    ) THEN
    RAISE EXCEPTION USING ERRCODE = '42501', MESSAGE = 'attempt_timer_adjustment_forbidden';
  END IF;

  -- Explicit NULL checks are required: SQL three-valued logic must never let
  -- a NULL mode or reason slip through an IF predicate that evaluates NULL.
  IF p_attempt_id IS NULL OR p_mode IS NULL OR p_reason_category IS NULL
    OR p_mode NOT IN ('extended', 'untimed')
    OR p_reason_category NOT IN (
      'accessibility_accommodation', 'approved_extension', 'verified_platform_outage'
    )
    OR (p_mode = 'extended' AND (
      p_extension_seconds IS NULL OR p_extension_seconds NOT BETWEEN 60 AND 43200
    ))
    OR (p_mode = 'untimed' AND p_extension_seconds IS NOT NULL) THEN
    RAISE EXCEPTION USING ERRCODE = '22023', MESSAGE = 'invalid_attempt_timer_adjustment';
  END IF;

  SELECT attempt.* INTO selected_attempt
  FROM public.attempts AS attempt
  WHERE attempt.id = p_attempt_id
  FOR UPDATE;

  IF NOT FOUND OR selected_attempt.status <> 'in_progress' THEN
    RAISE EXCEPTION USING ERRCODE = 'P0001', MESSAGE = 'attempt_not_adjustable';
  END IF;

  SELECT timer_session.* INTO selected_session
  FROM private.attempt_timer_sessions AS timer_session
  WHERE timer_session.attempt_id = p_attempt_id
  FOR UPDATE;

  IF NOT FOUND THEN
    RAISE EXCEPTION USING ERRCODE = 'P0002', MESSAGE = 'attempt_timer_session_missing';
  END IF;

  SELECT adjustment.adjusted_allowance_seconds
  INTO selected_allowance
  FROM private.attempt_timer_events AS adjustment
  WHERE adjustment.attempt_id = p_attempt_id
    AND adjustment.event_type = 'adjustment'
  ORDER BY adjustment.created_at DESC, adjustment.id DESC
  LIMIT 1;

  IF NOT FOUND THEN
    selected_allowance := selected_session.allowance_seconds;
  END IF;

  IF p_mode = 'extended' THEN
    IF selected_allowance IS NULL OR selected_allowance + p_extension_seconds > 86400 THEN
      RAISE EXCEPTION USING ERRCODE = '22023', MESSAGE = 'attempt_timer_extension_out_of_range';
    END IF;
    selected_allowance := selected_allowance + p_extension_seconds;
  ELSE
    selected_allowance := NULL;
  END IF;

  INSERT INTO private.attempt_timer_events (
    attempt_id, event_type, actor_id, adjustment_seconds,
    adjusted_allowance_seconds, accommodation_mode, reason_category, authorised_by,
    created_at
  )
  VALUES (
    p_attempt_id, 'adjustment', actor_id, p_extension_seconds,
    selected_allowance, p_mode, p_reason_category, actor_id, adjustment_time
  );

  INSERT INTO private.security_audit_events (
    actor_id, action, target_type, target_id, outcome, reason_category
  )
  VALUES (
    actor_id, 'attempt_timer_adjusted', 'attempt', p_attempt_id,
    'success', p_reason_category
  );

  RETURN QUERY SELECT p_attempt_id, p_mode, selected_allowance, adjustment_time;
END;
$function$;

ALTER FUNCTION public.authorise_attempt_timer_adjustment(uuid,text,integer,text) OWNER TO postgres;
REVOKE ALL ON FUNCTION public.authorise_attempt_timer_adjustment(uuid,text,integer,text)
  FROM PUBLIC, anon, service_role;
GRANT EXECUTE ON FUNCTION public.authorise_attempt_timer_adjustment(uuid,text,integer,text)
  TO authenticated;
