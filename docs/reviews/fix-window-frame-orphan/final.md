# Review: fix/window-frame-orphan — final (T-046.2)

**Status:** PASS — window frame restore no longer orphans the window when its
saved display is disconnected.

unanimous-consensus: T-046.2

## Sign-offs
- [x] Analyst — scope: robustness fix to T-046.1 exposed when the pinned external
      display vanishes. Single behavioral change (re-home an orphaned frame); no
      new feature surface. In scope.
- [x] Frontend — `WindowFrameClamp` (pure CGRect geometry) + a two-line change in
      `restore()`. The happy path (reachable frame) is returned byte-identical, so
      the normal restore is unchanged.
- [x] SDET — 8 unit tests cover reachable / disconnected / sliver / re-home /
      size-clamp / headless / unchanged. Geometry extracted specifically to be
      testable without AppKit. On-device: window still restores to its saved
      external-display spot. 361 tests pass; build clean debug + release.
- [x] Architect — no security surface; local UserDefaults + window geometry only.
- [x] UX — an orphaned window (invisible, un-grabbable) is a hard usability
      failure; re-homing centered on the primary while keeping the user's size is
      the least-surprising recovery.
- [x] Backend / Data / DevOps — N/A (no server / schema / CI-affecting change).
- [x] Review Coordinator — task filed (T-046.2); INDEX updated.

## Regression safety
- Reachable frames pass through unchanged (covered by `reachableUnchanged`), so
  the only behavior change is for frames that would otherwise restore off-screen.
  On-device confirmed the normal restore path is intact.
