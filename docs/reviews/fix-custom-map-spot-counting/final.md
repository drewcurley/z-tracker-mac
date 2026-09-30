# Review: fix/custom-map-spot-counting — final (T-235)

**Status:** PASS — custom maps now count overworld spots from the quest's spot total (not the vanilla
terrain masks), add an "undiscovered" fog count with a spots-left ≤ undiscovered invariant, and stop
the mask-based INFO highlight. User specified the model and approved the build. Ships as **v1.2.11**.

unanimous-consensus: T-235

## What shipped
- `OverworldQuest.overworldSpotTotal` (73 first/mixed-first, 80 second/mixed-second).
- `OverworldGrid.customMapFogCount` (unrevealed-screen count).
- `MapStateSummary`: on custom maps, `owSpotsRemain = min(overworldSpotTotal − realMarked, fogCount)`
  and new `owUndiscovered = fogCount`; the vanilla whistle/bracelet/gettable block is skipped.
- `StatusReadoutView`: shows "N undiscovered" on custom maps in place of "gettable".
- `OverworldMapView.overlayHighlight`: open-caves/all-gettable modes disabled on custom maps.

## Sign-offs
- [x] Analyst — matches the reported bug and the user's specified model (quest-total − marked;
      undiscovered = fog; spots-left ≤ undiscovered). Scope decisions (dontCare = confirmed-empty
      not a spot; overlay disabled) confirmed with the user.
- [x] Architect — no persistence/schema change; reuses existing fog state and quest; the spot total
      is a single documented constant.
- [x] Data — n/a.
- [x] Backend — vanilla path untouched (all custom logic gated on `customMapActive`); the
      quest-total read uses `instance.quest`, already available in `compute`.
- [x] Frontend/UX — readout reuses the existing layout with a distinct cyan "undiscovered" line;
      the misleading mask highlight is off on custom maps; help text updated.
- [x] SDET — new tests: quest-total accounting, dontCare-reveals-not-counted, the clamp invariant,
      and 73/80 per quest + vanilla-undiscovered-0; replaced the obsolete test that asserted the old
      128-count bug. **794 tests pass** (full suite green).
- [x] DevOps — clean build/test; ships as notarized dual-arch DMGs + appcasts for v1.2.11.
- [x] Review Coordinator — T-235 filed; INDEX + CHANGELOG (1.2.11) updated; VERSION → 1.2.11.

## Items to address (follow-ups)
- Verify the 73/80 totals against a real seed of each quest when convenient; they live in
  `overworldSpotTotal` for a one-line adjustment if a count is off.
