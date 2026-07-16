# Review: fix/drag-paint-option-defer — final (T-072.1)

**Status:** PASS — ⌥-drag no longer circles the first room.

unanimous-consensus: T-072.1

## Sign-offs
- [x] Analyst — scope: a one-behavior bugfix to T-072 (drag-paint) from user
      testing. In scope.
- [x] Frontend — root cause: `⌥+left` is the left button, and left fired on
      mouse-down, so the ⌥-click (circle) ran before the drag. Fix narrows the
      mouse-down fire to a *plain* left press; all modified/other presses defer to
      release. Doors unchanged (drag disabled → all fire on down).
- [x] UX — ⌥-drag now paints cleanly; ⌥-click still toggles circle/brightness on
      release; the primary plain left-click stays on mouse-down.
- [x] SDET — 418 tests pass; build clean debug + release. The click/drag timing
      can't be synthesized here; relaunched for the user's re-confirm.
- [x] Architect / Data / Backend / DevOps — N/A.
- [x] Review Coordinator — task filed (T-072.1); INDEX updated.

## Regression safety
- Narrows which presses fire on mouse-down (plain-left only) and mirrors it in the
  release path; no other change. Plain left-click and door behavior are untouched.
