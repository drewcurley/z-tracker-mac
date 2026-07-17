/// One dungeon room (T-019.3) — the five fields of the reference's
/// `DungeonRoomState` (`DungeonRoomState.fs:469-491`). A value type; the grid
/// (`DungeonRoomMap`) owns the mutable collection.
public struct DungeonRoom: Sendable, Equatable {
    public var isCompleted: Bool
    public var roomType: RoomType
    /// The room's primary monster.
    public var monsterDetail: MonsterDetail
    /// An optional **second** monster (T-116, beyond the reference's single-monster
    /// model — user request). When set, both icons render stacked. `unmarked` when
    /// the room has only one (or no) monster.
    public var monsterDetail2: MonsterDetail
    public var floorDropDetail: FloorDropDetail
    /// Whether the floor-drop icon renders bright vs darkened ("already
    /// collected"), toggled by middle-click in the reference.
    public var floorDropAppearsBright: Bool

    public init(isCompleted: Bool = false,
                roomType: RoomType = .unmarked,
                monsterDetail: MonsterDetail = .unmarked,
                monsterDetail2: MonsterDetail = .unmarked,
                floorDropDetail: FloorDropDetail = .unmarked,
                floorDropAppearsBright: Bool = true) {
        self.isCompleted = isCompleted
        self.roomType = roomType
        self.monsterDetail = monsterDetail
        self.monsterDetail2 = monsterDetail2
        self.floorDropDetail = floorDropDetail
        self.floorDropAppearsBright = floorDropAppearsBright
    }

    /// The room's monsters in display order, without the `unmarked` placeholders
    /// (0, 1, or 2 entries).
    public var monsters: [MonsterDetail] {
        [monsterDetail, monsterDetail2].filter { !$0.isNotMarked }
    }

    /// Toggle `m` into this room's up-to-two monster set (T-116), keeping the pair
    /// normalized (primary filled before secondary). Tapping `unmarked` clears both;
    /// tapping a present monster removes it (promoting the secondary); tapping a new
    /// monster fills the empty slot, or replaces the secondary when both are full.
    public mutating func toggleMonster(_ m: MonsterDetail) {
        let (a, b) = (monsterDetail, monsterDetail2)
        let pair: (MonsterDetail, MonsterDetail)
        if m.isNotMarked { pair = (.unmarked, .unmarked) }
        else if m == a { pair = (b, .unmarked) }
        else if m == b { pair = (a, .unmarked) }
        else if a.isNotMarked { pair = (m, .unmarked) }
        else if b.isNotMarked { pair = (a, m) }
        else { pair = (a, m) }
        (monsterDetail, monsterDetail2) = pair
    }

    /// `IsEmpty` — unmarked or off-the-map. Drives room contiguity / door logic.
    public var isEmpty: Bool { roomType.isNotMarked || roomType.isOffMap }

    public var isGannonOrZelda: Bool { roomType == .gannon || roomType == .zelda }

    /// The save "default room" sentinel (`DungeonSaveAndLoad.IsDefault`): not
    /// completed, all three details unmarked, and the floor drop still bright.
    /// Such rooms serialize as `null`.
    public var isDefault: Bool {
        !isCompleted && roomType.isNotMarked && monsterDetail.isNotMarked
            && monsterDetail2.isNotMarked && floorDropDetail.isNotMarked && floorDropAppearsBright
    }
}
