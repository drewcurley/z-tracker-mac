# Review: feat/hdn-lettered-dungeons — final (T-016.3)

**Status:** PASS

unanimous-consensus: T-016.3

## Summary
The HDN color-assignment feature. Reading the reference first **corrected the
task's premise**: the overworld dungeon tile keeps the fixed A–H slot letter
(already shipped), while the player-assigned **color + real number** live on the
tracker. Added `DungeonColorPalette` (42 swatches + `isBlackGoodContrast`,
ported verbatim), a 3×14 color grid in the HDN dungeon chooser popover, and
color-aware rendering of the dungeon card's number chip (glyph black/white by
contrast). `Dungeon.color` — previously written-once dead state — is now both
assignable and rendered.

## Sign-offs
- [x] Analyst — scope corrected against the reference (the overworld does NOT
      take the player color/number; that was the whole point of the "read the
      reference first" criterion). Delivered the genuinely-missing half (color).
- [x] Architect — no security surface; pure display + palette data.
- [x] Data Engineer — palette is pure `0xRRGGBB` ints in `TrackerCore`, unit-
      tested for shape/layout/contrast; consumes existing `Dungeon.color`.
- [x] Backend — no logic paths changed; `labelChar` consumers untouched.
- [x] Frontend — color grid reuses the existing chooser popover; the chip
      renders `Color(rgb:)` background + contrast glyph, mirroring the
      reference's `alphaNumOnTransparentBmp` + `isBlackGoodContrast`. Color-
      select is live (no dismiss) so color+number can be set in either order.
- [x] UX — the swatch grid matches the reference's dark/medium/light layout;
      the assigned color reads at a glance on the card. `?` stays a muted
      placeholder so the chip is still tappable when unset.
- [x] Test Engineer — 3 palette tests (shape, row layout, contrast incl. the
      dark→white branch). 316/316 pass, build clean. Rendering verified
      on-device (no snapshot harness in this project).
- [x] DevOps — no infra/deps.
- [x] Review Coordinator — task filed (T-016.3 → completed, premise corrected);
      green-warp overworld variant filed as follow-up T-016.4; INDEX regenerated.

## Seven lenses (major decision — HDN feature scope)
- **CEO / Marketing:** faithful HDN support broadens the "1:1 clone" claim; the
  correction (color on tracker, not map) keeps parity honest.
- **Product:** shipped the missing half (color) rather than the mis-specified
  half (colored map tiles); smaller, correct, in scope.
- **Developer:** palette is testable pure data; the change is additive.
- **Middle-management / Investor / Purchasing:** N/A for a solo tracker port.

## Regression safety
- Additive: new `DungeonColorPalette` type, a new popover section, and a chip
  rendering change gated on the assigned color (unset → prior neutral look).
- Full suite 316/316, build clean. On-device: color+number assign and render
  correctly with contrast.
