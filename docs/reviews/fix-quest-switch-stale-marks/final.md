# Review: fix/quest-switch-stale-marks — final (T-252)

**Status:** PASS — single-operator review (audit §4 follow-up; user-directed scope).

unanimous-consensus: T-252

## Sign-offs
- [x] Analyst — closes the T-237 follow-up exactly; no new quest logic.
- [x] Architect — n/a for this change.
- [x] Data — no save-format change; clearing goes through the normal take-any release.
- [x] Backend — one 'located' rule app-wide (dead spots excluded), matching MapStateSummary.
- [x] Frontend / UX — flag is visible but small; the switch dialog offers clear vs keep.
- [x] SDET — model + view tests; 861 pass.
- [x] DevOps — n/a for this change.
- [x] Review Coordinator — T-252 filed; INDEX + CHANGELOG updated.
