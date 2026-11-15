BEGIN;
SELECT no_plan();
-- Founder qualified academic approval is recorded outside this database.
-- This test MUST NOT manufacture a review receipt, numerical rubric or score.
SELECT is((SELECT count(*)::integer FROM private.pa_release_evidence_receipts),0,
  'no exact-version private acceptance records are fabricated');
SELECT is((SELECT count(*)::integer FROM private.pa_rubric_approvals),0,
  'no missing numerical maxima or calibration records are fabricated');

SET LOCAL ROLE authenticated;
SELECT set_config('request.jwt.claim.sub','11111111-1111-4111-8111-111111111111',true);
SELECT set_config('request.jwt.claims',
 '{"sub":"11111111-1111-4111-8111-111111111111","role":"authenticated","aal":"aal1"}',true);
SELECT throws_ok($q$SELECT * FROM private.pa_release_evidence_receipts$q$,
 '42501',NULL,'student cannot read restricted academic evidence receipts');
SELECT throws_ok($q$SELECT public.record_pa_release_evidence(
 'ed222222-2222-4222-8222-222222222222',
 '00000000-0000-0000-0000-000000000000',
 'Restricted exact Year 4 school route',repeat('a',64),repeat('b',64),
 repeat('c',64),repeat('d',64),
 'Missing documents cannot be accepted from a learner.')$q$,
 '42501','pa_release_evidence_forbidden',
 'learner cannot register academic release evidence');

SELECT set_config('request.jwt.claim.sub','55555555-5555-4555-8555-555555555555',true);
SELECT set_config('request.jwt.claims',
 '{"sub":"55555555-5555-4555-8555-555555555555","role":"authenticated","aal":"aal2"}',true);
SELECT throws_ok($q$SELECT public.record_pa_release_evidence(
 'ed222222-2222-4222-8222-222222222222',
 '00000000-0000-0000-0000-000000000000',
 'Restricted exact Year 4 school route',repeat('a',64),repeat('b',64),
 repeat('c',64),repeat('d',64),
 'Missing documents cannot be accepted by an assigned grader.')$q$,
 '42501','pa_release_evidence_forbidden',
 'assigned grader is not academic evidence authority');

SELECT set_config('request.jwt.claim.sub','88888888-8888-4888-8888-888888888888',true);
SELECT set_config('request.jwt.claims',
 '{"sub":"88888888-8888-4888-8888-888888888888","role":"authenticated","aal":"aal1"}',true);
SELECT throws_ok($q$SELECT public.record_pa_release_evidence(
 'ed222222-2222-4222-8222-222222222222',
 '00000000-0000-0000-0000-000000000000',
 'Restricted exact Year 4 school route',repeat('a',64),repeat('b',64),
 repeat('c',64),repeat('d',64),
 'Missing documents cannot be accepted without AAL2.')$q$,
 '42501','pa_release_evidence_forbidden',
 'Owner AAL1 cannot register academic release evidence');

SELECT set_config('request.jwt.claims',
 '{"sub":"88888888-8888-4888-8888-888888888888","role":"authenticated","aal":"aal2"}',true);
SELECT throws_ok($q$SELECT public.record_pa_release_evidence(
 'ed222222-2222-4222-8222-222222222222',
 '00000000-0000-0000-0000-000000000000',
 'Restricted exact Year 4 school route','not_a_digest',repeat('b',64),
 repeat('c',64),repeat('d',64),
 'Hash-less provisional sources cannot be registered.')$q$,
 '22023','invalid_pa_release_evidence',
 'evidence record requires valid cryptographic references');
SELECT throws_ok($q$SELECT public.record_pa_release_evidence(
 'ed222222-2222-4222-8222-222222222222',
 '00000000-0000-0000-0000-000000000000',
 'Restricted exact Year 4 school route',repeat('a',64),repeat('b',64),
 repeat('c',64),repeat('d',64),
 'Real matching rubric reference is absent for this draft.')$q$,
 '55000','pa_release_requires_exact_rubric',
 'Owner cannot file a receipt without an exact-version stored rubric');
RESET ROLE;

-- The prior published synthetic 15-observation fixture stays valid.
SELECT ok(EXISTS(SELECT 1 FROM public.diagnostic_versions
 WHERE diagnostic_code='ib-myp-g9-cycle1' AND release_state='published'
   AND version=1), 'previous published v1 remains unchanged');
SELECT throws_ok($q$UPDATE public.diagnostic_versions SET release_state='published'
 WHERE id='ed222222-2222-4222-8222-222222222222'$q$,
 '55000','pa_publication_requires_reviewed_direct_mapping',
 'direct mapping gate remains first for an unreviewed full v2');
-- Separate synthetic-only trigger-order assertion. Temporarily bypass the
-- older mapping gate within this rolled-back pgTAP transaction to prove that
-- the NEW independent private-evidence publication safeguard is also effective.
ALTER TABLE public.diagnostic_versions DISABLE TRIGGER pa_version_publication_gate;
SELECT throws_ok($q$UPDATE public.diagnostic_versions SET release_state='published'
 WHERE id='ed222222-2222-4222-8222-222222222222'$q$,
 '55000','pa_publication_requires_exact_academic_evidence',
 'new academic receipt gate independently denies release if mapping gate were bypassed');
ALTER TABLE public.diagnostic_versions ENABLE TRIGGER pa_version_publication_gate;
SELECT is((SELECT release_state FROM public.diagnostic_versions
 WHERE id='ed222222-2222-4222-8222-222222222222'),
 'draft','full instrument remains hidden and uncapturable');
SELECT is((SELECT count(*)::integer FROM private.pa_release_evidence_receipts),0,
 'failed attempts created no private release evidence');
SELECT * FROM finish();
ROLLBACK;
