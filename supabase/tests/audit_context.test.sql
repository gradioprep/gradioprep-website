BEGIN;
SELECT no_plan();
SELECT has_column('private','security_audit_events','actor_roles','private audit events store server-derived active-role snapshots');
SELECT has_column('private','security_audit_events','request_id','private audit events store a request correlation UUID');
SELECT has_column('private','security_audit_events','transaction_id','private audit events store a PostgreSQL transaction ID');
SELECT ok(
 NOT has_function_privilege('anon','public.audit_protected_read_outcome(text,uuid,text)','EXECUTE')
 AND NOT has_function_privilege('authenticated','public.audit_protected_read_outcome(text,uuid,text)','EXECUTE')
 AND NOT has_function_privilege('authenticated','public.audit_authorized_protected_read(text,uuid)','EXECUTE')
 AND NOT has_function_privilege('authenticated','public.audit_privileged_write_outcome(text,uuid,text,text)','EXECUTE')
 AND NOT has_function_privilege('authenticated','public.record_worker_audit_outcome(uuid,text,uuid,text,text)','EXECUTE'),
 'browser-facing roles cannot execute generic audit-ingestion RPCs'
);
SELECT ok(has_function_privilege('service_role','public.record_worker_audit_outcome(uuid,text,uuid,text,text)','EXECUTE'),'only the Worker service role can ingest protected API audit outcomes');

SET LOCAL ROLE service_role;
SELECT set_config('request.jwt.claims','{"role":"service_role"}',true);
SELECT set_config('request.headers','{"x-request-id":"aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa"}',true);
SELECT ok(public.record_worker_audit_outcome('11111111-1111-4111-8111-111111111111','student_attempt_list_authorized',NULL,'success',NULL),'trusted Worker records a successful protected student-list read');
SELECT ok(public.record_worker_audit_outcome('11111111-1111-4111-8111-111111111111','student_submission_list_authorized',NULL,'success',NULL),'trusted Worker records a second protected read in the same request');
RESET ROLE;
SELECT is((SELECT count(*)::integer FROM private.security_audit_events WHERE actor_id='11111111-1111-4111-8111-111111111111' AND request_id='aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa' AND outcome='success' AND reason_category='student_self' AND actor_roles @> ARRAY['student'::public.app_role] AND transaction_id IS NOT NULL),2,'events retain actor, database-derived roles and request metadata');
SELECT is((SELECT count(DISTINCT transaction_id)::integer FROM private.security_audit_events WHERE request_id='aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa'),1,'one request shares a database transaction identifier');

SET LOCAL ROLE service_role;
SELECT set_config('request.jwt.claims','{"role":"service_role"}',true);
SELECT set_config('request.headers','{"x-request-id":"bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbbb"}',true);
SELECT ok(public.record_worker_audit_outcome('88888888-8888-4888-8888-888888888888','owner_submission_queue_authorized',NULL,'success',NULL),'trusted Worker records an Owner protected-read result');
RESET ROLE;
SELECT ok((SELECT actor_roles @> ARRAY['owner'::public.app_role] AND transaction_id IS NOT NULL FROM private.security_audit_events WHERE request_id='bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbbb' LIMIT 1),'Owner audit rows use database-derived role snapshots');

SET LOCAL ROLE service_role;
SELECT set_config('request.jwt.claims','{"role":"service_role"}',true);
SELECT set_config('request.headers','{"x-request-id":"not-a-uuid"}',true);
SELECT ok(public.record_worker_audit_outcome('11111111-1111-4111-8111-111111111111','student_attempt_list_authorized',NULL,'success',NULL),'invalid request ID does not block trusted audit writes');
RESET ROLE;
SELECT is((SELECT count(*)::integer FROM private.security_audit_events WHERE actor_id='11111111-1111-4111-8111-111111111111' AND action='student_attempt_list_authorized' AND request_id IS NOT NULL AND request_id <> 'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa'),1,'database trigger replaces invalid request correlation IDs');

-- Role-assignment reason is free text and must never be copied into the audit category.
UPDATE public.role_assignments
SET reason = 'SYNTHETIC-SENSITIVE-CANARY-DO-NOT-LOG'
WHERE id = (
  SELECT id FROM public.role_assignments
  WHERE user_id = '11111111-1111-4111-8111-111111111111'
    AND role = 'student' AND revoked_at IS NULL
  LIMIT 1
);
SELECT is(
  (
    SELECT reason_category
    FROM private.security_audit_events
    WHERE action = 'role_assignment_updated'
      AND target_id = (
        SELECT id FROM public.role_assignments
        WHERE user_id = '11111111-1111-4111-8111-111111111111'
          AND role = 'student' AND revoked_at IS NULL
        LIMIT 1
      )
    ORDER BY occurred_at DESC
    LIMIT 1
  ),
  'role_assignment_updated'::text,
  'role audit records store only a fixed action category, not the supplied free-text reason'
);
SELECT ok(
  NOT EXISTS (
    SELECT 1 FROM private.security_audit_events
    WHERE reason_category = 'SYNTHETIC-SENSITIVE-CANARY-DO-NOT-LOG'
  ),
  'synthetic sensitive canary text is excluded from persisted audit metadata'
);

SET LOCAL ROLE authenticated;
SELECT set_config('request.jwt.claim.sub','11111111-1111-4111-8111-111111111111',true);
SELECT set_config('request.jwt.claims','{"sub":"11111111-1111-4111-8111-111111111111","role":"authenticated","aal":"aal1"}',true);
SELECT throws_ok($$SELECT * FROM private.security_audit_events$$,'42501',NULL,'authenticated users still cannot read the private audit table directly');
RESET ROLE;
SELECT * FROM finish();
ROLLBACK;
