import Testing
import TrackerCore
@testable import ZTrackerMac

/// The shared dungeon-room mark-apply used by both the pickers and the hotkey path (T-135).
@MainActor
struct DungeonRoomMarkApplyTests {
    private func freshMap() -> DungeonRoomMap { DungeonRoomMap() }

    // Diagnostic (2026-07-18): does the shared apply path infer the entry door when
    // marking a room adjacent to an already-marked one? (Voice + hotkey + click all use
    // this path.) If this passes, voice door inference works *when the setting is on*.
    @Test func markingAdjacentRoomInfersConnectingDoorWhenEnabled() {
        let map = freshMap()
        // Mark room A at (0,0), then the adjacent room B at (1,0), inference ON.
        DungeonRoomMark.applyRoomType(.nonDescript, col: 0, row: 0, map: map, inferDoors: true)
        DungeonRoomMark.applyRoomType(.nonDescript, col: 1, row: 0, map: map, inferDoors: true)
        // The wall between A(0,0) and B(1,0) is the horizontal door at col 0 — should now be open.
        #expect(map.horizontalDoor(col: 0, row: 0) == .yes)
    }

    @Test func markingAdjacentRoomDoesNotInferWhenDisabled() {
        let map = freshMap()
        DungeonRoomMark.applyRoomType(.nonDescript, col: 0, row: 0, map: map, inferDoors: false)
        DungeonRoomMark.applyRoomType(.nonDescript, col: 1, row: 0, map: map, inferDoors: false)
        #expect(map.horizontalDoor(col: 0, row: 0) == .unknown)
    }

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
