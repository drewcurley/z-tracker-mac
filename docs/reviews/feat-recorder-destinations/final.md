# Review: feat/recorder-destinations — final (T-035.7)

**Status:** PASS

unanimous-consensus: T-035.7

## Summary
A recorder-destination tracker: `RecorderDestinations.compute` (ported verbatim
from `TrackerModel.fs:1606-1619`) yields the ordered available warp screens, and
a below-map `RecorderDestinationBar` is the single place to see the current one,
with ◄ ► arrows stepping the whistle count and a lone diamond marking the
current destination on the map. Two checkboxes ("to new dungeons" / "to unbeaten
dungeons") drive availability.

## Design correction (mid-build)
v1 marked every available destination with a diamond, forcing a map scan. On
user feedback (matching the reference), reworked to: one below-map stepper as
the single place to look, and at most one diamond on the *current* destination.
Confirmed the set keys off `playerHasTriforce`, not `isComplete`.

## Sign-offs
- [x] Analyst — matches the corrected user intent (single-place stepper, no
      scatter). Routing-graph integration intentionally out of scope (routing
      deprioritized); this delivers the tracker + markers.
- [x] Architect — no security surface.
- [x] Data Engineer — compute reads `playerHasTriforce` + `mapState.dungeonLocations`;
      HDN maps level→dungeon via `labelChar`, exactly like the reference.
- [x] Backend — `haveRecorder` is the real possession (`PlayerComputedStateSummary`),
      not the preserved TAG mirror. Index wraps against the live list.
- [x] Frontend — the bar lives below the map; `recorderDestination` (single
      current coord) threads into `TileView`; the diamond is a lone corner mark.
- [x] UX — one fixed place to read the destination (dungeon label + coord +
      n/total); arrows model whistling; settings behind a compact button.
- [x] Test Engineer — 4 compute tests across all checkbox combos (no-recorder,
      beaten+new, unbeaten+new, beaten+vanilla). 324/324 pass, build clean.
- [x] DevOps — no infra/deps.
- [x] Review Coordinator — task filed (T-035.7); INDEX regenerated.

## Regression safety
- New pure type + model flags/index + a below-map view + one map-overlay
  branch. The map shows nothing extra unless a current destination exists.
- On-device (with the user): recorder + 3 triforce'd dungeons → the stepper
  cycles all three, one diamond on the current (Dungeon 6, C3, 3/3).

## Notes
- Perf: user saw the app **beachball** under rapid automated input; the map
  recomputes `MapStateSummary` several times per body eval (pre-existing) and
  this adds a couple more via `recorderDestinations`. Flagged for a perf pass.
