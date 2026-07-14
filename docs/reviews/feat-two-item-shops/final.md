# Review: feat/two-item-shops — final (T-060)

**Status:** PASS — shop second-item, model-backed.

unanimous-consensus: T-060

## Sign-offs
- [x] Analyst — scope: a shop's second item, settable + shown in dropdown order,
      dupes disabled. Reference records two (creator's call); matched. In scope.
- [x] Data — `shopSecondItem`/`setShopSecondItem` use the existing
      `shopExtraDataKey` in the reference toItem encoding (`ShopKind` index + 1),
      exactly what `MapStateSummary` reads for "found shop". `shopItems` sorts by
      `ShopKind.allCases` order.
- [x] Frontend — `markMenu` shows "Shop — 2nd item" only for shop tiles, primary
      disabled; `applyMark` clears a second item that duplicates the new primary;
      `TileView` renders the ordered pair on the shop background.
- [x] UX — both items always render in the same order (listing order), so the
      display is stable no matter the pick order.
- [x] Test Engineer — `shopTwoItems` (set/clear, ordered display, toItem
      encoding, non-shop empty). 305/305. On-device: Book + Arrow → tile shows
      arrow then book; Book disabled in the 2nd-item list.
- [x] Architect / Backend / DevOps — N/A.
- [x] Review Coordinator — task filed (T-060); INDEX updated.

## Regression safety
- Reuses the `shopExtraDataKey` slot `MapStateSummary` already reads; single-item
  shops render unchanged (one icon). Full suite 305/305, build clean.
