BEGIN;
SELECT no_plan();

-- Synthetic fixture only: this is not an IB, Cambridge or CBSE curriculum route.
INSERT INTO public.curriculum_route_versions (
  id, route_key, version, awarding_body, programme_code, subject_code,
  course_code, level_code, level_label, academic_session, syllabus_edition,
  official_source_title, official_source_url, source_checked_at,
  review_state, verified_by, verified_at
)
VALUES
(
  '0c000000-0000-4000-8000-000000000001',
  'synthetic-route-only', 1, 'TEST', 'SYNTHETIC', 'ENGLISH',
  'SYNTHETIC-COURSE', 'SYNTHETIC-LEVEL', 'Synthetic fixture only',
  'synthetic-fixture', 'not-an-official-edition',
  'Synthetic test fixture — not an official curriculum source',
  'https://example.invalid/not-an-official-curriculum-source',
  clock_timestamp(), 'pending_review',
  NULL, NULL
),
(
  '0c000000-0000-4000-8000-000000000002',
  'synthetic-pending-route', 1, 'TEST', 'SYNTHETIC', 'ENGLISH',
  'SYNTHETIC-COURSE', 'SYNTHETIC-LEVEL', 'Unreviewed synthetic fixture',
  'synthetic-fixture', 'not-an-official-edition',
  NULL, NULL, NULL, 'pending_review', NULL, NULL
);

INSERT INTO public.curriculum_unit_versions (
  id, route_version_id, unit_code, version, sequence_number, title,
  learning_objective_summary, release_state
)
VALUES
  ('0c000000-0000-4000-8000-000000000101','0c000000-0000-4000-8000-000000000001','SYN-U1',1,1,'Synthetic M1 unit','Synthetic-only learning objective. No curriculum claim.','draft'),
  ('0c000000-0000-4000-8000-000000000102','0c000000-0000-4000-8000-000000000001','SYN-U2',1,2,'Synthetic M2 unit','Synthetic-only learning objective. No curriculum claim.','draft'),
  ('0c000000-0000-4000-8000-000000000103','0c000000-0000-4000-8000-000000000001','SYN-U3',1,3,'Synthetic M3 unit','Synthetic-only learning objective. No curriculum claim.','draft'),
  ('0c000000-0000-4000-8000-000000000104','0c000000-0000-4000-8000-000000000002','SYN-DRAFT',1,1,'Unpublished synthetic unit','Not visible to learners.','draft');
INSERT INTO public.curriculum_unit_versions (
  id, route_version_id, unit_code, version, sequence_number, title,
  learning_objective_summary, release_state
)
VALUES (
  '0c000000-0000-4000-8000-000000000105',
  '0c000000-0000-4000-8000-000000000001',
  'SYN-NO-MAPPING',1,4,'Unit without direct mapping',
  'Must not be publishable without a reviewed direct outcome.','draft'
);

INSERT INTO public.curriculum_unit_outcome_mappings (
  id, curriculum_unit_version_id, outcome_reference, outcome_title,
  source_locator, mapping_status, mapping_rationale, reviewed_by, reviewed_at
)
VALUES
  ('0c000000-0000-4000-8000-000000000201','0c000000-0000-4000-8000-000000000101','SYN-OUTCOME-1','Synthetic outcome one','Synthetic fixture only — no official source','direct','Synthetic authorization fixture only.','88888888-8888-4888-8888-888888888888',clock_timestamp()),
  ('0c000000-0000-4000-8000-000000000202','0c000000-0000-4000-8000-000000000102','SYN-OUTCOME-2','Synthetic outcome two','Synthetic fixture only — no official source','direct','Synthetic authorization fixture only.','88888888-8888-4888-8888-888888888888',clock_timestamp()),
  ('0c000000-0000-4000-8000-000000000203','0c000000-0000-4000-8000-000000000103','SYN-OUTCOME-3','Synthetic outcome three','Synthetic fixture only — no official source','direct','Synthetic authorization fixture only.','88888888-8888-4888-8888-888888888888',clock_timestamp());

UPDATE public.curriculum_route_versions
SET review_state='verified',
    verified_by='88888888-8888-4888-8888-888888888888',
    verified_at=clock_timestamp()
WHERE id='0c000000-0000-4000-8000-000000000001';


SELECT throws_ok(
  $$
    INSERT INTO public.curriculum_unit_versions (
      route_version_id, unit_code, version, sequence_number, title,
      learning_objective_summary, release_state
    )
    VALUES (
      '0c000000-0000-4000-8000-000000000001',
      'SYN-LATE-UNIT',1,5,'Late unit','Requires a new route version.','draft'
    )
  $$,
  '55000',
  'curriculum_route_units_locked',
  'verified route content cannot be extended without a new route version'
);

UPDATE public.curriculum_unit_versions
SET release_state='published'
WHERE id IN (
  '0c000000-0000-4000-8000-000000000101',
  '0c000000-0000-4000-8000-000000000102',
  '0c000000-0000-4000-8000-000000000103'
);

INSERT INTO public.milestone_cycle_versions (
  id, route_version_id, version, release_state
)
VALUES ('0c000000-0000-4000-8000-000000000301','0c000000-0000-4000-8000-000000000001',1,'draft');

INSERT INTO public.milestone_segments (
  id, milestone_cycle_version_id, route_version_id, segment_number, title
)
VALUES
  ('0c000000-0000-4000-8000-000000000311','0c000000-0000-4000-8000-000000000301','0c000000-0000-4000-8000-000000000001',1,'Synthetic Milestone 1'),
  ('0c000000-0000-4000-8000-000000000312','0c000000-0000-4000-8000-000000000301','0c000000-0000-4000-8000-000000000001',2,'Synthetic Milestone 2'),
  ('0c000000-0000-4000-8000-000000000313','0c000000-0000-4000-8000-000000000301','0c000000-0000-4000-8000-000000000001',3,'Synthetic Milestone 3');

INSERT INTO public.milestone_unit_memberships (
  id, milestone_cycle_version_id, milestone_segment_id,
  curriculum_unit_version_id, route_version_id, sequence_number, is_required
)
VALUES
  ('0c000000-0000-4000-8000-000000000321','0c000000-0000-4000-8000-000000000301','0c000000-0000-4000-8000-000000000311','0c000000-0000-4000-8000-000000000101','0c000000-0000-4000-8000-000000000001',1,true),
  ('0c000000-0000-4000-8000-000000000322','0c000000-0000-4000-8000-000000000301','0c000000-0000-4000-8000-000000000312','0c000000-0000-4000-8000-000000000102','0c000000-0000-4000-8000-000000000001',1,true),
  ('0c000000-0000-4000-8000-000000000323','0c000000-0000-4000-8000-000000000301','0c000000-0000-4000-8000-000000000313','0c000000-0000-4000-8000-000000000103','0c000000-0000-4000-8000-000000000001',1,true);

SELECT throws_ok(
  $$
    INSERT INTO public.milestone_unit_memberships (
      id, milestone_cycle_version_id, milestone_segment_id,
      curriculum_unit_version_id, route_version_id, sequence_number
    )
    VALUES (
      '0c000000-0000-4000-8000-000000000399',
      '0c000000-0000-4000-8000-000000000301',
      '0c000000-0000-4000-8000-000000000312',
      '0c000000-0000-4000-8000-000000000101',
      '0c000000-0000-4000-8000-000000000001', 2
    )
  $$,
  '23505',
  NULL,
  'one unit version cannot appear in two milestone segments in the same cycle'
);

UPDATE public.milestone_cycle_versions
SET release_state='published'
WHERE id='0c000000-0000-4000-8000-000000000301';

SELECT throws_ok(
  $$
    INSERT INTO public.milestone_unit_memberships (
      id, milestone_cycle_version_id, milestone_segment_id,
      curriculum_unit_version_id, route_version_id, sequence_number
    )
    VALUES (
      '0c000000-0000-4000-8000-000000000398',
      '0c000000-0000-4000-8000-000000000301',
      '0c000000-0000-4000-8000-000000000312',
      '0c000000-0000-4000-8000-000000000101',
      '0c000000-0000-4000-8000-000000000001', 2
    )
  $$,
  '55000',
  'published_curriculum_snapshot_immutable',
  'a published milestone cycle cannot gain new unit memberships'
);

INSERT INTO public.course_enrolments (id, learner_id, pathway_id, status)
VALUES
  ('0c000000-0000-4000-8000-000000000401','11111111-1111-4111-8111-111111111111','synthetic-route-only','active'),
  ('0c000000-0000-4000-8000-000000000402','11111111-1111-4111-8111-111111111111','synthetic-other-route','active');

SELECT is(
  (SELECT count(*)::integer FROM public.milestone_segments WHERE milestone_cycle_version_id='0c000000-0000-4000-8000-000000000301'),
  3,
  'the synthetic cycle has exactly three milestone segments'
);



SELECT throws_ok(
  $$UPDATE public.curriculum_unit_versions SET release_state='published' WHERE id='0c000000-0000-4000-8000-000000000105'$$,
  '55000',
  'curriculum_unit_requires_direct_outcome',
  'a unit cannot be published without at least one reviewed DIRECT outcome mapping'
);

SELECT throws_ok(
  $$UPDATE public.curriculum_unit_versions SET release_state='published' WHERE id='0c000000-0000-4000-8000-000000000104'$$,
  '55000',
  'curriculum_unit_requires_verified_route',
  'a unit cannot be published against an unverified curriculum route'
);

SELECT throws_ok(
  $$UPDATE public.curriculum_unit_versions SET title='tampered published version' WHERE id='0c000000-0000-4000-8000-000000000101'$$,
  '55000',
  'published_curriculum_snapshot_immutable',
  'published unit versions are immutable; publish a new version instead'
);

SELECT throws_ok(
  $$UPDATE public.milestone_cycle_versions SET version=2 WHERE id='0c000000-0000-4000-8000-000000000301'$$,
  '55000',
  'published_curriculum_snapshot_immutable',
  'published M1-M3 cycle versions are immutable'
);

-- Anonymous users cannot inspect curriculum versioning or learner progress.
SET LOCAL ROLE anon;
SELECT throws_ok($$SELECT * FROM public.curriculum_route_versions$$,'42501',NULL,'anonymous cannot read curriculum route versions');
SELECT throws_ok($$SELECT * FROM public.milestone_unit_memberships$$,'42501',NULL,'anonymous cannot read milestone membership');
SELECT throws_ok($$SELECT * FROM public.learner_unit_progress$$,'42501',NULL,'anonymous cannot read learner unit progress');
RESET ROLE;

-- Student A sees only verified/published curriculum snapshots and may update their own progress through the protected RPC.
SET LOCAL ROLE authenticated;
SELECT set_config('request.jwt.claim.sub','11111111-1111-4111-8111-111111111111',true);
SELECT set_config('request.jwt.claims','{"sub":"11111111-1111-4111-8111-111111111111","role":"authenticated","aal":"aal1"}',true);

SELECT is((SELECT count(*)::integer FROM public.curriculum_route_versions),1,'student sees only verified route versions');
SELECT is((SELECT count(*)::integer FROM public.curriculum_unit_versions),3,'student sees only published units from a verified route');
SELECT is((SELECT count(*)::integer FROM public.curriculum_unit_outcome_mappings),3,'student sees only reviewed route-specific outcome mappings');
SELECT is((SELECT count(*)::integer FROM public.milestone_cycle_versions),1,'student sees only published M1-M3 cycle versions');
SELECT is((SELECT count(*)::integer FROM public.milestone_segments),3,'student sees the three published milestone segments');
SELECT is((SELECT count(*)::integer FROM public.milestone_unit_memberships),3,'student sees only published exact unit memberships');

SELECT throws_ok(
  $$
    INSERT INTO public.curriculum_unit_versions (
      route_version_id, unit_code, version, sequence_number, title,
      learning_objective_summary, release_state
    )
    VALUES (
      '0c000000-0000-4000-8000-000000000001',
      'CLIENT-INJECTION',1,99,'Not allowed','Client cannot write route content.','published'
    )
  $$,
  '42501', NULL,
  'students cannot write curriculum catalogue records directly'
);

SELECT lives_ok(
  $$SELECT * FROM public.record_learner_unit_progress(
    '0c000000-0000-4000-8000-000000000401',
    '0c000000-0000-4000-8000-000000000321',
    'in_progress'
  )$$,
  'student starts a unit only inside their matching active enrolment and published M1-M3 set'
);
SELECT is(
  (SELECT status FROM public.learner_unit_progress WHERE enrolment_id='0c000000-0000-4000-8000-000000000401'),
  'in_progress',
  'unit start is persisted against the exact milestone membership'
);

SELECT lives_ok(
  $$SELECT * FROM public.record_learner_unit_progress(
    '0c000000-0000-4000-8000-000000000401',
    '0c000000-0000-4000-8000-000000000321',
    'completed'
  )$$,
  'student completes the same unit through the protected RPC'
);
SELECT is(
  (SELECT status FROM public.learner_unit_progress WHERE enrolment_id='0c000000-0000-4000-8000-000000000401'),
  'completed',
  'unit completion is recorded'
);
SELECT ok(
  (SELECT completed_at IS NOT NULL FROM public.learner_unit_progress WHERE enrolment_id='0c000000-0000-4000-8000-000000000401'),
  'completion time is server-stamped'
);

SELECT lives_ok(
  $$SELECT * FROM public.record_learner_unit_progress(
    '0c000000-0000-4000-8000-000000000401',
    '0c000000-0000-4000-8000-000000000321',
    'in_progress'
  )$$,
  'replayed start request is safely idempotent after completion'
);
SELECT is(
  (SELECT status FROM public.learner_unit_progress WHERE enrolment_id='0c000000-0000-4000-8000-000000000401'),
  'completed',
  'completed unit progress cannot regress to in progress'
);

SELECT throws_ok(
  $$SELECT * FROM public.record_learner_unit_progress(
    '0c000000-0000-4000-8000-000000000402',
    '0c000000-0000-4000-8000-000000000321',
    'in_progress'
  )$$,
  '42501',
  'unit_progress_forbidden',
  'an enrolment with a different route key cannot reuse this milestone membership'
);

SELECT throws_ok(
  $$SELECT * FROM public.record_learner_unit_progress(
    '0c000000-0000-4000-8000-000000000401',
    '0c000000-0000-4000-8000-000000000321',
    'skipped'
  )$$,
  '22023',
  'invalid_unit_progress_status',
  'unsupported learner progress status is rejected'
);

SELECT throws_ok(
  $$UPDATE public.learner_unit_progress SET status='in_progress' WHERE enrolment_id='0c000000-0000-4000-8000-000000000401'$$,
  '42501',
  NULL,
  'students cannot bypass the progress transition RPC'
);

RESET ROLE;

-- Another learner cannot inspect or update Student A's unit progress.
SET LOCAL ROLE authenticated;
SELECT set_config('request.jwt.claim.sub','22222222-2222-4222-8222-222222222222',true);
SELECT set_config('request.jwt.claims','{"sub":"22222222-2222-4222-8222-222222222222","role":"authenticated","aal":"aal1"}',true);
SELECT is((SELECT count(*)::integer FROM public.learner_unit_progress),0,'another learner cannot read another learner unit progress');
SELECT throws_ok(
  $$SELECT * FROM public.record_learner_unit_progress(
    '0c000000-0000-4000-8000-000000000401',
    '0c000000-0000-4000-8000-000000000322',
    'completed'
  )$$,
  '42501','unit_progress_forbidden',
  'another learner cannot record progress for a foreign enrolment'
);
RESET ROLE;

-- Guardian A sees progress only because the synthetic seed grants progress consent.
SET LOCAL ROLE authenticated;
SELECT set_config('request.jwt.claim.sub','33333333-3333-4333-8333-333333333333',true);
SELECT set_config('request.jwt.claims','{"sub":"33333333-3333-4333-8333-333333333333","role":"authenticated","aal":"aal1"}',true);
SELECT is((SELECT count(*)::integer FROM public.learner_unit_progress),1,'guardian with verified progress consent can read linked learner progress');
RESET ROLE;

SELECT * FROM finish();
ROLLBACK;
