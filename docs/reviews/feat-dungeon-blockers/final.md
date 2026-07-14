# Review: feat/dungeon-blockers — final

**Status:** PASS

**Process note:** solo project (`playbook/AGENTS.md` §12) — one operator
reviewed sequentially wearing each of the 9 hats.

## Blockers (must fix before merge)
- none

## Warnings (fix before next review)
- [ ] The blocker-*setting* UI is not built — it's uncharacterized in the
      reference (the task itself says "read the reference's blocker-UI
      before implementing") and needs a dungeon-tracker UI host that doesn't
      exist yet. Recorded as a remaining parity gap in `domain.md` § 6. The
      model + container are complete and independently tested.
- [ ] `DungeonBlockersContainer` has no save/load yet (consistent with the
      rest of `TrackerModel`); `asJsonString` ports the exact reference save
      shape so a future persistence layer round-trips.

## Suggestions (consider for polish)
- `CombatUnblockerDetail` is ported but not yet consumed (the combat-blocker
  detail UI is part of the deferred blocker UI) — kept for parity/shape.

## Agent Sign-offs
- [x] Analyst — scope matches T-017's portable half: the full blocker model
      + container + staleness check, with the uncharacterized setting-UI
      correctly deferred (not guessed at).
- [x] Architect — no security surface; the reference's `static` singleton +
      change event + load-ignore flag become plain `@Observable` instance
      state, owned by `TrackerModel` like the other sub-models.
- [x] Data Engineer — transcribed against `TrackerModel.fs:1147-1273`: all 16
      `DungeonBlocker` cases in `All` order (so `next`/`prev` cycle
      identically), the `HardCanonical` maybe→definite map, the
      `PlayerCouldBeBlockedByThis` gating (only ladder/recorder/bow+arrow/key
      have a staleness check, `:1188-1194`), the exact `AsHotKeyName` save
      strings, and the `AsJsonString` shape (`:1269-1271`).
- [x] Backend — N/A (no server); container get/set is a flat-index port of
      the `Array2D`.
- [x] Frontend — N/A (no UI this task).
- [x] UX — N/A (setting UI deferred).
- [x] Test Engineer — 9 tests: 16-case count/order, `hardCanonical` map, the
      full `playerCouldBeBlockedByThis` matrix (incl. bow-AND-arrow needing
      both, and the always-true default group), hotkey-name round-trip +
      unknown→nothing, `next`/`prev` wraparound, `displayDescription`,
      container defaults / independent set-get / `asJsonString` shape.
      167/167 total.
- [x] DevOps — no CI/deploy changes; `swift build` + `swift test` clean.
- [x] Review Coordinator — process followed; `domain.md` § 6 + `tasks/T-017.md`
      updated; INDEX regenerated.

## Lens Sign-offs (routine model port — no new major decision)
- [x] Builder — modeling the 16-case union as a Swift enum with computed
      properties keeps it a faithful, exhaustively-switched port; `Codable`
      conformance readies it for the future save layer.
- Other lenses — N/A (internal annotation-feature model).

## Regression safety
- Contracts touched = none (in-process model + one additive `TrackerModel`
  init parameter with a default). Reflected in docs = yes (`domain.md` § 6).
  Cross-repo consumers = none. Compatibility = additive-only.
- Full suite: 158/158 → 167/167, no regressions. `swift build` clean.

## Out of scope (tracked as follow-ons)
- Blocker-setting UI (uncharacterized; needs a dungeon-tracker UI host).
- Save/load of blocker state (with the persistence layer).
- T-018 — reminders/announcements/Triforce-and-Go (a consumer of blockers).
