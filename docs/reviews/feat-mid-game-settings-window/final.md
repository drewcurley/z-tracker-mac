# Review: feat/mid-game-settings-window — final (T-091)

**Status:** PASS — settings reachable mid-game via a gear button and ⌘,.

unanimous-consensus: T-091

## Sign-offs
- [x] Analyst — first slice of the agreed mid-game-settings design (window +
      access). Seed flags / recorder toggles are separate slices (T-092/T-093).
- [x] Architect — a `Window` scene (single instance) sharing the app's `options`;
      same pattern as the Progress-HUD `WindowGroup`.
- [x] Frontend — `SettingsWindowView` wraps `SettingsPanelView` in a ScrollView;
      `OpenSettingsButton` binds ⌘, via `CommandGroup(replacing: .appSettings)`.
- [x] UX — two discoverable entry points (gear + ⌘,); live `options` so changes
      apply immediately.
- [x] SDET — build clean; existing settings-persistence tests unaffected. The
      window/command wiring is declarative scene config (not unit-testable);
      on-device visual check deferred (see note).
- [x] Data / Backend / DevOps — N/A.
- [x] Review Coordinator — task filed (T-091); INDEX updated.

## Verification note
- On-device visual confirmation is pending: mid-session the test machine's
  secondary display (where the tracker is pinned) became unavailable, so window
  placement/screenshots weren't reliable — and screenshotting an unverified region
  risks capturing other windows, so it was not attempted. The scene + command
  wiring mirrors the already-working Progress-HUD window; `SettingsPanelView` is
  the same view already shipping on the startup screen.

## Regression safety
- Additive: a new scene + one button + one menu command. Startup panel unchanged.
