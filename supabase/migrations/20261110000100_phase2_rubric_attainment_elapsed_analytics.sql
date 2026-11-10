-- Phase 2: immutable rubric-bound attainment and server-derived elapsed response analytics.
-- Derive only after a human-published assessment version and its criterion snapshots
-- have been committed. Never read or persist private grader drafts.

CREATE TABLE private.assessment_response_analytics (
  assessment_version_id uuid PRIMARY KEY
    REFERENCES public.assessment_versions(id) ON DELETE CASCADE,
  submission_id uuid NOT NULL,
  timed_attempt_assessment_link_id uuid
    REFERENCES private.timed_attempt_assessment_links(id) ON DELETE CASCADE,
  attempt_id uuid,
  learner_id uuid NOT NULL,
  task_version_id uuid NOT NULL,
  rubric_version_id uuid NOT NULL,
  assessment_version_number integer NOT NULL CHECK (assessment_version_number > 0),
  response_mode text NOT NULL CHECK (response_mode IN ('typed', 'typed_pdf', 'pdf_only')),
  score_awarded numeric(9,2) NOT NULL CHECK (score_awarded >= 0),
  score_max numeric(9,2) NOT NULL CHECK (score_max > 0 AND score_awarded <= score_max),
  attainment_percent numeric(6,3),
  attainment_status text NOT NULL CHECK (attainment_status IN (
    'valid', 'rubric_version_mismatch', 'incomplete_criteria',
    'invalid_denominator', 'score_snapshot_mismatch'
  )),
  criterion_count integer NOT NULL CHECK (criterion_count >= 0),
  expected_criterion_count integer NOT NULL CHECK (expected_criterion_count >= 0),
  criterion_score_snapshot jsonb NOT NULL CHECK (jsonb_typeof(criterion_score_snapshot) = 'array'),
  elapsed_response_seconds bigint,
  elapsed_response_status text NOT NULL CHECK (elapsed_response_status IN (
    'valid', 'not_linked', 'missing_timer_session', 'missing_submitted_event',
    'invalid_clock_range', 'identity_mismatch'
  )),
  timer_mode text NOT NULL CHECK (timer_mode IN ('timed', 'untimed', 'not_linked', 'missing', 'invalid')),
  accommodation_mode text NOT NULL CHECK (accommodation_mode IN (
    'none', 'extended', 'untimed', 'not_linked', 'unknown'
  )),
  timer_policy_version smallint,
  base_allowance_seconds integer,
  effective_allowance_seconds integer,
  adjustment_count integer NOT NULL DEFAULT 0 CHECK (adjustment_count >= 0),
  comparison_group_key text,
  comparability_status text NOT NULL CHECK (comparability_status IN (
    'eligible', 'excluded_attainment', 'excluded_unlinked', 'excluded_timing'
  )),
  derived_at timestamptz NOT NULL DEFAULT clock_timestamp(),
  CHECK (
    (timed_attempt_assessment_link_id IS NULL AND attempt_id IS NULL)
    OR (timed_attempt_assessment_link_id IS NOT NULL AND attempt_id IS NOT NULL)
  ),
  CHECK (
    (attainment_status = 'valid' AND attainment_percent BETWEEN 0 AND 100)
    OR (attainment_status <> 'valid' AND attainment_percent IS NULL)
  ),
  CHECK (
    (elapsed_response_status = 'valid' AND elapsed_response_seconds IS NOT NULL
      AND elapsed_response_seconds >= 0)
    OR (elapsed_response_status <> 'valid' AND elapsed_response_seconds IS NULL)
  ),
  CHECK (
    (comparability_status = 'eligible' AND comparison_group_key IS NOT NULL
      AND attainment_status = 'valid' AND elapsed_response_status = 'valid')
    OR (comparability_status <> 'eligible' AND comparison_group_key IS NULL)
  )
);

CREATE INDEX assessment_response_analytics_submission_idx
  ON private.assessment_response_analytics (submission_id, assessment_version_number DESC);
CREATE INDEX assessment_response_analytics_comparison_idx
  ON private.assessment_response_analytics (comparison_group_key)
  WHERE comparability_status = 'eligible';

COMMENT ON TABLE private.assessment_response_analytics IS
  'Private immutable derivation from a published human assessment version and, when linked, its server timer history. Contains score snapshots and timing metadata only; never response text, grader drafts, diagnosis, attention signals, or public ranks.';
COMMENT ON COLUMN private.assessment_response_analytics.elapsed_response_seconds IS
  'Floor of server-recorded timer-session start to submitted attempt timestamp. PDF upload, accepted-file, transcript creation and OCR processing times are deliberately excluded.';
COMMENT ON COLUMN private.assessment_response_analytics.comparison_group_key IS
  'Exact-context grouping key: task version, rubric version, response mode, timer policy, timed/untimed mode, accommodation mode and effective allowance. It is not a rank or a statement of cross-context equivalence.';

ALTER TABLE private.assessment_response_analytics ENABLE ROW LEVEL SECURITY;
REVOKE ALL ON private.assessment_response_analytics
  FROM PUBLIC, anon, authenticated, service_role;

CREATE OR REPLACE FUNCTION private.prevent_assessment_response_analytics_mutation()
RETURNS trigger
LANGUAGE plpgsql
SET search_path = ''
AS $function$
BEGIN
  IF TG_OP = 'DELETE' AND pg_catalog.pg_trigger_depth() > 1 THEN
    RETURN OLD;
  END IF;
  RAISE EXCEPTION USING ERRCODE = '42501', MESSAGE = 'assessment_response_analytics_immutable';
END;
$function$;

CREATE TRIGGER assessment_response_analytics_immutable
  BEFORE UPDATE OR DELETE ON private.assessment_response_analytics
  FOR EACH ROW EXECUTE FUNCTION private.prevent_assessment_response_analytics_mutation();

CREATE OR REPLACE FUNCTION private.derive_assessment_response_analytics()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $function$
DECLARE
  selected_submission public.assessment_submissions%ROWTYPE;
  selected_attempt public.attempts%ROWTYPE;
  selected_timer_session private.attempt_timer_sessions%ROWTYPE;
  selected_adjustment private.attempt_timer_events%ROWTYPE;
  selected_link private.timed_attempt_assessment_links%ROWTYPE;
  expected_criteria integer := 0;
  actual_criteria integer := 0;
  distinct_criteria integer := 0;
  rubric_criteria_matched integer := 0;
  criterion_snapshots_matched integer := 0;
  criteria_score numeric(9,2) := 0;
  criteria_max numeric(9,2) := 0;
  criteria_snapshot jsonb := '[]'::jsonb;
  attainment_state text;
  attainment_value numeric(6,3);
  timer_state text := 'not_linked';
  accommodation_state text := 'not_linked';
  elapsed_state text := 'not_linked';
  elapsed_value bigint;
  base_allowance integer;
  effective_allowance integer;
  policy_version smallint;
  adjustment_total integer := 0;
  comparison_key text;
  comparison_state text;
BEGIN
  SELECT submission.* INTO selected_submission
  FROM public.assessment_submissions AS submission
  WHERE submission.id = NEW.submission_id;

  IF NOT FOUND OR selected_submission.status <> 'feedback_published'
    OR NEW.rubric_version_id IS DISTINCT FROM selected_submission.rubric_version_id THEN
    attainment_state := 'rubric_version_mismatch';
  ELSE
    SELECT count(*)::integer INTO expected_criteria
    FROM public.rubric_criteria AS criterion
    WHERE criterion.rubric_version_id = NEW.rubric_version_id;

    SELECT
      count(*)::integer,
      count(DISTINCT result.rubric_criterion_id)::integer,
      count(*) FILTER (WHERE criterion.id IS NOT NULL)::integer,
      count(*) FILTER (
        WHERE criterion.id IS NOT NULL
          AND result.max_points_snapshot = criterion.max_points
          AND result.criterion_code_snapshot = criterion.criterion_code
          AND result.criterion_title_snapshot = criterion.title
          AND result.descriptor_snapshot = criterion.descriptor
      )::integer,
      coalesce(sum(result.points_awarded), 0)::numeric(9,2),
      coalesce(sum(result.max_points_snapshot), 0)::numeric(9,2),
      coalesce(
        jsonb_agg(jsonb_build_object(
          'criterion_result_id', result.id,
          'rubric_criterion_id', result.rubric_criterion_id,
          'criterion_code', result.criterion_code_snapshot,
          'criterion_title', result.criterion_title_snapshot,
          'points_awarded', result.points_awarded,
          'max_points', result.max_points_snapshot
        ) ORDER BY result.criterion_code_snapshot),
        '[]'::jsonb
      )
    INTO actual_criteria, distinct_criteria, rubric_criteria_matched,
      criterion_snapshots_matched, criteria_score, criteria_max, criteria_snapshot
    FROM public.criterion_results AS result
    LEFT JOIN public.rubric_criteria AS criterion
      ON criterion.id = result.rubric_criterion_id
     AND criterion.rubric_version_id = NEW.rubric_version_id
    WHERE result.assessment_version_id = NEW.id;

    IF expected_criteria = 0 OR actual_criteria <> expected_criteria
      OR distinct_criteria <> expected_criteria
      OR rubric_criteria_matched <> actual_criteria THEN
      attainment_state := 'incomplete_criteria';
    ELSIF criterion_snapshots_matched <> actual_criteria THEN
      attainment_state := 'score_snapshot_mismatch';
    ELSIF criteria_max <= 0 OR NEW.max_points <= 0 THEN
      attainment_state := 'invalid_denominator';
    ELSIF criteria_score IS DISTINCT FROM NEW.total_points
      OR criteria_max IS DISTINCT FROM NEW.max_points THEN
      attainment_state := 'score_snapshot_mismatch';
    ELSE
      attainment_state := 'valid';
      attainment_value := round((NEW.total_points / NEW.max_points) * 100, 3)::numeric(6,3);
    END IF;
  END IF;

  IF selected_submission.id IS NULL THEN
    RAISE EXCEPTION USING ERRCODE = '23503', MESSAGE = 'analytics_submission_missing';
  END IF;

  SELECT link.* INTO selected_link
  FROM private.timed_attempt_assessment_links AS link
  WHERE link.assessment_submission_id = selected_submission.id;

  IF FOUND THEN
    IF selected_link.learner_id IS DISTINCT FROM selected_submission.learner_id
      OR selected_link.task_version_id IS DISTINCT FROM selected_submission.task_version_id THEN
      elapsed_state := 'identity_mismatch';
      timer_state := 'invalid';
      accommodation_state := 'unknown';
    ELSE
      SELECT attempt.* INTO selected_attempt
      FROM public.attempts AS attempt
      WHERE attempt.id = selected_link.attempt_id;

      IF NOT FOUND
        OR selected_attempt.learner_id IS DISTINCT FROM selected_submission.learner_id
        OR selected_attempt.task_version_id IS DISTINCT FROM selected_submission.task_version_id THEN
        elapsed_state := 'identity_mismatch';
        timer_state := 'invalid';
        accommodation_state := 'unknown';
      ELSE
        SELECT timer_session.* INTO selected_timer_session
        FROM private.attempt_timer_sessions AS timer_session
        WHERE timer_session.attempt_id = selected_attempt.id;

        IF NOT FOUND THEN
          elapsed_state := 'missing_timer_session';
          timer_state := 'missing';
          accommodation_state := 'unknown';
        ELSE
          base_allowance := selected_timer_session.allowance_seconds;
          effective_allowance := base_allowance;
          policy_version := selected_timer_session.timer_policy_version;

          SELECT count(*)::integer INTO adjustment_total
          FROM private.attempt_timer_events AS event
          WHERE event.attempt_id = selected_attempt.id
            AND event.event_type = 'adjustment';

          IF adjustment_total > 0 THEN
            SELECT event.* INTO selected_adjustment
            FROM private.attempt_timer_events AS event
            WHERE event.attempt_id = selected_attempt.id
              AND event.event_type = 'adjustment'
            ORDER BY event.created_at DESC, event.id DESC
            LIMIT 1;

            effective_allowance := selected_adjustment.adjusted_allowance_seconds;
            accommodation_state := selected_adjustment.accommodation_mode;
          ELSE
            accommodation_state := 'none';
          END IF;

          timer_state := CASE WHEN effective_allowance IS NULL THEN 'untimed' ELSE 'timed' END;

          IF selected_attempt.status <> 'submitted'
            OR selected_attempt.submitted_at IS NULL
            OR NOT EXISTS (
              SELECT 1
              FROM private.attempt_timer_events AS event
              WHERE event.attempt_id = selected_attempt.id
                AND event.event_type = 'submitted'
                AND event.actor_id = selected_submission.learner_id
            ) THEN
            elapsed_state := 'missing_submitted_event';
          ELSIF selected_attempt.submitted_at < selected_timer_session.started_at THEN
            elapsed_state := 'invalid_clock_range';
            timer_state := 'invalid';
          ELSE
            elapsed_state := 'valid';
            elapsed_value := floor(extract(epoch FROM (
              selected_attempt.submitted_at - selected_timer_session.started_at
            )))::bigint;
          END IF;
        END IF;
      END IF;
    END IF;
  END IF;

  IF attainment_state <> 'valid' THEN
    comparison_state := 'excluded_attainment';
  ELSIF elapsed_state = 'not_linked' THEN
    comparison_state := 'excluded_unlinked';
  ELSIF elapsed_state <> 'valid' THEN
    comparison_state := 'excluded_timing';
  ELSE
    comparison_state := 'eligible';
    comparison_key := concat_ws('|',
      selected_submission.task_version_id::text,
      NEW.rubric_version_id::text,
      selected_submission.response_mode,
      policy_version::text,
      timer_state,
      accommodation_state,
      coalesce(base_allowance::text, 'untimed'),
      coalesce(effective_allowance::text, 'untimed')
    );
  END IF;

  INSERT INTO private.assessment_response_analytics (
    assessment_version_id, submission_id, timed_attempt_assessment_link_id,
    attempt_id, learner_id, task_version_id, rubric_version_id,
    assessment_version_number, response_mode,
    score_awarded, score_max, attainment_percent, attainment_status,
    criterion_count, expected_criterion_count, criterion_score_snapshot,
    elapsed_response_seconds, elapsed_response_status, timer_mode,
    accommodation_mode, timer_policy_version, base_allowance_seconds,
    effective_allowance_seconds, adjustment_count, comparison_group_key,
    comparability_status
  )
  VALUES (
    NEW.id, selected_submission.id, selected_link.id, selected_link.attempt_id,
    selected_submission.learner_id, selected_submission.task_version_id,
    NEW.rubric_version_id, NEW.version_number, selected_submission.response_mode,
    NEW.total_points, NEW.max_points, attainment_value, attainment_state,
    actual_criteria, expected_criteria, criteria_snapshot,
    elapsed_value, elapsed_state, timer_state, accommodation_state,
    policy_version, base_allowance, effective_allowance, adjustment_total,
    comparison_key, comparison_state
  );

  RETURN NEW;
END;
$function$;

REVOKE ALL ON FUNCTION private.prevent_assessment_response_analytics_mutation()
  FROM PUBLIC, anon, authenticated, service_role;
REVOKE ALL ON FUNCTION private.derive_assessment_response_analytics()
  FROM PUBLIC, anon, authenticated, service_role;

-- Deferred until transaction commit so all criterion_results inserted by the
-- human publication RPC are present before deriving the snapshot.
CREATE CONSTRAINT TRIGGER assessment_response_analytics_derive_after_publish
  AFTER INSERT ON public.assessment_versions
  DEFERRABLE INITIALLY DEFERRED
  FOR EACH ROW EXECUTE FUNCTION private.derive_assessment_response_analytics();

CREATE OR REPLACE FUNCTION public.get_assigned_assessment_response_analytics(
  p_submission_id uuid
)
RETURNS TABLE (
  assessment_version_id uuid,
  submission_id uuid,
  attempt_id uuid,
  learner_id uuid,
  task_version_id uuid,
  rubric_version_id uuid,
  assessment_version_number integer,
  response_mode text,
  score_awarded numeric,
  score_max numeric,
  attainment_percent numeric,
  attainment_status text,
  criterion_count integer,
  expected_criterion_count integer,
  criterion_score_snapshot jsonb,
  elapsed_response_seconds bigint,
  elapsed_response_status text,
  timer_mode text,
  accommodation_mode text,
  timer_policy_version smallint,
  base_allowance_seconds integer,
  effective_allowance_seconds integer,
  adjustment_count integer,
  comparison_group_key text,
  comparability_status text,
  derived_at timestamptz
)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $function$
DECLARE
  actor_id uuid := auth.uid();
  selected_submission public.assessment_submissions%ROWTYPE;
  selected_analytics private.assessment_response_analytics%ROWTYPE;
BEGIN
  IF actor_id IS NULL OR NOT private.current_account_is_active()
    OR NOT private.current_user_has_role('grader'::public.app_role)
    OR coalesce(auth.jwt() ->> 'aal', 'aal1') <> 'aal2' THEN
    RAISE EXCEPTION USING ERRCODE = '42501', MESSAGE = 'assessment_analytics_forbidden';
  END IF;

  SELECT submission.* INTO selected_submission
  FROM public.assessment_submissions AS submission
  WHERE submission.id = p_submission_id
    AND submission.status = 'feedback_published';

  IF NOT FOUND THEN
    RAISE EXCEPTION USING ERRCODE = 'P0002', MESSAGE = 'published_assessment_analytics_not_found';
  END IF;

  IF NOT EXISTS (
    SELECT 1
    FROM public.submission_grader_assignments AS assignment
    WHERE assignment.submission_id = p_submission_id
      AND assignment.grader_user_id = actor_id
      AND assignment.revoked_at IS NULL
  ) THEN
    RAISE EXCEPTION USING ERRCODE = '42501', MESSAGE = 'assessment_analytics_forbidden';
  END IF;

  SELECT analytics.* INTO selected_analytics
  FROM private.assessment_response_analytics AS analytics
  JOIN public.assessment_versions AS version
    ON version.id = analytics.assessment_version_id
  WHERE analytics.submission_id = p_submission_id
  ORDER BY version.version_number DESC
  LIMIT 1;

  IF NOT FOUND THEN
    RAISE EXCEPTION USING ERRCODE = 'P0002', MESSAGE = 'published_assessment_analytics_not_found';
  END IF;

  RETURN QUERY SELECT
    selected_analytics.assessment_version_id,
    selected_analytics.submission_id,
    selected_analytics.attempt_id,
    selected_analytics.learner_id,
    selected_analytics.task_version_id,
    selected_analytics.rubric_version_id,
    selected_analytics.assessment_version_number,
    selected_analytics.response_mode,
    selected_analytics.score_awarded,
    selected_analytics.score_max,
    selected_analytics.attainment_percent,
    selected_analytics.attainment_status,
    selected_analytics.criterion_count,
    selected_analytics.expected_criterion_count,
    selected_analytics.criterion_score_snapshot,
    selected_analytics.elapsed_response_seconds,
    selected_analytics.elapsed_response_status,
    selected_analytics.timer_mode,
    selected_analytics.accommodation_mode,
    selected_analytics.timer_policy_version,
    selected_analytics.base_allowance_seconds,
    selected_analytics.effective_allowance_seconds,
    selected_analytics.adjustment_count,
    selected_analytics.comparison_group_key,
    selected_analytics.comparability_status,
    selected_analytics.derived_at;
END;
$function$;

ALTER FUNCTION public.get_assigned_assessment_response_analytics(uuid) OWNER TO postgres;
REVOKE ALL ON FUNCTION public.get_assigned_assessment_response_analytics(uuid)
  FROM PUBLIC, anon, service_role;
GRANT EXECUTE ON FUNCTION public.get_assigned_assessment_response_analytics(uuid)
  TO authenticated;

CREATE OR REPLACE FUNCTION public.record_worker_assessment_analytics_read(
  p_actor_id uuid,
  p_submission_id uuid,
  p_assurance text,
  p_outcome text
)
RETURNS TABLE (audit_recorded boolean, access_allowed boolean)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $function$
DECLARE
  allowed boolean;
  event_outcome text;
  event_reason text;
BEGIN
  IF coalesce(auth.jwt() ->> 'role', '') <> 'service_role'
    OR p_actor_id IS NULL
    OR p_submission_id IS NULL
    OR p_assurance IS NULL
    OR p_assurance NOT IN ('aal1', 'aal2')
    OR p_outcome IS NULL
    OR p_outcome NOT IN ('success', 'failed')
    OR NOT EXISTS (SELECT 1 FROM auth.users AS actor WHERE actor.id = p_actor_id) THEN
    RETURN QUERY SELECT false, false;
    RETURN;
  END IF;

  SELECT
    EXISTS (
      SELECT 1 FROM public.profiles AS profile
      WHERE profile.user_id = p_actor_id AND profile.account_status = 'active'
    )
    AND EXISTS (
      SELECT 1 FROM public.role_assignments AS role
      WHERE role.user_id = p_actor_id
        AND role.role = 'grader'::public.app_role
        AND role.revoked_at IS NULL
    )
    AND p_assurance = 'aal2'
    AND EXISTS (
      SELECT 1
      FROM public.assessment_submissions AS submission
      JOIN public.submission_grader_assignments AS assignment
        ON assignment.submission_id = submission.id
      WHERE submission.id = p_submission_id
        AND submission.status = 'feedback_published'
        AND assignment.grader_user_id = p_actor_id
        AND assignment.revoked_at IS NULL
    )
  INTO allowed;

  IF allowed THEN
    event_outcome := p_outcome;
    event_reason := CASE
      WHEN p_outcome = 'failed' THEN 'database_read_failed'
      ELSE 'active_grader_assignment_aal2'
    END;
  ELSE
    event_outcome := 'denied';
    event_reason := CASE
      WHEN NOT EXISTS (
        SELECT 1 FROM public.profiles AS profile
        WHERE profile.user_id = p_actor_id AND profile.account_status = 'active'
      ) THEN 'inactive_account'
      WHEN p_assurance <> 'aal2' THEN 'aal2_required'
      WHEN NOT EXISTS (
        SELECT 1 FROM public.role_assignments AS role
        WHERE role.user_id = p_actor_id
          AND role.role = 'grader'::public.app_role
          AND role.revoked_at IS NULL
      ) THEN 'role_required'
      ELSE 'resource_scope_denied'
    END;
  END IF;

  INSERT INTO private.security_audit_events (
    actor_id, action, target_type, target_id, outcome, reason_category
  )
  VALUES (
    p_actor_id, 'grader_assessment_analytics_read', 'assessment_submission',
    p_submission_id, event_outcome, event_reason
  );

  RETURN QUERY SELECT true, allowed;
END;
$function$;

ALTER FUNCTION public.record_worker_assessment_analytics_read(uuid,uuid,text,text)
  OWNER TO postgres;
REVOKE ALL ON FUNCTION public.record_worker_assessment_analytics_read(uuid,uuid,text,text)
  FROM PUBLIC, anon, authenticated;
GRANT EXECUTE ON FUNCTION public.record_worker_assessment_analytics_read(uuid,uuid,text,text)
  TO service_role;

COMMENT ON FUNCTION public.get_assigned_assessment_response_analytics(uuid) IS
  'Returns only the latest published rubric-bound analytics snapshot to its currently assigned AAL2 Grader. Never returns a draft or unpublished result.';
COMMENT ON FUNCTION public.record_worker_assessment_analytics_read(uuid,uuid,text,text) IS
  'Worker-only metadata audit for assigned Grader analytics reads. Independently rechecks account, role, AAL2, assignment and published-feedback state.';
