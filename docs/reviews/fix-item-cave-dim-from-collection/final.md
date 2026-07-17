# Review: fix/item-cave-dim-from-collection — final (T-110)

**Status:** PASS — item caves dim from collection, matching the reference.

unanimous-consensus: T-110

## Sign-offs
- [x] Analyst — fixes the two reported bugs (#3 map dim, #4 spot-summary dim); scope
      held to the three item caves + placement defaults.
- [x] Architect — derives visual state from the single source of truth (item boxes /
      player sword), removing a duplicated, drift-prone map `used` flag.
- [x] Data — `isUsedToggleable` now equals the reference `toggleables` set exactly;
      `SpotSummary.compute` gains `armosDone`/`whiteSwordItemDone`/`hasMagicalSword`
      (defaulted, so existing call sites/tests are source-compatible).
- [x] Frontend — `tileIsCollected` centralizes the map dim; call site passes model
      state to the summary.
- [x] UX — placement defaults match the reference (secrets/letter/hint dark;
      take-any/wood-sword bright), so nothing dims before it's collected.
- [x] Backend — no server logic.
- [x] SDET — updated the toggleable + spot-summary tests; added `derivedCavesDone`.
      467 tests pass; build clean.
- [x] DevOps — no infra impact.
- [x] Review Coordinator — task filed (T-110); INDEX updated.

## Regression safety
- Secrets / letter / hint-shop / wood-sword-cave / take-any behavior unchanged. The
  three derived caves no longer read the map `used` flag (a stale no-op path removed).
  Full suite green.
