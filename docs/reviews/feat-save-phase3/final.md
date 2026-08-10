# Review: feat/save-phase3 — final (T-196)

**Status:** PASS — Save/Load phase 3: starting-items now persist in the save, and
save-on-completion is wired. (Timeline was already persisted in T-186.)

unanimous-consensus: T-196

## What shipped
- `StartingItemsAndExtras.State` (Codable) + `state`/`restore`; `TrackerModel.State`
  carries it as an optional field (pre-T-196 saves decode with default empty inventory).
- `GameSave.saveOnCompletionIfEnabled` writes `ztracker-completed-<date>.json` when the run
  finishes and the option is on; guarded against firing during a load (`isApplyingSave`).

## Sign-offs
- [x] Analyst — closes the two open §2 Save/Load phase-3 items; timeline already done (T-186).
- [x] Architect — additive optional field keeps backward/forward save compat; the load guard
      matches the reference's `isCurrentlyLoadingASave` intent.
- [x] Data — full snapshot→JSON→restore round-trip incl. the fixed-size HDN array (guarded).
- [x] Backend — completion hook reuses the existing `hasRescuedZelda` observer + `makeFile`.
- [x] SDET — round-trip covers starting-items; `completedName` format tested; **728 pass**.
- [x] DevOps / Frontend / UX — n/a; clean build/test.
- [x] Review Coordinator — task filed (T-196); INDEX updated.

## Items to address (follow-ups)
- A starting-items *editor UI* is a separate concern (not in the coverage list); the data now
  persists whenever that inventory is set.
