# Review: fix/triforce-hitbox — final (T-120)

**Status:** PASS — the triforce toggle is now a large, easy target.

unanimous-consensus: T-120

## Sign-offs
- [x] Analyst — matches the request (label + pip + everything to the first box).
- [x] Architect — presentation-only; `toggleTriforce` unchanged.
- [x] Frontend — `triforceRegion` fills width; tap + a11y on the wrapper; Level 9 inert.
- [x] UX — big hitbox fixes frequent misses; chips (display-only) fold into the target.
- [x] Data / Backend / DevOps — N/A.
- [x] SDET — toggle covered by existing dungeon tests; hitbox is view-only. 488 tests pass.
- [x] Review Coordinator — task filed (T-120); INDEX updated.

## Regression safety
- Only the click target grew; the pip visuals and toggle behavior are unchanged. Green.
