BEGIN;
SELECT no_plan();

SET LOCAL ROLE anon;
SELECT throws_ok($$SELECT * FROM public.diagnostic_versions$$,'42501',NULL,'anonymous cannot read Diagnostic versions');
SELECT throws_ok($$SELECT * FROM public.diagnostic_attempts$$,'42501',NULL,'anonymous cannot read Diagnostic attempts');
SELECT throws_ok($$SELECT * FROM public.diagnostic_response_versions$$,'42501',NULL,'anonymous cannot read Diagnostic evidence');
RESET ROLE;

CREATE TEMP TABLE diagnostic_test_state(attempt_id uuid) ON COMMIT DROP;
GRANT SELECT,INSERT ON diagnostic_test_state TO authenticated;

SET LOCAL ROLE authenticated;
SELECT set_config('request.jwt.claim.sub','11111111-1111-4111-8111-111111111111',true);
SELECT set_config('request.jwt.claims','{"sub":"11111111-1111-4111-8111-111111111111","role":"authenticated","aal":"aal1"}',true);

SELECT is((SELECT count(*)::integer FROM public.diagnostic_versions),1,'enrolled synthetic MYP student sees the published version');
SELECT is((SELECT count(*)::integer FROM public.diagnostic_observations WHERE group_code='RV'),10,'Read & View version exposes ten evidence observations');
SELECT is((SELECT count(*)::integer FROM public.diagnostic_observations WHERE group_code='LC'),5,'Language in Context exposes five evidence observations');

INSERT INTO diagnostic_test_state
SELECT attempt_id FROM public.create_diagnostic_attempt(
 'ed111111-1111-4111-8111-111111111111','ed011111-1111-4111-8111-111111111111'
);
SELECT is((SELECT status FROM public.diagnostic_attempts WHERE id=(SELECT attempt_id FROM diagnostic_test_state)),
 'in_progress','start creates an in-progress Diagnostic attempt');
SELECT is((SELECT is_replay FROM public.create_diagnostic_attempt(
 'ed111111-1111-4111-8111-111111111111','ed021111-1111-4111-8111-111111111111'
)),true,'repeat start resumes the same attempt');

SELECT lives_ok($$SELECT * FROM public.save_diagnostic_response((SELECT attempt_id FROM diagnostic_test_state),'RV01','{"a":"B","b":["A","C"]}'::jsonb)$$,'saves valid compound selection');
SELECT lives_ok($$SELECT * FROM public.save_diagnostic_response((SELECT attempt_id FROM diagnostic_test_state),'RV02','{"text":"Nia records what was completed and what must wait, showing a balanced view of the afternoon."}'::jsonb)$$,'saves RV02 text evidence');
SELECT lives_ok($$SELECT * FROM public.save_diagnostic_response((SELECT attempt_id FROM diagnostic_test_state),'RV03','{"text":"The bright note creates a lively moment and helps show why the small success matters."}'::jsonb)$$,'saves RV03 text evidence');
SELECT lives_ok($$SELECT * FROM public.save_diagnostic_response((SELECT attempt_id FROM diagnostic_test_state),'RV04','{"choice":"A"}'::jsonb)$$,'saves RV04 choice');
SELECT lives_ok($$SELECT * FROM public.save_diagnostic_response((SELECT attempt_id FROM diagnostic_test_state),'RV05','{"choice":"A"}'::jsonb)$$,'saves RV05 choice');
SELECT lives_ok($$SELECT * FROM public.save_diagnostic_response((SELECT attempt_id FROM diagnostic_test_state),'RV06','{"text":"The claim exaggerates the result because 17 of the 48 objects were not repaired on the day."}'::jsonb)$$,'saves RV06 evidence evaluation');
SELECT lives_ok($$SELECT * FROM public.save_diagnostic_response((SELECT attempt_id FROM diagnostic_test_state),'RV07a','{"text":"Nia sees success as honest progress, while the poster counts outcomes and makes unfinished work visible."}'::jsonb)$$,'saves RV07a comparison');
SELECT lives_ok($$SELECT * FROM public.save_diagnostic_response((SELECT attempt_id FROM diagnostic_test_state),'RV07b','{"text":"The story uses a sequence of events, while the poster groups results into clear visual categories."}'::jsonb)$$,'saves RV07b form comparison');
SELECT lives_ok($$SELECT * FROM public.save_diagnostic_response((SELECT attempt_id FROM diagnostic_test_state),'RV08','{"order":["2","3","4","5","1"],"explanation":"The sequence moves from uncertainty to small success and then an honest record of what remains."}'::jsonb)$$,'saves RV08 sequence evidence');

SELECT is((SELECT count(DISTINCT observation_id)::integer FROM public.diagnostic_response_versions WHERE attempt_id=(SELECT attempt_id FROM diagnostic_test_state)),
 9,'nine of ten observations are saved before completion');

SELECT lives_ok($$SELECT * FROM public.save_diagnostic_response((SELECT attempt_id FROM diagnostic_test_state),'LC01','{"choice":"A"}'::jsonb)$$,'saves LC01 contextual vocabulary choice');
SELECT lives_ok($$SELECT * FROM public.save_diagnostic_response((SELECT attempt_id FROM diagnostic_test_state),'LC02','{"choice":"A"}'::jsonb)$$,'saves LC02 sentence-focus choice');
SELECT lives_ok($$SELECT * FROM public.save_diagnostic_response((SELECT attempt_id FROM diagnostic_test_state),'LC03','{"choice":"B"}'::jsonb)$$,'saves LC03 grammar and usage choice');
SELECT lives_ok($$SELECT * FROM public.save_diagnostic_response((SELECT attempt_id FROM diagnostic_test_state),'LC04','{"choice":"A"}'::jsonb)$$,'saves LC04 punctuation choice');
SELECT lives_ok($$SELECT * FROM public.save_diagnostic_response((SELECT attempt_id FROM diagnostic_test_state),'LC05','{"text":"Please place bags on the shelves beside the entrance so that the stairs and walkway remain clear for everyone."}'::jsonb)$$,'saves LC05 audience and register response');
SELECT is((SELECT count(DISTINCT observation_id)::integer FROM public.diagnostic_response_versions WHERE attempt_id=(SELECT attempt_id FROM diagnostic_test_state)),
 14,'fourteen of fifteen observations are saved before completion');
SELECT throws_ok($$SELECT * FROM public.submit_diagnostic_attempt((SELECT attempt_id FROM diagnostic_test_state))$$,
 'P0001','diagnostic_responses_incomplete','submission is blocked while an observation is unanswered');

SELECT throws_ok($$SELECT * FROM public.save_diagnostic_response((SELECT attempt_id FROM diagnostic_test_state),'RV01','{"a":"B","b":["A","A"]}'::jsonb)$$,
 '22023','invalid_diagnostic_response','duplicate multiple-choice selections are rejected');
SELECT throws_ok($$SELECT * FROM public.save_diagnostic_response((SELECT attempt_id FROM diagnostic_test_state),'LC01','{"choice":"A","extra":"forged"}'::jsonb)$$,
 '22023','invalid_diagnostic_response','LC choice rejects unrecognised response fields');
SELECT throws_ok($$SELECT * FROM public.save_diagnostic_response((SELECT attempt_id FROM diagnostic_test_state),'LC05','{"text":null}'::jsonb)$$,
 '22023','invalid_diagnostic_response','LC05 rejects a null text value');
SELECT throws_ok($$SELECT * FROM public.save_diagnostic_response((SELECT attempt_id FROM diagnostic_test_state),'AW01','{"text":"An observation outside the enabled Read & View section."}'::jsonb)$$,
 '22023','invalid_diagnostic_response','other task groups cannot be written through the first-slice API');


SELECT throws_ok($$SELECT * FROM public.save_diagnostic_response((SELECT attempt_id FROM diagnostic_test_state),'RV01','{"a":null,"b":["A","C"]}'::jsonb)$$,
 '22023','invalid_diagnostic_response','null main-choice value is rejected');
SELECT throws_ok($$SELECT * FROM public.save_diagnostic_response((SELECT attempt_id FROM diagnostic_test_state),'RV04','{"choice":null}'::jsonb)$$,
 '22023','invalid_diagnostic_response','null single-choice value is rejected');
SELECT throws_ok($$SELECT * FROM public.save_diagnostic_response((SELECT attempt_id FROM diagnostic_test_state),'RV08','{"order":["1","2","3","4","5"],"explanation":null}'::jsonb)$$,
 '22023','invalid_diagnostic_response','null sequence explanation is rejected');
SELECT throws_ok($$SELECT * FROM public.save_diagnostic_response((SELECT attempt_id FROM diagnostic_test_state),'RV09','{"choice":"B","explanation":null}'::jsonb)$$,
 '22023','invalid_diagnostic_response','null evidence explanation is rejected');

SELECT lives_ok($$SELECT * FROM public.save_diagnostic_response((SELECT attempt_id FROM diagnostic_test_state),'RV09','{"choice":"B","explanation":"The figures list completed and unfinished outcomes, unlike the tagline or invitation."}'::jsonb)$$,
 'saves final RV09 evidence');
SELECT is((SELECT count(DISTINCT observation_id)::integer FROM public.diagnostic_response_versions WHERE attempt_id=(SELECT attempt_id FROM diagnostic_test_state)),
 15,'all fifteen enabled Read & View and Language in Context observations have evidence');
SELECT is((SELECT revision_number FROM public.save_diagnostic_response((SELECT attempt_id FROM diagnostic_test_state),'RV02',
 '{"text":"Nia records the completed work and what must wait, showing a balanced view of the afternoon."}'::jsonb)),2,
 'changed response is appended as a new revision');
SELECT is((SELECT revision_number FROM public.save_diagnostic_response((SELECT attempt_id FROM diagnostic_test_state),'RV02',
 '{"text":"Nia records the completed work and what must wait, showing a balanced view of the afternoon."}'::jsonb)),2,
 'identical retry does not create another revision');
SELECT lives_ok($$SELECT * FROM public.submit_diagnostic_attempt((SELECT attempt_id FROM diagnostic_test_state))$$,
 'student submits complete unscored evidence');
SELECT is((SELECT status FROM public.diagnostic_attempts WHERE id=(SELECT attempt_id FROM diagnostic_test_state)),
 'submitted','submission is finalised');
SELECT throws_ok($$SELECT * FROM public.save_diagnostic_response((SELECT attempt_id FROM diagnostic_test_state),'RV02',
 '{"text":"Late changes must not overwrite submitted Diagnostic evidence."}'::jsonb)$$,
 'P0001','diagnostic_attempt_not_editable','submitted evidence is immutable');

RESET ROLE;
SET LOCAL ROLE authenticated;
SELECT set_config('request.jwt.claim.sub','22222222-2222-4222-8222-222222222222',true);
SELECT set_config('request.jwt.claims','{"sub":"22222222-2222-4222-8222-222222222222","role":"authenticated","aal":"aal1"}',true);
SELECT is((SELECT count(*)::integer FROM public.diagnostic_attempts),0,'unrelated Cambridge student cannot read MYP attempts');
SELECT is((SELECT count(*)::integer FROM public.diagnostic_response_versions),0,'unrelated student cannot read Diagnostic responses');
SELECT is((SELECT count(*)::integer FROM public.diagnostic_versions),0,'student outside the MYP pathway cannot discover the version');
RESET ROLE;

SET LOCAL ROLE authenticated;
SELECT set_config('request.jwt.claim.sub','11111111-1111-4111-8111-111111111111',true);
SELECT set_config('request.jwt.claims','{"sub":"11111111-1111-4111-8111-111111111111","role":"authenticated","aal":"aal1"}',true);
SELECT throws_ok($$INSERT INTO public.diagnostic_attempts(learner_id,diagnostic_version_id,idempotency_key)
 VALUES('11111111-1111-4111-8111-111111111111','ed111111-1111-4111-8111-111111111111','ed031111-1111-4111-8111-111111111111')$$,
 '42501',NULL,'browser student cannot bypass the transactional attempt function');
RESET ROLE;

SELECT is((SELECT count(*)::integer FROM private.security_audit_events
 WHERE action='diagnostic_response_saved' AND target_type='diagnostic_attempt'
 AND target_id=(SELECT attempt_id FROM diagnostic_test_state)),16,
 'successful response saves write metadata-only audit events');
SELECT ok(NOT EXISTS(
 SELECT 1 FROM private.security_audit_events
 WHERE action='diagnostic_response_saved' AND target_id=(SELECT attempt_id FROM diagnostic_test_state)
 AND reason_category IS NULL
),'Diagnostic response audit never contains missing reason classification');

SELECT * FROM finish();
ROLLBACK;
