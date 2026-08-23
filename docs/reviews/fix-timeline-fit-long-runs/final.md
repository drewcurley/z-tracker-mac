# Review: fix/timeline-fit-long-runs — final (T-209)

**Status:** PASS — the timeline now fits the whole run to the pane instead of overflowing a
fixed-scale scroll view. User QA confirms the full run is visible and rescales live with the
window. Ships as v0.9.1.

unanimous-consensus: T-209

## Root cause
Fixed **26 px/min** in a horizontal `ScrollView`: a 2h16m run was ~3,600 px wide, so only the
first ~40 min showed and the rest sat off-screen, unscrolled — it read as broken though the data
was intact (autosave held all 42 events out to 132 min).

## Fix (`GameTimelineView`)
- **Fit-to-width** `pxPerMinute` (cap 26, floor 6), width measured via a background
  `GeometryReader` on the outer frame — no feedback loop, rescales live on resize.
- **Adaptive axis** step (1→2→3→5→10…) keeping minor lines ≥14px / labels ≥48px; major lines
  drawn in a second pass so they always land on labels.
- **Proximity icon stacking** (icon-width of run-time) so a compressed run doesn't smear.

## Sign-offs
- [x] Analyst — scope is the reported bug only; no behavior change for short runs.
- [x] Architect — width read on the outer frame (not content) avoids a GeometryReader/ScrollView
      layout loop; scale is pure-derived from measured width + `maxMinute`.
- [x] Backend / Data — n/a (view-only; timeline data + save format untouched).
- [x] Frontend — cap/floor keep short runs identical and cap the compression; live resize works.
- [x] UX — the whole run is visible at a glance with a legible, scaling axis (the user's ask).
- [x] SDET — **739 tests pass**; verified against a 42-event ~135-min save fixture (the original
      run's autosave was overwritten and the box has no root to mount the TM snapshot holding it).
- [x] DevOps — clean build/test; dual-arch DMGs cut for v0.9.1.
- [x] Review Coordinator — T-209 filed; INDEX updated; VERSION → 0.9.1.

## Items to address (follow-ups)
- None. (A pure-function extraction of the fit/step math would make it unit-testable; deferred —
  it's simple and the view exercises it.)
