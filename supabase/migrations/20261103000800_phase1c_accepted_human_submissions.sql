-- Phase 1C-B: accepted typed human-assessment submissions.
-- This is separate from practice attempts. PDF/object storage is deliberately
-- deferred to Phase 1D. Capacity is fail-closed until an operator configures it;
-- local synthetic seed data enables it only in local CI.

CREATE TABLE public.rubrics (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  rubric_code text NOT NULL UNIQUE CHECK (char_length(btrim(rubric_code)) BETWEEN 1 AND 120),
  title text NOT NULL CHECK (char_length(btrim(title)) BETWEEN 1 AND 240),
  created_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE public.rubric_versions (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  rubric_id uuid NOT NULL REFERENCES public.rubrics(id) ON DELETE RESTRICT,
  version integer NOT NULL CHECK (version > 0),
  title text NOT NULL CHECK (char_length(btrim(title)) BETWEEN 1 AND 240),
  release_state text NOT NULL DEFAULT 'draft'
    CHECK (release_state IN ('draft', 'published', 'retired')),
  created_at timestamptz NOT NULL DEFAULT now(),
  UNIQUE (rubric_id, version)
);

CREATE TABLE public.rubric_criteria (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  rubric_version_id uuid NOT NULL REFERENCES public.rubric_versions(id) ON DELETE RESTRICT,
  criterion_code text NOT NULL CHECK (char_length(btrim(criterion_code)) BETWEEN 1 AND 80),
  sequence integer NOT NULL CHECK (sequence > 0),
  title text NOT NULL CHECK (char_length(btrim(title)) BETWEEN 1 AND 200),
  descriptor text NOT NULL CHECK (char_length(btrim(descriptor)) BETWEEN 1 AND 3000),
  max_points numeric(7,2) NOT NULL CHECK (max_points >= 0),
  created_at timestamptz NOT NULL DEFAULT now(),
  UNIQUE (rubric_version_id, criterion_code),
  UNIQUE (rubric_version_id, sequence)
);

CREATE TABLE public.task_rubric_mappings (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  task_version_id uuid NOT NULL UNIQUE
    REFERENCES public.task_versions(id) ON DELETE RESTRICT,
  rubric_version_id uuid NOT NULL
    REFERENCES public.rubric_versions(id) ON DELETE RESTRICT,
  created_at timestamptz NOT NULL DEFAULT now(),
  UNIQUE (task_version_id, rubric_version_id)
);

-- Exactly one singleton capacity record is used to serialize acceptance and
-- prevent concurrent requests from exceeding the configured open-work limit.
-- The migration default is disabled: hosted acceptance remains blocked until
-- capacity is deliberately configured. The local-only seed enables synthetic CI.
CREATE TABLE private.grading_capacity_config (
  singleton boolean PRIMARY KEY DEFAULT true CHECK (singleton),
  enabled boolean NOT NULL DEFAULT false,
  max_open_submissions integer NOT NULL DEFAULT 1
    CHECK (max_open_submissions BETWEEN 1 AND 10000),
  config_version integer NOT NULL DEFAULT 1 CHECK (config_version > 0),
  updated_at timestamptz NOT NULL DEFAULT now()
);

INSERT INTO private.grading_capacity_config (singleton, enabled, max_open_submissions, config_version)
VALUES (true, false, 1, 1)
ON CONFLICT (singleton) DO NOTHING;

CREATE TABLE public.assessment_submissions (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  learner_id uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  task_version_id uuid NOT NULL REFERENCES public.task_versions(id) ON DELETE RESTRICT,
  rubric_version_id uuid NOT NULL REFERENCES public.rubric_versions(id) ON DELETE RESTRICT,
  status text NOT NULL DEFAULT 'queued'
    CHECK (status IN ('queued', 'assigned', 'grading', 'feedback_published', 'closed', 'withdrawn')),
  accepted_at timestamptz NOT NULL,
  grading_due_at timestamptz NOT NULL,
  sla_target_seconds integer NOT NULL DEFAULT 86400 CHECK (sla_target_seconds = 86400),
  capacity_config_version integer NOT NULL CHECK (capacity_config_version > 0),
  capacity_limit_snapshot integer NOT NULL CHECK (capacity_limit_snapshot > 0),
  open_submissions_before_acceptance integer NOT NULL CHECK (open_submissions_before_acceptance >= 0),
  idempotency_key uuid NOT NULL,
  created_at timestamptz NOT NULL DEFAULT now(),
  CHECK (grading_due_at = accepted_at + make_interval(secs => sla_target_seconds)),
  UNIQUE (learner_id, idempotency_key)
);

CREATE INDEX assessment_submissions_queue_idx
  ON public.assessment_submissions (accepted_at ASC, id ASC)
  WHERE status IN ('queued', 'assigned', 'grading');

CREATE INDEX assessment_submissions_learner_idx
  ON public.assessment_submissions (learner_id, accepted_at DESC);

CREATE TABLE public.submission_versions (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  submission_id uuid NOT NULL
    REFERENCES public.assessment_submissions(id) ON DELETE RESTRICT,
  version_number integer NOT NULL CHECK (version_number > 0),
  response_text text NOT NULL CHECK (char_length(response_text) BETWEEN 1 AND 12000),
  word_count integer GENERATED ALWAYS AS (
    CASE
      WHEN btrim(response_text) = '' THEN 0
      ELSE array_length(regexp_split_to_array(btrim(response_text), E'\\s+'), 1)
    END
  ) STORED,
  created_by uuid NOT NULL REFERENCES auth.users(id) ON DELETE RESTRICT,
  created_at timestamptz NOT NULL DEFAULT now(),
  UNIQUE (submission_id, version_number)
);

CREATE INDEX submission_versions_submission_idx
  ON public.submission_versions (submission_id, version_number DESC);

-- The version history is append-only. Corrected or later responses must be
-- represented by a new version through a future protected operation.
CREATE OR REPLACE FUNCTION private.prevent_submission_version_mutation()
RETURNS trigger
LANGUAGE plpgsql
SET search_path = ''
AS $$
BEGIN
  RAISE EXCEPTION USING ERRCODE = '42501', MESSAGE = 'submission_version_immutable';
END;
$$;

CREATE TRIGGER submission_versions_immutable
  BEFORE UPDATE OR DELETE ON public.submission_versions
  FOR EACH ROW EXECUTE FUNCTION private.prevent_submission_version_mutation();

CREATE OR REPLACE FUNCTION private.can_read_assessment_submission(target_submission_id uuid)
RETURNS boolean
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = ''
AS $$
  SELECT EXISTS (
    SELECT 1
    FROM public.assessment_submissions AS submission
    WHERE submission.id = target_submission_id
      AND private.current_account_is_active()
      AND (
        (
          submission.learner_id = (SELECT auth.uid())
          AND private.current_user_has_role('student'::public.app_role)
        )
        OR (
          private.current_user_has_role('guardian'::public.app_role)
          AND private.can_view_learner(submission.learner_id, 'submissions')
        )
        OR (
          private.current_user_has_role('owner'::public.app_role)
          AND coalesce(auth.jwt() ->> 'aal', 'aal1') = 'aal2'
        )
      )
  );
$$;

CREATE OR REPLACE FUNCTION private.can_read_rubric_version(target_rubric_version_id uuid)
RETURNS boolean
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = ''
AS $$
  SELECT EXISTS (
    SELECT 1
    FROM public.rubric_versions AS version
    WHERE version.id = target_rubric_version_id
      AND private.current_account_is_active()
      AND private.current_user_has_role('owner'::public.app_role)
      AND coalesce(auth.jwt() ->> 'aal', 'aal1') = 'aal2'
  );
$$;

REVOKE ALL ON FUNCTION private.can_read_assessment_submission(uuid) FROM PUBLIC, anon, authenticated;
REVOKE ALL ON FUNCTION private.can_read_rubric_version(uuid) FROM PUBLIC, anon, authenticated;
GRANT EXECUTE ON FUNCTION private.can_read_assessment_submission(uuid) TO authenticated;
GRANT EXECUTE ON FUNCTION private.can_read_rubric_version(uuid) TO authenticated;

-- All new tables containing assessment, learner or rubric information use RLS.
ALTER TABLE public.rubrics ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.rubric_versions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.rubric_criteria ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.task_rubric_mappings ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.assessment_submissions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.submission_versions ENABLE ROW LEVEL SECURITY;
ALTER TABLE private.grading_capacity_config ENABLE ROW LEVEL SECURITY;

REVOKE ALL ON public.rubrics, public.rubric_versions, public.rubric_criteria,
  public.task_rubric_mappings, public.assessment_submissions, public.submission_versions
  FROM PUBLIC, anon, authenticated;
REVOKE ALL ON private.grading_capacity_config FROM PUBLIC, anon, authenticated;

GRANT SELECT ON public.rubrics, public.rubric_versions, public.rubric_criteria,
  public.task_rubric_mappings, public.assessment_submissions, public.submission_versions
  TO authenticated;

-- Rubric material is withheld until a staff workflow grants a specific,
-- authorised grader access in a later Phase 1C slice. For now, owner+AAL2 only.
CREATE POLICY rubrics_select_owner_aal2
  ON public.rubrics FOR SELECT TO authenticated
  USING (
    private.current_account_is_active()
    AND private.current_user_has_role('owner'::public.app_role)
    AND coalesce(auth.jwt() ->> 'aal', 'aal1') = 'aal2'
  );

CREATE POLICY rubric_versions_select_owner_aal2
  ON public.rubric_versions FOR SELECT TO authenticated
  USING (private.can_read_rubric_version(id));

CREATE POLICY rubric_criteria_select_owner_aal2
  ON public.rubric_criteria FOR SELECT TO authenticated
  USING (private.can_read_rubric_version(rubric_version_id));

CREATE POLICY task_rubric_mappings_select_owner_aal2
  ON public.task_rubric_mappings FOR SELECT TO authenticated
  USING (
    private.current_account_is_active()
    AND private.current_user_has_role('owner'::public.app_role)
    AND coalesce(auth.jwt() ->> 'aal', 'aal1') = 'aal2'
  );

CREATE POLICY assessment_submissions_select_authorized_scope
  ON public.assessment_submissions FOR SELECT TO authenticated
  USING (private.can_read_assessment_submission(id));

CREATE POLICY submission_versions_select_authorized_scope
  ON public.submission_versions FOR SELECT TO authenticated
  USING (private.can_read_assessment_submission(submission_id));

-- No direct INSERT/UPDATE/DELETE grants or policies exist. The only acceptance
-- path is the transaction below; actor, immutable version links, accepted time,
-- due time, SLA and capacity snapshots are server-controlled.
CREATE OR REPLACE FUNCTION public.accept_assessment_submission(
  p_task_version_id uuid,
  p_idempotency_key uuid,
  p_response_text text
)
RETURNS TABLE (
  submission_id uuid,
  learner_id uuid,
  task_version_id uuid,
  rubric_version_id uuid,
  status text,
  accepted_at timestamptz,
  grading_due_at timestamptz,
  sla_target_seconds integer,
  capacity_limit_snapshot integer,
  open_submissions_before_acceptance integer,
  is_replay boolean
)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
DECLARE
  actor_id uuid := auth.uid();
  selected_pathway_id text;
  selected_rubric_version_id uuid;
  capacity private.grading_capacity_config%ROWTYPE;
  existing_submission public.assessment_submissions%ROWTYPE;
  existing_response text;
  created_submission public.assessment_submissions%ROWTYPE;
  open_count integer;
  accepted_time timestamptz;
BEGIN
  IF actor_id IS NULL
    OR NOT private.current_account_is_active()
    OR NOT private.current_user_has_role('student'::public.app_role) THEN
    RAISE EXCEPTION USING ERRCODE = '42501', MESSAGE = 'assessment_submission_forbidden';
  END IF;

  IF p_task_version_id IS NULL OR p_idempotency_key IS NULL
    OR p_response_text IS NULL
    OR char_length(btrim(p_response_text)) = 0
    OR char_length(p_response_text) > 12000 THEN
    RAISE EXCEPTION USING ERRCODE = '22023', MESSAGE = 'invalid_assessment_submission';
  END IF;

  SELECT task_version.pathway_id, mapping.rubric_version_id
    INTO selected_pathway_id, selected_rubric_version_id
    FROM public.task_versions AS task_version
    JOIN public.course_enrolments AS enrolment
      ON enrolment.pathway_id = task_version.pathway_id
     AND enrolment.learner_id = actor_id
     AND enrolment.status = 'active'
    JOIN public.task_rubric_mappings AS mapping
      ON mapping.task_version_id = task_version.id
    JOIN public.rubric_versions AS rubric_version
      ON rubric_version.id = mapping.rubric_version_id
     AND rubric_version.release_state = 'published'
    WHERE task_version.id = p_task_version_id
      AND task_version.release_state = 'published'
      AND task_version.response_mode = 'typed';

  IF NOT FOUND OR NOT EXISTS (
    SELECT 1
    FROM public.task_version_prompts AS prompt
    WHERE prompt.task_version_id = p_task_version_id
  ) THEN
    RAISE EXCEPTION USING ERRCODE = 'P0002', MESSAGE = 'assessment_task_not_available';
  END IF;

  -- Fast idempotent replay check. A key cannot be reused for another task or
  -- another response, and a retry still succeeds when capacity is now full.
  SELECT submission.* INTO existing_submission
    FROM public.assessment_submissions AS submission
    WHERE submission.learner_id = actor_id
      AND submission.idempotency_key = p_idempotency_key;

  IF FOUND THEN
    SELECT version.response_text INTO existing_response
      FROM public.submission_versions AS version
      WHERE version.submission_id = existing_submission.id
        AND version.version_number = 1;

    IF existing_submission.task_version_id <> p_task_version_id
      OR existing_response IS DISTINCT FROM p_response_text THEN
      RAISE EXCEPTION USING ERRCODE = 'P0001', MESSAGE = 'submission_idempotency_conflict';
    END IF;

    RETURN QUERY
      SELECT existing_submission.id, existing_submission.learner_id,
        existing_submission.task_version_id, existing_submission.rubric_version_id,
        existing_submission.status, existing_submission.accepted_at,
        existing_submission.grading_due_at, existing_submission.sla_target_seconds,
        existing_submission.capacity_limit_snapshot,
        existing_submission.open_submissions_before_acceptance, true;
    RETURN;
  END IF;

  -- Lock the singleton row to serialize capacity decisions across concurrent
  -- requests. Re-check the key after locking to handle concurrent same-key calls.
  SELECT config.* INTO capacity
    FROM private.grading_capacity_config AS config
    WHERE config.singleton = true
    FOR UPDATE;

  IF NOT FOUND OR NOT capacity.enabled THEN
    RAISE EXCEPTION USING ERRCODE = 'P0001', MESSAGE = 'submission_capacity_unavailable';
  END IF;

  SELECT submission.* INTO existing_submission
    FROM public.assessment_submissions AS submission
    WHERE submission.learner_id = actor_id
      AND submission.idempotency_key = p_idempotency_key;

  IF FOUND THEN
    SELECT version.response_text INTO existing_response
      FROM public.submission_versions AS version
      WHERE version.submission_id = existing_submission.id
        AND version.version_number = 1;

    IF existing_submission.task_version_id <> p_task_version_id
      OR existing_response IS DISTINCT FROM p_response_text THEN
      RAISE EXCEPTION USING ERRCODE = 'P0001', MESSAGE = 'submission_idempotency_conflict';
    END IF;

    RETURN QUERY
      SELECT existing_submission.id, existing_submission.learner_id,
        existing_submission.task_version_id, existing_submission.rubric_version_id,
        existing_submission.status, existing_submission.accepted_at,
        existing_submission.grading_due_at, existing_submission.sla_target_seconds,
        existing_submission.capacity_limit_snapshot,
        existing_submission.open_submissions_before_acceptance, true;
    RETURN;
  END IF;

  SELECT count(*)::integer INTO open_count
    FROM public.assessment_submissions AS submission
    WHERE submission.status IN ('queued', 'assigned', 'grading');

  IF open_count >= capacity.max_open_submissions THEN
    RAISE EXCEPTION USING ERRCODE = 'P0001', MESSAGE = 'submission_capacity_full';
  END IF;

  accepted_time := clock_timestamp();

  INSERT INTO public.assessment_submissions (
    learner_id, task_version_id, rubric_version_id, status,
    accepted_at, grading_due_at, sla_target_seconds,
    capacity_config_version, capacity_limit_snapshot,
    open_submissions_before_acceptance, idempotency_key
  )
  VALUES (
    actor_id, p_task_version_id, selected_rubric_version_id, 'queued',
    accepted_time, accepted_time + interval '24 hours', 86400,
    capacity.config_version, capacity.max_open_submissions,
    open_count, p_idempotency_key
  )
  RETURNING * INTO created_submission;

  INSERT INTO public.submission_versions (
    submission_id, version_number, response_text, created_by
  )
  VALUES (
    created_submission.id, 1, p_response_text, actor_id
  );

  INSERT INTO private.security_audit_events (
    actor_id, action, target_type, target_id, outcome, reason_category
  )
  VALUES (
    actor_id, 'assessment_submission_accepted', 'assessment_submission',
    created_submission.id, 'success', 'learner_action'
  );

  RETURN QUERY
    SELECT created_submission.id, created_submission.learner_id,
      created_submission.task_version_id, created_submission.rubric_version_id,
      created_submission.status, created_submission.accepted_at,
      created_submission.grading_due_at, created_submission.sla_target_seconds,
      created_submission.capacity_limit_snapshot,
      created_submission.open_submissions_before_acceptance, false;
END;
$$;

REVOKE ALL ON FUNCTION public.accept_assessment_submission(uuid, uuid, text)
  FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.accept_assessment_submission(uuid, uuid, text)
  TO authenticated;
