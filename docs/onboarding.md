# Onboarding — z-tracker-mac

**Status:** forward-looking — no Xcode/SPM project exists yet (tracked as `tasks/T-002.md`).
This describes the intended day-one setup once that scaffold lands.

## Prerequisites

- Apple Silicon Mac (this app targets Apple Silicon natively — see `stack.md`).
- Xcode (latest stable; exact minimum version to be pinned in `stack.md` once the
  project scaffold is created and a minimum macOS deployment target is chosen).
- No other toolchain — Swift Package Manager ships with Xcode, no separate install.
- `gh` CLI recommended for PR workflow (not required).

## First-day path

1. Clone the repo: `git clone https://github.com/drewcurley/z-tracker-mac.git`.
2. Install hooks: `sh scripts/setup-hooks.sh` (one-time; see `.githooks/README.md`
   for what each hook enforces).
3. Read `AGENTS.md` (points to `../playbook/AGENTS.md` for the full conventions) and
   every file in `/docs/` — see `docs/README.md` for why and the Grounding &
   Completeness Protocol.
4. Read `tasks/INDEX.md` for what's in flight.
5. Open the project in Xcode once `tasks/T-002.md` (initial scaffold) lands; until
   then, there is no buildable target — the repo is in the docs-bootstrap phase.
6. Build: `swift build`. Test: `swift test`. (Both currently no-op / `continue-on-error`
   in CI until the scaffold exists — see `.github/workflows/checks.yml`.)

## First pull request expectations

- Every non-trivial change follows the branch → plan-review → build → build-review →
  test → regression-safety-check → commit → push → PR flow in `playbook/AGENTS.md` § 7.
- Commit messages reference a Task ID (`T-NNN`); enforced by `.githooks/commit-msg`.
- Since this is solo, "review" means working through each of the 9 agent-hat
  checklists in `.claude/agents/*.md` yourself before merging — not skipping it
  because there's no second person to ask.

## Communication channels

N/A — solo project, no team channels. Decisions worth remembering later are
recorded as ADRs in `docs/decisions/`, not left in chat/issue history.

## Update-this-doc-when

Update this file when the Xcode/SPM scaffold lands (`tasks/T-002.md`) — replace the
"forward-looking" build/run steps with the real, verified ones, and pin exact Xcode
and Swift toolchain versions.
