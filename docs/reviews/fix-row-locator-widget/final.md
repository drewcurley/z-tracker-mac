# Review: fix/row-locator-widget — final (T-078.1)

**Status:** PASS (live hover pending user) — row-locator rebuilt per the reference + screenshots.

unanimous-consensus: T-078.1

## Sign-offs
- [x] Analyst — scope: correct T-078's design to the reference/screenshot (always-on
      icons + info-strip widget). In scope.
- [x] UX — icons omnipresent by the old-man counter; the hover reveals only the
      row marker — matching the Windows app the user showed.
- [x] Frontend — `hoveredRow` lifted to `DungeonMapView` (binding into the grid);
      `RowLocatorWidget` renders the always-on icon column + hover marker. The
      grid's reserved strip + full-row bar are removed (width back to prior).
- [x] SDET — 423 tests pass; clean debug + release. On-device: always-on icons +
      forced-hover marker at the correct band. Live hover can't be synthesized.
- [x] Data / Architect / Backend / DevOps — N/A.
- [x] Review Coordinator — task filed (T-078.1); INDEX updated.

## Regression safety
- Replaces the T-078 grid strip with an info-strip widget; grid geometry reverts to
  pre-T-078. `onHover` per cell still falls through the mouse catcher (button-downs
  only), so clicks/scroll/drag are unaffected.
