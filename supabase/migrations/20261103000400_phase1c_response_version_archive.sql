-- Phase 1C hardening: preserve every typed-response revision and narrow response writes.
-- The snapshot table is private and append-only; browser clients can never read it.

CREATE TABLE private.attempt_response_versions (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  response_id uuid NOT NULL REFERENCES public.attempt_responses(id) ON DELETE RESTRICT,
  attempt_id uuid NOT NULL REFERENCES public.attempts(id) ON DELETE RESTRICT,
  version integer NOT NULL CHECK (version > 0),
  response_text text NOT NULL CHECK (char_length(response_text) <= 12000),
  word_count integer GENERATED ALWAYS AS (
    CASE
      WHEN btrim(response_text) = '' THEN 0
      ELSE array_length(regexp_split_to_array(btrim(response_text), E'\\s+'), 1)
    END
  ) STORED,
  saved_by uuid REFERENCES auth.users(id) ON DELETE SET NULL,
  saved_at timestamptz NOT NULL DEFAULT now(),
  UNIQUE (response_id, version)
);

ALTER TABLE private.attempt_response_versions ENABLE ROW LEVEL SECURITY;
REVOKE ALL ON TABLE private.attempt_response_versions FROM PUBLIC, anon, authenticated;

CREATE INDEX attempt_response_versions_attempt_saved_idx
  ON private.attempt_response_versions (attempt_id, saved_at ASC);

CREATE OR REPLACE FUNCTION private.reject_attempt_response_version_mutation()
RETURNS trigger
LANGUAGE plpgsql
SET search_path = ''
AS $$
BEGIN
  RAISE EXCEPTION 'attempt response versions are append-only' USING ERRCODE = '42501';
END;
$$;

CREATE TRIGGER attempt_response_versions_append_only
  BEFORE UPDATE OR DELETE ON private.attempt_response_versions
  FOR EACH ROW EXECUTE FUNCTION private.reject_attempt_response_version_mutation();

CREATE OR REPLACE FUNCTION private.archive_attempt_response_version()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
BEGIN
  INSERT INTO private.attempt_response_versions (
    response_id, attempt_id, version, response_text, saved_by
  )
  VALUES (
    NEW.id, NEW.attempt_id, NEW.version, NEW.response_text, (SELECT auth.uid())
  );
  RETURN NEW;
END;
$$;

REVOKE ALL ON FUNCTION private.reject_attempt_response_version_mutation() FROM PUBLIC, anon, authenticated;
REVOKE ALL ON FUNCTION private.archive_attempt_response_version() FROM PUBLIC, anon, authenticated;

CREATE TRIGGER attempt_responses_archive_version
  AFTER INSERT OR UPDATE ON public.attempt_responses
  FOR EACH ROW EXECUTE FUNCTION private.archive_attempt_response_version();

-- Remove direct response mutation grants. The only write path is the narrowly
-- scoped RPC below, which checks the current actor, locks their in-progress
-- attempt, validates prompt membership and lets the database stamp version/time.
REVOKE INSERT (attempt_id, task_version_id, prompt_id, response_text),
  UPDATE (response_text)
  ON public.attempt_responses FROM authenticated;

CREATE OR REPLACE FUNCTION public.save_attempt_response(
  p_attempt_id uuid,
  p_prompt_id uuid,
  p_response_text text
)
RETURNS TABLE (
  id uuid,
  attempt_id uuid,
  prompt_id uuid,
  response_text text,
  word_count integer,
  version integer,
  updated_at timestamptz
)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
DECLARE
  actor_id uuid := auth.uid();
  selected_task_version_id uuid;
  current_status text;
BEGIN
  IF actor_id IS NULL
    OR NOT private.current_account_is_active()
    OR NOT private.current_user_has_role('student'::public.app_role) THEN
    RAISE EXCEPTION USING ERRCODE = '42501', MESSAGE = 'attempt_response_forbidden';
  END IF;

  IF p_response_text IS NULL OR char_length(p_response_text) > 12000 THEN
    RAISE EXCEPTION USING ERRCODE = '22023', MESSAGE = 'invalid_attempt_response';
  END IF;

  SELECT attempt.task_version_id, attempt.status
    INTO selected_task_version_id, current_status
    FROM public.attempts AS attempt
    WHERE attempt.id = p_attempt_id
      AND attempt.learner_id = actor_id
    FOR UPDATE;

  IF NOT FOUND THEN
    RAISE EXCEPTION USING ERRCODE = 'P0002', MESSAGE = 'attempt_not_found';
  END IF;

  IF current_status <> 'in_progress' THEN
    RAISE EXCEPTION USING ERRCODE = 'P0001', MESSAGE = 'attempt_not_editable';
  END IF;

  IF NOT EXISTS (
    SELECT 1
    FROM public.task_version_prompts AS prompt
    WHERE prompt.id = p_prompt_id
      AND prompt.task_version_id = selected_task_version_id
  ) THEN
    RAISE EXCEPTION USING ERRCODE = '22023', MESSAGE = 'invalid_attempt_prompt';
  END IF;

  RETURN QUERY
    INSERT INTO public.attempt_responses AS saved_response (
      attempt_id, task_version_id, prompt_id, response_text
    )
    VALUES (
      p_attempt_id, selected_task_version_id, p_prompt_id, p_response_text
    )
    ON CONFLICT ON CONSTRAINT attempt_responses_attempt_id_prompt_id_key
    DO UPDATE SET response_text = EXCLUDED.response_text
    RETURNING
      saved_response.id,
      saved_response.attempt_id,
      saved_response.prompt_id,
      saved_response.response_text,
      saved_response.word_count,
      saved_response.version,
      saved_response.updated_at;
END;
$$;

REVOKE ALL ON FUNCTION public.save_attempt_response(uuid, uuid, text) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.save_attempt_response(uuid, uuid, text) TO authenticated;
