-- Phase 1B: local-first, synthetic-data identity and role foundation.
-- Application roles are never accepted from browser signup metadata.
CREATE EXTENSION IF NOT EXISTS pgcrypto WITH SCHEMA extensions;

CREATE TYPE public.app_role AS ENUM (
  'student',
  'guardian',
  'grader',
  'admin',
  'owner'
);

CREATE TYPE public.account_status AS ENUM (
  'active',
  'suspended',
  'closed'
);

CREATE TYPE public.guardian_link_status AS ENUM (
  'pending',
  'verified',
  'revoked'
);

CREATE TYPE public.enrolment_status AS ENUM (
  'active',
  'paused',
  'completed',
  'withdrawn'
);

CREATE SCHEMA IF NOT EXISTS private;
REVOKE ALL ON SCHEMA private FROM PUBLIC;
REVOKE ALL ON SCHEMA private FROM anon;
REVOKE ALL ON SCHEMA private FROM authenticated;

CREATE TABLE public.profiles (
  user_id uuid PRIMARY KEY REFERENCES auth.users (id) ON DELETE CASCADE,
  display_name text NOT NULL DEFAULT 'Learner'
    CHECK (char_length(display_name) BETWEEN 1 AND 80),
  account_status public.account_status NOT NULL DEFAULT 'active',
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE public.role_assignments (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL REFERENCES auth.users (id) ON DELETE CASCADE,
  role public.app_role NOT NULL,
  granted_by uuid REFERENCES auth.users (id) ON DELETE SET NULL,
  granted_at timestamptz NOT NULL DEFAULT now(),
  revoked_by uuid REFERENCES auth.users (id) ON DELETE SET NULL,
  revoked_at timestamptz,
  reason text CHECK (reason IS NULL OR char_length(reason) <= 240),
  CHECK (revoked_at IS NULL OR revoked_at >= granted_at)
);

CREATE UNIQUE INDEX role_assignments_one_active_role
  ON public.role_assignments (user_id, role)
  WHERE revoked_at IS NULL;

CREATE INDEX role_assignments_user_active_idx
  ON public.role_assignments (user_id)
  WHERE revoked_at IS NULL;

CREATE TABLE public.guardian_learner_links (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  guardian_id uuid NOT NULL REFERENCES auth.users (id) ON DELETE CASCADE,
  learner_id uuid NOT NULL REFERENCES auth.users (id) ON DELETE CASCADE,
  status public.guardian_link_status NOT NULL DEFAULT 'pending',
  consent_verified_at timestamptz,
  verified_by uuid REFERENCES auth.users (id) ON DELETE SET NULL,
  can_view_profile boolean NOT NULL DEFAULT false,
  can_view_learning_progress boolean NOT NULL DEFAULT false,
  can_view_submissions boolean NOT NULL DEFAULT false,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  CHECK (guardian_id <> learner_id),
  CHECK (
    status <> 'verified'
    OR (consent_verified_at IS NOT NULL AND verified_by IS NOT NULL)
  ),
  UNIQUE (guardian_id, learner_id)
);

CREATE INDEX guardian_learner_links_learner_idx
  ON public.guardian_learner_links (learner_id, status);

CREATE TABLE public.course_enrolments (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  learner_id uuid NOT NULL REFERENCES auth.users (id) ON DELETE CASCADE,
  pathway_id text NOT NULL CHECK (char_length(pathway_id) BETWEEN 1 AND 120),
  status public.enrolment_status NOT NULL DEFAULT 'active',
  starts_at timestamptz NOT NULL DEFAULT now(),
  ends_at timestamptz,
  created_at timestamptz NOT NULL DEFAULT now(),
  CHECK (ends_at IS NULL OR ends_at >= starts_at),
  UNIQUE (learner_id, pathway_id)
);

CREATE TABLE private.security_audit_events (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  actor_id uuid REFERENCES auth.users (id) ON DELETE SET NULL,
  action text NOT NULL CHECK (char_length(action) BETWEEN 1 AND 80),
  target_type text NOT NULL CHECK (char_length(target_type) BETWEEN 1 AND 80),
  target_id uuid,
  occurred_at timestamptz NOT NULL DEFAULT now(),
  outcome text NOT NULL DEFAULT 'success' CHECK (outcome IN ('success', 'denied', 'failed')),
  reason_category text CHECK (reason_category IS NULL OR char_length(reason_category) <= 80)
);

CREATE INDEX security_audit_events_occurred_at_idx
  ON private.security_audit_events (occurred_at DESC);

-- Private, tightly scoped authorization helpers avoid recursive RLS evaluation.
CREATE OR REPLACE FUNCTION private.current_user_has_role(required_role public.app_role)
RETURNS boolean
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = ''
AS $$
  SELECT EXISTS (
    SELECT 1
    FROM public.role_assignments AS assignment
    WHERE assignment.user_id = (SELECT auth.uid())
      AND assignment.role = required_role
      AND assignment.revoked_at IS NULL
  );
$$;

CREATE OR REPLACE FUNCTION private.can_view_learner(target_learner_id uuid, required_scope text)
RETURNS boolean
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = ''
AS $$
  SELECT EXISTS (
    SELECT 1
    FROM public.guardian_learner_links AS link
    WHERE link.guardian_id = (SELECT auth.uid())
      AND link.learner_id = target_learner_id
      AND link.status = 'verified'
      AND link.consent_verified_at IS NOT NULL
      AND CASE required_scope
        WHEN 'profile' THEN link.can_view_profile
        WHEN 'progress' THEN link.can_view_learning_progress
        WHEN 'submissions' THEN link.can_view_submissions
        ELSE false
      END
  );
$$;

REVOKE ALL ON FUNCTION private.current_user_has_role(public.app_role) FROM PUBLIC;
REVOKE ALL ON FUNCTION private.can_view_learner(uuid, text) FROM PUBLIC;
GRANT USAGE ON SCHEMA private TO authenticated;
GRANT EXECUTE ON FUNCTION private.current_user_has_role(public.app_role) TO authenticated;
GRANT EXECUTE ON FUNCTION private.can_view_learner(uuid, text) TO authenticated;

CREATE OR REPLACE FUNCTION private.set_updated_at()
RETURNS trigger
LANGUAGE plpgsql
SET search_path = ''
AS $$
BEGIN
  NEW.updated_at := now();
  RETURN NEW;
END;
$$;

CREATE TRIGGER profiles_set_updated_at
  BEFORE UPDATE ON public.profiles
  FOR EACH ROW EXECUTE FUNCTION private.set_updated_at();

CREATE TRIGGER guardian_links_set_updated_at
  BEFORE UPDATE ON public.guardian_learner_links
  FOR EACH ROW EXECUTE FUNCTION private.set_updated_at();

-- New accounts receive a student role only. User metadata cannot request a privileged role.
CREATE OR REPLACE FUNCTION private.handle_new_auth_user()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
DECLARE
  requested_display_name text;
BEGIN
  requested_display_name := nullif(btrim(coalesce(NEW.raw_user_meta_data ->> 'display_name', '')), '');
  INSERT INTO public.profiles (user_id, display_name)
  VALUES (NEW.id, coalesce(left(requested_display_name, 80), 'Learner'))
  ON CONFLICT (user_id) DO NOTHING;

  INSERT INTO public.role_assignments (user_id, role, reason)
  VALUES (NEW.id, 'student', 'default_signup_role')
  ON CONFLICT DO NOTHING;

  RETURN NEW;
END;
$$;

REVOKE ALL ON FUNCTION private.handle_new_auth_user() FROM PUBLIC;

CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION private.handle_new_auth_user();

-- Audit role grants/revocations; never record credentials, tokens or learner response content.
CREATE OR REPLACE FUNCTION private.audit_role_assignment_change()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
DECLARE
  action_name text;
  actor uuid;
BEGIN
  actor := coalesce(NEW.granted_by, NEW.revoked_by, OLD.revoked_by, OLD.granted_by);
  IF TG_OP = 'INSERT' THEN
    action_name := 'role_granted';
  ELSIF OLD.revoked_at IS NULL AND NEW.revoked_at IS NOT NULL THEN
    action_name := 'role_revoked';
  ELSE
    action_name := 'role_assignment_updated';
  END IF;

  INSERT INTO private.security_audit_events (
    actor_id, action, target_type, target_id, outcome, reason_category
  )
  VALUES (
    actor,
    action_name,
    'role_assignment',
    coalesce(NEW.id, OLD.id),
    'success',
    coalesce(NEW.reason, OLD.reason)
  );

  RETURN coalesce(NEW, OLD);
END;
$$;

REVOKE ALL ON FUNCTION private.audit_role_assignment_change() FROM PUBLIC;

CREATE TRIGGER role_assignments_audit
  AFTER INSERT OR UPDATE ON public.role_assignments
  FOR EACH ROW EXECUTE FUNCTION private.audit_role_assignment_change();

-- Audit records are append-only. Only the owner of the trigger function can insert.
CREATE OR REPLACE FUNCTION private.reject_audit_mutation()
RETURNS trigger
LANGUAGE plpgsql
SET search_path = ''
AS $$
BEGIN
  RAISE EXCEPTION 'security audit events are append-only' USING ERRCODE = '42501';
END;
$$;

CREATE TRIGGER security_audit_append_only
  BEFORE UPDATE OR DELETE ON private.security_audit_events
  FOR EACH ROW EXECUTE FUNCTION private.reject_audit_mutation();

-- No private schema/table access is exposed through the PostgREST API.
REVOKE ALL ON ALL TABLES IN SCHEMA private FROM PUBLIC, anon, authenticated;
REVOKE ALL ON ALL FUNCTIONS IN SCHEMA private FROM PUBLIC, anon, authenticated;
GRANT USAGE ON SCHEMA private TO authenticated;
GRANT EXECUTE ON FUNCTION private.current_user_has_role(public.app_role) TO authenticated;
GRANT EXECUTE ON FUNCTION private.can_view_learner(uuid, text) TO authenticated;

-- Public tables: reset privileges and then grant only the columns/operations needed.
REVOKE ALL ON public.profiles FROM PUBLIC, anon, authenticated;
REVOKE ALL ON public.role_assignments FROM PUBLIC, anon, authenticated;
REVOKE ALL ON public.guardian_learner_links FROM PUBLIC, anon, authenticated;
REVOKE ALL ON public.course_enrolments FROM PUBLIC, anon, authenticated;

GRANT SELECT ON public.profiles TO authenticated;
GRANT UPDATE (display_name) ON public.profiles TO authenticated;
GRANT SELECT ON public.role_assignments TO authenticated;
GRANT SELECT ON public.guardian_learner_links TO authenticated;
GRANT SELECT ON public.course_enrolments TO authenticated;

ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.role_assignments ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.guardian_learner_links ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.course_enrolments ENABLE ROW LEVEL SECURITY;

CREATE POLICY profiles_select_scoped
  ON public.profiles FOR SELECT TO authenticated
  USING (
    user_id = (SELECT auth.uid())
    OR private.current_user_has_role('owner')
    OR private.can_view_learner(user_id, 'profile')
  );

CREATE POLICY profiles_update_own_display_name
  ON public.profiles FOR UPDATE TO authenticated
  USING (user_id = (SELECT auth.uid()))
  WITH CHECK (user_id = (SELECT auth.uid()));

CREATE POLICY role_assignments_select_own_or_owner
  ON public.role_assignments FOR SELECT TO authenticated
  USING (
    user_id = (SELECT auth.uid())
    OR private.current_user_has_role('owner')
  );

CREATE POLICY guardian_links_select_participant_or_owner
  ON public.guardian_learner_links FOR SELECT TO authenticated
  USING (
    guardian_id = (SELECT auth.uid())
    OR learner_id = (SELECT auth.uid())
    OR private.current_user_has_role('owner')
  );

CREATE POLICY course_enrolments_select_scoped
  ON public.course_enrolments FOR SELECT TO authenticated
  USING (
    learner_id = (SELECT auth.uid())
    OR private.current_user_has_role('owner')
    OR private.can_view_learner(learner_id, 'progress')
  );

-- Do not grant INSERT/DELETE or role/link/enrolment writes to browser identities.
