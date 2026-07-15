import Testing
@testable import TrackerCore

@Suite("Auto-map vanilla dungeons (T-035.x)")
struct AutoMapVanillaDungeonsTests {
    @Test("first-quest coordinates place dungeons 1–9 at the canonical screens")
    func firstQuest() {
        let m = TrackerModel()
        m.autoMapVanillaDungeons(secondQuest: false)
        for (i, loc) in OverworldVanillaDungeons.firstQuest.enumerated() {
            #expect(m.overworldGrid.mark(column: loc.column, row: loc.row) == .dungeon(i + 1))
        }
        // Exactly nine dungeon marks exist.
        var count = 0
        for c in 0..<OverworldGrid.columnCount {
            for r in 0..<OverworldGrid.rowCount {
                if case .dungeon = m.overworldGrid.mark(column: c, row: r) { count += 1 }
            }
        }
        #expect(count == 9)
    }

    @Test("second-quest coordinates differ and place all nine")
    func secondQuest() {
        let m = TrackerModel()
        m.autoMapVanillaDungeons(secondQuest: true)
        for (i, loc) in OverworldVanillaDungeons.secondQuest.enumerated() {
            #expect(m.overworldGrid.mark(column: loc.column, row: loc.row) == .dungeon(i + 1))
        }
    }

    @Test("re-mapping clears prior dungeon marks but keeps other marks")
    func clearsPriorDungeonsOnly() {
        let m = TrackerModel()
        // A stray dungeon mark somewhere it won't be in FQ, plus a shop to keep.
        m.overworldGrid.setMark(.dungeon(3), column: 0, row: 1)
        m.overworldGrid.setMark(.shop(.bomb), column: 15, row: 7)

        m.autoMapVanillaDungeons(secondQuest: false)

        // The stray dungeon mark is gone.
        #expect(m.overworldGrid.mark(column: 0, row: 1) == .unmarked)
        // The shop survives.
        #expect(m.overworldGrid.mark(column: 15, row: 7) == .shop(.bomb))
        // Still exactly nine dungeons (no duplicate of 3).
        var count = 0
        for c in 0..<OverworldGrid.columnCount {
            for r in 0..<OverworldGrid.rowCount {
                if case .dungeon = m.overworldGrid.mark(column: c, row: r) { count += 1 }
            }
        }
        #expect(count == 9)
    }

    @Test("overwriting a take-any tile releases its Items-group slot (T-066)")
    func releasesTakeAnySlot() {
        let m = TrackerModel()
        // Put a claimed take-any exactly on FQ dungeon 1's screen (7,3).
        let d1 = OverworldVanillaDungeons.firstQuest[0]
        m.setOverworldTakeAny(.takenHeart, column: d1.column, row: d1.row)
        #expect(m.playerProgress.takeAnyHearts[0] == .takenHeart)

        m.autoMapVanillaDungeons(secondQuest: false)
        #expect(m.overworldGrid.mark(column: d1.column, row: d1.row) == .dungeon(1))
        // The heart slot was freed, not left stranded.
        #expect(m.playerProgress.takeAnyHearts.allSatisfy { $0 == .untaken })
    }
}
