# Review: feat/secret-count-reminders — final (T-105)

**Status:** PASS — one-left / none-left secret reminders per size.

unanimous-consensus: T-105

## Sign-offs
- [x] Analyst — user feature to curb over-marking; a documented deviation (no such
      reference reminder; cap stays unlimited).
- [x] Architect — new `.secrets` category surfaces via `allCases` (settings +
      persistence) and defaults on.
- [x] Data — remaining = quest total − placed sized secrets (1Q 3/7/4, 2Q 1/7/6),
      matching `SpotSummary`.
- [x] Backend — edge-trigger on crossing to 1/0 per size; re-fires on un-mark; not
      reset on groundhog (permanent marks).
- [x] SDET — 465 tests (2 new: engine crossings/re-fire, display+category).
- [x] Frontend / UX / DevOps — the setting appears automatically; text is plain.
- [x] Review Coordinator — task filed (T-105); INDEX updated.

## Regression safety
- Additive announcement + category (default on) + one grid scan addition. Full suite green.
