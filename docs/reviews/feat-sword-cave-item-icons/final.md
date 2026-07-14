# Review: feat/sword-cave-item-icons — final (T-063)

**Status:** PASS

unanimous-consensus: T-063

## Summary
Sword-cave tiles now render the high-fidelity Items-area sword sprites
(`icons7x7` wood/white/magical) instead of the reference's number-stamped
`ow_icons5x9` swords — the level is implied by the sword, so the digit is
dropped. A new `OverworldTileIconSource.swordCaveItem(Int)` carries the level;
`TileView` and `OverworldMarkIcon` render it via `ItemIconAtlas` on a dark
plate sized like the dungeon-number badge. Separately, the "Take any" submenu
(a submenu since T-057) was moved up with the other submenus in the tile
picker, where it belongs.

## Sign-offs
- [x] Analyst — both items are exactly the user's request ("use the higher-
      fidelity sword icons… the L1 L2 L3 are superfluous"; and the follow-up
      pointing at Take-any's odd placement). In scope; the broader "widen the
      other interior icons" is intentionally not bundled here.
- [x] Architect — no security surface; a rendering + menu-ordering change.
- [x] Data Engineer — the domain mapping stays in core (`iconSource`); the
      atlas choice lives in the view. `ow_icons5x9` indices 0...2 are now
      unused by the live UI (documented in the completeness test).
- [x] Backend — `swordCaveItem` is additive; out-of-range sword levels still
      resolve to `.none`.
- [x] Frontend — swords drawn on a dark plate (mirrors the Items boxes the user
      liked) at 0.82·min(tile), counter-flipped under mirror like the digit
      badge. Take-any relocated with its `.disabled(isExhausted…)` intact.
- [x] UX — sword fidelity now matches the dungeon-number/take-any tiles; the
      picker's submenu cluster is internally consistent.
- [x] Test Engineer — `OverworldTileMarkTests` updated: swords → `.swordCaveItem`,
      interior sprites Set(3...13), plus an explicit level→sprite check. 306/306.
- [x] DevOps — no infra/deps; build clean.
- [x] Review Coordinator — task filed (T-063); INDEX regenerated.

## Regression safety
- Additive icon-source case; `iconSource` completeness re-proven by the updated
  test (digits, shop 0...7, interior 3...13, swordCaveItem 1...3 all covered).
- On-device: placed wood/white sword caves — render as the Items sprites with
  no number; Wood Sword correctly disabled once placed; Take-any grouped with
  the submenus. Full suite 306/306, build clean.
