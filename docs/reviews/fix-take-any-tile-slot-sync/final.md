# Review: fix/take-any-tile-slot-sync — final (T-066)

**Status:** PASS

unanimous-consensus: T-066

## Summary
Fixes the T-057 take-any desync: an overworld `.takeAny` tile now owns exactly
one Items-group heart slot via a per-tile link (`OverworldGrid.takeAnySlotLinks`),
and every take-any edit routes through `TrackerModel` so tile and slot stay in
sync. Re-marking a tile reuses its slot; changing/clearing the tile frees it;
left-click cycles in sync; and editing a heart box reflects back onto the tile.

## Sign-offs (Bug fix scope: Backend + SDET + Ops)
- [x] Backend — the record-into-next-free-slot logic (`recordTakeAny`, removed)
      is replaced by link-aware model methods. Slot claiming skips slots already
      owned by a tile, so no double-linking even if a linked slot is emptied
      directly. `applyMark` releases a take-any tile's slot before overwriting.
- [x] Data Engineer — the link is a dedicated `[Int]` (128, `-1` default) rather
      than overloading `extraData` (which mirrors reference mapSquare indices);
      `clearAll` / `clearAllUsed` reset it; groundhog reset clears it with the
      hearts.
- [x] Test Engineer — 7 tests cover: re-mark reuses slot, change-away frees slot,
      untaken frees only its own, new tile skips owned slots, tile-cycle,
      reverse (heart-box) sync, groundhog clears links. 313/313 pass, build clean.
- [x] DevOps — no infra/deps; pure model + view wiring.
- [x] Architect — no security surface.
- [x] Frontend — `TakeAnyHeartBox` cycles via a model closure; the map's
      left-click on take-any routes to `cycleOverworldTakeAny` instead of the
      generic used-toggle (which would have desynced).
- [x] UX — a take-any tile and its heart box now always agree; no phantom
      second heart, no stranded heart after re-marking.
- [x] Analyst — matches the reported bug exactly; the linkage is the user's
      requested model ("record which tile maps to which slot, keep in sync").
- [x] Review Coordinator — task filed (T-066); INDEX regenerated.

## Regression safety
- `TakeAnyHeartState.cycled` centralizes the wrap logic (map tiles + heart
  boxes share it); `ItemProgressGrid.cycledHeart` delegates to it. The obsolete
  `recordTakeAny` and its test were removed and replaced with a `cycled` test.
- On-device: Heart→slot0 heart; re-mark Potion→slot0 potion (no second slot);
  change to Armos→slot0 emptied. Full suite 313/313, build clean.
