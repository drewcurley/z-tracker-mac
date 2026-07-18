import Observation

/// App-level UI focus state shared with the hotkey dispatcher (T-133). Holding the
/// selected dungeon tab here (rather than as `@State` inside `DungeonMapView`) lets
/// Global `DungeonTab*` hotkeys switch tabs, and makes the selection survive the
/// dungeon-band reflow (which recreates the map view).
@Observable
@MainActor
final class TrackerFocusState {
    /// The visible dungeon tab: 0…8 = dungeons 1–9, 9 = the Summary tab.
    var selectedDungeonTab: Int = 0

    // MARK: Keyboard cursor (T-134 / T-135)

    /// One grid cell (column, row).
    struct GridCell: Equatable, Sendable { var col: Int; var row: Int }

    /// A region the keyboard cursor can occupy. The `CycleRegionForward/Backward`
    /// hotkeys step through `cycleOrder` (T-135); today only the overworld and
    /// dungeon-map grids are navigable, so the cycle spans those two — items,
    /// blockers, and the dungeon-item card join `cycleOrder` as they gain nav.
    enum CursorRegion: Sendable, Equatable, CaseIterable {
        case dungeonItem, items, overworld, dungeonMap, blockers
    }

    /// The regions the cursor cycles through, in the user's requested order
    /// (dungeon item ▸ items ▸ overworld ▸ dungeon map ▸ blockers). Only the
    /// implemented ones appear; the list grows as regions gain cursor nav.
    static let cycleOrder: [CursorRegion] = [.items, .overworld, .dungeonMap, .blockers]

    /// Grid dimensions per region.
    static let overworldCols = 16, overworldRows = 8
    static let dungeonCols = 8, dungeonRows = 8
    static let itemsCols = 5, itemsRows = 4
    static func dims(_ region: CursorRegion) -> (cols: Int, rows: Int) {
        switch region {
        case .overworld:  (overworldCols, overworldRows)
        case .dungeonMap: (dungeonCols, dungeonRows)
        case .items:      (itemsCols, itemsRows)
        case .blockers:   (BlockerRegion.cols, BlockerRegion.rows)
        default:          (1, 1)
        }
    }

    var cursorRegion: CursorRegion = .overworld
    var overworldCursor = GridCell(col: 0, row: 0)
    var dungeonCursor = GridCell(col: 0, row: 0)
    var itemsCursor = GridCell(col: 0, row: 0)
    var blockersCursor = GridCell(col: 0, row: 0)
    /// Shown once the cursor has been used (a Move/Cycle key or a hover); hidden
    /// regions don't draw a cursor.
    var cursorShown = false

    /// The cursor cell on the active region.
    var cursorCell: GridCell {
        switch cursorRegion {
        case .items: itemsCursor
        case .dungeonMap: dungeonCursor
        case .blockers: blockersCursor
        default: overworldCursor
        }
    }

    /// Move the cursor within the active region, clamped to bounds (T-134).
    func moveCursor(dcol: Int, drow: Int) {
        cursorShown = true
        let d = Self.dims(cursorRegion)
        let (maxC, maxR) = (d.cols - 1, d.rows - 1)
        func clamp(_ v: Int, _ hi: Int) -> Int { min(hi, max(0, v)) }
        func moved(_ c: GridCell) -> GridCell {
            GridCell(col: clamp(c.col + dcol, maxC), row: clamp(c.row + drow, maxR))
        }
        switch cursorRegion {
        case .items:      itemsCursor = moved(itemsCursor)
        case .dungeonMap: dungeonCursor = moved(dungeonCursor)
        case .blockers:   blockersCursor = moved(blockersCursor)
        default:          overworldCursor = moved(overworldCursor)
        }
    }

    /// Jump the cursor to an absolute cell in the active region, clamped (T-138 —
    /// voice "E7" moves the cursor there).
    func setCursor(col: Int, row: Int) {
        cursorShown = true
        let d = Self.dims(cursorRegion)
        let c = min(max(0, col), d.cols - 1), r = min(max(0, row), d.rows - 1)
        let cell = GridCell(col: c, row: r)
        switch cursorRegion {
        case .items: itemsCursor = cell
        case .dungeonMap: dungeonCursor = cell
        case .blockers: blockersCursor = cell
        default: overworldCursor = cell
        }
    }

    /// Step the cursor to the next / previous region in `cycleOrder` (T-135).
    func cycleRegion(forward: Bool) {
        cursorShown = true
        let order = Self.cycleOrder
        guard !order.isEmpty else { return }
        let i = order.firstIndex(of: cursorRegion) ?? 0
        let n = order.count
        cursorRegion = order[(i + (forward ? 1 : n - 1)) % n]
    }

    /// Mouse hover moved onto an overworld tile / dungeon room — the cursor follows
    /// (T-134, user choice), so keyboard nudges continue from where the mouse is.
    func hoverOverworld(col: Int, row: Int) {
        overworldCursor = GridCell(col: col, row: row)
        cursorRegion = .overworld
        cursorShown = true
    }
    func hoverDungeon(col: Int, row: Int) {
        dungeonCursor = GridCell(col: col, row: row)
        cursorRegion = .dungeonMap
        cursorShown = true
    }
    func hoverItems(col: Int, row: Int) {
        itemsCursor = GridCell(col: col, row: row)
        cursorRegion = .items
        cursorShown = true
    }
    func hoverBlockers(col: Int, row: Int) {
        blockersCursor = GridCell(col: col, row: row)
        cursorRegion = .blockers
        cursorShown = true
    }
}
