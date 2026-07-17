# Review: feat/timeline-popout — final (T-100)

**Status:** PASS — Timeline pops out into its own window; the break-out pattern begins.

unanimous-consensus: T-100

## Sign-offs
- [x] Analyst — the user's break-out idea, applied to the timeline first.
- [x] Architect — `BreakoutWindows` app-level state coordinates inline ⇄ window;
      same `Window` + `openWindow`/`onDisappear` pattern as the working Settings/HUD windows.
- [x] Frontend — pop-out button + "Bring back" placeholder; window mirrors `model.timeline`.
- [x] UX — collapse and pop-out both available; on by default.
- [x] SDET — 458 tests; build clean; clean launch. Window open/close is declarative
      scene config (matches proven windows) — interaction is user QA.
- [x] Data / Backend / DevOps — N/A.
- [x] Review Coordinator — task filed (T-100); INDEX updated.

## Verification note
- Follows the already-working Settings/Progress-HUD window pattern exactly; on-device
  window interaction deferred to QA (unstable display this session).

## Regression safety
- Additive: one app-level observable + a window scene + a threaded param. Full suite green.
