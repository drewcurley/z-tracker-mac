# Review: feat/dungeon-tab-hotkeys — final (T-133)

**Status:** PASS — dungeon-tab hotkeys switch tabs; tab hoisted to shared state.

unanimous-consensus: T-133

## Sign-offs
- [x] Analyst — next Part-B slice; scope limited to the tab globals + the enabling hoist.
- [x] Architect — `TrackerFocusState` is app-level shared state (like overlays/hotkeys),
      reachable by the dispatcher and stable across the reflow; the cursor phase reuses it.
- [x] Frontend — `DungeonMapView.selected` now a computed view over the shared state.
- [x] UX — tabs switch by key from anywhere; clicking unchanged; survives reflow (a fix).
- [x] Data / Backend — no game-state change.
- [x] SDET — dispatch is AppKit-coupled (manual QA'd: `3` → tab 3). 503 tests pass; build clean.
- [x] DevOps — no infra impact.
- [x] Review Coordinator — task filed (T-133); INDEX updated.

## Regression safety
- The tab's source of truth moved but its behavior is unchanged; a bonus fix is that
  it no longer resets on the band's reflow.
