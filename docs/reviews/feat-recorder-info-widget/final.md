# Review: feat/recorder-info-widget — final (T-081)

**Status:** PASS — recorder destination relocated to the Info group with
triforce-based, placement-independent logic.

unanimous-consensus: T-081

## Sign-offs
- [x] Analyst — matches the user's 4-part spec (location, representation,
      triforce-based logic, darkened/no-default/lowest/manual). In scope.
- [x] Architect — pure model logic in TrackerCore; no security surface.
- [x] Data — `infoEntries` reuses the same triforce filter as the faithful
      `compute` port; only the located-gating differs (deliberately).
- [x] Backend — `selectedEntry` centralizes selection so the widget and the map
      marker derive identically from model state (no divergence).
- [x] Frontend — `RecorderInfoWidget` (compact `◄ icon ► N coord`); greyscale via
      opacity+saturation; arrows disabled when not steppable.
- [x] UX — sits under the six overlay icons as requested; help text per state.
- [x] SDET — 7 recorder tests pass (3 new: unplaced listing, auto/manual/wrap,
      empty→nil, i.e. no default). Build clean debug + release; darkened default render-verified.
- [x] DevOps — no infra change. Old `RecorderDestinationBar` deleted (no dead code).
- [x] Review Coordinator — task filed (T-081); INDEX updated.

## Notes
- `RecorderDestinations.compute` (the reference-faithful map-highlight port) is
  retained and still unit-tested; the new widget uses `infoEntries` instead.
- There is **no default destination**: before a triforce is obtained the
  recorder's target is genuinely unknown (you don't know which dungeon dropped
  it), so the widget shows `0` rather than a placeholder number. The reference has
  no numbered stepper — it highlights warp spots on the map.

## Regression safety
- Item/map behavior unchanged; only the recorder readout moved and its selection
  rule changed. Full build clean.
