BEGIN;
SELECT no_plan();

-- Temporary fixture state for report-specific grader-access grant/revocation assertions.
CREATE TEMP TABLE report_access_test_state (grant_id uuid PRIMARY KEY);
GRANT SELECT, INSERT ON report_access_test_state TO authenticated;

-- Synthetic-only PA baseline report fixture. No curriculum outcome is inferred.
INSERT INTO public.curriculum_route_versions (
  id,route_key,version,awarding_body,programme_code,subject_code,course_code,level_code,level_label,
  academic_session,syllabus_edition,official_source_title,official_source_url,source_checked_at,review_state
)
VALUES (
  '1d000000-0000-4000-8000-000000000001','synthetic-ib-myp-year-4',99,'TEST','SYNTHETIC','ENGLISH',
  'SYNTHETIC-PA','SYNTHETIC-Y4','Synthetic only','synthetic-session','synthetic-edition',
  'Synthetic test fixture — not an official source','https://example.invalid/pa-report-fixture',clock_timestamp(),'pending_review'
);

INSERT INTO public.curriculum_unit_versions (
  id,route_version_id,unit_code,version,sequence_number,title,learning_objective_summary,release_state
)
VALUES ('1d000000-0000-4000-8000-000000000101','1d000000-0000-4000-8000-000000000001',
  'SYN-PA-UNIT',1,1,'Synthetic PA unit','Synthetic test-only unit.','draft');

INSERT INTO public.curriculum_unit_outcome_mappings (
  id,curriculum_unit_version_id,outcome_reference,outcome_title,source_locator,
  mapping_status,mapping_rationale,reviewed_by,reviewed_at
)
VALUES ('1d000000-0000-4000-8000-000000000201','1d000000-0000-4000-8000-000000000101',
  'SYN-PA-OUTCOME','Synthetic outcome','No official locator — synthetic only',
  'pending','Synthetic test fixture only.',NULL,NULL);

UPDATE public.curriculum_route_versions
SET review_state='verified',verified_by='88888888-8888-4888-8888-888888888888',verified_at=clock_timestamp()
WHERE id='1d000000-0000-4000-8000-000000000001';
UPDATE public.curriculum_unit_outcome_mappings
SET mapping_status='direct',reviewed_by='88888888-8888-4888-8888-888888888888',reviewed_at=clock_timestamp()
WHERE id='1d000000-0000-4000-8000-000000000201';
UPDATE public.curriculum_unit_versions SET release_state='published'
WHERE id='1d000000-0000-4000-8000-000000000101';

INSERT INTO public.diagnostic_versions (
  id,diagnostic_code,pathway_id,title,version,release_state,total_minutes,sitting_count,route_version_id
)
VALUES (
  '1d000000-0000-4000-8000-000000000501','synthetic-pa-report','synthetic-ib-myp-year-4',
  'Synthetic PA report fixture',99,'published',80,2,'1d000000-0000-4000-8000-000000000001'
);
INSERT INTO public.diagnostic_observations (
  diagnostic_version_id,observation_code,group_code,sitting_number,sequence_number,response_kind,learner_capture_enabled
)
SELECT '1d000000-0000-4000-8000-000000000501',observation_code,group_code,sitting_number,
  sequence_number,response_kind,learner_capture_enabled
FROM public.diagnostic_observations
WHERE diagnostic_version_id='ed111111-1111-4111-8111-111111111111';

INSERT INTO public.diagnostic_observation_outcome_mappings (
  diagnostic_version_id,diagnostic_observation_id,route_version_id,curriculum_unit_version_id,
  curriculum_unit_outcome_mapping_id,mapping_status,mapping_rationale,reviewed_by,reviewed_at
)
SELECT '1d000000-0000-4000-8000-000000000501',observation.id,
  '1d000000-0000-4000-8000-000000000001','1d000000-0000-4000-8000-000000000101',
  '1d000000-0000-4000-8000-000000000201','direct','Synthetic direct mapping for regression only.',
  '88888888-8888-4888-8888-888888888888',clock_timestamp()
FROM public.diagnostic_observations AS observation
WHERE observation.diagnostic_version_id='1d000000-0000-4000-8000-000000000501'
  AND observation.sequence_number=1;

SELECT throws_ok($q$UPDATE public.diagnostic_observation_outcome_mappings
  SET mapping_rationale='attempt to rewrite reviewed mapping'
  WHERE diagnostic_version_id='1d000000-0000-4000-8000-000000000501'$q$,
  '55000','diagnostic_outcome_mapping_immutable','reviewed direct PA mappings cannot be changed');

SELECT throws_ok($q$UPDATE public.diagnostic_versions SET route_version_id=NULL
  WHERE id='1d000000-0000-4000-8000-000000000501'$q$,
  '55000','published_diagnostic_route_immutable','published Diagnostic route lineage cannot be changed');

INSERT INTO public.diagnostic_attempts (
  id,learner_id,diagnostic_version_id,status,idempotency_key,submitted_at
)
VALUES (
  '1d000000-0000-4000-8000-000000000301','11111111-1111-4111-8111-111111111111',
  '1d000000-0000-4000-8000-000000000501','submitted',
  '1d000000-0000-4000-8000-000000000302',clock_timestamp()
);

-- The test deliberately supplies no PA observation mapping or response evidence.
INSERT INTO public.evaluation_report_records (
  id,report_scope,learner_id,course_enrolment_id,route_version_id,diagnostic_attempt_id
)
VALUES (
  '1d000000-0000-4000-8000-000000000401','pa_baseline','11111111-1111-4111-8111-111111111111',
  (SELECT id FROM public.course_enrolments WHERE learner_id='11111111-1111-4111-8111-111111111111'
    AND pathway_id='synthetic-ib-myp-year-4'),
  '1d000000-0000-4000-8000-000000000001','1d000000-0000-4000-8000-000000000301'
);

SET LOCAL ROLE authenticated;
SELECT set_config('request.jwt.claim.sub','11111111-1111-4111-8111-111111111111',true);
SELECT set_config('request.jwt.claims','{"sub":"11111111-1111-4111-8111-111111111111","role":"authenticated","aal":"aal1"}',true);

SELECT throws_ok($q$SELECT * FROM public.evaluation_report_records$q$,'42501',NULL,
  'learner cannot bypass the audited report-read RPC with direct table access');
SELECT throws_ok(
  $$INSERT INTO public.evaluation_report_records(report_scope,learner_id,course_enrolment_id,route_version_id,diagnostic_attempt_id)
    VALUES('pa_baseline',auth.uid(),'00000000-0000-0000-0000-000000000000','1d000000-0000-4000-8000-000000000001','1d000000-0000-4000-8000-000000000301')$$,
  '42501',NULL,'learner cannot directly create report records');

SELECT * FROM public.create_preliminary_evaluation_report(
  '1d000000-0000-4000-8000-000000000301',
  (SELECT id FROM public.course_enrolments WHERE learner_id='11111111-1111-4111-8111-111111111111'
    AND pathway_id='synthetic-ib-myp-year-4'),
  '1d000000-0000-4000-8000-000000000001',
  '1d000000-0000-4000-8000-000000000303'
);
SELECT is((SELECT is_replay FROM public.create_preliminary_evaluation_report(
  '1d000000-0000-4000-8000-000000000301',
  (SELECT id FROM public.course_enrolments WHERE learner_id='11111111-1111-4111-8111-111111111111'
    AND pathway_id='synthetic-ib-myp-year-4'),
  '1d000000-0000-4000-8000-000000000001',
  '1d000000-0000-4000-8000-000000000303'
)),true,'same PA report idempotency key returns the immutable original version');

SELECT is((SELECT count(*)::integer FROM public.get_evaluation_report(
  '1d000000-0000-4000-8000-000000000401',NULL)),1,
  'learner can read own PA baseline through the audited report-read RPC');
RESET ROLE;

SELECT is((SELECT count(*)::integer FROM public.evaluation_report_versions),1,
  'one immutable PA report version is created');
SELECT is((SELECT curriculum_mapping_status FROM public.evaluation_report_versions),'contains_unmapped',
  'PA report records missing direct mappings instead of inventing curriculum claims');
SELECT is((SELECT evidence_sufficiency_status FROM public.evaluation_report_versions),'insufficient',
  'PA report labels missing response and mapping evidence insufficient');
SELECT is((SELECT curriculum_mapping_snapshot->0->>'mapping_status'
  FROM public.evaluation_report_versions),'direct',
  'synthetic reviewed direct mapping is captured for the corresponding PA observation');
SELECT is((SELECT curriculum_mapping_snapshot->0->'direct_outcomes'->0->>'outcome_reference'
  FROM public.evaluation_report_versions),'SYN-PA-OUTCOME',
  'report includes the actual mapped outcome reference from the reviewed synthetic record');
SELECT ok((SELECT NOT EXISTS (
  SELECT 1 FROM jsonb_array_elements(curriculum_mapping_snapshot) AS entry
  WHERE entry->>'observation_code' <> 'RV01'
    AND jsonb_array_length(entry->'direct_outcomes') <> 0
) FROM public.evaluation_report_versions),
  'unmapped observations expose no fabricated curriculum outcome references');

SELECT is((SELECT scope_snapshot->>'report_scoring_state' FROM public.evaluation_report_versions),'unscored_baseline',
  'PA baseline is explicitly unscored');
SELECT ok((SELECT eligible_analytics_snapshot->>'score' IS NULL
  AND eligible_analytics_snapshot->>'official_grade' IS NULL
  AND eligible_analytics_snapshot->>'percentile_or_rank' IS NULL
  FROM public.evaluation_report_versions),
  'PA report contains no invented score, grade or rank');
SELECT ok((SELECT jsonb_array_length(curriculum_mapping_snapshot)=15
  AND jsonb_array_length(learner_evidence_snapshot)=15
  FROM public.evaluation_report_versions),
  'PA snapshot preserves all fifteen enabled observation slots and their missing-evidence states');
SELECT is((SELECT count(*)::integer FROM private.security_audit_events
  WHERE action='evaluation_report_created' AND target_type='evaluation_report_version'),1,
  'report creation writes one metadata-only audit event');

SELECT throws_ok(
  $$UPDATE public.evaluation_report_versions SET evidence_sufficiency_status='sufficient'$$,
  '42501','evaluation_report_immutable','published report versions cannot be changed');
SELECT throws_ok(
  $$UPDATE public.evaluation_report_records SET route_version_id='1d000000-0000-4000-8000-000000000001'$$,
  '42501','evaluation_report_immutable','report-series lineage cannot be changed');

SET LOCAL ROLE authenticated;
SELECT set_config('request.jwt.claim.sub','33333333-3333-4333-8333-333333333333',true);
SELECT set_config('request.jwt.claims','{"sub":"33333333-3333-4333-8333-333333333333","role":"authenticated","aal":"aal1"}',true);
SELECT is((SELECT count(*)::integer FROM public.get_evaluation_report(
  '1d000000-0000-4000-8000-000000000401',NULL)),1,
  'verified guardian with progress consent can read the linked learner report through the audited RPC');
RESET ROLE;

SET LOCAL ROLE authenticated;
SELECT set_config('request.jwt.claim.sub','22222222-2222-4222-8222-222222222222',true);
SELECT set_config('request.jwt.claims','{"sub":"22222222-2222-4222-8222-222222222222","role":"authenticated","aal":"aal1"}',true);
SELECT throws_ok($q$SELECT * FROM public.get_evaluation_report('1d000000-0000-4000-8000-000000000401',NULL)$q$,
  '42501','evaluation_report_read_forbidden','unrelated learner cannot read another learner report');
RESET ROLE;

SET LOCAL ROLE authenticated;
SELECT set_config('request.jwt.claim.sub','88888888-8888-4888-8888-888888888888',true);
SELECT set_config('request.jwt.claims','{"sub":"88888888-8888-4888-8888-888888888888","role":"authenticated","aal":"aal2"}',true);
SELECT is((SELECT count(*)::integer FROM public.get_evaluation_report(
  '1d000000-0000-4000-8000-000000000401',NULL)),1,
  'Owner at AAL2 can inspect the report through the audited RPC');

INSERT INTO report_access_test_state
SELECT access_grant_id FROM public.grant_evaluation_report_teacher_access(
  '1d000000-0000-4000-8000-000000000401','55555555-5555-4555-8555-555555555555','Synthetic report-specific teacher grant'
);
RESET ROLE;

SET LOCAL ROLE authenticated;
SELECT set_config('request.jwt.claim.sub','55555555-5555-4555-8555-555555555555',true);
SELECT set_config('request.jwt.claims','{"sub":"55555555-5555-4555-8555-555555555555","role":"authenticated","aal":"aal2"}',true);
SELECT is((SELECT count(*)::integer FROM public.get_evaluation_report('1d000000-0000-4000-8000-000000000401',NULL)),1,
  'AAL2 Grader with an active report-specific grant can read the report');
RESET ROLE;

SET LOCAL ROLE authenticated;
SELECT set_config('request.jwt.claim.sub','88888888-8888-4888-8888-888888888888',true);
SELECT set_config('request.jwt.claims','{"sub":"88888888-8888-4888-8888-888888888888","role":"authenticated","aal":"aal2"}',true);
SELECT is(public.revoke_evaluation_report_teacher_access((SELECT grant_id FROM report_access_test_state),'Synthetic access review complete'),true,
  'Owner at AAL2 can revoke a report-specific teacher grant');
RESET ROLE;

SET LOCAL ROLE authenticated;
SELECT set_config('request.jwt.claim.sub','55555555-5555-4555-8555-555555555555',true);
SELECT set_config('request.jwt.claims','{"sub":"55555555-5555-4555-8555-555555555555","role":"authenticated","aal":"aal2"}',true);
SELECT throws_ok($q$SELECT * FROM public.get_evaluation_report('1d000000-0000-4000-8000-000000000401',NULL)$q$,
  '42501','evaluation_report_read_forbidden','revoked teacher grant immediately denies report access');
RESET ROLE;
SELECT throws_ok(
  $$SELECT * FROM public.create_preliminary_evaluation_report(
    '1d000000-0000-4000-8000-000000000301',
    (SELECT id FROM public.course_enrolments WHERE learner_id='11111111-1111-4111-8111-111111111111'
      AND pathway_id='synthetic-ib-myp-year-4'),
    '1d000000-0000-4000-8000-000000000001',
    '1d000000-0000-4000-8000-000000000304'
  )$$,
  '42501','preliminary_evaluation_report_forbidden','Owner cannot impersonate learner to create a PA report');
RESET ROLE;

-- The trusted Worker may record only report-operation failure outcomes.
SET LOCAL ROLE service_role;
SELECT set_config('request.jwt.claims','{"role":"service_role"}',true);
SELECT ok(public.record_worker_audit_outcome(
  '11111111-1111-4111-8111-111111111111',
  'evaluation_report_create',
  '1d000000-0000-4000-8000-000000000401',
  'failed',
  'operation_failed'
),'service-role Worker can record an allowlisted PA report-creation failure');
SELECT ok(public.record_worker_audit_outcome(
  '11111111-1111-4111-8111-111111111111',
  'evaluation_report_read_authorized',
  '1d000000-0000-4000-8000-000000000401',
  'denied',
  NULL
),'service-role Worker can record a scoped PA report-read denial');
SELECT ok(NOT public.record_worker_audit_outcome(
  '11111111-1111-4111-8111-111111111111',
  'arbitrary_report_action',
  '1d000000-0000-4000-8000-000000000401',
  'failed',
  'operation_failed'
),'unlisted report audit actions are rejected');
RESET ROLE;
SELECT is((SELECT count(*)::integer FROM private.security_audit_events
  WHERE actor_id='11111111-1111-4111-8111-111111111111'
    AND target_id='1d000000-0000-4000-8000-000000000401'
    AND action IN ('evaluation_report_create','evaluation_report_read_authorized')
    AND outcome IN ('failed','denied')),2,
  'Worker report failure audit writes only allowlisted metadata events');

SELECT ok(public.record_worker_audit_outcome(
  '11111111-1111-4111-8111-111111111111','staff_submission_transcript_review',
  '1d000000-0000-4000-8000-000000000401','failed','operation_failed'
),'existing transcript-review audit action remains allowlisted');
SELECT ok(public.record_worker_audit_outcome(
  '11111111-1111-4111-8111-111111111111','student_submission_file_upload',
  '1d000000-0000-4000-8000-000000000401','failed','operation_failed'
),'existing private-file upload audit action remains allowlisted');
SELECT ok(public.record_worker_audit_outcome(
  '11111111-1111-4111-8111-111111111111','owner_submission_file_cleanup',
  NULL,'failed','operation_failed'
),'existing file-cleanup collection audit action remains allowlisted');
SELECT ok(public.record_worker_audit_outcome(
  '11111111-1111-4111-8111-111111111111','staff_attempt_timer_adjustment',
  '1d000000-0000-4000-8000-000000000401','failed','operation_failed'
),'existing timer-adjustment audit action remains allowlisted');
SELECT ok(public.record_worker_audit_outcome(
  '11111111-1111-4111-8111-111111111111','student_timed_attempt_assessment_link',
  '1d000000-0000-4000-8000-000000000401','failed','operation_failed'
),'existing timed-assessment linkage audit action remains allowlisted');
RESET ROLE;

SELECT is((SELECT count(*)::integer FROM private.security_audit_events
  WHERE actor_id='11111111-1111-4111-8111-111111111111'
    AND action IN ('staff_submission_transcript_review','student_submission_file_upload',
      'owner_submission_file_cleanup','staff_attempt_timer_adjustment','student_timed_attempt_assessment_link')
    AND outcome='failed'),5,
  'legacy allowlisted Worker actions remain operational after report audit extension');


-- A test-only identifier avoids having restricted roles query the report table directly.
CREATE TEMP TABLE pa_feedback_test_state AS
  SELECT id AS report_version_id FROM public.evaluation_report_versions LIMIT 1;
GRANT SELECT ON pa_feedback_test_state TO authenticated;

-- Private teacher feedback authoring: never changes the learner's immutable report snapshot.
SET LOCAL ROLE authenticated;
SELECT set_config('request.jwt.claim.sub','11111111-1111-4111-8111-111111111111',true);
SELECT set_config('request.jwt.claims','{"sub":"11111111-1111-4111-8111-111111111111","role":"authenticated","aal":"aal1"}',true);
SELECT throws_ok($q$SELECT public.create_pa_evaluation_feedback_draft(
  (SELECT report_version_id FROM pa_feedback_test_state),
  'This is a private synthetic review draft, not approved feedback.')$q$,
  '42501','pa_feedback_draft_forbidden','learner cannot author private feedback drafts');
SELECT throws_ok($q$SELECT * FROM public.get_pa_evaluation_feedback_drafts(
  '1d000000-0000-4000-8000-000000000401')$q$,
  '42501','pa_feedback_draft_forbidden','learner cannot retrieve private teacher feedback drafts');
SELECT throws_ok($q$SELECT * FROM private.pa_evaluation_feedback_drafts$q$,
  '42501',NULL,'learner cannot directly read private drafts');
RESET ROLE;

SET LOCAL ROLE authenticated;
SELECT set_config('request.jwt.claim.sub','88888888-8888-4888-8888-888888888888',true);
SELECT set_config('request.jwt.claims','{"sub":"88888888-8888-4888-8888-888888888888","role":"authenticated","aal":"aal1"}',true);
SELECT throws_ok($q$SELECT public.create_pa_evaluation_feedback_draft(
  (SELECT report_version_id FROM pa_feedback_test_state),
  'AAL1 must not be able to write teacher feedback drafts.')$q$,
  '42501','pa_feedback_draft_forbidden','Owner without AAL2 cannot author feedback drafts');
RESET ROLE;

SET LOCAL ROLE authenticated;
SELECT set_config('request.jwt.claim.sub','88888888-8888-4888-8888-888888888888',true);
SELECT set_config('request.jwt.claims','{"sub":"88888888-8888-4888-8888-888888888888","role":"authenticated","aal":"aal2"}',true);
SELECT ok(public.create_pa_evaluation_feedback_draft(
  (SELECT report_version_id FROM pa_feedback_test_state),
  'Synthetic private teacher draft. This is unapproved and never shown to the learner.') IS NOT NULL,
  'Owner AAL2 can record an unapproved, version-bound private feedback draft');
SELECT is((SELECT count(*)::integer FROM public.get_pa_evaluation_feedback_drafts(
  '1d000000-0000-4000-8000-000000000401')),1,
  'Owner AAL2 can read the restricted draft through its RPC');
RESET ROLE;

SET LOCAL ROLE authenticated;
SELECT set_config('request.jwt.claim.sub','55555555-5555-4555-8555-555555555555',true);
SELECT set_config('request.jwt.claims','{"sub":"55555555-5555-4555-8555-555555555555","role":"authenticated","aal":"aal2"}',true);
SELECT throws_ok($q$SELECT * FROM public.get_pa_evaluation_feedback_drafts(
  '1d000000-0000-4000-8000-000000000401')$q$,
  '42501','pa_feedback_draft_forbidden','revoked grader access cannot read private drafts');
RESET ROLE;

SELECT is((SELECT published_feedback_snapshot->>'status' FROM public.evaluation_report_versions LIMIT 1),
  'not_applicable_unscored_preliminary_assessment',
  'unapproved private draft never enters the immutable learner report');
SELECT is((SELECT count(*)::integer FROM private.security_audit_events
  WHERE action='pa_feedback_draft_created' AND outcome='success'),1,
  'private draft authoring records metadata-only audit evidence');
SELECT throws_ok($q$UPDATE private.pa_evaluation_feedback_drafts
  SET draft_text='This modification must fail.'$q$,
  '42501','pa_feedback_draft_immutable','private draft revisions must be append-only');


SELECT * FROM finish();
ROLLBACK;
