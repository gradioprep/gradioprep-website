# Internal Diagnostic Provider Ranking Register

**Classification:** Internal project record — not learner-facing.  
**Version:** 1.0-draft  
**Date:** 31 October 2026  
**Owner:** Founder / project owner  
**Applies to:** Diagnostic-provider landscape research for each selected GradiPrep learning-readiness cycle.

## 1. Binding confidentiality rule

Provider ranking data is strictly internal. The Founder may retrieve the current percentile, supporting evidence, underlying data and ordinal position from this register.

**Never expose any of the following in a learner-facing or parent-facing evaluation report, dashboard, downloadable report, API payload, page source, client bundle or logged-in student/parent view:**
- provider percentile or composite ranking score;
- ordinal position (first, second, seventh, etc.);
- the ranking methodology, component weights or underlying provider test-taker counts;
- internal provider comparison or selection rationale.

This restriction applies whether or not a learner, parent or school user is logged in. Provider rankings are not learner performance percentiles and must never be conflated with them.

The current prototype has no authentication or private administrator area. Do not put internal ranking data into client-side application code or learner-report data structures. Keep it in private repository documentation until a separately approved, properly access-controlled internal retrieval mechanism exists. Do not add authentication or infrastructure as part of this requirement.

## 2. Approved 50/50 percentile methodology

The internal provider percentile is based on two equally weighted components:

| Component | Weight | Evidence basis |
|---|---:|---|
| Actual test-taker volume percentile | 50% | Number of unique actual students who completed the exact diagnostic product or a clearly identified norming/validation administration. |
| Independent research evidence percentile | 50% | Breadth and strength of genuinely independent research documents, studies, evidence clearinghouses and research sources for the exact product. |
| **Composite internal provider percentile** | **100%** | 0.50 × volume percentile + 0.50 × independent-research percentile. |

### 2.1 Test-taker volume evidence rules

- Prefer unique students who completed the exact diagnostic assessment within a clearly stated period.
- Record separately: unique students, number of test administrations/scores, study/norming sample size, grade-specific sample size, reporting period, geography and product/version.
- Do not treat school counts, educator counts, subscribers, registered accounts, downloads, practice activities or intervention-platform users as diagnostic test takers.
- Do not count repeated administrations as additional unique students.
- Do not mix a one-time historical standardisation sample with a current annual user count without a comparability warning.
- Prefer Grade 9 / relevant secondary-level data when available; do not silently substitute an all-grade total.
- Record the source and date checked. If a reliable number is not disclosed, record **not publicly disclosed**; do not estimate, extrapolate or invent it.

### 2.2 Independent research evidence rules

Count only genuinely independent sources as independent. Provider-authored technical manuals, marketing pages, product case studies and vendor-funded reports may inform product understanding but do not count as independent research sources for this 50% component.

For every independent source, record publisher, author/evaluator, publication date, study design, sample, grade/age fit, outcome measured, product version and limitations. Distinguish:
- peer-reviewed experimental or quasi-experimental studies;
- independent government, university or evidence-clearinghouse evaluations;
- independent technical/psychometric reviews;
- other credible independent research.

Do not inflate counts by counting mirrors, citations of the same study, derivative press releases or multiple pages from one report as separate documents. Source quality and relevance must be considered; raw link count alone is not sufficient.

### 2.3 Percentile calculation and missing evidence

Calculate the percentile rank for each component across the five providers only when the underlying values are sufficiently comparable and documented. Use a consistent ranking convention, disclose ties internally and retain the raw evidence table.

If one or more providers lack comparable test-taker or independent research evidence:
- mark the component **provisional / not scoreable** for that provider;
- do not fabricate a percentile or fill missing data with zero;
- do not publish a final composite percentile until the data coverage and comparability are adequate;
- preserve the qualitative weighted diagnostic-fit rubric as a separate research aid, not as a substitute for the approved 50/50 formula.

## 3. Grade 9 IB MYP Year 4 — evidence availability snapshot

The following is an evidence inventory, not a completed percentile ranking. Different products publish different kinds of counts; the figures must not be treated as directly comparable without further verification.

| Provider | Publicly located count evidence | Type / limitation | Current volume-component status |
|---|---|---|---|
| IXL LevelUp Diagnostic for ELA | Grade 9 30-day test-retest samples: Reading n=913; Writing & Language n=283 in the technical manual. | Grade-specific reliability subsamples, not total annual diagnostic users. | Provisional |
| Edmentum Exact Path | Vendor technical-report brief reports over 400,000 US students completing more than 1.7 million diagnostic assessments annually. | Annual unique-student and administration totals; confirm report date and exact product/version before final scoring. | Provisional |
| NWEA MAP Growth | 2025 norms report 13.8 million students and 116 million test scores across six testing terms (Fall 2022–Spring 2024). | Unique students and scores for norm development; broad MAP Growth population, not necessarily Grade 9 Reading + Language Usage alone. | Provisional |
| Lexia PowerUp Literacy | Vendor reports 940,600 students using PowerUp in 2025–26; a separate 2024–25 report records nearly 1.1 million users. | Program users and instructional activity, not a comparable standalone diagnostic-test-taker count. | Not comparable / further evidence needed |
| GL Assessment Progress Test in English | Current product page reports standardisation on over 37,000 students. | Standardisation sample; UK population and older EEF profile notes 2014 standardisation. | Provisional |

Sources:
- IXL technical manual: https://www.ixl.com/materials/IXL_LevelUp_Diagnostic_for_ELA_Technical_Manual.pdf
- Edmentum Exact Path Technical Report Brief: https://cdn.edmentum.com/assets/pdf/RSCH-108-4-Page-XP-Technical-Report-Brief.pdf
- NWEA 2025 MAP Growth norms: https://www.nwea.org/map-growth-norms/
- Lexia PowerUp 2025–26 usage report: https://www.lexialearning.com/resources/infographics/powerup-us-infographic
- GL Assessment PTE: https://www.gl-assessment.co.uk/products/progress-test-in-english/
- EEF PTE evidence profile: https://educationendowmentfoundation.org.uk/measures-database/progress-test-in-english

## 4. Independent-research evidence inventory

| Provider | Independent sources identified in the current review | Evidence caveat |
|---|---|---|
| IXL LevelUp ELA | NCII screening-tool profile; further independent Grade 9 validation evidence not yet established. | The technical manual is provider-authored and is not counted as independent. |
| Edmentum Exact Path | NCII screening-tool profile; independent state/academic evaluation records where product/version fit can be established. | Provider research-base papers are not independent. |
| NWEA MAP Growth | Independent Virginia validation study (ERIC record); independent technical/academic evaluations to be expanded. | NWEA technical reports and norms publications are provider-authored. |
| Lexia PowerUp Literacy | Evidence for ESSA; peer-reviewed cluster-randomised study. | Evidence grade/age range and intervention fidelity must be matched to Grade 9. |
| GL Assessment PTE | Education Endowment Foundation measure profile. | EEF profile notes age/norm and validity-evidence limitations; provider materials are not independent. |

The independent evidence inventory must be expanded and checked for duplicate studies before calculating the research percentile component.

## 5. Existing weighted diagnostic-fit rubric — separate from the 50/50 rank

The earlier six-criterion weighted review remains useful as a qualitative diagnostic-fit audit:
- diagnostic quality/construct validity/skill granularity — 25%;
- age/grade/context fit — 20%;
- reporting and analytics — 20%;
- actionable remediation — 15%;
- assessment design/item variety/adaptivity — 10%;
- evidence transparency/currency/access/privacy/practical suitability — 10%.

Its 100-point totals in the Grade 9 provider review are **not** the approved provider percentile and must not be substituted for it. Keep both analyses distinct.

## 6. Retrieval and change control

The Founder may request the internal provider percentiles, ordinal order, component evidence, source list or calculation audit at any time. Update this register when new reliable data is found, record the date and product/version, and preserve prior snapshots rather than silently overwriting history.

No ranking field from this register may be copied into student/parent-facing report content or frontend bundles. Any future internal retrieval feature requires a separate product/security design and explicit Founder approval.
