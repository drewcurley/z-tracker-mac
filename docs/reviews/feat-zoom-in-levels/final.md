# Review: feat/zoom-in-levels — final (T-230)

**Status:** PASS — adds 110% and 120% zoom-in levels to the universal "Tracker zoom" picker (now
120/110/100/90/80/70/60%). User QA'd and approved. Ships as notarized **v1.2.8**.

unanimous-consensus: T-230

## What shipped
- Two new "Tracker zoom" options — **110%** and **120%** — for larger displays, extending the
  zoom-out-only picker from [T-229](../feat-responsive-lowres-and-zoom/final.md).

## Sign-offs
- [x] Analyst — matches the request ("go the other direction… 110 and 120"); scope limited to two
      picker entries.
- [x] Architect — no engine/model/persistence change; the same `@AppStorage "ui.zoom"` pref, now
      taking values > 1.
- [x] Data — n/a.
- [x] Backend — `ScaledFootprint` already supports `scale > 1` (its `.fixedSize` guard prevents the
      known grow-loop); `effectiveWidth = contentWidth / zoom` generalizes to zoom > 1 unchanged.
- [x] Frontend/UX — options sit above 100% (largest first); at 120% the tracker magnifies and the
      window scrolls vertically, and the responsive breakpoints collapse a touch sooner — expected
      for a magnified view; help text updated.
- [x] SDET — pure picker-values change; the zoom pref round-trips via the existing options coverage.
      **789 tests pass.**
- [x] DevOps — clean build/test; ships as notarized dual-arch DMGs + appcasts for v1.2.8.
- [x] Review Coordinator — T-230 filed; INDEX + CHANGELOG (1.2.8) updated; VERSION → 1.2.8.

## Items to address (follow-ups)
- None.
