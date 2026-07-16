# Review: feat/dungeon-oldmen-layout — final (T-080)

**Status:** PASS — old-man counter is a single line with the icon, below the row-locator.

unanimous-consensus: T-080

## Sign-offs
- [x] Analyst — a layout tweak from user feedback. In scope.
- [x] UX — matches the reference's single-line `[old-man icon] X/Y`; stacking below
      the row-locator removes the wonky side-by-side.
- [x] Frontend — `DungeonMonsterAtlas.oldMan` (sheet index 11) + a restructured
      info-strip VStack. No logic change.
- [x] SDET — build clean debug + release; on-device verified (icon + 0/1 on one
      line). Tests unaffected.
- [x] Data / Architect / Backend / DevOps — N/A.
- [x] Review Coordinator — task filed (T-080); INDEX updated.

## Regression safety
- Layout-only; the count value (`oldManText`, T-074) is unchanged. Build clean.
