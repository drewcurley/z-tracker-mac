# Review: feat/warn-close-timer-running — final (T-109)

**Status:** PASS — quitting mid-run now prompts (setting default on).

unanimous-consensus: T-109

## Sign-offs
- [x] Analyst — matches the user ask: setting, default on, warns on close while the
      timer runs. Beyond the reference (documented as a deliberate deviation).
- [x] Architect — `applicationShouldTerminate` is the correct, cancelable termination
      hook; the guard closure is `@MainActor` and captures live app state.
- [x] Backend — `TrackerTimer.hardReset()` fully returns to pre-Go state; Reset App
      resets in place so the captured quit guard survives a reset.
- [x] Frontend — settings toggle added under Other; `NSAlert` (Quit / Cancel).
- [x] UX — Cancel is the safe default path; no prompt when the timer isn't running or
      the setting is off, so no nag.
- [x] Data — `warnOnCloseWhileTimerRunning` persisted with the other startup bools.
- [x] SDET — `hardResetClears` + default assertion; 466 tests pass; build clean.
- [x] DevOps — no infra/CI impact.
- [x] Review Coordinator — task filed (T-109); INDEX updated.

## Regression safety
- Termination is unchanged when the timer is stopped or the setting is off. The only
  behavioral change while running is a cancelable confirmation. Full suite green.
