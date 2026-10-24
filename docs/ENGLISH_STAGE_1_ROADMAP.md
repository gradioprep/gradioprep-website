# English Stage 1 — Curriculum Roadmap

**Status:** Working roadmap. The first pilot unit's instructional content review passed for preview version 1; official syllabus mapping remains unverified, and the other pathway sequences still require their own review. Pathway count and production targets follow the master brief.
**Source of truth:** `PROJECT_MASTER_BRIEF.md`
**Purpose:** Turn the approved Stage 1 scope into a trackable production plan without claiming full syllabus coverage or inventing official curriculum mappings.

## 1. Rules that must not be broken

- IB MYP Language and Literature, Cambridge Lower Secondary English and Cambridge IGCSE First Language English are separate pathways. Do not merge their objectives into one generic “Grade 6–10 English” course.
- Grade equivalents are a navigation aid only. They are not a claim that a qualification or syllabus is officially defined by that school grade.
- Before an item is published, record the relevant programme, course, year/stage, syllabus edition (where applicable), skill objective, task type and review status.
- Verify mappings against the applicable official specification. Record the official URL, edition/code, date checked and reviewer. Do not invent objective codes or imply a syllabus edition has been checked when it has not.
- Stage 1 is a starter pathway, not exhaustive syllabus coverage. Quality and verified mapping take precedence over item counts.
- All content must be original or used with appropriate rights. Do not copy protected examination papers or paid materials into the platform without permission.
- Every current screen example remains demonstration content until individually reviewed and approved.

## 2. Initial pathway register

The approved planning target is 10 pathway entries. The two IGCSE rows below are learner-facing grade-equivalent bands under the relevant IGCSE course/syllabus, not separate official qualifications or automatically separate syllabuses.

| Pathway ID | Programme / course | Learner-facing level | Initial unit slots | Mapping status |
|---|---|---|---:|---|
| `ib-myp-lal-y1` | IB MYP Language and Literature | Year 1 (approx. Grade 6 equivalent) | 3 | To verify |
| `ib-myp-lal-y2` | IB MYP Language and Literature | Year 2 (approx. Grade 7 equivalent) | 3 | To verify |
| `ib-myp-lal-y3` | IB MYP Language and Literature | Year 3 (approx. Grade 8 equivalent) | 3 | To verify |
| `ib-myp-lal-y4` | IB MYP Language and Literature | Year 4 (approx. Grade 9 equivalent) | 3 | To verify |
| `ib-myp-lal-y5` | IB MYP Language and Literature | Year 5 (approx. Grade 10 equivalent) | 3 | To verify |
| `cambridge-ls-english-s7` | Cambridge Lower Secondary English | Stage 7 | 3 | To verify |
| `cambridge-ls-english-s8` | Cambridge Lower Secondary English | Stage 8 | 3 | To verify |
| `cambridge-ls-english-s9` | Cambridge Lower Secondary English | Stage 9 | 3 | To verify |
| `cambridge-igcse-fle-band-9` | Cambridge IGCSE First Language English | Grade 9-equivalent learning band | 3 | Confirm appropriate current syllabus and mapping |
| `cambridge-igcse-fle-band-10` | Cambridge IGCSE First Language English | Grade 10-equivalent learning band | 3 | Confirm appropriate current syllabus and mapping |

**Do not release the IGCSE rows as distinct syllabus tracks unless the academic lead confirms that the distinction is useful and correctly mapped.** They may share the same qualification syllabus while differing in the recommended sequence or readiness support.

## 3. Planning targets

These are production targets from the master brief, not promises of complete coverage:

| Measure | Initial target | Control |
|---|---:|---|
| Pathway entries | 10 | Keep official programme/course identity separate from grade-equivalent labels |
| Skill units | About 30 | About 3 per pathway; final distribution may differ if academic review requires it |
| Original short-form practice items | About 300 | Each must have a learning purpose, answer/explanation or appropriate marking guidance, and review status |
| Extended-response tasks | About 30 | Each must have task instructions, expected response format, task-specific rubric/criteria and credit requirement if offered for human grading |
| Diagnostic | One per pathway | Use only after skill mapping and scoring/recommendation rules are approved |
| Annotated example(s) | At least one per pathway | Clearly link the example to a verified objective or mark it as general introductory material pending mapping |
| Common mistakes and next steps | For each released unit | Must lead to a relevant skill or task, not a generic link |

Treat these counts as a planning baseline. Do not create filler items to hit a quota.

## 4. Unit planning sheet

Create three unit records for each pathway in the register. Initially, use the identifiers `<pathway-id>-u1`, `<pathway-id>-u2` and `<pathway-id>-u3`. The following fields must remain **unapproved/blank** until academic review; the identifier does not imply a confirmed skill focus.

| Field | Required decision or record |
|---|---|
| Unit title | Clear learner-facing title after content is selected |
| Learning objective | Specific, assessable skill written in original language |
| Official mapping | Objective/reference from the applicable verified specification, or an explicit “general/unmapped introductory content” label |
| Prerequisites | Prior skills needed, where relevant |
| Teaching sequence | Explanation, worked/annotated example, guided practice and independent practice as appropriate |
| Question mix | Selected task types and difficulty progression |
| Common errors | Typical errors with corrective explanation |
| Exit check | Evidence that informs the next recommendation |
| Review record | Academic reviewer, review date, content version and decision |
| Release state | Planned, Draft, In review, Approved, Published or Retired |

The academic lead can choose the actual unit focuses and their order after reviewing the official specifications. This document deliberately does not assign generic skills to official syllabus objectives.

## 5. Required fields for each content item

Every lesson, practice question, diagnostic item and extended-response task should carry:

- Stable content ID and version.
- Programme, course, pathway/year or stage, and applicable syllabus edition.
- One or more skill objective mappings, each with its own verification/review state.
- Content type and response type.
- Learner-facing title, instructions and body/prompt.
- Expected time where useful.
- Answer key and explanation for automatically checked items, or task-specific marking guidance/rubric for extended responses.
- Author, reviewer, review date, review notes and publication state.
- Rights/source note for any quoted or adapted material.
- Related prerequisites and next-step links only when those relationships have been reviewed.

Keep the answer key separate from learner-visible prompt content in the future application. Do not ship production answer keys to an unrestricted frontend bundle.

## 6. Content review and release gates

1. **Planned:** pathway/unit slot exists; no syllabus claim is made.
2. **Draft:** content authored; not visible as released learning material.
3. **Academic review:** verify accuracy, age/level suitability, objective mapping, difficulty, originality/rights and explanations.
4. **Approved:** reviewer records approval against the exact content version and syllabus mapping.
5. **Published:** only approved version is available to its intended audience.
6. **Retired:** hidden from new discovery but retained for audit/history where learner records depend on it.

A material edit to a published question, answer, rubric or syllabus mapping creates a new version and triggers review again. Existing attempts and assessments must retain the exact content/rubric version used at that time.

## 7. Acceptance checklist before the first pathway is released

- [ ] Academic lead selected the three unit focuses and sequence for this pathway.
- [ ] Applicable official specification and edition were checked and recorded.
- [ ] Each syllabus mapping is defensible and reviewed; unmapped general content is labelled honestly.
- [ ] The pathway is clearly labelled as Stage 1 starter content, not complete syllabus coverage.
- [ ] Lesson, example, question, answer/explanation and next step align.
- [ ] Extended-response tasks include their own task-specific rubric and explicit credit scope before submission.
- [ ] Content is original or has a recorded, appropriate rights basis.
- [ ] Accessibility, readability and responsive presentation were checked.
- [ ] All content states and versions are recorded; unreleased items do not appear as available.
- [ ] A final academic-lead approval is recorded.

## 8. Implementation status and immediate next action

**Change control:** Approved/reviewed units, features and documentation remain revisable at any later date. Track a version and rationale, update dependent documents, and repeat affected review gates for material changes.

A typed catalogue exists at `src/content/pathways.ts` with 10 planned pathways and three slots per pathway. The first IB MYP Year 1 pilot, **How writers shape meaning**, now has a unit brief (`src/content/pilotUnitDraft.ts`), a learner-safe lesson source (`src/content/pilotLearnerLesson.ts`) and a separate teacher/editor answer source (`src/content/pilotLessonPack.ts`). Academic content review for pilot-preview version 1 passed, as confirmed by the project owner on 24 October 2026. The Lesson screen is interactive: learners can select a choice, draft written answers and check success indicators. The preview does not score or persist responses.

The teacher/editor source is not imported into the client UI; only learner-safe data is used in the lesson view. This is adequate for the static preview but is not production authorization. Real answer keys must be served only through a protected server-side path.

The official IB guide edition and objective mapping remain unverified. Candidate Criterion A strands A(ii) and A(iii) are not recorded as official objective codes. The static readiness fixture now records the reviewed lesson and practice IDs, answer-key review and academic-review pass. Rights review, accessibility review and explicit release approval remain separate outstanding gates. Therefore the unit is **approved for pilot preview only**, not a released syllabus-mapped course.

Next, complete the independent source/mapping and rights/accessibility evidence, then implement production content storage and server-side learner/teacher authorization before real learner records or graded submissions are added. Do not infer a production release from this preview.
