import Testing
@testable import TrackerCore

/// T-071 — the vanilla dungeon footprints must match the reference exactly and be
/// well-formed (9 dungeons × 8×8 of only `X`/`.`).
@Suite("Vanilla dungeon data (T-071)")
struct VanillaDungeonDataTests {

    @Test("both quests are 9 dungeons of 8 rows × 8 chars, only X/.")
    func wellFormed() {
        for quest in VanillaQuest.allCases {
            let all = quest == .first ? VanillaDungeonData.firstQuest : VanillaDungeonData.secondQuest
            #expect(all.count == 9)
            for dungeon in all {
                #expect(dungeon.count == 8)
                for row in dungeon {
                    #expect(row.count == 8)
                    #expect(row.allSatisfy { $0 == "X" || $0 == "." })
                }
            }
        }
    }

    @Test("spot-checks against the reference layouts")
    func spotChecks() {
        // First quest L1: top two rows empty; row 2 has rooms at cols 2,3.
        #expect(!VanillaDungeonData.isRoom(.first, dungeon: 0, col: 0, row: 0))
        #expect(VanillaDungeonData.isRoom(.first, dungeon: 0, col: 2, row: 2))
        #expect(VanillaDungeonData.isRoom(.first, dungeon: 0, col: 3, row: 2))
        #expect(!VanillaDungeonData.isRoom(.first, dungeon: 0, col: 4, row: 2))

        // First quest L9: row 0 is ".XXXXXXX"; row 1 all rooms.
        #expect(!VanillaDungeonData.isRoom(.first, dungeon: 8, col: 0, row: 0))
        #expect(VanillaDungeonData.isRoom(.first, dungeon: 8, col: 1, row: 0))
        #expect(VanillaDungeonData.isRoom(.first, dungeon: 8, col: 0, row: 1))

        // Second quest L8: row 0 all rooms; row 7 only the last col.
        #expect(VanillaDungeonData.isRoom(.second, dungeon: 7, col: 0, row: 0))
        #expect(VanillaDungeonData.isRoom(.second, dungeon: 7, col: 7, row: 7))
        #expect(!VanillaDungeonData.isRoom(.second, dungeon: 7, col: 0, row: 7))
    }

    @Test("out-of-range coordinates are not rooms")
    func outOfRange() {
        #expect(!VanillaDungeonData.isRoom(.first, dungeon: 0, col: 8, row: 0))
        #expect(!VanillaDungeonData.isRoom(.first, dungeon: 0, col: 0, row: 8))
        #expect(!VanillaDungeonData.isRoom(.first, dungeon: 9, col: 0, row: 0))
    }

    @Test("room counts are plausible (non-empty, within the 64-cell grid)")
    func roomCounts() {
        for quest in VanillaQuest.allCases {
            for d in 0..<9 {
                let n = VanillaDungeonData.roomCount(quest, dungeon: d)
                #expect(n > 0 && n <= 64)
            }
        }
        // L9 first quest is the big one — most of the grid.
        #expect(VanillaDungeonData.roomCount(.first, dungeon: 8) >= 48)
    }
}
