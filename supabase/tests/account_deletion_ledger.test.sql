BEGIN;
SELECT plan(38);

SELECT ok(
  (SELECT relrowsecurity FROM pg_class WHERE oid = 'private.account_deletion_requests'::regclass),
  'account-deletion request ledger has RLS enabled'
);
SELECT ok(
  (SELECT relrowsecurity FROM pg_class WHERE oid = 'private.account_deletion_legal_holds'::regclass),
  'account-deletion legal-hold ledger has RLS enabled'
);
SELECT ok(
  NOT has_table_privilege('authenticated', 'private.account_deletion_requests', 'SELECT'),
  'browser roles cannot directly read deletion requests'
);
SELECT ok(
  NOT has_table_privilege('service_role', 'private.account_deletion_requests', 'SELECT'),
  'Worker service role cannot bypass the deletion-request RPC'
);
SELECT ok(
  NOT has_table_privilege('authenticated', 'private.account_deletion_requests', 'INSERT'),
  'browser roles cannot forge deletion requests directly'
);
SELECT ok(
  NOT has_table_privilege('authenticated', 'private.account_deletion_legal_holds', 'SELECT'),
  'browser roles cannot directly read legal-hold evidence'
);
SELECT ok(
  NOT has_function_privilege('anon', 'public.request_account_deletion(text)', 'EXECUTE'),
  'anonymous users cannot submit deletion requests'
);
SELECT ok(
  has_function_privilege('authenticated', 'public.request_account_deletion(text)', 'EXECUTE'),
  'authenticated users can submit their own verified deletion request'
);
SELECT ok(
  NOT has_function_privilege('anon', 'public.list_account_deletion_requests()', 'EXECUTE'),
  'anonymous users cannot list deletion requests'
);
SELECT ok(
  NOT has_function_privilege('service_role', 'public.review_account_deletion_request(uuid,text,text)', 'EXECUTE'),
  'service role cannot impersonate an Owner review'
);
SELECT ok(
  NOT has_function_privilege('service_role', 'public.place_account_deletion_legal_hold(uuid,text,text,text,timestamptz)', 'EXECUTE'),
  'service role cannot place legal holds'
);

CREATE TEMP TABLE account_deletion_request_context (
  request_id uuid,
  request_status text,
  requested_at timestamptz,
  response_due_at timestamptz,
  is_replay boolean
);
GRANT SELECT, INSERT ON account_deletion_request_context TO authenticated;

SET LOCAL ROLE authenticated;
SELECT set_config(
  'request.jwt.claims',
  '{"sub":"11111111-1111-4111-8111-111111111111","role":"authenticated","aal":"aal1"}',
  true
);
INSERT INTO account_deletion_request_context
SELECT request_id, request_status, requested_at, response_due_at, is_replay
FROM public.request_account_deletion('account_closure');

SELECT is(
  (SELECT request_status FROM account_deletion_request_context LIMIT 1),
  'under_review'::text,
  'confirmed-email self-request enters the review queue'
);
SELECT ok(
  (SELECT response_due_at = requested_at + interval '30 days'
   FROM account_deletion_request_context LIMIT 1),
  'the response target is exactly 30 days after verified request receipt'
);
INSERT INTO account_deletion_request_context
SELECT request_id, request_status, requested_at, response_due_at, is_replay
FROM public.request_account_deletion('data_erasure');
RESET ROLE;

SELECT is(
  (SELECT identity_verification_method
   FROM private.account_deletion_requests
   WHERE id = (SELECT request_id FROM account_deletion_request_context LIMIT 1)),
  'authenticated_confirmed_email'::text,
  'verification evidence records the confirmed-email authenticated method'
);

SELECT ok(
  (SELECT is_replay FROM account_deletion_request_context ORDER BY requested_at LIMIT 1 OFFSET 1),
  'a repeated open request returns the existing request instead of duplicating it'
);
SELECT is(
  (SELECT request_id FROM account_deletion_request_context ORDER BY requested_at LIMIT 1 OFFSET 1),
  (SELECT request_id FROM account_deletion_request_context ORDER BY requested_at LIMIT 1),
  'a replay cannot create a second deletion request or change its scope'
);

-- The account is synthetic and the transaction rolls back; this simulates an
-- unverified address without adding or retaining any real personal data.
UPDATE auth.users
SET email_confirmed_at = NULL
WHERE id = '22222222-2222-4222-8222-222222222222';

SET LOCAL ROLE authenticated;
SELECT set_config(
  'request.jwt.claims',
  '{"sub":"22222222-2222-4222-8222-222222222222","role":"authenticated","aal":"aal1"}',
  true
);
SELECT throws_ok(
  'SELECT * FROM public.request_account_deletion()',
  '42501',
  'account_deletion_request_forbidden',
  'unconfirmed email cannot create a deletion request'
);
SELECT throws_ok(
  'SELECT * FROM public.list_account_deletion_requests()',
  '42501',
  'account_deletion_owner_aal2_required',
  'a learner cannot browse the Owner deletion-request queue'
);
RESET ROLE;

UPDATE auth.users
SET email_confirmed_at = clock_timestamp()
WHERE id = '22222222-2222-4222-8222-222222222222';

CREATE TEMP TABLE account_deletion_hold_context (hold_id uuid);
GRANT SELECT, INSERT ON account_deletion_hold_context TO authenticated;

SET LOCAL ROLE authenticated;
SELECT set_config(
  'request.jwt.claims',
  '{"sub":"88888888-8888-4888-8888-888888888888","role":"authenticated","aal":"aal1"}',
  true
);
SELECT throws_ok(
  format(
    'SELECT public.place_account_deletion_legal_hold(%L,%L,%L,%L,clock_timestamp()+interval ''30 days'')',
    (SELECT request_id FROM account_deletion_request_context LIMIT 1),
    'court_order', 'SYNTHETIC-CASE-01',
    'Synthetic legal hold reason for permission testing'
  ),
  '42501',
  'account_deletion_owner_aal2_required',
  'Owner AAL1 cannot place a deletion legal hold'
);
RESET ROLE;

SET LOCAL ROLE authenticated;
SELECT set_config(
  'request.jwt.claims',
  '{"sub":"88888888-8888-4888-8888-888888888888","role":"authenticated","aal":"aal2"}',
  true
);

SELECT is(
  (SELECT count(*)::integer FROM public.list_account_deletion_requests()),
  1,
  'Owner AAL2 can list the minimal deletion-request queue'
);

INSERT INTO account_deletion_hold_context
SELECT public.place_account_deletion_legal_hold(
  (SELECT request_id FROM account_deletion_request_context LIMIT 1),
  'court_order',
  'SYNTHETIC-CASE-01',
  'Synthetic legal hold reason for permission testing',
  clock_timestamp() + interval '30 days'
);

SELECT ok(
  (SELECT hold_id IS NOT NULL FROM account_deletion_hold_context),
  'Owner AAL2 can place a legal hold with authority, reason and review date'
);
SELECT is(
  (SELECT status FROM private.account_deletion_requests
   WHERE id = (SELECT request_id FROM account_deletion_request_context LIMIT 1)),
  'on_hold'::text,
  'placing a legal hold moves the request into on-hold state'
);
SELECT ok(
  (SELECT has_active_legal_hold
          AND active_legal_hold_authority_category = 'court_order'
          AND active_legal_hold_authority_reference = 'SYNTHETIC-CASE-01'
          AND active_legal_hold_reason_summary = 'Synthetic legal hold reason for permission testing'
          AND active_legal_hold_review_due_at > now()
   FROM public.list_account_deletion_requests()
   WHERE request_id = (SELECT request_id FROM account_deletion_request_context LIMIT 1)),
  'Owner AAL2 queue exposes the active hold authority, reason and review date'
);
SELECT ok(
  (SELECT authority_reference = 'SYNTHETIC-CASE-01'
          AND char_length(reason_summary) >= 12
          AND review_due_at > placed_at
   FROM private.account_deletion_legal_holds
   WHERE id = (SELECT hold_id FROM account_deletion_hold_context)),
  'legal-hold evidence stores its authority reference, reason and scheduled review'
);
SELECT throws_ok(
  format(
    'SELECT public.review_account_deletion_request(%L,%L,%L)',
    (SELECT request_id FROM account_deletion_request_context LIMIT 1),
    'approve', 'retention_review_complete'
  ),
  'P0001',
  'account_deletion_request_on_legal_hold',
  'an active legal hold blocks approval for deletion'
);
SELECT is(
  public.release_account_deletion_legal_hold(
    (SELECT hold_id FROM account_deletion_hold_context),
    'review_cleared'
  ),
  true,
  'Owner AAL2 can release a hold with a recorded release reason'
);
SELECT is(
  (SELECT status FROM private.account_deletion_requests
   WHERE id = (SELECT request_id FROM account_deletion_request_context LIMIT 1)),
  'under_review'::text,
  'releasing a hold returns the request to review rather than auto-approving it'
);
SELECT is(
  public.review_account_deletion_request(
    (SELECT request_id FROM account_deletion_request_context LIMIT 1),
    'approve',
    'retention_review_complete'
  ),
  'approved'::text,
  'Owner AAL2 can approve a reviewed request after the hold is released'
);
RESET ROLE;

SELECT ok(
  (SELECT status = 'approved'
          AND reviewed_by = '88888888-8888-4888-8888-888888888888'::uuid
          AND reviewed_at IS NOT NULL
          AND completed_at IS NULL
   FROM private.account_deletion_requests
   WHERE id = (SELECT request_id FROM account_deletion_request_context LIMIT 1)),
  'approval records Owner evidence but does not execute or complete deletion'
);
SELECT is(
  (SELECT count(*)::integer
   FROM private.security_audit_events
   WHERE action IN (
     'account_deletion_request_submitted',
     'account_deletion_requests_listed',
     'account_deletion_legal_hold_placed',
     'account_deletion_legal_hold_released',
     'account_deletion_request_reviewed'
   )),
  6,
  'request, protected queue reads, hold and review transitions are audited'
);
SELECT throws_ok(
  format(
    'DELETE FROM private.account_deletion_requests WHERE id = %L',
    (SELECT request_id FROM account_deletion_request_context LIMIT 1)
  ),
  '42501',
  'account_deletion_request_delete_requires_retention_workflow',
  'deletion-request evidence cannot be directly deleted'
);
SELECT throws_ok(
  format(
    'UPDATE private.account_deletion_requests SET subject_user_id = %L WHERE id = %L',
    '22222222-2222-4222-8222-222222222222',
    (SELECT request_id FROM account_deletion_request_context LIMIT 1)
  ),
  '42501',
  'account_deletion_request_identity_immutable',
  'request subject and verification scope cannot be reassigned'
);
SELECT throws_ok(
  format(
    'DELETE FROM private.account_deletion_legal_holds WHERE id = %L',
    (SELECT hold_id FROM account_deletion_hold_context)
  ),
  '42501',
  'account_deletion_legal_hold_delete_forbidden',
  'legal-hold evidence cannot be directly deleted'
);
SELECT throws_ok(
  format(
    'UPDATE private.account_deletion_legal_holds SET reason_summary = %L WHERE id = %L',
    'Changed legal hold reason after release',
    (SELECT hold_id FROM account_deletion_hold_context)
  ),
  '42501',
  'account_deletion_legal_hold_release_immutable',
  'released legal-hold evidence cannot be rewritten'
);
SELECT ok(
  EXISTS (
    SELECT 1 FROM auth.users
    WHERE id = '11111111-1111-4111-8111-111111111111'
  ),
  'an approved request does not delete or disable the account in this ledger-only slice'
);
UPDATE private.account_deletion_requests
SET subject_user_id = NULL
WHERE id = (SELECT request_id FROM account_deletion_request_context LIMIT 1);
UPDATE private.account_deletion_legal_holds
SET subject_user_id = NULL
WHERE id = (SELECT hold_id FROM account_deletion_hold_context);

SELECT ok(
  (SELECT subject_user_id IS NULL
          AND status = 'approved'
          AND reviewed_at IS NOT NULL
          AND decision_reason_category = 'retention_review_complete'
   FROM private.account_deletion_requests
   WHERE id = (SELECT request_id FROM account_deletion_request_context LIMIT 1)),
  'detaching the account identity preserves its non-content deletion-request evidence'
);
SELECT ok(
  (SELECT subject_user_id IS NULL
          AND released_at IS NOT NULL
          AND release_reason_category = 'review_cleared'
          AND authority_reference = 'SYNTHETIC-CASE-01'
   FROM private.account_deletion_legal_holds
   WHERE id = (SELECT hold_id FROM account_deletion_hold_context)),
  'detaching the account identity preserves released legal-hold evidence'
);
SELECT ok(
  EXISTS (
    SELECT 1 FROM public.assessment_submissions
    WHERE learner_id = '11111111-1111-4111-8111-111111111111'
  ),
  'assessment records remain intact pending the retention-aware execution workflow'
);

SELECT * FROM finish();
ROLLBACK;
