# Review: feat/persist-startup-settings — final (T-070)

**Status:** PASS — the startup settings (door inference et al.) now persist across
launches.

unanimous-consensus: T-070

## Sign-offs
- [x] Analyst — scope: extend the existing reminder persistence (T-004.1) to the
      rest of the startup settings, per user request after door inference reset
      each launch. In scope; no behavior change beyond persistence.
- [x] Frontend — a keypath map is the single source of truth (add a setting there
      and it persists); saved at the quest-start commit point (settings are only
      editable pre-run), loaded at launch via `withPersistence()`.
- [x] Data — stores a `[String: Bool]` (stable keys) + the broadcast enum rawValue
      + a hidden-tiles `[String: Bool]`; missing/unknown keys keep defaults, so the
      schema is forward/backward compatible. Mirrors the reminder-persistence shape.
- [x] SDET — 5 unit tests over real `UserDefaults` suites (round-trip, enum+dict,
      no-save-no-write, no-store-no-touch, all-key-paths). Suites now self-clean
      via `defer` (the older reminder tests still leak suites — noted as a
      follow-up). 400 total pass; clean debug + release. On-device: a seeded saved
      pref restored the matching startup checkboxes.
- [x] Architect — local `UserDefaults` only; no security surface. `nonisolated(unsafe)`
      on the immutable keypath map (key paths of the non-Sendable options class
      aren't `Sendable`; the map never mutates).
- [x] UX — settings that stick across launches match the reference and remove the
      per-launch re-checking.
- [x] Backend / DevOps — N/A.
- [x] Review Coordinator — task filed (T-070); INDEX updated.

## Regression safety
- Additive to `TrackerOptions`; the reminder persistence path is untouched.
  `withReminderPersistence` still exists (tests); the app moved to `withPersistence`.
  Build clean; 400 tests pass; on-device load confirmed.

## Follow-up
- The T-004.1 reminder tests leak `UserDefaults` suites (no teardown) — apply the
  same `defer`-cleanup there.
- Optionally also save on app-terminate to catch a change-then-quit-without-
  starting (today only the quest-start commit persists).
