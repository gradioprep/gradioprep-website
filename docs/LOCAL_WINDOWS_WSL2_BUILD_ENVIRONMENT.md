# Local Windows WSL2 Build and CI Recovery Guide

**Status date:** 7 November 2026  
**Repository:** private `gradioprep/gradioprep-website`, PR #22  
**Purpose:** use a trusted repository-scoped Linux runner for local Supabase verification without consuming GitHub-hosted Actions job minutes.

## 1. Current setup checkpoint

WSL2 and Ubuntu are installed. The Linux account is `gradioprep`. Docker Desktop/WSL integration, a private repository checkout inside the Linux filesystem, a separately reviewed workflow change and a repository-scoped self-hosted runner remain pending.

The current workflow is `.github/workflows/phase1b-verification.yml` and still targets `runs-on: ubuntu-latest`. **Registering a self-hosted runner alone will not redirect the workflow.** The workflow change is a separate security-sensitive implementation task and is not part of this documentation-only reconciliation.

## 2. Verify the WSL2 Ubuntu installation

Open Windows PowerShell and run:

```powershell
wsl --list --verbose
```

Confirm Ubuntu is listed and the VERSION column is `2`. If it is version 1, use the exact distribution name shown:

```powershell
wsl --set-version Ubuntu 2
```

Use `wsl --update` only if Windows reports that the WSL kernel needs updating. Open Ubuntu and confirm the Linux account:

```bash
whoami
pwd
```

Expected `whoami` output: `gradioprep`. Do not disclose passwords or authentication tokens in screenshots or terminal transcripts.

## 3. Install Docker Desktop and connect it to Ubuntu

1. Install Docker Desktop for Windows using the [official Docker Desktop installation guide](https://docs.docker.com/desktop/setup/install/windows-install/).
2. In Docker Desktop, open **Settings → General** and enable **Use the WSL 2 based engine**.
3. Open **Settings → Resources → WSL Integration** and enable integration for the installed Ubuntu distribution.
4. Apply the settings, let Docker Desktop restart and keep it running while local Supabase is used.
5. In Ubuntu, run:

```bash
docker version
docker compose version
docker info
```

Both client and server details should appear in `docker version`; `docker info` must complete without a daemon connection error. If not, check that Docker Desktop is running, the WSL2 engine is enabled and Ubuntu integration is on; restart Docker Desktop and reopen Ubuntu before retrying.

When using Docker Desktop's WSL integration, **do not install a second Docker Engine inside Ubuntu**. Supabase should use the Docker daemon exposed by Docker Desktop.

## 4. Clone the private repository inside Linux

Keep the checkout on the Linux filesystem, for example under `/home/gradioprep`, rather than under `/mnt/c`. This avoids Windows-mounted filesystem performance and permission differences and keeps runner work separate from personal Windows files.

First authenticate to GitHub using an approved secure method, such as GitHub CLI interactive authentication or an SSH key. Never put a personal access token in a clone URL, script, shell history, terminal screenshot or committed file.

Then in Ubuntu:

```bash
mkdir -p ~/src
cd ~/src
git clone https://github.com/gradioprep/gradioprep-website.git
cd gradioprep-website
git switch feature/phase-1b-local-auth-api
git pull --ff-only origin feature/phase-1b-local-auth-api
git status --short --branch
git rev-parse HEAD
```

Confirm that the branch is `feature/phase-1b-local-auth-api` and compare the commit with the live PR #22 head before running tests. Keep ignored local environment files and generated backup artefacts out of Git.

## 5. Register a repository-scoped self-hosted runner

Do this only after Docker/repository setup is ready and the workflow trust review is complete.

1. Open the private repository on GitHub: **Settings → Actions → Runners → New self-hosted runner**.
2. Select **Linux** and the architecture shown for the Ubuntu installation (normally x64 on a standard Windows PC).
3. Follow the current download/configuration commands shown by GitHub for that repository. Runner versions and one-time configuration tokens change; do not use stale copied commands.
4. Download and configure the runner in a dedicated directory outside the checkout, such as `/home/gradioprep/actions-runner`.
5. Retain the default labels `self-hosted`, `linux` and `x64`; add a project label such as `gradioprep-wsl2`.
6. Configure and run it as the ordinary Linux user `gradioprep`, never as root. Start it interactively for the initial validation. Consider service installation only after the security review and lifecycle are settled.
7. Treat GitHub's one-time runner registration token as a short-lived credential: use it immediately; never save, share, screenshot or commit it.

Register at the **repository level only**, not account-wide or organization-wide. Keep the runner installation and work directory outside the code checkout and away from Windows personal folders.

## 6. Security requirements before the workflow targets this runner

A self-hosted runner is a persistent machine, not a fresh virtual machine for every job. Untrusted workflow code can compromise it and access other files, services or credentials available to the host. It must therefore be tightly restricted.

- Keep the repository private and limit write access to trusted maintainers. Never execute fork or untrusted pull-request code on this runner.
- Restrict triggers to trusted pushes and explicitly trusted same-repository PR activity; review every trigger and job-level condition. Never use `pull_request_target` to check out or execute untrusted PR code with privileged access.
- Only after runner registration, separately change the workflow's runner label to an exact set such as `[self-hosted, linux, x64, gradioprep-wsl2]`. The current `ubuntu-latest` setting must be changed; runner registration alone does not route jobs.
- Use least-privilege `GITHUB_TOKEN` permissions. The local SQL/build/test job should not have deployment permissions or broad write access.
- Do not store Cloudflare API tokens, R2 credentials, hosted Supabase credentials, production secrets or real learner data on this persistent runner. Keep any secret-bearing Preview/deployment job isolated from persistent test execution and separately permissioned.
- Keep `.dev.vars`, `.env.local`, database dumps, PDF fixtures and backup artefacts out of Git. Use synthetic test identities only and clean local credentials and disposable test data after each run.
- Do not mount personal Windows folders into the runner workspace. If untrusted code runs or host compromise is suspected, stop and remove the runner registration, rebuild WSL from a clean state, and rotate credentials the machine could access.

Official guidance: [add a self-hosted runner](https://docs.github.com/en/actions/how-tos/manage-runners/self-hosted-runners/add-runners) and [secure use of GitHub Actions](https://docs.github.com/en/actions/reference/security/secure-use).

## 7. Avoid additional GitHub-hosted Actions minutes

GitHub documents that self-hosted runner job execution does not incur GitHub-hosted Actions minutes. Artifact/cache storage may still consume quotas or be billed. The Windows computer, electricity and internet are also local costs, so this is not a guarantee of zero total cost.

**All five GitHub spending budgets remain blocked.** Do not unblock them, enable paid usage, increase spend caps or permit paid overage.

References: [GitHub Actions billing concepts](https://docs.github.com/en/actions/concepts/billing-and-usage) and [viewing job execution time](https://docs.github.com/en/actions/how-tos/monitor-workflows/view-job-execution-time).

## 8. Local synthetic verification sequence

Only after Docker Desktop is integrated and the correct Linux checkout exists:

```bash
npm install --no-audit --no-fund
npm run supabase:start
npm run supabase:env
npx supabase db reset --local
npx supabase test db --local
npm run build
npm run test:e2e
npm run phase1e:backup:verify
npm run supabase:stop
```

The Supabase environment script writes ignored local-only files. Do not print or upload secret values. Confirm cleanup even after a test failure; stop the local stack and remove local-only credentials using the repository's cleanup procedure.

The current Phase 1E test plans are:

| Test file | Declared pgTAP plan | Status |
|---|---:|---|
| `supabase/tests/account_deletion_ledger.test.sql` | 35 assertions | Not yet run |
| `supabase/tests/account_closure_retention.test.sql` | 47 assertions | Not yet run |

Capture actual test output before reporting pass/fail. A declared assertion count is not a test result.

The backup/restore verifier is also unverified until it completes. It is restricted to local Supabase and synthetic `.invalid` email fixtures. Its test artefact is currently unencrypted and explicitly local-only; never use it for real learner data or copy it to R2. It does not establish a numeric RPO/RTO.

## 9. Exact current blocker and next steps

Exact-head Actions run [#42208654326](https://github.com/gradioprep/gradioprep-website/actions/runs/42208654326), attempt 4, failed before runner assignment. Job `127868964485` reports runner ID 0, an empty runner name and no steps; no SQL test or other workflow step executed. This is a runner-assignment failure, not a failed SQL assertion.

1. Finish Docker Desktop WSL2 integration and confirm `docker info` works in Ubuntu.
2. Clone/update the private repository inside `/home/gradioprep` and verify the branch/head.
3. Complete a separate workflow security review and change `runs-on` only when the trusted repository-scoped runner is ready.
4. Register/start the repository-scoped runner under the restrictions above.
5. Run the Phase 1E SQL tests and local backup/restore round-trip; repair actual failures in a later implementation change, then rerun exact-head verification.
6. Proceed to Phase 1F only after Phase 1E acceptance passes.

Phase 1C is complete; Phase 1D remains verified at its recorded checkpoint; Phase 1E is partial and unverified. No hosted Supabase provisioning, R2, real learner data, external processing, paid usage, Preview/production deployment, DNS/custom-domain change or PR merge is authorised.
