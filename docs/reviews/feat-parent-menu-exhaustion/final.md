# Review: feat/parent-menu-exhaustion — final (T-059)

**Status:** PASS — small follow-on to T-058.

unanimous-consensus: T-059

## Sign-offs
- [x] Analyst — scope: disable the parent submenu when all children are
      exhausted. Exactly the user's follow-up. In scope.
- [x] Frontend — `allExhausted(_:)` = `allSatisfy(isExhausted)`; `.disabled` on
      the Dungeon / Any road / Sword cave menus. Built on the verified
      `isExhausted` + unit-tested `maxUses`.
- [x] UX — you can no longer open a submenu with nothing selectable; the whole
      group greys out when full.
- [x] Test Engineer — the underlying limits are covered by
      `OverworldClaimCorrectnessTests` (T-058); the parent-disable is view glue,
      verified on-device (Sword cave parent greys after all 3 sword caves). 304/304.
- [x] Data / Backend / Architect / DevOps — N/A.
- [x] Review Coordinator — task filed (T-059); INDEX updated.

## Regression safety
- Additive `.disabled` on three menus over already-verified logic; unbounded
  groups (shops/secrets) never trigger. Full suite 304/304, build clean.
