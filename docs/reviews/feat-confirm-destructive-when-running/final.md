# Review: feat/confirm-destructive-when-running — final (T-051)

**Status:** PASS — misclick safety on the crowded top section.

unanimous-consensus: T-051

## Sign-offs
- [x] Analyst — scope: confirm state-destructive controls. Two tiers, per the
      user: config toggles (Heart Shuffle, HDN) confirm only mid-run; the reset
      buttons all confirm always. In scope.
- [x] UX — the distinction is right: during setup / pause you can flip flags
      freely, but once the clock is running a misclick can't silently rebuild the
      dungeon tracker or zero the timer. Cancel reverts the toggle (the binding
      reads the model, which never changed).
- [x] Frontend — `runOrConfirm` centralizes the "run now vs. queue for
      confirmation" decision; `DestructiveAction` + the
      `destructiveActionConfirmation` modifier render it. The toggle bindings
      route their setters through it gated on `timer.isRunning`; Reset Timer got
      a plain always-on `confirmationDialog` matching App / keep-maps.
- [x] Backend / Data — no model change; the destructive operations
      (`setHeartShuffle`, `setHideDungeonNumbers`, `timer.reset`) are unchanged,
      only gated in the view.
- [x] Test Engineer — `runOrConfirm` routing test: not-running fires now;
      running queues without firing; performing the queued action fires it.
      294/294. On-device: HDN applies directly before Go; while running (1:25)
      it shows "Change Hidden Dungeon Numbers mid-run?" and Cancel keeps HDN on;
      Reset Timer shows its confirmation.
- [x] Architect / DevOps — N/A.
- [x] Review Coordinator — task filed (T-051); INDEX updated.

## Regression safety
- Non-destructive flags (Swordless, Boomstick, Mirror OW) are untouched — they
  don't wipe state, so they stay immediate. When the timer isn't running,
  behavior is unchanged. Full suite 294/294, build clean debug + release.
