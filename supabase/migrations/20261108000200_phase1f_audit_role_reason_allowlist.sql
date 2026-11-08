-- Phase 1F: keep free-form role-assignment reasons out of audit metadata.
-- reason_category is a bounded classification, not a copy of user-supplied text.
CREATE OR REPLACE FUNCTION private.audit_role_assignment_change()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $function$
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
    action_name
  );

  RETURN coalesce(NEW, OLD);
END;
$function$;

ALTER FUNCTION private.audit_role_assignment_change() OWNER TO postgres;
REVOKE ALL ON FUNCTION private.audit_role_assignment_change() FROM PUBLIC, anon, authenticated;

COMMENT ON FUNCTION private.audit_role_assignment_change() IS
'Append-only audit for role grants, revocations and assignment updates. The reason_category stores only the fixed action name; the free-text role_assignments.reason value is never copied into the audit record.';
