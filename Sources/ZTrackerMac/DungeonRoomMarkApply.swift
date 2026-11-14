import TrackerCore

/// The one place a dungeon room's marks are applied (T-135), so a mouse pick and a
/// keyboard hotkey on the cursor room do identically the same thing. Mirrors the
/// three room pickers' mutations exactly.
enum DungeonRoomMark {
    /// Set the room type (RoomType picker). Matches the picker: records first-
    /// interaction and, when door inference is on and the room was blank, infers the
    /// entry door.
    @MainActor
    static func applyRoomType(_ type: RoomType, col: Int, row: Int,
                              map: DungeonRoomMap, inferDoors: Bool) {
        let wasUnmarked = map.room(col: col, row: row).roomType.isNotMarked
        var r = map.room(col: col, row: row)
        r.roomType = type
        _ = map.setRoom(r, col: col, row: row)
        map.firstInteractionDone = true
        if inferDoors, wasUnmarked { _ = map.inferEntryDoor(col: col, row: row) }
    }

    /// Toggle a monster on the room (MonsterPicker) — adds it, or, if already the
    /// primary/secondary, removes it; `.unmarked` clears.
    @MainActor
    static func toggleMonster(_ monster: MonsterDetail, col: Int, row: Int, map: DungeonRoomMap) {
        var r = map.room(col: col, row: row)
        r.toggleMonster(monster)
        _ = map.setRoom(r, col: col, row: row)
    }

    /// Set the floor-drop (FloorDropPicker).
    @MainActor
    static func setFloorDrop(_ drop: FloorDropDetail, col: Int, row: Int, map: DungeonRoomMap) {
        var r = map.room(col: col, row: row)
        r.floorDropDetail = drop
        _ = map.setRoom(r, col: col, row: row)
    }

    /// The primary left-click on a room: the accelerator / cycle / completion toggle, then (if
    /// enabled) entry-door inference. Shared by the mouse and the Left-click hotkey (T-249).
    @MainActor
    static func leftClick(col: Int, row: Int, map: DungeonRoomMap,
                          preferNonDescript: Bool, inferDoors: Bool) {
        let wasUnmarked = map.room(col: col, row: row).roomType.isNotMarked
        // "Default to NonDescript" (T-206): the left-click accelerator marks an unmarked
        // room as NonDescript (empty) instead of MaybePushBlock when the option is on.
        map.leftClick(col: col, row: row, defaultRoom: preferNonDescript ? .nonDescript : .maybePushBlock)
        if inferDoors, wasUnmarked { map.inferEntryDoor(col: col, row: row) }
    }

    /// A wall of the room, for the door-nudge hotkeys (T-249).
    enum DoorSide: CaseIterable, Sendable {
        case west, east, north, south
        var hotkeyName: String {
            switch self { case .west: "West"; case .east: "East"; case .north: "North"; case .south: "South" }
        }
    }

    /// Step the door on `side` of room (col,row) to its next (or previous) state — the
    /// reference's `DoorHotKeyResponse` (`DungeonUI.fs:1268-1279`, `Door.Next/Prev`). The outer
    /// wall has no door, so an edge side is a no-op returning false. Counts as an interaction
    /// (cancels the first-click entrance accelerator, `:1282`).
    @MainActor @discardableResult
    static func nudgeDoor(_ side: DoorSide, increment: Bool, col: Int, row: Int,
                          map: DungeonRoomMap) -> Bool {
        let target: (axis: DungeonRoomMap.DoorAxis, col: Int, row: Int)
        switch side {
        case .west:
            guard col > 0 else { return false }
            target = (.horizontal, col - 1, row)
        case .east:
            guard col < DungeonRoomMap.cols - 1 else { return false }
            target = (.horizontal, col, row)
        case .north:
            guard row > 0 else { return false }
            target = (.vertical, col, row - 1)
        case .south:
            guard row < DungeonRoomMap.rows - 1 else { return false }
            target = (.vertical, col, row)
        }
        let state = map.door(target.axis, col: target.col, row: target.row)
        map.setDoor(increment ? state.next : state.prev, axis: target.axis, col: target.col, row: target.row)
        map.firstInteractionDone = true
        return true
    }

    /// Route a `DungeonRoom_*` hotkey selector to the room at (col,row). Returns
    /// false for the door-nudge selectors (handled elsewhere / unbound).
    @MainActor @discardableResult
    static func applyHotkey(_ selectorID: String, col: Int, row: Int,
                            map: DungeonRoomMap, inferDoors: Bool) -> Bool {
        if let suffix = selectorID.dropPrefix("DungeonRoom_RoomType_") {
            applyRoomType(RoomType.fromHotKeyName("RoomType_" + suffix),
                          col: col, row: row, map: map, inferDoors: inferDoors)
            return true
        }
        if let suffix = selectorID.dropPrefix("DungeonRoom_MonsterDetail_") {
            toggleMonster(MonsterDetail.fromHotKeyName("MonsterDetail_" + suffix),
                          col: col, row: row, map: map)
            return true
        }
        if let suffix = selectorID.dropPrefix("DungeonRoom_FloorDropDetail_") {
            setFloorDrop(FloorDropDetail.fromHotKeyName("FloorDropDetail_" + suffix),
                         col: col, row: row, map: map)
            return true
        }
        return false   // door increments/decrements — not a room-mark
    }
}

private extension String {
    /// The remainder after `prefix`, or nil if it doesn't match.
    func dropPrefix(_ prefix: String) -> String? {
        hasPrefix(prefix) ? String(dropFirst(prefix.count)) : nil
    }
}
