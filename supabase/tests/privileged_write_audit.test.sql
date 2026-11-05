BEGIN;
SELECT no_plan();
SELECT ok(
 NOT has_function_privilege('anon','public.audit_privileged_write_outcome(text,uuid,text,text)','EXECUTE')
 AND NOT has_function_privilege('authenticated','public.audit_privileged_write_outcome(text,uuid,text,text)','EXECUTE')
 AND NOT has_function_privilege('authenticated','public.audit_protected_read_outcome(text,uuid,text)','EXECUTE')
 AND NOT has_function_privilege('authenticated','public.audit_authorized_protected_read(text,uuid)','EXECUTE')
 AND NOT has_function_privilege('authenticated','public.record_worker_audit_outcome(uuid,text,uuid,text,text)','EXECUTE'),
 'browser-authenticated sessions cannot submit audit outcomes directly'
);
SELECT ok(has_function_privilege('service_role','public.record_worker_audit_outcome(uuid,text,uuid,text,text)','EXECUTE'),'trusted Worker service role has the narrow audit-ingestion grant');
SET LOCAL ROLE authenticated;
SELECT set_config('request.jwt.claim.sub','88888888-8888-4888-8888-888888888888',true);
SELECT set_config('request.jwt.claims','{"sub":"88888888-8888-4888-8888-888888888888","role":"authenticated","aal":"aal2"}',true);
SELECT throws_ok($$SELECT public.audit_privileged_write_outcome('owner_submission_transition','d3333333-3333-4333-8333-333333333333','failed','state_conflict')$$,'42501',NULL,'authenticated Owner cannot forge a write-failure audit event');
SELECT throws_ok($$SELECT public.audit_protected_read_outcome('owner_submission_queue_authorized',NULL,'failed')$$,'42501',NULL,'authenticated Owner cannot forge a protected-read failure event');
RESET ROLE;
SELECT is((SELECT count(*)::integer FROM private.security_audit_events WHERE actor_id='88888888-8888-4888-8888-888888888888' AND action IN ('owner_submission_transition','owner_submission_queue_authorized') AND outcome='failed'),0,'browser forgery attempts create no audit events');
SET LOCAL ROLE service_role;
SELECT set_config('request.jwt.claims','{"role":"service_role"}',true);
SELECT set_config('request.headers','{"x-request-id":"cccccccc-cccc-4ccc-8ccc-cccccccccccc"}',true);
SELECT ok(public.record_worker_audit_outcome('88888888-8888-4888-8888-888888888888','owner_submission_transition','d3333333-3333-4333-8333-333333333333','failed','state_conflict'),'trusted Worker records allowlisted Owner operation failure');
SELECT ok(NOT public.record_worker_audit_outcome('88888888-8888-4888-8888-888888888888','owner_submission_transition','d3333333-3333-4333-8333-333333333333','success',NULL),'Worker cannot create success events for state-changing operations');
SELECT ok(NOT public.record_worker_audit_outcome('88888888-8888-4888-8888-888888888888','owner_submission_transition','d3333333-3333-4333-8333-333333333333','failed','raw SQL error supplied by a client'),'unsafe error text is rejected');
RESET ROLE;
SELECT is((SELECT count(*)::integer FROM private.security_audit_events WHERE actor_id='88888888-8888-4888-8888-888888888888' AND action='owner_submission_transition' AND target_type='assessment_submission' AND target_id='d3333333-3333-4333-8333-333333333333' AND outcome='failed' AND reason_category='state_conflict' AND actor_roles @> ARRAY['owner'::public.app_role] AND request_id='cccccccc-cccc-4ccc-8ccc-cccccccccccc' AND transaction_id IS NOT NULL),1,'trusted operation failures retain only safe categories and verified actor context');
SELECT * FROM finish();
ROLLBACK;
