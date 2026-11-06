BEGIN;
SELECT plan(35);

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
  NOT has_table_privilege('service_role', 'private.account_deletion_legal_holds', 'SELECT'),
  'Worker service role cannot directly read legal-hold evidence'
);
SELECT ok(
  NOT has_table_privilege('authenticated', 'private.account_deletion_legal_holds', 'INSERT'),
  'browser roles cannot forge legal holds directly'
);
SELECT ok(
  NOT has_table_privilege('service_role', 'private.account_deletion_requests', 'UPDATE'),
  'Worker service role cannot bypass the deletion-request state machine'
);
SELECT ok(
  NOT has_table_privilege('service_role', 'private.account_deletion_requests', 'DELETE'),
  'Worker service role cannot delete request evidence directly'
);
SELECT ok(
  NOT has_table_privilege('service_role', 'private.account_deletion_legal_holds', 'UPDATE'),
  'Worker service role cannot rewrite legal-hold evidence directly'
);
SELECT ok(
  NOT has_table_privilege('service_role', 'private.account_deletion_legal_holds', 'DELETE'),
  'Worker service role cannot delete legal-hold evidence directly'
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
SELECT is(
  (SELECT identity_verification_method
   FROM public.list_account_deletion_requests()
   WHERE request_id = (SELECT request_id FROM account_deletion_request_context LIMIT 1)),
  'authenticated_confirmed_email'::text,
  'Owner queue exposes the recorded confirmed-email identity-verification method'
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
SELECT ok(
  (SELECT request_status = 'on_hold'
          AND has_active_legal_hold
          AND active_legal_hold_authority_category = 'court_order'
          AND active_legal_hold_authority_reference = 'SYNTHETIC-CASE-01'
          AND active_legal_hold_reason_summary = 'Synthetic legal hold reason for permission testing'
          AND active_legal_hold_review_due_at > now()
   FROM public.list_account_deletion_requests()
   WHERE request_id = (SELECT request_id FROM account_deletion_request_context LIMIT 1)),
  'Owner AAL2 queue shows the on-hold state and complete legal-hold review evidence'
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
  (SELECT request_status FROM public.list_account_deletion_requests()
   WHERE request_id = (SELECT request_id FROM account_deletion_request_context LIMIT 1)),
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
SELECT ok(
  (SELECT request_status = 'approved'
          AND reviewed_by = '88888888-8888-4888-8888-888888888888'::uuid
          AND reviewed_at IS NOT NULL
          AND completed_at IS NULL
   FROM public.list_account_deletion_requests()
   WHERE request_id = (SELECT request_id FROM account_deletion_request_context LIMIT 1)),
  'approval preserves Owner review evidence and does not mark deletion complete'
);
RESET ROLE;

SELECT ok(
  EXISTS (
    SELECT 1
    FROM pg_trigger
    WHERE tgrelid = 'private.account_deletion_requests'::regclass
      AND tgname = 'account_deletion_request_integrity'
      AND NOT tgisinternal AND tgenabled <> 'D'
  ),
  'request state and identity integrity trigger is installed and enabled'
);
SELECT ok(
  EXISTS (
    SELECT 1
    FROM pg_trigger
    WHERE tgrelid = 'private.account_deletion_legal_holds'::regclass
      AND tgname = 'account_deletion_legal_hold_integrity'
      AND NOT tgisinternal AND tgenabled <> 'D'
  ),
  'legal-hold evidence immutability trigger is installed and enabled'
);

SELECT * FROM finish();
ROLLBACK;
