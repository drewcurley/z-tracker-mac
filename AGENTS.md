# Project Conventions for AI Agents — z-tracker-mac

> **This repo is part of a workspace.** The canonical conventions — the 9-agent
> team, the 3-round review cycle, redlines, the 7 strategic lenses, the session-start
> procedure, and the Docs Bootstrap Workflow — live in the shared playbook at
> **[`../playbook/AGENTS.md`](../playbook/AGENTS.md)**. Read that file in full before
> doing any work here. This file exists only so a session opened directly inside
> `z-tracker-mac/` (without `../playbook` already in context) still finds its way there.

## This repo's role

`z-tracker-mac` is the **active development repo** — a from-scratch, feature-by-feature,
near pixel-perfect clone of [Z-Tracker](https://github.com/brianmcn/Zelda1RandoTools),
built as a native Apple Silicon macOS app. All feature work, commits, and pull requests
happen here. See `playbook/workspace.manifest.md` for the full repo roster (this repo
plus the read-only `Zelda1RandoTools` reference).

## Session start (quick version — see playbook/AGENTS.md § 0 for the full procedure)

1. Confirm `../playbook/workspace.manifest.md` exists (it does — this is a workspace).
2. Read `../playbook/docs/` (project-wide architecture + `integration-map.md`).
3. Read this repo's own `/docs/` in full — especially `contracts.md`.
4. Read `tasks/INDEX.md` for in-flight work.
5. Proceed with the user's request under the playbook's review cycle and redlines.

## Scaled-down process

This is a solo project. Per `playbook/AGENTS.md` § 12, one person (with AI agent
assistance) wears all 9 agent hats sequentially rather than requiring 9 separate
reviewers. Redlines, hooks, the CI mirror, and the `/docs/*` consensus rule are **not**
scaled down. See `docs/decisions/0001-solo-scale-down.md` (playbook) for the full
reasoning.
