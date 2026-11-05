BEGIN;
SELECT no_plan();

CREATE TEMP TABLE staff_invitation_fixtures (
  invitation_id uuid,
  token_hash text,
  invited_email text,
  invited_role public.app_role
) ON COMMIT DROP;
GRANT ALL ON TABLE pg_temp.staff_invitation_fixtures TO authenticated;

SET LOCAL ROLE anon;
SELECT throws_ok(
  $$SELECT * FROM public.list_staff_invitations()$$,
  '42501',
  NULL,
  'anonymous users cannot list staff invitations'
);
RESET ROLE;

SET LOCAL ROLE authenticated;
SELECT set_config('request.jwt.claim.sub', '11111111-1111-4111-8111-111111111111', true);
SELECT set_config('request.jwt.claims', '{"sub":"11111111-1111-4111-8111-111111111111","role":"authenticated","aal":"aal2"}', true);
SELECT throws_ok(
  $$SELECT * FROM public.create_staff_invitation('grader.new@example.invalid', 'grader', repeat('a', 64))$$,
  '42501', 'staff_invitation_forbidden',
  'students cannot create staff invitations'
);
SELECT throws_ok(
  $$SELECT * FROM public.list_staff_invitations()$$,
  '42501', 'staff_invitation_forbidden',
  'students cannot list staff invitations'
);
SELECT set_config('request.jwt.claim.sub', '77777777-7777-4777-8777-777777777777', true);
SELECT set_config('request.jwt.claims', '{"sub":"77777777-7777-4777-8777-777777777777","role":"authenticated","aal":"aal2"}', true);
SELECT throws_ok(
  $$SELECT * FROM public.create_staff_invitation('grader.new@example.invalid', 'grader', repeat('a', 64))$$,
  '42501', 'staff_invitation_forbidden',
  'admins cannot create staff invitations'
);
RESET ROLE;

SET LOCAL ROLE authenticated;
SELECT set_config('request.jwt.claim.sub', '88888888-8888-4888-8888-888888888888', true);
SELECT set_config('request.jwt.claims', '{"sub":"88888888-8888-4888-8888-888888888888","role":"authenticated","aal":"aal1"}', true);
SELECT throws_ok(
  $$SELECT * FROM public.create_staff_invitation('grader.new@example.invalid', 'grader', repeat('a', 64))$$,
  'P0001', 'mfa_required',
  'owner cannot create invitations at AAL1'
);
SELECT throws_ok(
  $$SELECT * FROM public.revoke_staff_invitation(gen_random_uuid(), 'Synthetic test reason')$$,
  'P0001', 'mfa_required',
  'owner cannot revoke invitations at AAL1'
);
SELECT set_config('request.jwt.claims', '{"sub":"88888888-8888-4888-8888-888888888888","role":"authenticated","aal":"aal2"}', true);
SELECT throws_ok(
  $$SELECT * FROM public.create_staff_invitation('grader.new@example.invalid', 'owner', repeat('a', 64))$$,
  '22023', 'invalid_invitation_role',
  'owner role cannot be offered through an invitation'
);
SELECT throws_ok(
  $$SELECT * FROM public.create_staff_invitation('grader.new@example.invalid', 'grader', 'not-a-hash')$$,
  '22023', 'invalid_invitation_token_hash',
  'only a SHA-256 token hash can be stored'
);

INSERT INTO pg_temp.staff_invitation_fixtures
SELECT invitation_id,
       encode(extensions.digest('student-b-grader-invitation', 'sha256'), 'hex'),
       invited_email,
       invited_role
FROM public.create_staff_invitation(
  'student.b@example.invalid',
  'grader',
  encode(extensions.digest('student-b-grader-invitation', 'sha256'), 'hex')
);
SELECT is(
  (SELECT invited_role FROM pg_temp.staff_invitation_fixtures LIMIT 1),
  'grader'::public.app_role,
  'owner can create a grader invitation'
);
SELECT is(
  (SELECT expires_at <= created_at + interval '7 days'
   FROM public.list_staff_invitations()
   WHERE invitation_id = (SELECT invitation_id FROM pg_temp.staff_invitation_fixtures LIMIT 1)),
  true,
  'invitation expiry cannot exceed seven days'
);
SELECT is(
  (SELECT status FROM public.list_staff_invitations()
   WHERE invitation_id = (SELECT invitation_id FROM pg_temp.staff_invitation_fixtures LIMIT 1)),
  'pending'::text,
  'owner can list safe invitation status'
);
SELECT throws_ok(
  $$SELECT * FROM public.create_staff_invitation(
      'student.b@example.invalid', 'grader',
      encode(extensions.digest('second-student-b-invitation', 'sha256'), 'hex')
    )$$,
  '23505', 'invitation_already_pending',
  'duplicate pending invitation for the same email and role is denied'
);
RESET ROLE;

SELECT is(
  (SELECT count(*)::integer
   FROM private.security_audit_events
   WHERE action = 'staff_invitations_listed'
     AND actor_id = '88888888-8888-4888-8888-888888888888'
     AND outcome = 'success'
     AND reason_category = 'owner_aal2'
     AND target_type = 'staff_invitation_collection'
     AND target_id IS NULL
     AND actor_roles @> ARRAY['owner'::public.app_role]
     AND request_id IS NOT NULL
     AND transaction_id IS NOT NULL),
  2,
  'each privileged staff-invitation list read is attributed and correlation-enriched'
);

SET LOCAL ROLE authenticated;
SELECT set_config('request.jwt.claim.sub', '11111111-1111-4111-8111-111111111111', true);
SELECT set_config('request.jwt.claims', '{"sub":"11111111-1111-4111-8111-111111111111","role":"authenticated","aal":"aal2"}', true);
SELECT throws_ok(
  $$SELECT * FROM public.accept_staff_invitation(
      (SELECT token_hash FROM pg_temp.staff_invitation_fixtures LIMIT 1)
    )$$,
  '42501', 'invitation_email_mismatch',
  'invitation cannot be redeemed by an account with a different email'
);
SELECT set_config('request.jwt.claim.sub', '22222222-2222-4222-8222-222222222222', true);
SELECT set_config('request.jwt.claims', '{"sub":"22222222-2222-4222-8222-222222222222","role":"authenticated","aal":"aal1"}', true);
SELECT throws_ok(
  $$SELECT * FROM public.accept_staff_invitation(
      (SELECT token_hash FROM pg_temp.staff_invitation_fixtures LIMIT 1)
    )$$,
  'P0001', 'mfa_required',
  'invitee cannot accept without AAL2'
);
RESET ROLE;

UPDATE auth.users
SET email_confirmed_at = NULL
WHERE id = '22222222-2222-4222-8222-222222222222';

SET LOCAL ROLE authenticated;
SELECT set_config('request.jwt.claim.sub', '22222222-2222-4222-8222-222222222222', true);
SELECT set_config('request.jwt.claims', '{"sub":"22222222-2222-4222-8222-222222222222","role":"authenticated","aal":"aal2"}', true);
SELECT throws_ok(
  $$SELECT * FROM public.accept_staff_invitation(
      (SELECT token_hash FROM pg_temp.staff_invitation_fixtures LIMIT 1)
    )$$,
  '42501', 'invitation_email_unverified',
  'invitee must verify the matching email first'
);
RESET ROLE;

UPDATE auth.users
SET email_confirmed_at = now()
WHERE id = '22222222-2222-4222-8222-222222222222';

SET LOCAL ROLE authenticated;
SELECT set_config('request.jwt.claim.sub', '22222222-2222-4222-8222-222222222222', true);
SELECT set_config('request.jwt.claims', '{"sub":"22222222-2222-4222-8222-222222222222","role":"authenticated","aal":"aal2"}', true);
SELECT lives_ok(
  $$SELECT * FROM public.accept_staff_invitation(
      (SELECT token_hash FROM pg_temp.staff_invitation_fixtures LIMIT 1)
    )$$,
  'verified invitee with AAL2 can accept the invitation'
);
SELECT is(
  (SELECT count(*)::integer FROM public.role_assignments
   WHERE user_id = '22222222-2222-4222-8222-222222222222'
     AND role = 'grader' AND revoked_at IS NULL),
  1,
  'acceptance grants only the invited grader role'
);
RESET ROLE;
SELECT is(
  (SELECT CASE
      WHEN revoked_at IS NOT NULL THEN 'revoked'
      WHEN accepted_at IS NOT NULL THEN 'accepted'
      WHEN expires_at <= now() THEN 'expired'
      ELSE 'pending'
    END
   FROM private.staff_invitations
   WHERE id = (SELECT invitation_id FROM pg_temp.staff_invitation_fixtures LIMIT 1)),
  'accepted'::text,
  'accepted invitation is marked as consumed in its private record'
);
SET LOCAL ROLE authenticated;
SELECT set_config('request.jwt.claim.sub', '22222222-2222-4222-8222-222222222222', true);
SELECT set_config('request.jwt.claims', '{"sub":"22222222-2222-4222-8222-222222222222","role":"authenticated","aal":"aal2"}', true);
SELECT throws_ok(
  $$SELECT * FROM public.accept_staff_invitation(
      (SELECT token_hash FROM pg_temp.staff_invitation_fixtures LIMIT 1)
    )$$,
  'P0001', 'invitation_already_used',
  'the same invitation token cannot be replayed'
);
RESET ROLE;

SET LOCAL ROLE authenticated;
SELECT set_config('request.jwt.claim.sub', '88888888-8888-4888-8888-888888888888', true);
SELECT set_config('request.jwt.claims', '{"sub":"88888888-8888-4888-8888-888888888888","role":"authenticated","aal":"aal2"}', true);
INSERT INTO pg_temp.staff_invitation_fixtures
SELECT invitation_id,
       encode(extensions.digest('expired-student-a-invitation', 'sha256'), 'hex'),
       invited_email,
       invited_role
FROM public.create_staff_invitation(
  'student.a@example.invalid',
  'admin',
  encode(extensions.digest('expired-student-a-invitation', 'sha256'), 'hex')
);
INSERT INTO pg_temp.staff_invitation_fixtures
SELECT invitation_id,
       encode(extensions.digest('revoked-student-a-invitation', 'sha256'), 'hex'),
       invited_email,
       invited_role
FROM public.create_staff_invitation(
  'student.a@example.invalid',
  'grader',
  encode(extensions.digest('revoked-student-a-invitation', 'sha256'), 'hex')
);
SELECT lives_ok(
  $$SELECT public.revoke_staff_invitation(
      (SELECT invitation_id FROM pg_temp.staff_invitation_fixtures
       WHERE invited_role = 'grader' AND invited_email = 'student.a@example.invalid' LIMIT 1),
      'Synthetic owner revocation'
    )$$,
  'owner can revoke a pending invitation'
);
SELECT is(
  (SELECT status FROM public.list_staff_invitations()
   WHERE invitation_id = (SELECT invitation_id FROM pg_temp.staff_invitation_fixtures
     WHERE invited_role = 'grader' AND invited_email = 'student.a@example.invalid' LIMIT 1)),
  'revoked'::text,
  'revocation appears in the owner list'
);
RESET ROLE;
UPDATE private.staff_invitations
SET created_at = now() - interval '8 days',
    expires_at = now() - interval '1 day'
WHERE id = (
  SELECT invitation_id FROM pg_temp.staff_invitation_fixtures
  WHERE invited_role = 'admin' AND invited_email = 'student.a@example.invalid' LIMIT 1
);

SET LOCAL ROLE authenticated;
SELECT set_config('request.jwt.claim.sub', '11111111-1111-4111-8111-111111111111', true);
SELECT set_config('request.jwt.claims', '{"sub":"11111111-1111-4111-8111-111111111111","role":"authenticated","aal":"aal2"}', true);
SELECT throws_ok(
  $$SELECT * FROM public.accept_staff_invitation(
      (SELECT token_hash FROM pg_temp.staff_invitation_fixtures
       WHERE invited_role = 'admin' AND invited_email = 'student.a@example.invalid' LIMIT 1)
    )$$,
  'P0001', 'invitation_expired',
  'expired invitations cannot be accepted'
);
SELECT throws_ok(
  $$SELECT * FROM public.accept_staff_invitation(
      (SELECT token_hash FROM pg_temp.staff_invitation_fixtures
       WHERE invited_role = 'grader' AND invited_email = 'student.a@example.invalid' LIMIT 1)
    )$$,
  'P0001', 'invitation_revoked',
  'revoked invitations cannot be accepted'
);
RESET ROLE;

SELECT is(
  (SELECT count(*)::integer FROM private.security_audit_events
   WHERE action = 'staff_invitation_accepted'
     AND actor_id = '22222222-2222-4222-8222-222222222222'
     AND target_id = (SELECT invitation_id FROM pg_temp.staff_invitation_fixtures
       WHERE invited_email = 'student.b@example.invalid' LIMIT 1)),
  1,
  'the invitation acceptance is attributed to the accepting user in the audit log'
);

-- Prepare a pending synthetic invitation for the database-derived failure
-- helper. Generic audit outcome ingestion is now Worker-only.
SET LOCAL ROLE authenticated;
SELECT set_config('request.jwt.claim.sub','88888888-8888-4888-8888-888888888888',true);
SELECT set_config('request.jwt.claims','{"sub":"88888888-8888-4888-8888-888888888888","role":"authenticated","aal":"aal2"}',true);
INSERT INTO pg_temp.staff_invitation_fixtures
SELECT invitation_id, encode(extensions.digest('pending-student-b-admin-audit-test','sha256'),'hex'), invited_email, invited_role
FROM public.create_staff_invitation('student.b@example.invalid','admin',encode(extensions.digest('pending-student-b-admin-audit-test','sha256'),'hex'));
RESET ROLE;

SET LOCAL ROLE authenticated;
SELECT set_config('request.jwt.claim.sub', '11111111-1111-4111-8111-111111111111', true);
SELECT set_config('request.jwt.claims', '{"sub":"11111111-1111-4111-8111-111111111111","role":"authenticated","aal":"aal2"}', true);
SELECT set_config('request.headers', '{"x-request-id":"ffffffff-ffff-4fff-8fff-ffffffffffff"}', true);
SELECT ok(
  public.audit_staff_invitation_acceptance_failure(
    (SELECT token_hash FROM pg_temp.staff_invitation_fixtures
     WHERE invited_role = 'grader' AND invited_email = 'student.a@example.invalid' LIMIT 1)
  ),
  'acceptance failure is bound to the private invitation resolved from the token hash'
);
RESET ROLE;
SELECT is(
  (SELECT count(*)::integer FROM private.security_audit_events
   WHERE actor_id = '11111111-1111-4111-8111-111111111111'
     AND action = 'staff_invitation_accepted'
     AND target_id = (SELECT invitation_id FROM pg_temp.staff_invitation_fixtures
       WHERE invited_role = 'grader' AND invited_email = 'student.a@example.invalid' LIMIT 1)
     AND outcome = 'failed'
     AND reason_category = 'state_conflict'
     AND request_id = 'ffffffff-ffff-4fff-8fff-ffffffffffff'),
  1,
  'revoked invitation replays are recorded without token hash or email'
);

SET LOCAL ROLE authenticated;
SELECT set_config('request.jwt.claim.sub', '22222222-2222-4222-8222-222222222222', true);
SELECT set_config('request.jwt.claims', '{"sub":"22222222-2222-4222-8222-222222222222","role":"authenticated","aal":"aal2"}', true);
SELECT set_config('request.headers', '{"x-request-id":"abababab-abab-4bab-8bab-abababababab"}', true);
SELECT ok(
  public.audit_staff_invitation_acceptance_failure(
    (SELECT token_hash FROM pg_temp.staff_invitation_fixtures
     WHERE invited_role = 'grader' AND invited_email = 'student.a@example.invalid' LIMIT 1)
  ),
  'a different email attempting acceptance is retained as a derived denial'
);
RESET ROLE;
SELECT is(
  (SELECT count(*)::integer FROM private.security_audit_events
   WHERE actor_id = '22222222-2222-4222-8222-222222222222'
     AND action = 'staff_invitation_accepted'
     AND target_id = (SELECT invitation_id FROM pg_temp.staff_invitation_fixtures
       WHERE invited_role = 'grader' AND invited_email = 'student.a@example.invalid' LIMIT 1)
     AND outcome = 'denied'
     AND reason_category = 'email_mismatch'
     AND request_id = 'abababab-abab-4bab-8bab-abababababab'),
  1,
  'email-mismatched acceptance stores metadata only'
);

SET LOCAL ROLE authenticated;
SELECT set_config('request.jwt.claim.sub', '22222222-2222-4222-8222-222222222222', true);
SELECT set_config('request.jwt.claims', '{"sub":"22222222-2222-4222-8222-222222222222","role":"authenticated","aal":"aal2"}', true);
SELECT set_config('request.headers', '{"x-request-id":"bcbcbcbc-bcbc-4bcb-8bcb-bcbcbcbcbcbc"}', true);
SELECT ok(
  NOT public.audit_staff_invitation_acceptance_failure(
    (SELECT token_hash FROM pg_temp.staff_invitation_fixtures
     WHERE invited_role = 'admin' AND invited_email = 'student.b@example.invalid' LIMIT 1)
  ),
  'an otherwise eligible invitee cannot forge an acceptance failure event'
);
RESET ROLE;
SELECT is(
  (SELECT count(*)::integer FROM private.security_audit_events
   WHERE actor_id = '22222222-2222-4222-8222-222222222222'
     AND action = 'staff_invitation_accepted'
     AND target_id = (SELECT invitation_id FROM pg_temp.staff_invitation_fixtures
       WHERE invited_role = 'admin' AND invited_email = 'student.b@example.invalid' LIMIT 1)),
  0,
  'eligible invitation acceptance attempts do not create false failure audit entries'
);
SET LOCAL ROLE authenticated;
SELECT set_config('request.jwt.claim.sub', '22222222-2222-4222-8222-222222222222', true);
SELECT set_config('request.jwt.claims', '{"sub":"22222222-2222-4222-8222-222222222222","role":"authenticated","aal":"aal2"}', true);
SELECT lives_ok(
  $q$SELECT * FROM public.accept_staff_invitation(
      (SELECT token_hash FROM pg_temp.staff_invitation_fixtures
       WHERE invited_role = 'admin' AND invited_email = 'student.b@example.invalid' LIMIT 1)
    )$q$,
  'the same otherwise eligible invitation can be accepted through the operation RPC'
);
RESET ROLE;

SET LOCAL ROLE authenticated;
SELECT set_config('request.jwt.claim.sub', '88888888-8888-4888-8888-888888888888', true);
SELECT set_config('request.jwt.claims', '{"sub":"88888888-8888-4888-8888-888888888888","role":"authenticated","aal":"aal2"}', true);
SELECT set_config('request.headers', '{"x-request-id":"cdcdcdcd-cdcd-4dcd-8dcd-cdcdcdcdcdcd"}', true);
SELECT ok(
  NOT public.audit_staff_invitation_acceptance_failure(repeat('f',64)),
  'unknown invitation hashes cannot create unscoped acceptance audit events'
);
RESET ROLE;

SELECT * FROM finish();
ROLLBACK;
