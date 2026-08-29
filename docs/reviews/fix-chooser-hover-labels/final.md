# Review: fix/chooser-hover-labels — final (T-222)

**Status:** PASS — the room/monster/floor-drop/enemy choosers gained the live hover-label the tile
chooser already had, and the room chooser now spells "Ganon". User QA'd and approved. Ships as
notarized **v1.2.4**.

unanimous-consensus: T-222

## What shipped
- `hoverLabel` + `.onHover` on `RoomTypePicker`, `MonsterPicker`, `FloorDropPicker`, and
  `OverworldEnemyPicker`: the header names the hovered option live, mirroring `GraphicalTileChooser`
  (T-205), with the same enter/exit guard.
- `RoomType.displayDescription` for `.gannon` → "Ganon" (display only; case name unchanged).

## Sign-offs
- [x] Analyst — scope: exactly the two reported bugs; consistent with the existing tile-chooser UX.
- [x] Architect — view-local `@State`; no model/persistence change; the internal `.gannon` case is
      untouched so hotkeys/voice/save round-trips are unaffected.
- [x] Data — n/a.
- [x] Backend — n/a; toggles/picks unchanged.
- [x] Frontend/UX — all four choosers now match the tile chooser's instant label; header reverts to
      its prompt off-hover; "Ganon" matches every other surface.
- [x] SDET — no logic change; **771 tests pass**; no test asserted the old "Gannon" display.
- [x] DevOps — clean build/test; notarized dual-arch DMGs + appcasts for v1.2.4.
- [x] Review Coordinator — T-222 filed; INDEX + CHANGELOG updated; VERSION → 1.2.4.

## Items to address (follow-ups)
- None.
