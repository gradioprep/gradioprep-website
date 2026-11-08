# Free-First Infrastructure, Subscription and Cost-Control Policy

> **Current execution checkpoint — 8 November 2026:** PR #22 remains open, draft and unmerged on `feature/phase-1b-local-auth-api`, based on `docs/phase-1-secure-foundation-spec`. GitHub confirms the repository is **public**. The last user-reported clean WSL checkout is `1caf00e134333f7effcdaf94ac0cb233218e295b`; this session cannot inspect the local Windows/WSL files, so local cleanliness and synchronization are unverified. The remote branch has advanced since that report. Before further local work, inspect `git status --short --branch`, then fast-forward with `git pull --ff-only origin feature/phase-1b-local-auth-api` only if the working tree is clean; do not reclone or reinstall. Node 22.23.4, npm 10.9.9 and the 130-package install were last reported complete. **Do not start Supabase/Docker locally or register a self-hosted runner.** The heavy verification workflow now runs once on pushes to PR #22's dedicated branch `feature/phase-1b-local-auth-api` by the repository owner `gradioprep`; it ignores `docs/**` and Markdown-only changes and cancels superseded runs for the same branch. There is no parallel `pull_request` trigger or PR-description event. Commit `dc13c80` implements this single-trigger design. Standard `ubuntu-latest` and all database, SQL, build, browser and Phase 1E backup/restore steps remain. A passing post-change CI result is not yet confirmed. Previous run [#42466941118](https://github.com/gradioprep/gradioprep-website/actions/runs/42466941118) failed in about two seconds with zero job steps and unavailable logs; it proves neither a test failure nor quota exhaustion. Phase 1C is complete, Phase 1D verified, Phase 1E partial/unverified, and Phase 1F remains gated on Phase 1E acceptance. Hosted CI retry attempt 2 [#42466941118](https://github.com/gradioprep/gradioprep-website/actions/runs/42466941118) executed the 35-assertion deletion-ledger suite successfully. The 47-assertion closure/retention suite stopped at test line 82 because the fixture's separate clock readings violated the exact SLA constraint by one microsecond; its fixture was corrected in test-only commit `26fbea0`. The other 15 SQL files passed in that attempt. Current full run [#42473310987](https://github.com/gradioprep/gradioprep-website/actions/runs/42473310987) is running on the corrected branch head. The 47 assertions still need a successful run, and the browser/PDF + database backup/restore round-trip remain unverified. Cloudflare Workers Builds remains connected, but its watch-path exclusions have not been changed. No hosted Supabase, paid usage, DNS/custom-domain change, production deployment, real learner data or merge is authorised. All five GitHub spending budgets were last recorded as blocked.
**Version:** 1.2
**Decision date:** 3 November 2026  
**Last updated:** 8 November 2026
**Status:** Founder-approved operating and budget policy.  
**Authority:** This policy records the Founder's direction that free resources are the default and paid services are used only when demonstrably unavoidable. It is binding on the Master Project Brief, Phase 0 decision register, Phase 1 specification, Phase 1A execution plan, Data Model, flagship feature plan and Preview/release process.

## 1. Binding budget objective

1. **Free-first is the core operating model.** Use suitable free plans, free quotas, open-source software and local development tools by default. Do not choose a paid service merely because it is more convenient or has a larger quota.
2. **Twelve-month target:** from 3 November 2026 through 2 November 2027, target **US$0 in recurring infrastructure subscriptions and paid API usage**. This excludes the domain already purchased and the user's existing computer/internet arrangements. This is a budget target, not a promise that every free tier can satisfy every production reliability requirement.
3. **100-subscriber review point:** when GradiPrep reaches 100 or more active subscribers, review service capacity, reliability, support, recovery and actual usage. This is a review trigger, **not an automatic instruction to upgrade**. Continue using free services where they still meet requirements.
4. **Unavoidable exception before 100 subscribers:** a paid service may be proposed earlier only where documented tests show that no suitable free/open-source/local option can satisfy an essential security, privacy, data-residency, recovery, availability, capacity or product requirement. Explain the failed free alternatives and the consequences of not paying.
5. **Approval before charges:** before any paid subscription, paid API call, paid add-on, usage overage, billing-method activation for a service, spend-cap removal or automatic upgrade, provide the exact provider, reason, alternatives, current price, estimated monthly recurring cost, variable usage formula, taxes/currency caveats and any one-off charges. Obtain the Founder's explicit approval for that specific spend. No approval is implied by a provider being listed in the approved architecture.
6. Never enable automatic upgrades, uncontrolled paid overage, automatic spend-cap increases or paid fallback routing. Configure budgets/spend caps and service-level quota stops wherever the provider supports them. If the free quota is exhausted, fail safely and use the approved manual fallback; do not silently incur a charge.

## 2. Implementation approval versus provisioning and spending

The Founder has approved the phased implementation plan and the Phase 0 architecture/provider choices. Work that stays within that approved scope and sequence is authorised to proceed through implementation, draft PRs, automated checks and public synthetic-data Preview verification; do not repeatedly ask the Founder to re-approve an implementation step already included in the approved plan.

The Founder has also explicitly approved Phase 1B local Supabase coding and verification using fictional/synthetic data only. That does not authorise hosted resource provisioning, paid usage, real learner records, sending learner content to external processors, PR merge, production deployment, DNS changes or public launch. Those actions remain separate gates because they create billing, privacy, security or release consequences.

A review of a completed implementation checkpoint is evidence-based milestone acceptance, not a request to re-authorise the approved plan. Ask for a new decision only when the proposed work changes the approved scope/provider/region/data handling, requires a charge or new hosted resource, begins real-data processing, or reaches a separately gated merge/production/release action.

## 3. Approved providers: free-first assessment and known limits

All figures below are a dated reference snapshot checked on 3 November 2026. They are not a purchase authorisation, invoice quote or guarantee that the same quotas will remain available. Recheck official provider terms, exact region, taxes, account-level limits and current pricing immediately before activation.

| Service and approved role | Free-first option and important limits | Paid option / cost exposure | Operating rule |
|---|---|---|---|
| **Supabase** — single Auth, PostgreSQL and primary private Storage project in Mumbai (`ap-south-1`) | Free: US$0; 500 MB database, 1 GB file storage, 50,000 monthly active users, 5 GB egress plus 5 GB cached egress; projects may pause after 7 days of low activity; no automatic downloadable database backups. Manual logical database exports using Supabase CLI are available. | Pro starts at US$25/month for the first project; usage, compute, storage and egress may add charges. Daily database backups are retained for 7 days on Pro, but do not include Storage API objects. PITR is a separate paid add-on; the published 7-day option is approximately US$100/month and requires at least Small compute. | Free is the starting candidate, not an unconditional approval for live data. Pro is not mandatory solely because it is named in an older document. Real learner records remain blocked until availability, capacity, backup/restore and privacy gates pass on the selected plan. If Free cannot meet them, compare a tested free approach, a weaker explicitly accepted recovery commitment, and the exact paid option before deciding. |
| **Cloudflare Workers** — current website host and lightweight API | Free: 100,000 Worker requests/day and 10 ms CPU per HTTP invocation; static asset requests are free and unlimited. | Workers Paid minimum US$5/month/account; includes 10 million requests and 30 million CPU milliseconds/month; usage above those allowances is billed. | Keep the current application on Free while measured traffic and CPU stay within limits. Static assets remain the preferred delivery path. No upgrade merely for convenience. |
| **Cloudflare Workers Builds** — Git-connected application build/deploy | Free allowance: 3,000 build minutes/month, one concurrent build and 20-minute build timeout. The existing private GitHub repository connection has automatic builds and Previews enabled. Account limit check on 8 November 2026 reported the limit was not reached; actual recent build history/usage was not confirmed. | Paid build allowance and overage are subject to current Cloudflare terms; do not upgrade or enable paid overage without a separate cost decision. | Keep the existing integration. Configure documentation-only watch-path exclusions for production and Preview in a later reviewed settings change; retain app, Worker, migration, test and config paths. |
| **Cloudflare R2** — secondary encrypted file-object backup only | Standard storage: 10 GB-month, 1 million Class A and 10 million Class B operations/month; internet egress is free. | Standard storage above the allowance is US$0.015/GB-month; operation overages are separately charged. | Use only as the already-selected secondary backup candidate, not primary app storage or a second database. Its location hint is best-effort and does not guarantee India residency. No real learner objects until transfer, residency, key custody and privacy gates pass. |
| **Azure Document Intelligence Read** — scanned-page OCR | F0: up to 500 pages/month; 4 MB max document size, 2-page analysis limit and 1 request/second. The approved 10 MB/10-page upload cap is a product cap; if F0 is used, process eligible page images individually under the provider limit. | S0 is usage-priced per page; exact Central India price and tax must be quoted before activation. | Use digital text extraction through PDF.js first. Apply OCR only to pages that need it. Hard-stop at the free quota and fall back to teacher review of the original PDF. No automatic S0 upgrade. |
| **Cloudflare Workers AI** — ten teacher-only feedback suggestions | 10,000 Neurons/day free allocation. If the daily allowance is exhausted, do not assume further inference is free. | To exceed the free allocation, Workers Paid is required; the published AI rate is US$0.011 per 1,000 Neurons above the allowance, in addition to the Workers Paid plan minimum. | Use only after synthetic quality evaluation and external-processing approval. At quota exhaustion, use manual teacher feedback. Never auto-publish AI text. |
| **GitHub Actions** — targeted security, database and browser tests | Retain ephemeral `ubuntu-latest` hosted jobs for synthetic Supabase/RLS, API, build and Playwright checks. GitHub-hosted included minutes for private repositories depend on the owner account's plan. The user's current account plan and remaining included minutes have not been verified. | Usage beyond included minutes may be chargeable; no extra budget is approved. Latest failure without job steps/logs does not prove quota exhaustion. | Keep all five GitHub spending budgets blocked. Do not make the repository public or use a persistent WSL runner just to avoid minutes. Trigger only for relevant code/config/test changes. |
| **Key management** — encryption key custody for backups | No vendor or paid key-management product has been selected. Evaluate platform-supported or suitable free options, operational recovery and key separation first. | AWS KMS was only a candidate: a customer-managed key is listed at US$1/key/month, plus applicable request charges. | AWS KMS is not approved or required by this policy. Do not provision it unless a specific security design demonstrates the need and the Founder approves the exact cost. |
| **Email delivery and other optional APIs** | No separate paid email provider or other paid API is selected. Assess included provider capability and suitable free options first. | Any provider may have recurring or metered charges. | No new provider or charge without a cost comparison and explicit approval. |

The indicative monthly base prices above are not additive requirements. In particular, Supabase Pro, Workers Paid, PITR, AWS KMS, Azure S0 and paid email are not a bundle and must not be activated by default.

## 4. Reliability, capacity and safe degradation

Free-tier limits do not constitute an uptime SLA, production backup guarantee or unlimited service. “Free-first” must not be used to waive security or data-protection requirements.

Before accepting real learner records or PDF submissions:

- Measure expected database growth, file size, monthly submission volume, egress, OCR pages, AI usage, concurrency and CI minutes against the actual current free limits.
- Implement capacity warnings before quotas are reached and enforce hard limits before any charge can occur.
- Test database export/restore and original-file backup/restore as separate recovery paths. Supabase database backups do not include Storage API file objects.
- On Supabase Free, design and test scheduled/manual CLI database exports and a separate reviewed backup for file objects; define operator, encryption, access, retention, restore and deletion. A successful database dump alone is not a full restore.
- Treat Supabase Free inactivity pausing as an availability risk. Do not attempt to bypass provider policy with artificial traffic. Verify whether expected legitimate activity reliably avoids pausing; otherwise do not claim continuous availability.
- Keep accepted original PDFs safe when extraction/OCR/AI is unavailable or quota is reached. Teacher review of the original is the fallback. Do not destroy an accepted submission or silently charge for processing.
- If these safeguards cannot meet the Founder-approved service and recovery requirements at zero cost, keep real-data acceptance blocked until the Founder chooses between a revised tested service commitment and the exact unavoidable paid option.

The numeric RTO/RPO values in the Phase 1A document are proposals only. They are not Founder-approved service promises and must not be used as a hidden reason to buy PITR, KMS or another paid product.

## 5. Approval gates that remain separate

The approved implementation plan does not waive the following:
- Hosted Supabase or other hosted infrastructure provisioning, including a free-tier resource, where the project records require a provisioning decision.
- Paid services, subscriptions, paid usage, billing changes or overages.
- Real learner data, live authentication accounts, learner PDFs or production records.
- External processing by OCR, AI or backup providers; exact regional, privacy, contract, guardian-consent and deletion reviews remain mandatory.
- Cross-region or cross-border transfer of learner data or backup objects.
- PR merge, production deployment, DNS/custom-domain changes and public launch.

These are not repeated approvals of the plan. They are approvals for materially different actions with separate security, privacy, billing or release effects.

## 6. Review and change control

Review provider terms and usage at least quarterly, before each new hosted integration, before the first real-data pilot and when subscriber count reaches 100. Also review earlier if any free quota approaches its hard limit or reliability/recovery testing fails. Update this policy and every dependent source-of-truth record together when a provider, price, quota or decision changes.

No assistant, developer or automation may infer spending authority from this plan, a listed vendor, an estimate, a quota warning or the 100-subscriber review point.

## Official references checked 3 November 2026

- Supabase pricing: https://supabase.com/pricing
- Supabase billing and free-plan pausing: https://supabase.com/docs/guides/platform/billing-on-supabase and https://supabase.com/kb/faqs/platform/free-project-pausing
- Supabase Free-plan manual backups: https://supabase.com/kb/faqs/platform/free-plan-backups
- Supabase database backups and Storage API exclusion: https://supabase.com/docs/guides/platform/backups
- Supabase PITR pricing and compute requirement: https://supabase.com/docs/guides/platform/manage-your-usage/point-in-time-recovery
- Cloudflare Workers limits and pricing: https://developers.cloudflare.com/workers/platform/limits/ and https://developers.cloudflare.com/workers/platform/pricing/
- Cloudflare R2 pricing: https://developers.cloudflare.com/r2/pricing/
- Cloudflare Workers AI pricing: https://developers.cloudflare.com/workers-ai/platform/pricing/
- Azure Document Intelligence limits: https://learn.microsoft.com/en-us/azure/ai-services/document-intelligence/service-limits?view=doc-intel-4.0.0
- Azure Document Intelligence pricing: https://azure.microsoft.com/en-us/pricing/details/document-intelligence/
- GitHub Actions included usage and billing: https://docs.github.com/en/billing/reference/product-usage-included and https://docs.github.com/en/billing/concepts/product-billing/github-actions
- Cloudflare Workers Builds: https://developers.cloudflare.com/workers/ci-cd/builds/ and path filtering: https://developers.cloudflare.com/workers/ci-cd/builds/configuration/.
- AWS KMS pricing (candidate reference only): https://aws.amazon.com/kms/pricing/

**No provisioning or spending action is authorised by this policy itself.**

## Approved cost and feature additions — 6 November 2026

Build submission search/filter using existing PostgreSQL, measured indexes and existing Worker APIs. No paid search service, second database or separate application. Use bounded query parameters, permission-scoped server filtering and stable pagination; add indexes only when synthetic query plans/load tests justify them.

Develop catalogue, credit formula, ledger and course entitlements locally with synthetic data. Store INR prices in integer paise; keep prices/campaigns versioned and server-authoritative. No payment provider, paid subscription, live payment or hosted resource is activated by this documentation amendment. A no-monthly-fee payment provider may still charge transaction fees.

Approved catalogue: free Diagnostic + complete report (₹999 stated value); standalone Remedial Course ₹1,999; 2 credits ₹1,500; 5 credits ₹3,750; Gold 10 credits ₹7,500; Platinum 20 credits ₹14,999. Only Diwali offers: free Diagnostic/report and Platinum 20 credits plus Remedial Course for ₹7,999. No other campaign discount or bundle. Full tariff is in the Grading Credit and Remedial Access Policy.


## 7. Project-specific CI, build and cost-control decision — 8 November 2026

### 7.1 GitHub Actions

The repository is publicly visible. The current account plan and remaining Actions-minute balance have not been independently verified in this review. The previous exact-head run #42466941118 failed after starting a job with zero reported steps; its logs were unavailable. This is not evidence of an SQL/browser test failure or minute exhaustion. Do not infer a quota cause from that run.

Keep all five GitHub spending budgets blocked. Do not increase budgets, enable overages, upgrade the plan or select larger/paid runners. The database workflow uses standard GitHub-hosted `ubuntu-latest`; its ephemeral Supabase stack runs on GitHub infrastructure, not the user's PC. A local WSL runner is rejected because of device memory and persistent-runner security risk. Repository visibility is already public and is not approval for paid CI or disclosure of credentials/data.

The workflow optimization is implemented in commit `dc13c80`:
- The full synthetic database/security/browser/backup suite runs once on pushes to PR #22's dedicated head branch, by the repository owner.
- `docs/**` and Markdown paths are ignored; PR description edits do not run it because there is no `pull_request` trigger.
- A branch-scoped concurrency group cancels an older run when a newer revision is pushed.
- Standard `ubuntu-latest`, dependency installation, migrations and complete SQL coverage, Worker build, Playwright, backup/restore verifier and cleanup remain.
- The separate `build.yml` ignores documentation-only paths, cancels superseded runs and remains skipped for PR #22's stacked docs base. A successful run of the updated workflow has not yet been confirmed.

### 7.2 Cloudflare Workers Builds

Read-only inspection on 8 November 2026 confirmed the existing Cloudflare Worker `gradioprep-website` is linked to public repository `gradioprep/gradioprep-website`. Automatic builds and Previews are enabled; production branch is `main`; production commands are `npm run build` / `npx wrangler deploy`; Preview commands are `npm run build` / `npx wrangler preview`. Production and Preview watch paths both currently include all files and exclude nothing. The build-list query returned no records, so the current check does not verify a recent successful build. The account build-limit endpoint reported `has_reached_build_minutes_limit=false` with refresh on 30 November 2026.

Cloudflare's published Workers Builds Free allowance is 3,000 minutes/month, one concurrent build and a 20-minute timeout. Retain the existing connection as the app build/deployment path. The next reviewed configuration change should exclude docs-only paths (for example, `docs/**`, Markdown files and root `README.md`) from both production and Preview builds while continuing to watch application, Worker, migration, test and deployment-configuration files. Do not change the production branch, deploy command, domain, DNS, secrets, bindings or production settings under this documentation decision.

### 7.3 Repository visibility

The repository is already public. Its full history, branches, pull requests, product roadmap, diagnostic/assessment specifications, security architecture and Actions logs/artifacts may be publicly accessible. Do not commit credentials, API keys, passwords, real learner records or confidential teacher materials. This status entry does not claim every historical commit, branch, log and artifact has been exhaustively scanned. Any future visibility change requires a separate explicit owner decision.

## 8. Conditional Supabase Free cloud project

A separate Supabase Free project is a possible later environment for hosted end-to-end authentication/API/Storage testing or the mandatory branded staging journey. It is not required for the current database/RLS CI suites, which can use disposable Supabase inside GitHub-hosted CI. Current Supabase documentation provides up to two active Free projects per eligible account; Free projects may pause after a week of insufficient database activity. Account-level availability must be checked before assuming a project can be created.

No cloud Supabase project is provisioned or authorised now. Even a Free project requires separate explicit approval, isolated synthetic data, restricted credentials, no production linkage and reviewed reset, backup/restore and deletion controls. Never use a free test project for real learner data or silently connect it to production.

