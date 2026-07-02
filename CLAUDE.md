# Claude Code — Project Entry Point (z-tracker-mac)

> **All project conventions live in [`AGENTS.md`](./AGENTS.md)**, which points to the
> shared playbook at [`../playbook/AGENTS.md`](../playbook/AGENTS.md). Do not duplicate
> convention content here — read `AGENTS.md` first, every session.

## Read this first, every session

1. Open and read **[`AGENTS.md`](./AGENTS.md)** in full — it points to the playbook.
2. Follow the Session Start Procedure in `playbook/AGENTS.md` § 0: this repo is inside
   a workspace (sibling `playbook/` with `workspace.manifest.md`), so read the playbook's
   `docs/` + `integration-map.md`, then this repo's own `/docs/`, then `tasks/INDEX.md`.
3. Then respond to the user's request, applying the agent team, review cycle, and hard
   gates defined in the playbook.

## Claude-Code-specific notes

- Subagents are defined in [`.claude/agents/`](./.claude/agents/) (mirrored from the
  playbook) — invoke via the `Task` / `Agent` tool, one per specialist.
- Project permissions live in [`.claude/settings.json`](./.claude/settings.json).
