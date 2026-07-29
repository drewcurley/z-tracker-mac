# Review: feat/dungeon-drag-swap — final (T-182)

**Status:** PASS — drag any dungeon item box onto another box in the same dungeon
to exchange their contents. QA-approved on device ("behavior looks good").

unanimous-consensus: T-182

## Why
The spoiler importer (T-181) fills a dungeon's boxes in the order the log lists
them because the log doesn't distinguish a dungeon's **floor** item from its
**basement** item. Drag-to-swap is the one-gesture correction, and also fixes
ordinary mis-marks.

## What shipped
- `Box.swapContents(with:)` (TrackerCore) — exchanges `cellCurrent` + `playerHas`;
  no-op against itself. Swapping within one item set preserves item uniqueness, so
  it's always legal.
- `DungeonBoxRef` — `Transferable` drag payload (dungeonId + boxIndex) over a custom
  UTI `com.ztracker.dungeon-box`, declared in `UTExportedTypeDeclarations` so the
  in-app drag type is registered (no runtime log).
- `DungeonBoxSwapModifier` on each box in `DungeonCardView`: `.draggable` +
  `.dropDestination`, guarded to the **same dungeon**; a green ring highlights the
  drop target. Disabled boxes (an identified two-boxer's third slot) don't drag or
  accept.

## Scope
- Same-dungeon floor↔basement swap only. Cross-dungeon and named-box
  (coast/armos/white-sword) swaps are out of scope for v1 (matches the request).

## Sign-offs
- [x] Analyst — scoped exactly to the request (same-dungeon swap); motivated by and
      complements T-181 without widening it.
- [x] Architect — pure in-app drag payload; no external I/O; swap preserves the item
      uniqueness invariant, so no illegal duplicate can be produced.
- [x] Data — n/a (no schema); box contents are the existing `cellCurrent`/`playerHas`.
- [x] Backend — swap is a symmetric exchange on the model, guarded same-dungeon and
      against self; drop from another dungeon is rejected.
- [x] Frontend / UX — direct manipulation with a green drop-target ring; existing box
      gestures (left-click toggle, right-click picker, hover ring) coexist —
      user-verified on device.
- [x] SDET — `DungeonBoxTests`: swap exchanges both fields, swap-with-empty moves the
      item, swap-against-self is a no-op. **707 tests pass.**
- [x] DevOps — Info.plist template gains the exported-type declaration; `swift build`/
      `swift test` clean; `.app` rebuilt for QA.
- [x] Review Coordinator — task filed (T-182); INDEX updated.

## Items to address (follow-ups)
- Optional: cross-dungeon and named-box (coast/armos/white-sword) swaps, if the need
  comes up.
- QA note carried: if a future SwiftUI version regresses `.draggable` vs the box's
  tap gestures, fall back to a manual `DragGesture(minimumDistance:)` with
  named-coordinate-space frame hit-testing.
