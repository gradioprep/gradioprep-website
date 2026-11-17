-- Remove anonymous execution rights from privileged invitation APIs.
-- Keep explicit authenticated EXECUTE grants: each function performs its own Owner/identity checks.
REVOKE EXECUTE ON FUNCTION public.accept_staff_invitation(text) FROM PUBLIC, anon;
REVOKE EXECUTE ON FUNCTION public.create_staff_invitation(text, public.app_role, text) FROM PUBLIC, anon;
REVOKE EXECUTE ON FUNCTION public.list_staff_invitations() FROM PUBLIC, anon;
REVOKE EXECUTE ON FUNCTION public.revoke_staff_invitation(uuid, text) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.accept_staff_invitation(text) TO authenticated;
GRANT EXECUTE ON FUNCTION public.create_staff_invitation(text, public.app_role, text) TO authenticated;
GRANT EXECUTE ON FUNCTION public.list_staff_invitations() TO authenticated;
GRANT EXECUTE ON FUNCTION public.revoke_staff_invitation(uuid, text) TO authenticated;
