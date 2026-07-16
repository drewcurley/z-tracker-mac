# Review: fix/single-window — final (T-097)

**Status:** PASS — one tracker window; the multi-window/tab liberty is removed.

unanimous-consensus: T-097

## Sign-offs
- [x] Analyst — removes an unintended `WindowGroup` default (not broadcast prep).
- [x] Architect — `Window` (single instance) shares the same app-level `model`/
      `options`; Settings + HUD scenes untouched.
- [x] Frontend — `WindowGroup {}` → `Window("Z-Tracker", id:)`; `.newItem` command
      replaced with an empty group (no New Window).
- [x] UX — one tracker, no tab bar, no drifting duplicates.
- [x] SDET — build clean; verified on-device via AX (1 window; ⌘N no-op; File>New
      Window absent). No test surface (declarative scene config).
- [x] Data / Backend / DevOps — N/A.
- [x] Review Coordinator — task filed (T-097); INDEX updated.

## Notes
- Broadcast (a future read-only mirror) would be its own `Window` scene, so this
  doesn't constrain it. Window-frame persistence (`persistWindowFrame`) still works.

## Regression safety
- Scene-type change only; game state, persistence, Settings/HUD windows unchanged.
