BEGIN;
SELECT no_plan();

-- All names, curriculum outcomes and task content below are synthetic fixtures only.
INSERT INTO public.curriculum_route_versions (
  id, route_key, version, awarding_body, programme_code, subject_code,
  course_code, level_code, level_label, academic_session, syllabus_edition,
  official_source_title, official_source_url, source_checked_at,
  review_state, verified_by, verified_at
)
VALUES (
  '0d000000-0000-4000-8000-000000000001',
  'synthetic-sa-route',1,'TEST','SYNTHETIC','ENGLISH',
  'SYNTHETIC-COURSE','SYNTHETIC-LEVEL','Synthetic only',
  'synthetic-fixture','not-an-official-edition',
  'Synthetic fixture only — not an official curriculum source',
  'https://example.invalid/synthetic-fixture',
  clock_timestamp(),'pending_review',NULL,NULL
);

INSERT INTO public.curriculum_unit_versions (
  id,route_version_id,unit_code,version,sequence_number,title,
  learning_objective_summary,release_state
)
VALUES
  ('0d000000-0000-4000-8000-000000000101','0d000000-0000-4000-8000-000000000001','SYN-M1',1,1,'Synthetic M1','Synthetic only.','draft'),
  ('0d000000-0000-4000-8000-000000000102','0d000000-0000-4000-8000-000000000001','SYN-M2',1,2,'Synthetic M2','Synthetic only.','draft'),
  ('0d000000-0000-4000-8000-000000000103','0d000000-0000-4000-8000-000000000001','SYN-M3',1,3,'Synthetic M3','Synthetic only.','draft');

INSERT INTO public.curriculum_unit_outcome_mappings (
  id,curriculum_unit_version_id,outcome_reference,outcome_title,source_locator,
  mapping_status,mapping_rationale,reviewed_by,reviewed_at,is_listening_outcome
)
VALUES
  ('0d000000-0000-4000-8000-000000000201','0d000000-0000-4000-8000-000000000101','SYN-OUT-1','Synthetic M1 outcome','Synthetic only — no official locator','direct','Synthetic review fixture.','88888888-8888-4888-8888-888888888888',clock_timestamp(),false),
  ('0d000000-0000-4000-8000-000000000202','0d000000-0000-4000-8000-000000000102','SYN-OUT-2','Synthetic M2 outcome','Synthetic only — no official locator','direct','Synthetic review fixture.','88888888-8888-4888-8888-888888888888',clock_timestamp(),false),
  ('0d000000-0000-4000-8000-000000000203','0d000000-0000-4000-8000-000000000103','SYN-OUT-3','Synthetic M3 listening outcome','Synthetic only — no official locator','direct','Synthetic review fixture.','88888888-8888-4888-8888-888888888888',clock_timestamp(),true),
  ('0d000000-0000-4000-8000-000000000204','0d000000-0000-4000-8000-000000000101','SYN-OUT-LISTEN-M1','Synthetic M1 listening outcome','Synthetic only — no official locator','direct','Synthetic negative test fixture.','88888888-8888-4888-8888-888888888888',clock_timestamp(),true);

UPDATE public.curriculum_route_versions
SET review_state='verified',
    verified_by='88888888-8888-4888-8888-888888888888',
    verified_at=clock_timestamp()
WHERE id='0d000000-0000-4000-8000-000000000001';

UPDATE public.curriculum_unit_versions
SET release_state='published'
WHERE route_version_id='0d000000-0000-4000-8000-000000000001';

INSERT INTO public.milestone_cycle_versions (id,route_version_id,version,release_state)
VALUES ('0d000000-0000-4000-8000-000000000301','0d000000-0000-4000-8000-000000000001',1,'draft');

INSERT INTO public.milestone_segments (
  id,milestone_cycle_version_id,route_version_id,segment_number,title
)
VALUES
  ('0d000000-0000-4000-8000-000000000311','0d000000-0000-4000-8000-000000000301','0d000000-0000-4000-8000-000000000001',1,'Synthetic M1'),
  ('0d000000-0000-4000-8000-000000000312','0d000000-0000-4000-8000-000000000301','0d000000-0000-4000-8000-000000000001',2,'Synthetic M2'),
  ('0d000000-0000-4000-8000-000000000313','0d000000-0000-4000-8000-000000000301','0d000000-0000-4000-8000-000000000001',3,'Synthetic M3');

INSERT INTO public.milestone_unit_memberships (
  id,milestone_cycle_version_id,milestone_segment_id,curriculum_unit_version_id,
  route_version_id,sequence_number,is_required
)
VALUES
  ('0d000000-0000-4000-8000-000000000321','0d000000-0000-4000-8000-000000000301','0d000000-0000-4000-8000-000000000311','0d000000-0000-4000-8000-000000000101','0d000000-0000-4000-8000-000000000001',1,true),
  ('0d000000-0000-4000-8000-000000000322','0d000000-0000-4000-8000-000000000301','0d000000-0000-4000-8000-000000000312','0d000000-0000-4000-8000-000000000102','0d000000-0000-4000-8000-000000000001',1,true),
  ('0d000000-0000-4000-8000-000000000323','0d000000-0000-4000-8000-000000000301','0d000000-0000-4000-8000-000000000313','0d000000-0000-4000-8000-000000000103','0d000000-0000-4000-8000-000000000001',1,true);

UPDATE public.milestone_cycle_versions
SET release_state='published'
WHERE id='0d000000-0000-4000-8000-000000000301';

INSERT INTO public.task_versions (
  id,task_code,pathway_id,title,version,response_mode,
  expected_min_words,ideal_words,release_state
)
VALUES
  ('0d000000-0000-4000-8000-000000000501','SYN-SA1','synthetic-sa-route','Synthetic SA1 task',1,'typed',20,120,'published'),
  ('0d000000-0000-4000-8000-000000000502','SYN-SA1-MISSING','synthetic-sa-route','Synthetic incomplete SA1 task',1,'typed',20,120,'published'),
  ('0d000000-0000-4000-8000-000000000503','SYN-SA3','synthetic-sa-route','Synthetic SA3 task',1,'typed',20,120,'published');

INSERT INTO public.task_version_prompts (
  id,task_version_id,sequence,prompt_text
)
VALUES
  ('0d000000-0000-4000-8000-000000000511','0d000000-0000-4000-8000-000000000501',1,'Synthetic prompt one.'),
  ('0d000000-0000-4000-8000-000000000512','0d000000-0000-4000-8000-000000000501',2,'Synthetic prompt two.'),
  ('0d000000-0000-4000-8000-000000000513','0d000000-0000-4000-8000-000000000502',1,'Synthetic prompt missing a mapping.'),
  ('0d000000-0000-4000-8000-000000000514','0d000000-0000-4000-8000-000000000503',1,'Synthetic M3 Listening prompt.');

INSERT INTO public.milestone_assessment_task_mappings (
  id,task_version_id,route_version_id,milestone_cycle_version_id,
  milestone_segment_id,assessment_code,review_state,mapping_rationale
)
VALUES
  ('0d000000-0000-4000-8000-000000000601','0d000000-0000-4000-8000-000000000501','0d000000-0000-4000-8000-000000000001','0d000000-0000-4000-8000-000000000301','0d000000-0000-4000-8000-000000000311','SA1','draft','Synthetic-only mapping fixture.'),
  ('0d000000-0000-4000-8000-000000000602','0d000000-0000-4000-8000-000000000502','0d000000-0000-4000-8000-000000000001','0d000000-0000-4000-8000-000000000301','0d000000-0000-4000-8000-000000000311','SA1','draft','Synthetic incomplete mapping fixture.'),
  ('0d000000-0000-4000-8000-000000000603','0d000000-0000-4000-8000-000000000503','0d000000-0000-4000-8000-000000000001','0d000000-0000-4000-8000-000000000301','0d000000-0000-4000-8000-000000000313','SA3','draft','Synthetic M3 Listening mapping fixture.');

INSERT INTO public.milestone_assessment_prompt_outcome_mappings (
  id,task_mapping_id,task_version_id,task_version_prompt_id,route_version_id,
  milestone_cycle_version_id,milestone_segment_id,milestone_unit_membership_id,
  curriculum_unit_version_id,curriculum_unit_outcome_mapping_id,
  mapping_status,mapping_rationale,reviewed_by,reviewed_at
)
VALUES
  ('0d000000-0000-4000-8000-000000000611','0d000000-0000-4000-8000-000000000601','0d000000-0000-4000-8000-000000000501','0d000000-0000-4000-8000-000000000511','0d000000-0000-4000-8000-000000000001','0d000000-0000-4000-8000-000000000301','0d000000-0000-4000-8000-000000000311','0d000000-0000-4000-8000-000000000321','0d000000-0000-4000-8000-000000000101','0d000000-0000-4000-8000-000000000201','direct','Synthetic direct mapping.','88888888-8888-4888-8888-888888888888',clock_timestamp()),
  ('0d000000-0000-4000-8000-000000000612','0d000000-0000-4000-8000-000000000601','0d000000-0000-4000-8000-000000000501','0d000000-0000-4000-8000-000000000512','0d000000-0000-4000-8000-000000000001','0d000000-0000-4000-8000-000000000301','0d000000-0000-4000-8000-000000000311','0d000000-0000-4000-8000-000000000321','0d000000-0000-4000-8000-000000000101','0d000000-0000-4000-8000-000000000201','direct','Synthetic direct mapping.','88888888-8888-4888-8888-888888888888',clock_timestamp());

SELECT throws_ok(
  $$
    INSERT INTO public.milestone_assessment_prompt_outcome_mappings (
      id,task_mapping_id,task_version_id,task_version_prompt_id,route_version_id,
      milestone_cycle_version_id,milestone_segment_id,milestone_unit_membership_id,
      curriculum_unit_version_id,curriculum_unit_outcome_mapping_id,
      mapping_status,mapping_rationale,reviewed_by,reviewed_at
    )
    VALUES (
      '0d000000-0000-4000-8000-000000000614',
      '0d000000-0000-4000-8000-000000000601',
      '0d000000-0000-4000-8000-000000000501',
      '0d000000-0000-4000-8000-000000000511',
      '0d000000-0000-4000-8000-000000000001',
      '0d000000-0000-4000-8000-000000000301',
      '0d000000-0000-4000-8000-000000000311',
      '0d000000-0000-4000-8000-000000000321',
      '0d000000-0000-4000-8000-000000000101',
      '0d000000-0000-4000-8000-000000000204',
      'direct','Must not enter SA1.','88888888-8888-4888-8888-888888888888',clock_timestamp()
    )
  $$,
  '55000',
  'milestone_assessment_listening_sa3_only',
  'Listening cannot be mapped into SA1 or SA2'
);

INSERT INTO public.milestone_assessment_prompt_outcome_mappings (
  id,task_mapping_id,task_version_id,task_version_prompt_id,route_version_id,
  milestone_cycle_version_id,milestone_segment_id,milestone_unit_membership_id,
  curriculum_unit_version_id,curriculum_unit_outcome_mapping_id,
  mapping_status,mapping_rationale,reviewed_by,reviewed_at
)
VALUES (
  '0d000000-0000-4000-8000-000000000613',
  '0d000000-0000-4000-8000-000000000603',
  '0d000000-0000-4000-8000-000000000503',
  '0d000000-0000-4000-8000-000000000514',
  '0d000000-0000-4000-8000-000000000001',
  '0d000000-0000-4000-8000-000000000301',
  '0d000000-0000-4000-8000-000000000313',
  '0d000000-0000-4000-8000-000000000323',
  '0d000000-0000-4000-8000-000000000103',
  '0d000000-0000-4000-8000-000000000203',
  'direct','Synthetic M3 direct listening route mapping.','88888888-8888-4888-8888-888888888888',clock_timestamp()
);

UPDATE public.milestone_assessment_task_mappings
SET review_state='approved',
    reviewed_by='88888888-8888-4888-8888-888888888888',
    reviewed_at=clock_timestamp()
WHERE id='0d000000-0000-4000-8000-000000000603';

SELECT throws_ok(
  $$UPDATE public.milestone_assessment_task_mappings
    SET review_state='approved',reviewed_by='88888888-8888-4888-8888-888888888888',reviewed_at=clock_timestamp()
    WHERE id='0d000000-0000-4000-8000-000000000602'$$,
  '55000',
  'milestone_assessment_requires_direct_mapping_for_every_prompt',
  'an SA task mapping cannot be approved while any prompt is unmapped'
);

UPDATE public.milestone_assessment_task_mappings
SET review_state='approved',
    reviewed_by='88888888-8888-4888-8888-888888888888',
    reviewed_at=clock_timestamp()
WHERE id='0d000000-0000-4000-8000-000000000601';

SELECT throws_ok(
  $$UPDATE public.milestone_assessment_task_mappings
    SET assessment_code='SA2'
    WHERE id='0d000000-0000-4000-8000-000000000602'$$,
  '23514',
  'milestone_assessment_code_segment_mismatch',
  'SA code must match the exact M1/M2/M3 segment number'
);

INSERT INTO public.course_enrolments (id,learner_id,pathway_id,status)
VALUES ('0d000000-0000-4000-8000-000000000701','11111111-1111-4111-8111-111111111111','synthetic-sa-route','active');

INSERT INTO public.attempts (id,learner_id,task_version_id,status)
VALUES
  ('0d000000-0000-4000-8000-000000000711','11111111-1111-4111-8111-111111111111','0d000000-0000-4000-8000-000000000501','in_progress'),
  ('0d000000-0000-4000-8000-000000000712','11111111-1111-4111-8111-111111111111','0d000000-0000-4000-8000-000000000501','in_progress');

SELECT throws_ok(
  $$UPDATE public.milestone_assessment_task_mappings
    SET mapping_rationale='Tampered after approval'
    WHERE id='0d000000-0000-4000-8000-000000000601'$$,
  '55000',
  'milestone_assessment_task_mapping_immutable',
  'approved SA task mappings are immutable'
);

SET LOCAL ROLE authenticated;
SELECT set_config('request.jwt.claim.sub','11111111-1111-4111-8111-111111111111',true);
SELECT set_config('request.jwt.claims','{"sub":"11111111-1111-4111-8111-111111111111","role":"authenticated","aal":"aal1"}',true);

SELECT is(
  (SELECT count(*)::integer FROM public.milestone_assessment_task_mappings),
  2,
  'student sees only approved SA task mappings on their active route'
);
SELECT is(
  (SELECT count(*)::integer FROM public.milestone_assessment_prompt_outcome_mappings),
  3,
  'student sees only directly mapped prompts for approved SA1 and SA3 tasks'
);

SELECT throws_ok(
  $$
    SELECT * FROM public.link_milestone_assessment_attempt(
      '0d000000-0000-4000-8000-000000000711',
      '0d000000-0000-4000-8000-000000000701',
      '0d000000-0000-4000-8000-000000000601',
      '0d000000-0000-4000-8000-000000000801'
    )
  $$,
  'P0001',
  'milestone_segment_units_incomplete',
  'SA attempt linking is blocked until every required M1 unit is completed'
);

SELECT lives_ok(
  $$SELECT * FROM public.record_learner_unit_progress(
    '0d000000-0000-4000-8000-000000000701',
    '0d000000-0000-4000-8000-000000000321',
    'completed'
  )$$,
  'synthetic student completes the required M1 unit through the protected progress RPC'
);

SELECT lives_ok(
  $$
    SELECT * FROM public.link_milestone_assessment_attempt(
      '0d000000-0000-4000-8000-000000000711',
      '0d000000-0000-4000-8000-000000000701',
      '0d000000-0000-4000-8000-000000000601',
      '0d000000-0000-4000-8000-000000000801'
    )
  $$,
  'eligible SA attempt is linked to the exact completed M1 set'
);

SELECT is(
  (SELECT is_replay FROM public.link_milestone_assessment_attempt(
    '0d000000-0000-4000-8000-000000000711',
    '0d000000-0000-4000-8000-000000000701',
    '0d000000-0000-4000-8000-000000000601',
    '0d000000-0000-4000-8000-000000000801'
  )),
  true,
  'same learner, attempt, mapping and idempotency key returns the original link'
);

SELECT throws_ok(
  $$
    SELECT * FROM public.link_milestone_assessment_attempt(
      '0d000000-0000-4000-8000-000000000712',
      '0d000000-0000-4000-8000-000000000701',
      '0d000000-0000-4000-8000-000000000601',
      '0d000000-0000-4000-8000-000000000801'
    )
  $$,
  'P0001',
  'milestone_assessment_attempt_link_idempotency_conflict',
  'idempotency key cannot be reused for a different attempt'
);

SELECT throws_ok(
  $$SELECT * FROM private.milestone_assessment_attempt_links$$,
  '42501',
  NULL,
  'student cannot read private milestone assessment attempt links directly'
);

SELECT throws_ok(
  $$
    INSERT INTO public.milestone_assessment_task_mappings (
      task_version_id,route_version_id,milestone_cycle_version_id,
      milestone_segment_id,assessment_code,mapping_rationale
    )
    VALUES (
      '0d000000-0000-4000-8000-000000000502',
      '0d000000-0000-4000-8000-000000000001',
      '0d000000-0000-4000-8000-000000000301',
      '0d000000-0000-4000-8000-000000000311',
      'SA1','Client mapping write must be denied.'
    )
  $$,
  '42501',
  NULL,
  'student cannot create SA task-to-unit mappings directly'
);

RESET ROLE;

SELECT is(
  (SELECT count(*)::integer FROM private.milestone_assessment_attempt_links),
  1,
  'one immutable private SA attempt-to-milestone link is stored'
);
SELECT is(
  (SELECT count(*)::integer FROM private.security_audit_events
   WHERE action='student_milestone_assessment_attempt_linked'),
  1,
  'successful SA attempt linkage writes one metadata-only audit event'
);

SELECT throws_ok(
  $$UPDATE private.milestone_assessment_attempt_links
    SET milestone_segment_id='0d000000-0000-4000-8000-000000000312'
    WHERE attempt_id='0d000000-0000-4000-8000-000000000711'$$,
  '42501',
  'milestone_assessment_attempt_link_immutable',
  'stored SA attempt lineage is immutable'
);

SELECT * FROM finish();
ROLLBACK;
