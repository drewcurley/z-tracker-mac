# Review: fix/door-repair-dim — final (T-077)

**Status:** PASS — door-repair tiles dim permanently when marked, surviving groundhog.

unanimous-consensus: T-077

## Sign-offs
- [x] Analyst — scope: a one-behavior tile-render rule from user feedback. In scope.
- [x] Data — dim derives from the mark (knowledge), not `used`; `resetForGroundhog`
      keeps marks (only `clearAllUsed`), so the dim persists — asserted by test.
- [x] UX — matches the reference "door repair always dark"; a one-shot spot you
      never revisit reads as done.
- [x] SDET — 2 tests (only door-repair dims; mark survives groundhog). 423 total
      pass; clean debug + release. On-device: door-repair dark, MMG bright.
- [x] Frontend — one-line OR into the existing `used`→dim path; no new render code.
- [x] Architect / Backend / DevOps — N/A.
- [x] Review Coordinator — task filed (T-077); INDEX updated.

## Regression safety
- Additive: a pure mark property + one OR in the tile dim flag. Other tiles
  unaffected (property is false for everything but door-repair). Build clean; 423 pass.
