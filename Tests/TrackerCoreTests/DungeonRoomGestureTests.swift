import Testing
@testable import TrackerCore

/// T-019.6 (D2a) — the plain left-click behavior, ported from the reference
/// mouse handler (`Z1R_WPF/DungeonUI.fs:1418-1450`). The resolver is pure, so
/// these pin the exact branch order.
@Suite("Dungeon room left-click gesture (T-019.6)")
struct DungeonRoomGestureTests {

    @Test("first interaction drops the entrance (from south), completed")
    func firstInteractionPlacesEntrance() {
        let out = DungeonRoomGesture.leftClick(on: DungeonRoom(), isFirstInteraction: true)
        #expect(out.room.roomType == .startEnterFromS)
        #expect(out.room.isCompleted)
        #expect(out.clearsFirstInteraction)
    }

    @Test("first interaction on an already-marked room still forces the entrance")
    func firstInteractionOverridesMarked() {
        // Matches the reference: the isFirstTime branch runs before the cycle/
        // toggle branches, regardless of current type.
        let marked = DungeonRoom(roomType: .nonDescript)
        let out = DungeonRoomGesture.leftClick(on: marked, isFirstInteraction: true)
        #expect(out.room.roomType == .startEnterFromS)
        #expect(out.room.isCompleted)
    }

    @Test("on a touched dungeon, clicking an unknown room marks default + completed")
    func acceleratorMarksDefault() {
        let out = DungeonRoomGesture.leftClick(on: DungeonRoom(), isFirstInteraction: false)
        #expect(out.room.roomType == DungeonRoomGesture.defaultRoom)
        #expect(out.room.roomType == .maybePushBlock)
        #expect(out.room.isCompleted)
        #expect(!out.clearsFirstInteraction)
    }

    @Test("'Default to NonDescript' (T-206) makes the accelerator mark NonDescript instead")
    func acceleratorHonorsDefaultRoomOverride() {
        let out = DungeonRoomGesture.leftClick(on: DungeonRoom(), isFirstInteraction: false,
                                               defaultRoom: .nonDescript)
        #expect(out.room.roomType == .nonDescript)
        #expect(out.room.isCompleted)
    }

    @Test("entrance rooms cycle S→W→N→E→S")
    func entranceCycles() {
        var type = RoomType.startEnterFromS
        let expected: [RoomType] = [.startEnterFromW, .startEnterFromN, .startEnterFromE, .startEnterFromS]
        for want in expected {
            let out = DungeonRoomGesture.leftClick(on: DungeonRoom(roomType: type), isFirstInteraction: false)
            #expect(out.room.roomType == want)
            type = out.room.roomType
        }
    }

    @Test("cycling an entrance leaves completion untouched")
    func entranceCycleKeepsCompletion() {
        let room = DungeonRoom(isCompleted: true, roomType: .startEnterFromN)
        let out = DungeonRoomGesture.leftClick(on: room, isFirstInteraction: false)
        #expect(out.room.roomType == .startEnterFromE)
        #expect(out.room.isCompleted)   // unchanged
    }

    @Test("off-the-map paints back to unmarked")
    func offMapPaintsBack() {
        let out = DungeonRoomGesture.leftClick(on: DungeonRoom(roomType: .offTheMap), isFirstInteraction: false)
        #expect(out.room.roomType == .unmarked)
    }

    @Test("a plain marked room toggles completedness both ways")
    func togglesCompletion() {
        let incomplete = DungeonRoom(isCompleted: false, roomType: .doubleMoat)
        let a = DungeonRoomGesture.leftClick(on: incomplete, isFirstInteraction: false)
        #expect(a.room.isCompleted)
        #expect(a.room.roomType == .doubleMoat)   // type unchanged

        let b = DungeonRoomGesture.leftClick(on: a.room, isFirstInteraction: false)
        #expect(!b.room.isCompleted)
    }

    @Test("toggling completion preserves monster + floor drop")
    func togglePreservesDetails() {
        let room = DungeonRoom(isCompleted: false, roomType: .doubleMoat,
                               monsterDetail: .gleeok, floorDropDetail: .triforce)
        let out = DungeonRoomGesture.leftClick(on: room, isFirstInteraction: false)
        #expect(out.room.monsterDetail == .gleeok)
        #expect(out.room.floorDropDetail == .triforce)
    }
}

/// The map-level integration: `leftClick` runs the resolver, commits, and manages
/// the per-dungeon first-interaction flag.
@Suite("DungeonRoomMap.leftClick integration (T-019.6)")
struct DungeonRoomMapLeftClickTests {

    @Test("first left-click places the entrance and clears the first-interaction flag")
    func firstClickEntrance() {
        let map = DungeonRoomMap()
        #expect(!map.firstInteractionDone)
        map.leftClick(col: 3, row: 7)
        #expect(map.room(col: 3, row: 7).roomType == .startEnterFromS)
        #expect(map.room(col: 3, row: 7).isCompleted)
        #expect(map.firstInteractionDone)
    }

    @Test("second click on the entrance cycles it (not a re-entrance)")
    func secondClickCycles() {
        let map = DungeonRoomMap()
        map.leftClick(col: 3, row: 7)                 // entrance S
        map.leftClick(col: 3, row: 7)                 // cycle → W
        #expect(map.room(col: 3, row: 7).roomType == .startEnterFromW)
    }

    @Test("after the first interaction, clicking a blank room uses the accelerator")
    func acceleratorAfterFirst() {
        let map = DungeonRoomMap()
        map.leftClick(col: 0, row: 0)                 // first interaction elsewhere
        map.leftClick(col: 5, row: 5)                 // blank room → default+complete
        #expect(map.room(col: 5, row: 5).roomType == .maybePushBlock)
        #expect(map.room(col: 5, row: 5).isCompleted)
    }

    @Test("old-man count reflects rooms marked via the accelerator + picker")
    func oldManCountTracks() {
        let map = DungeonRoomMap()
        map.firstInteractionDone = true
        map.setRoom(DungeonRoom(roomType: .oldManHint), col: 1, row: 1)
        map.setRoom(DungeonRoom(roomType: .bombUpgrade), col: 2, row: 2)
        #expect(map.oldManCount == 2)
    }
}
