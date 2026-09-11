# Review: feat/shop-items-and-panel-sync — final (T-224)

**Status:** PASS — standalone-heart shop item, a 3rd item per shop tile, and the Shop & Price panel
syncing with the map (equal-set consolidation, followed slots). User QA'd each phase and the reworked
sync. Ships as notarized **v1.2.5** with the armos work (T-223).

unanimous-consensus: T-224

## What shipped
- `ShopKind.heart` (consumable, always visible); wired into chooser/menu/hotkey/voice/panel + spoiler
  import; raw-index bridge extended as an app index (37), verified safe.
- Up to **3 items per shop** via bit-packing the 2nd/3rd into the existing extra-data slot (old saves
  decode unchanged); threaded through render, hide-owned, found-shop detection, and the smarts.
- Panel↔map sync: slots **follow** a shop tile (edits propagate), consolidate only on **equal** item
  sets, dedupe instances, release on removal, and never clobber typed items/prices.

## Sign-offs
- [x] Analyst — matches the requests + the two rounds of QA feedback (equal-set identity, not subset;
      followed-slot updates). The four-shop-types domain rule is honored.
- [x] Architect — heart avoids the reference's fixed 8-shop arithmetic (app index; never an extra-data
      key; Codable-persisted). Bit-packing keeps the save format/size unchanged and back-compatible.
      Sync keeps prices stable by following coords; hand-entered slots aren't auto-released.
- [x] Data — `OverworldGrid` packing round-trips; pre-T-224 saves decode (bare 2nd item, no 3rd);
      `ShopPriceRecord.slotCoords` optional in the snapshot.
- [x] Backend — the 3-item smarts (fill 2nd→3rd, 4th replaces primary, promote on removal) and the
      sync (release/update/place/consolidate) are covered; `MapStateSummary` checks all shop items.
- [x] Frontend/UX — all three shop items render on the tile; the 9-item shop chooser row; the panel
      slots fill/update from the map with prices preserved.
- [x] SDET — packing + compat, 3-slot smarts, the reported end-to-end sync scenario, heart
      eligibility/render, and updated 8→9 invariants. **787 tests pass.**
- [x] DevOps — clean build/test; ships as notarized dual-arch DMGs + appcasts for v1.2.5.
- [x] Review Coordinator — T-224 filed; INDEX + CHANGELOG (1.2.5) updated.

## Items to address (follow-ups)
- Optional un-merge / "make this a separate shop" control for the rare overlapping-partial case
  (two partial views that aren't equal or subset). Not needed by the equal-set rule; flagged if wanted.
