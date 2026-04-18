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

## Windows Verification Caveats

`corepack pnpm -r typecheck` is expected to work on Windows when the repo root is on `PATH` so the tracked `pnpm.cmd` shim can satisfy nested workspace scripts:

```powershell
$env:PATH = "$PWD;$env:PATH"
corepack pnpm -r typecheck
```

The full Vitest and build suites currently exercise upstream scripts and tests that assume POSIX process behavior. On Windows, known failure modes include:

- `spawn sh ENOENT` when tests start runtime services through `sh`
- extensionless temporary command files such as `gemini` or `agent` failing to spawn
- POSIX path assertions such as `/tmp/...` not matching Windows paths
- build scripts using `mkdir -p` and `cp -R` when the script shell is `cmd.exe`

When these appear, verify startup locally with `start.bat` and run full test/build verification in a POSIX-compatible environment or CI.
