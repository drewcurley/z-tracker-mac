import Observation

/// One dungeon's room map (T-019.3): an 8×8 grid of `DungeonRoom`, the door
/// state between adjacent rooms, per-room "circled" flags, and the transport-
/// stair pairing counter. Ported from the reference's per-dungeon `roomStates` /
/// `horizontalDoors` / `verticalDoors` / `roomIsCircled` / `usedTransports`
/// (`Z1R_WPF/DungeonUI.fs`). Uniform 8×8 for all nine dungeons (incl. level 9).
///
/// Grid knowledge, so a groundhog reset keeps it (like the overworld marks).
@Observable
public final class DungeonRoomMap {
    public static let cols = 8
    public static let rows = 8

    /// 8×8 rooms, row-major (`index = row*8 + col`).
    private var rooms: [DungeonRoom]
    /// Vertical wall segments between horizontally-adjacent rooms: `[col 0…6][row 0…7]`.
    private var horizontalDoors: [DoorState]
    /// Horizontal wall segments between vertically-adjacent rooms: `[col 0…7][row 0…6]`.
    private var verticalDoors: [DoorState]
    /// Per-room "circled" marker.
    private var circled: [Bool]
    /// How many of each transport number (1…8) are currently placed (index 0
    /// unused). A pair is complete at 2; a third is rejected.
    private var transportCounts: [Int]

    /// Whether the user has interacted with this dungeon's map yet. The reference's
    /// per-level `isFirstTimeClickingAnyRoom`: the first left-click drops the
    /// entrance (rather than the usual mark), and any interaction clears the flag.
    /// Knowledge (persists across a groundhog reset).
    public var firstInteractionDone = false

    public init() {
        rooms = Array(repeating: DungeonRoom(), count: Self.cols * Self.rows)
        horizontalDoors = Array(repeating: .unknown, count: 7 * Self.rows)
        verticalDoors = Array(repeating: .unknown, count: Self.cols * 7)
        circled = Array(repeating: false, count: Self.cols * Self.rows)
        transportCounts = Array(repeating: 0, count: 9)
    }

    // MARK: Rooms

    public func room(col: Int, row: Int) -> DungeonRoom {
        rooms[Self.roomIndex(col, row)]
    }

    /// Sets a room, keeping the transport-pair counter in sync and rejecting an
    /// illegal third copy of a transport number (returns `false`, unchanged).
    /// Ported from `SetNewValue`'s `usedTransports.[n] <> 2` guard.
    @discardableResult
    public func setRoom(_ newRoom: DungeonRoom, col: Int, row: Int) -> Bool {
        let idx = Self.roomIndex(col, row)
        let old = rooms[idx].roomType.transportNumber
        let new = newRoom.roomType.transportNumber
        if let new, new != old, transportCounts[new] >= 2 {
            return false   // can't place a third copy of a transport pair
        }
        if let old { transportCounts[old] -= 1 }
        if let new { transportCounts[new] += 1 }
        rooms[idx] = newRoom
        return true
    }

    /// Apply a plain **left-click** at `(col,row)` (D2a): run the gesture
    /// resolver, commit via `setRoom` (so transport limits still hold), and clear
    /// the first-interaction flag as the reference does on any interaction.
    /// Returns the committed room.
    @discardableResult
    public func leftClick(col: Int, row: Int) -> DungeonRoom {
        let outcome = DungeonRoomGesture.leftClick(on: room(col: col, row: row),
                                                   isFirstInteraction: !firstInteractionDone)
        setRoom(outcome.room, col: col, row: row)
        firstInteractionDone = true
        return room(col: col, row: row)
    }

    /// Whether placing transport number `n` here is legal (fewer than two
    /// elsewhere, or this room already is that number).
    public func canPlaceTransport(_ n: Int, col: Int, row: Int) -> Bool {
        guard (1...8).contains(n) else { return false }
        if rooms[Self.roomIndex(col, row)].roomType.transportNumber == n { return true }
        return transportCounts[n] < 2
    }

    /// How many of transport number `n` (1…8) are placed.
    public func transportCount(_ n: Int) -> Int {
        (1...8).contains(n) ? transportCounts[n] : 0
    }

    // MARK: Circled

    public func isCircled(col: Int, row: Int) -> Bool { circled[Self.roomIndex(col, row)] }
    public func toggleCircle(col: Int, row: Int) { circled[Self.roomIndex(col, row)].toggle() }

    /// Middle-click (D2b): with no floor drop, toggle the room's circle; with a
    /// floor drop, toggle its brightness ("already collected"). Ported from the
    /// reference (`DungeonUI.fs:1466-1471`).
    public func middleClick(col: Int, row: Int) {
        if room(col: col, row: row).floorDropDetail.isNotMarked {
            toggleCircle(col: col, row: row)
        } else {
            var r = room(col: col, row: row)
            r.floorDropAppearsBright.toggle()
            setRoom(r, col: col, row: row)
        }
    }

    // MARK: Doors

    /// The vertical wall between rooms `(col,row)` and `(col+1,row)` — `col` in
    /// `0…6`.
    public func horizontalDoor(col: Int, row: Int) -> DoorState {
        horizontalDoors[Self.hDoorIndex(col, row)]
    }
    public func setHorizontalDoor(_ state: DoorState, col: Int, row: Int) {
        horizontalDoors[Self.hDoorIndex(col, row)] = state
    }

    /// The horizontal wall between rooms `(col,row)` and `(col,row+1)` — `row` in
    /// `0…6`.
    public func verticalDoor(col: Int, row: Int) -> DoorState {
        verticalDoors[Self.vDoorIndex(col, row)]
    }
    public func setVerticalDoor(_ state: DoorState, col: Int, row: Int) {
        verticalDoors[Self.vDoorIndex(col, row)] = state
    }

    // MARK: Derived

    /// Count of marked "old man" NPC rooms (`IsOldMan`) — feeds the per-dungeon
    /// old-man readout.
    public var oldManCount: Int {
        rooms.reduce(0) { $0 + ($1.roomType.isOldMan ? 1 : 0) }
    }

    /// Whether any room is off-the-map (drives the reference's inverse-minimap).
    public var hasOffMapRoom: Bool { rooms.contains { $0.roomType.isOffMap } }

    // MARK: Indexing

    private static func roomIndex(_ col: Int, _ row: Int) -> Int {
        precondition((0..<cols).contains(col) && (0..<rows).contains(row), "room \(col),\(row) out of range")
        return row * cols + col
    }
    private static func hDoorIndex(_ col: Int, _ row: Int) -> Int {
        precondition((0..<7).contains(col) && (0..<rows).contains(row), "h-door \(col),\(row) out of range")
        return col * rows + row
    }
    private static func vDoorIndex(_ col: Int, _ row: Int) -> Int {
        precondition((0..<cols).contains(col) && (0..<7).contains(row), "v-door \(col),\(row) out of range")
        return col * 7 + row
    }
}
