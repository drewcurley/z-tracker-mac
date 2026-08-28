# Review: feat/drop-rooms-window — final (T-219)

**Status:** PASS — a Drop Rooms breakout reference (per-dungeon never-drop room layouts) plus the
Hint Decoder "Other hints" clickable-title fix. User QA'd and approved. Ships as notarized **v1.2.3**.

unanimous-consensus: T-219

## What shipped
- Hint Decoder: the "Other hints" title toggles the disclosure (not just the chevron).
- `DropRooms` (TrackerCore): 14 room layouts + `never` / `levelSpecific(dungeon:)` /
  `neverDrop(dungeon:)`, transcribed from the community chart (both quests).
- 14 `droproom-*.png` thumbnails sliced from the user's reference at detected uniform geometry
  (137×79, 147px pitch) — bundled resources.
- `DropRoomsView` + `DropRoomImage` loader; `Window(id: DropRoomsWindowID)`; a "Drop Rooms…" button
  in `MapInfoView` between Hint Decoder and Settings. Reads the selected dungeon from
  `focus.selectedDungeonTab`; resolves the number under HDN via `labelChar.wholeNumberValue`.

## Sign-offs
- [x] Analyst — scope: two requested polish items; the Drop Rooms data matches the supplied chart;
      both-quest applicability confirmed with the user.
- [x] Architect — grouping data is pure/testable in TrackerCore; the view layer owns image loading;
      dungeon-number resolution reuses the existing HDN pattern (`expectedOldMen`), so Summary/HDN
      edge cases degrade to a prompt rather than wrong data.
- [x] Data — static reference table; no persistence. Grouping unit-tested per dungeon.
- [x] Backend — no server/logic; window reads shared focus + model state live.
- [x] Frontend/UX — thumbnails re-sliced to uniform framing after a QA pass; window has a title,
      level badge, explanation, adaptive grid; clickable disclosure title matches expectation.
- [x] SDET — `DropRoomsTests` (per-dungeon sets) + `DropRoomImageTests` (all 14 thumbnails load from
      the bundle, guarding against a missing/mis-named resource). **771 tests pass.**
- [x] DevOps — clean build/test; PNG resources bundle via the existing Resources processing; ships as
      notarized dual-arch DMGs + appcasts for v1.2.3.
- [x] Review Coordinator — T-219 filed; INDEX updated; VERSION → 1.2.3.

## Items to address (follow-ups)
- None.
