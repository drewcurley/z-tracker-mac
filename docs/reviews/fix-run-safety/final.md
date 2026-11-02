# Review: fix/run-safety — final (T-238, T-239, T-240, T-241)

**Status:** PASS — fixes the audit's run-safety findings: no flow can silently lose or overwrite a
run's save, destructive inputs need deliberate confirmation, the timer restores exactly what was
saved, and corrupt saves load safely instead of crash-looping. Not yet released (CHANGELOG Unreleased).

unanimous-consensus: T-238
unanimous-consensus: T-239
unanimous-consensus: T-240
unanimous-consensus: T-241

## Sign-offs
- [x] Analyst — scoped to the audit's §1 findings; the "Warn when quitting" no-op and other stubs are
      deliberately left for the stubs pass.
- [x] Architect — no new persistence surface; archives are plain save files in `~/Documents/ztracker/`
      (loadable via Load); the crash guard is one UserDefaults flag. Untrusted decoded values are now
      sanitized before reaching preconditions/indexing.
- [x] Data — `TrackerTimer.State` gains optional fields (backward-compatible); `TrackerModel.restore`
      resets absent optional sub-states; no format version bump needed.
- [x] Backend — decisions extracted as pure, injectable functions (`quitDecision`, `checkLastSession`,
      `restoredElapsed`, `isGroundhogConfirmed`, `isDeliberateEndGame`, `notesWithFinishLine`).
- [x] Frontend/UX — Reset App/quit/resume never lose a run; a stale or unreadable session explains
      itself; groundhog hotkey shows a "press again" toast; one documented behavior change (a run
      saved paused reopens paused).
- [x] SDET — new `RunSafetyTests` (quit decisions, session check: offer/clear/unreadable/crash-loop,
      deferred archive, stale auto-resume, finish line, groundhog window) and `RestoreHardeningTests`
      (bad box items, levelHints shape, recorder bound, take-any links, missing sub-state reset,
      spoiler line); voice end-game false-positive tests; timer tests for running/paused/pauses/lap/
      legacy/clamp. Two T-192 tests updated to the corrected behavior. **819 tests pass.**
- [x] DevOps — no build/release changes in this batch.
- [x] Review Coordinator — tasks filed; INDEX + CHANGELOG (Unreleased) updated.

## Follow-ups
- Reminder engine/log aren't reset on manual Load (low; re-announcements possible).
- Wall-clock timer (no sleep/wake handling) — low; a monotonic clock is a separate change.
