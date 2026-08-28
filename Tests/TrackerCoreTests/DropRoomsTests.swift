import Testing
@testable import TrackerCore

@Suite("Drop Rooms reference (T-219)")
struct DropRoomsTests {
    @Test("the universal never-drop set is the five NEVER rooms")
    func neverSet() {
        #expect(DropRooms.never.map(\.name) == ["Zelda", "3 Rows", "Spike Trap", "Single Block", "Circle Wall"])
    }

    @Test("each dungeon's never-drop set matches the chart")
    func perDungeon() {
        #expect(DropRooms.levelSpecific(dungeon: 1).map(\.name) ==
                ["Spiral Stair", "Gleeok", "Maze", "T", "Diamond Stair", "Single 6"])
        for d in [2, 3, 6, 7, 8, 9] {
            #expect(DropRooms.levelSpecific(dungeon: d).map(\.name) ==
                    ["Five Pair", "Maze", "Pointless Moat"], "level \(d)")
        }
        #expect(DropRooms.levelSpecific(dungeon: 4).map(\.name) ==
                ["Grid", "Diamond Stair", "Five Pair", "Single 6", "Spiral Stair"])
        #expect(DropRooms.levelSpecific(dungeon: 5).map(\.name) ==
                ["Grid", "Diamond Stair", "Gleeok", "Maze", "Spiral Stair", "Five Pair", "Single 6"])
    }

    @Test("neverDrop is the universal set plus the level set, universal first")
    func combined() {
        let d1 = DropRooms.neverDrop(dungeon: 1)
        #expect(Array(d1.prefix(5)) == DropRooms.never)
        #expect(d1.count == 5 + 6)
        #expect(DropRooms.neverDrop(dungeon: 4).count == 5 + 5)
    }

    @Test("every room's image key follows the droproom- convention")
    func imageKeys() {
        let all = DropRooms.never + (1...9).flatMap { DropRooms.levelSpecific(dungeon: $0) }
        for r in all { #expect(r.imageKey.hasPrefix("droproom-"), "\(r.name)") }
    }
}
