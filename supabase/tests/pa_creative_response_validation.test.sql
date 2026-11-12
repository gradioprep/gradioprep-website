BEGIN;
SELECT no_plan();

-- One creative text produces five evidence dimensions, with plan and revision trace.
SELECT ok(private.valid_diagnostic_response('CW01',jsonb_build_object(
 'plan','Viewpoint: Sam; rain changes the event; ending: shared reading.',
 'initial_draft','The hall was busy, and Sam noticed a corner.',
 'final_text',repeat('The corner became a reading place. ',12),
 'revision_before','the room was nice','revision_after','the hall sounded like a river',
 'revision_note','The new image creates a more specific atmosphere.')),
 'complete draft, plan and genuine revision trace accepted');
SELECT ok(private.valid_diagnostic_response('CW01',jsonb_build_object(
 'plan','Viewpoint: Sam; rain moves everyone inside.',
 'initial_draft','There was a small space for a chair.',
 'final_text',repeat('word ',200),
 'revision_before','small','revision_after','narrow',
 'revision_note','The description becomes more precise.')),
 '200-word final text accepted despite guidance of 125 words');
SELECT ok(NOT private.valid_diagnostic_response('CW01',jsonb_build_object(
 'plan','Viewpoint: Sam; rain moves the book swap.',
 'initial_draft','A character notices the windows.',
 'final_text','The corner becomes a quiet space.',
 'revision_before','bright','revision_after','bright',
 'revision_note','This edit changes nothing.')),
 'unchanged before/after revision rejected');
SELECT ok(NOT private.valid_diagnostic_response('CW01',jsonb_build_object(
 'plan','Viewpoint: Sam; rain moves the book swap.',
 'initial_draft','A character notices the windows.',
 'final_text','The corner becomes a quiet space.',
 'revision_before','small','revision_after','sunlit',
 'revision_note','A more specific image replaces a vague word.',
 'score',7)),
 'score injection rejected');
SELECT ok(NOT private.valid_diagnostic_response('CW01',jsonb_build_object(
 'plan','Viewpoint: Sam; rain moves the book swap.',
 'initial_draft','A character notices the windows.',
 'final_text','The corner becomes a quiet space.',
 'revision_before','small','revision_after','sunlit')),
 'missing revision rationale rejected');
SELECT ok(NOT private.valid_diagnostic_response('CW02','{"text":"another separate answer"}'::jsonb),
 'CW02 cannot be a separate answer');
SELECT is((SELECT count(*)::integer FROM public.diagnostic_observations
 WHERE diagnostic_version_id='ed222222-2222-4222-8222-222222222222'
 AND group_code='CW' AND learner_capture_enabled),0,
 'full creative group remains uncapturable before academic sign-off');
SELECT is((SELECT release_state FROM public.diagnostic_versions
 WHERE id='ed222222-2222-4222-8222-222222222222'),'draft',
 'full PA remains draft');
SELECT * FROM finish();
ROLLBACK;
