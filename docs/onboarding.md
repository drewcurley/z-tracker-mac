# Onboarding — z-tracker-mac

**Status:** verified — the scaffold (`tasks/T-002.md`) is merged; the steps
below are real, run commands, not a plan.

## Prerequisites

- Apple Silicon Mac (this app targets Apple Silicon natively — see `stack.md`).
- Xcode 26+ / Swift 6+ toolchain (built and tested against Xcode 26.6, Swift 6.3.3).
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
5. Build: `swift build`. Test: `swift test` (runs the `TrackerCoreTests` Swift
   Testing suite — 5 tests as of `T-002`). Run: `swift run ZTrackerMac` (opens a
   placeholder window; no tracker UI yet). Both `swift build` and `swift test`
   are required (not `continue-on-error`) in CI — see `.github/workflows/checks.yml`.
6. There is no Xcode project file (`.xcodeproj`) — this is a pure SwiftPM
   package. Opening the folder in Xcode directly (`xed .`) works and gives the
   full IDE experience (editing, debugging, running) against the same
   `Package.swift`.

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

Update this file if the toolchain version requirement changes, or if the
project ever moves from a pure SwiftPM package to a `.xcodeproj`-based layout.
