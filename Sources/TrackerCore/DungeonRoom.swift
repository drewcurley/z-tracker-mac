/// One dungeon room (T-019.3) — the five fields of the reference's
/// `DungeonRoomState` (`DungeonRoomState.fs:469-491`). A value type; the grid
/// (`DungeonRoomMap`) owns the mutable collection.
public struct DungeonRoom: Sendable, Equatable {
    public var isCompleted: Bool
    public var roomType: RoomType
    public var monsterDetail: MonsterDetail
    public var floorDropDetail: FloorDropDetail
    /// Whether the floor-drop icon renders bright vs darkened ("already
    /// collected"), toggled by middle-click in the reference.
    public var floorDropAppearsBright: Bool

    public init(isCompleted: Bool = false,
                roomType: RoomType = .unmarked,
                monsterDetail: MonsterDetail = .unmarked,
                floorDropDetail: FloorDropDetail = .unmarked,
                floorDropAppearsBright: Bool = true) {
        self.isCompleted = isCompleted
        self.roomType = roomType
        self.monsterDetail = monsterDetail
        self.floorDropDetail = floorDropDetail
        self.floorDropAppearsBright = floorDropAppearsBright
    }

    /// `IsEmpty` — unmarked or off-the-map. Drives room contiguity / door logic.
    public var isEmpty: Bool { roomType.isNotMarked || roomType.isOffMap }

    public var isGannonOrZelda: Bool { roomType == .gannon || roomType == .zelda }

    /// The save "default room" sentinel (`DungeonSaveAndLoad.IsDefault`): not
    /// completed, all three details unmarked, and the floor drop still bright.
    /// Such rooms serialize as `null`.
    public var isDefault: Bool {
        !isCompleted && roomType.isNotMarked && monsterDetail.isNotMarked
            && floorDropDetail.isNotMarked && floorDropAppearsBright
    }
}
