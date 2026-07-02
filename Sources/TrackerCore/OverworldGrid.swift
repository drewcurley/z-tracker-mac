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

    public init() {
        tiles = Array(repeating: .unmarked, count: Self.columnCount * Self.rowCount)
    }

    public func mark(column: Int, row: Int) -> OverworldTileMark {
        tiles[Self.index(column: column, row: row)]
    }

    public func setMark(_ mark: OverworldTileMark, column: Int, row: Int) {
        tiles[Self.index(column: column, row: row)] = mark
    }

    /// Resets every tile to `.unmarked` — not itself a confirmed reference-app
    /// gesture, but a useful testing/reset hook.
    public func clearAll() {
        tiles = Array(repeating: .unmarked, count: Self.columnCount * Self.rowCount)
    }

    private static func index(column: Int, row: Int) -> Int {
        precondition((0..<columnCount).contains(column), "column \(column) out of range")
        precondition((0..<rowCount).contains(row), "row \(row) out of range")
        return row * columnCount + column
    }
}
