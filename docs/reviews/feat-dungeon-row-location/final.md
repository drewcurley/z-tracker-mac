# Review: feat/dungeon-row-location — final (T-078)

**Status:** PASS (live hover pending user) — rupee/key/bomb row-locator.

unanimous-consensus: T-078

## Sign-offs
- [x] Analyst — scope: the row-location assist (audit #18) as a hover reveal per
      the user. The minimap hover (the related feature) is the next slice.
- [x] Frontend — reserved strip folded into `contentWidth` (no layout shift);
      `onHover` per cell falls through the mouse catcher (button-downs only), so
      clicks/scroll/drag are unaffected. Icons reuse the floor-drop atlas.
- [x] UX — matches the reference row bands; a hover reveal (not always-on) per the
      user; full-row highlight makes the row obvious.
- [x] SDET — 423 tests pass; clean debug + release. On-device verified via a
      forced hover (icons + highlight). Live hover can't be synthesized — flagged.
- [x] Data / Architect / Backend / DevOps — N/A.
- [x] Review Coordinator — task filed (T-078); INDEX updated.

## Regression safety
- Additive: a reserved strip + hover-gated overlay + an `onHover`. The grid width
  grew by the strip (map-width cap recomputes); rooms/doors/gestures unchanged.

## Follow-up
- Minimap hover-reveal (faux in-game HUD map of marked rooms) — the related slice.
