# Review: feat/triforce-and-go-summary — final

**Status:** PASS

**Process note:** solo project (`playbook/AGENTS.md` §12) — one operator
reviewed sequentially wearing each of the 9 hats.

## Blockers (must fix before merge)
- none

## Warnings (fix before next review)
- [ ] **Preserved upstream bug.** `haveRecorder` reads `haveLadder`, exactly
      matching the reference's copy-paste bug (`TrackerModel.fs:1444`).
      Replicated for 1:1 TAG-score parity; documented in code, `domain.md`
      § 6, an auto-memory note, and pinned by a test. A consequence is that
      TAG level `102` is unreachable. Do not "fix" without an explicit
      decision to diverge from the reference.
- [ ] Not yet surfaced anywhere — the advisor is computed but no view shows
      it. Its broadcaster (`allUIEventingLogic`) is T-018.2.

## Suggestions (consider for polish)
- When T-018.2 wires this, expose it as a `TrackerModel` computed convenience
  (it needs six inputs — grid/instance/mapState/dungeonTracker/playerState/
  progress — all already on or derivable from the model).

## Agent Sign-offs
- [x] Analyst — scope matches T-018.1: the pure advisor + its helper,
      splitting the architecture-laden orchestration into T-018.2. No UI, no
      `ITrackerEvents`.
- [x] Architect — no security surface; pure value derivation. Splitting the
      architecture decision (`ITrackerEvents` vs `@Observable`) into T-018.2
      keeps this PR free of it.
- [x] Data Engineer — the scoring + TAG-level cascade is transcribed
      constant-for-constant against `TrackerModel.fs:1454-1480` (penalties
      20/8/35/30/15/5, TAG gates 101/102/103, the `missingDungeonCount==0 ||
      unreachableCount==0` guard) and `unreachablePossibleDungeonSpotCount`
      against `:1422-1438` (the five tool-gated increments, `cur < 9` filter).
      `mapState.dungeonLocations[i] != nil` = `HasBeenLocated()`.
- [x] Backend — N/A (no server); a pure function.
- [x] Frontend — N/A (no UI this sub-task).
- [x] UX — N/A.
- [x] Test Engineer — 8 tests: the empty-first-quest unreachable count pinned
      to the mask sum (41 = bomb 22 + burn 16 + raft 2 + whistle 1), all-
      tools→0, fresh→level 0, full-TAG→103, might-be-TAG→101, silvers-known-
      in-L9→103, all-located-no-items heuristic→15, and the bug-mirror
      assertion. 175/175 total.
- [x] DevOps — no CI/deploy changes; `swift build` + `swift test` clean.
- [x] Review Coordinator — process followed; `domain.md` § 6 + umbrella
      `T-018.md` + T-018.1/.2 task files + auto-memory updated; INDEX
      regenerated.

## Lens Sign-offs (routine computation port; the parity-bug call is the notable one)
- [x] Builder — preserving the upstream bug (loudly flagged + tested) over
      silently "fixing" it is the right call for a 1:1 clone: it keeps scores
      identical and makes the divergence an explicit, reversible decision.
- [x] PM — extracting the pure advisor now, deferring the orchestration's
      architecture decision to its own plan-reviewed task, de-risks the
      largest remaining piece.
- Other lenses — N/A (internal computation).

## Regression safety
- Contracts touched = none (in-process value type). Reflected in docs = yes
  (`domain.md` § 6). Cross-repo consumers = none. Compatibility = additive.
- Full suite: 167/167 → 175/175, no regressions. `swift build` clean.

## Out of scope (tracked as follow-ons)
- T-018.2 — `ITrackerEvents` + `allUIEventingLogic` orchestration (+ the
  reactive-vs-delegate architecture decision, + recorder-warp destinations
  deferred from T-015.5).
