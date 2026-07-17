# Review: fix/zoom-persist-and-runaway — final (T-129)

**Status:** PASS — runaway, persistence, and button size fixed.

unanimous-consensus: T-129

## Sign-offs
- [x] Analyst — three reported issues; no scope creep.
- [x] Architect — `fixedSize` breaks the measure→frame→measure loop; `mapScale`
      hoisted to the stable parent (binding) survives `ViewThatFits`.
- [x] Frontend — wider zoom control spanning the info strip; `ViewThatFits` kept
      (an `AnyLayout` breakpoint mismeasured the overflowing content width).
- [x] UX — user-QA'd: 120% sane, zoom holds through reflow, buttons match sidebar.
- [x] Data / Backend — no logic change.
- [x] SDET — view-only; 493 tests pass; build clean.
- [x] DevOps — no infra impact.
- [x] Review Coordinator — task filed (T-129); INDEX updated.

## Regression safety
- `ScaledFootprint` still pass-through at 100%; reflow behavior unchanged apart from
  the persisted zoom. Green.

## Known follow-up
- The selected dungeon tab + FQ/SQ overlay still reset on reflow (same root cause,
  lower stakes) — hoist if it becomes annoying.
