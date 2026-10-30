# Teacher-Pack, Question Design and Feedback Standard

**Version:** 1.0  
**Approved:** 30 October 2026  
**Status:** Binding standard for all English learning tracks and all current/future learner-facing objective and typed-response tasks.  
**Related source of truth:** `docs/PROJECT_MASTER_BRIEF.md`, `docs/CONTENT_ORIGINALITY_AND_RIGHTS_PROTOCOL.md`, `docs/LITERARY_EXCERPT_SOURCE_REGISTER.md`, `docs/ENGLISH_STAGE_1_ROADMAP.md`, and `docs/curriculum/UNIT_PRODUCTION_REGISTER.md`.

## 1. Purpose and scope

Every question must teach the learner something through its answer, reasoning and feedback. A teacher/editor pack is not complete merely because it contains a correct-answer letter or a generic marking note.

This standard applies to IB MYP, IB DP, Cambridge Lower Secondary, Cambridge IGCSE and CBSE English. Each course still keeps its own verified curriculum objectives, assessment language, task types and rubrics. This shared standard does not create cross-curriculum equivalence or official syllabus mappings.

## 2. Objective and closed-response questions

For every objective/closed-response item—including MCQs, multiple-select, matching, choose-a-word fill-in-the-blanks, sentence ordering, paragraph ordering and other fixed-answer formats—the teacher/editor pack must contain:

1. The exact correct answer, accepted answer set or correct sequence.
2. An AI-drafted answer explanation/model response that states **why this answer is correct in this particular question and context**.
3. A clear reasoning chain grounded in the source text, stimulus or stated rule.
4. A rationale for **each alternative**: why each distractor is incorrect, unsupported, incomplete or less suitable than the accepted answer. Do not use “wrong” as the only explanation.
5. Acceptable variants, synonyms, spelling/format variants or alternative sequences where the task genuinely permits them.
6. The learner-facing feedback to be shown after an attempt, not only private teacher notes.

Specific controls:

- **MCQs:** explain the correct option and each distractor separately. State why the correct response fits better than every other alternative.
- **Choose-a-word blanks:** identify the expected word, any accepted alternative(s), the grammatical/semantic clue, and why the remaining word-bank options do not fit that blank.
- **Sentence/paragraph ordering:** give the full sequence and explain the chronological, causal, referential, logical or narrative link that determines each placement. Record any other defensible sequence if the text allows one.
- **Matching/multiple-select:** explain each correct pairing/selection and the reason each unused or incorrect pairing/option does not fit.
- **Ambiguous items:** revise the question or explicitly accept and explain every defensible answer. Never force a single key where the source supports more than one interpretation.

AI-generated answer explanations and reasoning are authoring inputs, not automatically trusted answers. An academically responsible human must verify them against the exact excerpt, task wording and intended learning outcome before approval.

## 3. Subjective and typed-response questions

Every typed-response question must specify a **question-specific response length**. State the expected length in the learner instructions as a word limit, word range or clearly described concise/extended format. There is no universal word count across tasks: choose the length that allows this question's intended thinking to be shown without rewarding padding.

For each question, the teacher/editor pack must include:

- The intended thinking skill and the exact part of the excerpt/stimulus the question targets.
- A recommended or acceptable word range and the rationale for that range.
- An AI-drafted, question-specific model response at the expected length.
- The key ideas, evidence, reasoning links or interpretation features that make the response successful.
- Acceptable alternative interpretations where the excerpt reasonably supports them.
- Specific feedback for strong, developing and weak responses, including common misconceptions.
- A clear next step for improving the response, tied to what the learner actually wrote and the question's target skill.

A typed-response task must not be left with a generic comment such as “link the detail to the text” or “explain further.” Feedback must identify the relevant word/phrase/detail and explain what the learner did or did not connect.

**Illustrative literary-analysis example:** If a passage says “the lights faded into the raindrops,” a model response might explain that the fading lights make the bus appear to move physically farther away from the observer. In the scene's emotional context, the same image may also suggest psychological distance between the observer and the people leaving. A strong response must connect both possible effects to the exact wording and the moment in the passage; it should not present one unsupported interpretation as the only correct meaning.

## 4. AI generation, human validation and feedback quality

AI may draft answer explanations, distractor rationales, model responses and question-specific feedback. The content author/editor must check every generated element against the exact public-domain excerpt and task, correct inaccuracies and record the approved version. Do not use generic AI feedback templates as a substitute for item-level design.

For live practice feedback, an AI service may evaluate a learner's response only against approved server-side answer guidance, model responses and question-specific criteria. Feedback should normally identify:
1. What the learner got right, with reference to their actual answer.
2. What is missing, inaccurate or insufficiently supported for this particular question.
3. One focused improvement or next step.

For literary interpretation, acknowledge a valid alternative when it is supported by the excerpt. Do not mark a response wrong merely because it differs from the model wording.

## 5. Teacher/editor pack minimum schema

For each question, preserve at least:

- Stable unit/question ID and content version.
- Excerpt ID and Source ID (where the item uses a passage).
- Task type, exact prompt, response mode and learner-facing instructions.
- Correct answer/accepted answer set or sequence for objective items.
- Correct-answer explanation and per-alternative/distractor rationales.
- Response-length guidance for typed tasks.
- Model response at the expected length.
- Question-specific criteria, evidence anchors and accepted interpretations.
- Strong/developing/weak answer features and item-specific feedback.
- Common misconceptions, accessibility alternatives and next-step guidance.
- Author/editor, human validator, review date and approval/release state.

## 6. Student-facing experience

- Show expected word count/range before the learner starts typing.
- For auto-checked objective practice, provide immediate feedback after the response is submitted or checked: identify the correct answer, explain the reasoning and clarify why the alternatives do not fit.
- For ordering tasks, reveal the correct order with a short explanation of the sequence logic.
- For typed answers, provide immediate, question-specific formative feedback after submission where the task is configured for AI-assisted marking.
- Do not expose answer keys, full model responses or hidden criteria before the learner's attempt. The reveal timing is part of the task design.
- Distinguish formative/AI-assisted practice feedback from official IB/Cambridge grades or human-graded assessment.

## 7. Security and implementation boundary

The static prototype currently does not provide genuine automatic marking or question-specific AI assessment. Existing “review my thinking” or self-check controls must not be described as AI grading.

When genuine marking is implemented:

1. The browser may receive the learner-safe prompt, passage excerpt, task instructions and response field configuration.
2. The answer key, correct-answer IDs, model responses, per-option rationale, marking criteria and private teacher notes stay on a protected server-side path (Cloudflare Worker or another approved service) and are never bundled into public client JavaScript or public files.
3. Submit only the learner's response and minimum required task/version identifiers to the protected endpoint.
4. The server evaluates using the approved item-specific guidance and returns only the appropriate feedback for that attempt; do not return the hidden pack or full key before its intended reveal state.
5. Add rate limits, basic abuse/probing controls, input validation and error handling before formal assessments. Persist attempts only after an approved database and retention/privacy design exists.

Do not add live AI/API cost, a database, authentication, a production grading endpoint or any other paid/infrastructure dependency without the required founder approval.