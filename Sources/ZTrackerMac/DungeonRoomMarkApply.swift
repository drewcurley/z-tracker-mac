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
