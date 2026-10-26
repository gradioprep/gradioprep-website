# English Curriculum Guides — Year/Stage Framework and Pathway Implementation Plan

**Status:** Internal guide register v0.8. The original 12 planned year/stage/delivery entries across four curriculum groups remain under versioned development; the separately approved CBSE English Grades 6–12 pathway is recorded in its research brief and the Unit Production Register, with class-wise research/guides still pending. Exact official objective maps remain unverified where current descriptors are not directly available.
**Source of truth:** `PROJECT_MASTER_BRIEF.md`, `ENGLISH_STAGE_1_ROADMAP.md`, `ENGLISH_CURRICULUM_RESEARCH_AND_DESIGN_STANDARD.md`, and `ENGLISH_PUBLIC_SOURCE_REGISTER.md`.
**Purpose:** Provide a maintainable guide structure for each approved year/stage without inventing official syllabus objectives or unit sequences.

## 1. Document architecture decision

Use **one independently reviewable guide per curriculum-year/stage track**, plus one shared research/pedagogy standard and a compact register. Finish a guide and implementation structure, record founder approval, then produce and review the relevant unit within the binding Unit 1 rotation. The active second item is Cambridge Stage 7 Unit 1 v1.3; founder review is pending. It keeps approval, source editions, changes and completion status unambiguous; a single large group document can hide unfinished year-level work.

Use a separate implementation-plan document for each curriculum-year/stage track. Keep shared research methods, evidence standards, source-access limits and the rubric in the central research standard/register.

Canonical guide files:
- `docs/curriculum/IB_MYP_LANGUAGE_AND_LITERATURE_YEAR_1_GUIDE.md` — **public-framework-aligned guide v1.1; founder-approved 26 October 2026; current official objective mapping remains unverified**.
- `docs/curriculum/IB_MYP_YEAR_1_PATHWAY_IMPLEMENTATION.md` — **implementation structure v1.2; guide/structure founder-approved; Unit 1 v2 remains an unmerged candidate with separate review and release gates open**.
- `docs/curriculum/IB_MYP_LANGUAGE_AND_LITERATURE_GUIDE.md` — legacy group draft with Years 1–5 chapters; Year 1 is superseded by the standalone guide. Years 2–5 remain drafts, not completed/approved guides.
- `docs/curriculum/CAMBRIDGE_LOWER_SECONDARY_ENGLISH_0861_GUIDE.md` — group guide v0.5; Stage 7 Unit 1 v1.3 is the active draft review candidate. Founder review of the exact unit remains pending; full current framework/version and objective codes beyond 7Ri.03 explicit-information items remain unverified.
- `docs/curriculum/IB_DP_LANGUAGE_A_LANGUAGE_AND_LITERATURE_GUIDE.md` — existing group draft; review/split DP Year 1 as its own guide when it reaches the approved rotation.
- `docs/curriculum/CAMBRIDGE_IGCSE_FIRST_LANGUAGE_ENGLISH_0500_GUIDE.md` — syllabus-wide 0500 source/assessment register. Delivery phases are platform conventions, not official syllabus years.
- `docs/curriculum/UNIT_PRODUCTION_REGISTER.md` — source, completion checkpoint, Unit 1 rotation and release-gate register.
- `docs/ENGLISH_CURRICULUM_RESEARCH_AND_DESIGN_STANDARD.md` and `docs/ENGLISH_PUBLIC_SOURCE_REGISTER.md` — shared research rubric, source currency/access and sample-paper rules.

Every standalone guide must contain a source/edition register, publicly verifiable syllabus/framework facts, explicit unmapped fields where necessary, progressive outcomes, proposed unit sequence, task/assessment design, common misconceptions, inclusion/accessibility, rights considerations, self-rating, review history and release gates. Its implementation plan translates the guide into route/content metadata and QA without silently changing curriculum decisions.

## 2. Year/stage guide register

The entries below define **guide work to complete**, not official IB/Cambridge teaching sequences. No topic or unit objective is assigned to an official syllabus unless directly verified. Previously drafted group chapters are not treated as completed standalone guides until their turn in the rotation.

| Track | Guide chapter | Scope to research | Current state |
|---|---|---|---|
| IB MYP Language and Literature | Year 1 | Public six-skill framework, inquiry, text/context/audience/purpose; progressive evidence-led unit plan | Standalone guide v1.1 and implementation structure v1.2 founder-approved; Unit 1 v2 candidate remains subject to separate review gates; official objective/strand mapping not claimed |
| IB MYP Language and Literature | Year 2 | Independent evidence selection, stronger reasoning and purposeful communication | Draft chapter exists; official mapping unverified |
| IB MYP Language and Literature | Year 3 | Sustained analysis, evidence-driven argument and comparison | Draft chapter exists; official mapping unverified |
| IB MYP Language and Literature | Year 4 | Layered interpretation, contextual nuance and synthesis | Draft chapter exists; official mapping unverified |
| IB MYP Language and Literature | Year 5 | Independent transfer and preparation for school-selected assessment route; optional eAssessment is not assumed | Draft chapter exists; official Year 5/eAssessment descriptors remain unverified |
| Cambridge Lower Secondary English 0861 | Stage 7 | Public-framework-aligned design for reading, writing, speaking/listening; official objective IDs must match the exact framework version | Group guide v0.5; Unit 1 v1.3 is an AI-reviewed candidate awaiting founder review. 7Ri.03 is used only for explicit information; full framework/version and other codes remain unverified |
| Cambridge Lower Secondary English 0861 | Stage 8 | Explain effects, choose planning approach and strengthen discussion/performance | Draft chapter exists; official objective-code verification pending |
| Cambridge Lower Secondary English 0861 | Stage 9 | Analyse structure/effect, write independently, and prepare for chosen next pathway | Draft chapter exists; official objective-code verification pending |
| IB DP Language A: Language and Literature | Year 1 delivery chapter | Close reading, purpose/context, analysis of choices and transfer to current assessed task types | Draft chapter exists; detailed assessment mapping and school sequence need review |
| IB DP Language A: Language and Literature | Year 2 delivery chapter | Timed analytical application, comparative argument and oral integration where officially applicable | Draft chapter exists; session-specific assessment details need review |
| Cambridge IGCSE First Language English 0500 | Grade 9-equivalent delivery band (proposed phase A) | Build on official 0500 syllabus and specimens for the learner’s exam year; verify component/route | Draft syllabus-wide guide exists; candidate exam-year route remains to record |
| Cambridge IGCSE First Language English 0500 | Grade 10-equivalent delivery band (proposed phase B) | Integrate reading/writing and exam readiness under the same verified 0500 syllabus | Draft second-phase guidance exists in same syllabus guide; proposed school sequence needs academic review |

### Official programme differences to preserve

- **IB MYP Language and Literature:** IB identifies listening, speaking, reading, writing, viewing and presenting; inquiry, context, cultural perspectives and conceptual understanding matter. MYP assessment criteria and required strands must be taken from the applicable current guide, not inferred from the public overview.
- **Cambridge Lower Secondary English 0861:** Cambridge describes an integrated reading, writing, speaking and listening curriculum, using fiction, poetry, playscripts and non-fiction. Framework objectives and progression indicators must be transcribed/verified from the current official framework.
- **IB DP:** The founder has selected Language A: Language and Literature. Preserve its distinction from Language A: Literature and Language B. Year 1 and Year 2 are platform delivery chapters mapped to the full course guide and verified local sequence, not separate official DP syllabuses.
- **Cambridge IGCSE:** Scope is limited to First Language English 0500. A syllabus is not inherently divided into product “Year 1” and “Year 2”; the two grade-equivalent bands are delivery planning conventions. Verify the applicable exam-year syllabus and permitted component/route before mapping.

## 3. Mandatory guide template

For each year/stage chapter, complete all sections below. If a field is not yet verifiable, state **“Not verified — blocked”**, identify the needed source and do not invent a substitute.

1. **Identity and version**
   - Programme, course, year/stage and official syllabus code where applicable.
   - Guide edition/version, first teaching/assessment/exam year and last verification date.
   - Official source URL, source title, access date, relevant pages/sections.
2. **Learner context**
   - Assumed prior learning and prerequisite checks.
   - Language background assumptions; avoid equating school grade with proficiency.
   - Support and extension needs.
3. **Official curriculum requirements**
   - Verified objectives/criteria/strands in a traceable table.
   - Assessment format, weighting and rules where officially specified.
   - Explicitly distinguish official requirements from our teaching recommendations.
4. **Progression**
   - What should be known before this year/stage.
   - Expected growth within it.
   - Readiness evidence for the next stage.
   - Vertical progression links verified against adjacent guide chapters.
5. **Unit sequence**
   - Three proposed unit slots initially, as in the existing roadmap; the number can change only after evidence-based academic approval.
   - Each unit includes its objective mappings, essential question/purpose, core knowledge, text-type coverage, model, practice, transfer task and exit evidence.
   - Mark proposed sequences as platform design decisions, not official syllabus order.
6. **Assessment blueprint**
   - Formative checks, independent task, task-specific success criteria/rubric, feedback and revision.
   - Clear alignment between taught skill, task demand and judgement criteria.
   - Do not promise automatic grading or official grades.
7. **Text and rights plan**
   - Genre/text-type range and rationale.
   - Original writing or documented rights basis.
   - Cultural breadth, age suitability and sensitive-content review.
8. **Inclusive teaching and access**
   - Vocabulary/pre-teaching, scaffolded and stretch pathways, accessibility, assistive technology and readable formats.
   - Avoid reducing cognitive demand when providing access support.
9. **Evidence-informed distinctive features**
   - Annotated worked examples; model–practice–reflect; reading-to-writing transfer; criterion-linked feedback; deliberate revision; visible evidence of progression.
   - Each feature states its evidence basis and how impact will be tested.
10. **Quality assurance and release**
    - Academic reviewer, rights reviewer, accessibility reviewer, exact content version and approval date.
    - Unresolved issues, confidence level and release status.
11. **Source and change log**
    - Citations, source dates, mapping changes and reason for revision.

## 4. Proposed pathway structure

Use this hierarchy consistently:
**Pathways catalogue → curriculum/course → year/stage or verified syllabus route → unit detail → lesson/practice → feedback and next-step recommendation.**

For each pathway, show:
- The official programme/course identity separately from any familiar grade equivalent.
- Which syllabus edition/exam year the pathway supports.
- A clear “starter coverage” label while the scope is incomplete.
- Unit-level status (planned, draft, in review, approved, published) based on records, not visual styling.
- A transparent explanation when an objective, next unit or syllabus route has not yet been verified.

The pathway's unit order is our recommended learning sequence unless the official source explicitly prescribes one. Never imply that IB or Cambridge endorsed our unit design.

## 5. Rotation rules: guide creation first, then unit content

**Binding founder instruction:** complete a year/stage curriculum-guide chapter in a cross-track rotation. Only after the guide cycle has been completed should new learner-facing unit content be produced, also in a cross-track rotation. Do not complete an entire curriculum group before starting the others. The sequence below is our production order, not official IB/Cambridge curriculum order.

### A. Curriculum-guide creation rotation

1. IB MYP Language and Literature — Year 1 (public-framework-aligned guide drafted; objective/strand mapping remains unverified).
2. Cambridge Lower Secondary English 0861 — Stage 7.
3. IB DP Language A: Language and Literature — Year 1 delivery chapter.
4. Cambridge IGCSE First Language English 0500 — first proposed delivery phase, under the one syllabus-wide guide.
5. IB MYP Language and Literature — Year 2.
6. Cambridge Lower Secondary English 0861 — Stage 8.
7. IB DP Language A: Language and Literature — Year 2 delivery chapter.
8. Cambridge Lower Secondary English 0861 — Stage 9.
9. Cambridge IGCSE First Language English 0500 — second proposed delivery phase, still under the same syllabus-wide guide.
10. IB MYP Language and Literature — Year 3.
11. IB MYP Language and Literature — Year 4.
12. IB MYP Language and Literature — Year 5.

### B. Unit-content production rotation, after the guide cycle

Use the same order for Unit 1 across every eligible track, then repeat across the approved tracks for Unit 2, then Unit 3. No curriculum group is to be completed end-to-end first.

1. IB MYP Year 1 — Unit 1.
2. Cambridge Lower Secondary Stage 7 — Unit 1.
3. IB DP Language A: Language and Literature Year 1 — Unit 1.
4. Cambridge IGCSE 0500 first approved delivery phase — Unit 1.
5. IB MYP Year 2 — Unit 1.
6. Cambridge Lower Secondary Stage 8 — Unit 1.
7. IB DP Language A: Language and Literature Year 2 — Unit 1.
8. Cambridge Lower Secondary Stage 9 — Unit 1.
9. Cambridge IGCSE 0500 second approved delivery phase — Unit 1.
10. IB MYP Year 3 — Unit 1.
11. IB MYP Year 4 — Unit 1.
12. IB MYP Year 5 — Unit 1.

Continue through Unit 2 and Unit 3 in the same order. A track whose source, exam-year syllabus, objective mapping, rights or required review gates are unresolved stays **Blocked**; do not invent content to preserve the rotation. For IGCSE, the two delivery phases remain a proposed school-level learning sequence under syllabus 0500, not separate official qualifications or syllabuses.

## 6. Implementation gates and immediate next step

The detailed current MYP guide and Year 1 objective/strand descriptors remain preferred sources if they become publicly available, but their absence does not block public-source-aligned guide design. Only claims of official objective mapping remain blocked. Before marking any year guide complete:
- [ ] Use the source/currency method in `docs/ENGLISH_PUBLIC_SOURCE_REGISTER.md`; check and record public official source versions.
- [x] Draft a public-framework-aligned Cambridge Lower Secondary Stage 7 guide; the exact objective table remains blocked pending verification of the applicable official framework version.
- [ ] Verify the current Cambridge Lower Secondary English 0861 framework through Cambridge's official resource/support site before assigning objective codes.
- [x] Founder selected IB DP Language A: Language and Literature on 25 October 2026; verify the applicable current course guide and school delivery sequence.
- [x] Founder confirmed Cambridge IGCSE First Language English 0500 only; keep 0990, O Level 1123 and English as a Second Language outside scope unless separately approved.
- [ ] Confirm and record the Cambridge IGCSE 0500 exam-year syllabus and component/route; the 2027–2029 Version 1 syllabus is the baseline for candidates from 2027.
- [ ] Approve the unit sequence and rubric/assessment design before bulk production.
- [ ] For each unit, clear objective mapping, academic review, rights, accessibility and explicit release approval separately.

The current pilot **How writers shape meaning** remains academic-review passed for pilot preview version 1 only. The public-source Year 1 guide evaluates it as a candidate Unit 1 but does not convert it into official objective mapping or clear its separate rights/accessibility/release gates.

## 7. Research sources

- IB MYP Language and Literature: https://www.ibo.org/programmes/middle-years-programme/curriculum/language-and-literature/
- IB MYP curriculum: https://www.ibo.org/programmes/middle-years-programme/curriculum/
- IB DP Studies in Language and Literature: https://ibo.org/programmes/diploma-programme/curriculum/language-and-literature/
- IB DP Language A: Language and Literature: https://ibo.org/programmes/diploma-programme/curriculum/language-and-literature/language-a-language-and-literature/
- IB DP Language A: Literature: https://ibo.org/programmes/diploma-programme/curriculum/language-and-literature/language-a-literature/
- Cambridge Lower Secondary English 0861: https://www.cambridgeinternational.org/programmes-and-qualifications/cambridge-lower-secondary/curriculum/english/
- IB MYP Language and Literature detailed guide resource (sign-in required in this environment): https://resources.ibo.org/data/m_1_langa_guu_1405_8_e.pdf
- IB Programme Resource Centre: https://resources.ibo.org/
- Cambridge IGCSE First Language English 0500: https://www.cambridgeinternational.org/programmes-and-qualifications/cambridge-igcse-english-first-language-0500/
- Cambridge 0500 2027–2029 syllabus: https://www.cambridgeinternational.org/Images/718783-2027-2029-syllabus.pdf
- IES/WWC secondary writing practice guide: https://ies.ed.gov/ncee/wwc/PracticeGuide/22
- EEF Metacognition and Self-Regulated Learning (second edition, 2025): https://educationendowmentfoundation.org.uk/education-evidence/guidance-reports/metacognition/
- EEF Improving Literacy in Secondary Schools: https://educationendowmentfoundation.org.uk/education-evidence/guidance-reports/literacy-ks3-ks4
- OECD PISA 2022 Results, Volume II: https://www.oecd.org/en/publications/2023/12/pisa-2022-results-volume-ii_222a5ef6/full-report/component-10.html


## MYP Year 1 resource-depth checkpoint — 26 October 2026

The v1.0 guide's research scope was too narrow for the founder's request to assess MYP-focused EdTech platforms. Version 1.1 now includes a dedicated comparative audit of InThinking/ThinkIB, ASJ Learning, Hachette Learning/MYP by Concept, ManageBac+, Toddle, My IB Hub and lower-confidence marketplace sources, alongside current public IB pages and the indexed 2014/15 detailed guide reference.

The old detailed guide is treated as a **legacy reference, not verified current edition**. Enhanced MYP beta guidance remains a separate transition watch. Year 1 is now six proposed units plus shared time for diagnostics, language support, retrieval, revision and transfer, totaling at least 50 planned teaching hours. These unit names/order are platform decisions, not IB-prescribed structure. The MYP guide and implementation structure have founder approval, while MYP Unit 1 v2 remains subject to separate review and release gates. Stage 7 Unit 1 v1.3 is the active candidate awaiting founder review; the later production rotation remains blocked until the required gate records are complete.
