BEGIN;
SELECT no_plan();

SELECT ok(
  NOT has_function_privilege('anon', 'public.audit_authorized_protected_read(text,uuid)', 'EXECUTE')
  AND NOT has_function_privilege('anon', 'public.audit_protected_read_outcome(text,uuid,text)', 'EXECUTE')
  AND NOT has_function_privilege('anon', 'public.reassign_submission_grader(uuid,uuid,text)', 'EXECUTE')
  AND NOT has_function_privilege('anon', 'public.transition_assessment_submission(uuid,text,text)', 'EXECUTE')
  AND NOT has_function_privilege('anon', 'public.assign_submission_to_grader(uuid,uuid,text)', 'EXECUTE')
  AND NOT has_function_privilege('anon', 'public.save_assessment_draft(uuid,text,text,jsonb)', 'EXECUTE')
  AND NOT has_function_privilege('anon', 'public.publish_assessment_feedback(uuid)', 'EXECUTE')
  AND NOT has_function_privilege('anon', 'public.accept_assessment_submission(uuid,uuid,text)', 'EXECUTE')
  AND NOT has_function_privilege('anon', 'public.save_attempt_response(uuid,uuid,text)', 'EXECUTE')
  AND NOT has_function_privilege('anon', 'public.create_private_qa_record(uuid,jsonb,text,text,text,text)', 'EXECUTE')
  AND NOT has_function_privilege('anon', 'public.get_private_qa_records(uuid)', 'EXECUTE'),
  'anonymous has no execute privilege on sensitive assessment, grading, audit or replay RPCs'
);
SELECT ok(
  NOT has_function_privilege('authenticated', 'public.audit_authorized_protected_read(text,uuid)', 'EXECUTE')
  AND NOT has_function_privilege('authenticated', 'public.audit_protected_read_outcome(text,uuid,text)', 'EXECUTE')
  AND NOT has_function_privilege('authenticated', 'public.audit_privileged_write_outcome(text,uuid,text,text)', 'EXECUTE')
  AND has_function_privilege('service_role', 'public.record_worker_audit_outcome(uuid,text,uuid,text,text)', 'EXECUTE')
  AND has_function_privilege('authenticated', 'public.reassign_submission_grader(uuid,uuid,text)', 'EXECUTE')
  AND has_function_privilege('authenticated', 'public.transition_assessment_submission(uuid,text,text)', 'EXECUTE')
  AND has_function_privilege('authenticated', 'public.assign_submission_to_grader(uuid,uuid,text)', 'EXECUTE')
  AND has_function_privilege('authenticated', 'public.save_assessment_draft(uuid,text,text,jsonb)', 'EXECUTE')
  AND has_function_privilege('authenticated', 'public.publish_assessment_feedback(uuid)', 'EXECUTE')
  AND has_function_privilege('authenticated', 'public.accept_assessment_submission(uuid,uuid,text)', 'EXECUTE')
  AND has_function_privilege('authenticated', 'public.save_attempt_response(uuid,uuid,text)', 'EXECUTE')
  AND has_function_privilege('authenticated', 'public.create_private_qa_record(uuid,jsonb,text,text,text,text)', 'EXECUTE')
  AND has_function_privilege('authenticated', 'public.get_private_qa_records(uuid)', 'EXECUTE'),
  'business RPCs retain authorization checks while audit ingestion is restricted to the Worker service role'
);
SELECT ok(
  NOT has_function_privilege('authenticated', 'private.archive_assessment_draft(uuid,uuid,text)', 'EXECUTE')
  AND NOT has_function_privilege('authenticated', 'private.invalidate_submission_assignments_after_grader_revocation()', 'EXECUTE'),
  'internal archive and role-revocation functions are not directly callable'
);
SELECT ok(
  NOT has_table_privilege('authenticated', 'private.assessment_drafts', 'SELECT')
  AND NOT has_table_privilege('authenticated', 'private.assessment_draft_history', 'SELECT')
  AND NOT has_table_privilege('authenticated', 'private.security_audit_events', 'SELECT')
  AND NOT has_table_privilege('authenticated', 'private.attempt_response_versions', 'SELECT')
  AND NOT has_table_privilege('authenticated', 'private.private_qa_records', 'SELECT'),
  'authenticated callers cannot inspect private drafts, audit events or response history directly'
);

SET LOCAL ROLE authenticated;
SELECT set_config('request.jwt.claim.sub', '11111111-1111-4111-8111-111111111111', true);
SELECT set_config('request.jwt.claims', '{"sub":"11111111-1111-4111-8111-111111111111","role":"authenticated","aal":"aal1"}', true);
SELECT ok(
  NOT public.audit_authorized_protected_read('arbitrary_function_name', NULL),
  'the protected-read audit RPC rejects unknown action names by default'
);
SELECT ok(
  NOT public.audit_authorized_protected_read('student_submission_read_authorized', NULL),
  'the protected-read audit RPC rejects missing detail record IDs'
);
SELECT throws_ok(
  $$INSERT INTO public.submission_grader_assignments DEFAULT VALUES$$,
  '42501', NULL,
  'learners cannot create submission grader assignments directly'
);
SELECT throws_ok(
  $$UPDATE public.assessment_versions SET overall_feedback = 'forged learner edit'$$,
  '42501', NULL,
  'learners cannot alter immutable published assessments directly'
);
SELECT throws_ok(
  $$DELETE FROM public.criterion_results$$,
  '42501', NULL,
  'learners cannot delete immutable criterion outcomes directly'
);
SELECT throws_ok(
  $$UPDATE public.assessment_submissions SET status = 'feedback_published'$$,
  '42501', NULL,
  'learners cannot forge accepted-submission workflow state directly'
);
RESET ROLE;

SET LOCAL ROLE authenticated;
SELECT set_config('request.jwt.claim.sub', '88888888-8888-4888-8888-888888888888', true);
SELECT set_config('request.jwt.claims', '{"sub":"88888888-8888-4888-8888-888888888888","role":"authenticated","aal":"aal1"}', true);
SELECT ok(
  NOT public.audit_authorized_protected_read('owner_submission_queue_authorized', NULL),
  'Owner at AAL1 cannot audit privileged submission queue access'
);
SELECT throws_ok(
  $$SELECT * FROM public.reassign_submission_grader(
    'd3333333-3333-4333-8333-333333333333',
    '55555555-5555-4555-8555-555555555555',
    'AAL1 adversarial reassignment denial'
  )$$,
  '42501', 'assessment_assignment_forbidden',
  'Owner at AAL1 cannot reassign submission graders at the database boundary'
);
SELECT throws_ok(
  $$SELECT * FROM public.transition_assessment_submission(
    'd3333333-3333-4333-8333-333333333333',
    'withdrawn', 'AAL1 adversarial transition denial'
  )$$,
  '42501', 'assessment_transition_forbidden',
  'Owner at AAL1 cannot transition workflow state at the database boundary'
);
RESET ROLE;

SET LOCAL ROLE authenticated;
SELECT set_config('request.jwt.claim.sub', '77777777-7777-4777-8777-777777777777', true);
SELECT set_config('request.jwt.claims', '{"sub":"77777777-7777-4777-8777-777777777777","role":"authenticated","aal":"aal2"}', true);
SELECT throws_ok(
  $$SELECT * FROM public.reassign_submission_grader(
    'd3333333-3333-4333-8333-333333333333',
    '55555555-5555-4555-8555-555555555555',
    'AAL2 Admin adversarial reassignment denial'
  )$$,
  '42501', 'assessment_assignment_forbidden',
  'AAL2 Admin cannot inherit Owner reassignment rights'
);
SELECT throws_ok(
  $$SELECT * FROM public.transition_assessment_submission(
    'd3333333-3333-4333-8333-333333333333',
    'withdrawn', 'AAL2 Admin adversarial transition denial'
  )$$,
  '42501', 'assessment_transition_forbidden',
  'AAL2 Admin cannot inherit Owner workflow-transition rights'
);
SELECT ok(
  NOT public.audit_authorized_protected_read('owner_submission_queue_authorized', NULL)
  AND NOT public.audit_authorized_protected_read('grader_submission_queue_authorized', NULL),
  'AAL2 Admin receives neither Owner nor Grader protected-read authority'
);
RESET ROLE;

SELECT * FROM finish();
ROLLBACK;
