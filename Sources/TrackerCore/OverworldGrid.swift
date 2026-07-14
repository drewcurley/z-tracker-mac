import Observation

/// The 16×8 overworld map's tile-mark state (docs/domain.md § 4.5). Every
/// tile defaults to `.unmarked`. Stored as a flat array (row-major) rather
/// than a nested array so `@Observable` tracks single-tile writes without
/// needing to reassign an entire row.
@Observable
public final class OverworldGrid {
    public static let columnCount = 16
    public static let rowCount = 8

    private var tiles: [OverworldTileMark]

    /// Per-tile "extra data" key-value store, ported from the reference's
    /// `overworldMapExtraData` (`TrackerModel.fs:996-1011`): each of the 128
    /// tiles carries an array of `keyCount` ints (all 0 by default). Used for
    /// a 3-item shop's **second item** (key `OverworldTileMark.shopExtraDataKey`,
    /// value `0` = none, `1…8` in `toItem` format), `.theLetter`'s
    /// have-potion-letter toggle, and `.dontCare`'s un-revealed toggle. Stored
    /// flat (`tileIndex * keyCount + key`) so `@Observable` tracks single-cell
    /// writes.
    ///
    /// `keyCount` is `DARK_X + 1 = 36`, matching the reference's
    /// `Array.zeroCreate (DARK_X+1)` — the key is itself a mapSquare index.
    public static let extraDataKeyCount = OverworldTileMark.maxRawIndex + 1

    private var extraData: [Int]

    public init() {
        tiles = Array(repeating: .unmarked, count: Self.columnCount * Self.rowCount)
        extraData = Array(repeating: 0, count: Self.columnCount * Self.rowCount * Self.extraDataKeyCount)
    }

    public func mark(column: Int, row: Int) -> OverworldTileMark {
        tiles[Self.index(column: column, row: row)]
    }

    public func setMark(_ mark: OverworldTileMark, column: Int, row: Int) {
        tiles[Self.index(column: column, row: row)] = mark
    }

    /// Reads a tile's extra-data value for `key` (`0…extraDataKeyCount-1`).
    /// Ported from `getOverworldMapExtraData` (`TrackerModel.fs:1000-1008`);
    /// this port omits the reference's `#if DEBUG` consistency assertion.
    public func extraData(column: Int, row: Int, key: Int) -> Int {
        extraData[Self.extraDataIndex(column: column, row: row, key: key)]
    }

    /// Writes a tile's extra-data value for `key`. Ported from
    /// `setOverworldMapExtraData` (`TrackerModel.fs:1009-1011`).
    public func setExtraData(_ value: Int, column: Int, row: Int, key: Int) {
        extraData[Self.extraDataIndex(column: column, row: row, key: key)] = value
    }

    /// Whether this tile's claimable thing has been marked **used** (collected)
    /// — T-054, only meaningful when the mark `isUsedToggleable`. Stored in
    /// `extraData` at the mark's own raw index (`extraData[state] == state`),
    /// exactly as the reference's `ToggleOverworldTileIfItIsToggleable`.
    public func isUsed(column: Int, row: Int) -> Bool {
        let mark = mark(column: column, row: row)
        guard mark.isUsedToggleable else { return false }
        let key = mark.rawIndex
        return extraData(column: column, row: row, key: key) == key
    }

    /// Toggle a claimable tile's used state (no-op if the mark isn't
    /// toggleable). Ported from `ToggleOverworldTileIfItIsToggleable`
    /// (`OverworldMapTileCustomization.fs:237-244`).
    public func toggleUsed(column: Int, row: Int) {
        let mark = mark(column: column, row: row)
        guard mark.isUsedToggleable else { return }
        let key = mark.rawIndex
        let current = extraData(column: column, row: row, key: key)
        setExtraData(current == key ? 0 : key, column: column, row: row, key: key)
    }

    /// Explicitly set a claimable tile's used state (no-op if not toggleable).
    /// Used when marking a claimable tile, which defaults to **used** (T-056).
    public func setUsed(_ used: Bool, column: Int, row: Int) {
        let mark = mark(column: column, row: row)
        guard mark.isUsedToggleable else { return }
        let key = mark.rawIndex
        setExtraData(used ? key : 0, column: column, row: row, key: key)
    }

    /// Resets every tile to `.unmarked` and clears all extra-data — not
    /// itself a confirmed reference-app gesture, but a useful testing/reset
    /// hook.
    public func clearAll() {
        tiles = Array(repeating: .unmarked, count: Self.columnCount * Self.rowCount)
        extraData = Array(repeating: 0, count: Self.columnCount * Self.rowCount * Self.extraDataKeyCount)
    }

    private static func index(column: Int, row: Int) -> Int {
        precondition((0..<columnCount).contains(column), "column \(column) out of range")
        precondition((0..<rowCount).contains(row), "row \(row) out of range")
        return row * columnCount + column
    }

    private static func extraDataIndex(column: Int, row: Int, key: Int) -> Int {
        precondition((0..<extraDataKeyCount).contains(key), "extra-data key \(key) out of range")
        return index(column: column, row: row) * extraDataKeyCount + key
    }
}
