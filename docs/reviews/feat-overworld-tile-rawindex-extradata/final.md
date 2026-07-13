# Review: feat/overworld-tile-rawindex-extradata — final

**Status:** PASS

**Process note:** solo project (`playbook/AGENTS.md` §12) — one operator
reviewed sequentially wearing each of the 9 hats.

## Blockers (must fix before merge)
- none

## Warnings (fix before next review)
- [ ] No consumer yet — the raw-index bridge and extra-data store exist for
      T-015.3 (`recomputeMapStateSummary`) and T-015.6 (picker). Intentional
      foundation, fully tested against the reference numbering.

## Suggestions (consider for polish)
- The reference's `getOverworldMapExtraData` has a `#if DEBUG` consistency
  assertion (that the key matches the tile's mark or is `SHOP` for a shop);
  the port omits it. If a future bug suggests a mis-keyed write, port that
  assertion as a `precondition` in DEBUG builds.

## Agent Sign-offs
- [x] Analyst — scope matches T-015.2 exactly: the raw-index bridge + the
      extra-data store, the two genuinely-missing model pieces the recompute
      needs. No recompute logic itself (that's T-015.3).
- [x] Architect — no security surface; value/observable types. `rawIndex`
      and `fromRawIndex` are written as explicit per-case switches rather
      than `CaseIterable`-order arithmetic, so the numbering cannot silently
      drift from `MapSquareChoiceDomainHelper`.
- [x] Data Engineer — the numbering is pinned exhaustively: all 36 marks →
      their reference index (`TrackerModel.fs:311-352`), `.unmarked`→-1, a
      full `-1…35` round-trip, `isItem` range `16…23`, and `toItem`'s
      `state-15` arithmetic (ARROW→1, BLUE_RING→5, SHIELD→8). `maxRawIndex`
      35 independently confirmed by counting the 36 `overworldTiles`
      entries. Extra-data `keyCount = DARK_X+1 = 36` matches the reference's
      `Array.zeroCreate (DARK_X+1)`.
- [x] Backend — N/A (no server); pure helpers + a flat-array store.
- [x] Frontend — N/A (no UI).
- [x] UX — N/A.
- [x] Test Engineer — 8 new tests: full rawIndex table, inverse + round-trip,
      out-of-range nil, isItem/toItem arithmetic, constants, extra-data
      per-(tile,key) independence, `clearAll` reset. 130/130 total passing.
- [x] DevOps — no CI/deploy changes; `swift build` + `swift test` clean.
- [x] Review Coordinator — process followed; `domain.md` § 6 + umbrella
      `T-015.md` table + `tasks/T-015.2.md` updated; INDEX regenerated.

## Lens Sign-offs (routine foundation port — no new major decision)
- [x] Builder — the explicit-per-case bridge + raw strings keep the port
      line-diffable against the reference and immune to enum-reorder bugs.
- Other lenses — N/A (internal foundation, no external-facing decision).

## Regression safety
- Contracts touched = none (in-process model types, not registered in
  `contracts.md`, consistent with prior tasks). Reflected in docs = yes
  (`domain.md` § 6). Cross-repo consumers = none. Compatibility =
  additive-only (new extension + new `OverworldGrid` members; existing
  `OverworldGrid` API unchanged, `clearAll` extended to also clear
  extra-data).
- Full suite: 122/122 → 130/130, no regressions. `swift build` clean.

## Out of scope (tracked as follow-ons)
- T-015.3 — `recomputeMapStateSummary` (first consumer of both the bridge
  and the extra-data store).
- T-015.4/.5/.6 — GYR rendering, placeholder wiring, destination picker.
