# Review: fix/secret-picker-cap — final (T-108)

**Status:** PASS — sized secrets are capped in the picker.

unanimous-consensus: T-108

## Sign-offs
- [x] Analyst — completes the secret ask (reminders in T-105, cap here). A
      deliberate deviation (reference leaves secrets unlimited) per the user.
- [x] Data — `maxUses(.secret(size))` = quest totals (1Q 3/7/4, 2Q 1/7/6); unknown
      unlimited. Matches `SpotSummary`/reminder totals.
- [x] Frontend — Secret menu `.disabled(isExhausted)` like the other capped marks.
- [x] SDET — claim-limits test updated to the caps + unknown-unlimited. Build clean.
- [x] Architect / Backend / UX / DevOps — N/A.
- [x] Review Coordinator — task filed (T-108); INDEX updated.

## Regression safety
- Only tightens the secret cap in the picker; unknown secrets and everything else
  unchanged. Full suite green.
