import Foundation

/// A parsed Z1R randomizer **spoiler log** (`*_log.txt`), for the spoiler importer (T-181).
///
/// Pure/`Sendable` — no UI, no model mutation. `parse(_:)` turns the log text into structured
/// data; a separate apply layer writes it into the tracker (per the user's per-section checkboxes).
/// The cave-string → `OverworldTileMark` vocabulary is user-verified ([[spoiler-cave-strings]]);
/// unrecognized cave strings land in `unmappedCaves` rather than being mis-marked.
///
/// This slice covers `SEED`, `LEVEL 9 ENTRY`, `ITEMS`, `CAVES`, and `SHOP INFO`. The `LEVEL N MAP`
/// ASCII grids are a later slice (see T-181); item **names** are kept raw here and mapped to the
/// app's item model in the apply layer (another verify-don't-guess vocabulary).
public struct SpoilerLog: Sendable, Equatable {

    /// A 0-indexed overworld screen coordinate (column 0…15, row 0…7).
    public struct Coord: Sendable, Equatable, Hashable {
        public let column: Int
        public let row: Int
        public init(column: Int, row: Int) { self.column = column; self.row = row }

        /// Parse a spoiler coordinate like `E8` — row letter A…H (0…7), column 1…16 (→ 0…15).
        /// `hexIndex = row*16 + (col-1)` (verified: `E8` → `0x47` = 71).
        public static func parse(_ s: String) -> Coord? {
            let t = s.trimmingCharacters(in: .whitespaces)
            guard let first = t.first, first.isLetter,
                  let scalar = first.uppercased().unicodeScalars.first else { return nil }
            let rowIdx = Int(scalar.value) - 65   // 'A' → 0
            guard (0...7).contains(rowIdx), let col = Int(t.dropFirst()), (1...16).contains(col)
            else { return nil }
            return Coord(column: col - 1, row: rowIdx)
        }
    }

    /// A resolved overworld cave: the tile mark, plus a shop's second trackable item (if any).
    public struct CaveEntry: Sendable, Equatable {
        public let coord: Coord
        public let mark: OverworldTileMark
        public let shopSecondItem: ShopKind?
    }

    /// An `ITEMS`-section placement. Item names are raw (mapped to the model in the apply layer).
    public struct ItemPlacement: Sendable, Equatable {
        public enum Site: Sendable, Equatable {
            case dungeon(Int)          // "Level 1-N"
            case whiteSwordCave        // "White Sword Cave"
            case armos                 // "Armos Item"
            case coastLadderSpot       // "Coast Ladder Spot"
        }
        public let site: Site
        public let overworld: Coord?   // where the dungeon sits, when the line gives it
        public let itemName: String    // raw randomizer name, e.g. "Magic Boomerang"
    }

    public struct UnmappedCave: Sendable, Equatable {
        public let coord: Coord
        public let raw: String
    }

    public var seed: Int?
    public var level9Triforces: [Int]
    public var startScreen: Coord?
    public var caves: [CaveEntry]
    public var items: [ItemPlacement]
    public var unmappedCaves: [UnmappedCave]

    // MARK: - Parse

    public static func parse(_ text: String) -> SpoilerLog {
        let lines = text.components(separatedBy: .newlines)
        let shopKinds = parseShopInfo(lines)   // shop number → trackable kinds, for "SHOP N" caves

        var seed: Int?
        var l9: [Int] = []
        var start: Coord?
        var caves: [CaveEntry] = []
        var items: [ItemPlacement] = []
        var unmapped: [UnmappedCave] = []
        var section = ""

        for raw in lines {
            let line = raw.trimmingCharacters(in: .whitespaces)
            if line.isEmpty { continue }

            // Section headers.
            if line == "ITEMS" { section = "ITEMS"; continue }
            if line == "CAVES" { section = "CAVES"; continue }
            if line == "SHOP INFO" { section = "SHOP"; continue }
            if line.hasPrefix("LEVEL ") && line.hasSuffix(" MAP") { section = "MAP"; continue }
            if line.hasSuffix("----") { continue }

            if line.hasPrefix("SEED ") { seed = Int(line.dropFirst(5).trimmingCharacters(in: .whitespaces)) }
            if line.hasPrefix("Specific triforces needed:") {
                l9 = line.split(separator: ":").last.map(String.init)?
                    .split(whereSeparator: { $0 == " " }).compactMap { Int($0) } ?? []
            }
            if line.hasPrefix("Start Screen:") {
                start = Coord.parse(String(line.dropFirst("Start Screen:".count)))
            }

            switch section {
            case "ITEMS":
                if let p = parseItemLine(line) { items.append(p) }
            case "CAVES":
                if let (coord, desc) = parseCaveLine(line) {
                    if let (mark, second) = mapCave(desc, shopKinds: shopKinds) {
                        caves.append(CaveEntry(coord: coord, mark: mark, shopSecondItem: second))
                    } else {
                        unmapped.append(UnmappedCave(coord: coord, raw: desc))
                    }
                }
            default:
                break
            }
        }

        return SpoilerLog(seed: seed, level9Triforces: l9, startScreen: start,
                          caves: caves, items: items, unmappedCaves: unmapped)
    }

    // MARK: - Line parsers

    /// `Location E10 contains: MAGICAL SWORD CAVE` → (coord, "MAGICAL SWORD CAVE").
    private static func parseCaveLine(_ line: String) -> (Coord, String)? {
        guard line.hasPrefix("Location "), let range = line.range(of: " contains:") else { return nil }
        let coordStr = String(line[line.index(line.startIndex, offsetBy: 9)..<range.lowerBound])
        guard let coord = Coord.parse(coordStr) else { return nil }
        let desc = String(line[range.upperBound...]).trimmingCharacters(in: .whitespaces)
        return (coord, desc)
    }

    /// `Level 1-6 (located at 47 E8) contains Boomerang` / `White Sword Cave contains Wand`
    /// / `Armos Item contains Red Ring` / `Coast Ladder Spot contains BOMB UPGRADE`.
    private static func parseItemLine(_ line: String) -> ItemPlacement? {
        guard let r = line.range(of: " contains ") else { return nil }
        let head = String(line[..<r.lowerBound])
        let item = String(line[r.upperBound...]).trimmingCharacters(in: .whitespaces)
        guard !item.isEmpty else { return nil }

        if head.hasPrefix("Level ") {
            // "Level 1-6 (located at 47 E8)" → dungeon 6, overworld E8.
            let afterDash = head.drop(while: { $0 != "-" }).dropFirst()
            let dungeonNum = Int(afterDash.prefix(while: { $0.isNumber })) ?? 0
            var coord: Coord?
            if let lp = head.range(of: "(located at "), let rp = head.range(of: ")") {
                let inside = String(head[lp.upperBound..<rp.lowerBound])   // "47 E8"
                if let last = inside.split(separator: " ").last { coord = Coord.parse(String(last)) }
            }
            guard dungeonNum >= 1 else { return nil }
            return ItemPlacement(site: .dungeon(dungeonNum), overworld: coord, itemName: item)
        }
        if head.hasPrefix("White Sword Cave") { return ItemPlacement(site: .whiteSwordCave, overworld: nil, itemName: item) }
        if head.hasPrefix("Armos") { return ItemPlacement(site: .armos, overworld: nil, itemName: item) }
        if head.hasPrefix("Coast") { return ItemPlacement(site: .coastLadderSpot, overworld: nil, itemName: item) }
        return nil
    }

    // MARK: - Cave vocabulary (user-verified — see [[spoiler-cave-strings]])

    /// Map a cave description to a mark (+ shop second item), or nil = unrecognized (→ unmapped).
    private static func mapCave(_ desc: String, shopKinds: [Int: [ShopKind]]) -> (OverworldTileMark, ShopKind?)? {
        let d = desc.uppercased()

        if d.hasPrefix("LEVEL "), let n = Int(d.dropFirst(6).prefix(while: { $0.isNumber })), (1...9).contains(n) {
            return (.dungeon(n), nil)
        }
        if d.hasPrefix("SHOP "), let n = Int(d.dropFirst(5).prefix(while: { $0.isNumber })) {
            let kinds = shopKinds[n] ?? []
            guard let primary = kinds.first else { return nil }   // no trackable item → unmapped
            return (.shop(primary), kinds.dropFirst().first)
        }
        switch d {
        case "WOODEN SWORD CAVE": return (.swordCave(1), nil)
        case "WHITE SWORD CAVE":  return (.swordCave(2), nil)
        case "MAGICAL SWORD CAVE": return (.swordCave(3), nil)
        case "10 SECRET":  return (.secret(.small), nil)
        case "30 SECRET":  return (.secret(.medium), nil)
        case "100 SECRET": return (.secret(.large), nil)
        case "DOOR REPAIR": return (.doorRepair, nil)
        case "MONEY MAKING GAME": return (.moneyMakingGame, nil)
        case "POTION SHOP": return (.potionShop, nil)
        case "LETTER CAVE": return (.theLetter, nil)
        case "TAKE ANY ONE": return (.takeAny, nil)                 // unclaimed heart/potion/candle
        default: break
        }
        if d.hasPrefix("TAKE ANY ROAD") { return (.anyRoad(0), nil) }  // warp, unknown 1–4 order
        // Hint caves (user-verified): "SECRET IS IN...", the two "PAY ME" caves, old-man-at-grave.
        if d.hasPrefix("SECRET IS IN") || d.hasSuffix("PAY ME") || d == "OLD MAN AT GRAVE" {
            return (.hintShop, nil)
        }
        return nil
    }

    // MARK: - SHOP INFO

    /// Build `shopNumber → [ShopKind]` (trackable kinds only, notable-first) from the SHOP INFO
    /// section, so a `SHOP N` cave resolves to a shop mark (+ optional second item).
    private static func parseShopInfo(_ lines: [String]) -> [Int: [ShopKind]] {
        var table: [Int: [ShopKind]] = [:]
        var current: Int?
        var inShopInfo = false
        for raw in lines {
            let line = raw.trimmingCharacters(in: .whitespaces)
            if line == "SHOP INFO" { inShopInfo = true; continue }
            guard inShopInfo else { continue }
            if line.hasPrefix("LEVEL ") && line.hasSuffix(" MAP") { break }   // SHOP INFO ended
            if line.hasPrefix("SHOP "), let n = Int(line.dropFirst(5).prefix(while: { $0.isNumber })) {
                current = n; table[n] = []; continue
            }
            if line.hasPrefix("POTION SHOP") { current = nil; continue }      // priced separately
            if let n = current, let colon = line.firstIndex(of: ":") {
                let item = String(line[..<colon]).trimmingCharacters(in: .whitespaces)
                if let kind = shopItemKind(item) { table[n, default: []].append(kind) }
            }
        }
        // Reorder each shop notable-first so the primary mark is the item players track.
        let priority: [ShopKind] = [.blueRing, .candle, .book, .arrow, .bomb, .shield, .key, .meat]
        for (n, kinds) in table {
            table[n] = priority.filter { kinds.contains($0) }
        }
        return table
    }

    /// A shop item name → the tracked `ShopKind`, or nil for untracked items (e.g. Heart).
    private static func shopItemKind(_ name: String) -> ShopKind? {
        let s = name.uppercased()
        if s.contains("BLUE RING") { return .blueRing }
        if s.contains("CANDLE")    { return .candle }   // "Blue Candle"
        if s.contains("BOOK")      { return .book }
        if s.contains("ARROW")     { return .arrow }    // "Wooden Arrow"
        if s.contains("BOMB")      { return .bomb }     // "Bombs"
        if s.contains("SHIELD")    { return .shield }   // "Magic Shield"
        if s.contains("KEY")       { return .key }
        if s.contains("BAIT")      { return .meat }     // Bait = meat/food
        return nil                                       // Heart, Potion, etc. — untracked
    }
}
