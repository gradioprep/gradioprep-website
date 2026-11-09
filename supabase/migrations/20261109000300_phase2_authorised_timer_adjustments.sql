-- Phase 2: authorised timer extensions and untimed accommodations.
-- Changes are append-only events; the original timer-session snapshot is never rewritten.
ALTER TABLE private.attempt_timer_events
  ADD COLUMN adjustment_seconds integer,
  ADD COLUMN adjusted_allowance_seconds integer,
  ADD COLUMN accommodation_mode text
    CHECK (accommodation_mode IS NULL OR accommodation_mode IN ('extended', 'untimed')),
  ADD COLUMN reason_category text,
  ADD COLUMN authorised_by uuid REFERENCES auth.users(id) ON DELETE RESTRICT;

ALTER TABLE private.attempt_timer_events
  ADD CONSTRAINT attempt_timer_adjustment_shape_check CHECK (
    (event_type <> 'adjustment'
      AND adjustment_seconds IS NULL
      AND adjusted_allowance_seconds IS NULL
      AND accommodation_mode IS NULL
      AND reason_category IS NULL
      AND authorised_by IS NULL)
    OR
    (event_type = 'adjustment'
      AND adjustment_seconds IS NULL
      AND adjusted_allowance_seconds IS NULL
      AND accommodation_mode = 'untimed'
      AND reason_category IS NOT NULL
      AND authorised_by = actor_id)
    OR
    (event_type = 'adjustment'
      AND adjustment_seconds BETWEEN 60 AND 43200
      AND adjusted_allowance_seconds BETWEEN 60 AND 86400
      AND accommodation_mode = 'extended'
      AND reason_category IS NOT NULL
      AND authorised_by = actor_id)
  );

COMMENT ON COLUMN private.attempt_timer_events.reason_category IS
  'Fixed allow-listed reason category only. Never store a diagnosis or free-text explanation in the timer event.';
COMMENT ON COLUMN private.attempt_timer_events.accommodation_mode IS
  'Authorised adjustment mode. Untimed means no countdown deadline; extended means the allowance was increased.';
COMMENT ON COLUMN private.attempt_timer_events.adjusted_allowance_seconds IS
  'Server-derived effective allowance after this adjustment. NULL for an authorised untimed accommodation.';

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

  IF p_mode NOT IN ('extended', 'untimed')
    OR p_reason_category NOT IN ('accessibility_accommodation', 'approved_extension', 'verified_platform_outage')
    OR (p_mode = 'extended' AND (p_extension_seconds IS NULL OR p_extension_seconds NOT BETWEEN 60 AND 43200))
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

CREATE OR REPLACE FUNCTION public.get_learner_attempt_timer(p_attempt_id uuid)
RETURNS TABLE (
  attempt_id uuid,
  allowance_seconds integer,
  timer_policy_version smallint,
  started_at timestamptz,
  deadline_at timestamptz,
  server_now timestamptz,
  elapsed_seconds integer,
  remaining_seconds integer,
  is_expired boolean,
  attempt_status text,
  submitted_at timestamptz
)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $function$
DECLARE
  actor_id uuid := auth.uid();
  selected_status text;
  selected_submitted_at timestamptz;
  selected_allowance integer;
  selected_policy smallint;
  selected_started_at timestamptz;
  server_time timestamptz;
  calculated_deadline timestamptz;
  calculated_expired boolean;
  calculated_elapsed integer;
  calculated_remaining integer;
BEGIN
  IF actor_id IS NULL OR NOT private.current_account_is_active()
    OR NOT private.current_user_has_role('student'::public.app_role) THEN
    RAISE EXCEPTION USING ERRCODE = '42501', MESSAGE = 'attempt_timer_forbidden';
  END IF;

  SELECT attempt.status, attempt.submitted_at,
         timer_session.allowance_seconds, timer_session.timer_policy_version,
         timer_session.started_at
    INTO selected_status, selected_submitted_at,
         selected_allowance, selected_policy, selected_started_at
  FROM public.attempts AS attempt
  JOIN private.attempt_timer_sessions AS timer_session ON timer_session.attempt_id = attempt.id
  WHERE attempt.id = p_attempt_id AND attempt.learner_id = actor_id;

  IF NOT FOUND THEN
    RAISE EXCEPTION USING ERRCODE = 'P0002', MESSAGE = 'attempt_not_found';
  END IF;

  SELECT adjustment.adjusted_allowance_seconds
    INTO selected_allowance
  FROM private.attempt_timer_events AS adjustment
  WHERE adjustment.attempt_id = p_attempt_id AND adjustment.event_type = 'adjustment'
  ORDER BY adjustment.created_at DESC, adjustment.id DESC
  LIMIT 1;
  IF NOT FOUND THEN
    SELECT timer_session.allowance_seconds INTO selected_allowance
    FROM private.attempt_timer_sessions AS timer_session
    WHERE timer_session.attempt_id = p_attempt_id;
  END IF;

  server_time := clock_timestamp();
  calculated_deadline := CASE WHEN selected_allowance IS NULL THEN NULL
    ELSE selected_started_at + make_interval(secs => selected_allowance) END;
  calculated_expired := calculated_deadline IS NOT NULL AND server_time >= calculated_deadline;
  calculated_elapsed := floor(greatest(0::numeric, extract(epoch FROM (server_time - selected_started_at))))::integer;
  calculated_remaining := CASE WHEN calculated_deadline IS NULL THEN NULL
    ELSE greatest(0, ceil(extract(epoch FROM (calculated_deadline - server_time)))::integer) END;

  IF calculated_expired THEN
    INSERT INTO private.attempt_timer_events (attempt_id, event_type, actor_id)
    VALUES (p_attempt_id, 'expired', actor_id) ON CONFLICT DO NOTHING;
  END IF;

  RETURN QUERY SELECT p_attempt_id, selected_allowance, selected_policy,
    selected_started_at, calculated_deadline, server_time, calculated_elapsed,
    calculated_remaining, calculated_expired, selected_status, selected_submitted_at;
END;
$function$;

ALTER FUNCTION public.get_learner_attempt_timer(uuid) OWNER TO postgres;
REVOKE ALL ON FUNCTION public.get_learner_attempt_timer(uuid) FROM PUBLIC, anon, service_role;
GRANT EXECUTE ON FUNCTION public.get_learner_attempt_timer(uuid) TO authenticated;

COMMENT ON FUNCTION public.authorise_attempt_timer_adjustment(uuid,text,integer,text) IS
'Owner, Admin or currently assigned Grader AAL2 operation. Appends an immutable, allow-listed extension/untimed event and metadata-only audit record; never stores diagnosis or free text.';
