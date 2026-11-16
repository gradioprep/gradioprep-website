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

SELECT * FROM finish();
ROLLBACK;
