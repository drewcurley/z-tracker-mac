# Review: feat/true-gyr-rendering — final

**Status:** PASS

**Process note:** solo project (`playbook/AGENTS.md` §12) — one operator
reviewed sequentially wearing each of the 9 hats.

## Blockers (must fix before merge)
- none

## Warnings (fix before next review)
- [ ] **Cyan override not implemented** — `doComputedDrawing`'s
      `whatToCyan` (`OverworldRouteDrawing.fs:65-68`) highlights the
      currently-selected route target. There is no selected target until the
      destination picker (T-015.6) produces one, so it is deferred there.
      Documented in the task's out-of-scope, not silently dropped.
- [ ] **Live visual confirmation recommended.** The GYR *logic* is
      exhaustively unit-tested and the wiring compiles, but this is a
      rendering change; confirming the actual green/yellow/red pixels means
      launching the app, enabling "highlight nearby," marking a few screens,
      and hovering. See "Verification" below.

## Suggestions (consider for polish)
- When T-015.5 gives `MirrorOverworld` a live source, thread it through
  `MainTrackerPlaceholderView.mapState` (currently `false`).

## Agent Sign-offs
- [x] Analyst — scope matches T-015.4: the G/Y/R cascade + its wiring,
      replacing the flat overlay. Cyan correctly deferred to T-015.6 (its
      only trigger, a selected target, doesn't exist yet).
- [x] Architect — no security surface. The color decision is a pure function
      in `TrackerCore` (testable, UI-framework-agnostic), matching the
      project's split of logic-from-view.
- [x] Data Engineer — the cascade is transcribed rule-for-rule and in the
      exact order from `OverworldRouteDrawing.fs:44-63` (dungeon-1–8-green →
      not-gettable-red → sometimesEmpty-yellow → green); the red-before-
      yellow ordering is pinned by test.
- [x] Backend — N/A (no server).
- [x] Frontend — `OverworldMapView` gains one `mapState` parameter;
      `MainTrackerPlaceholderView` computes it from the observable model, so
      colors re-derive when marks/items/dungeon state change. `#Preview` and
      the one call site updated. `overworldInstance` is derived locally from
      the existing `quest`, so no extra param for `sometimesEmpty`.
- [x] UX — green/yellow/red now conveys accessibility (the tracker's whole
      point) instead of a single "nearby" green; bold/pale preserved so the
      route-cost emphasis is unchanged. Colors use system `.green/.yellow/
      .red` at the existing 0.45/0.2 opacities — legible in both light/dark.
- [x] Test Engineer — 6 cascade tests: dungeon-1–8-always-green (all
      gettable×sometimesEmpty combos), dungeon-9-falls-through, red-wins-
      over-yellow, yellow, green, and a non-dungeon (shop) mark. The
      upstream `owGettableLocations`/`sometimesEmpty` inputs are already
      covered by T-015.3/T-015.1 tests. 148/148 total.
- [x] DevOps — no CI/deploy changes; `swift build` + `swift test` clean.
- [x] Review Coordinator — process followed; `domain.md` § 6 + umbrella
      `T-015.md` table + `tasks/T-015.4.md` updated; INDEX regenerated.

## Lens Sign-offs (user-facing rendering — Adopter/Builder relevant)
- [x] Adopter — this is the visible feature the whole player-state +
      map-state stack was for: the map now tells you at a glance what's
      reachable (green), quest-conditional (yellow), or blocked (red).
- [x] Builder — pure-function cascade + one thin view param keeps the change
      small and the logic testable without a running UI.
- Other lenses — N/A (internal rendering of already-decided behavior).

## Regression safety
- Contracts touched = none (in-process types + a SwiftUI view param).
  Reflected in docs = yes (`domain.md` § 6). Cross-repo consumers = none.
  Compatibility = additive (one new `OverworldMapView` parameter; both call
  sites updated).
- Full suite: 142/142 → 148/148, no regressions. `swift build` clean
  (app target links).

## Verification
- Unit: 6 new cascade tests + the 142 upstream (incl. the T-015.3 map-state
  scenarios that produce the `gettable` inputs).
- Build: `swift build` links the `ZTrackerMac` app target with the new
  `mapState` wiring.
- Live visual: recommended interactively (enable highlight-nearby, mark a
  few screens, hover) — the running debug build renders the map without
  crashing after the wiring change.

## Out of scope (tracked as follow-ons)
- T-015.5 — live `MirrorOverworld` / warp / any-road wiring.
- T-015.6 — destination picker + the cyan selected-target override.
