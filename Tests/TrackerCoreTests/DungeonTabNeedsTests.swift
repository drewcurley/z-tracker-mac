import Testing
@testable import TrackerCore

/// T-084 — the per-dungeon "needs" flags that decorate each dungeon tab
/// (reference `DungeonUI.fs:849-867`).
@Suite("Dungeon tab needs markers (T-084)")
struct DungeonTabNeedsTests {
    @Test("Hungry-Goriya: shown when present, checked once fed (complete)")
    func hungryGoriya() {
        let map = DungeonRoomMap()
        #expect(!map.hasHungryGoriya)
        map.setRoom(DungeonRoom(roomType: .hungryGoriyaMeatBlock), col: 2, row: 3)
        #expect(map.hasHungryGoriya)
        #expect(!map.hungryGoriyaFed)
        map.setRoom(DungeonRoom(isCompleted: true, roomType: .hungryGoriyaMeatBlock), col: 2, row: 3)
        #expect(map.hungryGoriyaFed)
    }

    @Test("Bomb-Upgrade dot: only while the upgrade is unbought (incomplete)")
    func bombUpgrade() {
        let map = DungeonRoomMap()
        #expect(!map.hasUnboughtBombUpgrade)
        map.setRoom(DungeonRoom(roomType: .bombUpgrade), col: 0, row: 0)
        #expect(map.hasUnboughtBombUpgrade)
        map.setRoom(DungeonRoom(isCompleted: true, roomType: .bombUpgrade), col: 0, row: 0)
        #expect(!map.hasUnboughtBombUpgrade)   // bought → dot clears
    }

    @Test("NPC-hint dot: only while the hint is unread (incomplete)")
    func oldManHint() {
        let map = DungeonRoomMap()
        #expect(!map.hasUnreadOldManHint)
        map.setRoom(DungeonRoom(roomType: .oldManHint), col: 4, row: 4)
        #expect(map.hasUnreadOldManHint)
        map.setRoom(DungeonRoom(isCompleted: true, roomType: .oldManHint), col: 4, row: 4)
        #expect(!map.hasUnreadOldManHint)      // read → dot clears
    }
}
