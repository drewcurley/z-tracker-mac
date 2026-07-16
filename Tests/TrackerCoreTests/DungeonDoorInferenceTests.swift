import Testing
@testable import TrackerCore

/// T-019.12 — conservative door inference (reference `DungeonUI.fs:1148-1167`):
/// a newly-marked room with exactly one plausible entry gets that door set open.
@Suite("Dungeon door inference (T-019.12)")
struct DungeonDoorInferenceTests {

    /// Mark a room with a single marked neighbor to its left; the connecting
    /// (left) door should be inferred open.
    @Test("one marked neighbor → its door is inferred open")
    func singleNeighborInfers() {
        let map = DungeonRoomMap()
        map.setRoom(DungeonRoom(roomType: .nonDescript), col: 2, row: 3)   // left neighbor
        map.setRoom(DungeonRoom(roomType: .doubleMoat), col: 3, row: 3)    // the new room
        #expect(map.inferEntryDoor(col: 3, row: 3))
        // The door between (2,3) and (3,3) is horizontalDoor(col:2,row:3).
        #expect(map.horizontalDoor(col: 2, row: 3) == .yes)
    }

    @Test("infers a vertical door for a neighbor above")
    func neighborAboveInfersVerticalDoor() {
        let map = DungeonRoomMap()
        map.setRoom(DungeonRoom(roomType: .nonDescript), col: 4, row: 1)   // above
        map.setRoom(DungeonRoom(roomType: .nonDescript), col: 4, row: 2)   // new
        #expect(map.inferEntryDoor(col: 4, row: 2))
        #expect(map.verticalDoor(col: 4, row: 1) == .yes)
    }

    @Test("no marked neighbors → no inference (e.g. the entrance room)")
    func noNeighborsNoInference() {
        let map = DungeonRoomMap()
        map.setRoom(DungeonRoom(roomType: .startEnterFromS), col: 3, row: 7)
        #expect(!map.inferEntryDoor(col: 3, row: 7))
    }

    @Test("two marked neighbors → ambiguous, no inference")
    func twoNeighborsNoInference() {
        let map = DungeonRoomMap()
        map.setRoom(DungeonRoom(roomType: .nonDescript), col: 2, row: 3)   // left
        map.setRoom(DungeonRoom(roomType: .nonDescript), col: 4, row: 3)   // right
        map.setRoom(DungeonRoom(roomType: .doubleMoat), col: 3, row: 3)    // new (between)
        #expect(!map.inferEntryDoor(col: 3, row: 3))
        #expect(map.horizontalDoor(col: 2, row: 3) == .unknown)
        #expect(map.horizontalDoor(col: 3, row: 3) == .unknown)
    }

    @Test("a neighbor whose door is already NO isn't a candidate")
    func noDoorNeighborExcluded() {
        let map = DungeonRoomMap()
        // Two neighbors, but the left one's door is a wall (NO): only the right
        // remains a candidate, so the right door is inferred.
        map.setRoom(DungeonRoom(roomType: .nonDescript), col: 2, row: 3)   // left
        map.setRoom(DungeonRoom(roomType: .nonDescript), col: 4, row: 3)   // right
        map.setHorizontalDoor(.no, col: 2, row: 3)                         // left wall
        map.setRoom(DungeonRoom(roomType: .doubleMoat), col: 3, row: 3)
        #expect(map.inferEntryDoor(col: 3, row: 3))
        #expect(map.horizontalDoor(col: 3, row: 3) == .yes)   // right door opened
        #expect(map.horizontalDoor(col: 2, row: 3) == .no)    // left wall untouched
    }

    @Test("single candidate but door already set (not unknown) → left as-is")
    func nonUnknownDoorNotOverwritten() {
        let map = DungeonRoomMap()
        map.setRoom(DungeonRoom(roomType: .nonDescript), col: 2, row: 3)
        map.setHorizontalDoor(.purple, col: 2, row: 3)   // user already marked it
        map.setRoom(DungeonRoom(roomType: .doubleMoat), col: 3, row: 3)
        #expect(!map.inferEntryDoor(col: 3, row: 3))
        #expect(map.horizontalDoor(col: 2, row: 3) == .purple)   // preserved
    }

    @Test("Gannon/Zelda rooms don't infer")
    func gannonZeldaSkipped() {
        let map = DungeonRoomMap()
        map.setRoom(DungeonRoom(roomType: .nonDescript), col: 2, row: 3)
        map.setRoom(DungeonRoom(roomType: .gannon), col: 3, row: 3)
        #expect(!map.inferEntryDoor(col: 3, row: 3))
        #expect(map.horizontalDoor(col: 2, row: 3) == .unknown)
    }

    @Test("the second copy of a transport pair doesn't infer")
    func secondTransportSkipped() {
        let map = DungeonRoomMap()
        map.setRoom(DungeonRoom(roomType: .nonDescript), col: 2, row: 3)   // neighbor
        map.setRoom(DungeonRoom(roomType: .transport1), col: 0, row: 0)    // first copy
        map.setRoom(DungeonRoom(roomType: .transport1), col: 3, row: 3)    // second copy, next to neighbor
        #expect(map.transportCount(1) == 2)
        #expect(!map.inferEntryDoor(col: 3, row: 3))
        #expect(map.horizontalDoor(col: 2, row: 3) == .unknown)
    }

    @Test("an off-map neighbor is not a valid entry")
    func offMapNeighborNotCandidate() {
        let map = DungeonRoomMap()
        map.setRoom(DungeonRoom(roomType: .offTheMap), col: 2, row: 3)     // off-map left
        map.setRoom(DungeonRoom(roomType: .doubleMoat), col: 3, row: 3)
        #expect(!map.inferEntryDoor(col: 3, row: 3))
    }
}
