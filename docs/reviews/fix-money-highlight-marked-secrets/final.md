# Review: fix/money-highlight-marked-secrets — final (T-111)

**Status:** PASS — money locator now includes uncollected money secrets.

unanimous-consensus: T-111

## Sign-offs
- [x] Analyst — fixes reported issue #5; scope limited to the money overlay predicate.
- [x] Architect — pure predicate stays unit-testable; no new state.
- [x] Data — reference highlights priced secrets; absent pricing, "marked & not
      collected" is the faithful stand-in (documented deviation).
- [x] Frontend — call site passes the tile's `grid.isUsed`.
- [x] UX — collected (spent) secrets correctly drop out; MMG always shown.
- [x] Backend / DevOps — N/A.
- [x] SDET — overlay test rewritten for the collected axis. 467 tests pass; build clean.
- [x] Review Coordinator — task filed (T-111); INDEX updated.

## Regression safety
- Only broadens the money highlight to marked sized secrets; MMG/unknown unchanged.
  Full suite green.
