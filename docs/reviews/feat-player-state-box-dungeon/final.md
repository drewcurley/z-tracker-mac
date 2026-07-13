# Review: feat/player-state-box-dungeon — final

**Status:** PASS

**Process note:** solo project (`playbook/AGENTS.md` §12) — one operator
reviewed sequentially wearing each of the 9 hats.

## Blockers (must fix before merge)
- none

## Warnings (fix before next review)
- [ ] `Box.cellCurrent` is a plain `Int` with no cross-box max-use
      enforcement — marking two boxes with the same unique item (e.g. two
      Ladders) is currently *possible* in the model, where the reference's
      `ChoiceDomain` would prevent it. Deliberate T-013 deferral (see
      Suggestions); the same gap already exists for `OverworldGrid` and is
      closed when the item-picker UI needs it (T-014/T-015). No completion-
      logic consumer is affected because `isDone` only reads `!= -1`.
- [ ] No save/load round-trip for `DungeonTrackerInstance` yet — consistent
      with the rest of `TrackerModel` today (no persistence task has run);
      not a new gap.

## Suggestions (consider for polish)
- When T-014/T-015 introduces the item `ChoiceDomain`/`Cell`, revisit
  whether `Box` should hold a real `Cell` or keep the `Int` + a separately-
  owned domain. The `Int` was chosen to keep T-013 to the possession/
  completion model exactly.

## Agent Sign-offs
- [x] Analyst — scope matches T-013's acceptance criteria exactly: DEFAULT-
      mode `PlayerHas`/`Box`/`Dungeon`/`DungeonTrackerInstance`,
      `isComplete`, triforce toggle, `getTriforceHaves()`, box counts. HDN
      mode, `StairKind`/`BoxOwner`/`CurrentlyHasBasementStair`,
      `Color`/`LabelChar` all correctly left for T-016;
      `PlayerComputedStateSummary` left for T-014. No UI added — none is in
      the acceptance criteria (resisted the T-012-style debug-panel
      temptation; real UI is T-015).
- [x] Architect — no security surface; plain in-process observable state.
      The one architecture call — replace the reference's mutable
      `static TheDungeonTrackerInstance` singleton + `IsSecondQuestDungeons`
      global with plain instance state (each `Dungeon` holds an `unowned`
      back-ref to its owner) — removes two globals, keeps behavior identical,
      and makes the type unit-testable in isolation. `unowned` is safe: the
      instance owns every dungeon and outlives them.
- [x] Data Engineer — the load-bearing structural data is transcribed
      against the F# source and cross-checked by call-count: DEFAULT base
      box counts `[2,2,2,2,2,2,2,3,2]` verified line-by-line against
      `makeDungeons()` (`TrackerModel.fs:679-693`); the quest-dependent
      `finalBoxOf1Or4` placement (`id=0 && !2Q` or `id=3 && 2Q`) verified
      against `Boxes` (`:783-786`); `allBoxes()` = 23 (19 base + 1 finalBox
      + 3 standalone) verified against `all()` (`:712-721`) and the
      reference's own "23 items exist" comment; `getTriforceHaves()` DEFAULT
      indexing verified against `:834-835`. `PlayerHas` raw values pinned to
      `AsInt()` (`:584`).
- [x] Backend — N/A (no server); `TrackerModel` ownership is constructor
      injection consistent with `overworldGrid`/`playerProgress`.
- [x] Frontend — `@Observable` on `Box`/`Dungeon`/`DungeonTrackerInstance`;
      the `Dungeon.boxes` computed property reads
      `instance.isSecondQuestDungeons`, so observation re-derives box layout
      when the flag flips — covered by the `toggleMovesThirdBox` test.
- [x] UX — no user-facing surface this task.
- [x] Test Engineer — 20 new tests across 4 suites: `PlayerHas` raw-value
      pinning; `Box` `isDone`/`isEmptyRedBox` truth matrix + mutation;
      base + effective box counts in both quests; shared-`finalBoxOf1Or4`
      identity; the 23-box flatten; standalone-box `.skipped` seeding;
      `allBoxProgress` (start 3/20, 1.0 cap); triforce toggle + dungeon-9
      exclusion; completion scenarios (triforce×boxes matrix, skipped-
      counts-as-done, quest-reparenting of the shared box). 101/101 total
      passing.
- [x] DevOps — no CI/deploy changes; `swift build` + `swift test` clean.
- [x] Review Coordinator — process followed; `docs/domain.md` § 6 updated to
      mark T-013 done with grounding + the three deliberate simplifications;
      `tasks/T-013.md` acceptance criteria checked off with evidence.

## Lens Sign-offs (routine port — no new major decision)
- [x] PM — kept to exactly the re-scoped T-013; did not start T-014 inline.
- [x] Builder — modeling the F# `PlayerHas` `YES|NO|SKIPPED` as a proper
      Swift enum (as T-012's review explicitly recommended for this task),
      and `isComplete` as a plain computed property instead of the F#
      reentrancy-guarded member, are small real improvements with identical
      behavior.
- Other lenses — N/A (internal model port, no external-facing decision).

## Regression safety
- Contracts touched = none (`docs/contracts.md` is persistence/integration/
  security-scoped; in-process TrackerCore model types are not registered
  there, consistent with T-012). Reflected in docs = yes (`domain.md` § 6).
  Cross-repo consumers = none (single active repo). Compatibility =
  additive-only (new types + one new optional `TrackerModel` init parameter
  with a default).
- Full suite: 81/81 → 101/101, no regressions. `swift build` clean.
- No new runtime UI surface to drive end-to-end; the model's observable
  behavior is exactly what the 20 new tests exercise.

## Out of scope (tracked as follow-ons)
- T-014 — `PlayerComputedStateSummary` derivation (consumes `allBoxes()`).
- T-015 — real GYR + destination picker + live routing + item-picker UI
  (first real consumer of the item `ChoiceDomain`/`Cell`).
- T-016 — HDN mode, `StairKind`/`BoxOwner`/`CurrentlyHasBasementStair`,
  `Color`/`LabelChar`.
- T-017 / T-018 — dungeon blockers, reminders/TAG.
