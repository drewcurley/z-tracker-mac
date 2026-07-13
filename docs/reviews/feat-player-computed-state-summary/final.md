# Review: feat/player-computed-state-summary — final

**Status:** PASS

**Process note:** solo project (`playbook/AGENTS.md` §12) — one operator
reviewed sequentially wearing each of the 9 hats.

## Blockers (must fix before merge)
- none

## Warnings (fix before next review)
- [ ] **Behavior change (intended, parity-correct):** the overworld routing
      graph now reads live `haveLadder`/`haveRaft` (both `false` on a fresh
      game) instead of T-011's hardcoded `true` placeholders. A brand-new
      game therefore shows *fewer* routes (no ladder/raft crossings) until
      those items are marked — which is exactly what the reference's
      `OverworldRouteDrawing` does. Called out so it isn't mistaken for a
      regression.
- [ ] No save/load for `isWSMSReplacedByBU` yet — consistent with the rest
      of `TrackerModel` (no persistence task has run); not a new gap.

## Suggestions (consider for polish)
- `PlayerHasTheBook()` and the `IsCurrentlyBook`/`IsBookAnAtlas` flags land
  with their real consumers (`PlayerCanSeeMapOfThisDungeon`, dungeon-map
  reveal, announcements) rather than being added unconsumed now — revisit in
  T-015/T-016/T-018.

## Agent Sign-offs
- [x] Analyst — scope matches T-014's acceptance criteria: all 16 fields,
      faithful recompute, known-scenario tests, and the T-011 ladder/raft
      placeholder replacement (criterion #4). **Grounded scope correction,
      surfaced not silently applied:** the recompute branches on only
      `IsWSMSReplacedByBU`, not the "three flags" the task text names — the
      other two gate deferred helpers, so adding them now would be
      unconsumed state. Documented in `domain.md` § 6 and the code.
- [x] Architect — no security surface. One design call: derive the summary
      as an `@Observable`-tracked computed value instead of the reference's
      mutable global + manual `recompute()`; removes a global and the event
      plumbing, behavior identical.
- [x] Data Engineer — the derivation is transcribed predicate-for-predicate
      against `recomputePlayerStateSummary()` (`TrackerModel.fs:865-958`):
      box-scan `ITEMS.*` cases (`:872-912`), progress flags (`:913-922`),
      starting items (`:923-948`), standalone-box done-checks (`:949-952`),
      hearts (`:953-956`). `ITEMS` indices pinned value-for-value against
      `:179-208`. The White-Sword/Magical-Sword × WSMS-as-BU asymmetry
      (starting-item always counts; box/progress suppressed) verified
      against `:911`/`:924` and covered by dedicated tests.
- [x] Backend — N/A (no server); `compute(...)` is a pure function over its
      inputs, `TrackerModel.playerComputedStateSummary` a thin convenience.
- [x] Frontend — `OverworldMapView` gains a `playerState` parameter fed by
      `model.playerComputedStateSummary`; because that computed reads
      `@Observable` inputs, the map re-derives routes when a box/starting-
      item/progress flag changes. `#Preview` and the one call site updated.
- [x] UX — the only user-visible effect is more-accurate routing (fewer
      false routes on a fresh game); no new controls.
- [x] Test Engineer — 13 new tests: `ITEMS` index pinning; fresh defaults;
      full box-item scan; `.yes`-only possession; hearts arithmetic
      (containers + take-any-heart raw-1-only + differential); level max
      semantics; both magical-sword paths × WSMS; both white-sword paths ×
      WSMS; standalone coast/white-sword-item boxes; every starting-item
      mapping; magic-boomerang precedence; `TrackerModel` convenience ==
      direct compute. 114/114 total passing.
- [x] DevOps — no CI/deploy changes; `swift build` + `swift test` clean.
- [x] Review Coordinator — process followed; `domain.md` § 6 (T-014 bullet +
      the routing-placeholder note) updated; `tasks/T-014.md` criteria
      checked off with evidence.

## Lens Sign-offs (routine port — no new major decision)
- [x] PM — kept to T-014; did not start T-015's shop/cave/GYR work.
- [x] Builder — modeling the summary as an immutable `Equatable` value +
      pure `compute` (vs. the F# mutable global) makes it trivially testable
      and thread-safe, no behavior change.
- Other lenses — N/A (internal derivation, one parity-correct behavior
  change already covered above).

## Regression safety
- Contracts touched = none (`docs/contracts.md` is persistence/integration/
  security-scoped; in-process model types are not registered there,
  consistent with T-012/T-013). Reflected in docs = yes (`domain.md` § 6).
  Cross-repo consumers = none (single active repo). Compatibility =
  additive-only (new types + one new optional `TrackerModel` init parameter
  with a default + one new required `OverworldMapView` parameter, all call
  sites updated).
- Full suite: 101/101 → 114/114, no regressions. `swift build` clean.
- The routing behavior change is exercised by the existing pathfinding tests
  (which take `ladder`/`raft` as explicit inputs) and the new derivation
  tests; the view wiring compiles and both call sites are updated.

## Out of scope (tracked as follow-ons)
- T-015 — shop/cave discovery + `MapStateSummary` recompute + true GYR +
  destination picker + `MirrorOverworld` wiring + item-picker UI (with the
  deferred `ChoiceDomain`/`Cell`).
- T-016 — HDN mode + `IsBookAnAtlas`/`PlayerCanSeeMapOfThisDungeon`.
- T-018 — `IsCurrentlyBook`/`PlayerHasTheBook` in announcements.
