# Review: perf/streaming-cpu — final (T-244, T-245)

**Status:** PASS — removes the four High performance findings (overworld hover re-rendering the grid,
the extra once-a-second re-layout, per-tile 24 fps highlight clocks, per-render atlas crops) plus the
routing-graph rebuild and the panel cursor-ring re-renders. Not yet released.

unanimous-consensus: T-244
unanimous-consensus: T-245

## Sign-offs
- [x] Analyst — scoped to the audit's §3 High items plus two cheap Mediums; remaining Mediums listed below.
- [x] Architect — no model/persistence change except `TimelineModel.displaySeconds` (derived, not
      saved); observation boundaries are now explicit (`OverworldHoverState`, `FocusCursorRing`).
- [x] Data — `latestSeconds` still persisted exactly (round-trip test unchanged).
- [x] Backend — graph cache keyed on its actual inputs; hover bookkeeping `@ObservationIgnored`.
- [x] Frontend/UX — the pulse keeps its look; GYR/cursor now layer above tile glyphs (translucent;
      visual check requested); the mirror window still renders continuously (OBS capture unaffected —
      nothing pauses rendering).
- [x] SDET — `RenderCachingTests` (identical cached crops), timeline stepping test; full suite
      **826 tests pass**. View-update cost isn't unit-testable — verify with `sample`/the FPS readout
      while hovering and with an overlay locked.
- [x] DevOps — no build/release changes.
- [x] Review Coordinator — tasks filed; INDEX + CHANGELOG updated.

## Follow-ups (audit Mediums not done here)
- Compute `mapState` once per body and make `MapStateSummary` `Equatable` (breadth of invalidation).
- Grid-level popovers / one AppKit catcher instead of 3 popovers + an NSView per tile (T-145 pattern).
- Root "constant minimum size" container so a leaf update doesn't re-measure the whole tree.
- FlowLayout cache; ScaledFootprint as a one-pass Layout; downsample custom map images on import.
