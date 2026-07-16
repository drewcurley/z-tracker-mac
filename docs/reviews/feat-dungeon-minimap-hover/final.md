# Review: feat/dungeon-minimap-hover — final (T-079)

**Status:** PASS (live hover pending user) — faux in-game HUD minimap on hover.

unanimous-consensus: T-079

## Sign-offs
- [x] Analyst — scope: the minimap hover-reveal the user clarified. In scope.
- [x] Data — lit rule mirrors the reference (`not IsEmpty` for the normal board;
      `not OffTheMap` for the inverse); blue RGB 71,47,228; blocks at the 8×4 pitch.
- [x] UX — a `LEVEL-N` + blue-block map reads as the in-game dungeon map for a
      quick "does it match?" check; the inverse shows the carved shape when you've
      painted off-map. Reveal on hover of a small thumbnail, per the user.
- [x] Frontend — `Canvas` draws the blocks; hover → `.popover`. Reads the live
      `DungeonRoomMap` (@Observable) so it reflects current marks. Additive.
- [x] SDET — 423 tests pass; clean debug + release. On-device verified via a temp
      force-open + seed (removed): inverse + normal boards render correctly. Live
      hover can't be synthesized — flagged.
- [x] Architect / Backend / DevOps — N/A.
- [x] Review Coordinator — task filed (T-079); INDEX updated.

## Regression safety
- Additive: two new views + a thumbnail in the info strip. Temp force-open + seed
  confirmed removed (`grep TEMP` clean). Build clean; 423 pass.

## Follow-up
- Popover-on-hover can flicker if you move onto it; if the user finds it fiddly,
  switch to a side overlay anchored to the icon.
