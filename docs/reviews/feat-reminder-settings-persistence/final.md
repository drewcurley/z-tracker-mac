# Review: feat/reminder-settings-persistence — final (T-004.1)

**Status:** PASS — Reminder settings persist across launches; Voice/Visual header alignment fixed.

unanimous-consensus: T-004.1

## Sign-offs
- [x] Analyst — scope: make the already-wired Reminders section persist (volume,
      per-category voice/visual, preferred voice) across launches, and fix the
      header alignment in the same section (user request). Other settings stay
      session-only. In scope.
- [x] Architect — persistence lives in `UserDefaults` under `ztracker.reminders.*`
      keys; opt-in via `enableReminderPersistence(store:)` so it's injectable and
      tests use isolated suites (never `.standard`). No security/privacy surface
      (local settings only). `didSet`-driven saves are synchronous and cheap.
- [x] Data — the toggle dictionaries serialize to `[String: Bool]` keyed by the
      category `rawValue` (stable); load merges over defaults so an unknown or
      missing category keeps its default (forward/backward compatible). Volume
      clamped 0…100 on load.
- [x] Frontend — `ZTrackerMacApp` builds `options` via
      `TrackerOptions.withReminderPersistence()`; Reset App keeps `options`.
      Header fix: removed the leading 1pt spacer cell and set
      `.gridColumnAlignment(.center)` on the two header cells so each sits over
      its checkbox column.
- [x] UX — settings now "stick" between sessions as a user expects; the
      Voice/Visual headers read correctly over their columns.
- [x] Backend — the gating (`ReminderController.handle`) and volume application
      (audio player + TTS) were already correct and are unchanged; this only adds
      persistence, so no behavior regression in how reminders fire.
- [x] SDET — `ReminderPersistenceTests`: round-trip across a simulated relaunch,
      Disable-all persists, plain `TrackerOptions()` writes nothing, a category
      absent from the save keeps its default. 335/335. On-device: raised volume +
      unchecked "Sword hearts Voice" both survived quit/relaunch; headers aligned.
- [x] DevOps — N/A.
- [x] Review Coordinator — task filed (T-004.1); INDEX updated.

## Regression safety
- Additive + opt-in: persistence is off unless `enableReminderPersistence` is
  called, so existing tests/previews using `TrackerOptions()` are unaffected
  (verified by a test). `didSet` doesn't fire during `init`, and the load path
  guards re-entrancy with `isApplyingPersistedReminders`. The header change is
  layout-only. Build clean debug + release, 335/335.

## Note
- `@Observable` + `didSet` on stored properties compiles and works (verified in
  build + tests) — used here to avoid threading persist calls through every UI
  binding.
