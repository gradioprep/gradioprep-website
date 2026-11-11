-- Phase 2: direct task/prompt mapping and learner SA-attempt-to-milestone linkage.
-- Generic schema only. No live curriculum route, SA task or prompt mapping is seeded.

ALTER TABLE public.milestone_unit_memberships
  ADD CONSTRAINT milestone_unit_memberships_assessment_identity_unique
  UNIQUE (
    id,
    milestone_cycle_version_id,
    milestone_segment_id,
    route_version_id,
    curriculum_unit_version_id
  );

ALTER TABLE public.curriculum_unit_outcome_mappings
  ADD COLUMN is_listening_outcome boolean NOT NULL DEFAULT false;

ALTER TABLE public.curriculum_unit_outcome_mappings
  ADD CONSTRAINT curriculum_unit_outcome_mappings_assessment_identity_unique
  UNIQUE (id, curriculum_unit_version_id);

CREATE TABLE public.milestone_assessment_task_mappings (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  task_version_id uuid NOT NULL
    REFERENCES public.task_versions(id) ON DELETE RESTRICT,
  route_version_id uuid NOT NULL,
  milestone_cycle_version_id uuid NOT NULL,
  milestone_segment_id uuid NOT NULL,
  assessment_code text NOT NULL CHECK (assessment_code IN ('SA1', 'SA2', 'SA3')),
  review_state text NOT NULL DEFAULT 'draft'
    CHECK (review_state IN ('draft', 'approved', 'unmapped')),
  mapping_rationale text NOT NULL
    CHECK (char_length(btrim(mapping_rationale)) BETWEEN 1 AND 2000),
  reviewed_by uuid REFERENCES auth.users(id) ON DELETE RESTRICT,
  reviewed_at timestamptz,
  created_at timestamptz NOT NULL DEFAULT now(),
  FOREIGN KEY (milestone_cycle_version_id, route_version_id)
    REFERENCES public.milestone_cycle_versions(id, route_version_id)
    ON DELETE RESTRICT,
  FOREIGN KEY (milestone_segment_id, milestone_cycle_version_id, route_version_id)
    REFERENCES public.milestone_segments(id, milestone_cycle_version_id, route_version_id)
    ON DELETE RESTRICT,
  UNIQUE (task_version_id, milestone_cycle_version_id),
  UNIQUE (
    id,
    task_version_id,
    route_version_id,
    milestone_cycle_version_id,
    milestone_segment_id
  ),
  CHECK (
    review_state NOT IN ('approved', 'unmapped')
    OR (reviewed_by IS NOT NULL AND reviewed_at IS NOT NULL)
  )
);

CREATE INDEX milestone_assessment_task_mappings_segment_idx
  ON public.milestone_assessment_task_mappings (
    milestone_cycle_version_id,
    milestone_segment_id,
    review_state
  );

CREATE TABLE public.milestone_assessment_prompt_outcome_mappings (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  task_mapping_id uuid NOT NULL,
  task_version_id uuid NOT NULL,
  task_version_prompt_id uuid NOT NULL,
  route_version_id uuid NOT NULL,
  milestone_cycle_version_id uuid NOT NULL,
  milestone_segment_id uuid NOT NULL,
  milestone_unit_membership_id uuid NOT NULL,
  curriculum_unit_version_id uuid NOT NULL,
  curriculum_unit_outcome_mapping_id uuid NOT NULL,
  mapping_status text NOT NULL DEFAULT 'pending'
    CHECK (mapping_status IN ('pending', 'direct', 'unmapped')),
  mapping_rationale text NOT NULL
    CHECK (char_length(btrim(mapping_rationale)) BETWEEN 1 AND 2000),
  reviewed_by uuid REFERENCES auth.users(id) ON DELETE RESTRICT,
  reviewed_at timestamptz,
  created_at timestamptz NOT NULL DEFAULT now(),
  FOREIGN KEY (
    task_mapping_id,
    task_version_id,
    route_version_id,
    milestone_cycle_version_id,
    milestone_segment_id
  )
    REFERENCES public.milestone_assessment_task_mappings (
      id,
      task_version_id,
      route_version_id,
      milestone_cycle_version_id,
      milestone_segment_id
    )
    ON DELETE RESTRICT,
  FOREIGN KEY (task_version_prompt_id, task_version_id)
    REFERENCES public.task_version_prompts(id, task_version_id)
    ON DELETE RESTRICT,
  FOREIGN KEY (
    milestone_unit_membership_id,
    milestone_cycle_version_id,
    milestone_segment_id,
    route_version_id,
    curriculum_unit_version_id
  )
    REFERENCES public.milestone_unit_memberships (
      id,
      milestone_cycle_version_id,
      milestone_segment_id,
      route_version_id,
      curriculum_unit_version_id
    )
    ON DELETE RESTRICT,
  FOREIGN KEY (curriculum_unit_outcome_mapping_id, curriculum_unit_version_id)
    REFERENCES public.curriculum_unit_outcome_mappings(id, curriculum_unit_version_id)
    ON DELETE RESTRICT,
  UNIQUE (
    task_mapping_id,
    task_version_prompt_id,
    curriculum_unit_outcome_mapping_id
  ),
  CHECK (
    mapping_status NOT IN ('direct', 'unmapped')
    OR (reviewed_by IS NOT NULL AND reviewed_at IS NOT NULL)
  )
);

CREATE INDEX milestone_assessment_prompt_mappings_task_idx
  ON public.milestone_assessment_prompt_outcome_mappings (
    task_mapping_id,
    task_version_prompt_id,
    mapping_status
  );

CREATE OR REPLACE FUNCTION private.validate_milestone_assessment_task_mapping()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
DECLARE
  selected_segment_number smallint;
  selected_route_key text;
  selected_task_pathway text;
  selected_task_state text;
  selected_cycle_state text;
  selected_route_state text;
  prompt_count integer;
  mapped_prompt_count integer;
BEGIN
  SELECT segment.segment_number
    INTO selected_segment_number
  FROM public.milestone_segments AS segment
  WHERE segment.id = NEW.milestone_segment_id
    AND segment.milestone_cycle_version_id = NEW.milestone_cycle_version_id
    AND segment.route_version_id = NEW.route_version_id;

  IF NOT FOUND
    OR NEW.assessment_code <> ('SA' || selected_segment_number::text) THEN
    RAISE EXCEPTION USING ERRCODE = '23514', MESSAGE = 'milestone_assessment_code_segment_mismatch';
  END IF;

  SELECT route.route_key, route.review_state, cycle.release_state,
         task.pathway_id, task.release_state
    INTO selected_route_key, selected_route_state, selected_cycle_state,
         selected_task_pathway, selected_task_state
  FROM public.curriculum_route_versions AS route
  JOIN public.milestone_cycle_versions AS cycle
    ON cycle.route_version_id = route.id
  JOIN public.task_versions AS task
    ON task.id = NEW.task_version_id
  WHERE route.id = NEW.route_version_id
    AND cycle.id = NEW.milestone_cycle_version_id;

  IF NOT FOUND OR selected_task_pathway IS DISTINCT FROM selected_route_key THEN
    RAISE EXCEPTION USING ERRCODE = '23514', MESSAGE = 'milestone_assessment_task_route_mismatch';
  END IF;

  IF NEW.review_state = 'approved' THEN
    IF NEW.reviewed_by IS NULL OR NEW.reviewed_at IS NULL
      OR selected_route_state <> 'verified'
      OR selected_cycle_state <> 'published'
      OR selected_task_state <> 'published' THEN
      RAISE EXCEPTION USING ERRCODE = '55000', MESSAGE = 'milestone_assessment_requires_published_route_cycle_task';
    END IF;

    SELECT count(*)::integer INTO prompt_count
    FROM public.task_version_prompts AS prompt
    WHERE prompt.task_version_id = NEW.task_version_id;

    SELECT count(DISTINCT prompt.id)::integer INTO mapped_prompt_count
    FROM public.task_version_prompts AS prompt
    WHERE prompt.task_version_id = NEW.task_version_id
      AND EXISTS (
        SELECT 1
        FROM public.milestone_assessment_prompt_outcome_mappings AS outcome_mapping
        WHERE outcome_mapping.task_mapping_id = NEW.id
          AND outcome_mapping.task_version_prompt_id = prompt.id
          AND outcome_mapping.mapping_status = 'direct'
          AND outcome_mapping.reviewed_by IS NOT NULL
          AND outcome_mapping.reviewed_at IS NOT NULL
      );

    IF prompt_count = 0 OR mapped_prompt_count <> prompt_count THEN
      RAISE EXCEPTION USING ERRCODE = '55000', MESSAGE = 'milestone_assessment_requires_direct_mapping_for_every_prompt';
    END IF;

    IF EXISTS (
      SELECT 1
      FROM public.milestone_assessment_prompt_outcome_mappings AS outcome_mapping
      WHERE outcome_mapping.task_mapping_id = NEW.id
        AND outcome_mapping.mapping_status <> 'direct'
    ) THEN
      RAISE EXCEPTION USING ERRCODE = '55000', MESSAGE = 'milestone_assessment_contains_unreviewed_prompt_mapping';
    END IF;
  END IF;

  RETURN NEW;
END;
$$;

ALTER FUNCTION private.validate_milestone_assessment_task_mapping() OWNER TO postgres;
REVOKE ALL ON FUNCTION private.validate_milestone_assessment_task_mapping() FROM PUBLIC, anon, authenticated;

CREATE TRIGGER milestone_assessment_task_mappings_validate
  BEFORE INSERT OR UPDATE ON public.milestone_assessment_task_mappings
  FOR EACH ROW EXECUTE FUNCTION private.validate_milestone_assessment_task_mapping();

CREATE OR REPLACE FUNCTION private.prevent_milestone_assessment_task_mapping_mutation()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
BEGIN
  IF OLD.review_state IN ('approved', 'unmapped') THEN
    RAISE EXCEPTION USING ERRCODE = '55000', MESSAGE = 'milestone_assessment_task_mapping_immutable';
  END IF;
  IF TG_OP = 'DELETE' THEN
    RETURN OLD;
  END IF;
  RETURN NEW;
END;
$$;

ALTER FUNCTION private.prevent_milestone_assessment_task_mapping_mutation() OWNER TO postgres;
REVOKE ALL ON FUNCTION private.prevent_milestone_assessment_task_mapping_mutation() FROM PUBLIC, anon, authenticated;

CREATE TRIGGER milestone_assessment_task_mappings_immutable
  BEFORE UPDATE OR DELETE ON public.milestone_assessment_task_mappings
  FOR EACH ROW EXECUTE FUNCTION private.prevent_milestone_assessment_task_mapping_mutation();

CREATE OR REPLACE FUNCTION private.validate_milestone_assessment_prompt_mapping()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
DECLARE
  parent_state text;
  parent_assessment_code text;
  route_state text;
  cycle_state text;
  unit_state text;
  outcome_state text;
  outcome_reviewer uuid;
  outcome_reviewed_at timestamptz;
  outcome_is_listening boolean;
BEGIN
  IF TG_OP = 'DELETE' THEN
    SELECT mapping.review_state, mapping.assessment_code
      INTO parent_state, parent_assessment_code
    FROM public.milestone_assessment_task_mappings AS mapping
    WHERE mapping.id = OLD.task_mapping_id;
  ELSE
    SELECT mapping.review_state, mapping.assessment_code
      INTO parent_state, parent_assessment_code
    FROM public.milestone_assessment_task_mappings AS mapping
    WHERE mapping.id = NEW.task_mapping_id;
  END IF;

  IF parent_state IN ('approved', 'unmapped') THEN
    RAISE EXCEPTION USING ERRCODE = '55000', MESSAGE = 'milestone_assessment_task_mapping_immutable';
  END IF;

  IF TG_OP <> 'DELETE' AND NEW.mapping_status = 'direct' THEN
    SELECT route.review_state, cycle.release_state,
           unit.release_state, outcome.mapping_status,
           outcome.reviewed_by, outcome.reviewed_at, outcome.is_listening_outcome
      INTO route_state, cycle_state, unit_state, outcome_state,
           outcome_reviewer, outcome_reviewed_at, outcome_is_listening
    FROM public.curriculum_route_versions AS route
    JOIN public.milestone_cycle_versions AS cycle
      ON cycle.route_version_id = route.id
    JOIN public.curriculum_unit_versions AS unit
      ON unit.route_version_id = route.id
    JOIN public.curriculum_unit_outcome_mappings AS outcome
      ON outcome.curriculum_unit_version_id = unit.id
    WHERE route.id = NEW.route_version_id
      AND cycle.id = NEW.milestone_cycle_version_id
      AND unit.id = NEW.curriculum_unit_version_id
      AND outcome.id = NEW.curriculum_unit_outcome_mapping_id;

    IF NOT FOUND
      OR route_state <> 'verified'
      OR cycle_state <> 'published'
      OR unit_state <> 'published'
      OR outcome_state <> 'direct'
      OR outcome_reviewer IS NULL
      OR outcome_reviewed_at IS NULL
      OR NEW.reviewed_by IS NULL
      OR NEW.reviewed_at IS NULL THEN
      RAISE EXCEPTION USING ERRCODE = '55000', MESSAGE = 'milestone_assessment_prompt_requires_direct_published_outcome';
    END IF;

    IF outcome_is_listening AND parent_assessment_code <> 'SA3' THEN
      RAISE EXCEPTION USING ERRCODE = '55000', MESSAGE = 'milestone_assessment_listening_sa3_only';
    END IF;
  END IF;

  IF TG_OP = 'DELETE' THEN
    RETURN OLD;
  END IF;
  RETURN NEW;
END;
$$;

ALTER FUNCTION private.validate_milestone_assessment_prompt_mapping() OWNER TO postgres;
REVOKE ALL ON FUNCTION private.validate_milestone_assessment_prompt_mapping() FROM PUBLIC, anon, authenticated;

CREATE TRIGGER milestone_assessment_prompt_mappings_validate
  BEFORE INSERT OR UPDATE OR DELETE ON public.milestone_assessment_prompt_outcome_mappings
  FOR EACH ROW EXECUTE FUNCTION private.validate_milestone_assessment_prompt_mapping();

CREATE TABLE private.milestone_assessment_attempt_links (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  attempt_id uuid NOT NULL,
  task_mapping_id uuid NOT NULL,
  learner_id uuid NOT NULL,
  enrolment_id uuid NOT NULL,
  task_version_id uuid NOT NULL,
  route_version_id uuid NOT NULL,
  milestone_cycle_version_id uuid NOT NULL,
  milestone_segment_id uuid NOT NULL,
  idempotency_key uuid NOT NULL,
  linked_at timestamptz NOT NULL DEFAULT clock_timestamp(),
  CONSTRAINT milestone_assessment_attempt_links_attempt_unique UNIQUE (attempt_id),
  CONSTRAINT milestone_assessment_attempt_links_idempotency_unique UNIQUE (learner_id, idempotency_key),
  FOREIGN KEY (attempt_id, learner_id, task_version_id)
    REFERENCES public.attempts(id, learner_id, task_version_id)
    ON DELETE RESTRICT,
  FOREIGN KEY (enrolment_id, learner_id)
    REFERENCES public.course_enrolments(id, learner_id)
    ON DELETE RESTRICT,
  FOREIGN KEY (
    task_mapping_id,
    task_version_id,
    route_version_id,
    milestone_cycle_version_id,
    milestone_segment_id
  )
    REFERENCES public.milestone_assessment_task_mappings (
      id,
      task_version_id,
      route_version_id,
      milestone_cycle_version_id,
      milestone_segment_id
    )
    ON DELETE RESTRICT
);

CREATE INDEX milestone_assessment_attempt_links_learner_idx
  ON private.milestone_assessment_attempt_links (learner_id, linked_at DESC);

ALTER TABLE public.milestone_assessment_task_mappings ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.milestone_assessment_prompt_outcome_mappings ENABLE ROW LEVEL SECURITY;
ALTER TABLE private.milestone_assessment_attempt_links ENABLE ROW LEVEL SECURITY;

REVOKE ALL ON public.milestone_assessment_task_mappings,
  public.milestone_assessment_prompt_outcome_mappings
FROM PUBLIC, anon, authenticated;
GRANT SELECT ON public.milestone_assessment_task_mappings,
  public.milestone_assessment_prompt_outcome_mappings TO authenticated;
REVOKE ALL ON private.milestone_assessment_attempt_links FROM PUBLIC, anon, authenticated;

CREATE POLICY milestone_assessment_task_mappings_select_approved
  ON public.milestone_assessment_task_mappings
  FOR SELECT TO authenticated
  USING (
    (
      review_state = 'approved'
      AND EXISTS (
        SELECT 1
        FROM public.curriculum_route_versions AS route
        JOIN public.milestone_cycle_versions AS cycle
          ON cycle.route_version_id = route.id
        WHERE route.id = public.milestone_assessment_task_mappings.route_version_id
          AND route.review_state = 'verified'
          AND cycle.id = public.milestone_assessment_task_mappings.milestone_cycle_version_id
          AND cycle.release_state = 'published'
          AND private.current_account_is_active()
          AND private.current_user_has_role('student'::public.app_role)
          AND EXISTS (
            SELECT 1 FROM public.course_enrolments AS enrolment
            WHERE enrolment.learner_id = (SELECT auth.uid())
              AND enrolment.pathway_id = route.route_key
              AND enrolment.status = 'active'
          )
      )
    )
    OR (
      private.current_account_is_active()
      AND private.current_user_has_role('owner'::public.app_role)
      AND coalesce(auth.jwt() ->> 'aal', 'aal1') = 'aal2'
    )
  );

CREATE POLICY milestone_assessment_prompt_mappings_select_approved
  ON public.milestone_assessment_prompt_outcome_mappings
  FOR SELECT TO authenticated
  USING (
    (
      mapping_status = 'direct'
      AND EXISTS (
        SELECT 1
        FROM public.milestone_assessment_task_mappings AS task_mapping
        JOIN public.curriculum_route_versions AS route
          ON route.id = task_mapping.route_version_id
        JOIN public.milestone_cycle_versions AS cycle
          ON cycle.id = task_mapping.milestone_cycle_version_id
        WHERE task_mapping.id = public.milestone_assessment_prompt_outcome_mappings.task_mapping_id
          AND task_mapping.review_state = 'approved'
          AND route.review_state = 'verified'
          AND cycle.release_state = 'published'
          AND private.current_account_is_active()
          AND private.current_user_has_role('student'::public.app_role)
          AND EXISTS (
            SELECT 1 FROM public.course_enrolments AS enrolment
            WHERE enrolment.learner_id = (SELECT auth.uid())
              AND enrolment.pathway_id = route.route_key
              AND enrolment.status = 'active'
          )
      )
    )
    OR (
      private.current_account_is_active()
      AND private.current_user_has_role('owner'::public.app_role)
      AND coalesce(auth.jwt() ->> 'aal', 'aal1') = 'aal2'
    )
  );

CREATE OR REPLACE FUNCTION private.prevent_milestone_assessment_attempt_link_mutation()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
BEGIN
  RAISE EXCEPTION USING ERRCODE = '42501', MESSAGE = 'milestone_assessment_attempt_link_immutable';
  RETURN NULL;
END;
$$;

ALTER FUNCTION private.prevent_milestone_assessment_attempt_link_mutation() OWNER TO postgres;
REVOKE ALL ON FUNCTION private.prevent_milestone_assessment_attempt_link_mutation() FROM PUBLIC, anon, authenticated;

CREATE TRIGGER milestone_assessment_attempt_links_immutable
  BEFORE UPDATE OR DELETE ON private.milestone_assessment_attempt_links
  FOR EACH ROW EXECUTE FUNCTION private.prevent_milestone_assessment_attempt_link_mutation();

CREATE OR REPLACE FUNCTION public.link_milestone_assessment_attempt(
  p_attempt_id uuid,
  p_course_enrolment_id uuid,
  p_task_mapping_id uuid,
  p_idempotency_key uuid
)
RETURNS TABLE (
  link_id uuid,
  attempt_id uuid,
  task_mapping_id uuid,
  learner_id uuid,
  task_version_id uuid,
  milestone_cycle_version_id uuid,
  milestone_segment_id uuid,
  linked_at timestamptz,
  is_replay boolean
)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
DECLARE
  actor_id uuid := auth.uid();
  selected_attempt public.attempts%ROWTYPE;
  selected_mapping public.milestone_assessment_task_mappings%ROWTYPE;
  selected_enrolment public.course_enrolments%ROWTYPE;
  selected_link private.milestone_assessment_attempt_links%ROWTYPE;
  created_link private.milestone_assessment_attempt_links%ROWTYPE;
  selected_route_key text;
  all_required_units_complete boolean;
  required_unit_count integer;
BEGIN
  IF actor_id IS NULL
    OR NOT private.current_account_is_active()
    OR NOT private.current_user_has_role('student'::public.app_role) THEN
    RAISE EXCEPTION USING ERRCODE = '42501', MESSAGE = 'milestone_assessment_attempt_link_forbidden';
  END IF;

  IF p_attempt_id IS NULL
    OR p_course_enrolment_id IS NULL
    OR p_task_mapping_id IS NULL
    OR p_idempotency_key IS NULL THEN
    RAISE EXCEPTION USING ERRCODE = '22023', MESSAGE = 'invalid_milestone_assessment_attempt_link';
  END IF;

  PERFORM pg_catalog.pg_advisory_xact_lock(
    pg_catalog.hashtextextended(actor_id::text || ':' || p_idempotency_key::text, 0)
  );

  -- An exact retry returns the original immutable link even if the learner has
  -- since submitted the task or the enrolment has moved to a later state.
  SELECT link.* INTO selected_link
  FROM private.milestone_assessment_attempt_links AS link
  WHERE link.learner_id = actor_id
    AND link.idempotency_key = p_idempotency_key
  FOR UPDATE;

  IF FOUND THEN
    IF selected_link.attempt_id = p_attempt_id
      AND selected_link.task_mapping_id = p_task_mapping_id
      AND selected_link.enrolment_id = p_course_enrolment_id THEN
      RETURN QUERY SELECT selected_link.id, selected_link.attempt_id,
        selected_link.task_mapping_id, selected_link.learner_id,
        selected_link.task_version_id, selected_link.milestone_cycle_version_id,
        selected_link.milestone_segment_id, selected_link.linked_at, true;
      RETURN;
    END IF;
    RAISE EXCEPTION USING ERRCODE = 'P0001', MESSAGE = 'milestone_assessment_attempt_link_idempotency_conflict';
  END IF;

  SELECT attempt.* INTO selected_attempt
  FROM public.attempts AS attempt
  WHERE attempt.id = p_attempt_id
    AND attempt.learner_id = actor_id
  FOR UPDATE;

  IF NOT FOUND THEN
    RAISE EXCEPTION USING ERRCODE = 'P0002', MESSAGE = 'attempt_not_found';
  END IF;

  SELECT task_mapping.* INTO selected_mapping
  FROM public.milestone_assessment_task_mappings AS task_mapping
  WHERE task_mapping.id = p_task_mapping_id
    AND task_mapping.review_state = 'approved'
  FOR SHARE;

  IF NOT FOUND THEN
    RAISE EXCEPTION USING ERRCODE = 'P0002', MESSAGE = 'milestone_assessment_task_mapping_not_found';
  END IF;

  IF selected_attempt.task_version_id IS DISTINCT FROM selected_mapping.task_version_id THEN
    RAISE EXCEPTION USING ERRCODE = 'P0001', MESSAGE = 'milestone_assessment_task_version_mismatch';
  END IF;

  SELECT enrolment.* INTO selected_enrolment
  FROM public.course_enrolments AS enrolment
  WHERE enrolment.id = p_course_enrolment_id
    AND enrolment.learner_id = actor_id
    AND enrolment.status = 'active'
  FOR SHARE;

  IF NOT FOUND THEN
    RAISE EXCEPTION USING ERRCODE = '42501', MESSAGE = 'milestone_assessment_attempt_link_forbidden';
  END IF;

  SELECT route.route_key INTO selected_route_key
  FROM public.curriculum_route_versions AS route
  JOIN public.milestone_cycle_versions AS cycle
    ON cycle.route_version_id = route.id
  JOIN public.milestone_segments AS segment
    ON segment.milestone_cycle_version_id = cycle.id
   AND segment.route_version_id = route.id
  JOIN public.task_versions AS task
    ON task.id = selected_mapping.task_version_id
  WHERE route.id = selected_mapping.route_version_id
    AND cycle.id = selected_mapping.milestone_cycle_version_id
    AND segment.id = selected_mapping.milestone_segment_id
    AND route.review_state = 'verified'
    AND cycle.release_state = 'published'
    AND task.release_state = 'published'
    AND task.response_mode = 'typed'
    AND task.pathway_id = route.route_key
    AND selected_enrolment.pathway_id = route.route_key;

  IF selected_route_key IS NULL THEN
    RAISE EXCEPTION USING ERRCODE = '42501', MESSAGE = 'milestone_assessment_attempt_link_forbidden';
  END IF;

  IF selected_attempt.status <> 'in_progress' OR selected_attempt.submitted_at IS NOT NULL THEN
    RAISE EXCEPTION USING ERRCODE = 'P0001', MESSAGE = 'milestone_assessment_attempt_not_in_progress';
  END IF;

  SELECT count(*)::integer INTO required_unit_count
  FROM public.milestone_unit_memberships AS membership
  WHERE membership.milestone_cycle_version_id = selected_mapping.milestone_cycle_version_id
    AND membership.milestone_segment_id = selected_mapping.milestone_segment_id
    AND membership.is_required;

  IF required_unit_count = 0 THEN
    RAISE EXCEPTION USING ERRCODE = 'P0001', MESSAGE = 'milestone_segment_has_no_required_units';
  END IF;

  SELECT NOT EXISTS (
    SELECT 1
    FROM public.milestone_unit_memberships AS membership
    WHERE membership.milestone_cycle_version_id = selected_mapping.milestone_cycle_version_id
      AND membership.milestone_segment_id = selected_mapping.milestone_segment_id
      AND membership.is_required
      AND NOT EXISTS (
        SELECT 1
        FROM public.learner_unit_progress AS progress
        WHERE progress.enrolment_id = selected_enrolment.id
          AND progress.learner_id = actor_id
          AND progress.milestone_unit_membership_id = membership.id
          AND progress.route_version_id = selected_mapping.route_version_id
          AND progress.status = 'completed'
          AND progress.completed_at IS NOT NULL
      )
  ) INTO all_required_units_complete;

  IF NOT all_required_units_complete THEN
    RAISE EXCEPTION USING ERRCODE = 'P0001', MESSAGE = 'milestone_segment_units_incomplete';
  END IF;

  IF EXISTS (
    SELECT 1 FROM private.milestone_assessment_attempt_links AS link
    WHERE link.attempt_id = p_attempt_id
  ) THEN
    RAISE EXCEPTION USING ERRCODE = 'P0001', MESSAGE = 'milestone_assessment_attempt_link_conflict';
  END IF;

  INSERT INTO private.milestone_assessment_attempt_links (
    attempt_id, task_mapping_id, learner_id, enrolment_id, task_version_id,
    route_version_id, milestone_cycle_version_id, milestone_segment_id, idempotency_key
  )
  VALUES (
    selected_attempt.id, selected_mapping.id, actor_id, selected_enrolment.id,
    selected_mapping.task_version_id, selected_mapping.route_version_id,
    selected_mapping.milestone_cycle_version_id, selected_mapping.milestone_segment_id,
    p_idempotency_key
  )
  RETURNING * INTO created_link;

  INSERT INTO private.security_audit_events (
    actor_id, action, target_type, target_id, outcome, reason_category
  )
  VALUES (
    actor_id,
    'student_milestone_assessment_attempt_linked',
    'milestone_assessment_attempt_link',
    created_link.id,
    'success',
    'learner_action'
  );

  RETURN QUERY SELECT created_link.id, created_link.attempt_id,
    created_link.task_mapping_id, created_link.learner_id,
    created_link.task_version_id, created_link.milestone_cycle_version_id,
    created_link.milestone_segment_id, created_link.linked_at, false;
END;
$$;

ALTER FUNCTION public.link_milestone_assessment_attempt(uuid, uuid, uuid, uuid) OWNER TO postgres;
REVOKE ALL ON FUNCTION public.link_milestone_assessment_attempt(uuid, uuid, uuid, uuid)
  FROM PUBLIC, anon, service_role;
GRANT EXECUTE ON FUNCTION public.link_milestone_assessment_attempt(uuid, uuid, uuid, uuid)
  TO authenticated;

COMMENT ON TABLE public.milestone_assessment_task_mappings IS
  'One exact published task version is assigned to one SA segment within one cycle version. PA is not an SA mapping placement.';
COMMENT ON TABLE public.milestone_assessment_prompt_outcome_mappings IS
  'Every prompt in an approved SA task version has reviewed direct mapping to a source outcome from a unit in the same milestone segment.';
COMMENT ON TABLE private.milestone_assessment_attempt_links IS
  'Immutable private lineage from a learner attempt to its exact approved SA task mapping, active enrolment, route, cycle and segment. Link is permitted only after all required units in that segment are complete.';
COMMENT ON FUNCTION public.link_milestone_assessment_attempt(uuid, uuid, uuid, uuid) IS
  'Links an in-progress learner-owned typed SA attempt to one approved prompt-mapped task and exact milestone cycle/segment. Rechecks active route enrolment and all required unit completion; one-to-one and idempotent.';
