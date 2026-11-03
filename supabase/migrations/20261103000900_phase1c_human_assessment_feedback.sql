-- Phase 1C-C: assignment-scoped human grading, criterion outcomes and
-- immutable feedback publication. AI suggestions and PDF/file handling remain
-- deferred; only an explicitly authenticated human grader can publish feedback.

CREATE TABLE public.submission_grader_assignments (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  submission_id uuid NOT NULL
    REFERENCES public.assessment_submissions(id) ON DELETE RESTRICT,
  grader_user_id uuid NOT NULL REFERENCES auth.users(id) ON DELETE RESTRICT,
  assigned_by uuid NOT NULL REFERENCES auth.users(id) ON DELETE RESTRICT,
  assigned_at timestamptz NOT NULL DEFAULT clock_timestamp(),
  reason text NOT NULL CHECK (char_length(btrim(reason)) BETWEEN 3 AND 240),
  revoked_by uuid REFERENCES auth.users(id) ON DELETE RESTRICT,
  revoked_at timestamptz,
  CHECK (
    (revoked_at IS NULL AND revoked_by IS NULL)
    OR (revoked_at IS NOT NULL AND revoked_by IS NOT NULL)
  )
);

CREATE UNIQUE INDEX submission_grader_assignments_one_active
  ON public.submission_grader_assignments (submission_id)
  WHERE revoked_at IS NULL;

CREATE INDEX submission_grader_assignments_grader_active_idx
  ON public.submission_grader_assignments (grader_user_id, submission_id)
  WHERE revoked_at IS NULL;

CREATE TABLE public.assessment_versions (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  submission_id uuid NOT NULL
    REFERENCES public.assessment_submissions(id) ON DELETE RESTRICT,
  version_number integer NOT NULL CHECK (version_number > 0),
  rubric_version_id uuid NOT NULL
    REFERENCES public.rubric_versions(id) ON DELETE RESTRICT,
  total_points numeric(9,2) NOT NULL CHECK (total_points >= 0),
  max_points numeric(9,2) NOT NULL CHECK (max_points > 0 AND total_points <= max_points),
  overall_feedback text NOT NULL
    CHECK (char_length(btrim(overall_feedback)) BETWEEN 5 AND 8000),
  published_by uuid NOT NULL REFERENCES auth.users(id) ON DELETE RESTRICT,
  published_at timestamptz NOT NULL,
  first_published_at timestamptz NOT NULL,
  first_turnaround_seconds integer NOT NULL CHECK (first_turnaround_seconds >= 0),
  seconds_to_due_at_first_publish integer NOT NULL,
  sla_met boolean NOT NULL,
  change_reason text CHECK (change_reason IS NULL OR char_length(btrim(change_reason)) BETWEEN 3 AND 240),
  created_at timestamptz NOT NULL DEFAULT now(),
  CHECK (first_published_at <= published_at),
  CHECK (sla_met = (seconds_to_due_at_first_publish >= 0)),
  UNIQUE (submission_id, version_number)
);

CREATE INDEX assessment_versions_submission_idx
  ON public.assessment_versions (submission_id, version_number DESC);

CREATE TABLE public.criterion_results (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  assessment_version_id uuid NOT NULL
    REFERENCES public.assessment_versions(id) ON DELETE RESTRICT,
  rubric_criterion_id uuid NOT NULL
    REFERENCES public.rubric_criteria(id) ON DELETE RESTRICT,
  criterion_code_snapshot text NOT NULL CHECK (char_length(criterion_code_snapshot) BETWEEN 1 AND 80),
  criterion_title_snapshot text NOT NULL CHECK (char_length(criterion_title_snapshot) BETWEEN 1 AND 200),
  descriptor_snapshot text NOT NULL CHECK (char_length(descriptor_snapshot) BETWEEN 1 AND 3000),
  points_awarded numeric(7,2) NOT NULL CHECK (points_awarded >= 0),
  max_points_snapshot numeric(7,2) NOT NULL CHECK (max_points_snapshot >= 0 AND points_awarded <= max_points_snapshot),
  feedback text NOT NULL CHECK (char_length(btrim(feedback)) BETWEEN 5 AND 3000),
  created_at timestamptz NOT NULL DEFAULT now(),
  UNIQUE (assessment_version_id, rubric_criterion_id)
);

CREATE INDEX criterion_results_version_idx
  ON public.criterion_results (assessment_version_id, rubric_criterion_id);

-- Drafts are private and mutable only through the assigned grader's AAL2 RPC.
-- They never appear in learner/guardian or ordinary public-table reads.
CREATE TABLE private.assessment_drafts (
  submission_id uuid PRIMARY KEY
    REFERENCES public.assessment_submissions(id) ON DELETE RESTRICT,
  grader_user_id uuid NOT NULL REFERENCES auth.users(id) ON DELETE RESTRICT,
  rubric_version_id uuid NOT NULL REFERENCES public.rubric_versions(id) ON DELETE RESTRICT,
  overall_feedback text NOT NULL
    CHECK (char_length(btrim(overall_feedback)) BETWEEN 5 AND 8000),
  change_reason text CHECK (change_reason IS NULL OR char_length(btrim(change_reason)) BETWEEN 3 AND 240),
  criterion_results jsonb NOT NULL CHECK (jsonb_typeof(criterion_results) = 'array'),
  draft_revision integer NOT NULL DEFAULT 1 CHECK (draft_revision > 0),
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);

ALTER TABLE public.submission_grader_assignments ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.assessment_versions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.criterion_results ENABLE ROW LEVEL SECURITY;
ALTER TABLE private.assessment_drafts ENABLE ROW LEVEL SECURITY;

REVOKE ALL ON public.submission_grader_assignments, public.assessment_versions,
  public.criterion_results FROM PUBLIC, anon, authenticated;
GRANT SELECT ON public.submission_grader_assignments, public.assessment_versions,
  public.criterion_results TO authenticated;
REVOKE ALL ON private.assessment_drafts FROM PUBLIC, anon, authenticated;

-- Reuse the same assignment boundary for submission, response, task and rubric
-- reads. An AAL2 grader sees only work assigned to them; owner inspection is
-- independently AAL2-protected at the database boundary.
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
          private.current_user_has_role('grader'::public.app_role)
          AND coalesce(auth.jwt() ->> 'aal', 'aal1') = 'aal2'
          AND EXISTS (
            SELECT 1
            FROM public.submission_grader_assignments AS assignment
            WHERE assignment.submission_id = submission.id
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
      AND (
        (
          private.current_user_has_role('owner'::public.app_role)
          AND coalesce(auth.jwt() ->> 'aal', 'aal1') = 'aal2'
        )
        OR (
          private.current_user_has_role('grader'::public.app_role)
          AND coalesce(auth.jwt() ->> 'aal', 'aal1') = 'aal2'
          AND EXISTS (
            SELECT 1
            FROM public.assessment_submissions AS submission
            JOIN public.submission_grader_assignments AS assignment
              ON assignment.submission_id = submission.id
            WHERE submission.rubric_version_id = version.id
              AND assignment.grader_user_id = (SELECT auth.uid())
              AND assignment.revoked_at IS NULL
          )
        )
      )
  );
$$;

CREATE OR REPLACE FUNCTION private.can_read_task_version(target_task_version_id uuid)
RETURNS boolean
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = ''
AS $$
  SELECT EXISTS (
    SELECT 1
    FROM public.task_versions AS task_version
    WHERE task_version.id = target_task_version_id
      AND private.current_account_is_active()
      AND (
        (
          private.current_user_has_role('owner'::public.app_role)
          AND coalesce(auth.jwt() ->> 'aal', 'aal1') = 'aal2'
        )
        OR (
          task_version.release_state = 'published'
          AND (
            (
              private.current_user_has_role('student'::public.app_role)
              AND EXISTS (
                SELECT 1
                FROM public.course_enrolments AS enrolment
                WHERE enrolment.learner_id = (SELECT auth.uid())
                  AND enrolment.pathway_id = task_version.pathway_id
                  AND enrolment.status = 'active'
              )
            )
            OR (
              private.current_user_has_role('guardian'::public.app_role)
              AND EXISTS (
                SELECT 1
                FROM public.attempts AS attempt
                WHERE attempt.task_version_id = task_version.id
                  AND private.can_view_learner(attempt.learner_id, 'submissions')
              )
            )
            OR (
              private.current_user_has_role('grader'::public.app_role)
              AND coalesce(auth.jwt() ->> 'aal', 'aal1') = 'aal2'
              AND (
                EXISTS (
                  SELECT 1
                  FROM public.attempts AS attempt
                  JOIN public.grader_assignments AS assignment
                    ON assignment.attempt_id = attempt.id
                  WHERE attempt.task_version_id = task_version.id
                    AND attempt.status = 'submitted'
                    AND assignment.grader_user_id = (SELECT auth.uid())
                    AND assignment.revoked_at IS NULL
                )
                OR EXISTS (
                  SELECT 1
                  FROM public.assessment_submissions AS submission
                  JOIN public.submission_grader_assignments AS assignment
                    ON assignment.submission_id = submission.id
                  WHERE submission.task_version_id = task_version.id
                    AND assignment.grader_user_id = (SELECT auth.uid())
                    AND assignment.revoked_at IS NULL
                )
              )
            )
          )
        )
      )
  );
$$;

CREATE OR REPLACE FUNCTION private.can_read_assessment_version(target_assessment_version_id uuid)
RETURNS boolean
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = ''
AS $assessment_version_reader$
  SELECT EXISTS (
    SELECT 1
    FROM public.assessment_versions AS version
    WHERE version.id = target_assessment_version_id
      AND private.can_read_assessment_submission(version.submission_id)
      AND (
        (
          (
            private.current_user_has_role('student'::public.app_role)
            OR private.current_user_has_role('guardian'::public.app_role)
          )
          AND version.version_number = (
            SELECT max(latest.version_number)
            FROM public.assessment_versions AS latest
            WHERE latest.submission_id = version.submission_id
          )
        )
        OR (
          (
            private.current_user_has_role('grader'::public.app_role)
            OR private.current_user_has_role('owner'::public.app_role)
          )
          AND coalesce(auth.jwt() ->> 'aal', 'aal1') = 'aal2'
        )
      )
  );
$assessment_version_reader$;

REVOKE ALL ON FUNCTION private.can_read_assessment_submission(uuid) FROM PUBLIC, anon, authenticated;
REVOKE ALL ON FUNCTION private.can_read_assessment_version(uuid) FROM PUBLIC, anon, authenticated;
REVOKE ALL ON FUNCTION private.can_read_rubric_version(uuid) FROM PUBLIC, anon, authenticated;
REVOKE ALL ON FUNCTION private.can_read_task_version(uuid) FROM PUBLIC, anon, authenticated;
GRANT EXECUTE ON FUNCTION private.can_read_assessment_submission(uuid) TO authenticated;
GRANT EXECUTE ON FUNCTION private.can_read_assessment_version(uuid) TO authenticated;
GRANT EXECUTE ON FUNCTION private.can_read_rubric_version(uuid) TO authenticated;
GRANT EXECUTE ON FUNCTION private.can_read_task_version(uuid) TO authenticated;

CREATE POLICY submission_grader_assignments_select_scoped
  ON public.submission_grader_assignments FOR SELECT TO authenticated
  USING (
    private.current_account_is_active()
    AND (
      (
        grader_user_id = (SELECT auth.uid())
        AND revoked_at IS NULL
        AND private.current_user_has_role('grader'::public.app_role)
        AND coalesce(auth.jwt() ->> 'aal', 'aal1') = 'aal2'
      )
      OR (
        private.current_user_has_role('owner'::public.app_role)
        AND coalesce(auth.jwt() ->> 'aal', 'aal1') = 'aal2'
      )
    )
  );

CREATE POLICY assessment_versions_select_authorized_scope
  ON public.assessment_versions FOR SELECT TO authenticated
  USING (private.can_read_assessment_version(id));

CREATE POLICY criterion_results_select_authorized_scope
  ON public.criterion_results FOR SELECT TO authenticated
  USING (
    EXISTS (
      SELECT 1
      FROM public.assessment_versions AS version
      WHERE version.id = assessment_version_id
        AND private.can_read_assessment_version(version.id)
    )
  );

-- A published rubric version is immutable. Corrections require a new version,
-- never mutation of criteria already referenced by an accepted submission.
CREATE OR REPLACE FUNCTION private.prevent_published_rubric_mutation()
RETURNS trigger
LANGUAGE plpgsql
SET search_path = ''
AS $$
DECLARE
  target_rubric_version_id uuid;
  target_release_state text;
BEGIN
  target_rubric_version_id := CASE WHEN TG_OP = 'DELETE' THEN OLD.id ELSE NEW.id END;
  IF TG_TABLE_NAME = 'rubric_criteria' THEN
    target_rubric_version_id := CASE
      WHEN TG_OP = 'DELETE' THEN OLD.rubric_version_id
      ELSE NEW.rubric_version_id
    END;
  END IF;

  SELECT version.release_state INTO target_release_state
  FROM public.rubric_versions AS version
  WHERE version.id = target_rubric_version_id;

  IF target_release_state = 'published' THEN
    RAISE EXCEPTION USING ERRCODE = '42501', MESSAGE = 'published_rubric_immutable';
  END IF;
  RETURN CASE WHEN TG_OP = 'DELETE' THEN OLD ELSE NEW END;
END;
$$;

CREATE TRIGGER rubric_version_published_immutable
  BEFORE UPDATE OR DELETE ON public.rubric_versions
  FOR EACH ROW EXECUTE FUNCTION private.prevent_published_rubric_mutation();

CREATE TRIGGER rubric_criteria_published_immutable
  BEFORE INSERT OR UPDATE OR DELETE ON public.rubric_criteria
  FOR EACH ROW EXECUTE FUNCTION private.prevent_published_rubric_mutation();

CREATE OR REPLACE FUNCTION private.prevent_assessment_version_mutation()
RETURNS trigger
LANGUAGE plpgsql
SET search_path = ''
AS $$
BEGIN
  RAISE EXCEPTION USING ERRCODE = '42501', MESSAGE = 'assessment_version_immutable';
END;
$$;

CREATE TRIGGER assessment_versions_immutable
  BEFORE UPDATE OR DELETE ON public.assessment_versions
  FOR EACH ROW EXECUTE FUNCTION private.prevent_assessment_version_mutation();

CREATE OR REPLACE FUNCTION private.prevent_criterion_result_mutation()
RETURNS trigger
LANGUAGE plpgsql
SET search_path = ''
AS $$
BEGIN
  RAISE EXCEPTION USING ERRCODE = '42501', MESSAGE = 'criterion_result_immutable';
END;
$$;

CREATE TRIGGER criterion_results_immutable
  BEFORE UPDATE OR DELETE ON public.criterion_results
  FOR EACH ROW EXECUTE FUNCTION private.prevent_criterion_result_mutation();

CREATE OR REPLACE FUNCTION public.assign_submission_to_grader(
  p_submission_id uuid,
  p_grader_user_id uuid,
  p_reason text
)
RETURNS TABLE (
  assignment_id uuid,
  submission_id uuid,
  grader_user_id uuid,
  assigned_by uuid,
  assigned_at timestamptz
)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
DECLARE
  actor_id uuid := auth.uid();
  selected_submission public.assessment_submissions%ROWTYPE;
  created_assignment public.submission_grader_assignments%ROWTYPE;
BEGIN
  IF actor_id IS NULL
    OR NOT private.current_account_is_active()
    OR NOT private.current_user_has_role('owner'::public.app_role)
    OR coalesce(auth.jwt() ->> 'aal', 'aal1') <> 'aal2' THEN
    RAISE EXCEPTION USING ERRCODE = '42501', MESSAGE = 'assessment_assignment_forbidden';
  END IF;

  IF p_submission_id IS NULL OR p_grader_user_id IS NULL
    OR p_reason IS NULL OR char_length(btrim(p_reason)) NOT BETWEEN 3 AND 240 THEN
    RAISE EXCEPTION USING ERRCODE = '22023', MESSAGE = 'invalid_assessment_assignment';
  END IF;

  SELECT submission.* INTO selected_submission
  FROM public.assessment_submissions AS submission
  WHERE submission.id = p_submission_id
  FOR UPDATE;

  IF NOT FOUND THEN
    RAISE EXCEPTION USING ERRCODE = 'P0002', MESSAGE = 'assessment_submission_not_found';
  END IF;

  IF selected_submission.status <> 'queued'
    OR EXISTS (
      SELECT 1 FROM public.submission_grader_assignments AS assignment
      WHERE assignment.submission_id = p_submission_id
        AND assignment.revoked_at IS NULL
    ) THEN
    RAISE EXCEPTION USING ERRCODE = 'P0001', MESSAGE = 'assessment_submission_not_assignable';
  END IF;

  IF NOT EXISTS (
    SELECT 1
    FROM public.role_assignments AS role
    JOIN public.profiles AS profile ON profile.user_id = role.user_id
    WHERE role.user_id = p_grader_user_id
      AND role.role = 'grader'::public.app_role
      AND role.revoked_at IS NULL
      AND profile.account_status = 'active'
  ) THEN
    RAISE EXCEPTION USING ERRCODE = '22023', MESSAGE = 'grader_not_available';
  END IF;

  INSERT INTO public.submission_grader_assignments (
    submission_id, grader_user_id, assigned_by, reason
  )
  VALUES (p_submission_id, p_grader_user_id, actor_id, btrim(p_reason))
  RETURNING * INTO created_assignment;

  UPDATE public.assessment_submissions
  SET status = 'assigned'
  WHERE id = p_submission_id;

  INSERT INTO private.security_audit_events (
    actor_id, action, target_type, target_id, outcome, reason_category
  )
  VALUES (
    actor_id, 'assessment_submission_assigned', 'assessment_submission',
    p_submission_id, 'success', 'owner_assignment'
  );

  RETURN QUERY
    SELECT created_assignment.id, created_assignment.submission_id,
      created_assignment.grader_user_id, created_assignment.assigned_by,
      created_assignment.assigned_at;
END;
$$;

CREATE OR REPLACE FUNCTION public.save_assessment_draft(
  p_submission_id uuid,
  p_overall_feedback text,
  p_change_reason text,
  p_criterion_results jsonb
)
RETURNS TABLE (
  submission_id uuid,
  grader_user_id uuid,
  draft_revision integer,
  updated_at timestamptz
)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
DECLARE
  actor_id uuid := auth.uid();
  selected_submission public.assessment_submissions%ROWTYPE;
  existing_draft private.assessment_drafts%ROWTYPE;
  expected_criteria integer;
  supplied_criteria integer;
  distinct_criteria integer;
  published_count integer;
  next_revision integer;
  saved_at timestamptz;
  result_item jsonb;
BEGIN
  IF actor_id IS NULL OR NOT private.current_account_is_active()
    OR NOT private.current_user_has_role('grader'::public.app_role)
    OR coalesce(auth.jwt() ->> 'aal', 'aal1') <> 'aal2' THEN
    RAISE EXCEPTION USING ERRCODE = '42501', MESSAGE = 'grader_assessment_forbidden';
  END IF;

  IF p_submission_id IS NULL OR p_overall_feedback IS NULL
    OR char_length(btrim(p_overall_feedback)) NOT BETWEEN 5 AND 8000
    OR p_criterion_results IS NULL
    OR (p_change_reason IS NOT NULL AND char_length(btrim(p_change_reason)) NOT BETWEEN 3 AND 240) THEN
    RAISE EXCEPTION USING ERRCODE = '22023', MESSAGE = 'invalid_assessment_draft';
  END IF;

  IF jsonb_typeof(p_criterion_results) <> 'array' THEN
    RAISE EXCEPTION USING ERRCODE = '22023', MESSAGE = 'invalid_assessment_draft';
  END IF;

  IF jsonb_array_length(p_criterion_results) = 0 THEN
    RAISE EXCEPTION USING ERRCODE = '22023', MESSAGE = 'invalid_assessment_draft';
  END IF;

  SELECT submission.* INTO selected_submission
  FROM public.assessment_submissions AS submission
  WHERE submission.id = p_submission_id
  FOR UPDATE;

  IF NOT FOUND THEN
    RAISE EXCEPTION USING ERRCODE = 'P0002', MESSAGE = 'assessment_submission_not_found';
  END IF;

  IF selected_submission.status NOT IN ('assigned', 'grading', 'feedback_published') OR NOT EXISTS (
    SELECT 1 FROM public.submission_grader_assignments AS assignment
    WHERE assignment.submission_id = p_submission_id
      AND assignment.grader_user_id = actor_id
      AND assignment.revoked_at IS NULL
  ) THEN
    RAISE EXCEPTION USING ERRCODE = '42501', MESSAGE = 'grader_assessment_forbidden';
  END IF;

  SELECT draft.* INTO existing_draft
  FROM private.assessment_drafts AS draft
  WHERE draft.submission_id = p_submission_id
  FOR UPDATE;

  IF FOUND AND existing_draft.grader_user_id <> actor_id THEN
    RAISE EXCEPTION USING ERRCODE = '42501', MESSAGE = 'grader_assessment_forbidden';
  END IF;

  SELECT count(*)::integer INTO expected_criteria
  FROM public.rubric_criteria AS criterion
  WHERE criterion.rubric_version_id = selected_submission.rubric_version_id;

  IF expected_criteria = 0 THEN
    RAISE EXCEPTION USING ERRCODE = 'P0001', MESSAGE = 'invalid_assessment_criteria';
  END IF;

  FOR result_item IN SELECT value FROM jsonb_array_elements(p_criterion_results)
  LOOP
    IF jsonb_typeof(result_item) <> 'object' THEN
      RAISE EXCEPTION USING ERRCODE = '22023', MESSAGE = 'invalid_assessment_criteria';
    END IF;

    IF (SELECT count(*)::integer FROM jsonb_object_keys(result_item)) <> 3
      OR NOT (result_item ?& ARRAY['criterion_id', 'points_awarded', 'feedback'])
      OR jsonb_typeof(result_item -> 'criterion_id') <> 'string'
      OR (result_item ->> 'criterion_id') !~* '^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$'
      OR jsonb_typeof(result_item -> 'points_awarded') <> 'number'
      OR (result_item ->> 'points_awarded') !~ '^[0-9]{1,5}(\.[0-9]{1,2})?$'
      OR jsonb_typeof(result_item -> 'feedback') <> 'string'
      OR char_length(btrim(result_item ->> 'feedback')) NOT BETWEEN 5 AND 3000 THEN
      RAISE EXCEPTION USING ERRCODE = '22023', MESSAGE = 'invalid_assessment_criteria';
    END IF;
  END LOOP;

  SELECT
    count(*)::integer,
    count(DISTINCT (item.value ->> 'criterion_id'))::integer
  INTO supplied_criteria, distinct_criteria
  FROM jsonb_array_elements(p_criterion_results) AS item(value);

  IF supplied_criteria <> expected_criteria OR distinct_criteria <> expected_criteria THEN
    RAISE EXCEPTION USING ERRCODE = '22023', MESSAGE = 'invalid_assessment_criteria';
  END IF;

  IF EXISTS (
    SELECT 1
    FROM jsonb_array_elements(p_criterion_results) AS item(value)
    LEFT JOIN public.rubric_criteria AS criterion
      ON criterion.id = (item.value ->> 'criterion_id')::uuid
     AND criterion.rubric_version_id = selected_submission.rubric_version_id
    WHERE criterion.id IS NULL
      OR (item.value ->> 'points_awarded')::numeric > criterion.max_points
  ) THEN
    RAISE EXCEPTION USING ERRCODE = '22023', MESSAGE = 'invalid_assessment_criteria';
  END IF;

  SELECT count(*)::integer INTO published_count
  FROM public.assessment_versions AS version
  WHERE version.submission_id = p_submission_id;

  IF published_count > 0 AND char_length(btrim(coalesce(p_change_reason, ''))) < 3 THEN
    RAISE EXCEPTION USING ERRCODE = '22023', MESSAGE = 'assessment_change_reason_required';
  END IF;

  next_revision := CASE WHEN existing_draft.submission_id IS NULL
    THEN 1 ELSE existing_draft.draft_revision + 1 END;
  saved_at := clock_timestamp();

  INSERT INTO private.assessment_drafts (
    submission_id, grader_user_id, rubric_version_id, overall_feedback,
    change_reason, criterion_results, draft_revision, created_at, updated_at
  )
  VALUES (
    p_submission_id, actor_id, selected_submission.rubric_version_id,
    btrim(p_overall_feedback), nullif(btrim(coalesce(p_change_reason, '')), ''),
    p_criterion_results, next_revision, saved_at, saved_at
  )
  ON CONFLICT ON CONSTRAINT assessment_drafts_pkey DO UPDATE
  SET grader_user_id = EXCLUDED.grader_user_id,
      rubric_version_id = EXCLUDED.rubric_version_id,
      overall_feedback = EXCLUDED.overall_feedback,
      change_reason = EXCLUDED.change_reason,
      criterion_results = EXCLUDED.criterion_results,
      draft_revision = EXCLUDED.draft_revision,
      updated_at = EXCLUDED.updated_at;

  IF selected_submission.status = 'assigned' THEN
    UPDATE public.assessment_submissions
    SET status = 'grading'
    WHERE id = p_submission_id;
  END IF;

  INSERT INTO private.security_audit_events (
    actor_id, action, target_type, target_id, outcome, reason_category
  )
  VALUES (
    actor_id, 'assessment_draft_saved', 'assessment_submission',
    p_submission_id, 'success', 'grader_action'
  );

  RETURN QUERY SELECT p_submission_id, actor_id, next_revision, saved_at;
END;
$$;

CREATE OR REPLACE FUNCTION public.publish_assessment_feedback(p_submission_id uuid)
RETURNS TABLE (
  assessment_version_id uuid,
  submission_id uuid,
  version_number integer,
  total_points numeric,
  max_points numeric,
  published_at timestamptz,
  first_published_at timestamptz,
  first_turnaround_seconds integer,
  seconds_to_due_at_first_publish integer,
  sla_met boolean
)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
DECLARE
  actor_id uuid := auth.uid();
  selected_submission public.assessment_submissions%ROWTYPE;
  selected_draft private.assessment_drafts%ROWTYPE;
  created_version public.assessment_versions%ROWTYPE;
  next_version integer;
  published_time timestamptz;
  first_time timestamptz;
  first_turnaround integer;
  seconds_to_due integer;
  total numeric(9,2);
  maximum numeric(9,2);
BEGIN
  IF actor_id IS NULL OR NOT private.current_account_is_active()
    OR NOT private.current_user_has_role('grader'::public.app_role)
    OR coalesce(auth.jwt() ->> 'aal', 'aal1') <> 'aal2' THEN
    RAISE EXCEPTION USING ERRCODE = '42501', MESSAGE = 'grader_assessment_forbidden';
  END IF;

  SELECT submission.* INTO selected_submission
  FROM public.assessment_submissions AS submission
  WHERE submission.id = p_submission_id
  FOR UPDATE;

  IF NOT FOUND THEN
    RAISE EXCEPTION USING ERRCODE = 'P0002', MESSAGE = 'assessment_submission_not_found';
  END IF;

  IF selected_submission.status NOT IN ('assigned', 'grading', 'feedback_published')
    OR NOT EXISTS (
      SELECT 1 FROM public.submission_grader_assignments AS assignment
      WHERE assignment.submission_id = p_submission_id
        AND assignment.grader_user_id = actor_id
        AND assignment.revoked_at IS NULL
    ) THEN
    RAISE EXCEPTION USING ERRCODE = '42501', MESSAGE = 'grader_assessment_forbidden';
  END IF;

  SELECT draft.* INTO selected_draft
  FROM private.assessment_drafts AS draft
  WHERE draft.submission_id = p_submission_id
    AND draft.grader_user_id = actor_id
  FOR UPDATE;

  IF NOT FOUND THEN
    RAISE EXCEPTION USING ERRCODE = 'P0001', MESSAGE = 'assessment_draft_required';
  END IF;

  SELECT
    sum((item.value ->> 'points_awarded')::numeric)::numeric(9,2),
    sum(criterion.max_points)::numeric(9,2)
  INTO total, maximum
  FROM jsonb_array_elements(selected_draft.criterion_results) AS item(value)
  JOIN public.rubric_criteria AS criterion
    ON criterion.id = (item.value ->> 'criterion_id')::uuid
   AND criterion.rubric_version_id = selected_submission.rubric_version_id;

  IF total IS NULL OR maximum IS NULL OR maximum <= 0 THEN
    RAISE EXCEPTION USING ERRCODE = 'P0001', MESSAGE = 'assessment_draft_required';
  END IF;

  SELECT coalesce(max(version.version_number), 0) + 1
  INTO next_version
  FROM public.assessment_versions AS version
  WHERE version.submission_id = p_submission_id;

  published_time := clock_timestamp();

  IF next_version = 1 THEN
    first_time := published_time;
    first_turnaround := greatest(0, floor(extract(epoch FROM (published_time - selected_submission.accepted_at)))::integer);
    seconds_to_due := floor(extract(epoch FROM (selected_submission.grading_due_at - published_time)))::integer;
  ELSE
    SELECT version.first_published_at,
      version.first_turnaround_seconds,
      version.seconds_to_due_at_first_publish
    INTO first_time, first_turnaround, seconds_to_due
    FROM public.assessment_versions AS version
    WHERE version.submission_id = p_submission_id
    ORDER BY version.version_number ASC
    LIMIT 1;
  END IF;

  INSERT INTO public.assessment_versions (
    submission_id, version_number, rubric_version_id, total_points, max_points,
    overall_feedback, published_by, published_at, first_published_at,
    first_turnaround_seconds, seconds_to_due_at_first_publish, sla_met,
    change_reason
  )
  VALUES (
    p_submission_id, next_version, selected_submission.rubric_version_id,
    total, maximum, selected_draft.overall_feedback, actor_id, published_time,
    first_time, first_turnaround, seconds_to_due, seconds_to_due >= 0,
    selected_draft.change_reason
  )
  RETURNING * INTO created_version;

  INSERT INTO public.criterion_results (
    assessment_version_id, rubric_criterion_id, criterion_code_snapshot,
    criterion_title_snapshot, descriptor_snapshot, points_awarded,
    max_points_snapshot, feedback
  )
  SELECT created_version.id, criterion.id, criterion.criterion_code,
    criterion.title, criterion.descriptor,
    (item.value ->> 'points_awarded')::numeric,
    criterion.max_points,
    btrim(item.value ->> 'feedback')
  FROM jsonb_array_elements(selected_draft.criterion_results) AS item(value)
  JOIN public.rubric_criteria AS criterion
    ON criterion.id = (item.value ->> 'criterion_id')::uuid
   AND criterion.rubric_version_id = selected_submission.rubric_version_id;

  UPDATE public.assessment_submissions
  SET status = 'feedback_published'
  WHERE id = p_submission_id;

  DELETE FROM private.assessment_drafts
  WHERE submission_id = p_submission_id;

  INSERT INTO private.security_audit_events (
    actor_id, action, target_type, target_id, outcome, reason_category
  )
  VALUES (
    actor_id,
    CASE WHEN next_version = 1 THEN 'assessment_feedback_published' ELSE 'assessment_feedback_edited' END,
    'assessment_submission', p_submission_id, 'success', 'human_grader_publication'
  );

  RETURN QUERY SELECT created_version.id, created_version.submission_id,
    created_version.version_number, created_version.total_points,
    created_version.max_points, created_version.published_at,
    created_version.first_published_at, created_version.first_turnaround_seconds,
    created_version.seconds_to_due_at_first_publish, created_version.sla_met;
END;
$$;

CREATE OR REPLACE FUNCTION public.get_assessment_draft(p_submission_id uuid)
RETURNS TABLE (
  submission_id uuid,
  grader_user_id uuid,
  rubric_version_id uuid,
  overall_feedback text,
  change_reason text,
  criterion_results jsonb,
  draft_revision integer,
  updated_at timestamptz
)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $assessment_draft_reader$
DECLARE
  actor_id uuid := auth.uid();
BEGIN
  IF actor_id IS NULL OR NOT private.current_account_is_active()
    OR NOT private.current_user_has_role('grader'::public.app_role)
    OR coalesce(auth.jwt() ->> 'aal', 'aal1') <> 'aal2'
    OR NOT EXISTS (
      SELECT 1
      FROM public.submission_grader_assignments AS assignment
      WHERE assignment.submission_id = p_submission_id
        AND assignment.grader_user_id = actor_id
        AND assignment.revoked_at IS NULL
    ) THEN
    RAISE EXCEPTION USING ERRCODE = '42501', MESSAGE = 'grader_assessment_forbidden';
  END IF;

  RETURN QUERY
    SELECT draft.submission_id, draft.grader_user_id, draft.rubric_version_id,
      draft.overall_feedback, draft.change_reason, draft.criterion_results,
      draft.draft_revision, draft.updated_at
    FROM private.assessment_drafts AS draft
    WHERE draft.submission_id = p_submission_id
      AND draft.grader_user_id = actor_id;
END;
$assessment_draft_reader$;

REVOKE ALL ON FUNCTION public.get_assessment_draft(uuid) FROM PUBLIC, anon, authenticated;
GRANT EXECUTE ON FUNCTION public.get_assessment_draft(uuid) TO authenticated;

-- Keep table access in database-only definer routines; the browser never
-- receives direct read/write grants on the private draft table.
ALTER FUNCTION public.assign_submission_to_grader(uuid, uuid, text) OWNER TO postgres;
ALTER FUNCTION public.save_assessment_draft(uuid, text, text, jsonb) OWNER TO postgres;
ALTER FUNCTION public.publish_assessment_feedback(uuid) OWNER TO postgres;
ALTER FUNCTION public.get_assessment_draft(uuid) OWNER TO postgres;

REVOKE ALL ON FUNCTION public.assign_submission_to_grader(uuid, uuid, text) FROM PUBLIC, anon, authenticated;
REVOKE ALL ON FUNCTION public.save_assessment_draft(uuid, text, text, jsonb) FROM PUBLIC, anon, authenticated;
REVOKE ALL ON FUNCTION public.publish_assessment_feedback(uuid) FROM PUBLIC, anon, authenticated;
GRANT EXECUTE ON FUNCTION public.assign_submission_to_grader(uuid, uuid, text) TO authenticated;
GRANT EXECUTE ON FUNCTION public.save_assessment_draft(uuid, text, text, jsonb) TO authenticated;
GRANT EXECUTE ON FUNCTION public.publish_assessment_feedback(uuid) TO authenticated;
