import Observation
import TrackerCore

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
    /// hotkeys step through `cycleOrder` (T-135); all five are navigable as of T-168.
    enum CursorRegion: Sendable, Equatable, CaseIterable {
        case dungeonItem, items, overworld, dungeonMap, blockers, notes
    }

    /// The regions the cursor cycles through, in the user's requested order
    /// (dungeon item ▸ items ▸ overworld ▸ dungeon map ▸ blockers ▸ notes).
    static let cycleOrder: [CursorRegion] =
        [.dungeonItem, .items, .overworld, .dungeonMap, .blockers, .notes]

    /// Grid dimensions per region.
    static let overworldCols = 16, overworldRows = 8
    static let dungeonCols = 8, dungeonRows = 8
    static let itemsCols = 5, itemsRows = 4
    /// The dungeon-item card row: **9 dungeons across × 3 boxes down** (T-168), which
    /// is how it's laid out on screen — the nine cards run horizontally in an HStack
    /// and each card's boxes stack vertically. So left/right steps between dungeons
    /// and up/down walks a dungeon's item stack. Two-boxer dungeons still expose the
    /// third cell; it simply has no box to act on.
    static let dungeonItemCols = 9, dungeonItemRows = 3
    static func dims(_ region: CursorRegion) -> (cols: Int, rows: Int) {
        switch region {
        case .overworld:   (overworldCols, overworldRows)
        case .dungeonMap:  (dungeonCols, dungeonRows)
        case .items:       (itemsCols, itemsRows)
        case .blockers:    (BlockerRegion.cols, BlockerRegion.rows)
        case .dungeonItem: (dungeonItemCols, dungeonItemRows)
        case .notes:       (1, 1)   // a text field, not a grid — nothing to navigate
        }
    }

    var cursorRegion: CursorRegion = .overworld
    var overworldCursor = GridCell(col: 0, row: 0)
    var dungeonCursor = GridCell(col: 0, row: 0)
    var itemsCursor = GridCell(col: 0, row: 0)
    var blockersCursor = GridCell(col: 0, row: 0)
    var dungeonItemCursor = GridCell(col: 0, row: 0)
    /// Shown once the cursor has been used (a Move/Cycle key or a hover); hidden
    /// regions don't draw a cursor.
    var cursorShown = false

    // MARK: Hover context (T-168)

    /// The region the mouse is currently inside, or `nil` when it's outside all of
    /// them. **Hover wins** over the keyboard cursor when deciding which context a
    /// hotkey acts in — that's the reference's model, where what a key means depends
    /// on what you're pointing at.
    ///
    /// A deliberate keyboard navigation (move / cycle / voice jump) clears it, so a
    /// mouse left resting on the map can't veto keyboard-only play; moving the mouse
    /// re-asserts hover. In short: the last *deliberate* input wins.
    private(set) var hoverRegion: CursorRegion?

    /// The hint-zone box the mouse is over (T-168), for the `HintZone_*` context —
    /// a `HintTarget` index (dungeon 0…8, white-sword 9, magical-sword 10). Hint boxes
    /// aren't a grid, so they're tracked by target rather than by cell.
    private(set) var hoveredHintTarget: Int?

    // MARK: Notes region (T-168)

    /// Whether the Notes field currently holds keyboard focus.
    ///
    /// Cycling onto `.notes` deliberately does **not** raise this — it only parks the
    /// cursor there. A text field that grabs focus on arrival would swallow the very
    /// cycle key you're holding down to pass through it. Instead the first
    /// alphanumeric keypress while parked starts typing and takes focus (that
    /// character lands in the field, nothing is lost), and **Escape** blurs again.
    ///
    /// Focus matters because the hotkey dispatcher stands down entirely while a text
    /// field is first responder — that's what lets a note contain your hotkey letters.
    /// Cursor-navigation keys are the exception and keep working while parked, so you
    /// can always move on without touching the mouse.
    var notesFocused = false

    /// The cursor is parked on Notes but not yet typing — keys still reach the
    /// dispatcher, and an alphanumeric one starts a note.
    var notesParked: Bool { cursorShown && cursorRegion == .notes && !notesFocused }

    /// Focus / blur the Notes field. Entering also claims the cursor, so cycling out
    /// afterwards resumes from `.notes` — including when the user clicked in directly
    /// rather than cycling.
    func setNotesFocus(_ on: Bool) {
        notesFocused = on
        if on {
            cursorRegion = .notes
            cursorShown = true
            hoverRegion = nil
        }
    }

    /// The region a hotkey should act on: whatever's hovered, else the keyboard
    /// cursor's region once it's visible, else nothing.
    var activeRegion: CursorRegion? {
        if let hoverRegion { return hoverRegion }
        return cursorShown ? cursorRegion : nil
    }

    /// Mouse entered `region`. Called by each region's hover handler.
    func beginHover(_ region: CursorRegion) { hoverRegion = region }

    /// Mouse left `region` — only clears if that region is still the hovered one.
    /// Adjacent cells fire enter-then-exit out of order, so an unguarded clear would
    /// wipe the hover the neighbouring cell just set.
    func endHover(_ region: CursorRegion) {
        if hoverRegion == region { hoverRegion = nil }
    }

    func beginHoverHint(_ target: Int) { hoveredHintTarget = target }
    func endHoverHint(_ target: Int) {
        if hoveredHintTarget == target { hoveredHintTarget = nil }
    }

    /// The cursor cell on the active region.
    var cursorCell: GridCell {
        switch cursorRegion {
        case .items: itemsCursor
        case .dungeonMap: dungeonCursor
        case .blockers: blockersCursor
        case .dungeonItem: dungeonItemCursor
        case .overworld: overworldCursor
        case .notes: GridCell(col: 0, row: 0)
        }
    }

    /// The cursor cell for an arbitrary region (the dispatcher needs the hovered
    /// region's cell, which isn't necessarily `cursorRegion`).
    func cell(in region: CursorRegion) -> GridCell {
        switch region {
        case .items: itemsCursor
        case .dungeonMap: dungeonCursor
        case .blockers: blockersCursor
        case .dungeonItem: dungeonItemCursor
        case .overworld: overworldCursor
        case .notes: GridCell(col: 0, row: 0)
        }
    }

    /// Move the cursor within the active region, clamped to bounds (T-134).
    func moveCursor(dcol: Int, drow: Int) {
        cursorShown = true
        hoverRegion = nil       // deliberate keyboard nav takes over from a resting mouse
        let d = Self.dims(cursorRegion)
        let (maxC, maxR) = (d.cols - 1, d.rows - 1)
        func clamp(_ v: Int, _ hi: Int) -> Int { min(hi, max(0, v)) }
        func moved(_ c: GridCell) -> GridCell {
            GridCell(col: clamp(c.col + dcol, maxC), row: clamp(c.row + drow, maxR))
        }
        switch cursorRegion {
        case .items:       itemsCursor = moved(itemsCursor)
        case .dungeonMap:  dungeonCursor = moved(dungeonCursor)
        case .blockers:    blockersCursor = moved(blockersCursor)
        case .dungeonItem: dungeonItemCursor = moved(dungeonItemCursor)
        case .overworld:   overworldCursor = moved(overworldCursor)
        case .notes:       break    // the text field handles its own caret
        }
    }

    /// Jump the cursor to an absolute cell in the active region, clamped (T-138 —
    /// voice "E7" moves the cursor there).
    func setCursor(col: Int, row: Int) {
        cursorShown = true
        hoverRegion = nil
        let d = Self.dims(cursorRegion)
        let c = min(max(0, col), d.cols - 1), r = min(max(0, row), d.rows - 1)
        let cell = GridCell(col: c, row: r)
        switch cursorRegion {
        case .items: itemsCursor = cell
        case .dungeonMap: dungeonCursor = cell
        case .blockers: blockersCursor = cell
        case .dungeonItem: dungeonItemCursor = cell
        case .overworld: overworldCursor = cell
        case .notes: break
        }
    }

    /// Step the cursor to the next / previous region in `cycleOrder` (T-135).
    func cycleRegion(forward: Bool) {
        cursorShown = true
        hoverRegion = nil
        let order = Self.cycleOrder
        guard !order.isEmpty else { return }
        let i = order.firstIndex(of: cursorRegion) ?? 0
        let n = order.count
        cursorRegion = order[(i + (forward ? 1 : n - 1)) % n]
        // Cycling never takes focus — landing on Notes only parks there (see
        // `notesFocused`), and cycling away always releases the field.
        notesFocused = false
    }

    /// Mouse hover moved onto an overworld tile / dungeon room — the cursor follows
    /// (T-134, user choice), so keyboard nudges continue from where the mouse is.
    func hoverOverworld(col: Int, row: Int) {
        overworldCursor = GridCell(col: col, row: row)
        cursorRegion = .overworld
        cursorShown = true
        beginHover(.overworld)
    }
    func hoverDungeon(col: Int, row: Int) {
        dungeonCursor = GridCell(col: col, row: row)
        cursorRegion = .dungeonMap
        cursorShown = true
        beginHover(.dungeonMap)
    }
    func hoverItems(col: Int, row: Int) {
        itemsCursor = GridCell(col: col, row: row)
        cursorRegion = .items
        cursorShown = true
        beginHover(.items)
    }
    func hoverBlockers(col: Int, row: Int) {
        blockersCursor = GridCell(col: col, row: row)
        cursorRegion = .blockers
        cursorShown = true
        beginHover(.blockers)
    }
    /// Hovering a dungeon item box (T-168): `col` = dungeon 0…8, `row` = box index 0…2,
    /// matching the on-screen layout.
    func hoverDungeonItem(col: Int, row: Int) {
        dungeonItemCursor = GridCell(col: col, row: row)
        cursorRegion = .dungeonItem
        cursorShown = true
        beginHover(.dungeonItem)
    }
}
