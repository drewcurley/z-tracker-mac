# Review: fix/qa-round-2 — final (T-118)

**Status:** PASS — five QA fixes.

unanimous-consensus: T-118

## Sign-offs
- [x] Analyst — each fix maps 1:1 to a reported QA item; no scope creep.
- [x] Architect — letter change also corrects `havePotionLetter` (a latent bug from
      the force-used placement); wood-sword grant is a view→model callback, no new
      coupling in TrackerCore.
- [x] Data — SpotSummary letter `used`/`done` now key on placement; verified against
      the reference letter tile (dark = held, bright = delivered).
- [x] Frontend — timeline `.help` moved before `.position` (frame-expansion bug);
      enemy overlay HStack→VStack (leading).
- [x] UX — finish time gains ms for tie-breaks; enemies no longer occlude the mark.
- [x] Backend — wood-sword-cave toggle wired to `hasWoodSword`.
- [x] SDET — added letter/wood-sword-cave tests; updated the spot-summary letter
      assertion. 487 tests pass; build clean.
- [x] DevOps — no infra impact.
- [x] Review Coordinator — task filed (T-118); INDEX updated.

## Regression safety
- Secrets/hint-shop placement unchanged; only the letter's placement/dim inverted
  (now reference-correct). Timeline/enemy changes are display-only. Full suite green.
