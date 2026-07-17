# Review: fix/groundhog-hotkey-startlap — final (T-132.1)

**Status:** PASS — groundhog hotkey now matches the button.

unanimous-consensus: T-132.1

## Sign-offs
- [x] Analyst / Frontend / UX — the hotkey now restarts the lap like "Reset (keep maps)".
- [x] Backend — added `timer.startLap()`; reset logic unchanged (tested).
- [x] Architect / Data / SDET / DevOps — one-line dispatcher fix; 503 tests pass; build clean.
- [x] Review Coordinator — task filed (T-132.1); INDEX updated.

## Regression safety
- Only the Groundhog dispatch case changed; other globals untouched.
