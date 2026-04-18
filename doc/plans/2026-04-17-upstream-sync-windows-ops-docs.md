# Upstream Sync Windows Ops Docs Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Bring the fork up to the latest `paperclipai/paperclip` upstream, verify install/run behavior, and document a repeatable Windows update/run/automation workflow.

**Architecture:** Keep upstream source authoritative and layer fork-local Windows helpers and operator documentation on top. Use repo-local `.paperclip-local` for Windows batch startup to avoid the user's drifted global Paperclip instance, but keep the official `pnpm dev` / `pnpm dev:once` path documented as the canonical upstream path.

**Tech Stack:** Git, GitHub remotes (`origin` fork, `upstream` source), pnpm via Corepack, Windows batch files, PowerShell verification commands, Paperclip embedded PostgreSQL, Express/Vite dev middleware, Markdown docs.

---

## File Structure

- Modify: `AGENTS.md`
  - Add fork-local operating guidance for upstream sync cadence, batch helper expectations, and required docs updates after command changes.
- Create: `CLAUDE.md`
  - Mirror the essential repo operating contract for Claude-style agents without duplicating the full AGENTS.md body.
- Modify: `start.bat`
  - Keep it simple and foreground-oriented. It should call `paperclip-dev.cmd` directly so the visible window stays open and errors remain readable.
- Modify: `paperclip-dev.cmd`
  - Keep repo-local env setup aligned with `doc/DEVELOPING.md`, and use the direct server path only if retained after verification.
- Modify: `stop.bat`
  - Keep cleanup scoped to this checkout and port 3100. Do not destroy unrelated processes.
- Create: `doc/WINDOWS-RUNBOOK.md`
  - Human-facing Windows install, update, start, stop, blank-page, admin-token, and health-check guide.
- Create: `doc/UPSTREAM-MAINTENANCE.md`
  - Periodic upstream update process, cadence, commands, verification checklist, and push policy.
- Create: `doc/AUTOMATION-USE-CASES.md`
  - Practical coding automation, Paperclip company examples, investment-operation automation caveats, and recommended next steps.
- Modify: `doc/DEVELOPING.md`
  - Add a short pointer to Windows runbook and upstream maintenance docs rather than duplicating all content.

---

### Task 1: Sync Latest Upstream Onto the Fork Branch

**Files:**
- No source files modified directly in this task.

- [ ] **Step 1: Confirm current branch and remotes**

Run:

```powershell
git status --short --branch
git remote -v
git branch --show-current
```

Expected:

```text
## py-ci-park/work-20260405...origin/py-ci-park/work-20260405
origin   https://github.com/Py-CI-Park/paperclip.git (fetch)
origin   https://github.com/Py-CI-Park/paperclip.git (push)
upstream https://github.com/paperclipai/paperclip.git (fetch)
upstream https://github.com/paperclipai/paperclip.git (push)
py-ci-park/work-20260405
```

- [ ] **Step 2: Fetch upstream and record latest upstream commit**

Run:

```powershell
git fetch upstream --prune
git ls-remote upstream refs/heads/master
```

Expected:

```text
<latest-upstream-sha>        refs/heads/master
```

Record the exact SHA in the final report.

- [ ] **Step 3: Rebase local branch on upstream master**

Run:

```powershell
git rebase upstream/master
```

Expected:

```text
Successfully rebased and updated refs/heads/py-ci-park/work-20260405.
```

If conflicts occur, resolve only conflicts involving the fork-local Windows helper/docs files. Do not rewrite upstream implementation files unless a conflict requires it.

- [ ] **Step 4: Verify upstream latest is contained**

Run:

```powershell
$upstreamSha = (git ls-remote upstream refs/heads/master).Split()[0]
git merge-base --is-ancestor $upstreamSha HEAD
if ($LASTEXITCODE -eq 0) { "upstream-latest-contained" } else { "upstream-latest-not-contained" }
```

Expected:

```text
upstream-latest-contained
```

- [ ] **Step 5: Install dependencies**

Run:

```powershell
corepack pnpm install
```

Expected:

```text
Lockfile is up to date, resolution step is skipped
Already up to date
Done in ...
```

It is acceptable if pnpm prints its update banner. Do not update pnpm unless separately requested.

- [ ] **Step 6: Commit only if the rebase creates conflict-resolution changes**

If `git status --short` shows source/doc changes caused by conflict resolution, commit them with a Lore-style message:

```powershell
git add <resolved-files>
git commit -m "Preserve Windows helpers after upstream sync" `
  -m "The branch was rebased onto upstream/master and fork-local Windows helper documentation needed conflict resolution while preserving upstream source behavior." `
  -m "Constraint: Keep upstream implementation authoritative" `
  -m "Confidence: high" `
  -m "Scope-risk: narrow" `
  -m "Tested: corepack pnpm install"
```

If no files changed, do not create an empty commit.

---

### Task 2: Re-evaluate Windows Start/Stop Helpers Against Official Dev Flow

**Files:**
- Modify: `start.bat`
- Modify: `paperclip-dev.cmd`
- Modify: `stop.bat`
- Use reference: `doc/DEVELOPING.md`

- [ ] **Step 1: Read official dev commands**

Run:

```powershell
Select-String -Path doc\DEVELOPING.md -Pattern "Start Dev","pnpm dev","pnpm dev:once","pnpm dev:stop","Database in Dev" -Context 0,4
Get-Content package.json | Select-String -Pattern '"dev"', '"dev:once"', '"dev:stop"', '"dev:server"'
```

Expected:

```text
pnpm install
pnpm dev
pnpm dev:once
pnpm dev:stop
```

- [ ] **Step 2: Keep `start.bat` as a foreground wrapper**

Replace `start.bat` with this complete content if it differs:

```bat
@echo off
setlocal

set "ROOT=%~dp0"
cd /d "%ROOT%"
set "PAPERCLIP_DEV_URL=http://127.0.0.1:3100/"
title Paperclip Dev

powershell -NoLogo -NoProfile -Command ^
  "$id = [Security.Principal.WindowsIdentity]::GetCurrent();" ^
  "$principal = New-Object Security.Principal.WindowsPrincipal($id);" ^
  "if ($principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) { exit 0 } else { exit 1 }"
if %ERRORLEVEL% EQU 0 (
  echo start.bat cannot run from an Administrator console.
  echo Embedded PostgreSQL refuses to start with administrative privileges.
  echo Run start.bat from a normal non-admin Command Prompt, PowerShell, or Explorer.
  pause
  endlocal & exit /b 1
)

powershell -NoLogo -NoProfile -Command ^
  "try { $resp = Invoke-WebRequest -UseBasicParsing ($env:PAPERCLIP_DEV_URL + 'api/health') -TimeoutSec 2; if ($resp.StatusCode -eq 200) { exit 0 } } catch {} exit 1"
if %ERRORLEVEL% EQU 0 (
  echo Paperclip dev server is already running.
  start "" "%PAPERCLIP_DEV_URL%"
  pause
  endlocal & exit /b 0
)

call paperclip-dev.cmd

set "EXIT_CODE=%ERRORLEVEL%"
endlocal & exit /b %EXIT_CODE%
```

- [ ] **Step 3: Keep `paperclip-dev.cmd` aligned with official env requirements**

Replace `paperclip-dev.cmd` with this complete content if it differs:

```bat
@echo off
setlocal

set "ROOT=%~dp0"
cd /d "%ROOT%"
title Paperclip Dev

powershell -NoLogo -NoProfile -Command ^
  "$id = [Security.Principal.WindowsIdentity]::GetCurrent();" ^
  "$principal = New-Object Security.Principal.WindowsPrincipal($id);" ^
  "if ($principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) { exit 0 } else { exit 1 }"
if %ERRORLEVEL% EQU 0 (
  echo This console is running as Administrator.
  echo Embedded PostgreSQL refuses to start with administrative privileges.
  echo Close this window and run start.bat from a normal non-admin shell.
  pause
  endlocal & exit /b 1
)

set "PAPERCLIP_HOME=%ROOT%.paperclip-local"
set "PATH=%ROOT%;%PATH%"
set "PAPERCLIP_UI_DEV_MIDDLEWARE=true"
set "PAPERCLIP_MIGRATION_AUTO_APPLY=true"
set "PAPERCLIP_MIGRATION_PROMPT=never"
set "PAPERCLIP_OPEN_ON_LISTEN=true"

echo Starting Paperclip dev server...
echo   UI: http://127.0.0.1:3100/
echo   API: http://127.0.0.1:3100/api
echo.

call pnpm --filter @paperclipai/plugin-sdk build
if errorlevel 1 (
  echo.
  echo Plugin SDK build failed.
  pause
  endlocal & exit /b 1
)

call pnpm --filter @paperclipai/server dev
set "EXIT_CODE=%ERRORLEVEL%"

echo.
echo Paperclip dev server stopped or failed with exit code %EXIT_CODE%.
echo Press any key to close this window.
pause >nul

endlocal & exit /b %EXIT_CODE%
```

- [ ] **Step 4: Keep repo-local `pnpm.cmd` helper tracked**

Replace `pnpm.cmd` with this complete content if it differs:

```bat
@echo off
call corepack pnpm %*
```

- [ ] **Step 5: Keep `stop.bat` scoped but practical**

Confirm `stop.bat` contains all of these cleanup targets:

```text
pnpm dev:stop
src/index.ts
paperclip-dev.cmd
launch-dev.cmd
WINDOWTITLE eq Paperclip Dev
```

If any are missing, add them using existing PowerShell cleanup style from the file.

- [ ] **Step 6: Commit helper changes**

Run:

```powershell
git add start.bat paperclip-dev.cmd stop.bat pnpm.cmd
git commit -m "Align Windows helpers with current dev startup flow" `
  -m "Windows helper scripts now preserve the documented repo-local dev behavior while keeping startup visible and failures readable." `
  -m "Constraint: Embedded PostgreSQL must not run elevated on Windows" `
  -m "Confidence: high" `
  -m "Scope-risk: narrow" `
  -m "Tested: Pending in verification task"
```

Skip the commit if no helper files changed.

---

### Task 3: Add Windows Runbook

**Files:**
- Create: `doc/WINDOWS-RUNBOOK.md`
- Modify: `doc/DEVELOPING.md`

- [ ] **Step 1: Create `doc/WINDOWS-RUNBOOK.md`**

Create the file with this complete content:

```markdown
# Windows Runbook

This runbook describes the supported Windows local development flow for this fork.

## Golden Rules

1. Do not run Paperclip embedded PostgreSQL from an Administrator console.
2. Use a normal Command Prompt, PowerShell, Windows Terminal profile, or Explorer double-click.
3. Use repo-local state for this checkout: `.paperclip-local`.
4. Use `start.bat` to start and `stop.bat` to stop when you want the Windows helper flow.
5. Use the official upstream commands when debugging the app itself.

## Quick Start

From the repo root:

```powershell
.\start.bat
```

Expected:

- The `Paperclip Dev` console remains open.
- The server prints `Server listening on 127.0.0.1:3100`.
- Browser access works at `http://127.0.0.1:3100/`.

Stop:

```powershell
.\stop.bat
```

## Manual Official Dev Path

Use this when debugging without the batch helpers:

```powershell
cd D:\Chanil_Park\Project\Programming\paperclip
$env:PAPERCLIP_HOME = "$PWD\.paperclip-local"
$env:PAPERCLIP_UI_DEV_MIDDLEWARE = "true"
$env:PAPERCLIP_MIGRATION_AUTO_APPLY = "true"
$env:PAPERCLIP_MIGRATION_PROMPT = "never"
corepack pnpm --filter @paperclipai/server dev
```

Health check:

```powershell
Invoke-WebRequest -UseBasicParsing http://127.0.0.1:3100/api/health
```

UI check:

```powershell
Invoke-WebRequest -UseBasicParsing http://127.0.0.1:3100/
```

## Administrator Console Error

If you see:

```text
start.bat cannot run from an Administrator console.
Embedded PostgreSQL refuses to start with administrative privileges.
```

close that terminal and open a normal non-admin terminal. Embedded PostgreSQL refuses elevated startup by design.

## Blank Screen Checklist

1. Confirm the API is alive:

```powershell
Invoke-WebRequest -UseBasicParsing http://127.0.0.1:3100/api/health
```

2. Confirm the UI document is served:

```powershell
Invoke-WebRequest -UseBasicParsing http://127.0.0.1:3100/
```

3. Force-refresh the browser:

```text
Ctrl+F5
```

4. Open browser DevTools Console and record the first red error.

5. Restart cleanly:

```powershell
.\stop.bat
.\start.bat
```

## Reset Repo-Local Database

Stop Paperclip first:

```powershell
.\stop.bat
```

Then remove the repo-local database:

```powershell
Remove-Item -Recurse -Force .\.paperclip-local\instances\default\db
```

Start again:

```powershell
.\start.bat
```

## Update Then Run

```powershell
git fetch upstream --prune
git rebase upstream/master
corepack pnpm install
.\start.bat
```

## Verification Commands

```powershell
corepack pnpm install
corepack pnpm -r typecheck
corepack pnpm test:run
corepack pnpm build
```
```

- [ ] **Step 2: Add a pointer in `doc/DEVELOPING.md`**

Add this section after `## Start Dev` content or before `## Test Commands`:

```markdown
## Windows Helper Scripts

For this fork's Windows helper workflow, see [`doc/WINDOWS-RUNBOOK.md`](./WINDOWS-RUNBOOK.md).

The official upstream path remains:

```sh
pnpm install
pnpm dev
```

The Windows helpers wrap a repo-local `.paperclip-local` instance and are intended for local convenience only.
```

- [ ] **Step 3: Commit docs**

Run:

```powershell
git add doc/WINDOWS-RUNBOOK.md doc/DEVELOPING.md
git commit -m "Document Windows local runbook" `
  -m "The Windows runbook captures the supported start/stop helper flow, official manual dev path, admin-token caveat, blank-screen checklist, and repo-local database reset commands." `
  -m "Confidence: high" `
  -m "Scope-risk: narrow" `
  -m "Tested: Markdown content reviewed"
```

---

### Task 4: Add Periodic Upstream Maintenance Guidance

**Files:**
- Create: `doc/UPSTREAM-MAINTENANCE.md`
- Modify: `AGENTS.md`
- Create: `CLAUDE.md`

- [ ] **Step 1: Create `doc/UPSTREAM-MAINTENANCE.md`**

Create the file with this complete content:

```markdown
# Upstream Maintenance

This fork tracks `paperclipai/paperclip` as `upstream` and pushes fork-local work to `origin`.

## Remote Layout

```text
origin   https://github.com/Py-CI-Park/paperclip.git
upstream https://github.com/paperclipai/paperclip.git
```

## Recommended Cadence

- Check upstream before every active development session.
- Check at least weekly when the repo is idle.
- Re-run install and startup verification after every upstream rebase.
- Run full verification before claiming a branch is ready.

## Update Procedure

```powershell
git status --short --branch
git fetch upstream --prune
git ls-remote upstream refs/heads/master
git rebase upstream/master
corepack pnpm install
```

Confirm the latest upstream commit is included:

```powershell
$upstreamSha = (git ls-remote upstream refs/heads/master).Split()[0]
git merge-base --is-ancestor $upstreamSha HEAD
if ($LASTEXITCODE -eq 0) { "upstream-latest-contained" } else { "upstream-latest-not-contained" }
```

Push the rebased fork branch:

```powershell
git push --force-with-lease origin py-ci-park/work-20260405
```

## Startup Verification

```powershell
.\stop.bat
.\start.bat
Invoke-WebRequest -UseBasicParsing http://127.0.0.1:3100/api/health
Invoke-WebRequest -UseBasicParsing http://127.0.0.1:3100/
```

Expected:

- `/api/health` returns JSON with `"status":"ok"`.
- `/` returns HTTP `200`.

## Full Verification

Run before declaring done:

```powershell
corepack pnpm -r typecheck
corepack pnpm test:run
corepack pnpm build
```

## Reporting Template

```text
Upstream latest: <sha>
Local HEAD: <sha>
Install: passed/failed
Health: passed/failed
UI: passed/failed
Typecheck: passed/failed/not run
Tests: passed/failed/not run
Build: passed/failed/not run
Risks: <known gaps>
```
```

- [ ] **Step 2: Add upstream maintenance pointer to `AGENTS.md`**

Add this section before `## 11. Definition of Done`:

```markdown
## Upstream Maintenance

This fork tracks `paperclipai/paperclip` as `upstream`. Before update, run:

```sh
git fetch upstream --prune
git rebase upstream/master
corepack pnpm install
```

After update, verify startup and tests using [`doc/UPSTREAM-MAINTENANCE.md`](doc/UPSTREAM-MAINTENANCE.md). Keep Windows helper behavior documented in [`doc/WINDOWS-RUNBOOK.md`](doc/WINDOWS-RUNBOOK.md).
```

- [ ] **Step 3: Create `CLAUDE.md`**

Create the file with this complete content:

```markdown
# CLAUDE.md

This repository follows the same operating contract as `AGENTS.md`.

## Read First

1. `AGENTS.md`
2. `doc/GOAL.md`
3. `doc/PRODUCT.md`
4. `doc/SPEC-implementation.md`
5. `doc/DEVELOPING.md`
6. `doc/WINDOWS-RUNBOOK.md`
7. `doc/UPSTREAM-MAINTENANCE.md`

## Local Windows Notes

- Do not run embedded PostgreSQL from an Administrator console.
- Use `start.bat` / `stop.bat` for the fork-local Windows helper flow.
- Use the manual official dev path from `doc/WINDOWS-RUNBOOK.md` when debugging batch behavior.

## Upstream Sync

Before active work, check upstream:

```sh
git fetch upstream --prune
git rebase upstream/master
corepack pnpm install
```

Then verify health, UI, typecheck, tests, and build as appropriate.
```

- [ ] **Step 4: Commit maintenance docs**

Run:

```powershell
git add doc/UPSTREAM-MAINTENANCE.md AGENTS.md CLAUDE.md
git commit -m "Document upstream maintenance workflow" `
  -m "The fork now has explicit upstream sync cadence, verification commands, and Claude-facing guidance that points back to the canonical AGENTS.md contract." `
  -m "Confidence: high" `
  -m "Scope-risk: narrow" `
  -m "Tested: Markdown content reviewed"
```

---

### Task 5: Add Automation Use Cases and Recommendations

**Files:**
- Create: `doc/AUTOMATION-USE-CASES.md`

- [ ] **Step 1: Create `doc/AUTOMATION-USE-CASES.md`**

Create the file with this complete content:

```markdown
# Automation Use Cases

This document collects practical ways to use Paperclip once the local instance is running.

## Recommended First Company: Paperclip Local Ops

Goal:

```text
Keep this Paperclip fork updated, runnable, documented, and verified on Windows.
```

Suggested agents:

| Agent | Role | Reports To | Output |
|---|---|---|---|
| Local Ops Lead | Prioritizes update and runtime work | none | Weekly operating plan |
| Upstream Maintainer | Checks upstream and rebases safely | Local Ops Lead | Updated branch and sync report |
| Windows QA | Verifies start/stop, health, UI, and admin-token edge cases | Local Ops Lead | Verification notes |
| Docs Steward | Updates runbooks and troubleshooting docs | Local Ops Lead | Markdown docs |

Starter issues:

1. Check upstream and rebase the fork.
2. Run `corepack pnpm install`.
3. Verify `start.bat`, `/api/health`, `/`, and `stop.bat`.
4. Update `doc/WINDOWS-RUNBOOK.md` when startup behavior changes.
5. Summarize risks before pushing.

## Coding Automation Company

Goal:

```text
Automate routine code maintenance for a repository.
```

Suggested workflow:

1. Product/Lead agent turns a request into issues.
2. Engineer agent implements the issue on a branch.
3. QA agent runs focused tests and reproduces failures.
4. Docs agent updates user-facing instructions.
5. Release agent prepares a PR with verification evidence.

Good tasks:

- Update dependencies and verify builds.
- Fix failing tests.
- Reproduce user-reported startup issues.
- Write runbooks from repeated support cases.

## Personal Operations Company

Goal:

```text
Turn recurring personal or business tasks into tracked work with clear outputs.
```

Suggested agents:

- Chief of Staff: daily priorities and follow-up.
- Researcher: gathers facts and references.
- Writer: drafts emails, memos, summaries.
- Analyst: turns raw data into reports.

Good tasks:

- Weekly planning brief.
- Meeting notes to action items.
- Research summary with citations.
- Email draft with approval before send.

## Investment Operations Assistant

Goal:

```text
Support investment operations without automatically placing trades.
```

Safe starting scope:

- Collect portfolio snapshots.
- Summarize market and company news.
- Calculate target allocation drift.
- Flag risk thresholds.
- Draft a human-approved rebalance plan.

Avoid at the beginning:

- Fully automated order placement.
- High-frequency strategies.
- Unlogged discretionary model output.
- Strategies without backtesting and risk limits.

Recommended controls:

- Human approval before any trade.
- Position limits.
- Daily loss threshold.
- Audit log for every recommendation.
- Paper-trading period before live execution.

## Content and Marketing Company

Goal:

```text
Produce research-backed content from idea to draft to review.
```

Suggested workflow:

1. Content Lead chooses topics.
2. Researcher gathers sources.
3. Writer drafts.
4. Editor reviews for clarity and factual claims.
5. Publisher prepares channel-specific variants.

Good tasks:

- Blog outline.
- Newsletter draft.
- Social post variants.
- Competitor analysis.

## Recommended Next Step

Start with `Paperclip Local Ops`. It directly improves this environment and creates reusable evidence for future automation.
```

- [ ] **Step 2: Commit use-case docs**

Run:

```powershell
git add doc/AUTOMATION-USE-CASES.md
git commit -m "Document practical Paperclip automation use cases" `
  -m "The use-case guide gives concrete company/team examples for coding operations, personal operations, investment support, and content workflows, with a recommended first company for this fork." `
  -m "Confidence: high" `
  -m "Scope-risk: narrow" `
  -m "Tested: Markdown content reviewed"
```

---

### Task 6: Run Full Verification

**Files:**
- No source files modified directly in this task.

- [ ] **Step 1: Install dependencies**

Run:

```powershell
corepack pnpm install
```

Expected:

```text
Done in ...
```

- [ ] **Step 2: Verify batch startup**

Run:

```powershell
.\stop.bat
.\start.bat
```

In a separate terminal:

```powershell
Invoke-WebRequest -UseBasicParsing http://127.0.0.1:3100/api/health
Invoke-WebRequest -UseBasicParsing http://127.0.0.1:3100/
```

Expected:

```text
StatusCode: 200
```

and `/api/health` contains:

```json
{"status":"ok"}
```

- [ ] **Step 3: Verify manual official server path**

Stop the batch server:

```powershell
.\stop.bat
```

Start manually:

```powershell
$env:PAPERCLIP_HOME = "$PWD\.paperclip-local"
$env:PAPERCLIP_UI_DEV_MIDDLEWARE = "true"
$env:PAPERCLIP_MIGRATION_AUTO_APPLY = "true"
$env:PAPERCLIP_MIGRATION_PROMPT = "never"
corepack pnpm --filter @paperclipai/server dev
```

Expected:

```text
Server listening on 127.0.0.1:3100
```

Stop with `Ctrl+C`.

- [ ] **Step 4: Run typecheck**

Run:

```powershell
corepack pnpm -r typecheck
```

Expected:

```text
Exit code 0
```

- [ ] **Step 5: Run Vitest suite**

Run:

```powershell
corepack pnpm test:run
```

Expected:

```text
Test Files ... passed
Tests ... passed
Exit code 0
```

- [ ] **Step 6: Run build**

Run:

```powershell
corepack pnpm build
```

Expected:

```text
Exit code 0
```

- [ ] **Step 7: Push rebased branch**

Run:

```powershell
git status --short --branch
git push --force-with-lease origin py-ci-park/work-20260405
```

Expected:

```text
py-ci-park/work-20260405 -> py-ci-park/work-20260405
```

---

## Self-Review

**Spec coverage:** This plan covers upstream sync, dependency install, run verification, Windows batch helper review, AGENTS/CLAUDE guidance, periodic update docs, and automation/use-case docs.

**Placeholder scan:** No `TBD`, `TODO`, or undefined later-fill steps remain. Each file creation task includes full proposed content.

**Type consistency:** Commands consistently use `corepack pnpm`, `origin` for the fork, `upstream` for `paperclipai/paperclip`, branch `py-ci-park/work-20260405`, and repo-local `.paperclip-local`.
