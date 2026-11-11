-- Phase 2: versioned curriculum route, unit and M1-M3 progression foundation.
-- No live route or curriculum content is seeded by this migration. A school-specific
-- MYP Year 4 unit sequence must be academically supplied and reviewed before use.

ALTER TABLE public.course_enrolments
  ADD CONSTRAINT course_enrolments_id_learner_identity_unique
  UNIQUE (id, learner_id);

CREATE TABLE public.curriculum_route_versions (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  route_key text NOT NULL CHECK (char_length(btrim(route_key)) BETWEEN 1 AND 120),
  version integer NOT NULL CHECK (version > 0),
  awarding_body text NOT NULL CHECK (awarding_body IN ('IB', 'Cambridge', 'CBSE', 'TEST')),
  programme_code text NOT NULL CHECK (char_length(btrim(programme_code)) BETWEEN 1 AND 80),
  subject_code text NOT NULL CHECK (char_length(btrim(subject_code)) BETWEEN 1 AND 80),
  course_code text NOT NULL CHECK (char_length(btrim(course_code)) BETWEEN 1 AND 120),
  level_code text NOT NULL CHECK (char_length(btrim(level_code)) BETWEEN 1 AND 80),
  level_label text NOT NULL CHECK (char_length(btrim(level_label)) BETWEEN 1 AND 160),
  academic_session text NOT NULL CHECK (char_length(btrim(academic_session)) BETWEEN 1 AND 80),
  syllabus_edition text NOT NULL CHECK (char_length(btrim(syllabus_edition)) BETWEEN 1 AND 160),
  official_source_title text,
  official_source_url text,
  source_checked_at timestamptz,
  review_state text NOT NULL DEFAULT 'draft'
    CHECK (review_state IN ('draft', 'pending_review', 'verified', 'retired')),
  verified_by uuid REFERENCES auth.users(id) ON DELETE RESTRICT,
  verified_at timestamptz,
  created_at timestamptz NOT NULL DEFAULT now(),
  UNIQUE (route_key, version),
  UNIQUE (id, route_key),
  CHECK (
    (review_state = 'verified'
      AND official_source_title IS NOT NULL
      AND char_length(btrim(official_source_title)) BETWEEN 1 AND 240
      AND official_source_url IS NOT NULL
      AND official_source_url LIKE 'https://%'
      AND source_checked_at IS NOT NULL
      AND verified_by IS NOT NULL
      AND verified_at IS NOT NULL)
    OR (review_state <> 'verified'
      AND verified_by IS NULL
      AND verified_at IS NULL)
  )
);

CREATE INDEX curriculum_route_versions_lookup_idx
  ON public.curriculum_route_versions (route_key, version DESC);

CREATE TABLE public.curriculum_unit_versions (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  route_version_id uuid NOT NULL
    REFERENCES public.curriculum_route_versions(id) ON DELETE RESTRICT,
  unit_code text NOT NULL CHECK (char_length(btrim(unit_code)) BETWEEN 1 AND 80),
  version integer NOT NULL CHECK (version > 0),
  sequence_number integer NOT NULL CHECK (sequence_number > 0),
  title text NOT NULL CHECK (char_length(btrim(title)) BETWEEN 1 AND 240),
  learning_objective_summary text NOT NULL
    CHECK (char_length(btrim(learning_objective_summary)) BETWEEN 1 AND 2000),
  release_state text NOT NULL DEFAULT 'draft'
    CHECK (release_state IN ('draft', 'approved', 'published', 'retired')),
  created_at timestamptz NOT NULL DEFAULT now(),
  UNIQUE (route_version_id, unit_code, version),
  UNIQUE (id, route_version_id)
);

CREATE INDEX curriculum_unit_versions_route_sequence_idx
  ON public.curriculum_unit_versions (route_version_id, sequence_number);

CREATE TABLE public.curriculum_unit_outcome_mappings (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  curriculum_unit_version_id uuid NOT NULL
    REFERENCES public.curriculum_unit_versions(id) ON DELETE RESTRICT,
  outcome_reference text NOT NULL
    CHECK (char_length(btrim(outcome_reference)) BETWEEN 1 AND 120),
  outcome_title text NOT NULL CHECK (char_length(btrim(outcome_title)) BETWEEN 1 AND 300),
  source_locator text NOT NULL CHECK (char_length(btrim(source_locator)) BETWEEN 1 AND 240),
  mapping_status text NOT NULL DEFAULT 'pending'
    CHECK (mapping_status IN ('pending', 'direct', 'supporting', 'unmapped')),
  mapping_rationale text NOT NULL
    CHECK (char_length(btrim(mapping_rationale)) BETWEEN 1 AND 2000),
  reviewed_by uuid REFERENCES auth.users(id) ON DELETE RESTRICT,
  reviewed_at timestamptz,
  created_at timestamptz NOT NULL DEFAULT now(),
  UNIQUE (curriculum_unit_version_id, outcome_reference),
  CHECK (
    mapping_status NOT IN ('direct', 'supporting')
    OR (reviewed_by IS NOT NULL AND reviewed_at IS NOT NULL)
  )
);

CREATE INDEX curriculum_unit_outcome_mappings_unit_idx
  ON public.curriculum_unit_outcome_mappings (curriculum_unit_version_id, mapping_status);

CREATE TABLE public.milestone_cycle_versions (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  route_version_id uuid NOT NULL
    REFERENCES public.curriculum_route_versions(id) ON DELETE RESTRICT,
  version integer NOT NULL CHECK (version > 0),
  release_state text NOT NULL DEFAULT 'draft'
    CHECK (release_state IN ('draft', 'approved', 'published', 'retired')),
  created_at timestamptz NOT NULL DEFAULT now(),
  UNIQUE (route_version_id, version),
  UNIQUE (id, route_version_id)
);

CREATE TABLE public.milestone_segments (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  milestone_cycle_version_id uuid NOT NULL,
  route_version_id uuid NOT NULL,
  segment_number smallint NOT NULL CHECK (segment_number BETWEEN 1 AND 3),
  title text NOT NULL CHECK (char_length(btrim(title)) BETWEEN 1 AND 160),
  created_at timestamptz NOT NULL DEFAULT now(),
  UNIQUE (milestone_cycle_version_id, segment_number),
  UNIQUE (id, milestone_cycle_version_id, route_version_id),
  FOREIGN KEY (milestone_cycle_version_id, route_version_id)
    REFERENCES public.milestone_cycle_versions(id, route_version_id)
    ON DELETE RESTRICT
);

CREATE TABLE public.milestone_unit_memberships (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  milestone_cycle_version_id uuid NOT NULL,
  milestone_segment_id uuid NOT NULL,
  curriculum_unit_version_id uuid NOT NULL,
  route_version_id uuid NOT NULL,
  sequence_number integer NOT NULL CHECK (sequence_number > 0),
  is_required boolean NOT NULL DEFAULT true,
  created_at timestamptz NOT NULL DEFAULT now(),
  FOREIGN KEY (milestone_cycle_version_id, route_version_id)
    REFERENCES public.milestone_cycle_versions(id, route_version_id)
    ON DELETE RESTRICT,
  FOREIGN KEY (milestone_segment_id, milestone_cycle_version_id, route_version_id)
    REFERENCES public.milestone_segments(id, milestone_cycle_version_id, route_version_id)
    ON DELETE RESTRICT,
  FOREIGN KEY (curriculum_unit_version_id, route_version_id)
    REFERENCES public.curriculum_unit_versions(id, route_version_id)
    ON DELETE RESTRICT,
  UNIQUE (milestone_cycle_version_id, curriculum_unit_version_id),
  UNIQUE (milestone_segment_id, sequence_number),
  UNIQUE (id, route_version_id)
);

CREATE INDEX milestone_unit_memberships_segment_idx
  ON public.milestone_unit_memberships (milestone_segment_id, sequence_number);

CREATE TABLE public.learner_unit_progress (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  enrolment_id uuid NOT NULL,
  learner_id uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  milestone_unit_membership_id uuid NOT NULL,
  route_version_id uuid NOT NULL,
  status text NOT NULL CHECK (status IN ('in_progress', 'completed')),
  started_at timestamptz NOT NULL DEFAULT clock_timestamp(),
  completed_at timestamptz,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  FOREIGN KEY (enrolment_id, learner_id)
    REFERENCES public.course_enrolments(id, learner_id) ON DELETE CASCADE,
  FOREIGN KEY (milestone_unit_membership_id, route_version_id)
    REFERENCES public.milestone_unit_memberships(id, route_version_id)
    ON DELETE RESTRICT,
  UNIQUE (enrolment_id, milestone_unit_membership_id),
  CHECK (
    (status = 'in_progress' AND completed_at IS NULL)
    OR (status = 'completed' AND completed_at IS NOT NULL AND completed_at >= started_at)
  )
);

CREATE INDEX learner_unit_progress_learner_idx
  ON public.learner_unit_progress (learner_id, updated_at DESC);

CREATE OR REPLACE FUNCTION private.prevent_published_curriculum_snapshot_mutation()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
DECLARE
  protected_state boolean := false;
  parent_state text;
BEGIN
  IF TG_OP = 'INSERT' THEN
    CASE TG_TABLE_NAME
      WHEN 'curriculum_unit_outcome_mappings' THEN
        SELECT unit.release_state INTO parent_state
        FROM public.curriculum_unit_versions AS unit
        WHERE unit.id = NEW.curriculum_unit_version_id;
        protected_state := parent_state IN ('approved', 'published', 'retired');
      WHEN 'milestone_segments' THEN
        SELECT cycle.release_state INTO parent_state
        FROM public.milestone_cycle_versions AS cycle
        WHERE cycle.id = NEW.milestone_cycle_version_id;
        protected_state := parent_state IN ('approved', 'published', 'retired');
      WHEN 'milestone_unit_memberships' THEN
        SELECT cycle.release_state INTO parent_state
        FROM public.milestone_cycle_versions AS cycle
        WHERE cycle.id = NEW.milestone_cycle_version_id;
        protected_state := parent_state IN ('approved', 'published', 'retired');
      ELSE
        RAISE EXCEPTION USING ERRCODE = '22023', MESSAGE = 'unsupported_curriculum_snapshot_insert';
    END CASE;
  ELSE
    CASE TG_TABLE_NAME
      WHEN 'curriculum_route_versions' THEN
        protected_state := OLD.review_state IN ('verified', 'retired');
      WHEN 'curriculum_unit_versions' THEN
        protected_state := OLD.release_state IN ('approved', 'published', 'retired');
      WHEN 'curriculum_unit_outcome_mappings' THEN
        SELECT unit.release_state INTO parent_state
        FROM public.curriculum_unit_versions AS unit
        WHERE unit.id = OLD.curriculum_unit_version_id;
        protected_state := parent_state IN ('approved', 'published', 'retired');
      WHEN 'milestone_cycle_versions' THEN
        protected_state := OLD.release_state IN ('approved', 'published', 'retired');
      WHEN 'milestone_segments' THEN
        SELECT cycle.release_state INTO parent_state
        FROM public.milestone_cycle_versions AS cycle
        WHERE cycle.id = OLD.milestone_cycle_version_id;
        protected_state := parent_state IN ('approved', 'published', 'retired');
      WHEN 'milestone_unit_memberships' THEN
        SELECT cycle.release_state INTO parent_state
        FROM public.milestone_cycle_versions AS cycle
        WHERE cycle.id = OLD.milestone_cycle_version_id;
        protected_state := parent_state IN ('approved', 'published', 'retired');
      ELSE
        RAISE EXCEPTION USING ERRCODE = '22023', MESSAGE = 'unsupported_curriculum_snapshot_table';
    END CASE;
  END IF;

  IF protected_state THEN
    RAISE EXCEPTION USING ERRCODE = '55000', MESSAGE = 'published_curriculum_snapshot_immutable';
  END IF;

  IF TG_OP = 'DELETE' THEN
    RETURN OLD;
  END IF;
  RETURN NEW;
END;
$$;

ALTER FUNCTION private.prevent_published_curriculum_snapshot_mutation() OWNER TO postgres;
REVOKE ALL ON FUNCTION private.prevent_published_curriculum_snapshot_mutation() FROM PUBLIC, anon, authenticated;

CREATE TRIGGER curriculum_route_versions_immutable
  BEFORE UPDATE OR DELETE ON public.curriculum_route_versions
  FOR EACH ROW EXECUTE FUNCTION private.prevent_published_curriculum_snapshot_mutation();

CREATE OR REPLACE FUNCTION private.validate_curriculum_unit_release()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $
DECLARE
  route_state text;
BEGIN
  IF NEW.release_state IN ('approved', 'published')
    AND (TG_OP = 'INSERT' OR OLD.release_state NOT IN ('approved', 'published', 'retired')) THEN
    SELECT route.review_state INTO route_state
    FROM public.curriculum_route_versions AS route
    WHERE route.id = NEW.route_version_id;

    IF route_state IS DISTINCT FROM 'verified' THEN
      RAISE EXCEPTION USING ERRCODE = '55000', MESSAGE = 'curriculum_unit_requires_verified_route';
    END IF;

    IF NOT EXISTS (
      SELECT 1
      FROM public.curriculum_unit_outcome_mappings AS mapping
      WHERE mapping.curriculum_unit_version_id = NEW.id
        AND mapping.mapping_status = 'direct'
        AND mapping.reviewed_by IS NOT NULL
        AND mapping.reviewed_at IS NOT NULL
    ) THEN
      RAISE EXCEPTION USING ERRCODE = '55000', MESSAGE = 'curriculum_unit_requires_direct_outcome';
    END IF;
  END IF;
  RETURN NEW;
END;
$;

ALTER FUNCTION private.validate_curriculum_unit_release() OWNER TO postgres;
REVOKE ALL ON FUNCTION private.validate_curriculum_unit_release() FROM PUBLIC, anon, authenticated;

CREATE TRIGGER curriculum_unit_versions_validate_release
  BEFORE INSERT OR UPDATE ON public.curriculum_unit_versions
  FOR EACH ROW EXECUTE FUNCTION private.validate_curriculum_unit_release();

CREATE OR REPLACE FUNCTION private.prevent_unit_insert_after_route_verification()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $
DECLARE
  route_state text;
BEGIN
  SELECT route.review_state INTO route_state
  FROM public.curriculum_route_versions AS route
  WHERE route.id = NEW.route_version_id;

  IF route_state = 'verified' THEN
    RAISE EXCEPTION USING ERRCODE = '55000', MESSAGE = 'curriculum_route_units_locked';
  END IF;
  RETURN NEW;
END;
$;

ALTER FUNCTION private.prevent_unit_insert_after_route_verification() OWNER TO postgres;
REVOKE ALL ON FUNCTION private.prevent_unit_insert_after_route_verification() FROM PUBLIC, anon, authenticated;

CREATE TRIGGER curriculum_unit_versions_route_lock
  BEFORE INSERT ON public.curriculum_unit_versions
  FOR EACH ROW EXECUTE FUNCTION private.prevent_unit_insert_after_route_verification();

CREATE TRIGGER curriculum_unit_versions_immutable
  BEFORE UPDATE OR DELETE ON public.curriculum_unit_versions
  FOR EACH ROW EXECUTE FUNCTION private.prevent_published_curriculum_snapshot_mutation();

CREATE TRIGGER curriculum_unit_outcome_mappings_immutable
  BEFORE INSERT OR UPDATE OR DELETE ON public.curriculum_unit_outcome_mappings
  FOR EACH ROW EXECUTE FUNCTION private.prevent_published_curriculum_snapshot_mutation();

CREATE OR REPLACE FUNCTION private.validate_milestone_cycle_release()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $
DECLARE
  route_state text;
  segment_count integer;
BEGIN
  IF NEW.release_state IN ('approved', 'published')
    AND OLD.release_state NOT IN ('approved', 'published', 'retired') THEN
    SELECT route.review_state INTO route_state
    FROM public.curriculum_route_versions AS route
    WHERE route.id = NEW.route_version_id;

    IF route_state IS DISTINCT FROM 'verified' THEN
      RAISE EXCEPTION USING ERRCODE = '55000', MESSAGE = 'milestone_cycle_requires_verified_route';
    END IF;

    SELECT count(*)::integer INTO segment_count
    FROM public.milestone_segments AS segment
    WHERE segment.milestone_cycle_version_id = NEW.id;

    IF segment_count <> 3 THEN
      RAISE EXCEPTION USING ERRCODE = '55000', MESSAGE = 'milestone_cycle_requires_three_segments';
    END IF;

    IF EXISTS (
      SELECT 1
      FROM public.milestone_segments AS segment
      WHERE segment.milestone_cycle_version_id = NEW.id
        AND NOT EXISTS (
          SELECT 1 FROM public.milestone_unit_memberships AS membership
          WHERE membership.milestone_segment_id = segment.id
        )
    ) THEN
      RAISE EXCEPTION USING ERRCODE = '55000', MESSAGE = 'milestone_cycle_requires_units_in_each_segment';
    END IF;

    IF EXISTS (
      SELECT 1
      FROM public.milestone_unit_memberships AS membership
      JOIN public.curriculum_unit_versions AS unit
        ON unit.id = membership.curriculum_unit_version_id
      WHERE membership.milestone_cycle_version_id = NEW.id
        AND (
          unit.release_state <> 'published'
          OR NOT EXISTS (
            SELECT 1
            FROM public.curriculum_unit_outcome_mappings AS mapping
            WHERE mapping.curriculum_unit_version_id = unit.id
              AND mapping.mapping_status = 'direct'
              AND mapping.reviewed_by IS NOT NULL
              AND mapping.reviewed_at IS NOT NULL
          )
        )
    ) THEN
      RAISE EXCEPTION USING ERRCODE = '55000', MESSAGE = 'milestone_cycle_requires_published_directly_mapped_units';
    END IF;
  END IF;
  RETURN NEW;
END;
$;

ALTER FUNCTION private.validate_milestone_cycle_release() OWNER TO postgres;
REVOKE ALL ON FUNCTION private.validate_milestone_cycle_release() FROM PUBLIC, anon, authenticated;

CREATE TRIGGER milestone_cycle_versions_validate_release
  BEFORE INSERT OR UPDATE ON public.milestone_cycle_versions
  FOR EACH ROW EXECUTE FUNCTION private.validate_milestone_cycle_release();

CREATE TRIGGER milestone_cycle_versions_immutable
  BEFORE UPDATE OR DELETE ON public.milestone_cycle_versions
  FOR EACH ROW EXECUTE FUNCTION private.prevent_published_curriculum_snapshot_mutation();

CREATE TRIGGER milestone_segments_immutable
  BEFORE INSERT OR UPDATE OR DELETE ON public.milestone_segments
  FOR EACH ROW EXECUTE FUNCTION private.prevent_published_curriculum_snapshot_mutation();

CREATE TRIGGER milestone_unit_memberships_immutable
  BEFORE INSERT OR UPDATE OR DELETE ON public.milestone_unit_memberships
  FOR EACH ROW EXECUTE FUNCTION private.prevent_published_curriculum_snapshot_mutation();

CREATE TRIGGER learner_unit_progress_set_updated_at
  BEFORE UPDATE ON public.learner_unit_progress
  FOR EACH ROW EXECUTE FUNCTION private.set_updated_at();

ALTER TABLE public.curriculum_route_versions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.curriculum_unit_versions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.curriculum_unit_outcome_mappings ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.milestone_cycle_versions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.milestone_segments ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.milestone_unit_memberships ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.learner_unit_progress ENABLE ROW LEVEL SECURITY;

REVOKE ALL ON public.curriculum_route_versions,
  public.curriculum_unit_versions,
  public.curriculum_unit_outcome_mappings,
  public.milestone_cycle_versions,
  public.milestone_segments,
  public.milestone_unit_memberships,
  public.learner_unit_progress
FROM PUBLIC, anon, authenticated;

GRANT SELECT ON public.curriculum_route_versions,
  public.curriculum_unit_versions,
  public.curriculum_unit_outcome_mappings,
  public.milestone_cycle_versions,
  public.milestone_segments,
  public.milestone_unit_memberships,
  public.learner_unit_progress
TO authenticated;

CREATE POLICY curriculum_route_versions_select_verified
  ON public.curriculum_route_versions
  FOR SELECT TO authenticated
  USING (
    (private.current_account_is_active() AND review_state = 'verified')
    OR (
      private.current_account_is_active()
      AND private.current_user_has_role('owner'::public.app_role)
      AND coalesce(auth.jwt() ->> 'aal', 'aal1') = 'aal2'
    )
  );

CREATE POLICY curriculum_unit_versions_select_published
  ON public.curriculum_unit_versions
  FOR SELECT TO authenticated
  USING (
    (
      release_state = 'published'
      AND EXISTS (
        SELECT 1 FROM public.curriculum_route_versions AS route
        WHERE route.id = route_version_id AND route.review_state = 'verified'
      )
      AND private.current_account_is_active()
    )
    OR (
      private.current_account_is_active()
      AND private.current_user_has_role('owner'::public.app_role)
      AND coalesce(auth.jwt() ->> 'aal', 'aal1') = 'aal2'
    )
  );

CREATE POLICY curriculum_unit_outcome_mappings_select_reviewed
  ON public.curriculum_unit_outcome_mappings
  FOR SELECT TO authenticated
  USING (
    (
      mapping_status IN ('direct', 'supporting')
      AND EXISTS (
        SELECT 1
        FROM public.curriculum_unit_versions AS unit
        JOIN public.curriculum_route_versions AS route
          ON route.id = unit.route_version_id
        WHERE unit.id = curriculum_unit_version_id
          AND unit.release_state = 'published'
          AND route.review_state = 'verified'
      )
      AND private.current_account_is_active()
    )
    OR (
      private.current_account_is_active()
      AND private.current_user_has_role('owner'::public.app_role)
      AND coalesce(auth.jwt() ->> 'aal', 'aal1') = 'aal2'
    )
  );

CREATE POLICY milestone_cycle_versions_select_published
  ON public.milestone_cycle_versions
  FOR SELECT TO authenticated
  USING (
    (
      release_state = 'published'
      AND EXISTS (
        SELECT 1 FROM public.curriculum_route_versions AS route
        WHERE route.id = route_version_id AND route.review_state = 'verified'
      )
      AND private.current_account_is_active()
    )
    OR (
      private.current_account_is_active()
      AND private.current_user_has_role('owner'::public.app_role)
      AND coalesce(auth.jwt() ->> 'aal', 'aal1') = 'aal2'
    )
  );

CREATE POLICY milestone_segments_select_published
  ON public.milestone_segments
  FOR SELECT TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM public.milestone_cycle_versions AS cycle
      WHERE cycle.id = milestone_cycle_version_id AND cycle.release_state = 'published'
    )
    OR (
      private.current_account_is_active()
      AND private.current_user_has_role('owner'::public.app_role)
      AND coalesce(auth.jwt() ->> 'aal', 'aal1') = 'aal2'
    )
  );

CREATE POLICY milestone_unit_memberships_select_published
  ON public.milestone_unit_memberships
  FOR SELECT TO authenticated
  USING (
    (
      EXISTS (
        SELECT 1
        FROM public.milestone_cycle_versions AS cycle
        JOIN public.curriculum_unit_versions AS unit
          ON unit.id = curriculum_unit_version_id
         AND unit.route_version_id = route_version_id
        WHERE cycle.id = milestone_cycle_version_id
          AND cycle.release_state = 'published'
          AND unit.release_state = 'published'
          AND EXISTS (
            SELECT 1 FROM public.curriculum_route_versions AS route
            WHERE route.id = route_version_id AND route.review_state = 'verified'
          )
      )
      AND private.current_account_is_active()
    )
    OR (
      private.current_account_is_active()
      AND private.current_user_has_role('owner'::public.app_role)
      AND coalesce(auth.jwt() ->> 'aal', 'aal1') = 'aal2'
    )
  );

CREATE POLICY learner_unit_progress_select_scoped
  ON public.learner_unit_progress
  FOR SELECT TO authenticated
  USING (
    (
      learner_id = (SELECT auth.uid())
      AND private.current_account_is_active()
      AND private.current_user_has_role('student'::public.app_role)
    )
    OR (
      private.current_account_is_active()
      AND private.can_view_learner(learner_id, 'progress')
    )
    OR (
      private.current_account_is_active()
      AND private.current_user_has_role('owner'::public.app_role)
      AND coalesce(auth.jwt() ->> 'aal', 'aal1') = 'aal2'
    )
  );

CREATE OR REPLACE FUNCTION public.record_learner_unit_progress(
  p_enrolment_id uuid,
  p_milestone_unit_membership_id uuid,
  p_status text
)
RETURNS TABLE (
  progress_id uuid,
  progress_status text,
  started_at timestamptz,
  completed_at timestamptz
)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
DECLARE
  actor_id uuid := auth.uid();
  valid_route_key text;
  progress_time timestamptz := clock_timestamp();
BEGIN
  IF actor_id IS NULL
    OR NOT private.current_account_is_active()
    OR NOT private.current_user_has_role('student'::public.app_role) THEN
    RAISE EXCEPTION USING ERRCODE = '42501', MESSAGE = 'unit_progress_forbidden';
  END IF;

  IF p_status NOT IN ('in_progress', 'completed') THEN
    RAISE EXCEPTION USING ERRCODE = '22023', MESSAGE = 'invalid_unit_progress_status';
  END IF;

  SELECT route.route_key INTO valid_route_key
  FROM public.course_enrolments AS enrolment
  JOIN public.milestone_unit_memberships AS membership
    ON membership.id = p_milestone_unit_membership_id
  JOIN public.milestone_cycle_versions AS cycle
    ON cycle.id = membership.milestone_cycle_version_id
  JOIN public.curriculum_route_versions AS route
    ON route.id = membership.route_version_id
  JOIN public.curriculum_unit_versions AS unit
    ON unit.id = membership.curriculum_unit_version_id
   AND unit.route_version_id = membership.route_version_id
  WHERE enrolment.id = p_enrolment_id
    AND enrolment.learner_id = actor_id
    AND enrolment.pathway_id = route.route_key
    AND enrolment.status = 'active'
    AND route.review_state = 'verified'
    AND cycle.release_state = 'published'
    AND unit.release_state = 'published'
    AND EXISTS (
      SELECT 1
      FROM public.curriculum_unit_outcome_mappings AS outcome_mapping
      WHERE outcome_mapping.curriculum_unit_version_id = unit.id
        AND outcome_mapping.mapping_status = 'direct'
        AND outcome_mapping.reviewed_by IS NOT NULL
        AND outcome_mapping.reviewed_at IS NOT NULL
    );

  IF valid_route_key IS NULL THEN
    RAISE EXCEPTION USING ERRCODE = '42501', MESSAGE = 'unit_progress_forbidden';
  END IF;

  INSERT INTO public.learner_unit_progress (
    enrolment_id, learner_id, milestone_unit_membership_id,
    route_version_id, status, started_at, completed_at
  )
  VALUES (
    p_enrolment_id, actor_id, p_milestone_unit_membership_id,
    (SELECT membership.route_version_id
     FROM public.milestone_unit_memberships AS membership
     WHERE membership.id = p_milestone_unit_membership_id),
    p_status,
    progress_time,
    CASE WHEN p_status = 'completed' THEN progress_time ELSE NULL END
  )
  ON CONFLICT (enrolment_id, milestone_unit_membership_id)
  DO UPDATE SET
    status = CASE
      WHEN public.learner_unit_progress.status = 'completed' THEN 'completed'
      ELSE EXCLUDED.status
    END,
    started_at = coalesce(public.learner_unit_progress.started_at, EXCLUDED.started_at),
    completed_at = coalesce(public.learner_unit_progress.completed_at, EXCLUDED.completed_at),
    updated_at = clock_timestamp();

  RETURN QUERY
  SELECT progress.id, progress.status, progress.started_at, progress.completed_at
  FROM public.learner_unit_progress AS progress
  WHERE progress.enrolment_id = p_enrolment_id
    AND progress.milestone_unit_membership_id = p_milestone_unit_membership_id;
END;
$$;

ALTER FUNCTION public.record_learner_unit_progress(uuid, uuid, text) OWNER TO postgres;
REVOKE ALL ON FUNCTION public.record_learner_unit_progress(uuid, uuid, text) FROM PUBLIC, anon, authenticated;
GRANT EXECUTE ON FUNCTION public.record_learner_unit_progress(uuid, uuid, text) TO authenticated;

COMMENT ON TABLE public.curriculum_route_versions IS
  'Versioned exact learner-route identity and syllabus-source verification; no universal school-local MYP unit sequence is assumed.';
COMMENT ON TABLE public.curriculum_unit_versions IS
  'Versioned units within one exact route version. Published unit snapshots are immutable.';
COMMENT ON TABLE public.curriculum_unit_outcome_mappings IS
  'Route-specific unit-to-official-outcome mappings. Only reviewed DIRECT mappings may support PA/SA inclusion or unit progression.';
COMMENT ON TABLE public.milestone_cycle_versions IS
  'One immutable M1-M3 progression-plan version for one exact curriculum route version.';
COMMENT ON TABLE public.milestone_segments IS
  'The three named milestone segments belonging to one cycle version.';
COMMENT ON TABLE public.milestone_unit_memberships IS
  'Exact route- and cycle-scoped unit membership. A unit version can appear only once in a given M1-M3 cycle.';
COMMENT ON TABLE public.learner_unit_progress IS
  'Learner progress against an exact published milestone-unit membership; updates are monotonic and server-controlled.';
