# Free-First Infrastructure, Subscription and Cost-Control Policy

> **Current execution checkpoint — 8 November 2026 (authoritative active state; prior environment-setup proposals are superseded):** PR #22 remains open, draft and unmerged on `feature/phase-1b-local-auth-api`, based on `docs/phase-1-secure-foundation-spec`. The user's confirmed local WSL checkout was clean at `1caf00e134333f7effcdaf94ac0cb233218e295b`; the remote branch is now two documentation-only commits ahead: `d4ebfb114d874f2bde6dc65af2345f2ab88b30cf` and `37e279d93f0f5ad82ccfa29f51cca0031f1f806b`. Fast-forward once before the next local repository operation; do not reclone or reinstall. Node `v22.23.4`, npm `10.9.9` and the 130-package dependency installation are already complete. **Memory snapshot:** Windows reports 5.94 GiB visible RAM and 1.44 GiB available; WSL reports 2.8 GiB total, 688 MiB used, 1.8 GiB free and 2.1 GiB available, with 1 GiB swap unused; Docker reports about 2.81 GiB and 4 CPUs, with no running containers. **Binding device rule:** do not start Supabase/Docker-based database testing on this Windows/WSL computer, do not register it as a persistent self-hosted runner, and do not change its WSL/Docker resource limits. Run synthetic Supabase tests only inside an ephemeral GitHub-hosted `ubuntu-latest` CI job. Keep the repository private. GitHub Actions run [#42466738041](https://github.com/gradioprep/gradioprep-website/actions/runs/42466738041) failed with no steps reported and no accessible logs; its cause and current Actions-minute usage are unconfirmed, so do not claim that a quota was exhausted. The GitHub check [Workers Builds: gradioprep-website](https://github.com/gradioprep/gradioprep-website/runs/128687968955) passed on commit `37e279d93f0f5ad82ccfa29f51cca0031f1f806b`. All five GitHub spending budgets remain blocked. **Cloudflare:** the private repository is already connected to Workers Builds; automatic builds and previews are enabled, with `main` configured for production, `npm run build` as build command and `npx wrangler deploy` as production deploy command. Build watch-path exclusions are currently empty; configure documentation-only exclusions in a later reviewed settings change. The account build-limit check on 8 November reported that the limit had not been reached. Phase 1C is complete, Phase 1D verified and Phase 1E partial/unverified; its 35- and 47-assertion SQL suites and backup/restore verifier remain pending. Hosted Supabase is not provisioned. Any later isolated cloud test project, branded staging, paid use, real learner data, external processing/email, DNS change, production configuration/deployment or PR merge remains separately gated.
**Version:** 1.1
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

The repository is private. GitHub's standard hosted-runner usage is free for public repositories, while private-repository included compute depends on the account plan; the GitHub Free plan currently advertises 2,000 CI/CD minutes/month. The actual owner plan and consumed/remaining minutes were not confirmed during this review. Do not infer quota exhaustion from the recent failed jobs: the latest exact-head run #42466738041 reported no job steps and had unavailable logs. Determine the actual reason from GitHub's account usage/billing page and job metadata before changing the runner strategy.

Keep all five GitHub spending budgets blocked. Do not increase budgets, enable overages, create a paid plan or make the repository public. The current database workflow uses GitHub-hosted `ubuntu-latest`; its ephemeral Supabase stack runs on GitHub infrastructure, not the user's PC. A local WSL runner is rejected because of device memory and persistent-runner security risk.

Reduce unnecessary minutes without weakening tests:
- Ignore documentation-only/Markdown changes in the heavyweight workflow.
- Remove PR `edited` from the full verification trigger so title/body edits do not rerun the database/browser suite.
- Keep relevant migration, SQL test, Worker, application, browser, dependency, workflow and configuration changes covered.
- Review the separate build workflow for duplicate builds/browser runs.

### 7.2 Cloudflare Workers Builds

Read-only inspection on 8 November 2026 confirmed the existing Cloudflare Worker `gradioprep-website` is linked to private repository `gradioprep/gradioprep-website`. Automatic builds and Previews are enabled; production branch is `main`; production commands are `npm run build` / `npx wrangler deploy`; Preview commands are `npm run build` / `npx wrangler preview`. Production and Preview watch paths both currently include all files and exclude nothing. The build-list query returned no records, so the current check does not verify a recent successful build. The account build-limit endpoint reported `has_reached_build_minutes_limit=false` with refresh on 30 November 2026.

Cloudflare's published Workers Builds Free allowance is 3,000 minutes/month, one concurrent build and a 20-minute timeout. Retain the existing connection as the app build/deployment path. The next reviewed configuration change should exclude docs-only paths (for example, `docs/**`, Markdown files and root `README.md`) from both production and Preview builds while continuing to watch application, Worker, migration, test and deployment-configuration files. Do not change the production branch, deploy command, domain, DNS, secrets, bindings or production settings under this documentation decision.

### 7.3 Repository visibility

Keep the repository private. Public visibility would expose the whole Git history, branches, pull requests, internal product roadmap, diagnostic/assessment specifications, security architecture and Actions logs/artifacts. The absence of hard-coded API keys is not a sufficient disclosure assessment. Consider public/open-source status only after an explicit intellectual-property decision and a complete history, branch, PR, log, artifact and secret scan. Public visibility is not the selected CI-cost workaround.

## 8. Conditional Supabase Free cloud project

A separate Supabase Free project is a possible later environment for hosted end-to-end authentication/API/Storage testing or the mandatory branded staging journey. It is not required for the current database/RLS CI suites, which can use disposable Supabase inside GitHub-hosted CI. Current Supabase documentation provides up to two active Free projects per eligible account; Free projects may pause after a week of insufficient database activity. Account-level availability must be checked before assuming a project can be created.

No cloud Supabase project is provisioned or authorised now. Even a Free project requires separate explicit approval, isolated synthetic data, restricted credentials, no production linkage and reviewed reset, backup/restore and deletion controls. Never use a free test project for real learner data or silently connect it to production.

