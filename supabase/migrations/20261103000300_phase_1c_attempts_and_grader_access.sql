-- Phase 1C, first protected vertical slice: typed attempts and assignment-scoped grading reads.
-- This migration contains schema and authorization only. It creates no Storage bucket,
-- external service, real learner record or learner-facing curriculum content.

CREATE TABLE public.task_versions (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  task_code text NOT NULL CHECK (char_length(task_code) BETWEEN 1 AND 120),
  pathway_id text NOT NULL CHECK (char_length(pathway_id) BETWEEN 1 AND 120),
  title text NOT NULL CHECK (char_length(title) BETWEEN 1 AND 200),
  version integer NOT NULL CHECK (version > 0),
  response_mode text NOT NULL DEFAULT 'typed' CHECK (response_mode = 'typed'),
  expected_min_words integer NOT NULL DEFAULT 0 CHECK (expected_min_words BETWEEN 0 AND 5000),
  ideal_words integer NOT NULL CHECK (ideal_words BETWEEN expected_min_words AND 10000),
  release_state text NOT NULL DEFAULT 'draft' CHECK (release_state IN ('draft', 'published', 'retired')),
  created_at timestamptz NOT NULL DEFAULT now(),
  UNIQUE (task_code, version)
);

CREATE TABLE public.task_version_prompts (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  task_version_id uuid NOT NULL REFERENCES public.task_versions(id) ON DELETE RESTRICT,
  sequence integer NOT NULL CHECK (sequence > 0),
  prompt_text text NOT NULL CHECK (char_length(prompt_text) BETWEEN 1 AND 3000),
  created_at timestamptz NOT NULL DEFAULT now(),
  UNIQUE (task_version_id, sequence),
  UNIQUE (id, task_version_id)
);

CREATE TABLE public.attempts (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  learner_id uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  task_version_id uuid NOT NULL REFERENCES public.task_versions(id) ON DELETE RESTRICT,
  status text NOT NULL DEFAULT 'in_progress' CHECK (status IN ('in_progress', 'submitted', 'withdrawn')),
  started_at timestamptz NOT NULL DEFAULT now(),
  submitted_at timestamptz,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  CHECK ((status = 'submitted') = (submitted_at IS NOT NULL)),
  UNIQUE (id, task_version_id)
);

CREATE INDEX attempts_learner_created_idx
  ON public.attempts (learner_id, created_at DESC);
CREATE INDEX attempts_status_submitted_idx
  ON public.attempts (status, submitted_at ASC)
  WHERE status = 'submitted';

CREATE TABLE public.attempt_responses (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  attempt_id uuid NOT NULL,
  task_version_id uuid NOT NULL,
  prompt_id uuid NOT NULL,
  response_text text NOT NULL DEFAULT '' CHECK (char_length(response_text) <= 12000),
  word_count integer GENERATED ALWAYS AS (
    CASE
      WHEN btrim(response_text) = '' THEN 0
      ELSE array_length(regexp_split_to_array(btrim(response_text), E'\\s+'), 1)
    END
  ) STORED,
  version integer NOT NULL DEFAULT 1 CHECK (version > 0),
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  FOREIGN KEY (attempt_id, task_version_id)
    REFERENCES public.attempts(id, task_version_id) ON DELETE CASCADE,
  FOREIGN KEY (prompt_id, task_version_id)
    REFERENCES public.task_version_prompts(id, task_version_id) ON DELETE RESTRICT,
  UNIQUE (attempt_id, prompt_id)
);

CREATE INDEX attempt_responses_attempt_idx
  ON public.attempt_responses (attempt_id);

CREATE TABLE public.grader_assignments (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  attempt_id uuid NOT NULL REFERENCES public.attempts(id) ON DELETE RESTRICT,
  grader_user_id uuid NOT NULL REFERENCES auth.users(id) ON DELETE RESTRICT,
  assigned_by uuid NOT NULL REFERENCES auth.users(id) ON DELETE RESTRICT,
  assigned_at timestamptz NOT NULL DEFAULT now(),
  revoked_by uuid REFERENCES auth.users(id) ON DELETE SET NULL,
  revoked_at timestamptz,
  reason text NOT NULL CHECK (char_length(btrim(reason)) BETWEEN 3 AND 240),
  CHECK ((revoked_by IS NULL) = (revoked_at IS NULL))
);

CREATE UNIQUE INDEX grader_assignments_one_active_per_attempt
  ON public.grader_assignments (attempt_id)
  WHERE revoked_at IS NULL;
CREATE INDEX grader_assignments_grader_active_idx
  ON public.grader_assignments (grader_user_id, assigned_at)
  WHERE revoked_at IS NULL;

-- RLS helpers are private, fixed-search-path SECURITY DEFINER functions.
-- They return only a boolean and never return learner data or bypass a route check.
CREATE OR REPLACE FUNCTION private.can_read_attempt(target_attempt_id uuid)
RETURNS boolean
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = ''
AS $$
  SELECT EXISTS (
    SELECT 1
    FROM public.attempts AS attempt
    WHERE attempt.id = target_attempt_id
      AND private.current_account_is_active()
      AND (
        (
          attempt.learner_id = (SELECT auth.uid())
          AND private.current_user_has_role('student'::public.app_role)
        )
        OR (
          private.current_user_has_role('guardian'::public.app_role)
          AND private.can_view_learner(attempt.learner_id, 'submissions')
        )
        OR (
          private.current_user_has_role('grader'::public.app_role)
          AND coalesce(auth.jwt() ->> 'aal', 'aal1') = 'aal2'
          AND EXISTS (
            SELECT 1
            FROM public.grader_assignments AS assignment
            WHERE assignment.attempt_id = attempt.id
              AND assignment.grader_user_id = (SELECT auth.uid())
              AND assignment.revoked_at IS NULL
          )
        )
        OR (
          private.current_user_has_role('owner'::public.app_role)
          AND coalesce(auth.jwt() ->> 'aal', 'aal1') = 'aal2'
        )
      )
  );
$$;

CREATE OR REPLACE FUNCTION private.can_write_attempt(target_attempt_id uuid)
RETURNS boolean
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = ''
AS $$
  SELECT EXISTS (
    SELECT 1
    FROM public.attempts AS attempt
    WHERE attempt.id = target_attempt_id
      AND attempt.learner_id = (SELECT auth.uid())
      AND attempt.status = 'in_progress'
      AND private.current_account_is_active()
      AND private.current_user_has_role('student'::public.app_role)
  );
$$;

REVOKE ALL ON FUNCTION private.can_read_attempt(uuid) FROM PUBLIC, anon;
REVOKE ALL ON FUNCTION private.can_write_attempt(uuid) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION private.can_read_attempt(uuid) TO authenticated;
GRANT EXECUTE ON FUNCTION private.can_write_attempt(uuid) TO authenticated;

CREATE OR REPLACE FUNCTION private.prepare_attempt_response()
RETURNS trigger
LANGUAGE plpgsql
SET search_path = ''
AS $$
BEGIN
  IF TG_OP = 'INSERT' THEN
    NEW.version := 1;
    NEW.created_at := now();
  ELSE
    NEW.version := OLD.version + 1;
    NEW.created_at := OLD.created_at;
  END IF;
  NEW.updated_at := now();
  RETURN NEW;
END;
$$;

CREATE TRIGGER attempt_responses_prepare_metadata
  BEFORE INSERT OR UPDATE ON public.attempt_responses
  FOR EACH ROW EXECUTE FUNCTION private.prepare_attempt_response();

CREATE TRIGGER attempts_set_updated_at
  BEFORE UPDATE ON public.attempts
  FOR EACH ROW EXECUTE FUNCTION private.set_updated_at();

-- Reset browser/PostgREST grants and expose only the required read/write columns.
REVOKE ALL ON public.task_versions, public.task_version_prompts,
  public.attempts, public.attempt_responses, public.grader_assignments
  FROM PUBLIC, anon, authenticated;

GRANT SELECT ON public.task_versions, public.task_version_prompts,
  public.attempts, public.attempt_responses, public.grader_assignments
  TO authenticated;
GRANT INSERT (learner_id, task_version_id)
  ON public.attempts TO authenticated;
GRANT INSERT (attempt_id, task_version_id, prompt_id, response_text),
  UPDATE (response_text)
  ON public.attempt_responses TO authenticated;

ALTER TABLE public.task_versions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.task_version_prompts ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.attempts ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.attempt_responses ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.grader_assignments ENABLE ROW LEVEL SECURITY;

CREATE POLICY task_versions_select_released_or_owner
  ON public.task_versions FOR SELECT TO authenticated
  USING (
    private.current_account_is_active()
    AND (
      (
        release_state = 'published'
        AND (
          private.current_user_has_role('student'::public.app_role)
          OR private.current_user_has_role('guardian'::public.app_role)
          OR private.current_user_has_role('grader'::public.app_role)
        )
      )
      OR (
        private.current_user_has_role('owner'::public.app_role)
        AND coalesce(auth.jwt() ->> 'aal', 'aal1') = 'aal2'
      )
    )
  );

CREATE POLICY task_version_prompts_select_released_or_owner
  ON public.task_version_prompts FOR SELECT TO authenticated
  USING (
    private.current_account_is_active()
    AND EXISTS (
      SELECT 1
      FROM public.task_versions AS task_version
      WHERE task_version.id = task_version_id
        AND (
          task_version.release_state = 'published'
          OR (
            private.current_user_has_role('owner'::public.app_role)
            AND coalesce(auth.jwt() ->> 'aal', 'aal1') = 'aal2'
          )
        )
    )
  );

CREATE POLICY attempts_select_authorized_scope
  ON public.attempts FOR SELECT TO authenticated
  USING (private.can_read_attempt(id));

CREATE POLICY attempts_insert_own_published_task
  ON public.attempts FOR INSERT TO authenticated
  WITH CHECK (
    learner_id = (SELECT auth.uid())
    AND status = 'in_progress'
    AND submitted_at IS NULL
    AND private.current_account_is_active()
    AND private.current_user_has_role('student'::public.app_role)
    AND EXISTS (
      SELECT 1
      FROM public.task_versions AS task_version
      JOIN public.course_enrolments AS enrolment
        ON enrolment.pathway_id = task_version.pathway_id
      WHERE task_version.id = task_version_id
        AND task_version.release_state = 'published'
        AND task_version.response_mode = 'typed'
        AND enrolment.learner_id = (SELECT auth.uid())
        AND enrolment.status = 'active'
    )
  );

CREATE POLICY attempt_responses_select_authorized_scope
  ON public.attempt_responses FOR SELECT TO authenticated
  USING (private.can_read_attempt(attempt_id));

CREATE POLICY attempt_responses_insert_own_draft
  ON public.attempt_responses FOR INSERT TO authenticated
  WITH CHECK (
    private.can_write_attempt(attempt_id)
    AND EXISTS (
      SELECT 1
      FROM public.attempts AS attempt
      WHERE attempt.id = attempt_id
        AND attempt.task_version_id = task_version_id
    )
  );

CREATE POLICY attempt_responses_update_own_draft
  ON public.attempt_responses FOR UPDATE TO authenticated
  USING (private.can_write_attempt(attempt_id))
  WITH CHECK (private.can_write_attempt(attempt_id));

CREATE POLICY grader_assignments_select_assigned_or_owner
  ON public.grader_assignments FOR SELECT TO authenticated
  USING (
    private.current_account_is_active()
    AND (
      (
        grader_user_id = (SELECT auth.uid())
        AND private.current_user_has_role('grader'::public.app_role)
        AND coalesce(auth.jwt() ->> 'aal', 'aal1') = 'aal2'
      )
      OR (
        private.current_user_has_role('owner'::public.app_role)
        AND coalesce(auth.jwt() ->> 'aal', 'aal1') = 'aal2'
      )
    )
  );

-- A learner can submit only their own in-progress typed attempt, and the server
-- stamps the submitted state/time. A non-empty response is mandatory.
CREATE OR REPLACE FUNCTION public.submit_attempt(p_attempt_id uuid)
RETURNS TABLE (
  attempt_id uuid,
  status text,
  submitted_at timestamptz
)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
DECLARE
  actor_id uuid := auth.uid();
  current_status text;
  stamped_at timestamptz;
BEGIN
  IF actor_id IS NULL
    OR NOT private.current_account_is_active()
    OR NOT private.current_user_has_role('student'::public.app_role) THEN
    RAISE EXCEPTION USING ERRCODE = '42501', MESSAGE = 'attempt_submission_forbidden';
  END IF;

  SELECT attempt.status
    INTO current_status
    FROM public.attempts AS attempt
    WHERE attempt.id = p_attempt_id
      AND attempt.learner_id = actor_id
    FOR UPDATE;

  IF NOT FOUND THEN
    RAISE EXCEPTION USING ERRCODE = 'P0002', MESSAGE = 'attempt_not_found';
  END IF;

  IF current_status <> 'in_progress' THEN
    RAISE EXCEPTION USING ERRCODE = 'P0001', MESSAGE = 'attempt_not_in_progress';
  END IF;

  IF NOT EXISTS (
    SELECT 1
    FROM public.attempt_responses AS response
    WHERE response.attempt_id = p_attempt_id
      AND btrim(response.response_text) <> ''
  ) THEN
    RAISE EXCEPTION USING ERRCODE = '23514', MESSAGE = 'attempt_response_required';
  END IF;

  UPDATE public.attempts AS attempt
    SET status = 'submitted',
        submitted_at = now()
    WHERE attempt.id = p_attempt_id
    RETURNING attempt.submitted_at INTO stamped_at;

  INSERT INTO private.security_audit_events (
    actor_id, action, target_type, target_id, outcome, reason_category
  )
  VALUES (actor_id, 'attempt_submitted', 'attempt', p_attempt_id, 'success', 'learner_action');

  RETURN QUERY SELECT p_attempt_id, 'submitted'::text, stamped_at;
END;
$$;

-- Only the active owner at AAL2 may create a grader assignment. No browser role
-- can write this table directly; the RPC locks the submitted attempt and audits it.
CREATE OR REPLACE FUNCTION public.assign_attempt_to_grader(
  p_attempt_id uuid,
  p_grader_user_id uuid,
  p_reason text
)
RETURNS TABLE (
  assignment_id uuid,
  attempt_id uuid,
  grader_user_id uuid,
  assigned_at timestamptz
)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
DECLARE
  actor_id uuid := auth.uid();
  attempt_status text;
  new_assignment_id uuid;
  new_assigned_at timestamptz;
BEGIN
  IF actor_id IS NULL
    OR NOT private.current_account_is_active()
    OR NOT private.current_user_has_role('owner'::public.app_role) THEN
    RAISE EXCEPTION USING ERRCODE = '42501', MESSAGE = 'attempt_assignment_forbidden';
  END IF;

  IF coalesce(auth.jwt() ->> 'aal', 'aal1') <> 'aal2' THEN
    RAISE EXCEPTION USING ERRCODE = 'P0001', MESSAGE = 'mfa_required';
  END IF;

  IF p_reason IS NULL OR char_length(btrim(p_reason)) NOT BETWEEN 3 AND 240 THEN
    RAISE EXCEPTION USING ERRCODE = '22023', MESSAGE = 'invalid_assignment_reason';
  END IF;

  IF NOT EXISTS (
    SELECT 1
    FROM public.profiles AS profile
    JOIN public.role_assignments AS role_assignment
      ON role_assignment.user_id = profile.user_id
    WHERE profile.user_id = p_grader_user_id
      AND profile.account_status = 'active'
      AND role_assignment.role = 'grader'::public.app_role
      AND role_assignment.revoked_at IS NULL
  ) THEN
    RAISE EXCEPTION USING ERRCODE = '22023', MESSAGE = 'grader_not_available';
  END IF;

  SELECT attempt.status
    INTO attempt_status
    FROM public.attempts AS attempt
    WHERE attempt.id = p_attempt_id
    FOR UPDATE;

  IF NOT FOUND THEN
    RAISE EXCEPTION USING ERRCODE = 'P0002', MESSAGE = 'attempt_not_found';
  END IF;

  IF attempt_status <> 'submitted' THEN
    RAISE EXCEPTION USING ERRCODE = 'P0001', MESSAGE = 'attempt_not_submitted';
  END IF;

  IF EXISTS (
    SELECT 1
    FROM public.grader_assignments AS assignment
    WHERE assignment.attempt_id = p_attempt_id
      AND assignment.revoked_at IS NULL
  ) THEN
    RAISE EXCEPTION USING ERRCODE = 'P0001', MESSAGE = 'attempt_already_assigned';
  END IF;

  INSERT INTO public.grader_assignments AS new_assignment (
    attempt_id, grader_user_id, assigned_by, reason
  )
  VALUES (p_attempt_id, p_grader_user_id, actor_id, btrim(p_reason))
  RETURNING new_assignment.id, new_assignment.assigned_at
    INTO new_assignment_id, new_assigned_at;

  INSERT INTO private.security_audit_events (
    actor_id, action, target_type, target_id, outcome, reason_category
  )
  VALUES (actor_id, 'attempt_assigned_to_grader', 'grader_assignment',
    new_assignment_id, 'success', 'owner_assignment');

  RETURN QUERY SELECT new_assignment_id, p_attempt_id, p_grader_user_id, new_assigned_at;
END;
$$;

REVOKE ALL ON FUNCTION public.submit_attempt(uuid) FROM PUBLIC, anon;
REVOKE ALL ON FUNCTION public.assign_attempt_to_grader(uuid, uuid, text) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.submit_attempt(uuid) TO authenticated;
GRANT EXECUTE ON FUNCTION public.assign_attempt_to_grader(uuid, uuid, text) TO authenticated;
