import Testing
@testable import TrackerCore

/// T-074 — expected old-man counts per dungeon (reference `DungeonData.fs:69-70`).
@Suite("Dungeon old-man counts (T-074)")
struct DungeonOldManCountsTests {
    @Test("first-quest counts match the reference")
    func firstQuest() {
        #expect(DungeonOldManCounts.firstQuest == [1, 1, 1, 1, 3, 2, 3, 2, 3])
        #expect(DungeonOldManCounts.expected(secondQuestDungeons: false, dungeon: 0) == 1)  // L1 → 1
        #expect(DungeonOldManCounts.expected(secondQuestDungeons: false, dungeon: 4) == 3)  // L5 → 3
        #expect(DungeonOldManCounts.expected(secondQuestDungeons: false, dungeon: 8) == 3)  // L9 → 3
    }

    @Test("second-quest counts match the reference and differ from first")
    func secondQuest() {
        #expect(DungeonOldManCounts.secondQuest == [0, 0, 1, 3, 0, 1, 2, 2, 1])
        #expect(DungeonOldManCounts.expected(secondQuestDungeons: true, dungeon: 0) == 0)   // 2Q L1 → 0
        #expect(DungeonOldManCounts.expected(secondQuestDungeons: true, dungeon: 3) == 3)   // 2Q L4 → 3
    }
}
