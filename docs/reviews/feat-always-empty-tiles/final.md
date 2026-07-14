# Review: feat/always-empty-tiles — final (T-026)

**Status:** PASS

**Process note:** solo project (`playbook/AGENTS.md` §12) — one operator
reviewed sequentially wearing each of the 9 hats. Tier: routine UI gate over an
already-ported, tested model (memory: review-rigor-tiering).

## Blockers (must fix before merge)
- none

## Warnings (fix before next review)
- [ ] The reference draws special decorations on a few always-empty tiles —
      fairy spots (9,3),(3,4),second-quest(11,0) and the coast-item ladder box
      on the map at (15,5) (`WPFUI.fs:485-498`). Deferred (noted out-of-scope);
      the coast box already lives in the item grid (T-025.1).

## Suggestions (consider for polish)
- Permanent always-empty X and a user-set `.dontCare` both read as "dark tile";
  the reference uses the same DARK_X for both, so this matches. The permanence
  is conveyed by non-interactivity.

## Agent Sign-offs
- [x] Analyst — scope: auto-mark the per-quest always-empty screens as
      permanent don't-care + block editing (user request). Grounded in
      `OverworldData.fs` `AlwaysEmpty`; no creep into the deferred special-tile
      decorations.
- [x] Architect — no security surface. Derived from `OverworldInstance`
      (a pure value over static quest tables); the grid tile stays `.unmarked`
      underneath, so save/load, routing, and `MapStateSummary` are untouched.
- [x] Data Engineer — no data change. Reuses the already-tested
      `alwaysEmpty` tables (per-quest counts 55/48/35; mixed = first ∧ second).
- [x] Backend — N/A.
- [x] Frontend — `TileView.isAlwaysEmpty` draws dimmed terrain + a fixed X
      (the reference DARK_X). Interaction gated by `.allowsHitTesting(false)`
      (blocks tap/context-menu/hover) plus a defensive early-return in
      `handleLeftClick`; the tile is also excluded from the GYR highlight
      overlay. Playable tiles pass `isAlwaysEmpty=false` → unchanged.
- [x] UX — the ~55 (first quest) unreachable mountain/water screens are now
      clearly "nothing here" and can't be mis-clicked, reducing noise. Terrain
      stays readable under the dim (aesthetic license), unlike a hard black-out.
- [x] Test Engineer — 229/229 (228→229): added pinpoint `alwaysEmpty`
      coordinate assertions (first-quest (0,0) empty; (1,0)/(7,0)/(7,7) not;
      start screen playable in both quests) on top of the existing per-quest
      count + mixed-AND tests. View wiring verified on-device (X placement,
      non-interactivity, playable tiles still respond).
- [x] DevOps — no CI/deploy/asset change. `swift build` (debug+release) +
      `swift test` clean; app runs and renders.
- [x] Review Coordinator — `tasks/T-026.md` filed; INDEX updated. No `docs/*`
      domain change — the always-empty behavior is already documented model
      (T-015.1); this renders it.

## Lens Sign-offs
- Local UI slice, user-requested — full 7-lens review not triggered.

## Regression safety
- Contracts touched = none. Additive: a defaulted `TileView` param + two view
  modifiers + a defensive guard. Non-empty tiles take the identical path as
  before (`isAlwaysEmpty=false`).
- Full suite 228→229, no regressions. Builds clean (debug + release).

## Out of scope (follow-ons)
- Always-empty special decorations: fairy spots + the coast-item ladder box
  drawn on the overworld map at (15,5).
