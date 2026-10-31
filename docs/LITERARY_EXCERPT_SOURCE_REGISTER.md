# Literary Excerpt Source Register

**Version:** 1.2  
**Created:** 30 October 2026; source record recheck updated 31 October 2026  
**Access:** Internal/private project record. Do not expose teacher-only source notes or unreleased assessment material to learners.  
**Authority:** `docs/CONTENT_ORIGINALITY_AND_RIGHTS_PROTOCOL.md` and `docs/TEACHER_PACK_AND_FEEDBACK_STANDARD.md`.

## 1. Purpose

This register records the provenance of every learner passage and the full public-domain source details required for passages over 250 words. It is the single lookup point for replacing a passage without redesigning the website, navigation, layout, learner/teacher data boundary or assessment architecture. Platform-original passages of 250 words or fewer receive an authorship/provenance record here but do not receive a fictitious public-domain Source ID.

Use two identifiers:

- **Excerpt ID:** stable identifier for the location/role of an excerpt in a unit. Keep it when the passage is replaced.
- **Source ID:** identifies the exact public-domain work, edition/transcription and excerpt for a passage over 250 words. Create a new Source ID whenever the work, edition or excerpt changes.
- **Original-authorship record:** for a platform-original passage of 250 words or fewer, record author/owner, word count, creation date/version, linked task IDs, originality/provenance screen and suitability; do not create a public-domain Source ID.

No new passage may be inserted until its Excerpt ID and the correct record type (short-original provenance or long-form public-domain source) are present here. Preserve old records and mark them replaced rather than deleting them.


## 2. Existing passage/source audit baseline

The rows below preserve the earlier passage inventory. Apply the new 250-word threshold during each unit's scheduled revision; do not replace a project-authored passage solely because it is original.

| Excerpt ID | Track / unit | Existing passage or stimulus | Current source location | Current status | Required action |
|---|---|---|---|---|---|
| EXC-IB-MYP-Y1-U1-MAIN | IB MYP Language and Literature Year 1 Unit 1 | v1/v2 main passage | src/content/pilotLearnerLesson.ts / prior v2 teacher pack | Replaced in approved candidate v3 by Dickens Source ID SRC-IB-MYP-Y1-U1-001 | Keep v3 unchanged; v1/v2 records remain historical. |
| EXC-IB-MYP-Y1-U1-TRANSFER | IB MYP Language and Literature Year 1 Unit 1 | v2 original transfer micro-extract | Prior src/content/pilotLessonPack.ts | Replaced in approved candidate v3 by Carroll Source ID SRC-IB-MYP-Y1-U1-002 | Keep v3 unchanged; v2 record remains historical. |
| EXC-CAM-LS-S7-U1-WARMUP | Cambridge Lower Secondary English 0861 Stage 7 Unit 1 | “The map's corners fluttered…” warm-up mini-text | Cambridge v1.3 learner material / QA record | Platform-original; exact word count to be audited at its scheduled revision | Retain if 250 words or fewer. If over 250 and still a reading stimulus, replace with a registered public-domain excerpt; recasting/removal is a content-design choice within the authorised revision. |
| EXC-CAM-LS-S7-U1-MAIN | Cambridge Lower Secondary English 0861 Stage 7 Unit 1 | “The Rain Gauge” | Cambridge v1.3 learner material / QA record | Platform-original; exact word count to be audited at its scheduled revision | Retain if 250 words or fewer. If over 250, use a registered public-domain excerpt in the revised version and update dependent tasks/answers. |
| EXC-CBSE-G6-U1-MAIN | CBSE English Grade 6 Unit 1 “The Turning Sign” | Original narrative | CBSE v1.0 learner content / QA record | Platform-original; exact word count to be audited at its scheduled revision | Retain if 250 words or fewer. If over 250, use a registered public-domain excerpt in the revised version and update dependent tasks/answers. |

## 3. Required fields for each public-domain source record

| Field | Required entry |
|---|---|
| Source ID | Unique identifier, e.g. `SRC-IB-MYP-Y1-U1-001` |
| Excerpt ID | Stable placement ID from Section 2 or a new registered ID |
| Work | Exact work title |
| Author | Recognised writer's full name and relevant dates |
| Original language | Language in which the work was written |
| Publication details | First publication date/source and exact edition/transcription used |
| Edition / translation | Editor, translator, publisher/repository and date, if applicable; mark original text where appropriate |
| Source URL | Exact page for the work/version, not a search-result URL |
| Public-domain basis | Concise evidence and intended territory/territories checked, including India |
| Location | Chapter, section, stanza, poem, act/scene, paragraph or page |
| Excerpt anchor | Exact opening/closing words and any omitted lines; the unit content file stores the exact excerpt |
| Adaptation record | Punctuation, spelling, ellipses, brackets or formatting changes; default is no substantive modernisation |
| Intended use | Programme, course, level, unit, question IDs and skill |
| Suitability check | Style, syntax, semantic context, vocabulary, age/cultural suitability and intended task fit |
| Checked by / date | Responsible reviewer and date |
| Status | Candidate, verified, blocked, replaced or retired |
| Replacement history | Previous Source ID, reason and content version affected |

## 4. Quick source selection and quality workflow

1. Choose a recognised public-domain work likely to provide a good excerpt for the target skill and age band.
2. Check the exact work/edition and public-domain status for the intended territory. Check a translation separately. Use the simplest reliable primary or public-domain source record available.
3. Read enough surrounding context to ensure the excerpt is represented accurately and is stylistically, syntactically and semantically appropriate.
4. Record the exact location and Source ID here **before** adding it to the learner or teacher file.
5. Link every question and teacher-pack entry to the Excerpt ID/Source ID.
6. If a concern is reported later, replace the source while preserving the Excerpt ID; create a new Source ID, content version and updated passage-dependent answers.

This is a quick, proportionate selection check, not a demand for exhaustive literary/legal research. A source that is not clearly public domain or does not fit the learner/task should be rejected in favour of another. Modern translations, editions, annotations, transcriptions and images can carry separate rights even when the underlying work is public domain.

## 5. Future replacement guarantee

The source register is independent of application routes and components. Passage content is versioned data; questions refer to stable Excerpt IDs and question IDs, not page-layout or navigation details. Replacing a source must not require changes to site navigation, URL hierarchy, component design, account flows or assessment service contracts. Only the content, source record, question-specific answers and required review/version data should change.


## 6. IB MYP Language and Literature Year 1 Unit 1 — version 3 source records

The following records were added to the register before the corresponding excerpt text was committed to the learner/teacher candidate. The Excerpt IDs are stable placements retained from v2; the Source IDs are new and version-specific.

### 6.1 Main reading — Charles Dickens

| Field | Record |
|---|---|
| Source ID | `SRC-IB-MYP-Y1-U1-001` |
| Excerpt ID | `EXC-IB-MYP-Y1-U1-MAIN` |
| Work | `A Christmas Carol in Prose, Being a Ghost Story of Christmas` |
| Author | Charles Dickens (1812–1870); death 9 June 1870. |
| Original language | English |
| Publication details | London: Chapman & Hall, 1843. First edition, first issue confirmed by Morgan Library & Museum catalogue record (PML 30615); publication date also corroborated by the British Library. |
| Edition / transcription | Original English text; transcription checked against the 1843 Wikisource text page for Stave I. No modern translation, annotation, illustration or modern adaptation is incorporated. The underlying work and exact 1843 edition are identified separately from the online transcription. |
| Source URL | https://en.wikisource.org/wiki/A_Christmas_Carol_(Dickens,_1843)/Stave_1 |
| Edition evidence | https://www.themorgan.org/printed-books/168654 ; https://www.britishlibrary.cn/en/works/charles-dickenss-christmas-carol/ |
| Public-domain basis | **India:** Copyright Act, 1957, s.22: known-author published literary works generally remain protected until 60 years from the beginning of the calendar year following death. Dickens died in 1870; the term therefore ended 31 December 1930, and the work was public domain in India from 1 January 1931. **United Kingdom:** CDPA 1988, s.12(2): life plus 70 years from the end of the year of death. Dickens died in 1870; the term ended 31 December 1940, and the work was public domain in the UK from 1 January 1941. Author death date corroborated by Westminster Abbey. |
| Territory scope | India and United Kingdom checked for this candidate. United States and other territories are not cleared by this record; obtain jurisdiction-specific review before using there. |
| Location | Stave I, “Marley's Ghost”, paragraph beginning “The city clocks had only just gone three” and ending “brewing on a large scale.” |
| Excerpt anchor | Opening: “The city clocks had only just gone three”. Closing: “brewing on a large scale.” The excerpt comprises the full two consecutive paragraphs at the Wikisource lines corresponding to the counting-house exterior; no internal lines omitted. |
| Adaptation record | Text follows the source wording and paragraph order. No translation or substantive rewriting. Paragraph break retained. The candidate uses typographic quotation marks only in teaching notes, not as changes to the source passage. |
| Intended use | IB MYP Language and Literature Year 1 Unit 1 version 3; main reading; Q1–Q5 and guided evidence-chain teaching. |
| Suitability check | The 95-word passage supports imagery, comparison, personification, atmosphere and contextual reasoning. Victorian syntax and terms such as “palpable”, “chink” and “phantoms” create a meaningful but demanding reading load; a visible glossary and teacher-led sentence chunking are included. Human age/level, cultural/context and academic suitability review remains pending. |
| Checked by / date | Project content/rights research pass; 30 October 2026. Not a legal opinion or final rights approval. |
| Status | Candidate source recorded; final unit-level rights approval pending. |
| Replacement history | Replaces the platform-original v1/v2 use at the same Excerpt ID. Previous content and approval history remain in Git history and the v2 reconciliation record. |

### 6.2 Independent transfer — Lewis Carroll

| Field | Record |
|---|---|
| Source ID | `SRC-IB-MYP-Y1-U1-002` |
| Excerpt ID | `EXC-IB-MYP-Y1-U1-TRANSFER` |
| Work | `Alice's Adventures in Wonderland` |
| Author | Lewis Carroll (Charles Lutwidge Dodgson, 1832–1898); death 14 January 1898. |
| Original language | English |
| Publication details | London: Macmillan and Co., 1866-dated issue (the second edition/impression printed in November 1865 and dated 1866 for the Christmas trade). Morgan Library & Museum confirms the issue history; Library of Congress catalogues the London Macmillan 1866 copy. |
| Edition / transcription | Original English text, checked against the 1866-dated Macmillan title-page transcription and Chapter I text on Wikisource. No modern translation, Tenniel illustration, annotation or modern adaptation is incorporated. |
| Source URL | https://en.wikisource.org/wiki/Alice%27s_Adventures_in_Wonderland_%281866%29/Chapter_1 |
| Edition evidence | https://www.themorgan.org/printed-books/169544 ; https://www.loc.gov/item/30004663/ |
| Public-domain basis | **India:** Copyright Act, 1957, s.22: known-author published literary works generally remain protected until 60 years from the beginning of the calendar year following death. Carroll died in 1898; the term therefore ended 31 December 1958, and the work was public domain in India from 1 January 1959. **United Kingdom:** CDPA 1988, s.12(2): life plus 70 years from the end of the year of death. Carroll died in 1898; the term ended 31 December 1968, and the work was public domain in the UK from 1 January 1969. Author dates corroborated by Oxford Academic. |
| Territory scope | India and United Kingdom checked for this candidate. United States and other territories are not cleared by this record; obtain jurisdiction-specific review before using there. |
| Location | Chapter I, “Down the rabbit-hole”, from the paragraph beginning “The rabbit-hole went straight on like a tunnel” through the end of the paragraph describing cupboards, book-shelves, maps and pictures hung upon pegs. |
| Excerpt anchor | Opening: “The rabbit-hole went straight on like a tunnel for some way”. Closing: “here and there she saw maps and pictures hung upon pegs.” This is a continuous extract; no internal lines omitted. |
| Adaptation record | Text follows the cited original-English transcription. No translation, illustration or substantive rewriting. Original hyphenation “book-shelves” retained. |
| Intended use | IB MYP Language and Literature Year 1 Unit 1 version 3; independent exit transfer task; apply evidence-based analysis to a distinct fantasy context. |
| Suitability check | The 129-word extract offers a genuinely different fantasy setting and supports analysis of sudden change, simile, pacing, uncertainty and curiosity. The passage includes a long sentence and less familiar words; vocabulary support is included. Human age/level, cultural/context and academic suitability review remains pending. |
| Checked by / date | Project content/rights research pass; 30 October 2026. Not a legal opinion or final rights approval. |
| Status | Candidate source recorded; final unit-level rights approval pending. |
| Replacement history | Replaces the platform-original sunrise-platform transfer at the same Excerpt ID. Previous v2 content remains historical. |

### 6.3 Territory references and rights boundary

- India Copyright Act, 1957, section 22: https://copyright.gov.in/Copyright_Act_1957/chapter_v.html
- UK Copyright, Designs and Patents Act 1988, section 12: https://www.legislation.gov.uk/ukpga/1988/48/section/12
- Dickens death date: https://www.westminster-abbey.org/abbey-commemorations/commemorations/charles-dickens
- Carroll life dates: https://academic.oup.com/reference/62337/reference-article-abstract/554126366

The term calculations concern the underlying literary works and the specified historical English editions only. They do not clear later translations, annotations, modern editorial material, illustrations, scans, typographic designs or other assets. The project's initial cleared territory scope in these records is India and the UK; United States and other distribution territories require separate rights review before use. Final unit-level rights approval remains a separate release gate.

### 6.4 Existing poster photograph — recheck

The existing photograph “Bus stop with platform during night.jpg” by Mateusz Konieczny remains a separate visual asset. The Wikimedia Commons file page identifies the creator and expressly states CC0 1.0 Universal Public Domain Dedication: https://commons.wikimedia.org/wiki/File:Bus_stop_with_platform_during_night.jpg. Rechecked 31 October 2026. The original fictional poster copy and layout remain platform-authored. Asset-level source review does not complete the separate unit-level rights, visual-context or accessibility gate.

## 7. MYP v3 excerpt and visual-source recheck — 31 October 2026

The two current learner text excerpts were checked again against their registered source pages and opening/closing anchors. Under the project's lexical word-count rule, the Dickens main extract is 95 words and the Carroll transfer extract is 129 words. Both are historical original-English text passages well below the 250-word threshold; they were not changed during the recheck.

The project source register continues to record the intended-territory term calculations: India Copyright Act, 1957, section 22 (known-author life plus 60 years, counted from the beginning of the following calendar year) and UK Copyright, Designs and Patents Act 1988, section 12 (life plus 70 years, counted from the end of the year of death). The associated source pages and author-date references remain in Sections 6.1–6.3. These calculations concern the underlying Dickens and Carroll works only; they do not clear modern translations/editions outside the checked text, later editorial material or all territories. The current source record checks India and the UK only; the United States and other territories remain uncleared.

The Wikimedia Commons page for “Bus stop with platform during night.jpg” by Mateusz Konieczny was rechecked and continues to state CC0 1.0 Universal Public Domain Dedication. This record does not establish that the photograph visually supports every teacher-pack description (including “bright shelter”), nor does it replace human review of privacy, model/property, publicity, contextual or accessibility concerns. The image and its use remain subject to final unit-level human review.

**Disposition:** source/file-page recheck recorded; no v3 excerpt, photo, poster copy, alt text, question, answer or teacher-pack content was changed. Final unit-level rights and territory approval remain pending.
