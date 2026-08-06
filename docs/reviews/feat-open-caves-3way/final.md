# Review: feat/open-caves-3way — final (T-189)

**Status:** PASS — the open-caves overlay is now a 3-way toggle. QA-approved ("looks good").

unanimous-consensus: T-189

## What shipped
- `OverworldOverlayState.openCavesMode` (off / openCaves / allGettable); `toggleLock`
  cycles open caves, binary for the rest. `effectiveOpenCavesMode` folds in hover-preview.
- `OverworldMapView.overlayHighlight` returns a border `Color?` — green for money +
  open-caves-only; orange for all-gettable (`owGettableLocations`).
- Overlay toggle icon tints grey → green → orange to show the mode.

## Sign-offs
- [x] Analyst — matches the request exactly (3-way, distinct color for gettable, hover preview).
- [x] Architect — state is a small enum cycle; the map read (`owGettableLocations`) already existed.
- [x] Data — n/a; gettable set comes from the existing `MapStateSummary`.
- [x] Backend — cycle + effective-mode logic is pure and unit-tested.
- [x] Frontend / UX — icon reflects the mode; green/orange distinct from the cyan cursor. Verified.
- [x] SDET — `OverworldOverlaysTests`: full cycle + hover-preview + effective mode. **722 tests pass.**
- [x] DevOps — no infra; clean build/test; `.app` rebuilt.
- [x] Review Coordinator — task filed (T-189); INDEX updated.

## Items to address (follow-ups)
- The all-gettable color (orange) is a one-line change if a different hue is preferred.
