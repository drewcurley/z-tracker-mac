# Review: feat/dungeon-vanilla-outlines — final (T-071)

**Status:** PASS — FQ/SQ vanilla dungeon-outline overlays (global toggle).

unanimous-consensus: T-071

## Sign-offs
- [x] Analyst — scope: activate the FQ/SQ placeholders as the reference's vanilla-
      footprint overlay. In scope. Per user feedback, the toggle is global (not
      per-dungeon).
- [x] Data — the 18 layouts are transcribed verbatim from `DungeonData.fs:72-290`;
      a test asserts each quest is 9 dungeons × 8×8 of only `X`/`.`, plus spot-
      checks against known cells. No invented data.
- [x] Frontend — `VanillaOutlineOverlay` is a `Canvas` in the room grid's exact
      coordinate system (same cell/gap), `allowsHitTesting(false)` so it never
      blocks room/door input. Global `outlineMode` @State passed to the current
      dungeon grid.
- [x] UX — MediumPurple boundary lines + a light wash on non-room cells match the
      reference; rooms stay clear so the user's marks read through; the active
      FQ/SQ button is highlighted. A single global toggle (user's call) keeps it
      simple and follows the selected tab.
- [x] SDET — 4 data tests (well-formed, spot-checks, out-of-range, room counts);
      404 total pass; clean debug + release. On-device: the FQ overlay rendered
      L1's footprint correctly (verified via a temporary default, removed).
- [x] Architect — no security surface; static data + a Canvas.
- [x] Backend / DevOps — N/A.
- [x] Review Coordinator — task filed (T-071); INDEX updated.

## Regression safety
- Additive: a data file + an overlay view + button wiring; the overlay is a
  non-interactive top layer, so rooms/doors are unaffected. Temp render-check
  default confirmed removed. Build clean; 404 tests pass.

## Follow-up
- Optionally render the outline on the Summary tab's mini-maps too (fullest sense
  of "all dungeons"); deferred to keep this slice focused.
