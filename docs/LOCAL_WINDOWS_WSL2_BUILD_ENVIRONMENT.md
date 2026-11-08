# Local Windows WSL2 Build and CI Recovery Guide

**Status date:** 8 November 2026  
**Repository:** private `gradioprep/gradioprep-website`, PR #22  
**Purpose:** use a trusted repository-scoped Linux runner for local Supabase verification without consuming GitHub-hosted Actions job minutes.

## 1. Current setup checkpoint

**Verified on 8 November 2026:** WSL2 Ubuntu runs as Linux user gradioprep; Docker Desktop integration, Docker Engine, Compose, Git, GitHub CLI authentication and private repository access are verified. The PC has 8 GB DDR4 RAM. A previous Docker/Ubuntu reading reported approximately 2.8 GiB total memory and 2.1 GiB available; this is not a current snapshot.

**Node and dependency setup complete:** Node v22.23.4 and npm 10.9.9 both resolve inside /home/gradioprep/.nvm/versions/node/v22.23.4/bin/. npm install --no-audit --no-fund succeeded and added 130 packages. node_modules/ is ignored by Git. The workflow explicitly says package-lock.json is intentionally not committed; the user's post-fast-forward working-tree status is clean, so no generated lockfile remains in the working tree.

**Repository synchronisation complete:** the user ran git pull --ff-only origin feature/phase-1b-local-auth-api. Git fast-forwarded from acfde1e9572d5149e8d4a857bfb32032db1dc45a to 39b34c9727b15b2e6a1f514d87e1676a093b217f, changing only README and four Markdown documentation files. git rev-parse HEAD and gh pr view 22 --json headRefOid both returned 39b34c9727b15b2e6a1f514d87e1676a093b217f. git status --short --branch showed only the branch/tracking line, with no modified or untracked files.

**Supabase reduced-service configuration:** the checked-in workflow starts the local stack while excluding studio, logflare, vector, edge-runtime, postgres-meta, realtime and supavisor. This retains the required database plus Auth, Storage API, imgproxy, Kong, Mailpit and PostgREST. Supabase's CLI reference recommends at least 7 GB RAM to start all services and supports excluding unneeded containers. It does not publish a minimum-memory figure for this exact reduced combination. See the Supabase CLI start reference (https://supabase.com/docs/reference/cli/introduction) and local-development guide (https://supabase.com/docs/guides/local-development).

**Resource decision: HOLD — do not start Supabase yet.** The machine has 8 GB physical RAM; the prior Docker/Ubuntu report of 2.8 GiB total / 2.1 GiB available must be refreshed. WSL2 uses dynamic memory allocation under Docker Desktop, so capture current Windows available physical RAM, WSL free -h, Docker daemon MemTotal, and currently running container names. Do not edit .wslconfig, Docker memory/CPU/swap limits or start any containers during this assessment.

**Phase status:** Phase 1C complete; Phase 1D verified; Phase 1E partial/unverified. Its 35- and 47-assertion SQL suites and local backup/restore verifier have not passed. Latest exact-head Actions run #42462915084 failed with no job steps reported and logs unavailable; no SQL/build/browser test failure is established.

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
5. This was verified on 8 November 2026: Ubuntu integration is enabled and Docker Desktop appears in the Windows taskbar. Ubuntu reports Docker Desktop 4.98.0 / Engine 29.9.2 and Compose 5.6.1. The commands `docker version`, `docker compose version` and `docker info` completed successfully with both Client and Server details.

Both client and server details should appear in `docker version`; `docker info` must complete without a daemon connection error. If not, check that Docker Desktop is running, the WSL2 engine is enabled and Ubuntu integration is on; restart Docker Desktop and reopen Ubuntu before retrying.

When using Docker Desktop's WSL integration, **do not install a second Docker Engine inside Ubuntu**. Supabase should use the Docker daemon exposed by Docker Desktop.

## 4. Clone the private repository inside Linux

Keep the checkout on the Linux filesystem, not under `/mnt/c`. This avoids Windows-mounted filesystem performance and permission differences and keeps runner work separate from personal Windows files.

**Clone completed and verified (8 November 2026):** GitHub CLI authentication was confirmed for account `gradioprep`; the private repository was cloned into `/home/gradioprep/src/gradioprep-website`. The local branch is `feature/phase-1b-local-auth-api`, tracking the same origin branch. These checks returned the same SHA for local HEAD, remote branch and live PR #22 head: `2a582c42c071a7dda85d197672e9255398e55140`. PR #22 is open, draft and unmerged. Never put a personal access token in a clone URL, script, shell history, terminal screenshot or committed file.

The clone and head checks were (recorded at the original clone point):

```bash
gh auth setup-git
mkdir -p ~/src
cd ~/src
git clone --branch feature/phase-1b-local-auth-api --single-branch https://github.com/gradioprep/gradioprep-website.git
cd gradioprep-website
git status --short --branch
git rev-parse HEAD
git ls-remote origin refs/heads/feature/phase-1b-local-auth-api
gh pr view 22 --repo gradioprep/gradioprep-website --json number,state,isDraft,headRefName,headRefOid,baseRefName
```

**Node 22 setup is complete.** Do not repeat installation. Continue with the current checkout synchronisation and dependency-verification checkpoint in Section 1.

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

Node 22 and npm dependency installation are already verified on the synchronised checkout. The following commands are version/path verification only; do not repeat installation unnecessarily:

```bash
node --version
npm --version
command -v node
command -v npm
```

Confirm `node --version` reports a v22 release and `command -v node` points inside `/home/gradioprep/.nvm/`. Do not continue if WSL is still resolving Node/npm from a Windows-mounted path.

**Do not start Supabase yet.** The PC has 8 GB RAM, and Docker/Ubuntu reported about 2.8 GiB total memory. Review the reduced-service footprint and safe memory plan first. After that gate is passed, the intended local synthetic-only sequence is:

```bash
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

## 9. Current next step — collect memory readings (no startup)

Node installation, dependency installation and Git synchronisation are complete. Do not repeat them.

The current task is read-only resource assessment. Run the PowerShell readings on Windows:

```powershell
Get-CimInstance Win32_OperatingSystem | Select-Object @{Name='TotalRAM_GiB';Expression={[math]::Round($_.TotalVisibleMemorySize/1MB,2)}}, @{Name='AvailableRAM_GiB';Expression={[math]::Round($_.FreePhysicalMemory/1MB,2)}}
```

Then in Ubuntu/WSL:

```bash
free -h
docker info --format 'Docker daemon memory total: {{.MemTotal}} bytes; CPUs: {{.NCPU}}'
docker ps --format 'table {{.Names}}\t{{.Status}}'
```

These commands only inspect memory and running containers. Do not run supabase start, do not change .wslconfig or Docker resource limits, and do not start additional containers during this check.

The workflow retains the database plus Auth, Storage API, imgproxy, Kong, Mailpit and PostgREST; it excludes Studio, Logflare, Vector, Edge Runtime, Postgres Meta, Realtime and Supavisor. The 7 GB Supabase recommendation is for all services. No minimum is documented for this reduced service set. Review the new readings together before deciding whether a local run is reasonable on this 8 GB PC.

Phase 1E remains partial/unverified: the 35- and 47-assertion SQL suites and backup/restore verifier remain pending. The latest exact-head Actions run #42462915084 failed before reporting any job steps; logs were unavailable, so no test failure or precise runner cause is established. The workflow remains on ubuntu-latest; runner registration alone does not redirect it. Any self-hosted runner change requires a separate security review.

PR #22 remains open, draft and unmerged. All existing hosted provisioning, cost, real-data, external processing/email, DNS, production deployment and merge restrictions remain in force.

## 10. Historical Windows/Ubuntu setup checkpoint — 8 November 2026 (superseded by Section 1)

The user verified: Windows PC has 8 GB DDR4 RAM; WSL2 Ubuntu runs as `gradioprep` in `/home/gradioprep`; Docker Desktop 4.98.0 is integrated with Ubuntu; Docker Engine 29.9.2 and Compose 5.6.1 respond successfully; Git 2.43.0 and GitHub CLI 2.103.3 are installed. `whoami`, `docker version`, `docker compose version` and `docker info` succeeded. Docker/Ubuntu reported about 2.8 GiB total memory and 2.1 GiB available at the check; the Linux home filesystem had about 955 GB free.

**Exact pause point:** GitHub CLI is installed but not authenticated. The next command is `gh auth login` in Ubuntu. Choose GitHub.com, HTTPS and browser-based login; complete device authorisation privately, then run `gh auth status`. Never share the one-time code, password or token. The private repository has not yet been cloned.

Do not force a larger WSL/Docker memory allocation or start the full Supabase stack until safe resource requirements and a reduced-resource option are reviewed. No memory settings have been changed. Phase 1E remains partial/unverified and its 35- and 47-assertion SQL suites remain unrun. All five GitHub spending budgets remain blocked. PR #22 remains open, draft and unmerged; no workflow, application, migration or test changes were made by this setup work.


## 11. Resource note — 8 November 2026

Supabase's current CLI reference recommends at least 7 GB RAM to start all local services. The GradioPrep workflow already excludes Studio, Logflare, Vector, Edge Runtime, Postgres Meta, Realtime and Supavisor, so a reduced local stack may require less. However, the user's Docker/Ubuntu environment currently reports about 2.8 GiB total memory. Do not assume this is sufficient, increase WSL/Docker memory limits, or attempt a full local stack before inspecting the project-specific service list and planning a safe reduced-resource run. Windows must retain enough memory for normal operation. See the [Supabase local development guide](https://supabase.com/docs/guides/local-development) and [Supabase CLI start reference](https://supabase.com/docs/reference/cli/introduction).


## 12. GitHub CLI authentication and repository access — verified 8 November 2026 (clone status superseded by Section 4)

The user completed GitHub CLI browser authentication from Ubuntu. Reported output confirmed:
- Host: `github.com`
- Active account: `gradioprep`
- Git operations protocol: HTTPS
- Token scopes shown: `gist`, `read:org`, `repo`, `workflow`

The read-only repository check `gh repo view gradioprep/gradioprep-website --json nameWithOwner,isPrivate` returned `nameWithOwner: gradioprep/gradioprep-website` and `isPrivate: true`. No password, device code or token was shared in chat.

**Current status — 8 November 2026:** GitHub CLI authentication, repository clone, Node/npm setup, dependency installation and checkout synchronisation are complete. Local HEAD, origin branch and PR #22 all matched 39b34c9727b15b2e6a1f514d87e1676a093b217f after a successful fast-forward. The working tree is clean. Node v22.23.4/npm 10.9.9 are installed; npm added 130 packages. The generated lockfile is intentionally not committed under the repository's current workflow policy. The next action is only the Windows/WSL/Docker memory snapshot described in Section 9. Supabase remains stopped until that assessment supports proceeding.
