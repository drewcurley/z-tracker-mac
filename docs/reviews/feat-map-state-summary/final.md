# Review: feat/map-state-summary — final

**Status:** PASS

**Process note:** solo project (`playbook/AGENTS.md` §12) — one operator
reviewed sequentially wearing each of the 9 hats.

## Blockers (must fix before merge)
- none

## Warnings (fix before next review)
- [ ] `MapStateSummary` is computed but not yet *rendered* — T-015.4 consumes
      `owGettableLocations`/`sometimesEmpty` for the GYR cascade, and adds
      the `TrackerModel`/view wiring. No view change here by design.
- [ ] `mirrorOverworld` is a `compute(...)` parameter with no live source
      yet; callers pass `false` until T-015.5 models `MirrorOverworld`. The
      single code path it gates (coast-island `[15,2]`) is already tested
      with the flag both ways.

## Suggestions (consider for polish)
- When T-015.4 wires this into a view, add a `TrackerModel` convenience that
  builds the `OverworldInstance` from `quest` and threads the option flags,
  so the view doesn't assemble eight arguments inline.

## Agent Sign-offs
- [x] Analyst — scope matches T-015.3: the `MapStateSummary` type + the 8
      discovery flags + the recompute + scenario tests. No rendering, no
      picker, no placeholder wiring (those are .4/.5/.6). Consumes only
      already-shipped state (T-015.1 instance, T-015.2 bridge/extra-data,
      T-012–T-014 player state).
- [x] Architect — no security surface; pure value derivation, no globals
      (every reference global is an explicit parameter). `ScreenBoolGrid`'s
      bounds preconditions make out-of-range indexing a hard failure, not a
      silent wrong answer.
- [x] Data Engineer — the recompute is transcribed branch-for-branch against
      `TrackerModel.fs:1035-1143`: the raw-index `match` order, the per-mark
      routeworthy rules (dungeon-incomplete, dungeon-9-all-triforce, sword3
      `hearts>=10`, sword2 `hearts>=4`, armos-box-not-done), the empty-spot
      cannot-uncover disjunction (whistle/bracelet/ladder/raft/bomb/burn),
      the coast-island `[15,2]` exception, the DARK_X un-revealed count, the
      shop primary-or-second-item discovery, the potion-letter toggle, the
      `isInteresting` quest-only marks, and the final coast-item `[15,5]`
      override. The White-Sword TODO at `:1071` is preserved as
      unimplemented (matching the reference).
- [x] Backend — N/A (no server); `compute(...)` is a pure function.
- [x] Frontend — N/A (no UI this sub-task).
- [x] UX — N/A.
- [x] Test Engineer — 12 scenario tests. The empty-first-quest **count pins**
      (owSpotsRemain 73 = 128−55 always-empty; gettable/routeworthy 28 =
      nothingable screens; whistle 1; bracelet 4) are computed independently
      from the reference masks and exercise terrain-masks + raw-index bridge
      + recompute end-to-end — a mistranscription anywhere shifts a count.
      Plus per-mark scenarios (dungeon/sword/armos routeworthy gating, shop
      second-item discovery, potion letter, both coast rules). 142/142 total.
- [x] DevOps — no CI/deploy changes; `swift build` + `swift test` clean.
- [x] Review Coordinator — process followed; `domain.md` § 6 + umbrella
      `T-015.md` table + `tasks/T-015.3.md` updated; INDEX regenerated.

## Lens Sign-offs (routine port — no new major decision)
- [x] Builder — folding the 8 `EventingBool` discovery flags + the location
      arrays into one immutable, `@Observable`-derived value is simpler and
      thread-safe versus the reference's mutable global + event fan-out, with
      identical output.
- Other lenses — N/A (internal derivation).

## Regression safety
- Contracts touched = none (in-process model types, not registered in
  `contracts.md`). Reflected in docs = yes (`domain.md` § 6). Cross-repo
  consumers = none. Compatibility = additive-only (two new types).
- Full suite: 130/130 → 142/142, no regressions. `swift build` clean.

## Out of scope (tracked as follow-ons)
- T-015.4 — true GYR rendering (first consumer of `owGettableLocations`).
- T-015.5 — live mirror/warp/any-road wiring (`mirrorOverworld` source).
- T-015.6 — destination picker.
