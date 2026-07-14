# Review: feat/anyroad-warp-wiring — final

**Status:** PASS

**Process note:** solo project (`playbook/AGENTS.md` §12) — one operator
reviewed sequentially wearing each of the 9 hats. Carries a **scope
decision** (narrowing T-015.5, splitting out T-015.7) — reviewed below.

## Blockers (must fix before merge)
- none

## Warnings (fix before next review)
- [ ] `recorderWarpDestinations` is still fed empty — deferred to T-018
      (the reference derives it in the reminders/orchestration path). Marked
      in code with a grounded comment, not silently empty.
- [ ] `MirrorOverworld` (`placeholderIsMirror`) remains a placeholder,
      tracked as T-015.7 — it's a display-flip feature, out of this task's
      scope.

## Suggestions (consider for polish)
- When warp edges get warp-vs-walk metadata (with recorder-dests, T-018),
  reinstate the reference's dashed/skipped warp-line styling.

## Agent Sign-offs
- [x] Analyst — **scope decision reviewed.** A grounding read established
      that the original T-015.5 bundled one ready piece (any-roads) with two
      entangled ones (recorder-dests → needs T-018's orchestration + recorder
      options + HDN; mirror → a display feature). Narrowing to the ready
      piece and splitting the rest (T-015.7, T-018) keeps each unit honest
      and shippable — the same discipline that split T-015 itself.
- [x] Architect — no security surface; a one-line data wiring into an
      already-ported graph. No new globals.
- [x] Data Engineer — `anyRoadLocations` is populated by the T-015.3
      recompute (`case 9...12`), verified by the new test; the view's
      `compactMap`/`map` extraction is the exact routing input.
- [x] Backend — N/A (no server).
- [x] Frontend — `OverworldMapView.dynamicGraph` now passes
      `anyRoadDestinations` (derived from `mapState`) instead of `[]`; the
      graph's any-road warp machinery (T-010) does the rest.
- [x] UX — hover routing can now use any-road warps once the player marks two
      or more, matching the reference; no new controls.
- [x] Test Engineer — 1 new test: any-road marks populate `anyRoadLocations`
      by warp number (1→index 0, 3→index 2, others nil) and the view's
      extraction yields the 2 coords. The graph's any-road pathfinding (cost
      4 warp) is already covered by `OverworldPathfindingTests` (T-010).
      149/149 total.
- [x] DevOps — no CI/deploy changes; `swift build` + `swift test` clean.
- [x] Review Coordinator — process followed; `domain.md` § 6 + umbrella
      `T-015.md` (narrowed row + scope note + new T-015.7 row) +
      `tasks/T-015.5.md` (rewritten) + `tasks/T-015.7.md` (created) updated;
      INDEX regenerated.

## Lens Sign-offs (scope-narrowing decision)
- [x] PM — narrowing over guessing: shipping the ready any-road piece now and
      sequencing recorder-dests behind T-018 (where the reference actually
      computes them) avoids inventing recorder rules.
- [x] Builder — the deferred pieces are documented at their call sites, so
      the next engineer sees exactly why `recorderWarpDestinations` is empty
      and where mirror lives.
- Other lenses — N/A (internal wiring + sequencing).

## Regression safety
- Contracts touched = none (a SwiftUI view's internal wiring + a model test).
  Reflected in docs = yes (`domain.md` § 6). Cross-repo consumers = none.
  Compatibility = additive (routing now uses any-roads that were previously
  ignored — strictly more-correct routes, no removed behavior).
- Full suite: 148/148 → 149/149, no regressions. `swift build` clean.

## Out of scope (tracked as follow-ons)
- T-015.6 — destination picker.
- T-015.7 — MirrorOverworld display + routing.
- T-018 — recorder-warp destinations + warp-line styling.
