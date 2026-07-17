# Review: feat/timeline-hover-location — final (T-114)

**Status:** PASS — timeline hover shows split + source location.

unanimous-consensus: T-114

## Sign-offs
- [x] Analyst — completes reported issue #8; box-location surfaced where it exists,
      graceful (name-only) where it doesn't.
- [x] Architect — location computed once per tick and stored on the model, so the
      pop-out window (which only has `timeline`) shows it too; no view→model coupling.
- [x] Data — `boxItemEvent` maps item ids to events; labels reuse
      `DungeonLabeling.columnName` (consistent with T-112). Live view is sound —
      collected items don't move.
- [x] Frontend — hover reformatted to "split  name — location".
- [x] UX — matches the requested "31:03 Level 1 Box 1" shape.
- [x] Backend — `recordTimeline` gains a defaulted `boardInsteadOfLevel`.
- [x] SDET — added `boxLocations` + `recordLocations`. 473 tests pass; build clean.
- [x] DevOps — no infra impact.
- [x] Review Coordinator — task filed (T-114); INDEX updated.

## Regression safety
- Additive: `acquiredLocation` is a new map; `record`/`recordTimeline` gained
  defaulted params so existing callers/tests are unaffected. Full suite green.
