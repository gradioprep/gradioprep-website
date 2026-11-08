-- Phase 1F: keep free-form role-assignment reasons out of audit metadata.
-- Attribute revocations to the actor who revoked the role, not the original grantor.
-- reason_category is a fixed classification, never a copy of supplied text.
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
  IF TG_OP = 'INSERT' THEN
    action_name := 'role_granted';
    actor := NEW.granted_by;
  ELSIF OLD.revoked_at IS NULL AND NEW.revoked_at IS NOT NULL THEN
    action_name := 'role_revoked';
    actor := NEW.revoked_by;
  ELSE
    action_name := 'role_assignment_updated';
    actor := coalesce(NEW.revoked_by, NEW.granted_by, OLD.revoked_by, OLD.granted_by);
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
'Append-only audit for role grants, revocations and assignment updates. Grants are attributed to their grantor; revocations are attributed to the actual revoking actor. The reason_category stores only a fixed action name; free-text role_assignments.reason is never copied into the audit record.';
