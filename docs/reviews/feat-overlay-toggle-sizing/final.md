# Review: feat/overlay-toggle-sizing — final (T-035.12)

**Status:** PASS — Info overlay toggles resized to item-icon size, reflowed to 3×2.

unanimous-consensus: T-035.12

## Sign-offs
- [x] Analyst — scope: purely visual sizing/layout of the six existing overlay
      toggles per user request ("make them the same size as the item icons…
      break it up into two rows"). No behavior change. In scope.
- [x] Frontend — `overlayToggles` HStack→`Grid` with two `GridRow`s of three;
      `overlayToggle`/`progressToggle` cells now `itemGridCellSize` (34×34) with
      glyphs scaled (SF 12→18, atlas 15→22, radius 4→6). Reuses the existing
      `itemGridCellSize` constant so the tiles track the item cells if that
      changes.
- [x] UX — the toggles now read as first-class clickable icons matching the
      Items group, and the 3×2 block is a tidier shape in the Info column than a
      long single row. Hover-preview / click-lock affordances unchanged.
- [x] SDET — full suite 331/331 (pure layout change; no logic to unit-test
      beyond existing view tests). On-device verified: tiles render item-sized in
      two rows; a zoom confirms parity with the Items cells.
- [x] Data / Backend / Architect / DevOps — N/A (view-only).
- [x] Review Coordinator — task filed (T-035.12); INDEX updated.

## Regression safety
- Cosmetic only: frame sizes, glyph sizes, and container (HStack→Grid). Overlay
  hover/lock and the Progress-window toggle are untouched. Build clean debug +
  release, 331/331.
