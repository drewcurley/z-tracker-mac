# Review: perf/timer-render-cpu — final (T-144)

**Status:** PASS — the 100%-CPU blocker is fixed (100% → ~13%, `sample`-verified);
residual re-layout cost + dungeon hover jank tracked as follow-ups.

unanimous-consensus: T-144

## Sign-offs
- [x] Analyst — fixes the reported blocker (game lag from a pegged core); ships a
      diagnostic (FPS counter) to drive the remaining perf work. Scope held.
- [x] Architect — root cause identified from a live `sample` (NSHostingView full-tree
      `sizeThatFits` per timer tick), not guessed. Fix removes the high-frequency
      trigger rather than masking it; the deeper hosting-view re-measure is filed.
- [x] Data — n/a (no schema); timer stays a pure function of `now`, ms preserved for
      capture-to-notes.
- [x] Backend — `TimerFormatting.hms` (no ms) for display; 1 fps interval; paused timer
      renders once (no `TimelineView`). `showFPS` added to `TrackerOptions` (property +
      init + persistence map).
- [x] Frontend / UX — visible clock ticks H:MM:SS once/sec (user-approved: ms not needed
      on screen); FPS pill top-trailing, colour-coded, hit-testing off, sampled only while
      shown (CADisplayLink stops when detached).
- [x] SDET — timer-formatting + options unaffected; **588 tests pass**. Perf verified
      out-of-band via `sample` (100%→~13%); FPS counter is the ongoing measurement tool.
- [x] DevOps — no infra change; `swift build` clean; app rebuilt & relaunched for QA.
- [x] Review Coordinator — task filed (T-144); INDEX updated.

## Items to address (follow-ups)
- Deeper fix for the whole-tree re-measure (residual ~13% + mousing jank).
- Dungeon map hover ~10× worse than overworld — slim the dungeon view / cache atlases.
