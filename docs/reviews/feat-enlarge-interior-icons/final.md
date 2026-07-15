# Review: feat/enlarge-interior-icons — final (T-064)

**Status:** PASS

unanimous-consensus: T-064

## Summary
The overworld's plain interior-sprite tiles (secrets, door repair, money making
game, letter, armos, hint shop, take-any, potion) now render large and centered
instead of tiny/off-center in the reference's 5⁄16 × 9⁄11 interior region.
`TileView.interiorIconView` was split into `interiorSpriteView` (enlarged,
centered, native 5×9 aspect via `.fit`) and `shopIconView` (shops keep their
orange-plate placement). Same reference art — only scale and position changed.

## Sign-offs
- [x] Analyst — the remaining "other tiles look narrow" item from the "finish
      the upper area" request; the user explicitly chose "enlarge, same sprites."
- [x] Architect — no security surface; pure layout change.
- [x] Data Engineer — no model/atlas changes; still reads `OverworldInteriorIconAtlas`.
- [x] Backend — no logic touched; the mark→source mapping is unchanged.
- [x] Frontend — `.aspectRatio(.fit)` + nearest-neighbor keeps pixel art crisp
      and undistorted; height capped at 0.9·tile so it doesn't touch the border;
      counter-flipped under mirror like the other glyphs. Shops split out cleanly.
- [x] UX — interior tiles now match the dungeon-number / sword fidelity; the map
      reads consistently.
- [x] Test Engineer — layout-only; the full suite (306/306) stays green, build
      clean. Rendering verified on-device rather than via snapshot (no snapshot
      harness in this project).
- [x] DevOps — no infra/deps.
- [x] Review Coordinator — task filed (T-064); INDEX regenerated.

## Regression safety
- The enlarged sprite stays inside the existing `!hideMarks` gate, so "Hide tile
  icons" (T-062) and the used-dim (T-054) still apply. Shops unchanged.
- On-device: armos + the letter render large, centered, undistorted. 306/306,
  build clean.
