import Testing
import TrackerCore
@testable import ZTrackerMac

/// The shared dungeon-room mark-apply used by both the pickers and the hotkey path (T-135).
@MainActor
struct DungeonRoomMarkApplyTests {
    private func freshMap() -> DungeonRoomMap { DungeonRoomMap() }

    @Test func hotkeySetsRoomType() {
        let map = freshMap()
        let ok = DungeonRoomMark.applyHotkey("DungeonRoom_RoomType_CircleMoat",
                                             col: 3, row: 4, map: map, inferDoors: false)
        #expect(ok)
        #expect(map.room(col: 3, row: 4).roomType == .circleMoat)
    }

    @Test func hotkeyTogglesMonster() {
        let map = freshMap()
        DungeonRoomMark.applyHotkey("DungeonRoom_MonsterDetail_Aquamentus",
                                    col: 1, row: 1, map: map, inferDoors: false)
        #expect(map.room(col: 1, row: 1).monsters.contains(.aquamentus))
    }

    @Test func hotkeySetsFloorDrop() {
        let map = freshMap()
        DungeonRoomMark.applyHotkey("DungeonRoom_FloorDropDetail_Triforce",
                                    col: 2, row: 2, map: map, inferDoors: false)
        #expect(map.room(col: 2, row: 2).floorDropDetail == .triforce)
    }

    @Test func doorNudgesAreNotRoomMarks() {
        let map = freshMap()
        let ok = DungeonRoomMark.applyHotkey("DungeonRoom_WestDoorIncrement",
                                             col: 0, row: 0, map: map, inferDoors: false)
        #expect(ok == false)
    }
}
