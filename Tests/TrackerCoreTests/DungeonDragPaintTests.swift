import Testing
@testable import TrackerCore

/// T-072 — drag-paint rules (reference `dragBehavior`, `DungeonUI.fs:1357-1382`).
@Suite("Dungeon drag-paint (T-072)")
struct DungeonDragPaintTests {

    @Test("left over off-the-map paints it back to unmarked")
    func leftRestoresOffMap() {
        let map = DungeonRoomMap()
        map.setRoom(DungeonRoom(isCompleted: true, roomType: .offTheMap), col: 2, row: 2)
        #expect(map.dragPaint(.left, col: 2, row: 2))
        #expect(map.room(col: 2, row: 2).roomType == .unmarked)
        #expect(!map.room(col: 2, row: 2).isCompleted)
        #expect(map.firstInteractionDone)
    }

    @Test("left over a non-off-map room is a no-op")
    func leftNoOpOnMarked() {
        let map = DungeonRoomMap()
        map.setRoom(DungeonRoom(roomType: .doubleMoat), col: 1, row: 1)
        #expect(!map.dragPaint(.left, col: 1, row: 1))
        #expect(map.room(col: 1, row: 1).roomType == .doubleMoat)   // unchanged
    }

    @Test("right over unmarked paints it off-the-map")
    func rightPaintsOffMap() {
        let map = DungeonRoomMap()
        #expect(map.dragPaint(.right, col: 3, row: 3))
        #expect(map.room(col: 3, row: 3).roomType == .offTheMap)
    }

    @Test("right over a marked room is a no-op")
    func rightNoOpOnMarked() {
        let map = DungeonRoomMap()
        map.setRoom(DungeonRoom(roomType: .tee), col: 4, row: 4)
        #expect(!map.dragPaint(.right, col: 4, row: 4))
        #expect(map.room(col: 4, row: 4).roomType == .tee)
    }

    @Test("middle over unmarked paints the default room, completed")
    func middlePaintsDefault() {
        let map = DungeonRoomMap()
        #expect(map.dragPaint(.middle, col: 0, row: 0))
        #expect(map.room(col: 0, row: 0).roomType == DungeonRoomGesture.defaultRoom)
        #expect(map.room(col: 0, row: 0).isCompleted)
    }

    @Test("middle over an off-map room is a no-op (only unmarked)")
    func middleNoOpOnOffMap() {
        let map = DungeonRoomMap()
        map.setRoom(DungeonRoom(roomType: .offTheMap), col: 5, row: 5)
        #expect(!map.dragPaint(.middle, col: 5, row: 5))
        #expect(map.room(col: 5, row: 5).roomType == .offTheMap)
    }

    @Test("painting a run of off-map rooms restores each")
    func paintRun() {
        let map = DungeonRoomMap()
        for c in 0..<4 { map.setRoom(DungeonRoom(roomType: .offTheMap), col: c, row: 0) }
        for c in 0..<4 { map.dragPaint(.left, col: c, row: 0) }
        for c in 0..<4 { #expect(map.room(col: c, row: 0).roomType == .unmarked) }
    }
}

@Suite("Invert + left-drag auto-invert (T-253)")
struct DungeonInvertTests {
    @Test("invert swaps unmarked ↔ off-the-map and leaves marked rooms alone")
    func invertSwaps() {
        let map = DungeonRoomMap()
        var r = map.room(col: 1, row: 1); r.roomType = .nonDescript
        map.setRoom(r, col: 1, row: 1)
        var off = map.room(col: 2, row: 2); off.roomType = .offTheMap
        map.setRoom(off, col: 2, row: 2)
        map.invertOffTheMapWithUnmarked()
        #expect(map.room(col: 0, row: 0).roomType == .offTheMap)
        #expect(map.room(col: 2, row: 2).roomType == .unmarked)
        #expect(map.room(col: 1, row: 1).roomType == .nonDescript)
        #expect(map.hasEverInvertedOrDragged)
        map.invertOffTheMapWithUnmarked()
        #expect(map.room(col: 0, row: 0).roomType == .unmarked)
    }

    @Test("only the first left drag auto-inverts, and only with the option on")
    func autoInvertOnce() {
        let off = DungeonRoomMap()
        off.beginDrag(.left, autoInvert: false)
        #expect(off.room(col: 0, row: 0).roomType == .unmarked)      // option off: no invert
        #expect(off.hasEverInvertedOrDragged)

        let right = DungeonRoomMap()
        right.beginDrag(.right, autoInvert: true)                     // a right drag disarms
        right.beginDrag(.left, autoInvert: true)
        #expect(right.room(col: 0, row: 0).roomType == .unmarked)

        let map = DungeonRoomMap()
        map.beginDrag(.left, autoInvert: true)
        #expect(map.room(col: 0, row: 0).roomType == .offTheMap)
        #expect(map.dragPaint(.left, col: 3, row: 3))                 // paints it back on
        #expect(map.room(col: 3, row: 3).roomType == .unmarked)
        map.beginDrag(.left, autoInvert: true)                        // second drag: no re-invert
        #expect(map.room(col: 0, row: 0).roomType == .offTheMap)
    }

    @Test("middle-drag paints the chosen default room")
    func middleDragDefaultRoom() {
        let map = DungeonRoomMap()
        #expect(map.dragPaint(.middle, col: 0, row: 0, defaultRoom: .nonDescript))
        #expect(map.room(col: 0, row: 0).roomType == .nonDescript)
    }
}
