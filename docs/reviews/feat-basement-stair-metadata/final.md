# Review: feat/basement-stair-metadata — final

**Status:** PASS

**Process note:** solo project (`playbook/AGENTS.md` §12) — one operator
reviewed sequentially wearing each of the 9 hats.

## Blockers (must fix before merge)
- none

## Warnings (fix before next review)
- [ ] **Unconsumed model.** `currentlyHasBasementStair` has no consumer yet —
      the dungeon-room-grid UI that renders the stair icon isn't built. Ported
      for 1:1 completeness and covered by table tests; flagged so it isn't
      mistaken for wired-up behavior.

## Suggestions (consider for polish)
- When the dungeon-room-grid UI lands (a future task), it reads
  `instance.currentlyHasBasementStair(box)` — no further model work needed.

## Agent Sign-offs
- [x] Analyst — scope matches T-016.2: the basement-stair *metadata* only
      (`StairKind`/`BoxOwner` + the predicate), with the rendering UI
      correctly out of scope. Completes the Box model that T-013 deferred.
- [x] Architect — no security surface. The reference exposes
      `CurrentlyHasBasementStair` as a `Box` member reaching globals; this
      port computes it on `DungeonTrackerInstance` (which holds the
      kind/`isSecondQuestDungeons`/label context) — a cleaner home, same
      logic. `Box` stays a data holder.
- [x] Data Engineer — two tables transcribed against the source: the
      DEFAULT box-construction `StairKind` assignment (`:742-753`) and the
      `currentlyHasBasementStair` quest/label/box-index branches (`:607-632`,
      both the HDN label tables and the DEFAULT `StairKind` cases). Both
      quests and both modes are pinned by test.
- [x] Backend — N/A (no server).
- [x] Frontend — N/A (no UI this task; this is the metadata a future
      room-grid UI will read).
- [x] UX — N/A (rendering deferred).
- [x] Test Engineer — 4 tests: DEFAULT StairKind assignment (L1/L2/L3/L8/L9 +
      shared/standalone boxes), DEFAULT basement by StairKind×quest, HDN
      first-quest label table (`'1'`→n2, `'2'`→never, `'3'..'7'`→n1), HDN
      second-quest table + dungeon-9-always. 193/193 total; the existing
      T-013/T-016.1 dungeon suites still pass (defaulted `Box` params).
- [x] DevOps — no CI/deploy changes; `swift build` + `swift test` clean.
- [x] Review Coordinator — process followed; `domain.md` § 6 + umbrella
      `T-016.md` + `tasks/T-016.2.md` updated; INDEX regenerated.

## Lens Sign-offs (routine model port — no new major decision)
- [x] Builder — computing the predicate on the instance (context-holder)
      rather than threading an `unowned` instance into every `Box` keeps the
      construction simple; the DEFAULT params mean zero churn at existing
      `Box()` sites.
- Other lenses — N/A (internal, unconsumed metadata).

## Regression safety
- Contracts touched = none (in-process model; `Box` init gained two
  defaulted params — source-compatible). Reflected in docs = yes
  (`domain.md` § 6). Cross-repo consumers = none. Compatibility = additive.
- Full suite: 189/189 → 193/193, no regressions. `swift build` clean.

## Out of scope (tracked as follow-ons)
- The dungeon-room-grid UI that renders the basement stair (a future task) —
  this is the metadata it will consume.
