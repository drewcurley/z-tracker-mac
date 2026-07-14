# Review: fix/reset-buttons-info — final (T-048)

**Status:** PASS — corrects T-046's interaction per user feedback.

unanimous-consensus: T-048

## Sign-offs
- [x] Analyst — scope: replace T-046's pause-reveal hub with three omnipresent
      reset buttons under Info, and stop pausing the main timer on a groundhog
      reset. Exactly the user's correction.
- [x] Frontend — `TimerView` reverts to a single Pause/Resume button (the
      `onResetApp`/`onGroundhogReset` params and confirmations are gone). The
      three resets live in `MapInfoView`, which now takes `timer` + `onResetApp`.
- [x] UX — resets are always visible and predictable (no need to pause to reach
      them); pausing is just pausing. The groundhog reset restarts only the lap,
      matching how racers actually use it (the main/total time must not stop).
- [x] Backend — groundhog action is `resetForGroundhogOrRouters()` +
      `timer.startLap()`; no `pause`/`resume`, so the main timer is untouched.
      Reset Timer = `timer.reset()`; Reset App = the app-level model swap.
- [x] Test Engineer — timer semantics (startLap keeps main running; reset)
      covered by `TrackerTimerTests`; groundhog model reset by
      `GroundhogResetTests`; Reset-App contract by `TrackerModel.startsWithNoQuest`.
      284/284. On-device: after a groundhog reset the main timer stayed green at
      0:00:47 (running) while the lap reset to ~1s; buttons omnipresent.
- [x] Architect / Data / DevOps — N/A; no schema/infra/security change.
- [x] Review Coordinator — task filed (T-048); INDEX updated.

## Regression safety
- Pure relocation + a behavior fix (no forced pause on groundhog). The Reset App
  model-swap and timer reset paths are unchanged from T-046. Full suite 284/284,
  build clean debug + release.
