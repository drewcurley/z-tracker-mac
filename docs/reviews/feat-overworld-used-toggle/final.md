# Review: feat/overworld-used-toggle — final (T-054)

**Status:** PASS — claimable-tile used-state + Spot Summary integration.

unanimous-consensus: T-054

## Sign-offs
- [x] Analyst — scope: a used/unused left-click toggle for claimable overworld
      tiles, feeding the Spot Summary. Set follows the reference's `toggleables`
      minus the sword cave, plus armos + letter (user). In scope.
- [x] Data — `isUsed`/`toggleUsed` reuse the existing `extraData` store at the
      mark's own raw index (`extraData[state] == state`), exactly the reference's
      convention; keys (24–33) don't collide with `shopExtraDataKey(16)` or
      `DARK_X(35)`. `SpotSummary` counts placed vs used; remaining = total − used.
- [x] Frontend — left-click routes claimable marks to `toggleUsed` (else the
      existing unmarked→dontCare); `TileView` dims used tiles; the summary uses a
      3-state opacity for the two claimable uniques. `OverworldMarkIcon` unchanged.
- [x] UX — dimming the tile (dark overlay + darkened icon) reads as "done"; the
      redundant checkmark was dropped per feedback. Summary legend spells out
      to-find / found / collected.
- [x] Backend — pure grid mutations; no timer/model coupling.
- [x] Test Engineer — `SpotSummaryTests` extended: placement vs used, used
      reduces remaining, toggle-off restores, non-toggleable can't be used.
      298/298. On-device: take-any dims on left-click; a collected large secret
      drops Large 3→2 in the summary.
- [x] Architect / DevOps — N/A.
- [x] Review Coordinator — task filed (T-054); INDEX updated.

## Regression safety
- Additive: left-click on non-claimable marked tiles is unchanged; used defaults
  false everywhere. Full suite 298/298, build clean debug + release.

## Note
- Groundhog reset currently keeps `extraData` (map knowledge), so used-state
  persists across it. Whether a groundhog replay should clear collected-state is
  a separate call — deferred, not silently decided here.
