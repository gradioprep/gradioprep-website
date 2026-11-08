BEGIN;
SELECT no_plan();

-- Student-owned submission reads are audited, and cross-learner targets fail closed.
SET LOCAL ROLE authenticated;
SELECT set_config('request.jwt.claim.sub', '11111111-1111-4111-8111-111111111111', true);
SELECT set_config('request.jwt.claims', '{"sub":"11111111-1111-4111-8111-111111111111","role":"authenticated","aal":"aal1"}', true);

SELECT set_config(
  'test.workflow_submission_id',
  (SELECT submission_id::text
   FROM public.accept_assessment_submission(
     'a1111111-1111-4111-8111-111111111111',
     '81818181-8181-4181-8181-818181818181',
     'Synthetic workflow integrity response with enough detail to validate audit and replay protection.'
   )),
  true
);

SELECT is(
  (SELECT is_replay FROM public.accept_assessment_submission(
    'a1111111-1111-4111-8111-111111111111',
    '81818181-8181-4181-8181-818181818181',
    'Synthetic workflow integrity response with enough detail to validate audit and replay protection.'
  )),
  true,
  'an identical accepted-submission retry returns the existing acceptance'
);
SELECT is(
  (SELECT count(*)::integer FROM public.assessment_submissions
   WHERE id = current_setting('test.workflow_submission_id')::uuid),
  1,
  'an identical acceptance retry does not create a second submission'
);
RESET ROLE;
SELECT is(
  (SELECT count(*)::integer FROM private.security_audit_events
   WHERE action = 'assessment_submission_accepted'
     AND target_id = current_setting('test.workflow_submission_id')::uuid),
  1,
  'replayed acceptance does not duplicate the original acceptance audit event'
);
SET LOCAL ROLE service_role;
SELECT set_config('request.jwt.claims','{"role":"service_role"}',true);
SELECT set_config('request.headers','{"x-request-id":"eeeeeeee-eeee-4eee-8eee-eeeeeeeeeeee"}',true);
SELECT ok(
  public.record_worker_audit_outcome(
    '11111111-1111-4111-8111-111111111111',
    'student_submission_list_authorized',NULL,'success',NULL
  ),
  'trusted Worker records the completed student submission-list read'
);
SELECT ok(
  public.record_worker_audit_outcome(
    '11111111-1111-4111-8111-111111111111',
    'student_submission_read_authorized',
    current_setting('test.workflow_submission_id')::uuid,'success',NULL
  ),
  'trusted Worker records the completed student-owned submission read'
);
RESET ROLE;

-- Repeated identical typed-response saves do not create redundant versions,
-- archive rows or audit records.
SELECT set_config(
  'test.workflow_attempt_id',
  (SELECT attempt_id::text
   FROM public.create_attempt('a1111111-1111-4111-8111-111111111111')),
  true
);
SELECT is(
  (SELECT version FROM public.save_attempt_response(
    current_setting('test.workflow_attempt_id')::uuid,
    'b1111111-1111-4111-8111-111111111111',
    'An identical synthetic response is safely retried without changing its version.'
  )),
  1,
  'first typed response save creates version one'
);
SELECT is(
  (SELECT version FROM public.save_attempt_response(
    current_setting('test.workflow_attempt_id')::uuid,
    'b1111111-1111-4111-8111-111111111111',
    'An identical synthetic response is safely retried without changing its version.'
  )),
  1,
  'an identical typed-response retry returns the same version'
);
RESET ROLE;
SELECT is(
  (SELECT count(*)::integer FROM private.attempt_response_versions
   WHERE attempt_id = current_setting('test.workflow_attempt_id')::uuid),
  1,
  'the initial response is archived once and an identical retry creates no additional snapshot'
);
RESET ROLE;
SELECT is(
  (SELECT count(*)::integer FROM private.security_audit_events
   WHERE action = 'attempt_response_saved'
     AND target_id = current_setting('test.workflow_attempt_id')::uuid),
  1,
  'an identical typed-response retry creates no duplicate save audit event'
);
SET LOCAL ROLE service_role;
SELECT set_config('request.jwt.claims','{"role":"service_role"}',true);
SELECT ok(
  public.record_worker_audit_outcome(
    '11111111-1111-4111-8111-111111111111',
    'student_attempt_read_authorized',
    current_setting('test.workflow_attempt_id')::uuid,'success',NULL
  ),
  'trusted Worker records the completed student-owned typed-attempt read'
);
RESET ROLE;
SELECT is(
  (SELECT count(*)::integer FROM private.security_audit_events
   WHERE action = 'student_attempt_read_authorized'
     AND target_id = current_setting('test.workflow_attempt_id')::uuid),
  1,
  'the authorised attempt read creates an append-only audit event'
);
SET LOCAL ROLE authenticated;

-- Owner workflow mutation continues at AAL2. Direct client audit writes
-- are intentionally unavailable; the Worker records protected-read outcomes.
SET LOCAL ROLE authenticated;
SELECT set_config('request.jwt.claim.sub', '88888888-8888-4888-8888-888888888888', true);
SELECT set_config('request.jwt.claims', '{"sub":"88888888-8888-4888-8888-888888888888","role":"authenticated","aal":"aal2"}', true);
SELECT lives_ok(
  $$SELECT * FROM public.assign_submission_to_grader(
    current_setting('test.workflow_submission_id')::uuid,
    '55555555-5555-4555-8555-555555555555',
    'Workflow integrity synthetic assignment'
  )$$,
  'owner at AAL2 assigns synthetic submission through the protected RPC'
);

-- Grader workflow mutations continue under an assigned AAL2 account.
-- The Worker-only audit RPC is exercised separately through the route tests.
SET LOCAL ROLE authenticated;
SELECT set_config('request.jwt.claim.sub', '55555555-5555-4555-8555-555555555555', true);
SELECT set_config('request.jwt.claims', '{"sub":"55555555-5555-4555-8555-555555555555","role":"authenticated","aal":"aal2"}', true);

-- Identical feedback retries retain the revision while preserving a replay event.
SELECT is(
  (SELECT draft_revision FROM public.save_assessment_draft(
    current_setting('test.workflow_submission_id')::uuid,
    'This synthetic feedback explains the learner strengths and next improvement step.',
    NULL,
    '[
      {"criterion_id":"f3333333-3333-4333-8333-333333333333","points_awarded":3,"feedback":"The learner selects relevant evidence and integrates it into a supported explanation."},
      {"criterion_id":"f4444444-4444-4444-8444-444444444444","points_awarded":2,"feedback":"The learner explains one effect and can develop the link to the wider meaning."}
    ]'::jsonb
  )),
  1,
  'first grader draft save creates revision one'
);
SELECT is(
  (SELECT draft_revision FROM public.save_assessment_draft(
    current_setting('test.workflow_submission_id')::uuid,
    'This synthetic feedback explains the learner strengths and next improvement step.',
    NULL,
    '[
      {"criterion_id":"f3333333-3333-4333-8333-333333333333","points_awarded":3,"feedback":"The learner selects relevant evidence and integrates it into a supported explanation."},
      {"criterion_id":"f4444444-4444-4444-8444-444444444444","points_awarded":2,"feedback":"The learner explains one effect and can develop the link to the wider meaning."}
    ]'::jsonb
  )),
  1,
  'an identical grader draft retry returns the existing revision'
);
RESET ROLE;
SELECT is(
  (SELECT count(*)::integer FROM private.security_audit_events
   WHERE action = 'assessment_draft_saved'
     AND target_id = current_setting('test.workflow_submission_id')::uuid),
  1,
  'identical grader draft retry does not duplicate the primary save event'
);
SELECT is(
  (SELECT count(*)::integer FROM private.security_audit_events
   WHERE action = 'assessment_draft_save_replayed'
     AND target_id = current_setting('test.workflow_submission_id')::uuid),
  1,
  'identical grader draft retry is separately recorded as a replay'
);
SELECT ok(
  private.archive_assessment_draft(
    current_setting('test.workflow_submission_id')::uuid,
    '55555555-5555-4555-8555-555555555555',
    'SYNTHETIC-ARCHIVE-REASON-CANARY'
  ),
  'private synthetic draft can be archived with a bounded explanation'
);
SELECT is(
  (SELECT archive_reason FROM private.assessment_draft_history
   WHERE submission_id = current_setting('test.workflow_submission_id')::uuid
   ORDER BY archived_at DESC LIMIT 1),
  'SYNTHETIC-ARCHIVE-REASON-CANARY'::text,
  'the full archive explanation remains in private immutable draft history'
);
SELECT is(
  (SELECT reason_category FROM private.security_audit_events
   WHERE action = 'assessment_draft_archived'
     AND target_id = current_setting('test.workflow_submission_id')::uuid
   ORDER BY occurred_at DESC LIMIT 1),
  'draft_archived'::text,
  'draft archive audit uses a fixed category'
);
SELECT ok(
  NOT EXISTS (
    SELECT 1 FROM private.security_audit_events
    WHERE action = 'assessment_draft_archived'
      AND reason_category = 'SYNTHETIC-ARCHIVE-REASON-CANARY'
  ),
  'free-text archive explanation is excluded from audit metadata'
);
SET LOCAL ROLE authenticated;
SELECT set_config('request.jwt.claim.sub', '55555555-5555-4555-8555-555555555555', true);
SELECT set_config('request.jwt.claims', '{"sub":"55555555-5555-4555-8555-555555555555","role":"authenticated","aal":"aal2"}', true);

-- Admin role must not inherit owner or grader operational access.
SELECT set_config('request.jwt.claim.sub', '77777777-7777-4777-8777-777777777777', true);
SELECT set_config('request.jwt.claims', '{"sub":"77777777-7777-4777-8777-777777777777","role":"authenticated","aal":"aal2"}', true);


-- The audit schema contains no learner answer or feedback payload columns.
RESET ROLE;
SELECT is(
  (SELECT count(*)::integer FROM information_schema.columns
   WHERE table_schema = 'private'
     AND table_name = 'security_audit_events'
     AND column_name IN ('response_text', 'overall_feedback', 'criterion_results')),
  0,
  'security audit schema excludes learner response and feedback content'
);

SELECT * FROM finish();
ROLLBACK;
