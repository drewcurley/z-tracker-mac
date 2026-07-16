# Review: feat/dungeon-drag-paint — final (T-072)

**Status:** PASS (live drag + right/middle-release pending user confirmation) —
drag-paint over the room grid.

unanimous-consensus: T-072

## Sign-offs
- [x] Analyst — scope: the first power tool (drag-paint); GRAB is the remaining
      one (its own slice / design pass). In scope.
- [x] Data — `dragPaint` mirrors the reference `dragBehavior` rules exactly
      (left→off-map-restore, right→paint-off, ⌥/middle→default); no-op otherwise.
      7 unit tests incl. a painted run.
- [x] Frontend — drag support is opt-in on `RoomMouseCatcher` (doors pass no
      context → unchanged). The cursor→room map uses this cell's position + grid
      pitch in a flipped view (no window-coord bridging). A 4pt threshold splits
      click from drag.
- [x] UX — matches the reference paint gestures; ⌥-drag substitutes for the
      absent middle button. **Left-click stays on mouse-down** (the primary,
      most-used gesture is untouched) — only right/middle defer to release, so the
      regression surface is minimized.
- [x] SDET — model fully tested (411 total pass); build clean debug + release; the
      grid renders with no crash after the catcher refactor. The drag + the
      right/middle mouse-up click can't be synthesized here (no drag/click
      injection), so those are flagged for the user's confirmation.
- [x] Architect — no security surface; local model mutation + AppKit input.
- [x] Backend / DevOps — N/A.
- [x] Review Coordinator — task filed (T-072); INDEX updated.

## Regression safety
- Doors: unchanged (no drag context → click-on-mouse-down path). Rooms: left-click
  unchanged on mouse-down; only right/middle moved to mouse-up (deferred). The
  drag/threshold logic is additive. If the mouse-up reasoning were wrong it would
  affect only right/middle room clicks (not left), and the user's first test
  catches it. Build clean; 411 tests pass.

## Follow-up
- User to confirm: left-drag restores off-map, right-drag paints off-map,
  ⌥-drag paints default; and that right-click (picker) / ⌥-click still work
  (they now fire on release).
- GRAB (cut/paste a dungeon segment) — the second power tool; larger + more
  complex (contiguous-region detection, move, undo), recommended as its own slice
  with a design pass.
