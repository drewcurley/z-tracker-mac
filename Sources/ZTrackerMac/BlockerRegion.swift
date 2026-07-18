import TrackerCore

/// Maps between the blockers cursor grid and (dungeon, slot) (T-135). The blockers
/// UI is a 3×3 of dungeons, each showing `maxBlockersPerDungeon` slots in a row — so
/// the cursor grid is `(3 · slots)` columns × 3 rows, and column packs the dungeon
/// column and the slot within it.
enum BlockerRegion {
    static let slots = DungeonBlockersContainer.maxBlockersPerDungeon
    static let cols = 3 * slots
    static let rows = 3

    /// The cursor cell for a given dungeon (0–8) and slot.
    static func cell(dungeon: Int, slot: Int) -> TrackerFocusState.GridCell {
        .init(col: (dungeon % 3) * slots + slot, row: dungeon / 3)
    }

    /// The dungeon + slot a cursor cell addresses.
    static func target(_ cell: TrackerFocusState.GridCell) -> (dungeon: Int, slot: Int) {
        (dungeon: cell.row * 3 + cell.col / slots, slot: cell.col % slots)
    }
}
