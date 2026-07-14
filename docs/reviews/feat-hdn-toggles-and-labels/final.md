# Review: feat/hdn-toggles-and-labels — final (T-049)

**Status:** PASS — flag relocation + HDN wiring/labels (chooser deferred to T-050).

unanimous-consensus: T-049

## Sign-offs
- [x] Analyst — scope: move the two toggles to Flags + make HDN real (labels +
      3 boxes). The dungeon-number *chooser* is explicitly split to T-050 so this
      PR stays focused. In scope.
- [x] Data — `hideDungeonNumbers` now drives `dungeonTracker.kind`: `setHide-
      DungeonNumbers` rebuilds the instance (3-box HDN vs 2-box default),
      preserving `isSecondQuestDungeons` and re-seeding floor hearts.
      `setHeartShuffle` re-applies `applyFloorItemHearts`. Rebuild-on-toggle
      resets dungeon progress, which is correct for a structural seed change.
- [x] Frontend — `dungeonTracker` is now `private(set) var`; views read it fresh
      so the rebuild propagates. `DungeonLabeling.slotLabel` centralizes the
      A–H↔number mapping, reused by the dungeon cards, the map digit badge, and
      the mark menu. HDN hides the hint (its slot is the future chooser).
- [x] UX — the toggles live with the other seed flags now that the timer no
      longer auto-starts; A–H labels are consistent across the dungeon area and
      overworld; Level 9 stays "9".
- [x] Backend — the setters are small and idempotent (`setHideDungeonNumbers`
      guards on no-change).
- [x] Test Engineer — `DungeonLabelingTests`: slot labels (off/HDN/Level 9),
      HDN rebuild → 3 boxes and back, 2Q-preserved, heart-shuffle re-seed.
      289/289. On-device: startup toggles gone; Flags has both; HDN → A–H + 3
      boxes + hint hidden; selector shows Dungeon A–H + Level 9; map badge "C".
- [x] Architect / DevOps — N/A; no infra/security surface.
- [x] Review Coordinator — task filed (T-049); INDEX updated.

## Regression safety
- Off by default (both flags false → `.default` tracker, numeric labels,
  identity slotLabel). The rebuild only fires on an actual HDN change. Full suite
  289/289, build clean debug + release.
