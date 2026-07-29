import Foundation

/// Applies a parsed `SpoilerLog` into a `TrackerModel`, per the user's chosen sections (T-181).
/// Overwrites the affected board state (the caller confirms first) — spoiling is the point.
extension SpoilerLog {

    /// Which sections to import. Mirrors the import panel's checkboxes.
    public struct Sections: OptionSet, Sendable {
        public let rawValue: Int
        public init(rawValue: Int) { self.rawValue = rawValue }
        /// The `CAVES` section → overworld tile marks.
        public static let overworldMarks = Sections(rawValue: 1 << 0)
        /// The `ITEMS` section → dungeon / white-sword / coast / armos items. *(Next slice.)*
        public static let dungeonItems   = Sections(rawValue: 1 << 1)
        /// The `LEVEL N MAP` ASCII → the 8×8 room grids. *(Next slice.)*
        public static let roomMaps       = Sections(rawValue: 1 << 2)
        /// L9 triforce requirements → Notes, plus the Start Screen spot.
        public static let l9AndStart     = Sections(rawValue: 1 << 3)
        public static let all: Sections = [.overworldMarks, .dungeonItems, .roomMaps, .l9AndStart]
    }

    /// The overworld screens that can hold the **Armos item**. The spoiler log names the armos
    /// item in `ITEMS` but never its screen (it isn't a cave), and a known randomizer glitch can
    /// omit any on-map armos marker — so after the overworld import, whichever one of these is
    /// still unmarked is the armos spot (user-provided rule, 2026-07-28). Four are normally caves.
    public static let armosCandidates: [Coord] = ["D5", "B13", "C5", "D14", "E15"].compactMap(Coord.parse)

    /// A spoiler item name (e.g. "Magic Boomerang") → the tracker's `ITEMS` id (0…14), or nil for
    /// items the tracker's item boxes don't model (e.g. "BOMB UPGRADE", map/compass). Exact,
    /// lower-cased match — names in the log are consistent, so no fuzzy substring risk.
    public static func itemID(_ name: String) -> Int? {
        switch name.lowercased() {
        case "recorder": ITEMS.recorder
        case "raft": ITEMS.raft
        case "boomerang": ITEMS.boomerang
        case "magic boomerang": ITEMS.magicBoomerang
        case "ladder": ITEMS.ladder
        case "wand": ITEMS.wand
        case "bow": ITEMS.bow
        case "magic key": ITEMS.anyKey
        case "red candle": ITEMS.redCandle
        case "silver arrow": ITEMS.silverArrow
        case "book": ITEMS.bookOrShield
        case "power bracelet": ITEMS.powerBracelet
        case "heart container": ITEMS.heartContainer
        case "red ring": ITEMS.redRing
        case "white sword": ITEMS.whiteSword
        // A bomb upgrade only exists in a swordless seed, where it occupies the WS/MS item slot
        // (`ITEMS.whiteSword`) and renders as a bomb upgrade under `isWSMSReplacedByBU`
        // (ItemIconAtlas). See `apply`, which infers swordless when any BU is present.
        case "bomb upgrade": ITEMS.whiteSword
        default: nil
        }
    }

    /// A summary of what was applied, for the post-import report.
    public struct ApplyResult: Sendable, Equatable {
        public var overworldMarksSet = 0
        public var unmappedCaveCount = 0
        public var armosInferred = false
        public var dungeonItemsSet = 0
        public var heartsPlaced = 0
        public var unmappedItemCount = 0
        public var swordlessInferred = false
        public var startSpotSet = false
        public var l9NoteAdded = false
        /// Dungeon room maps populated (levels), rooms placed, and transport ends
        /// relocated because they sat outside the 8-wide window (cosmetic — they
        /// teleport). Surfaced so the report can be honest about the relocation.
        public var roomMapsApplied = 0
        public var roomMapRoomsPlaced = 0
        public var transportsRelocated = 0
        /// Sections requested but not yet implemented (dungeon items / room maps) — surfaced so the
        /// UI can be honest about what it did.
        public var deferredSections: [String] = []
    }

    /// - Parameter heartShuffle: the seed's Heart Shuffle setting (from the import panel). **Off**:
    ///   dungeons 1–8 keep a fixed Heart Container in their first box and the log's items fill the
    ///   remaining boxes. **On**: all 9 hearts (8 dungeon + coast) are shuffled into the pool, so the
    ///   log's items — hearts included, wherever they landed (dungeon box, coast, white-sword, armos,
    ///   possibly multiples) — are placed exactly as listed.
    @discardableResult
    public func apply(to model: TrackerModel, sections: Sections, heartShuffle: Bool = false) -> ApplyResult {
        var result = ApplyResult()

        if sections.contains(.overworldMarks) {
            for cave in caves {
                model.overworldGrid.setMark(cave.mark, column: cave.coord.column, row: cave.coord.row)
                if let second = cave.shopSecondItem {
                    model.overworldGrid.setShopSecondItem(second, column: cave.coord.column, row: cave.coord.row)
                }
                result.overworldMarksSet += 1
            }
            result.unmappedCaveCount = unmappedCaves.count

            // Infer the armos spot: whichever candidate screen is still unmarked after the caves
            // are placed (see `armosCandidates`). Only when exactly one is left, to avoid guessing.
            let unmarked = Self.armosCandidates.filter {
                model.overworldGrid.mark(column: $0.column, row: $0.row) == .unmarked
            }
            if unmarked.count == 1, let spot = unmarked.first {
                model.overworldGrid.setMark(.armos, column: spot.column, row: spot.row)
                result.armosInferred = true
            }
        }

        if sections.contains(.l9AndStart) {
            if let s = startScreen {
                model.startSpot = OverworldScreenCoordinate(x: s.column, y: s.row)
                result.startSpotSet = true
            }
            if !level9Triforces.isEmpty {
                let line = "Triforces needed for Level 9: "
                    + level9Triforces.map(String.init).joined(separator: " ")
                if !model.notes.contains("Triforces needed for Level 9") {
                    model.notes += (model.notes.isEmpty ? "" : "\n") + line
                }
                result.l9NoteAdded = true
            }
        }

        if sections.contains(.dungeonItems) {
            let tracker = model.dungeonTracker
            // A bomb-upgrade item anywhere ⇒ swordless seed (the only time BUs are items) — user rule.
            if items.contains(where: { $0.itemName.lowercased() == "bomb upgrade" }) {
                model.isWSMSReplacedByBU = true
                result.swordlessInferred = true
            }
            // Seed the fixed dungeon hearts per Heart Shuffle (off → L1–8 box[0] = heart; on → empty),
            // and record the flag so the tracker matches the seed.
            model.setHeartShuffle(heartShuffle)

            // The three named caves (present, uncollected).
            func setNamed(_ box: Box, _ name: String) {
                if let id = Self.itemID(name) { box.set(cellCurrent: id, playerHas: .no); result.dungeonItemsSet += 1 }
                else { result.unmappedItemCount += 1 }
            }
            for p in items {
                switch p.site {
                case .whiteSwordCave: setNamed(tracker.sword2Box, p.itemName)
                case .armos: setNamed(tracker.armosBox, p.itemName)
                case .coastLadderSpot: setNamed(tracker.ladderBox, p.itemName)
                case .dungeon: break   // grouped below
                }
            }
            // Dungeon floor items → filled into each dungeon's still-empty boxes in listed order
            // (we can't tell floor vs basement from the log, so box order follows the log). Off:
            // box[0] holds the fixed heart, so items flow into the remaining boxes — but the log's
            // *own* heart entries are real placements (e.g. the 9th "coast" heart relocated into a
            // dungeon) and are kept, not dropped.
            let byDungeon = Dictionary(grouping: items.compactMap { p -> (Int, String)? in
                if case .dungeon(let n) = p.site { return (n, p.itemName) } else { return nil }
            }, by: { $0.0 })
            for (n, list) in byDungeon where (1...9).contains(n) {
                let boxes = tracker.dungeons[n - 1].boxes
                var b = 0
                for name in list.map({ $0.1 }) {
                    guard let id = Self.itemID(name) else { result.unmappedItemCount += 1; continue }
                    while b < boxes.count && boxes[b].cellCurrent != -1 { b += 1 }
                    guard b < boxes.count else { break }
                    boxes[b].set(cellCurrent: id, playerHas: .no)
                    result.dungeonItemsSet += 1
                    b += 1
                }
            }
            // Heart Shuffle on: the log gives no heart locations, so every slot still empty after the
            // items are placed is a shuffled heart (dungeon box, or coast/white-sword/armos).
            if heartShuffle {
                func fillEmptyWithHeart(_ box: Box) {
                    if box.cellCurrent == -1 { box.set(cellCurrent: ITEMS.heartContainer, playerHas: .no); result.heartsPlaced += 1 }
                }
                for d in tracker.dungeons { for box in d.boxes { fillEmptyWithHeart(box) } }
                for box in [tracker.ladderBox, tracker.sword2Box, tracker.armosBox] { fillEmptyWithHeart(box) }
            }
        }

        if sections.contains(.roomMaps) {
            for dm in maps where (1...9).contains(dm.level) {
                let (placed, relocated) = Self.applyRoomMap(dm, to: model.dungeonRoomMaps[dm.level - 1])
                if placed > 0 {
                    result.roomMapsApplied += 1
                    result.roomMapRoomsPlaced += placed
                    result.transportsRelocated += relocated
                }
            }
        }

        return result
    }

    // MARK: - Room-map application

    private static func transportType(_ n: Int) -> RoomType {
        switch n {
        case 1: .transport1; case 2: .transport2; case 3: .transport3; case 4: .transport4
        case 5: .transport5; case 6: .transport6; case 7: .transport7; default: .transport8
        }
    }

    private static func entranceType(_ dir: SpoilerLog.EntranceDir) -> RoomType {
        switch dir {
        case .north: .startEnterFromN; case .south: .startEnterFromS
        case .east: .startEnterFromE; case .west: .startEnterFromW
        }
    }

    /// Populate one dungeon's `DungeonRoomMap` from a parsed spoiler map (overwrites
    /// it). Chooses the 8-wide column window that captures the most rooms (this always
    /// captures the whole connected cluster — only teleporting transport ends fall
    /// outside), off-maps every non-room cell so the shape reads, places transports +
    /// the entrance, and opens the `-`/`|` doors. Outlier transport ends are relocated
    /// to the nearest free cell (their exact column is cosmetic; the pair is what
    /// matters). Returns (rooms placed, transports relocated).
    static func applyRoomMap(_ dm: SpoilerLog.DungeonMap, to target: DungeonRoomMap) -> (Int, Int) {
        let cols = dm.rooms.keys.map(\.col)
        guard !cols.isEmpty else { return (0, 0) }

        // Best 8-wide window (start column capturing the most rooms).
        var offset = cols.min()!, best = -1
        for w in Set(cols).sorted() {
            let n = dm.rooms.keys.reduce(0) { $0 + ((w...w + 7).contains($1.col) ? 1 : 0) }
            if n > best { best = n; offset = w }
        }

        func localIndex(_ c: Int, _ r: Int) -> Int { r * 8 + c }
        var placement: [SpoilerLog.MapCell: (col: Int, row: Int)] = [:]
        var occupied: Set<Int> = []
        let ordered = dm.rooms.keys.sorted { ($0.row, $0.col) < ($1.row, $1.col) }

        // In-window rooms map directly.
        for cell in ordered where (offset...offset + 7).contains(cell.col) {
            let lc = cell.col - offset
            placement[cell] = (lc, cell.row)
            occupied.insert(localIndex(lc, cell.row))
        }
        // Outlier transport ends → nearest free cell to their edge/row.
        var relocated = 0
        for cell in ordered where !(offset...offset + 7).contains(cell.col) {
            let edge = cell.col < offset ? 0 : 7
            guard let free = nearestFreeCell(preferredCol: edge, row: cell.row, occupied: occupied) else { continue }
            placement[cell] = free
            occupied.insert(localIndex(free.col, free.row))
            relocated += 1
        }

        // Build a fresh map, then commit atomically (full overwrite).
        let fresh = DungeonRoomMap()
        for r in 0..<8 {
            for c in 0..<8 where !occupied.contains(localIndex(c, r)) {
                fresh.setRoom(DungeonRoom(roomType: .offTheMap), col: c, row: r)
            }
        }
        // Transports (plain rooms stay unmarked = on-map, unexplored).
        for (cell, kind) in dm.rooms {
            guard let p = placement[cell], case .transport(let n) = kind else { continue }
            fresh.setRoom(DungeonRoom(roomType: transportType(n)), col: p.col, row: p.row)
        }
        // Entrance.
        if let ec = dm.entranceCell, let dir = dm.entranceDir, let p = placement[ec] {
            fresh.setRoom(DungeonRoom(roomType: entranceType(dir)), col: p.col, row: p.row)
        }
        // Open doors (only between two placed, still-adjacent rooms).
        for d in dm.hDoors {
            guard let a = placement[SpoilerLog.MapCell(col: d.col, row: d.row)],
                  let b = placement[SpoilerLog.MapCell(col: d.col + 1, row: d.row)],
                  a.row == b.row, b.col == a.col + 1, a.col < 7 else { continue }
            fresh.setHorizontalDoor(.yes, col: a.col, row: a.row)
        }
        for d in dm.vDoors {
            guard let a = placement[SpoilerLog.MapCell(col: d.col, row: d.row)],
                  let b = placement[SpoilerLog.MapCell(col: d.col, row: d.row + 1)],
                  a.col == b.col, b.row == a.row + 1, a.row < 7 else { continue }
            fresh.setVerticalDoor(.yes, col: a.col, row: a.row)
        }
        fresh.firstInteractionDone = true
        target.restore(fresh.state)
        return (dm.rooms.count, relocated)
    }

    /// The free cell nearest `(preferredCol, row)` — same row first (sweeping from the
    /// preferred edge), then nearer rows. `nil` if the whole 8×8 is full.
    private static func nearestFreeCell(preferredCol: Int, row: Int, occupied: Set<Int>) -> (col: Int, row: Int)? {
        for dr in [0, 1, -1, 2, -2, 3, -3, 4, -4, 5, -5, 6, -6, 7, -7] {
            let r = row + dr
            guard (0..<8).contains(r) else { continue }
            let sweep = preferredCol == 0 ? Array(0..<8) : Array((0..<8).reversed())
            for c in sweep where !occupied.contains(r * 8 + c) { return (c, r) }
        }
        return nil
    }
}
