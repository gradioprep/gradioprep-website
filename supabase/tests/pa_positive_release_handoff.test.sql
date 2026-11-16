BEGIN;
SELECT no_plan();

-- End-to-end POSITIVE release handoff, deliberately synthetic and rolled back.
-- Never seed real Year 4 progression, mapping, calibrated marks, or approval.
-- Founder academic-review authority was already decided; this is engineering QA.
CREATE TEMP TABLE synthetic_pa_release_state(rubric_id uuid,receipt_id uuid);
GRANT SELECT,INSERT,UPDATE ON synthetic_pa_release_state TO authenticated;

SELECT is((SELECT release_state FROM public.diagnostic_versions
 WHERE id='ed222222-2222-4222-8222-222222222222'),'draft',
 'synthetic full 30-observation instrument starts as a hidden draft');

-- Build an isolated TEST-only route while it is still pending. Real route
-- records lock unit additions after verification, so exercise proper ordering.
INSERT INTO public.curriculum_route_versions (
 id,route_key,version,awarding_body,programme_code,subject_code,course_code,
 level_code,level_label,academic_session,syllabus_edition,official_source_title,
 official_source_url,source_checked_at,review_state
) VALUES (
 'fe000000-0000-4000-8000-000000000001','synthetic-ib-myp-year-4',99,
 'TEST','SYNTHETIC','ENGLISH','SYNTHETIC-PA',
 'SYN-Y4','Synthetic only','synthetic-session','synthetic-edition',
 'Fictional positive-path test; not official IB material',
 'https://example.invalid/pa-positive-release',clock_timestamp(),'pending_review'
);
UPDATE public.diagnostic_versions
 SET route_version_id='fe000000-0000-4000-8000-000000000001'
 WHERE id='ed222222-2222-4222-8222-222222222222';
INSERT INTO public.curriculum_unit_versions(
  id,route_version_id,unit_code,version,sequence_number,title,
  learning_objective_summary,release_state
) VALUES (
  'fe000000-0000-4000-8000-000000000101',
  'fe000000-0000-4000-8000-000000000001',
  'SYN-STEP8-UNIT',1,91,'Synthetic-only acceptance unit',
  'Synthetic direct mappings for transaction-rolled-back CI; not an IB unit.','draft'
);
INSERT INTO public.curriculum_unit_outcome_mappings(
  curriculum_unit_version_id,outcome_reference,outcome_title,source_locator,
  mapping_status,mapping_rationale,reviewed_by,reviewed_at
)
SELECT 'fe000000-0000-4000-8000-000000000101',
  'SYN-'||o.observation_code,
  'Synthetic outcome for '||o.observation_code,
  'No authorised source — CI test observation '||o.observation_code,
  'direct','Fictional mapping for positive database test only.',
  '88888888-8888-4888-8888-888888888888',clock_timestamp()
FROM public.diagnostic_observations o
WHERE o.diagnostic_version_id='ed222222-2222-4222-8222-222222222222';
UPDATE public.curriculum_route_versions
 SET review_state='verified',verified_by='88888888-8888-4888-8888-888888888888',
     verified_at=clock_timestamp()
 WHERE id='fe000000-0000-4000-8000-000000000001';
UPDATE public.curriculum_unit_versions SET release_state='published'
WHERE id='fe000000-0000-4000-8000-000000000101';

INSERT INTO public.diagnostic_observation_outcome_mappings(
  diagnostic_version_id,diagnostic_observation_id,route_version_id,
  curriculum_unit_version_id,curriculum_unit_outcome_mapping_id,
  mapping_status,mapping_rationale,reviewed_by,reviewed_at
)
SELECT o.diagnostic_version_id,o.id,
  'fe000000-0000-4000-8000-000000000001',
  'fe000000-0000-4000-8000-000000000101',
  m.id,'direct','Synthetic CI-only direct outcome mapping.',
  '88888888-8888-4888-8888-888888888888',clock_timestamp()
FROM public.diagnostic_observations o
JOIN public.curriculum_unit_outcome_mappings m
  ON m.curriculum_unit_version_id='fe000000-0000-4000-8000-000000000101'
 AND m.outcome_reference='SYN-'||o.observation_code
WHERE o.diagnostic_version_id='ed222222-2222-4222-8222-222222222222';

-- This never enables the actual draft: the SQL transaction ROLLBACK at EOF.
UPDATE public.diagnostic_observations SET learner_capture_enabled=true
WHERE diagnostic_version_id='ed222222-2222-4222-8222-222222222222';

SET LOCAL ROLE authenticated;
SELECT set_config('request.jwt.claim.sub','88888888-8888-4888-8888-888888888888',true);
SELECT set_config('request.jwt.claims',
 '{"sub":"88888888-8888-4888-8888-888888888888","role":"authenticated","aal":"aal2"}',true);
SELECT is((SELECT count(*)::integer FROM
 public.inspect_pa_academic_readiness('ed222222-2222-4222-8222-222222222222')
 WHERE learner_capture_enabled AND reviewed_direct_mapping_present),30,
 'Owner AAL2 sees exactly thirty mocked reviewed direct mappings');

-- The helper is intentionally private, so exercise its state validation as
-- the migration owner (not as an authenticated client without EXECUTE).
RESET ROLE;
-- A complete-looking rubric or a chat approval cannot authorise a real
-- Year 4 scored report while the instrument is still a hidden draft.
SELECT throws_ok($q$SELECT private.assert_pa_full_scored_release_ready(
 'ed222222-2222-4222-8222-222222222222',repeat('a',64))$q$,
 '55000','pa_full_scored_report_requires_academic_evidence',
 'real Year 4 scored publication refuses an unreleased draft without evidence');

-- Mappings and enabled capture alone cannot publish without a real private
-- rubric/evidence receipt. The new publication safeguard must reject it.
RESET ROLE;
SELECT throws_ok($q$UPDATE public.diagnostic_versions SET release_state='published'
 WHERE id='ed222222-2222-4222-8222-222222222222'$q$,
 '55000','pa_publication_requires_exact_academic_evidence',
 'mapped 30-observation draft stays blocked until evidence receipt');
SET LOCAL ROLE authenticated;
SELECT set_config('request.jwt.claim.sub','88888888-8888-4888-8888-888888888888',true);
SELECT set_config('request.jwt.claims',
 '{"sub":"88888888-8888-4888-8888-888888888888","role":"authenticated","aal":"aal2"}',true);

-- The rubric function must now accept exact authentic records BEFORE
-- publication (previously impossible circular sequencing).
INSERT INTO synthetic_pa_release_state(rubric_id)
SELECT public.approve_pa_scoring_rubric(
 'ed222222-2222-4222-8222-222222222222',repeat('a',64),
 (SELECT jsonb_agg(jsonb_build_object('code',observation_code,'max_points',4)
   ORDER BY sequence_number)
  FROM public.diagnostic_observations
  WHERE diagnostic_version_id='ed222222-2222-4222-8222-222222222222'),
 'Synthetic academic review reference only',
 'Synthetic calibration reference only',
 'Synthetic rubric maxima prove DB acceptance, not actual academic approval.');

SELECT ok((SELECT rubric_id FROM synthetic_pa_release_state) IS NOT NULL,
 'Owner can store exact 30-dimension rubric before instrument publication');

UPDATE synthetic_pa_release_state SET receipt_id=public.record_pa_release_evidence(
 'ed222222-2222-4222-8222-222222222222',rubric_id,
 'Synthetic route/source only — never an authorised IB Year 4 source',
 repeat('b',64),repeat('c',64),repeat('d',64),repeat('e',64),
 'Fictional source, teacher pack and calibration hashes for local CI only.');
SELECT ok((SELECT receipt_id FROM synthetic_pa_release_state) IS NOT NULL,
 'Owner can bind source, crosswalk, teacher packs and calibration hashes to the exact rubric');
RESET ROLE;

-- All structural gates now permit TEST publication. The transaction below is
-- ALWAYS rolled back, so there is no actual learner-facing v2 publication.
UPDATE public.diagnostic_versions SET release_state='published'
WHERE id='ed222222-2222-4222-8222-222222222222';
SELECT is((SELECT release_state FROM public.diagnostic_versions
 WHERE id='ed222222-2222-4222-8222-222222222222'),'published',
 'synthetic full PA passes both mapping and academic-evidence release gates');
-- Full scored-report publication checks the exact matching academic receipt,
-- not merely a 30-observation JSON snapshot or arbitrary rubric digest.
SELECT lives_ok($q$SELECT private.assert_pa_full_scored_release_ready(
 'ed222222-2222-4222-8222-222222222222',repeat('a',64))$q$,
 'published TEST-only instrument with exact rubric and receipt clears scored-report academic gate');
SELECT throws_ok($q$SELECT private.assert_pa_full_scored_release_ready(
 'ed222222-2222-4222-8222-222222222222',repeat('f',64))$q$,
 '55000','pa_full_scored_report_requires_academic_evidence',
 'different rubric fingerprint cannot reuse a release receipt');
SELECT throws_ok($q$SELECT private.assert_pa_full_scored_release_ready(
 'ed111111-1111-4111-8111-111111111111',repeat('a',64))$q$,
 '55000','pa_full_scored_report_requires_academic_evidence',
 'old 15-observation version cannot impersonate reviewed 30-dimension Year 4 rubric');

SELECT is((SELECT count(*)::integer FROM private.pa_release_evidence_receipts
 WHERE diagnostic_version_id='ed222222-2222-4222-8222-222222222222'),1,
 'one immutable audit-linked receipt for the exact synthetic version');
SELECT is((SELECT count(*)::integer FROM private.pa_rubric_approvals
 WHERE diagnostic_version_id='ed222222-2222-4222-8222-222222222222'),1,
 'synthetic rubric has exactly one version-matched 30-dimension record');
SELECT is((SELECT count(*)::integer FROM public.diagnostic_observations
 WHERE diagnostic_version_id='ed222222-2222-4222-8222-222222222222'
 AND group_code='L'),0,
 'even structurally ready full PA excludes Listening');


-- Integrated POSITIVE acceptance: actual submitted synthetic Year 4 PA v2 ->
-- all 18 saved response sources -> 30 directly mapped report observations ->
-- witnessed SP -> Owner private rubric marks and teacher approval -> immutable
-- scored report -> learner-only readback. Every row is rolled back at EOF.
CREATE TEMP TABLE synthetic_pa_scored_state(
  report_id uuid, source_version_id uuid, score_draft_id uuid,
  score_review_id uuid, feedback_draft_id uuid, feedback_review_id uuid,
  joint_id uuid
);
GRANT SELECT,INSERT,UPDATE ON synthetic_pa_scored_state TO authenticated;

INSERT INTO public.diagnostic_attempts(
 id,learner_id,diagnostic_version_id,status,idempotency_key)
VALUES ('fe000000-0000-4000-8000-000000000301',
 '11111111-1111-4111-8111-111111111111',
 'ed222222-2222-4222-8222-222222222222','in_progress',
 'fe000000-0000-4000-8000-000000000302');

-- Exercise the same strict sitting transitions used by real learners.
-- Responses can be captured only during an active sitting.
SET LOCAL ROLE authenticated;
SELECT set_config('request.jwt.claim.sub','11111111-1111-4111-8111-111111111111',true);
SELECT set_config('request.jwt.claims',
 '{"sub":"11111111-1111-4111-8111-111111111111","role":"authenticated","aal":"aal1"}',true);
SELECT is((SELECT sitting_number FROM public.start_pa_sitting(
 'fe000000-0000-4000-8000-000000000301',1)),1,
 'synthetic full PA first sitting starts under learner authorisation');
RESET ROLE;

INSERT INTO public.diagnostic_response_versions(
 attempt_id,observation_id,revision_number,response_json)
SELECT 'fe000000-0000-4000-8000-000000000301',o.id,1,
 jsonb_build_object('synthetic_response','CI first sitting response for '||o.observation_code)
FROM public.diagnostic_observations o
WHERE o.diagnostic_version_id='ed222222-2222-4222-8222-222222222222'
 AND o.sitting_number=1 AND
 (o.group_code IN ('RV','LC') OR o.observation_code IN ('AW01','CW01','SP01'));

SET LOCAL ROLE authenticated;
SELECT set_config('request.jwt.claim.sub','11111111-1111-4111-8111-111111111111',true);
SELECT set_config('request.jwt.claims',
 '{"sub":"11111111-1111-4111-8111-111111111111","role":"authenticated","aal":"aal1"}',true);
SELECT is(public.complete_pa_sitting(
 'fe000000-0000-4000-8000-000000000301',1),true,
 'first sitting completes only with all required source responses');
SELECT is((SELECT sitting_number FROM public.start_pa_sitting(
 'fe000000-0000-4000-8000-000000000301',2)),2,
 'second sitting starts after completion of first');
RESET ROLE;

INSERT INTO public.diagnostic_response_versions(
 attempt_id,observation_id,revision_number,response_json)
SELECT 'fe000000-0000-4000-8000-000000000301',o.id,1,
 jsonb_build_object('synthetic_response','CI second sitting response for '||o.observation_code)
FROM public.diagnostic_observations o
WHERE o.diagnostic_version_id='ed222222-2222-4222-8222-222222222222'
 AND o.sitting_number=2 AND
 (o.group_code IN ('RV','LC') OR o.observation_code IN ('AW01','CW01','SP01'));

SET LOCAL ROLE authenticated;
SELECT set_config('request.jwt.claim.sub','11111111-1111-4111-8111-111111111111',true);
SELECT set_config('request.jwt.claims',
 '{"sub":"11111111-1111-4111-8111-111111111111","role":"authenticated","aal":"aal1"}',true);
SELECT is(public.complete_pa_sitting(
 'fe000000-0000-4000-8000-000000000301',2),true,
 'second sitting completes with all writing and presentation evidence');
SELECT is((SELECT status FROM public.submit_diagnostic_attempt(
 'fe000000-0000-4000-8000-000000000301')),'submitted',
 'full Year 4 PA submits through the guarded learner workflow');
RESET ROLE;

SELECT is((SELECT count(*)::integer FROM public.diagnostic_response_versions
 WHERE attempt_id='fe000000-0000-4000-8000-000000000301'),18,
 'real PA response snapshot input has exactly 18 synthetic source responses');

SET LOCAL ROLE authenticated;
SELECT set_config('request.jwt.claim.sub','11111111-1111-4111-8111-111111111111',true);
SELECT set_config('request.jwt.claims',
 '{"sub":"11111111-1111-4111-8111-111111111111","role":"authenticated","aal":"aal1"}',true);
INSERT INTO synthetic_pa_scored_state(report_id,source_version_id)
SELECT report_record_id,report_version_id FROM public.create_preliminary_evaluation_report(
 'fe000000-0000-4000-8000-000000000301',
 (SELECT id FROM public.course_enrolments
  WHERE learner_id='11111111-1111-4111-8111-111111111111'
    AND pathway_id='synthetic-ib-myp-year-4'),
 'fe000000-0000-4000-8000-000000000001',
 'fe000000-0000-4000-8000-000000000305');
SELECT is((SELECT curriculum_mapping_status FROM public.get_evaluation_report(
 (SELECT report_id FROM synthetic_pa_scored_state),NULL)),
 'complete_direct','submitted synthetic PA report retains all 30 real mapping rows');
SELECT is((SELECT evidence_sufficiency_status FROM public.get_evaluation_report(
 (SELECT report_id FROM synthetic_pa_scored_state),NULL)),
 'sufficient','18 captured response sources satisfy 30 direct observation dimensions');
SELECT ok((SELECT eligible_analytics_snapshot->'pa_human_scoring' IS NULL
 FROM public.get_evaluation_report((SELECT report_id FROM synthetic_pa_scored_state),NULL)),
 'learner sees no private marks before Owner publication');
RESET ROLE;

INSERT INTO private.pa_spoken_performance_evidence(
 report_record_id,report_version_id,assessor_id,presentation_observation,
 followup_observation,observed_live)
SELECT report_id,source_version_id,'88888888-8888-4888-8888-888888888888',
 'Synthetic witnessed live SP presentation for CI only.',
 'Synthetic witnessed follow-up for CI only.',true
FROM synthetic_pa_scored_state;

SET LOCAL ROLE authenticated;
SELECT set_config('request.jwt.claim.sub','88888888-8888-4888-8888-888888888888',true);
SELECT set_config('request.jwt.claims',
 '{"sub":"88888888-8888-4888-8888-888888888888","role":"authenticated","aal":"aal2"}',true);
SELECT is((SELECT mapping_and_evidence_complete
 FROM public.inspect_pa_scoring_evidence(
 (SELECT report_id FROM synthetic_pa_scored_state))),true,
 'owner witness and all 30 mapped response dimensions pass real evidence audit');

UPDATE synthetic_pa_scored_state
SET score_draft_id=public.create_pa_scoring_draft(
 source_version_id,(SELECT rubric_id FROM synthetic_pa_release_state),
 (SELECT jsonb_agg(jsonb_build_object('code',o.observation_code,'points',2)
     ORDER BY o.sequence_number)
  FROM public.diagnostic_observations o
  WHERE o.diagnostic_version_id='ed222222-2222-4222-8222-222222222222'));
UPDATE synthetic_pa_scored_state
SET score_review_id=public.review_pa_scoring_draft(
 score_draft_id,'approved_private',
 'CI-only human scoring acceptance using a synthetic four-point scale.');
UPDATE synthetic_pa_scored_state
SET feedback_draft_id=public.create_pa_evaluation_feedback_draft(
 source_version_id,'Synthetic exact-version feedback for thirty scored observations.');
UPDATE synthetic_pa_scored_state
SET feedback_review_id=public.review_pa_evaluation_feedback_draft(
 feedback_draft_id,'approved_for_publication',
 'Synthetic-only teacher decision, not a real academic release.');
UPDATE synthetic_pa_scored_state
SET joint_id=public.approve_private_pa_report_composition(
 score_review_id,feedback_review_id,
 'Synthetic joint review binds human marks and feedback at one exact version.');

SELECT is((SELECT (public.get_private_pa_scored_report_review_manifest(
 (SELECT joint_id FROM synthetic_pa_scored_state))
 ->'private_attainment'->>'points_possible')::numeric),120::numeric,
 'joint reviewed manifest reconciles exact 30 maxima with 120 test points');

-- Deliberately invalidate an unrelated released version: the actual scorer
-- must not be able to substitute the old partial Year 4 instrument.
SELECT throws_ok($q$SELECT private.assert_pa_full_scored_release_ready(
 'ed111111-1111-4111-8111-111111111111',repeat('a',64))$q$,
 '42501',NULL,'private evidence helper stays inaccessible to staff clients');
RESET ROLE;

-- The helper's private EXECUTE permission stays unchanged; publication
-- reaches it only through the existing SECURITY DEFINER scored-report RPC.
SET LOCAL ROLE authenticated;
SELECT set_config('request.jwt.claim.sub','88888888-8888-4888-8888-888888888888',true);
SELECT set_config('request.jwt.claims',
 '{"sub":"88888888-8888-4888-8888-888888888888","role":"authenticated","aal":"aal2"}',true);
SELECT is((SELECT version_number FROM public.publish_approved_pa_scored_report(
 (SELECT joint_id FROM synthetic_pa_scored_state),
 'fe000000-0000-4000-8000-000000000361')),2,
 'exactly linked Year 4 source, rubric and release receipt allow a scored report');
SELECT is((SELECT is_replay FROM public.publish_approved_pa_scored_report(
 (SELECT joint_id FROM synthetic_pa_scored_state),
 'fe000000-0000-4000-8000-000000000361')),true,
 'scored Year 4 report publish replay is idempotent');
RESET ROLE;

SET LOCAL ROLE authenticated;
SELECT set_config('request.jwt.claim.sub','11111111-1111-4111-8111-111111111111',true);
SELECT set_config('request.jwt.claims',
 '{"sub":"11111111-1111-4111-8111-111111111111","role":"authenticated","aal":"aal1"}',true);
SELECT is((SELECT (eligible_analytics_snapshot->'pa_human_scoring'->>'dimension_count')::integer
 FROM public.get_evaluation_report(
 (SELECT report_id FROM synthetic_pa_scored_state),2)),30,
 'learner readback contains 30 only-after-release human-scored dimensions');
SELECT is((SELECT (eligible_analytics_snapshot->'pa_human_scoring'->>'attainment_percent')::numeric
 FROM public.get_evaluation_report(
 (SELECT report_id FROM synthetic_pa_scored_state),2)),50::numeric,
 'learner readback computes fifty percent only from synthetic accepted human marks');
SELECT is((SELECT published_feedback_snapshot->>'status'
 FROM public.get_evaluation_report(
 (SELECT report_id FROM synthetic_pa_scored_state),2)),
 'human_approved_published','same-version human feedback is included in learner readback');
SELECT ok((SELECT eligible_analytics_snapshot->'pa_human_scoring'->>'official_ib_grade' IS NULL
 AND eligible_analytics_snapshot->'pa_human_scoring'->>'rank' IS NULL
 AND eligible_analytics_snapshot->'pa_human_scoring'->>'percentile' IS NULL
 FROM public.get_evaluation_report(
 (SELECT report_id FROM synthetic_pa_scored_state),2)),
 'integrated genuine-code regression never invents official grades or cohort rankings');
RESET ROLE;

SELECT * FROM finish();
ROLLBACK;
