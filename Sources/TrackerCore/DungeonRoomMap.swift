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

    /// Which button is painting during a drag.
    public enum DragPaintButton: Sendable { case left, right, middle }

    /// Drag-paint a single room (T-072, reference `dragBehavior`
    /// `DungeonUI.fs:1357-1382`): while a button is held and dragged over rooms,
    /// each one is painted if it matches —
    /// - **left** over an off-the-map room → unmarked (paint the map back on)
    /// - **right** over an unmarked room → off-the-map (paint it off)
    /// - **middle** over an unmarked room → the default room, completed
    ///
    /// Any other combination is a no-op (so a drag only affects matching rooms).
    /// Returns whether it painted, and clears the first-interaction flag when it
    /// does (the reference cancels the entrance accelerator on paint).
    @discardableResult
    public func dragPaint(_ button: DragPaintButton, col: Int, row: Int) -> Bool {
        var r = room(col: col, row: row)
        switch button {
        case .left where r.roomType.isOffMap:
            r.roomType = .unmarked
            r.isCompleted = false
        case .right where r.roomType.isNotMarked:
            r.roomType = .offTheMap
            r.isCompleted = false
        case .middle where r.roomType.isNotMarked:
            r.roomType = DungeonRoomGesture.defaultRoom
            r.isCompleted = true
        default:
            return false
        }
        setRoom(r, col: col, row: row)
        firstInteractionDone = true
        return true
    }

    /// Conservative door inference (T-019.12, reference `DungeonUI.fs:1148-1167`):
    /// after a room is newly marked, if it has exactly one plausible entry — one
    /// adjacent non-empty room whose connecting door isn't already `no` — set that
    /// door to `yes` ("you must have walked in from there"). No-op with zero or
    /// several candidates, or if the single candidate door isn't `unknown`.
    ///
    /// The caller gates on the unmarked→marked transition and the
    /// `doDoorInference` option; this self-skips a Gannon/Zelda room and the
    /// second copy of a transport pair (you teleport in, not walk).
    /// Returns whether a door was set.
    @discardableResult
    public func inferEntryDoor(col: Int, row: Int) -> Bool {
        let here = room(col: col, row: row)
        guard !here.isEmpty, !here.isGannonOrZelda else { return false }
        if let n = here.roomType.transportNumber, transportCounts[n] == 2 { return false }

        // Adjacent non-empty rooms whose connecting door isn't `no` are candidates.
        var candidates: [(DoorAxis, Int, Int)] = []
        if col > 0, !room(col: col - 1, row: row).isEmpty, horizontalDoor(col: col - 1, row: row) != .no {
            candidates.append((.horizontal, col - 1, row))
        }
        if col < Self.cols - 1, !room(col: col + 1, row: row).isEmpty, horizontalDoor(col: col, row: row) != .no {
            candidates.append((.horizontal, col, row))
        }
        if row > 0, !room(col: col, row: row - 1).isEmpty, verticalDoor(col: col, row: row - 1) != .no {
            candidates.append((.vertical, col, row - 1))
        }
        if row < Self.rows - 1, !room(col: col, row: row + 1).isEmpty, verticalDoor(col: col, row: row) != .no {
            candidates.append((.vertical, col, row))
        }
        guard candidates.count == 1 else { return false }
        let (axis, dc, dr) = candidates[0]
        guard door(axis, col: dc, row: dr) == .unknown else { return false }
        setDoor(.yes, axis: axis, col: dc, row: dr)
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

    /// Which wall a door sits on: `horizontal` = the vertical wall between two
    /// side-by-side rooms; `vertical` = the horizontal wall between two stacked
    /// rooms. (Named for the row/column the door *spans*, matching the reference's
    /// `horizontalDoors` / `verticalDoors`.)
    public enum DoorAxis: Sendable { case horizontal, vertical }

    /// Unified door get/set (D3), so the door view has one code path.
    public func door(_ axis: DoorAxis, col: Int, row: Int) -> DoorState {
        axis == .horizontal ? horizontalDoor(col: col, row: row) : verticalDoor(col: col, row: row)
    }
    public func setDoor(_ state: DoorState, axis: DoorAxis, col: Int, row: Int) {
        switch axis {
        case .horizontal: setHorizontalDoor(state, col: col, row: row)
        case .vertical: setVerticalDoor(state, col: col, row: row)
        }
    }

    // MARK: Grab (cut/paste a contiguous segment) — T-073 model foundation

    /// A room's grid coordinate.
    public struct RoomCoord: Hashable, Sendable {
        public let col: Int
        public let row: Int
        public init(col: Int, row: Int) { self.col = col; self.row = row }
    }

    /// The contiguous region of non-empty rooms reachable from `(col,row)` by
    /// 4-adjacency (reference `GrabHelper.PreviewGrab`, `Dungeon.fs:70-89`) — the
    /// blob a GRAB would pick up. Empty if the start room is empty.
    public func contiguousRegion(col: Int, row: Int) -> Set<RoomCoord> {
        guard !room(col: col, row: row).isEmpty else { return [] }
        var region: Set<RoomCoord> = []
        var stack = [RoomCoord(col: col, row: row)]
        while let p = stack.popLast() {
            guard !region.contains(p) else { continue }
            region.insert(p)
            for (dc, dr) in [(-1, 0), (1, 0), (0, -1), (0, 1)] {
                let n = RoomCoord(col: p.col + dc, row: p.row + dr)
                guard (0..<Self.cols).contains(n.col), (0..<Self.rows).contains(n.row),
                      !region.contains(n), !room(col: n.col, row: n.row).isEmpty else { continue }
                stack.append(n)
            }
        }
        return region
    }

    /// Move a grabbed `region` by `(dx, dy)` (reference `GrabHelper.DoDrop`,
    /// `Dungeon.fs:119-149`): cut the region (its cells become empty, its touching
    /// doors clear), then paste the rooms + circles + their set internal doors at
    /// the offset. Cells that would land off-grid are dropped. Overlapped
    /// destination cells are overwritten.
    public func moveRegion(_ region: Set<RoomCoord>, byColumns dx: Int, rows dy: Int) {
        guard !region.isEmpty, dx != 0 || dy != 0 else { return }
        let oldRooms = rooms
        let oldCircled = circled
        let oldH = horizontalDoors
        let oldV = verticalDoors

        // 1. Cut: empty the region cells + uncircle; clear any door touching it.
        for p in region {
            rooms[Self.roomIndex(p.col, p.row)] = DungeonRoom()
            circled[Self.roomIndex(p.col, p.row)] = false
        }
        for col in 0..<7 {
            for row in 0..<Self.rows where region.contains(.init(col: col, row: row)) || region.contains(.init(col: col + 1, row: row)) {
                horizontalDoors[Self.hDoorIndex(col, row)] = .unknown
            }
        }
        for col in 0..<Self.cols {
            for row in 0..<7 where region.contains(.init(col: col, row: row)) || region.contains(.init(col: col, row: row + 1)) {
                verticalDoors[Self.vDoorIndex(col, row)] = .unknown
            }
        }

        // 2. Paste at the offset (rooms, circles, and each set internal door).
        for src in region {
            let dc = src.col + dx, dr = src.row + dy
            guard (0..<Self.cols).contains(dc), (0..<Self.rows).contains(dr) else { continue }
            rooms[Self.roomIndex(dc, dr)] = oldRooms[Self.roomIndex(src.col, src.row)]
            circled[Self.roomIndex(dc, dr)] = oldCircled[Self.roomIndex(src.col, src.row)]
            // Carry each of the four surrounding doors that was set (≠ unknown).
            if src.col < 7, dc < 7 {
                let s = oldH[Self.hDoorIndex(src.col, src.row)]
                if s != .unknown { horizontalDoors[Self.hDoorIndex(dc, dr)] = s }
            }
            if src.col > 0, dc > 0 {
                let s = oldH[Self.hDoorIndex(src.col - 1, src.row)]
                if s != .unknown { horizontalDoors[Self.hDoorIndex(dc - 1, dr)] = s }
            }
            if src.row < 7, dr < 7 {
                let s = oldV[Self.vDoorIndex(src.col, src.row)]
                if s != .unknown { verticalDoors[Self.vDoorIndex(dc, dr)] = s }
            }
            if src.row > 0, dr > 0 {
                let s = oldV[Self.vDoorIndex(src.col, src.row - 1)]
                if s != .unknown { verticalDoors[Self.vDoorIndex(dc, dr - 1)] = s }
            }
        }
        recomputeTransportCounts()
        firstInteractionDone = true
    }

    /// An opaque copy of all the mutable grid state (rooms, circles, doors), for
    /// the GRAB tool's "keep changes / undo" prompt (T-083): snapshot before a
    /// `moveRegion`, `restore` if the user chooses Undo.
    public struct Snapshot: Sendable {
        fileprivate let rooms: [DungeonRoom]
        fileprivate let horizontalDoors: [DoorState]
        fileprivate let verticalDoors: [DoorState]
        fileprivate let circled: [Bool]
        fileprivate let transportCounts: [Int]
    }

    public func snapshot() -> Snapshot {
        Snapshot(rooms: rooms, horizontalDoors: horizontalDoors,
                 verticalDoors: verticalDoors, circled: circled, transportCounts: transportCounts)
    }

    public func restore(_ s: Snapshot) {
        rooms = s.rooms
        horizontalDoors = s.horizontalDoors
        verticalDoors = s.verticalDoors
        circled = s.circled
        transportCounts = s.transportCounts
    }

    /// Whether a drop at `(dx, dy)` would overwrite existing rooms — the reference's
    /// "warn" state driving the keep/undo prompt (`GrabHelper.PreviewDrop`,
    /// `:102-117`). Region cells landing on a non-empty, non-region cell warn.
    public func dropWouldOverwrite(_ region: Set<RoomCoord>, byColumns dx: Int, rows dy: Int) -> Bool {
        for src in region {
            let dc = src.col + dx, dr = src.row + dy
            guard (0..<Self.cols).contains(dc), (0..<Self.rows).contains(dr) else { continue }
            let dest = RoomCoord(col: dc, row: dr)
            if region.contains(dest) { continue }   // landing on another grabbed cell is fine
            if !room(col: dc, row: dr).isEmpty { return true }
        }
        return false
    }

    private func recomputeTransportCounts() {
        var counts = Array(repeating: 0, count: 9)
        for r in rooms { if let n = r.roomType.transportNumber { counts[n] += 1 } }
        transportCounts = counts
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
