# Review: feat/overworld-terrain-instance — final

**Status:** PASS

**Process note:** solo project (`playbook/AGENTS.md` §12) — one operator
reviewed sequentially wearing each of the 9 hats. This branch also carries a
**scope decision** (splitting T-015 into six sub-tasks) — reviewed through
the relevant lenses below.

## Blockers (must fix before merge)
- none

## Warnings (fix before next review)
- [ ] `OverworldInstance` has no consumer yet — it is the foundation for
      T-015.3 (`recomputeMapStateSummary`). Shipping unconsumed foundation
      is intentional here (the same shape T-009's static graph took before
      T-010 used it), not dead code: it is fully tested against the
      reference and the next sub-task consumes it directly.

## Suggestions (consider for polish)
- If `OWQuest.BLANK` (custom overworld) is ever built, `OverworldInstance`
  gains one case per predicate — the switch shape already isolates where.

## Agent Sign-offs
- [x] Analyst — **scope decision reviewed.** The grounded scoping read
      established that T-015's premise was wrong (terrain predicates + shop
      extra-data unported) and that its acceptance criteria span five
      layers; splitting into T-015.1…T-015.6 keeps each unit independently
      shippable and testable, mirroring the accepted T-009/T-010 precedent.
      This sub-task (T-015.1) delivers exactly the pure-data foundation, no
      more. The umbrella `T-015.md` records the split; T-015.2–.6 are seeded.
- [x] Architect — no security surface; pure value types, no globals (the
      reference's mutable `owInstance` becomes a plain `struct` constructed
      per quest).
- [x] Data Engineer — the load-bearing data is transcribed verbatim and
      **independently count-verified**: every literal mask's `X`-count is
      pinned to a number counted directly from `OverworldData.fs`
      (armos 5, raftable 2, 1Q/2Q bombable 22/21, burnable 16/14, power-
      bracelet 4/7, ladderable 2, whistleable 1/10, gravepush 1/1,
      alwaysEmpty 55/48, sometimesEmpty 31), and the three derived masks
      recomputed exactly as `:239-271` (mixedAlwaysEmpty 35, secondQuestOnly
      20, firstQuestOnly 13). Armos's five exact coordinates pinned too.
- [x] Backend — N/A (no server); predicate dispatch is a direct port of
      `OverworldInstance`'s per-quest `match`.
- [x] Frontend — N/A (no UI in this sub-task).
- [x] UX — N/A.
- [x] Test Engineer — 8 new tests: literal-mask counts, derived-mask counts,
      armos coordinates, ladderable/alwaysEmpty/sometimesEmpty quest
      branching, MIXED=OR equivalence (checked square-by-square against the
      union of both single-quest masks), and `nothingable` composition.
      122/122 total passing.
- [x] DevOps — no CI/deploy changes; `swift build` + `swift test` clean.
- [x] Review Coordinator — process followed; `domain.md` § 6 updated with
      the split + T-015.1 done; `T-015.md` rewritten as the umbrella;
      T-015.1–.6 task files created; `tasks/INDEX.md` regenerated.

## Lens Sign-offs (the T-015 split is a plan-shaping decision)
- [x] PM — the split is the right call: T-015 as one PR would have bundled a
      data port, a model computation, a new data-modeling requirement, a
      render change, and a large new UI — untestable as a unit and slow to
      review. Six ordered sub-tasks each ship and verify independently.
- [x] Builder — the foundation-first ordering means every later sub-task
      builds on tested ground; the char-mask-as-raw-strings choice keeps the
      port line-diffable against the reference.
- [x] Adopter — no user-facing change yet; the split doesn't delay value
      (T-014 already delivered live ladder/raft routing), it sequences the
      remaining GYR work safely.
- Other lenses (CEO/Purchasing/Investor/Marketing) — N/A (internal
  sequencing decision, no external-facing or cost implications).

## Regression safety
- Contracts touched = none (`docs/contracts.md` is persistence/integration/
  security-scoped; in-process model types are not registered there,
  consistent with T-012/T-013/T-014). Reflected in docs = yes (`domain.md`
  § 6). Cross-repo consumers = none. Compatibility = additive-only (one new
  type + six new/rewritten task files).
- Full suite: 114/114 → 122/122, no regressions. `swift build` clean.
- No runtime UI surface in this sub-task; the data's correctness is what the
  8 count/branching tests exercise.

## Out of scope (tracked as follow-ons)
- T-015.2 — shop extra-data store + `OverworldTileMark` raw-index bridge.
- T-015.3 — `recomputeMapStateSummary` + `MapStateSummary` (first consumer
  of `OverworldInstance`).
- T-015.4/.5/.6 — GYR rendering, placeholder wiring, destination picker.
