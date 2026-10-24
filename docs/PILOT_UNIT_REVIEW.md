# Pilot Unit 1 — Academic Review Sheet

**Unit draft:** How writers shape meaning  
**Pathway slot:** `ib-myp-lal-y1-u1`  
**Content version:** 1  
**Review state:** Academic content review passed for preview version 1; official curriculum mapping and release remain blocked  
**Content sources:** `src/content/pilotUnitDraft.ts`, learner-safe `src/content/pilotLearnerLesson.ts`, and teacher/editor `src/content/pilotLessonPack.ts`

## Purpose

This sheet records the academic content-review pass and the remaining source/mapping, rights, accessibility and release checks. It is a manual record, not connected to a database; a future content or feature change may be made later, with a versioned change record and a new review of the affected scope.

## Included in the current draft

- Proposed learning objective and success criteria.
- Original short passage.
- Four-step teaching sequence, with learner actions and worked examples.
- One multiple-choice question with distractor feedback.
- Three written-response/revision tasks with model answers and success indicators.
- Exit ticket and an informal three-part feedback guide.
- Accessibility checks and specific academic-review questions.

The learner-facing preview now uses a separate student-safe data file, `src/content/pilotLearnerLesson.ts`, which contains no correct-answer IDs or model answers. The teacher/editor source with answer keys is `src/content/pilotLessonPack.ts` and is deliberately not imported by the client UI. This is a source-code separation for the static preview, not a production authorization system; in the production architecture, answer keys must be served through a protected server-side path and must never be included in an unrestricted learner bundle.

## Official-source notes

1. [IB MYP Language and literature subject page](https://www.ibo.org/programmes/middle-years-programme/curriculum/language-and-literature/) — checked 24 October 2026; the page describes the six skill areas and a range of literary/non-literary text types, but does not give a Year 1 unit sequence.
2. [IB MYP Language and literature subject brief](https://www.ibo.org/globalassets/new-structure/brochures-and-infographics/pdfs/myp-brief-language-literature-en.pdf) — public overview document labelled From 2014.
3. [IB-hosted Language and literature guide reference](https://resources.ibo.org/data/m_1_langa_guu_1405_8_e.pdf) — a search-indexed excerpt suggests Year 1 Criterion A strands A(ii) and A(iii). Opening the detailed guide redirects to IB curriculum sign-in. The exact guide edition used by the intended school has not been confirmed.

The academic content review has passed for version 1, based on the project owner's confirmation on 24 October 2026. This approval covers the instructional content and practice pack for pilot preview; it does not change the separate mapping evidence. The candidate strand references remain **unverified**. The `officialObjectiveCodes` list must stay empty and curriculum mapping must stay unverified until the applicable guide edition and objective references are checked. Public marketing must not describe this as an officially mapped IB unit in the meantime.

## Required review decisions

- [ ] Confirm which MYP Language and literature guide/edition applies to the intended learner — still open.
- [ ] Verify whether candidate strands A(ii), A(iii), both, or neither are applicable — still open.
- [x] Review the proposed objective, sequence and estimated 25-minute duration for pilot preview — academic content review passed per project-owner confirmation.
- [x] Review text and task difficulty for the intended audience — academic content review passed per project-owner confirmation.
- [x] Review multiple-choice distractors and feedback — academic content review passed per project-owner confirmation.
- [x] Review model responses and allow other evidence-supported interpretations — academic content review passed per project-owner confirmation.
- [x] Confirm the informal feedback guide is clearly distinguished from an official IB rubric.
- [ ] Complete and record the separate rights review.
- [ ] Complete and record the separate accessibility review.
- [ ] Verify official curriculum mapping before any claim of syllabus alignment or course release.
- [ ] Record an explicit release approval only after every required gate has evidence.

## Review record

| Field | Value |
|---|---|
| Reviewer | Academic lead — review pass confirmed by project owner; personal name not supplied |
| Date | 24 October 2026 |
| Decision | **Academic content review passed** for pilot preview version 1 |
| Review scope | Instructional draft, teaching sequence, practice prompts, answer guidance and informal feedback guide |
| Applicable syllabus/guide edition | Not verified |
| Approved official objective references | None recorded; candidate A(ii)/A(iii) references remain unverified |
| Rights review | Pending separate sign-off |
| Accessibility review | Pending separate sign-off |
| Official curriculum mapping | Unverified |
| Release approval | Not granted |

## Revision policy

Academic approval is version-specific, not a permanent freeze. Any approved or reviewed feature, content item, interface, rule or document can be amended later. Keep changes in Git history, update the relevant version/date/reason, and re-review the affected parts when a change is material. A change to content does not inherit the previous version's approval automatically.

## Release guardrail

The content review pass makes this package suitable for a pilot preview only. It is not a complete syllabus, official IB material, an official mark scheme, or an officially mapped/released course. Do not mark the unit ready for release based on this review sheet alone. The eight-gate release checklist in the Pathways screen remains authoritative for the current prototype state.
