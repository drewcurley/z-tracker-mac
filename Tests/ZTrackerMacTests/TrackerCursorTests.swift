import Testing
@testable import ZTrackerMac

/// Keyboard-cursor movement, region cycling, and hover-follow (T-134 / T-135).
@MainActor
struct TrackerCursorTests {
    typealias Cell = TrackerFocusState.GridCell

    @Test func startsHiddenOnOverworldAtOrigin() {
        let f = TrackerFocusState()
        #expect(f.cursorShown == false)
        #expect(f.cursorRegion == .overworld)
        #expect(f.cursorCell == Cell(col: 0, row: 0))
    }

    @Test func movingShowsTheCursor() {
        let f = TrackerFocusState()
        f.moveCursor(dcol: 1, drow: 0)
        #expect(f.cursorShown)
        #expect(f.overworldCursor == Cell(col: 1, row: 0))
    }

    @Test func clampsToOverworldBounds() {
        let f = TrackerFocusState()
        f.moveCursor(dcol: -1, drow: -1)
        #expect(f.overworldCursor == Cell(col: 0, row: 0))
        for _ in 0..<50 { f.moveCursor(dcol: 1, drow: 1) }
        #expect(f.overworldCursor == Cell(col: TrackerFocusState.overworldCols - 1,
                                          row: TrackerFocusState.overworldRows - 1))
    }

    @Test func clampsToDungeonBounds() {
        let f = TrackerFocusState()
        f.cycleRegion(forward: true)   // → dungeon map
        for _ in 0..<50 { f.moveCursor(dcol: 1, drow: 1) }
        #expect(f.dungeonCursor == Cell(col: TrackerFocusState.dungeonCols - 1,
                                        row: TrackerFocusState.dungeonRows - 1))
    }

    @Test func cycleStepsThroughRegionsAndWraps() {
        // cycleOrder is [dungeonItem, items, overworld, dungeonMap, blockers, notes]
        // as of T-168 (dungeonItem gained cursor nav; notes joined at the end of the
        // ring); starts on overworld.
        let f = TrackerFocusState()
        #expect(f.cursorRegion == .overworld)
        f.cycleRegion(forward: true)
        #expect(f.cursorRegion == .dungeonMap)
        #expect(f.cursorShown)
        f.cycleRegion(forward: true)
        #expect(f.cursorRegion == .blockers)
        f.cycleRegion(forward: true)
        #expect(f.cursorRegion == .notes)
        f.cycleRegion(forward: true)          // wraps to the front of the order
        #expect(f.cursorRegion == .dungeonItem)
        f.cycleRegion(forward: true)
        #expect(f.cursorRegion == .items)
        f.cycleRegion(forward: false)         // backward
        #expect(f.cursorRegion == .dungeonItem)
        f.cycleRegion(forward: false)         // backward wraps to the end
        #expect(f.cursorRegion == .notes)
    }

    @Test func eachRegionRemembersItsOwnPosition() {
        let f = TrackerFocusState()
        f.moveCursor(dcol: 3, drow: 2)                 // overworld → (3,2)
        f.cycleRegion(forward: true)                    // → dungeon map (0,0)
        f.moveCursor(dcol: 1, drow: 4)                 // dungeon → (1,4)
        #expect(f.dungeonCursor == Cell(col: 1, row: 4))
        f.cycleRegion(forward: false)                   // back to overworld
        #expect(f.overworldCursor == Cell(col: 3, row: 2))
        #expect(f.cursorCell == Cell(col: 3, row: 2))
    }

    @Test func itemsRegionNavigatesAndClamps() {
        let f = TrackerFocusState()
        f.hoverItems(col: 2, row: 1)
        #expect(f.cursorRegion == .items)
        #expect(f.cursorCell == Cell(col: 2, row: 1))
        for _ in 0..<20 { f.moveCursor(dcol: 1, drow: 1) }
        #expect(f.itemsCursor == Cell(col: TrackerFocusState.itemsCols - 1,
                                      row: TrackerFocusState.itemsRows - 1))
    }

    @Test func hoverOverworldMovesCursorAndSwitchesRegion() {
        let f = TrackerFocusState()
        f.cycleRegion(forward: true)                    // on dungeon map
        f.hoverOverworld(col: 5, row: 3)
        #expect(f.cursorRegion == .overworld)
        #expect(f.overworldCursor == Cell(col: 5, row: 3))
        #expect(f.cursorShown)
    }

    @Test func hoverDungeonMovesCursorAndSwitchesRegion() {
        let f = TrackerFocusState()
        f.hoverDungeon(col: 6, row: 7)
        #expect(f.cursorRegion == .dungeonMap)
        #expect(f.dungeonCursor == Cell(col: 6, row: 7))
        #expect(f.cursorShown)
    }

    @Test func keyboardNudgeContinuesFromHoverPosition() {
        let f = TrackerFocusState()
        f.hoverOverworld(col: 8, row: 4)               // mouse parks here
        f.moveCursor(dcol: 1, drow: 0)                 // then a keyboard nudge
        #expect(f.overworldCursor == Cell(col: 9, row: 4))
    }
}
