-- Phase 1C final authorization closure: owner-only private academic QA.
-- Records are version-specific and append-only. They are not learner feedback
-- and are not accessible to learners, guardians, graders or operational Admins.

CREATE TABLE private.private_qa_records (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  assessment_version_id uuid NOT NULL
    REFERENCES public.assessment_versions(id) ON DELETE RESTRICT,
  qa_revision integer NOT NULL CHECK (qa_revision > 0),
  reviewer_user_id uuid NOT NULL REFERENCES auth.users(id) ON DELETE RESTRICT,
  checks jsonb NOT NULL
    CHECK (jsonb_typeof(checks) = 'object' AND octet_length(checks::text) <= 8192),
  status text NOT NULL CHECK (status IN ('pending', 'passed', 'action_required')),
  explanation text NOT NULL
    CHECK (char_length(btrim(explanation)) BETWEEN 5 AND 2000),
  uncertainty text NOT NULL DEFAULT ''
    CHECK (char_length(uncertainty) <= 1000),
  reviewer_action text NOT NULL
    CHECK (char_length(btrim(reviewer_action)) BETWEEN 3 AND 1000),
  created_at timestamptz NOT NULL DEFAULT clock_timestamp(),
  UNIQUE (assessment_version_id, qa_revision)
);

CREATE INDEX private_qa_records_assessment_revision_idx
  ON private.private_qa_records (assessment_version_id, qa_revision DESC);

ALTER TABLE private.private_qa_records ENABLE ROW LEVEL SECURITY;
REVOKE ALL ON TABLE private.private_qa_records FROM PUBLIC, anon, authenticated;

CREATE OR REPLACE FUNCTION private.prevent_private_qa_record_mutation()
RETURNS trigger
LANGUAGE plpgsql
SET search_path = ''
AS $$
BEGIN
  RAISE EXCEPTION 'private QA records are append-only' USING ERRCODE = '42501';
END;
$$;

ALTER FUNCTION private.prevent_private_qa_record_mutation() OWNER TO postgres;
REVOKE ALL ON FUNCTION private.prevent_private_qa_record_mutation()
  FROM PUBLIC, anon, authenticated;

CREATE TRIGGER private_qa_records_append_only
  BEFORE UPDATE OR DELETE ON private.private_qa_records
  FOR EACH ROW EXECUTE FUNCTION private.prevent_private_qa_record_mutation();

CREATE OR REPLACE FUNCTION public.create_private_qa_record(
  p_assessment_version_id uuid,
  p_checks jsonb,
  p_status text,
  p_explanation text,
  p_uncertainty text,
  p_reviewer_action text
)
RETURNS TABLE (
  id uuid,
  assessment_version_id uuid,
  qa_revision integer,
  status text,
  reviewer_user_id uuid,
  created_at timestamptz
)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
DECLARE
  actor_id uuid := auth.uid();
  selected_version public.assessment_versions%ROWTYPE;
  next_revision integer;
  created_record private.private_qa_records%ROWTYPE;
BEGIN
  IF actor_id IS NULL
    OR NOT private.current_account_is_active()
    OR NOT private.current_user_has_role('owner'::public.app_role)
    OR coalesce(auth.jwt() ->> 'aal', 'aal1') <> 'aal2' THEN
    RAISE EXCEPTION USING ERRCODE = '42501', MESSAGE = 'private_qa_forbidden';
  END IF;

  IF p_assessment_version_id IS NULL
    OR p_checks IS NULL
    OR jsonb_typeof(p_checks) <> 'object' THEN
    RAISE EXCEPTION USING ERRCODE = '22023', MESSAGE = 'invalid_private_qa_record';
  END IF;

  IF octet_length(p_checks::text) > 8192
    OR p_status IS NULL
    OR p_status NOT IN ('pending', 'passed', 'action_required')
    OR p_explanation IS NULL
    OR char_length(btrim(p_explanation)) NOT BETWEEN 5 AND 2000
    OR char_length(coalesce(p_uncertainty, '')) > 1000
    OR p_reviewer_action IS NULL
    OR char_length(btrim(p_reviewer_action)) NOT BETWEEN 3 AND 1000 THEN
    RAISE EXCEPTION USING ERRCODE = '22023', MESSAGE = 'invalid_private_qa_record';
  END IF;

  IF (SELECT count(*)::integer FROM jsonb_object_keys(p_checks)) NOT BETWEEN 1 AND 30
    OR EXISTS (
      SELECT 1
      FROM jsonb_each(p_checks) AS item(key, value)
      WHERE item.key !~ '^[a-z][a-z0-9_]{1,39}$'
        OR jsonb_typeof(item.value) NOT IN ('boolean', 'string', 'number')
        OR (jsonb_typeof(item.value) = 'string'
            AND char_length(item.value #>> '{}') > 200)
    ) THEN
    RAISE EXCEPTION USING ERRCODE = '22023', MESSAGE = 'invalid_private_qa_checks';
  END IF;

  -- Lock the immutable assessment version so concurrent reviews receive a
  -- unique, monotonically increasing QA revision.
  SELECT version.* INTO selected_version
  FROM public.assessment_versions AS version
  WHERE version.id = p_assessment_version_id
  FOR UPDATE;

  IF NOT FOUND THEN
    RAISE EXCEPTION USING ERRCODE = 'P0002', MESSAGE = 'private_qa_assessment_version_not_found';
  END IF;

  SELECT coalesce(max(record.qa_revision), 0) + 1
  INTO next_revision
  FROM private.private_qa_records AS record
  WHERE record.assessment_version_id = p_assessment_version_id;

  INSERT INTO private.private_qa_records (
    assessment_version_id, qa_revision, reviewer_user_id, checks,
    status, explanation, uncertainty, reviewer_action
  )
  VALUES (
    p_assessment_version_id, next_revision, actor_id, p_checks,
    p_status, btrim(p_explanation), btrim(coalesce(p_uncertainty, '')),
    btrim(p_reviewer_action)
  )
  RETURNING * INTO created_record;

  INSERT INTO private.security_audit_events (
    actor_id, action, target_type, target_id, outcome, reason_category
  )
  VALUES (
    actor_id, 'private_qa_record_created', 'assessment_version',
    p_assessment_version_id, 'success', 'owner_qa_review'
  );

  RETURN QUERY SELECT
    created_record.id,
    created_record.assessment_version_id,
    created_record.qa_revision,
    created_record.status,
    created_record.reviewer_user_id,
    created_record.created_at;
END;
$$;

CREATE OR REPLACE FUNCTION public.get_private_qa_records(
  p_assessment_version_id uuid
)
RETURNS TABLE (
  id uuid,
  assessment_version_id uuid,
  qa_revision integer,
  checks jsonb,
  status text,
  explanation text,
  uncertainty text,
  reviewer_action text,
  reviewer_user_id uuid,
  created_at timestamptz
)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
DECLARE
  actor_id uuid := auth.uid();
BEGIN
  IF actor_id IS NULL
    OR NOT private.current_account_is_active()
    OR NOT private.current_user_has_role('owner'::public.app_role)
    OR coalesce(auth.jwt() ->> 'aal', 'aal1') <> 'aal2' THEN
    RAISE EXCEPTION USING ERRCODE = '42501', MESSAGE = 'private_qa_forbidden';
  END IF;

  IF p_assessment_version_id IS NULL OR NOT EXISTS (
    SELECT 1
    FROM public.assessment_versions AS version
    WHERE version.id = p_assessment_version_id
  ) THEN
    RAISE EXCEPTION USING ERRCODE = 'P0002', MESSAGE = 'private_qa_assessment_version_not_found';
  END IF;

  INSERT INTO private.security_audit_events (
    actor_id, action, target_type, target_id, outcome, reason_category
  )
  VALUES (
    actor_id, 'private_qa_records_read', 'assessment_version',
    p_assessment_version_id, 'success', 'owner_qa_review'
  );

  RETURN QUERY
  SELECT
    record.id,
    record.assessment_version_id,
    record.qa_revision,
    record.checks,
    record.status,
    record.explanation,
    record.uncertainty,
    record.reviewer_action,
    record.reviewer_user_id,
    record.created_at
  FROM private.private_qa_records AS record
  WHERE record.assessment_version_id = p_assessment_version_id
  ORDER BY record.qa_revision DESC;
END;
$$;

ALTER FUNCTION public.create_private_qa_record(uuid, jsonb, text, text, text, text)
  OWNER TO postgres;
ALTER FUNCTION public.get_private_qa_records(uuid) OWNER TO postgres;

REVOKE ALL ON FUNCTION public.create_private_qa_record(uuid, jsonb, text, text, text, text)
  FROM PUBLIC, anon, authenticated;
REVOKE ALL ON FUNCTION public.get_private_qa_records(uuid)
  FROM PUBLIC, anon, authenticated;
GRANT EXECUTE ON FUNCTION public.create_private_qa_record(uuid, jsonb, text, text, text, text)
  TO authenticated;
GRANT EXECUTE ON FUNCTION public.get_private_qa_records(uuid)
  TO authenticated;
