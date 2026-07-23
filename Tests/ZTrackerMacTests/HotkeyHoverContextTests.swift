import Testing
@testable import ZTrackerMac
@testable import TrackerCore

/// T-168 — hover decides which context a hotkey acts in, with the keyboard cursor as
/// the fallback. These cover the resolution rules in `TrackerFocusState`; the marking
/// itself is already covered by the per-region apply suites.
@Suite("Hotkey hover context (T-168)")
@MainActor
struct HotkeyHoverContextTests {

    @Test("with nothing hovered and no cursor shown, no region is active")
    func noneActive() {
        let f = TrackerFocusState()
        #expect(f.activeRegion == nil)
    }

    @Test("hover wins over the keyboard cursor's region")
    func hoverBeatsCursor() {
        let f = TrackerFocusState()
        f.cycleRegion(forward: true)            // cursor lands somewhere, cursorShown = true
        f.hoverBlockers(col: 1, row: 2)
        #expect(f.activeRegion == .blockers)
        #expect(f.cell(in: .blockers) == .init(col: 1, row: 2))
    }

    @Test("leaving a region falls back to the cursor, which stays where hover left it")
    func fallsBackToCursor() {
        let f = TrackerFocusState()
        f.hoverOverworld(col: 4, row: 3)
        #expect(f.activeRegion == .overworld)
        f.endHover(.overworld)
        // Cursor region + cell survive; only the hover claim is dropped.
        #expect(f.activeRegion == .overworld)
        #expect(f.overworldCursor == .init(col: 4, row: 3))
    }

    @Test("exit from a region that isn't hovered any more is ignored")
    func staleExitIgnored() {
        let f = TrackerFocusState()
        f.hoverOverworld(col: 1, row: 1)
        f.hoverItems(col: 0, row: 0)            // moved to a neighbouring region
        f.endHover(.overworld)                  // the old region's late exit
        #expect(f.activeRegion == .items)       // must not have cleared the new hover
    }

    @Test("deliberate keyboard nav takes over from a resting mouse")
    func keyboardNavClearsHover() {
        let f = TrackerFocusState()
        f.hoverOverworld(col: 2, row: 2)
        f.cycleRegion(forward: true)            // mouse hasn't moved, but the user cycled
        #expect(f.hoverRegion == nil)
        #expect(f.activeRegion == f.cursorRegion)
        #expect(f.activeRegion != .overworld)
    }

    @Test("moving the cursor also drops the hover claim")
    func moveCursorClearsHover() {
        let f = TrackerFocusState()
        f.hoverItems(col: 1, row: 1)
        f.moveCursor(dcol: 1, drow: 0)
        #expect(f.hoverRegion == nil)
        #expect(f.itemsCursor == .init(col: 2, row: 1))
    }

    @Test("the dungeon-item region is in the cycle and spans 9 dungeons x 3 boxes")
    func dungeonItemRegion() {
        #expect(TrackerFocusState.cycleOrder.contains(.dungeonItem))
        let d = TrackerFocusState.dims(.dungeonItem)
        #expect(d == (9, 3))
        let f = TrackerFocusState()
        f.hoverDungeonItem(col: 8, row: 2)      // last dungeon, bottom box
        #expect(f.activeRegion == .dungeonItem)
        f.moveCursor(dcol: 1, drow: 1)          // already at the corner — clamps
        #expect(f.dungeonItemCursor == .init(col: 8, row: 2))
    }

    /// The nine dungeon cards run **horizontally** and each card's boxes stack
    /// **vertically**, so the arrow keys must follow the eye: left/right between
    /// dungeons, up/down through one dungeon's item stack. Shipping this transposed
    /// made the arrows feel inverted, so it's pinned here.
    @Test("dungeon-item arrows follow the on-screen layout, not the transpose")
    func dungeonItemArrowsMatchLayout() {
        let f = TrackerFocusState()
        f.hoverDungeonItem(col: 3, row: 1)      // dungeon 4, middle box
        f.moveCursor(dcol: 1, drow: 0)          // right → next dungeon, same box
        #expect(f.dungeonItemCursor == .init(col: 4, row: 1))
        f.moveCursor(dcol: 0, drow: 1)          // down → next box, same dungeon
        #expect(f.dungeonItemCursor == .init(col: 4, row: 2))
        f.moveCursor(dcol: 0, drow: -1)         // up → back up the stack
        #expect(f.dungeonItemCursor == .init(col: 4, row: 1))
        f.moveCursor(dcol: -1, drow: 0)         // left → previous dungeon
        #expect(f.dungeonItemCursor == .init(col: 3, row: 1))
        // Left/right spans all nine dungeons; up/down only the three boxes.
        f.moveCursor(dcol: 99, drow: 99)
        #expect(f.dungeonItemCursor == .init(col: 8, row: 2))
    }

    @Test("Notes is the sixth region, last in the cycle")
    func notesRegionInCycle() {
        #expect(TrackerFocusState.cycleOrder.last == .notes)
        #expect(TrackerFocusState.cycleOrder.count == 6)
        let f = TrackerFocusState()
        f.cursorRegion = .blockers
        f.cycleRegion(forward: true)
        #expect(f.cursorRegion == .notes)
        f.cycleRegion(forward: true)            // wraps back to the front
        #expect(f.cursorRegion == .dungeonItem)
    }

    /// Cycling *through* Notes must not capture the keyboard, or the cycle key itself
    /// gets swallowed the moment you land — you'd be stuck typing your own hotkey.
    @Test("cycling onto Notes parks without taking focus")
    func cyclingOntoNotesDoesNotFocus() {
        let f = TrackerFocusState()
        f.cursorRegion = .blockers
        f.cycleRegion(forward: true)
        #expect(f.cursorRegion == .notes)
        #expect(f.notesFocused == false)        // parked, not typing
        #expect(f.notesParked)
        f.cycleRegion(forward: true)            // the cycle key still works
        #expect(f.cursorRegion == .dungeonItem)
        #expect(f.notesParked == false)
    }

    @Test("typing takes focus; Escape parks again without leaving the region")
    func typingFocusesAndEscapeParks() {
        let f = TrackerFocusState()
        f.cursorRegion = .blockers
        f.cycleRegion(forward: true)            // parked on Notes
        f.setNotesFocus(true)                   // first alphanumeric starts a note
        #expect(f.notesFocused)
        #expect(f.notesParked == false)         // focused, so keys belong to the field
        f.setNotesFocus(false)                  // Escape
        #expect(f.notesFocused == false)
        #expect(f.cursorRegion == .notes)       // still parked here…
        #expect(f.notesParked)
        f.cycleRegion(forward: true)            // …and the ring continues
        #expect(f.cursorRegion == .dungeonItem)
    }

    @Test("navigation globals stay live while parked, other bindings yield to typing")
    func navigationSurvivesParking() {
        #expect(GlobalHotkeyDispatcher.isNavigation("Global_CycleRegionForward"))
        #expect(GlobalHotkeyDispatcher.isNavigation("Global_MoveCursorLeft"))
        // Marking / toggle globals must NOT pre-empt typing a note.
        #expect(GlobalHotkeyDispatcher.isNavigation("Global_ToggleBombs") == false)
        #expect(GlobalHotkeyDispatcher.isNavigation("Global_DungeonTab3") == false)
    }

    @Test("a cursor that was never shown isn't parked on Notes")
    func unshownCursorIsNotParked() {
        let f = TrackerFocusState()
        f.cursorRegion = .notes                 // region set, but cursor never used
        #expect(f.cursorShown == false)
        #expect(f.notesParked == false)         // so stray letters don't start a note
    }

    @Test("clicking into Notes claims the cursor")
    func clickIntoNotesClaimsCursor() {
        let f = TrackerFocusState()
        f.hoverOverworld(col: 3, row: 3)
        f.setNotesFocus(true)                   // what a click into the field does
        #expect(f.cursorRegion == .notes)
        #expect(f.hoverRegion == nil)           // a stale hover can't outrank it
        #expect(f.activeRegion == .notes)
    }

    @Test("Notes has nothing to navigate, so arrows don't disturb it")
    func notesHasNoGrid() {
        let f = TrackerFocusState()
        f.setNotesFocus(true)
        f.moveCursor(dcol: 1, drow: 1)
        #expect(f.cursorRegion == .notes)
        #expect(f.cursorCell == .init(col: 0, row: 0))
    }

    @Test("hint-zone hover is tracked by target, independent of the grid regions")
    func hintHover() {
        let f = TrackerFocusState()
        f.hoverOverworld(col: 0, row: 0)
        f.beginHoverHint(HintTarget.whiteSwordCave)
        #expect(f.hoveredHintTarget == HintTarget.whiteSwordCave)
        #expect(f.activeRegion == .overworld)   // the grid hover is untouched
        f.endHoverHint(HintTarget.magicalSwordCave)   // stale exit for a different box
        #expect(f.hoveredHintTarget == HintTarget.whiteSwordCave)
        f.endHoverHint(HintTarget.whiteSwordCave)
        #expect(f.hoveredHintTarget == nil)
    }

    @Test("every HintZone_ selector suffix resolves to a zone")
    func hintZoneNamesRoundTrip() {
        let names = ["Unknown", "DeathMountain", "Lake", "LostHills", "River", "Grave",
                     "Desert", "Coast", "DeadWoods", "CloseToStart", "Forest"]
        for n in names {
            #expect(HintZone.fromHotKeyName(n) != nil, "\(n) should map to a zone")
        }
        #expect(HintZone.fromHotKeyName("CloseToStart") == .nearStart)
        #expect(HintZone.fromHotKeyName("NotAZone") == nil)
        // Every zone must be reachable by some name, or a binding would be dead.
        let reachable = Set(names.compactMap { HintZone.fromHotKeyName($0) })
        #expect(reachable.count == HintZone.allCases.count)
    }
}
