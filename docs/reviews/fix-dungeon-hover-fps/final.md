# Review: fix/dungeon-hover-fps — final (T-179)
**Status:** PASS — dungeon-hover FPS fixed (ViewThatFits removed), layout regression fixed,
file-based render-perf logging added; user QA'd (flow + captured log verified).
unanimous-consensus: T-179

## Sign-offs
- [x] Analyst — scope held to the confirmed FPS root cause + the diagnostic tool that found
      it. File-based logging was an explicit user-approved add (single PR chosen over a split);
      About build-stamp is a diagnosis aid kept in-scope.
- [x] Architect — no new I/O in the render path; the `dup2` stdout/stderr redirect is opt-in
      (toggle) and session-scoped, temp files in a dedicated GC'd folder, NSSavePanel for the
      only user-facing write (no silent writes). Session-global redirect trade-off documented.
- [x] Data Engineer — one added option (`logRenderPerf`, session-only bool); no schema/persist
      changes. Temp log is line-buffered; startup GC removes crash-leftovers.
- [x] Backend Engineer — `PerfLog.confirmSaveOnExit()` chained after the save-run dialog on
      Quit and gated before Reset App; discard-and-reopen keeps a continuing (Reset App)
      session capturing without a dangling fd. Save-panel Cancel returns to app (no data loss).
- [x] Frontend Engineer — `ViewThatFits` (the per-hover re-measure of both candidate layouts)
      replaced by a cached-width boolean; width read directly off the GeometryReader proxy
      (not via a PreferenceKey on a `.fixedSize` node, which reported a stuck 0). Behavior
      matches the pre-perf layout at any window width.
- [x] UX Designer — responsive side-by-side/stacked restored; toggle relabeled "Log render
      perf to file" with help text explaining the save-on-exit flow; Cancel is non-destructive.
- [x] SDET — 687 tests pass. Layout decision is deterministic from measured width; the FPS
      win was verified by the shipped instrumentation (62–96 ms → 15–26 ms) and the file
      capture confirmed against a saved 8.5k-line log with full `_printChanges` fidelity.
- [x] DevOps — `build-app.sh` bakes the git build stamp into Info.plist; no infra change. The
      redirect uses POSIX `dup2`; temp logs never leave `NSTemporaryDirectory`.
- [x] Review Coordinator — T-179 filed; INDEX updated. Single-PR packaging per user decision.
