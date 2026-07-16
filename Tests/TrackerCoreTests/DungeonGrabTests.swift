import Testing
@testable import TrackerCore

/// T-073 — the GRAB algorithm foundation: contiguous-region detection and the
/// cut/paste move (reference `GrabHelper`, `Dungeon.fs:61-149`). Interaction
/// (grab mode, drag-to-drop, undo prompt) is a later slice; this pins the logic.
@Suite("Dungeon grab model (T-073)")
struct DungeonGrabTests {
    private typealias Coord = DungeonRoomMap.RoomCoord

    @Test("contiguous region is the connected blob of non-empty rooms")
    func region() {
        let map = DungeonRoomMap()
        for c in 0..<3 { map.setRoom(DungeonRoom(roomType: .nonDescript), col: c, row: 0) }
        map.setRoom(DungeonRoom(roomType: .nonDescript), col: 0, row: 1)   // hangs off (0,0)
        map.setRoom(DungeonRoom(roomType: .tee), col: 5, row: 5)           // disconnected
        let region = map.contiguousRegion(col: 0, row: 0)
        #expect(region == Set([Coord(col: 0, row: 0), Coord(col: 1, row: 0),
                               Coord(col: 2, row: 0), Coord(col: 0, row: 1)]))
        #expect(!region.contains(Coord(col: 5, row: 5)))
    }

    @Test("region from an empty room is empty")
    func regionEmptyStart() {
        let map = DungeonRoomMap()
        #expect(map.contiguousRegion(col: 3, row: 3).isEmpty)
    }

    @Test("off-the-map rooms are empty, so they don't join a region")
    func offMapNotInRegion() {
        let map = DungeonRoomMap()
        map.setRoom(DungeonRoom(roomType: .nonDescript), col: 0, row: 0)
        map.setRoom(DungeonRoom(roomType: .offTheMap), col: 1, row: 0)
        map.setRoom(DungeonRoom(roomType: .nonDescript), col: 2, row: 0)   // cut off by the off-map
        let region = map.contiguousRegion(col: 0, row: 0)
        #expect(region == Set([Coord(col: 0, row: 0)]))
    }

    @Test("moving a region relocates rooms, circles, and internal doors; clears the source")
    func move() {
        let map = DungeonRoomMap()
        map.setRoom(DungeonRoom(roomType: .doubleMoat), col: 0, row: 0)
        map.setRoom(DungeonRoom(roomType: .tee), col: 1, row: 0)
        map.setHorizontalDoor(.yes, col: 0, row: 0)   // door between the two rooms
        map.toggleCircle(col: 0, row: 0)

        let region = map.contiguousRegion(col: 0, row: 0)
        map.moveRegion(region, byColumns: 0, rows: 2)

        // Source cleared.
        #expect(map.room(col: 0, row: 0).roomType == .unmarked)
        #expect(map.room(col: 1, row: 0).roomType == .unmarked)
        #expect(!map.isCircled(col: 0, row: 0))
        #expect(map.horizontalDoor(col: 0, row: 0) == .unknown)
        // Destination populated + door + circle carried.
        #expect(map.room(col: 0, row: 2).roomType == .doubleMoat)
        #expect(map.room(col: 1, row: 2).roomType == .tee)
        #expect(map.horizontalDoor(col: 0, row: 2) == .yes)
        #expect(map.isCircled(col: 0, row: 2))
    }

    @Test("region cells that would leave the grid are dropped")
    func moveOffGrid() {
        let map = DungeonRoomMap()
        map.setRoom(DungeonRoom(roomType: .nonDescript), col: 6, row: 0)
        map.setRoom(DungeonRoom(roomType: .tee), col: 7, row: 0)
        let region = map.contiguousRegion(col: 6, row: 0)
        map.moveRegion(region, byColumns: 2, rows: 0)   // (7,0)->off-grid, (6,0)->(8,0) off-grid too? no: 6+2=8 off, 7+2=9 off
        // Both land off-grid → both dropped; source cleared.
        #expect(map.room(col: 6, row: 0).roomType == .unmarked)
        #expect(map.room(col: 7, row: 0).roomType == .unmarked)
    }

    @Test("moving a transport room keeps the transport count consistent")
    func moveTransportRecount() {
        let map = DungeonRoomMap()
        map.setRoom(DungeonRoom(roomType: .transport1), col: 0, row: 0)
        #expect(map.transportCount(1) == 1)
        let region = map.contiguousRegion(col: 0, row: 0)
        map.moveRegion(region, byColumns: 3, rows: 3)
        #expect(map.transportCount(1) == 1)   // still exactly one, now at (3,3)
        #expect(map.room(col: 3, row: 3).roomType == .transport1)
    }

    @Test("dropWouldOverwrite flags a landing on an existing room")
    func overwriteDetection() {
        let map = DungeonRoomMap()
        map.setRoom(DungeonRoom(roomType: .doubleMoat), col: 0, row: 0)
        map.setRoom(DungeonRoom(roomType: .tee), col: 3, row: 0)   // in the drop path
        let region = map.contiguousRegion(col: 0, row: 0)
        #expect(map.dropWouldOverwrite(region, byColumns: 3, rows: 0))   // lands on (3,0)
        #expect(!map.dropWouldOverwrite(region, byColumns: 0, rows: 4))  // clear
    }

    @Test("snapshot/restore round-trips rooms, circles, and doors (GRAB undo)")
    func snapshotRestore() {
        let map = DungeonRoomMap()
        map.setRoom(DungeonRoom(roomType: .doubleMoat), col: 1, row: 1)
        map.setRoom(DungeonRoom(roomType: .transport1), col: 2, row: 1)
        map.toggleCircle(col: 1, row: 1)
        map.setDoor(.yes, axis: .horizontal, col: 1, row: 1)
        let snap = map.snapshot()

        // Mutate everything.
        let region = map.contiguousRegion(col: 1, row: 1)
        map.moveRegion(region, byColumns: 2, rows: 2)
        #expect(map.room(col: 1, row: 1).isEmpty)               // moved away
        #expect(map.room(col: 3, row: 3).roomType == .doubleMoat)

        // Undo.
        map.restore(snap)
        #expect(map.room(col: 1, row: 1).roomType == .doubleMoat)
        #expect(map.room(col: 2, row: 1).roomType == .transport1)
        #expect(map.isCircled(col: 1, row: 1))
        #expect(map.door(.horizontal, col: 1, row: 1) == .yes)
        #expect(map.transportCount(1) == 1)
        #expect(map.room(col: 3, row: 3).isEmpty)
    }
}
