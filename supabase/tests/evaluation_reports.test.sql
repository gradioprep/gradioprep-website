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

SELECT throws_ok($q$SELECT * FROM public.list_pa_evaluation_review_queue()$q$,
  '42501','pa_report_queue_forbidden','unrelated learner cannot enumerate private PA staff review queue');
RESET ROLE;

SET LOCAL ROLE authenticated;
SELECT set_config('request.jwt.claim.sub','88888888-8888-4888-8888-888888888888',true);
SELECT set_config('request.jwt.claims','{"sub":"88888888-8888-4888-8888-888888888888","role":"authenticated","aal":"aal2"}',true);
SELECT is((SELECT count(*)::integer FROM public.get_evaluation_report(
  '1d000000-0000-4000-8000-000000000401',NULL)),1,
  'Owner at AAL2 can inspect the report through the audited RPC');

SELECT is((SELECT count(*)::integer FROM public.list_pa_evaluation_teacher_grants(
  '1d000000-0000-4000-8000-000000000401')),0,
  'Owner sees no Grader assignments before assigning a reviewer');

SELECT is((SELECT count(*)::integer FROM public.list_pa_evaluation_review_queue()),1,
  'AAL2 Owner can discover the synthetic PA report oldest-first');
SELECT is((SELECT report_record_id FROM public.list_pa_evaluation_review_queue(1)),
  '1d000000-0000-4000-8000-000000000401'::uuid,
  'Owner queue returns exact report record identity, not learner personal data');
SELECT throws_ok($q$SELECT * FROM public.list_pa_evaluation_review_queue(51)$q$,
  '22023','invalid_pa_report_queue_limit','staff queue rejects limits over fifty');

INSERT INTO report_access_test_state
SELECT access_grant_id FROM public.grant_evaluation_report_teacher_access(
  '1d000000-0000-4000-8000-000000000401','55555555-5555-4555-8555-555555555555','Synthetic report-specific teacher grant'
);
SELECT is((SELECT count(*)::integer FROM public.list_pa_evaluation_teacher_grants(
  '1d000000-0000-4000-8000-000000000401')),1,
  'Owner sees assigned Grader through the restricted list');
RESET ROLE;

SET LOCAL ROLE authenticated;
SELECT set_config('request.jwt.claim.sub','55555555-5555-4555-8555-555555555555',true);
SELECT set_config('request.jwt.claims','{"sub":"55555555-5555-4555-8555-555555555555","role":"authenticated","aal":"aal2"}',true);
SELECT is((SELECT count(*)::integer FROM public.get_evaluation_report('1d000000-0000-4000-8000-000000000401',NULL)),1,
  'AAL2 Grader with an active report-specific grant can read the report');

SELECT throws_ok($q$SELECT * FROM public.list_pa_evaluation_teacher_grants(
  '1d000000-0000-4000-8000-000000000401')$q$,
  '42501','pa_report_grants_forbidden',
  'assigned Grader cannot enumerate private reviewer assignments');

SELECT is((SELECT count(*)::integer FROM public.list_pa_evaluation_review_queue()),1,
  'AAL2 Grader queue lists only report-specific active grants');
RESET ROLE;

SET LOCAL ROLE authenticated;
SELECT set_config('request.jwt.claim.sub','88888888-8888-4888-8888-888888888888',true);
SELECT set_config('request.jwt.claims','{"sub":"88888888-8888-4888-8888-888888888888","role":"authenticated","aal":"aal2"}',true);
SELECT is(public.revoke_evaluation_report_teacher_access((SELECT grant_id FROM report_access_test_state),'Synthetic access review complete'),true,
  'Owner at AAL2 can revoke a report-specific teacher grant');

SELECT is((SELECT count(*)::integer FROM public.list_pa_evaluation_teacher_grants(
  '1d000000-0000-4000-8000-000000000401')),0,
  'Owner reviewer list immediately reflects revocation');
RESET ROLE;

SET LOCAL ROLE authenticated;
SELECT set_config('request.jwt.claim.sub','55555555-5555-4555-8555-555555555555',true);
SELECT set_config('request.jwt.claims','{"sub":"55555555-5555-4555-8555-555555555555","role":"authenticated","aal":"aal2"}',true);
SELECT throws_ok($q$SELECT * FROM public.get_evaluation_report('1d000000-0000-4000-8000-000000000401',NULL)$q$,
  '42501','evaluation_report_read_forbidden','revoked teacher grant immediately denies report access');

SELECT is((SELECT count(*)::integer FROM public.list_pa_evaluation_review_queue()),0,
  'revoked Grader queue access disappears immediately');
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



-- Review decisions remain private and cannot make an unverified baseline publishable.
CREATE TEMP TABLE pa_feedback_review_test_state AS
  SELECT id AS draft_id FROM private.pa_evaluation_feedback_drafts LIMIT 1;
GRANT SELECT ON pa_feedback_review_test_state TO authenticated;

SET LOCAL ROLE authenticated;
SELECT set_config('request.jwt.claim.sub','11111111-1111-4111-8111-111111111111',true);
SELECT set_config('request.jwt.claims','{"sub":"11111111-1111-4111-8111-111111111111","role":"authenticated","aal":"aal1"}',true);
SELECT throws_ok($q$SELECT public.review_pa_evaluation_feedback_draft(
  (SELECT draft_id FROM pa_feedback_review_test_state),'changes_requested','More evidence needed.')$q$,
  '42501','pa_feedback_review_forbidden','student cannot decide feedback review');
SELECT throws_ok($q$SELECT * FROM public.get_pa_evaluation_feedback_reviews(
  '1d000000-0000-4000-8000-000000000401')$q$,
  '42501','pa_feedback_review_read_forbidden','student cannot read private review decisions');
RESET ROLE;

SET LOCAL ROLE authenticated;
SELECT set_config('request.jwt.claim.sub','88888888-8888-4888-8888-888888888888',true);
SELECT set_config('request.jwt.claims','{"sub":"88888888-8888-4888-8888-888888888888","role":"authenticated","aal":"aal1"}',true);
SELECT throws_ok($q$SELECT public.review_pa_evaluation_feedback_draft(
  (SELECT draft_id FROM pa_feedback_review_test_state),'changes_requested','More evidence needed.')$q$,
  '42501','pa_feedback_review_forbidden','Owner AAL1 cannot make review decisions');
RESET ROLE;

SET LOCAL ROLE authenticated;
SELECT set_config('request.jwt.claim.sub','55555555-5555-4555-8555-555555555555',true);
SELECT set_config('request.jwt.claims','{"sub":"55555555-5555-4555-8555-555555555555","role":"authenticated","aal":"aal2"}',true);
SELECT throws_ok($q$SELECT public.review_pa_evaluation_feedback_draft(
  (SELECT draft_id FROM pa_feedback_review_test_state),'changes_requested','More evidence needed.')$q$,
  '42501','pa_feedback_review_forbidden','Grader AAL2 cannot impersonate Founder reviewer');
RESET ROLE;

SET LOCAL ROLE authenticated;
SELECT set_config('request.jwt.claim.sub','88888888-8888-4888-8888-888888888888',true);
SELECT set_config('request.jwt.claims','{"sub":"88888888-8888-4888-8888-888888888888","role":"authenticated","aal":"aal2"}',true);
SELECT throws_ok($q$SELECT public.review_pa_evaluation_feedback_draft(
  (SELECT draft_id FROM pa_feedback_review_test_state),'approved_for_publication','Approved with missing official evidence.')$q$,
  '55000','pa_feedback_review_requires_complete_verified_evidence',
  'Owner cannot approve feedback for a mapped-incomplete and evidence-insufficient PA');
SELECT ok(public.review_pa_evaluation_feedback_draft(
  (SELECT draft_id FROM pa_feedback_review_test_state),'changes_requested',
  'Provide reviewed curriculum links and actual response evidence before approval.') IS NOT NULL,
  'Founder can request changes to a private report draft');
SELECT is((SELECT count(*)::integer FROM public.get_pa_evaluation_feedback_reviews(
  '1d000000-0000-4000-8000-000000000401')),1,
  'Owner can inspect private review decisions through scoped RPC');
SELECT throws_ok($q$SELECT public.review_pa_evaluation_feedback_draft(
  (SELECT draft_id FROM pa_feedback_review_test_state),'changes_requested','Do the revisions again.')$q$,
  '23505',NULL,'same draft cannot receive a contradictory second decision');
RESET ROLE;

SELECT is((SELECT count(*)::integer FROM private.pa_evaluation_feedback_reviews
  WHERE decision='approved_for_publication'),0,
  'no human approval is fabricated for the insufficient synthetic report');
SELECT is((SELECT published_feedback_snapshot->>'status'
  FROM public.evaluation_report_versions LIMIT 1),'not_applicable_unscored_preliminary_assessment',
  'private review decision does not alter immutable learner report');
SELECT throws_ok($q$UPDATE private.pa_evaluation_feedback_reviews
  SET decision='approved_for_publication'$q$,'42501','pa_feedback_draft_immutable',
  'private review decisions are immutable');
SELECT is((SELECT count(*)::integer FROM private.security_audit_events
  WHERE action='pa_feedback_review_decided' AND reason_category='changes_requested_private'),1,
  'review decision emits one metadata-only audit event');


-- Entirely synthetic positive publication regression; no real curriculum approval or learner data.
-- Create a separate TEST-only version of the existing report, with synthetic complete evidence.
INSERT INTO public.evaluation_report_versions(
  report_record_id,report_scope,learner_id,version_number,idempotency_key,supersedes_version_id,
  curriculum_mapping_status,evidence_sufficiency_status,scope_snapshot,content_snapshot,
  unit_set_snapshot,curriculum_mapping_snapshot,learner_evidence_snapshot,
  published_feedback_snapshot,eligible_analytics_snapshot,created_by)
SELECT v.report_record_id,v.report_scope,v.learner_id,2,
  '1d000000-0000-4000-8000-000000000611',v.id,
  'complete_direct','sufficient',v.scope_snapshot,v.content_snapshot,v.unit_set_snapshot,
  (SELECT jsonb_agg(jsonb_set(jsonb_set(m.value,'{mapping_status}','"direct"'::jsonb),
    '{direct_outcomes}',jsonb_build_array(jsonb_build_object('outcome_reference','SYN-ONLY-TEST')))
    ORDER BY m.ordinality)
    FROM jsonb_array_elements(v.curriculum_mapping_snapshot) WITH ORDINALITY AS m(value,ordinality)),
  (SELECT jsonb_agg(jsonb_set(e.value,'{response_sha256}',to_jsonb(repeat('a',64))) ORDER BY e.ordinality)
    FROM jsonb_array_elements(v.learner_evidence_snapshot) WITH ORDINALITY AS e(value,ordinality)),
  v.published_feedback_snapshot,v.eligible_analytics_snapshot,'88888888-8888-4888-8888-888888888888'
FROM public.evaluation_report_versions AS v WHERE v.version_number=1;

CREATE TEMP TABLE pa_publication_test_state(report_version_id uuid,draft_id uuid,review_id uuid);
GRANT SELECT, INSERT, UPDATE ON pa_publication_test_state TO authenticated;

SET LOCAL ROLE authenticated;
SELECT set_config('request.jwt.claim.sub','88888888-8888-4888-8888-888888888888',true);
SELECT set_config('request.jwt.claims','{"sub":"88888888-8888-4888-8888-888888888888","role":"authenticated","aal":"aal2"}',true);
INSERT INTO pa_publication_test_state(report_version_id,draft_id)
SELECT v.id,public.create_pa_evaluation_feedback_draft(v.id,
  'Synthetic teacher-approved text for the publication-path regression only.')
FROM public.get_evaluation_report('1d000000-0000-4000-8000-000000000401',2) AS v;
UPDATE pa_publication_test_state
SET review_id=public.review_pa_evaluation_feedback_draft(draft_id,'approved_for_publication',
  'Synthetic positive decision for regression only; not a real academic approval.');
RESET ROLE;

SET LOCAL ROLE authenticated;
SELECT set_config('request.jwt.claim.sub','11111111-1111-4111-8111-111111111111',true);
SELECT set_config('request.jwt.claims','{"sub":"11111111-1111-4111-8111-111111111111","role":"authenticated","aal":"aal1"}',true);
SELECT throws_ok($q$SELECT * FROM public.publish_pa_evaluation_feedback(
  (SELECT review_id FROM pa_publication_test_state),'1d000000-0000-4000-8000-000000000612')$q$,
  '42501','pa_feedback_publication_forbidden','learner cannot publish an approved private review');
RESET ROLE;

SET LOCAL ROLE authenticated;
SELECT set_config('request.jwt.claim.sub','88888888-8888-4888-8888-888888888888',true);
SELECT set_config('request.jwt.claims','{"sub":"88888888-8888-4888-8888-888888888888","role":"authenticated","aal":"aal2"}',true);
SELECT is((SELECT version_number FROM public.publish_pa_evaluation_feedback(
  (SELECT review_id FROM pa_publication_test_state),'1d000000-0000-4000-8000-000000000612')),3,
  'Founder publishes a new immutable report version after exact review');
SELECT is((SELECT is_replay FROM public.publish_pa_evaluation_feedback(
  (SELECT review_id FROM pa_publication_test_state),'1d000000-0000-4000-8000-000000000612')),true,
  'publication retries are idempotent');
SELECT throws_ok($q$SELECT * FROM public.publish_pa_evaluation_feedback(
  (SELECT review_id FROM pa_publication_test_state),'1d000000-0000-4000-8000-000000000613')$q$,
  '55000','pa_feedback_publication_requirements_not_met',
  'same review cannot be published as a second new report version');
RESET ROLE;

SET LOCAL ROLE authenticated;
SELECT set_config('request.jwt.claim.sub','11111111-1111-4111-8111-111111111111',true);
SELECT set_config('request.jwt.claims','{"sub":"11111111-1111-4111-8111-111111111111","role":"authenticated","aal":"aal1"}',true);
SELECT is((SELECT version_number FROM public.get_evaluation_report(
  '1d000000-0000-4000-8000-000000000401',NULL)),3,
  'learner sees newest published report version through existing read API');
SELECT is((SELECT published_feedback_snapshot->>'status' FROM public.get_evaluation_report(
  '1d000000-0000-4000-8000-000000000401',NULL)),'human_approved_published',
  'learner report contains only explicitly approved published text');
SELECT ok((SELECT published_feedback_snapshot->>'feedback_text' LIKE 'Synthetic teacher-approved%'
  FROM public.get_evaluation_report('1d000000-0000-4000-8000-000000000401',NULL)),
  'learner can see published feedback but no private reviewer note');
RESET ROLE;

SELECT is((SELECT count(*)::integer FROM public.evaluation_report_versions),3,
  'publication added exactly one report version without changing prior versions');
SELECT is((SELECT published_feedback_snapshot->>'status'
  FROM public.evaluation_report_versions WHERE version_number=1),
  'not_applicable_unscored_preliminary_assessment','original learner report remains unchanged');
SELECT ok((SELECT published_feedback_snapshot->>'reviewer_note' IS NULL
  FROM public.evaluation_report_versions WHERE version_number=3),
  'private reviewer note never enters published report');
SELECT is((SELECT count(*)::integer FROM private.security_audit_events
  WHERE action='pa_feedback_published' AND reason_category='owner_approved_report'),1,
  'exactly one publication audit event despite replay');

SET LOCAL ROLE authenticated;
SELECT set_config('request.jwt.claim.sub','88888888-8888-4888-8888-888888888888',true);
SELECT set_config('request.jwt.claims','{"sub":"88888888-8888-4888-8888-888888888888","role":"authenticated","aal":"aal1"}',true);
SELECT throws_ok($q$SELECT * FROM public.list_pa_evaluation_review_queue()$q$,
  '42501','pa_report_queue_forbidden','Owner at AAL1 cannot enumerate PA feedback queue');
RESET ROLE;

-- Scoped private oral performance tests. All identities and content are synthetic.
CREATE TEMP TABLE pa_spoken_test_state AS
  SELECT id AS report_version_id FROM public.evaluation_report_versions
  WHERE report_record_id='1d000000-0000-4000-8000-000000000401' AND version_number=3;
GRANT SELECT ON pa_spoken_test_state TO authenticated;

INSERT INTO public.diagnostic_observations(
  id,diagnostic_version_id,observation_code,group_code,sitting_number,
  sequence_number,response_kind,learner_capture_enabled
) VALUES (
  '1d000000-0000-4000-8000-000000000721',
  '1d000000-0000-4000-8000-000000000501',
  'SP01','SP',2,60,'text',false
);
INSERT INTO public.diagnostic_response_versions(
  attempt_id,observation_id,revision_number,response_json
) VALUES (
  '1d000000-0000-4000-8000-000000000301',
  '1d000000-0000-4000-8000-000000000721',1,
  '{"title":"Synthetic speaking outline","opening":"Recommendation","development":"Example","consideration":"Concern","closing":"Next step"}'::jsonb
);
SET LOCAL ROLE authenticated;
SELECT set_config('request.jwt.claim.sub','11111111-1111-4111-8111-111111111111',true);
SELECT set_config('request.jwt.claims','{"sub":"11111111-1111-4111-8111-111111111111","role":"authenticated","aal":"aal1"}',true);
SELECT throws_ok($q$SELECT public.record_pa_spoken_performance(
  '1d000000-0000-4000-8000-000000000401',
  (SELECT report_version_id FROM pa_spoken_test_state),
  'This is a fake learner claim of presenting the plan.',
  'This is a fake learner claim of answering the question.',true)$q$,
  '42501','pa_spoken_evidence_forbidden','learner cannot self-certify oral evidence');
SELECT throws_ok($q$SELECT * FROM public.get_pa_spoken_performance(
  '1d000000-0000-4000-8000-000000000401')$q$,
  '42501','pa_spoken_evidence_forbidden','learner cannot read private assessor notes');
RESET ROLE;
SET LOCAL ROLE authenticated;
SELECT set_config('request.jwt.claim.sub','88888888-8888-4888-8888-888888888888',true);
SELECT set_config('request.jwt.claims','{"sub":"88888888-8888-4888-8888-888888888888","role":"authenticated","aal":"aal1"}',true);
SELECT throws_ok($q$SELECT public.record_pa_spoken_performance(
  '1d000000-0000-4000-8000-000000000401',
  (SELECT report_version_id FROM pa_spoken_test_state),
  'Observed a clear presentation developing the proposal.',
  'Observed a response addressing the standard concern.',true)$q$,
  '42501','pa_spoken_evidence_forbidden','Owner without MFA cannot record oral evidence');
RESET ROLE;
SET LOCAL ROLE authenticated;
SELECT set_config('request.jwt.claim.sub','88888888-8888-4888-8888-888888888888',true);
SELECT set_config('request.jwt.claims','{"sub":"88888888-8888-4888-8888-888888888888","role":"authenticated","aal":"aal2"}',true);
SELECT throws_ok($q$SELECT public.record_pa_spoken_performance(
  '1d000000-0000-4000-8000-000000000401',
  (SELECT report_version_id FROM pa_spoken_test_state),
  'Observed a clear presentation developing the proposal.',
  'Observed a response addressing the standard concern.',false)$q$,
  '22023','invalid_pa_spoken_evidence','assessor must attest to witnessing live speech');
SELECT ok(public.record_pa_spoken_performance(
  '1d000000-0000-4000-8000-000000000401',
  (SELECT report_version_id FROM pa_spoken_test_state),
  'Observed coherent explanation and a practical example.',
  'Observed a reasoned response to another preference.',true) IS NOT NULL,
  'Owner at MFA may append witnessed evidence to the exact PA report version');
SELECT is((SELECT count(*)::integer FROM public.get_pa_spoken_performance(
  '1d000000-0000-4000-8000-000000000401')),1,
  'Owner may read private observed performance');
RESET ROLE;
SELECT throws_ok($q$UPDATE private.pa_spoken_performance_evidence
  SET presentation_observation='changed'$q$,'42501','pa_feedback_draft_immutable',
  'human oral observation records cannot be changed');
SELECT is((SELECT count(*)::integer FROM private.security_audit_events
  WHERE action='pa_spoken_evidence_recorded' AND reason_category='private_human_observation'),1,
  'successful oral performance evidence creation emits metadata-only audit');
SELECT is((SELECT count(*)::integer FROM public.evaluation_report_versions),3,
  'private speaking observations do not fabricate a new learner report');
SELECT is((SELECT count(*)::integer FROM private.pa_spoken_performance_evidence),1,
  'one witnessed performance record remains private');

-- Full-instrument, fabricated TEST-only report snapshots exercise the exact
-- 30-dimension evidence audit. These are not approved PA curriculum records or marks.
INSERT INTO public.evaluation_report_versions(
  report_record_id,report_scope,learner_id,version_number,idempotency_key,supersedes_version_id,
  curriculum_mapping_status,evidence_sufficiency_status,scope_snapshot,content_snapshot,
  unit_set_snapshot,curriculum_mapping_snapshot,learner_evidence_snapshot,
  published_feedback_snapshot,eligible_analytics_snapshot,created_by)
SELECT v.report_record_id,v.report_scope,v.learner_id,4,
  '1d000000-0000-4000-8000-000000000831',v.id,
  'complete_direct','sufficient',v.scope_snapshot,
  jsonb_set(v.content_snapshot,'{observations}',
    (SELECT jsonb_agg(jsonb_build_object(
      'observation_code',o.observation_code,'group_code',o.group_code,
      'capture_enabled',true,'sitting_number',o.sitting_number)
      ORDER BY o.sequence_number)
     FROM public.diagnostic_observations o
     WHERE o.diagnostic_version_id='ed222222-2222-4222-8222-222222222222')),
  v.unit_set_snapshot,
  (SELECT jsonb_agg(jsonb_build_object(
    'observation_code',o.observation_code,'mapping_status','direct',
    'direct_outcomes',jsonb_build_array(jsonb_build_object('outcome_reference','TEST-ONLY')))
    ORDER BY o.sequence_number)
   FROM public.diagnostic_observations o
   WHERE o.diagnostic_version_id='ed222222-2222-4222-8222-222222222222'),
  (SELECT jsonb_agg(jsonb_build_object(
    'observation_code',o.observation_code,
    'source_response_observation_code',CASE WHEN o.group_code IN ('AW','CW','SP')
      THEN o.group_code||'01' ELSE o.observation_code END,
    'response_sha256',repeat('a',64)) ORDER BY o.sequence_number)
   FROM public.diagnostic_observations o
   WHERE o.diagnostic_version_id='ed222222-2222-4222-8222-222222222222'),
  v.published_feedback_snapshot,v.eligible_analytics_snapshot,
  '88888888-8888-4888-8888-888888888888'
FROM public.evaluation_report_versions v WHERE v.version_number=3;

SET LOCAL ROLE authenticated;
SELECT set_config('request.jwt.claim.sub','88888888-8888-4888-8888-888888888888',true);
SELECT set_config('request.jwt.claims',
  '{"sub":"88888888-8888-4888-8888-888888888888","role":"authenticated","aal":"aal2"}',true);
SELECT is((SELECT expected_dimensions FROM public.inspect_pa_scoring_evidence(
  '1d000000-0000-4000-8000-000000000401')),30,
  'the full synthetic rubric snapshot has thirty dimensions');
SELECT is((SELECT directly_mapped_dimensions FROM public.inspect_pa_scoring_evidence(
  '1d000000-0000-4000-8000-000000000401')),30,
  'each synthetic dimension has exactly one direct mapping');
SELECT is((SELECT evidenced_dimensions FROM public.inspect_pa_scoring_evidence(
  '1d000000-0000-4000-8000-000000000401')),30,
  'five dimensions per AW/CW/SP shared response count correctly as distinct evidence');
SELECT is((SELECT mapping_and_evidence_complete FROM public.inspect_pa_scoring_evidence(
  '1d000000-0000-4000-8000-000000000401')),false,
  'oral live-performance evidence is mandatory even when every outline is present');
RESET ROLE;

-- Synthetic staff witness for report version 4 only.
INSERT INTO private.pa_spoken_performance_evidence(
 report_record_id,report_version_id,assessor_id,presentation_observation,followup_observation,observed_live)
SELECT v.report_record_id,v.id,'88888888-8888-4888-8888-888888888888',
  'Synthetic witnessed presentation evidence for the full thirty-dimension regression.',
  'Synthetic witnessed follow-up evidence for the full thirty-dimension regression.',true
FROM public.evaluation_report_versions v WHERE v.version_number=4;
SET LOCAL ROLE authenticated;
SELECT set_config('request.jwt.claim.sub','88888888-8888-4888-8888-888888888888',true);
SELECT set_config('request.jwt.claims',
  '{"sub":"88888888-8888-4888-8888-888888888888","role":"authenticated","aal":"aal2"}',true);
SELECT is((SELECT mapping_and_evidence_complete FROM public.inspect_pa_scoring_evidence(
  '1d000000-0000-4000-8000-000000000401')),true,
  'complete synthetic structure and a same-version witness satisfy structural evidence gate');
SELECT is((SELECT scoring_state FROM public.inspect_pa_scoring_evidence(
  '1d000000-0000-4000-8000-000000000401')),'human_rubric_approval_required',
  'even structurally sufficient test snapshots never imply rubric approval or grades');
RESET ROLE;

-- Synthetic human-scoring review regression. All rubric maxima, marks,
-- review notes and evidence are deliberately fabricated and rolled back.
INSERT INTO private.pa_rubric_approvals(
  id,diagnostic_version_id,rubric_sha256,dimension_maxima,
  academic_review_reference,assessor_calibration_reference,approval_note,approved_by)
SELECT '1d000000-0000-4000-8000-000000000851',
  '1d000000-0000-4000-8000-000000000501',repeat('b',64),
  jsonb_agg(jsonb_build_object('code',o.observation_code,'max_points',4)
    ORDER BY o.sequence_number),
  'Synthetic academic approval fixture','Synthetic assessor calibration fixture',
  'Synthetic only, regression does not constitute human approval.',
  '88888888-8888-4888-8888-888888888888'
FROM public.diagnostic_observations o
WHERE o.diagnostic_version_id='ed222222-2222-4222-8222-222222222222';
INSERT INTO private.pa_scoring_drafts(
  id,report_record_id,report_version_id,rubric_approval_id,
  scorer_id,dimension_marks,response_evidence_sha256)
SELECT '1d000000-0000-4000-8000-000000000852',v.report_record_id,v.id,
  '1d000000-0000-4000-8000-000000000851',
  '88888888-8888-4888-8888-888888888888',
  (SELECT jsonb_agg(jsonb_build_object('code',o.observation_code,'points',2)
    ORDER BY o.sequence_number)
    FROM public.diagnostic_observations o
    WHERE o.diagnostic_version_id='ed222222-2222-4222-8222-222222222222'),
  encode(extensions.digest(v.learner_evidence_snapshot::text,'sha256'),'hex')
FROM public.evaluation_report_versions v WHERE v.version_number=4;

SET LOCAL ROLE authenticated;
SELECT set_config('request.jwt.claim.sub','11111111-1111-4111-8111-111111111111',true);
SELECT set_config('request.jwt.claims',
  '{"sub":"11111111-1111-4111-8111-111111111111","role":"authenticated","aal":"aal1"}',true);
SELECT throws_ok($q$SELECT public.review_pa_scoring_draft(
 '1d000000-0000-4000-8000-000000000852','approved_private',
 'Learner cannot approve internal scoring.')$q$,
 '42501','pa_scoring_review_forbidden','learner cannot approve scoring');
SELECT throws_ok($q$SELECT * FROM public.get_private_pa_scoring_review(
 '1d000000-0000-4000-8000-000000000853')$q$,
 '42501','pa_scoring_review_read_forbidden','learner cannot access internal results');
RESET ROLE;
SET LOCAL ROLE authenticated;
SELECT set_config('request.jwt.claim.sub','88888888-8888-4888-8888-888888888888',true);
SELECT set_config('request.jwt.claims',
  '{"sub":"88888888-8888-4888-8888-888888888888","role":"authenticated","aal":"aal1"}',true);
SELECT throws_ok($q$SELECT public.review_pa_scoring_draft(
 '1d000000-0000-4000-8000-000000000852','approved_private',
 'MFA is mandatory for staff approval.')$q$,
 '42501','pa_scoring_review_forbidden','Owner AAL1 cannot review scores');
SELECT set_config('request.jwt.claims',
  '{"sub":"88888888-8888-4888-8888-888888888888","role":"authenticated","aal":"aal2"}',true);
SELECT throws_ok($q$SELECT public.review_pa_scoring_draft(
 '1d000000-0000-4000-8000-000000000852','not_a_decision',
 'Invalid review decision must fail.')$q$,
 '22023','invalid_pa_scoring_review','unrecognised decision is rejected');
CREATE TEMP TABLE pa_score_test_result(id uuid);
GRANT SELECT ON pa_score_test_result TO authenticated;
INSERT INTO pa_score_test_result
SELECT public.review_pa_scoring_draft(
 '1d000000-0000-4000-8000-000000000852','approved_private',
 'Synthetic human review decision for strictly private regression evidence.');
SELECT is((SELECT points_awarded FROM public.get_private_pa_scoring_review(
 (SELECT id FROM pa_score_test_result))),60::numeric,
 'private approved synthetic score totals the thirty human-marked dimensions');
SELECT is((SELECT points_possible FROM public.get_private_pa_scoring_review(
 (SELECT id FROM pa_score_test_result))),120::numeric,
 'private maximum points derive from the exact approved rubric dimensions');
SELECT is((SELECT attainment_percent FROM public.get_private_pa_scoring_review(
 (SELECT id FROM pa_score_test_result))),50::numeric,
 'private attainment is derived with a nonzero rubric denominator');
SELECT throws_ok($q$SELECT public.review_pa_scoring_draft(
 '1d000000-0000-4000-8000-000000000852','changes_requested',
 'A conflicting review must not overwrite the original.')$q$,
 '23505',NULL,'a scoring draft cannot receive contradictory decisions');
RESET ROLE;
SELECT ok((SELECT eligible_analytics_snapshot->>'score' IS NULL
  AND eligible_analytics_snapshot->>'official_grade' IS NULL
  FROM public.evaluation_report_versions WHERE version_number=4),
  'human-reviewed private scores do not leak into learner report analytics');
SELECT throws_ok($q$UPDATE private.pa_scoring_reviews SET decision='changes_requested'$q$,
  '42501','pa_feedback_draft_immutable','private human scoring decisions are immutable');
SELECT is((SELECT count(*)::integer FROM private.security_audit_events
  WHERE action='pa_scoring_review_decided'),1,
  'private approval records exactly one metadata-only security audit');
  
-- New immutable report version deliberately misattributes AW02 to LC01.
INSERT INTO public.evaluation_report_versions(
  report_record_id,report_scope,learner_id,version_number,idempotency_key,supersedes_version_id,
  curriculum_mapping_status,evidence_sufficiency_status,scope_snapshot,content_snapshot,
  unit_set_snapshot,curriculum_mapping_snapshot,learner_evidence_snapshot,
  published_feedback_snapshot,eligible_analytics_snapshot,created_by)
SELECT v.report_record_id,v.report_scope,v.learner_id,5,
  '1d000000-0000-4000-8000-000000000832',v.id,
  v.curriculum_mapping_status,v.evidence_sufficiency_status,v.scope_snapshot,v.content_snapshot,
  v.unit_set_snapshot,v.curriculum_mapping_snapshot,
  (SELECT jsonb_agg(CASE WHEN item->>'observation_code'='AW02'
    THEN jsonb_set(item,'{source_response_observation_code}',to_jsonb('LC01'::text))
    ELSE item END ORDER BY ordinality)
   FROM jsonb_array_elements(v.learner_evidence_snapshot)
     WITH ORDINALITY AS e(item,ordinality)),
  v.published_feedback_snapshot,v.eligible_analytics_snapshot,
  '88888888-8888-4888-8888-888888888888'
FROM public.evaluation_report_versions v WHERE v.version_number=4;
SET LOCAL ROLE authenticated;
SELECT set_config('request.jwt.claim.sub','88888888-8888-4888-8888-888888888888',true);
SELECT set_config('request.jwt.claims',
  '{"sub":"88888888-8888-4888-8888-888888888888","role":"authenticated","aal":"aal2"}',true);
SELECT is((SELECT evidenced_dimensions FROM public.inspect_pa_scoring_evidence(
  '1d000000-0000-4000-8000-000000000401')),29,
  'mismatched AW dimension source is rejected despite a present response hash');
SELECT is((SELECT mapping_and_evidence_complete FROM public.inspect_pa_scoring_evidence(
  '1d000000-0000-4000-8000-000000000401')),false,
  'newer invalid evidence cannot inherit a preceding report version witness');
RESET ROLE;

SELECT * FROM finish();
ROLLBACK;
