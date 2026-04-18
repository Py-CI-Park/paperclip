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
