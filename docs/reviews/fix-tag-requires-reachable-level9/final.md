# Review: fix/tag-requires-reachable-level9 — final (T-232)

**Status:** PASS — "Triforce and Go" is no longer announced when level 9 is genuinely unreachable.
Core-logic behavior fix; no version bump, folds into the next notarized build.

unanimous-consensus: T-232

## What changed
- `TriforceAndGoSummary.compute` now gates the TAG branch on level 9 being reachable
  (`dungeonLocations[8] != nil || owGettableLocations.trueCount > 0`). When 9 is unlocated and
  nothing is gettable, it falls to the heuristic score (sub-101, generic "not yet" text).

## Root cause
The full-TAG gate `missingDungeonCount == 0 || unreachableCount == 0` OR-short-circuited the
unreachable guard once all eight numbered dungeons were located, so a level-9 entrance walled behind
a power-bracelet spot (bracelet still in a dungeon) still read as TAG.

## Sign-offs
- [x] Analyst — matches the user's report and their chosen scope ("just suppress the false TAG"; no
      item-naming/chain). Out-of-scope items recorded on the task.
- [x] Backend — minimal, conservative gate at the right layer (`compute`), reusing already-computed
      `mapState` fields; no new inputs; the preserved `haveRecorder`/`haveLadder` bug is untouched.
- [x] Data — n/a (no schema/persistence change).
- [x] SDET — two new tests: false-TAG suppression (→ level 100, not TAG) and a located-control
      (→ 103, no over-suppression); all 8 prior TAG tests unchanged. **TrackerCore 574/574 pass.**
      Noted: the ZTrackerMacTests image/atlas suite is red in this environment on clean `main` too
      (pre-existing, unrelated, filed separately) — it does not exercise this code.
- [x] UX — the existing sub-101 phrasing is the "not yet" note the user asked for; no new copy.
- [x] Ops — no release cut here; ships with the next notarized build. CHANGELOG "Unreleased" records it.
- [x] Review Coordinator — T-232 filed; INDEX updated; CHANGELOG Unreleased entry added; VERSION untouched.

## Items to address (follow-ups)
- Separate investigation: why ZTrackerMacTests image decoding returns nil after the toolchain update
  (blocks the full-suite gate for future ships).
- Possible future enhancement: name the blocking item / "it's in level N" when known (declined here per scope).
