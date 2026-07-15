# Review: feat/window-position-persistence — final (T-046.1)

**Status:** PASS — main window frame persists across launches.

unanimous-consensus: T-046.1

## Sign-offs
- [x] Analyst — scope: remember the main window's position + size and restore
      next launch (user request). Main window only; HUD out of scope. In scope.
- [x] Architect — bridges SwiftUI → AppKit via a tiny `NSViewRepresentable`;
      state lives in `UserDefaults` (one string key, `NSStringFromRect`). No
      security/privacy surface. Chose explicit save/restore over
      `setFrameAutosaveName` for robustness (saves on move/resize/close/terminate,
      not only AppKit-driven moves).
- [x] Frontend — `WindowFramePersister` (@MainActor) attaches on window
      appearance (deferred a runloop tick since `view.window` is nil in
      `makeNSView`), restores, then observes the four notifications. Guards
      against a degenerate saved rect (<200pt). `.persistWindowFrame(...)` on
      ContentView so it targets the main window, not the HUD.
- [x] UX — the window reopens where the user left it, on the same display — the
      expected macOS behavior.
- [x] SDET — window-frame persistence is AppKit runtime behavior (not unit-
      testable headlessly); verified on-device end-to-end: move → the frame
      wrote to `UserDefaults` (confirmed on disk) → quit + relaunch with no
      repositioning → reopened at the exact saved frame. Full suite 335/335,
      build clean debug + release.
- [x] Data / Backend / DevOps — N/A.
- [x] Review Coordinator — task filed (T-046.1); INDEX updated.

## Regression safety
- Additive and self-contained: a new file + one modifier on ContentView. No
  model or existing-view changes. If nothing is saved yet (first launch) the
  window uses its default frame. Build clean debug + release, 335/335.

## Note
- Reset App keeps the same window (only the model is replaced), so the frame is
  unaffected by an in-app reset. The saved rect is in AppKit bottom-left-origin
  coordinates (`window.frame`), which round-trips correctly through
  `setFrame`.
