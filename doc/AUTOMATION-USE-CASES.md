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
