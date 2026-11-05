-- Phase 1C-E: enrich private audit events with server-derived actor and request context.
-- The enrichment trigger applies to every existing audit writer without widening
-- table/function grants or exposing the private audit table to browser clients.

ALTER TABLE private.security_audit_events
  ADD COLUMN actor_roles public.app_role[],
  ADD COLUMN request_id uuid,
  ADD COLUMN transaction_id bigint;

COMMENT ON COLUMN private.security_audit_events.actor_roles IS
  'Server-derived snapshot of all active application roles for the actor at event-write time; NULL when no active role is available or for legacy rows.';
COMMENT ON COLUMN private.security_audit_events.request_id IS
  'Request correlation UUID forwarded by the trusted Worker in x-request-id; invalid or absent values are replaced by a database-generated UUID. Never used for authorization.';
COMMENT ON COLUMN private.security_audit_events.transaction_id IS
  'PostgreSQL transaction identifier grouping audit writes performed in the same database transaction.';

CREATE INDEX security_audit_events_request_id_idx
  ON private.security_audit_events (request_id)
  WHERE request_id IS NOT NULL;

CREATE OR REPLACE FUNCTION private.audit_actor_roles(p_actor_id uuid)
RETURNS public.app_role[]
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = ''
AS $function$
  SELECT array_agg(assignment.role ORDER BY assignment.role::text)
  FROM public.role_assignments AS assignment
  JOIN public.profiles AS profile
    ON profile.user_id = assignment.user_id
  WHERE assignment.user_id = p_actor_id
    AND assignment.revoked_at IS NULL
    AND profile.account_status = 'active';
$function$;

ALTER FUNCTION private.audit_actor_roles(uuid) OWNER TO postgres;
REVOKE ALL ON FUNCTION private.audit_actor_roles(uuid)
  FROM PUBLIC, anon, authenticated;

CREATE OR REPLACE FUNCTION private.enrich_security_audit_context()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $function$
DECLARE
  request_headers jsonb;
  supplied_request_id text;
BEGIN
  -- Read the role snapshot from protected database records, never from JWT or
  -- caller-provided request fields. Keep every active role when an account has
  -- more than one application role.
  NEW.actor_roles := private.audit_actor_roles(NEW.actor_id);

  -- PostgREST exposes the inbound request headers as transaction-local JSON.
  -- Treat this only as correlation metadata; malformed/missing values fail
  -- closed to a fresh database-generated UUID.
  BEGIN
    request_headers := nullif(current_setting('request.headers', true), '')::jsonb;
    supplied_request_id := request_headers ->> 'x-request-id';
  EXCEPTION
    WHEN invalid_text_representation THEN
      supplied_request_id := NULL;
  END;

  IF supplied_request_id IS NOT NULL
    AND supplied_request_id ~* '^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$' THEN
    NEW.request_id := supplied_request_id::uuid;
  ELSE
    NEW.request_id := gen_random_uuid();
  END IF;

  NEW.transaction_id := txid_current();
  RETURN NEW;
END;
$function$;

ALTER FUNCTION private.enrich_security_audit_context() OWNER TO postgres;
REVOKE ALL ON FUNCTION private.enrich_security_audit_context()
  FROM PUBLIC, anon, authenticated;

DROP TRIGGER IF EXISTS security_audit_enrich_context
  ON private.security_audit_events;
CREATE TRIGGER security_audit_enrich_context
  BEFORE INSERT ON private.security_audit_events
  FOR EACH ROW EXECUTE FUNCTION private.enrich_security_audit_context();
