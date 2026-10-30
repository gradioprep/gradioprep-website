# Literary Excerpt and Content Rights Protocol

**Version:** 2.0  
**Last updated:** 30 October 2026  
**Status:** Binding production rule for all English programme tracks and all reading passages/excerpts.  
**Supersedes:** Version 1.0 of this protocol and every earlier instruction allowing platform-original short reading passages.  
**Related standards:** `docs/TEACHER_PACK_AND_FEEDBACK_STANDARD.md`, `docs/LITERARY_EXCERPT_SOURCE_REGISTER.md`, `docs/ENGLISH_PUBLIC_SOURCE_REGISTER.md`, `docs/ENGLISH_STAGE_1_ROADMAP.md`, and `docs/curriculum/UNIT_PRODUCTION_REGISTER.md`.

## 1. Binding default

**Every reading passage or literary extract used as a learner stimulus must be an excerpt from a recognised public-domain work by a well-known writer, whether the excerpt is short or long.** This includes main reading passages, short warm-ups, mini-extracts, transfer passages, unseen extracts and passages used for objective or typed questions.

Do not create a platform-original short story or passage as a substitute for a literary source. The earlier allowance for short platform-original reading passages is withdrawn. This change applies to existing drafts when they are next revised, not only to new content.

The project may continue to write original supporting teaching and assessment material: instructions, question prompts, scaffolds, explanations, hints, answer rationales, model responses, feedback, rubrics, captions and navigation copy. Such material must not reproduce protected modern wording or pass itself off as a quotation from the author.

## 2. Quick public-domain source check

Use a proportionate, repeatable check. The goal is to establish a clear, suitable source without creating a lengthy legal-research project for every excerpt.

Before adopting the exact excerpt:

1. Select a recognised writer and a specific work that is stylistically, syntactically, semantically and thematically useful for the intended learner, skill and question type.
2. Confirm the exact work and its publication/creator details from a reliable source. Check that the work is in the public domain for the intended use territory, including India and any other territory in which the platform is intended to operate. Do not assume that age, fame, online availability or a search-result label proves public-domain status.
3. Use the original-language text where practical. A modern translation, edited edition, annotation, illustration, introduction, transcription or adaptation can have separate rights even when the underlying work is public domain. Check the specific version being used.
4. Prefer a reliable public-domain text repository or digitised primary edition that identifies the work and edition. Record the exact page/URL and the relevant chapter, section, stanza, poem or page locator.
5. Make a brief fit check: vocabulary and syntax load, length, meaning in context, age suitability, cultural/context sensitivity, and whether the passage genuinely supports the intended skill and question. If it is awkward or a specific rights concern appears, choose another work rather than prolonging research.
6. Record the check date, reviewer, source identifier and rationale in the internal Literary Excerpt Source Register **before** the excerpt is placed into learner or teacher content.

Do not use an unverified modern translation or silently modernise wording. Do not present a paraphrase as an exact quotation. Preserve the source's wording, punctuation and relevant context; use ellipses or bracketed changes transparently and sparingly.

## 3. Stable source and replacement controls

Every excerpt location in the product has a stable **Excerpt ID**. Every exact public-domain work/text version assigned to that location has a separate **Source ID**. Keep the Excerpt ID when replacing an excerpt; create a new Source ID when the source work, edition or excerpt changes.

The register must make it possible to replace a passage without changing the website's layout, routes, question flow, answer submission contract, teacher/learner separation or other functionality. Keep reading text in versioned content data and use stable question IDs and excerpt IDs. Update task wording, expected answers, model responses, feedback and provenance references when the passage changes; do not assume an old answer key still applies.

If a source is challenged or later found unsuitable, mark it blocked/replacement-required, choose a new public-domain work, and update only the content/source mapping and any passage-dependent assessment data. Preserve the previous version and source record for audit history.

## 4. Visual and documentary assets remain separately controlled

This text-excerpt rule does not relax the existing visual-asset rules. The project-specific photograph requirement remains binding: do not select, download, embed, commit or preview a photograph unless the exact file page explicitly confirms CC0 dedication or public-domain status, and screen visible third-party rights concerns before selection. For non-photographic visual assets, verify the exact source and licence permits all intended commercial/online uses and edits. Check image rights separately even when the accompanying literary work is public domain.

## 5. Rights outcomes and scope

Use precise, separate statuses:

- **Public-domain basis — verified:** the exact work and edition/version have been checked for the intended territory and the evidence is recorded.
- **Source/edition mismatch — blocked:** the underlying work may be public domain, but the supplied translation, edition, transcription or asset is not verified.
- **Replacement required:** the existing stimulus is platform-original, not sufficiently sourced, unsuitable, or otherwise outside the new standard.
- **Permission/licence basis — recorded:** a specific permission/licence is used for a non-text visual asset and its scope is documented.
- **Escalated:** a material rights, ownership, territory or adaptation concern cannot be resolved by selecting a clearer source.

This internal process is a practical content-control check, not legal advice or a guarantee of a particular legal outcome. Do not conduct extensive legal research as a routine substitute for selecting a clearly public-domain text. Escalate only a concrete unresolved issue.

## 6. Mandatory source-register fields

For every excerpt, record:

- Stable Excerpt ID and separate Source ID.
- Programme, course, level, unit, content version and linked question/task IDs.
- Work title, author, relevant author/work dates and original language.
- Exact edition/transcription, editor or translator (if any), repository/publisher and source URL.
- Public-domain basis, relevant territory/territories checked, evidence note and check date.
- Exact chapter/section/stanza/poem/page locator plus opening and closing words or an exact-text fingerprint/anchor.
- The exact excerpt as stored in the versioned unit-content file, or a precise pointer to that file and location.
- Any omission, ellipsis, bracketed change or formatting change.
- Short suitability note: style, syntax, meaning, vocabulary, age/cultural fit and intended skill.
- Reviewer, approval state, replacement history and any later concern.

The private register is maintained at `docs/LITERARY_EXCERPT_SOURCE_REGISTER.md`. No excerpt may be added to a learner or teacher pack without a completed register row.

## 7. Existing content migration baseline — 30 October 2026

The following existing passage material was authored as platform-original under the superseded version 1.0 policy. It is retained in Git history as a legacy version and must be replaced before any revised version is treated as conforming to the new standard:

| Existing item | Current source location | Migration decision |
|---|---|---|
| IB MYP Year 1 Unit 1 v2 main prose passage | `src/content/pilotLearnerLesson.ts` / `src/content/pilotLessonPack.ts` | Replace with a public-domain literary excerpt; review the related teacher pack and any transfer extract. |
| IB MYP Year 1 Unit 1 v2 transfer extract | `src/content/pilotLessonPack.ts` | Replace with a separately registered public-domain excerpt or remove if the task no longer needs it. |
| Cambridge Lower Secondary Stage 7 Unit 1 v1.3 main passage, “The Rain Gauge” | `docs/curriculum/CAMBRIDGE_LS_S7_UNIT_1_LEARNER_CONTENT.md` and separate teacher pack | Replace with a public-domain literary excerpt; rework passage-dependent questions and answers. |
| Cambridge Stage 7 Unit 1 v1.3 short warm-up mini-text | `docs/curriculum/CAMBRIDGE_LS_S7_UNIT_1_LEARNER_CONTENT.md` | Replace with a registered public-domain excerpt or a non-passage instructional example that does not purport to be a literary/reading stimulus. |
| CBSE English Grade 6 Unit 1 v1.0, “The Turning Sign” | `docs/curriculum/CBSE_G6_UNIT_1_LEARNER_CONTENT.md` and learner-safe source data | Replace the original story with a public-domain literary excerpt appropriate to the unit's learning purpose; revisit all passage-dependent tasks. |

The prior founder approvals and internal originality-screen outcomes remain historical facts for the exact versions reviewed under the previous policy. They do **not** waive the new source requirement, transfer to revised versions, or constitute release approval.

## 8. Quality, review and release remain separate

A verified public-domain source does not automatically make a passage academically suitable, correctly mapped, age-appropriate, accessible or released. After replacement, create a new content version and re-run the relevant academic, source-fit, question/answer consistency, accessibility, cultural/context and release checks. Preserve official curriculum mapping as unverified wherever the exact current official source is not available.