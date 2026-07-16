# Review: feat/door-repair-reminder — final (T-088)

**Status:** PASS — door-repair count reminder wired up (was missing).

unanimous-consensus: T-088

## Sign-offs
- [x] Analyst — restores a reference reminder the user found missing. Scoped to
      door-repair; the other four unported reminders logged as T-089.
- [x] Architect / Data — pure edge-trigger on a grid-derived count; no schema.
- [x] Backend — `poll` gains `doorRepairFound/Max` (defaulted, so callers/tests
      unaffected); `pollReminders` counts marks + passes the quest max.
- [x] Frontend — reuses the existing toast + `SpeechEngine`; category toggle
      already present and defaults on.
- [x] UX — matches the reference text ("all N of X" at completion).
- [x] SDET — 441 tests (2 new: engine edge-trigger, display text). End-to-end
      verified on-device: marking a door repair fired the toast.
- [x] DevOps — no infra change.
- [x] Review Coordinator — task filed (T-088); follow-up T-089 noted; INDEX updated.

## Regression safety
- New params default to 0, so the engine behaves identically when no door repairs
  are marked. Not reset on groundhog (marks are permanent). Full suite green.
