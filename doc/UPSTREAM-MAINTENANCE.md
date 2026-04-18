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

On Windows, put the repo root on `PATH` before typecheck so nested `pnpm` calls can resolve the tracked shim:

```powershell
$env:PATH = "$PWD;$env:PATH"
corepack pnpm -r typecheck
```

If `pnpm test:run` or `pnpm build` fails because upstream scripts require POSIX shell behavior (`sh`, `mkdir -p`, `cp -R`, or POSIX path expectations), record the failure and run those checks in CI or another POSIX-compatible environment.

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
