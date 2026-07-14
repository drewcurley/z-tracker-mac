# Review: feat/pause-reset-panel — final (T-046)

**Status:** PASS — interaction change; app-level reset added.

unanimous-consensus: T-046

## Sign-offs
- [x] Analyst — scope matches the user's ask: replicate the Windows pause
      options minus "close & restart the app", add "Reset App" (return to
      startup), keep Reset Timer + groundhog. In scope.
- [x] Architect — "Reset App" replaces the whole `TrackerModel` instance (the
      app's `@State`), which is the robust way to guarantee a clean slate (no
      field left un-reset) and naturally tears down the main view + timer.
      `options` (settings) are intentionally preserved. No security surface.
- [x] Frontend — `resetApp` is a plain closure plumbed App → ContentView →
      MainTrackerPlaceholderView → TimerView (3 hops, defaulted so previews/tests
      compile). TimerView's paused branch is the reset hub; running shows only
      Pause. Confirmations gate the two destructive resets.
- [x] UX — pausing reveals Resume (prominent green) + Reset App / Reset Timer /
      Reset (keep maps); tooltips explain each. Consolidating all resets here
      (groundhog moved out of Info) declutters the Info group and gives one
      predictable "reset" home, mirroring the reference.
- [x] Backend / Data — groundhog uses the existing
      `resetForGroundhogOrRouters()`; the paused-panel variant additionally
      `startLap()` + `resume()` so the run continues with a fresh lap. No model
      logic changed.
- [x] Test Engineer — no new pure logic: Reset App's contract
      (`TrackerModel().quest == nil` → startup) is pinned by the existing
      `TrackerModel.startsWithNoQuest`; groundhog by `GroundhogResetTests`; timer
      reset by `TrackerTimerTests`. 284/284. On-device: pause hub renders; Reset
      App → confirm → startup screen (fresh state).
- [x] DevOps — N/A.
- [x] Review Coordinator — task filed (T-046); INDEX updated.

## Seven lenses (UX decision)
- Middle-management / Developer — removes the reference's disruptive
  "close & restart the app" (a community annoyance) while keeping a real
  start-over path; a clear usability win for racers. Other lenses neutral. No
  conflict.

## Regression safety
- Additive/relocating: the timer's own reset + groundhog logic are unchanged;
  only the surface (paused hub) and one relocation (groundhog out of Info) moved.
  Full suite 284/284, build clean debug + release.
