-- Phase 2: server-authoritative advisory attempt timers.
-- The browser may display the timer, but only this database snapshot and
-- database clock determine elapsed/remaining time. Expiry never blocks writes.

ALTER TABLE public.task_versions
  ADD COLUMN time_allowance_seconds integer,
  ADD COLUMN timer_policy_version smallint NOT NULL DEFAULT 1;

ALTER TABLE public.task_versions
  ADD CONSTRAINT task_versions_time_allowance_seconds_check
    CHECK (time_allowance_seconds IS NULL OR time_allowance_seconds BETWEEN 60 AND 43200),
  ADD CONSTRAINT task_versions_timer_policy_version_check
    CHECK (timer_policy_version > 0);

COMMENT ON COLUMN public.task_versions.time_allowance_seconds IS
  'Author-approved advisory allowance for this immutable task version. NULL means untimed. Values are snapshotted at attempt start.';
COMMENT ON COLUMN public.task_versions.timer_policy_version IS
  'Version of the advisory timer rules snapshotted when an attempt begins.';

CREATE TABLE private.attempt_timer_sessions (
  attempt_id uuid PRIMARY KEY,
  learner_id uuid NOT NULL REFERENCES auth.users(id) ON DELETE RESTRICT,
  task_version_id uuid NOT NULL,
  allowance_seconds integer,
  timer_policy_version smallint NOT NULL,
  started_at timestamptz NOT NULL,
  created_at timestamptz NOT NULL DEFAULT clock_timestamp(),
  FOREIGN KEY (attempt_id, task_version_id)
    REFERENCES public.attempts(id, task_version_id) ON DELETE RESTRICT,
  CHECK (allowance_seconds IS NULL OR allowance_seconds BETWEEN 60 AND 43200),
  CHECK (timer_policy_version > 0)
);

CREATE INDEX attempt_timer_sessions_learner_started_idx
  ON private.attempt_timer_sessions (learner_id, started_at DESC);

CREATE TABLE private.attempt_timer_events (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  attempt_id uuid NOT NULL REFERENCES private.attempt_timer_sessions(attempt_id) ON DELETE RESTRICT,
  event_type text NOT NULL
    CHECK (event_type IN ('started', 'response_saved', 'submitted', 'expired', 'adjustment')),
  actor_id uuid NOT NULL REFERENCES auth.users(id) ON DELETE RESTRICT,
  created_at timestamptz NOT NULL DEFAULT clock_timestamp()
);

CREATE INDEX attempt_timer_events_attempt_created_idx
  ON private.attempt_timer_events (attempt_id, created_at, id);

CREATE UNIQUE INDEX attempt_timer_events_one_lifecycle_event_idx
  ON private.attempt_timer_events (attempt_id, event_type)
  WHERE event_type IN ('started', 'submitted', 'expired');

ALTER TABLE private.attempt_timer_sessions ENABLE ROW LEVEL SECURITY;
ALTER TABLE private.attempt_timer_events ENABLE ROW LEVEL SECURITY;
REVOKE ALL ON private.attempt_timer_sessions, private.attempt_timer_events
  FROM PUBLIC, anon, authenticated, service_role;

CREATE OR REPLACE FUNCTION private.prevent_attempt_timer_history_mutation()
RETURNS trigger
LANGUAGE plpgsql
SET search_path = ''
AS $function$
BEGIN
  RAISE EXCEPTION USING ERRCODE = '42501', MESSAGE = 'attempt_timer_history_immutable';
END;
$function$;

CREATE TRIGGER attempt_timer_sessions_immutable
  BEFORE UPDATE OR DELETE ON private.attempt_timer_sessions
  FOR EACH ROW EXECUTE FUNCTION private.prevent_attempt_timer_history_mutation();

CREATE TRIGGER attempt_timer_events_immutable
  BEFORE UPDATE OR DELETE ON private.attempt_timer_events
  FOR EACH ROW EXECUTE FUNCTION private.prevent_attempt_timer_history_mutation();

CREATE OR REPLACE FUNCTION private.record_attempt_timer_start()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $function$
DECLARE
  selected_allowance integer;
  selected_policy smallint;
BEGIN
  SELECT task_version.time_allowance_seconds, task_version.timer_policy_version
    INTO selected_allowance, selected_policy
  FROM public.task_versions AS task_version
  WHERE task_version.id = NEW.task_version_id;

  IF NOT FOUND THEN
    RAISE EXCEPTION USING ERRCODE = '23503', MESSAGE = 'attempt_timer_task_version_missing';
  END IF;

  INSERT INTO private.attempt_timer_sessions (
    attempt_id, learner_id, task_version_id, allowance_seconds,
    timer_policy_version, started_at
  )
  VALUES (
    NEW.id, NEW.learner_id, NEW.task_version_id, selected_allowance,
    selected_policy, NEW.started_at
  );

  INSERT INTO private.attempt_timer_events (attempt_id, event_type, actor_id)
  VALUES (NEW.id, 'started', NEW.learner_id)
  ON CONFLICT DO NOTHING;

  RETURN NEW;
END;
$function$;

CREATE TRIGGER attempts_record_timer_start
  AFTER INSERT ON public.attempts
  FOR EACH ROW EXECUTE FUNCTION private.record_attempt_timer_start();

CREATE OR REPLACE FUNCTION private.record_attempt_timer_response_saved()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $function$
DECLARE
  selected_learner uuid;
  selected_actor uuid;
BEGIN
  SELECT attempt.learner_id
    INTO selected_learner
  FROM public.attempts AS attempt
  WHERE attempt.id = NEW.attempt_id;

  selected_actor := coalesce(auth.uid(), selected_learner);
  IF selected_learner IS NULL OR selected_actor IS NULL THEN
    RAISE EXCEPTION USING ERRCODE = '23502', MESSAGE = 'attempt_timer_event_actor_missing';
  END IF;

  INSERT INTO private.attempt_timer_events (attempt_id, event_type, actor_id)
  VALUES (NEW.attempt_id, 'response_saved', selected_actor);

  RETURN NEW;
END;
$function$;

CREATE TRIGGER attempt_responses_record_timer_save
  AFTER INSERT OR UPDATE OF response_text ON public.attempt_responses
  FOR EACH ROW EXECUTE FUNCTION private.record_attempt_timer_response_saved();

CREATE OR REPLACE FUNCTION private.record_attempt_timer_submission()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $function$
DECLARE
  selected_session private.attempt_timer_sessions%ROWTYPE;
  selected_actor uuid;
BEGIN
  IF OLD.status IS DISTINCT FROM 'submitted' AND NEW.status = 'submitted' THEN
    SELECT timer_session.*
      INTO selected_session
    FROM private.attempt_timer_sessions AS timer_session
    WHERE timer_session.attempt_id = NEW.id;

    IF NOT FOUND THEN
      RAISE EXCEPTION USING ERRCODE = '23503', MESSAGE = 'attempt_timer_session_missing';
    END IF;

    selected_actor := coalesce(auth.uid(), NEW.learner_id);

    IF selected_session.allowance_seconds IS NOT NULL
      AND NEW.submitted_at >= selected_session.started_at
        + make_interval(secs => selected_session.allowance_seconds) THEN
      INSERT INTO private.attempt_timer_events (attempt_id, event_type, actor_id)
      VALUES (NEW.id, 'expired', selected_actor)
      ON CONFLICT DO NOTHING;
    END IF;

    INSERT INTO private.attempt_timer_events (attempt_id, event_type, actor_id)
    VALUES (NEW.id, 'submitted', selected_actor)
    ON CONFLICT DO NOTHING;
  END IF;

  RETURN NEW;
END;
$function$;

CREATE TRIGGER attempts_record_timer_submission
  AFTER UPDATE OF status ON public.attempts
  FOR EACH ROW EXECUTE FUNCTION private.record_attempt_timer_submission();

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
  IF actor_id IS NULL
    OR NOT private.current_account_is_active()
    OR NOT private.current_user_has_role('student'::public.app_role) THEN
    RAISE EXCEPTION USING ERRCODE = '42501', MESSAGE = 'attempt_timer_forbidden';
  END IF;

  SELECT attempt.status, attempt.submitted_at,
         timer_session.allowance_seconds, timer_session.timer_policy_version,
         timer_session.started_at
    INTO selected_status, selected_submitted_at,
         selected_allowance, selected_policy, selected_started_at
  FROM public.attempts AS attempt
  JOIN private.attempt_timer_sessions AS timer_session
    ON timer_session.attempt_id = attempt.id
  WHERE attempt.id = p_attempt_id
    AND attempt.learner_id = actor_id;

  IF NOT FOUND THEN
    RAISE EXCEPTION USING ERRCODE = 'P0002', MESSAGE = 'attempt_not_found';
  END IF;

  server_time := clock_timestamp();
  calculated_deadline := CASE
    WHEN selected_allowance IS NULL THEN NULL
    ELSE selected_started_at + make_interval(secs => selected_allowance)
  END;
  calculated_expired := calculated_deadline IS NOT NULL
    AND server_time >= calculated_deadline;
  calculated_elapsed := floor(greatest(
    0::numeric, extract(epoch FROM (server_time - selected_started_at))
  ))::integer;
  calculated_remaining := CASE
    WHEN calculated_deadline IS NULL THEN NULL
    ELSE greatest(0, ceil(extract(epoch FROM (calculated_deadline - server_time)))::integer)
  END;

  IF calculated_expired THEN
    INSERT INTO private.attempt_timer_events (attempt_id, event_type, actor_id)
    VALUES (p_attempt_id, 'expired', actor_id)
    ON CONFLICT DO NOTHING;
  END IF;

  RETURN QUERY SELECT
    p_attempt_id,
    selected_allowance,
    selected_policy,
    selected_started_at,
    calculated_deadline,
    server_time,
    calculated_elapsed,
    calculated_remaining,
    calculated_expired,
    selected_status,
    selected_submitted_at;
END;
$function$;

ALTER FUNCTION public.get_learner_attempt_timer(uuid) OWNER TO postgres;
REVOKE ALL ON FUNCTION public.get_learner_attempt_timer(uuid)
  FROM PUBLIC, anon, service_role;
GRANT EXECUTE ON FUNCTION public.get_learner_attempt_timer(uuid)
  TO authenticated;

REVOKE ALL ON FUNCTION private.prevent_attempt_timer_history_mutation()
  FROM PUBLIC, anon, authenticated, service_role;
REVOKE ALL ON FUNCTION private.record_attempt_timer_start()
  FROM PUBLIC, anon, authenticated, service_role;
REVOKE ALL ON FUNCTION private.record_attempt_timer_response_saved()
  FROM PUBLIC, anon, authenticated, service_role;
REVOKE ALL ON FUNCTION private.record_attempt_timer_submission()
  FROM PUBLIC, anon, authenticated, service_role;

COMMENT ON TABLE private.attempt_timer_sessions IS
  'Immutable server-created snapshot of a task-version timer allowance and policy at attempt start. NULL allowance means untimed.';
COMMENT ON TABLE private.attempt_timer_events IS
  'Append-only minimal timing events only: lifecycle/save event type, actor and server timestamp. Never stores response text, keystrokes or attention signals.';
COMMENT ON FUNCTION public.get_learner_attempt_timer(uuid) IS
  'Learner-self-only timer read. Uses the database clock, records expiry once, and never changes attempt state or blocks response saves/submission.';
