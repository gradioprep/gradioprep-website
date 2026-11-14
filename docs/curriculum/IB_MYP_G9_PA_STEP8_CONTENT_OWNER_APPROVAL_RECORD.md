# IB MYP Year 4 PA — Step 8 Founder content-owner approval receipt and release gates

**Date:** 14 November 2026  
**Status:** Founder/content-owner review approved; **independent academic scoring/release acceptance remains blocked**.  
**Scope:** 30 provisional evidence observations across RV10, LC5, AW5, CW5, SP5; Listening excluded from PA.  
**Source of truth:** `PROJECT_MASTER_BRIEF.md` §§53–54; `IB_MYP_G9_DIAGNOSTIC_ITEM_MAP_AND_SCORING_SPEC.md` §5.1; `ASSESSMENT_CURRICULUM_MAPPING_AND_MILESTONE_STANDARD.md`; `TEACHER_PACK_AND_FEEDBACK_STANDARD.md`.

## Exact approved package and limits

**Founder/content-owner approval: recorded 14 November 2026.** The Founder stated “Reviewed and approved” in the current GradioPrep implementation conversation, in response to the exact Step 8 **restricted academic review package** previously provided for review. Treat this as authorisation to adopt and reconcile the *proposed draft wording, evidence corrections, private pack review candidates and review-checklist format* in that package; it is not an assertion that missing independent reviews, authorised curriculum sources, numerical rubric decisions or witnessed calibrations already exist.

- Package name: `GradioPrep_Step8_Restricted_Academic_Review_Package.zip`.
- Package SHA-256: `5575a0d1bb8e4358697014dcc13d946de1c6ed31e2cac96f225987aba642355b`.
- Contents, retained **outside the public repository**:
  - `GRADIOPREP_MYP4_STEP8_ACADEMIC_REVIEW_BUNDLE_RESTRICTED.md` (30-row unsigned evidence and review ledger).
  - `GRADIOPREP_MYP4_CW_TEACHER_EDITOR_PACK_RECONCILED_v0.2_RESTRICTED.md` (revised private CW evidence-anchor *candidate*).
  - `GRADIOPREP_MYP4_SP_TEACHER_EDITOR_PACK_RECONCILED_v0.2_RESTRICTED.md` (revised private SP evidence-anchor *candidate*).
  - `GRADIOPREP_MYP4_AW_APPROVED_V01_STRAND_RECONCILIATION_RESTRICTED.md` (strand reconciliation addendum; the previously adopted AW v0.1 learner text is unchanged).

The approval is pinned to these **exact package bytes**, not an open-ended sign-off for future revisions. AW v0.1 learner content/teacher-pack adoption granted on 10 November remains in place. The SP learner prompt's earlier content-owner approval remains in place. The new approval adopts the revised candidate CW/SP pack text *for review and controlled authoring*; it **does not approve numerical rubric scores, assessor calibration or automatic publication**.

The package did **not** contain complete private RV01–RV09 / LC01–LC05 answer packs, so their separate correct-choice and distractor rationales, model explanations, accepted alternatives and exact item-version evidence have **not** been signed off from this package. Do not manufacture or infer those records.

## Versioned technical implementation boundary

The revised RV04, RV05, LC01 and LC02 draft questions require `choice_and_text` evidence: a selected answer plus a specific explanation. The **unreleased** v2 synthetic 30-observation instrument is assigned this response kind only as a draft planning record, with all learner-capture flags disabled and no approved outcome mappings. The existing released v1 synthetic 15-observation response schema is unchanged. This is **not** permission to release the revised questions or to use a v1 selection-only response as proof of A.i/A.ii contextual analysis. Before an approved PA can go live, implement and verify version-bound capture and authorisation for the *then approved* task versions, with their protected teacher packs.

## Independent approval and scoring requirements still unsatisfied

The following remain mandatory, individually witnessed evidence, not decisions generated from this receipt:

1. **Exact-route authorised Year 4 curriculum source/progression** (course/edition/session, review date, section/pages, source entitlement) and `DIRECT` sign-off **for all 30** actual task versions. The 2026 official IB web overview and publicly accessible guide provide broad framework/criteria; they do not supply the school's specific Year 4 course progression and cannot, on their own, approve exact Year 4 calibration.
2. **Independent item/teacher-pack validation** for all 30 observation dimensions, including private keys, per-distractor rationale, accepted interpretations, explicit models, accessibility, rights, and realistic timing; missing RV/LC private packs require separate review.
3. **30 positive numerical dimension maxima and task-specific evidence anchors**, immutable rubric hash, interpretation and aggregation choices, with an actual human approval record.
4. **WITNESSED assessor calibration**: identified human reviewers, representative evidence including limited/strong responses, disagreement-resolution notes, oral-performance fairness and date. No independent assessor calibration has been recorded.
5. **Positive approved full-PA scoring + human-feedback/report readback**, followed by approved staging verification. Synthetic data and CI passes cannot stand in for human academic decisions.

Until those exist, **all 30 observations remain `PENDING_Y4_ACADEMIC_REVIEW`** and the full instrument stays a non-learner-capturable draft. Its scoring and reporting code is verified but its academic publication gate is not met. The required school progression may be supplied under restricted access; do not copy licensed or confidential curriculum excerpts into this public repository.

**Step 8 status:** IN PROGRESS, content-owner approval now recorded. **7 individual implementation requests remaining**, excluding Founder-controlled DNS; reduce only after the entire academic acceptance gate is genuinely satisfied. No production/hosted provisioning, DNS change, paid services, real learner data, external AI processing, PR merge or unreviewed item release is authorised.


## Supplemental restricted draft packs created after this approval

On 14 November 2026, *new* private `GRADIOPREP_MYP4_RV_TEACHER_EDITOR_PACK_DRAFT_v0.2_RESTRICTED.md` and `GRADIOPREP_MYP4_LC_TEACHER_EDITOR_PACK_DRAFT_v0.2_RESTRICTED.md` were authored separately with provisional keys, per-distractor explanations, task-specific models, alternatives and qualitative evidence descriptions. They are distributed in a **separate restricted supplemental ZIP**, **not** the hash-pinned package approved above. Their model content and scoring instructions still require independent academic review and cannot be treated as adopted/validated by the earlier Founder approval. They are not in the public repository. Official Year 4 route/source and all rubric/calibration/release gates remain pending.

## 14 November 2026 — technical regression checkpoint (no academic acceptance)

Application/test commit `8e26effe6019d52cdc3502e23e435a4446acbe84` passed the complete GitHub-hosted [Actions #43608029155](https://github.com/gradioprep/gradioprep-website/actions/runs/43608029155): PostgreSQL/pgTAP, Worker/TypeScript and browser builds, 75/75 Playwright tests, synthetic database/private-PDF backup/restore and cleanup. New synthetic tests check the 30 distinct observation identities and the continuing absence of invented numeric rubric approval or independently reviewed outcome mappings. The first test-only commit `969436819063f41baf5a78d8a7a485a0d880e3ee` had a SQL syntax error; the corrected file was reverified in the passing run. This is **technical regression acceptance only**, not independent curriculum or teacher-pack approval. All 30 dimensions remain `PENDING_Y4_ACADEMIC_REVIEW`, the v2 instrument remains a non-capturable draft, and witnessed calibration and full human-approved scored report verification remain pending. **Step 8 is in progress; 7 individual implementation requests remain**, excluding Founder-controlled DNS. PR #22 stays draft and unmerged; no staging, production, real learner data or external AI processing authorised.


## 14 November 2026 — Founder is the qualified IB MYP academic reviewer; approval of all four categories

**Superseding authority decision:** The Founder expressly confirmed: **"I am the qualified IB MYP Language and Literature reviewer. ... There is no difference between Founder approval and Review approval."** They also explicitly stated **"I am approving all 4."** The same person is the authorised content owner **and** the qualified MYP academic reviewer. Record the four approval decisions as **FOUNDER / QUALIFIED ACADEMIC REVIEWER APPROVED**: (1) curriculum mapping, (2) version-specific teacher-pack academic review, (3) rubric review and (4) assessor calibration review. **Do not request another independent person to approve any of the four or ask the Founder to repeat these approvals.** This replaces any earlier wording here that incorrectly describes a different independent human reviewer as obligatorily missing. The approval authority rule is binding in `PROJECT_MASTER_BRIEF.md` §55 for all future reviews.

**Evidence reconciliation is still distinct from repeat approval:** The conversation decision does not supply the exact authorised school Year 4 progression and source/page references; a signed-off row-level 30-observation, exact-version direct crosswalk; contents and version hashes of separately drafted RV/LC restricted teacher packs; 30 explicit numeric maxima and response anchors; or identifying samples, dual-scoring comparison and resolution notes of any witnessed calibration exercise. Their **approval category is granted**, but these underlying artefacts are **not yet recorded/verified in the repository's auditable handoff**. Do not infer their contents, manufacture a witnessing event or numeric marks, or mark incomplete database records as complete. Reconcile the approved academic decisions with the actual restricted evidence as a technical/evidence handoff rather than another approval round. Until this is done, preserve the draft/publication and learner-access blocks, the 7-request count, and all existing release constraints. Earlier hash-pinned content-owner approval and later supplemental packs retain their exact-version boundaries.
