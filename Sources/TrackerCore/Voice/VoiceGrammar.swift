import Foundation

/// A parsed voice command (T-137). Voice is a second front-end onto the same actions
/// the hotkey cursor drives — a spoken phrase resolves to one of these, which the app
/// executes with the existing region-apply code.
public enum VoiceCommand: Equatable, Sendable {
    /// Mark an overworld cell (0-based column/row) — e.g. "D5 bomb shop".
    case overworldMark(column: Int, row: Int, mark: OverworldTileMark)
    /// Mark an overworld cell as a take-any cave and record what was claimed — e.g.
    /// "D5 take any potion". Routes through the model's take-any linkage (updates the
    /// linked item-grid heart slot too), which a plain mark doesn't.
    case overworldTakeAny(column: Int, row: Int, state: TakeAnyHeartState)
    /// Switch the dungeon tab (1–9) — e.g. "enter level 5".
    case dungeonTab(Int)
    /// Nudge the keyboard cursor — e.g. "north".
    case moveCursor(dcol: Int, drow: Int)
}

/// Parses a spoken phrase into a `VoiceCommand`. Structured grammar (the user's
/// "grammar first" choice); pure and testable, no speech dependency.
///
/// Coordinates use the app's own tile labels (`OverworldCoords.label`): **letter =
/// row (A–H), number = column** (overworld 1–16). So "D5" = row D, column 5.
public enum VoiceGrammar {
    public static func parse(_ raw: String) -> VoiceCommand? {
        let tokens = normalize(raw)
        guard !tokens.isEmpty else { return nil }

        // 1) A bare direction moves the cursor.
        if let move = direction(in: tokens) { return move }

        // 2) A coordinate anywhere → an overworld action; the rest names it. "take
        //    any …" is checked before the mark table so "take any potion" sets the
        //    claimed item rather than matching the standalone "potion" → potion shop.
        if let (coord, rest) = coordinate(in: tokens) {
            if let state = takeAnyState(rest) {
                return .overworldTakeAny(column: coord.column, row: coord.row, state: state)
            }
            if let mark = markPhrase(rest) {
                return .overworldMark(column: coord.column, row: coord.row, mark: mark)
            }
            return nil
        }

        // 3) No coordinate: "enter level N" / "level N" / "dungeon N" switches tabs.
        if let n = levelNumber(in: tokens), (1...9).contains(n) {
            return .dungeonTab(n)
        }
        return nil
    }

    // MARK: Normalization

    /// Lowercase, strip punctuation, split into words, and split any letter-glued-to-
    /// digits token ("d5" → "d","5") so the coordinate scanner sees uniform tokens.
    static func normalize(_ raw: String) -> [String] {
        let cleaned = raw.lowercased().map { $0.isLetter || $0.isNumber ? $0 : " " }
        var out: [String] = []
        for word in String(cleaned).split(separator: " ") {
            out.append(contentsOf: splitLetterDigits(String(word)))
        }
        return out
    }

    /// "d5" → ["d","5"], "5d" → ["5","d"], "d" → ["d"], "level5" → ["level","5"].
    private static func splitLetterDigits(_ word: String) -> [String] {
        var parts: [String] = []
        var cur = ""
        var curIsDigit: Bool?
        for ch in word {
            let isDigit = ch.isNumber
            if let prev = curIsDigit, prev != isDigit {
                parts.append(cur); cur = ""
            }
            cur.append(ch); curIsDigit = isDigit
        }
        if !cur.isEmpty { parts.append(cur) }
        return parts
    }

    // MARK: Pieces

    private static let numberWords: [String: Int] = [
        "one": 1, "two": 2, "three": 3, "four": 4, "five": 5, "six": 6, "seven": 7,
        "eight": 8, "nine": 9, "ten": 10, "eleven": 11, "twelve": 12, "thirteen": 13,
        "fourteen": 14, "fifteen": 15, "sixteen": 16,
        // NOTE: phonetic homophones like "to"/"too"→2 were removed — they corrupted
        // real number words (the recognizer hearing "twelve" as "to" → 2). Bias the
        // recognizer toward the true words via `contextualVocabulary` instead.
    ]

    static func asInt(_ token: String) -> Int? {
        if let n = Int(token) { return n }
        return numberWords[token]
    }

    private static func direction(in tokens: [String]) -> VoiceCommand? {
        for t in tokens {
            switch t {
            case "north", "up":    return .moveCursor(dcol: 0, drow: -1)
            case "south", "down":  return .moveCursor(dcol: 0, drow: 1)
            case "east", "right":  return .moveCursor(dcol: 1, drow: 0)
            case "west", "left":   return .moveCursor(dcol: -1, drow: 0)
            default: continue
            }
        }
        return nil
    }

    /// The first `A–H` letter immediately followed by a number token (1–16). Returns
    /// the 0-based (column, row) and the remaining tokens.
    static func coordinate(in tokens: [String]) -> (coord: (column: Int, row: Int), rest: [String])? {
        for i in 0..<(tokens.count - 1) where tokens[i].count == 1 {
            guard let letter = tokens[i].first, ("a"..."h").contains(letter),
                  let num = asInt(tokens[i + 1]), (1...16).contains(num) else { continue }
            let row = Int(letter.asciiValue! - Character("a").asciiValue!)
            let rest = Array(tokens[..<i] + tokens[(i + 2)...])
            return ((column: num - 1, row: row), rest)
        }
        return nil
    }

    /// "level 5" / "dungeon 5" / "enter level 5" → 5.
    private static func levelNumber(in tokens: [String]) -> Int? {
        for i in 0..<tokens.count where tokens[i] == "level" || tokens[i] == "dungeon" {
            if i + 1 < tokens.count, let n = asInt(tokens[i + 1]) { return n }
        }
        return nil
    }

    /// "take any [potion/candle/heart]" → the claimed take-any state; `nil` if the
    /// phrase isn't a take-any at all.
    static func takeAnyState(_ tokens: [String]) -> TakeAnyHeartState? {
        let joined = tokens.joined(separator: " ")
        guard joined.contains("take any") || joined.contains("take-any")
            || joined.contains("takeany") || joined.contains("take-in") else { return nil }
        if joined.contains("potion") { return .takenPotion }
        if joined.contains("candle") { return .takenCandle }
        if joined.contains("heart") { return .takenHeart }
        return .untaken   // "take any" with nothing claimed yet
    }

    /// Map the words left after a coordinate to an overworld mark. Uses substring
    /// matching over the joined phrase, so glued transcriptions ("bookshop") and
    /// homophones still resolve.
    static func markPhrase(_ tokens: [String]) -> OverworldTileMark? {
        let joined = tokens.joined(separator: " ")
        func has(_ needles: String...) -> Bool { needles.contains { joined.contains($0) } }

        // Shops — "<kind> shop" (or glued "bombshop").
        if has("shop") {
            if has("bomb") { return .shop(.bomb) }
            if has("arrow") { return .shop(.arrow) }
            if has("candle") { return .shop(.candle) }
            if has("book", "magic") { return .shop(.book) }
            if has("ring", "blue") { return .shop(.blueRing) }
            if has("meat", "food") { return .shop(.meat) }
            if has("key") { return .shop(.key) }
            if has("shield") { return .shop(.shield) }
            if has("potion") { return .potionShop }
            if has("hint") { return .hintShop }
        }
        // Sword caves — "<wood/white/magical> sword".
        if has("sword") {
            if has("wood", "brown") { return .swordCave(1) }
            if has("white") { return .swordCave(2) }
            if has("magical", "magic") { return .swordCave(3) }
        }
        // Secrets — "<size> secret".
        if has("secret") {
            if has("large", "big") { return .secret(.large) }
            if has("medium") { return .secret(.medium) }
            if has("small") { return .secret(.small) }
            return .secret(.unknown)
        }
        // Any road — "any road N".
        if has("road", "any road"), let n = tokens.compactMap(asInt).first, (1...4).contains(n) {
            return .anyRoad(n)
        }
        // Dungeon on a tile — "level N" / "dungeon N".
        if has("level", "dungeon"),
           let n = tokens.compactMap(asInt).first, (1...9).contains(n) {
            return .dungeon(n)
        }
        // Singles (with common speech-to-text homophones).
        if has("armos", "armas", "armoss", "almos", "amos") { return .armos }
        if has("letter") { return .theLetter }
        if has("potion") { return .potionShop }
        if has("door") { return .doorRepair }              // "door repair"
        if has("money", "gamble", "making game") { return .moneyMakingGame }
        if has("don t care", "dark", "dontcare") { return .dontCare }
        if has("nothing", "clear", "empty", "erase") { return .unmarked }
        return nil
    }

    /// Phrases to bias the speech recognizer toward (`contextualStrings`). Dramatically
    /// improves recognition of the tracker's jargon over general dictation.
    public static let contextualVocabulary: [String] = [
        "bomb shop", "arrow shop", "candle shop", "book shop", "blue ring shop",
        "meat shop", "key shop", "shield shop", "potion shop", "hint shop",
        "armos", "the letter", "door repair", "take any", "money making game",
        "any road", "wood sword", "white sword", "magical sword",
        "large secret", "medium secret", "small secret", "don't care", "nothing",
        "level", "dungeon", "enter level", "north", "south", "east", "west",
        // Bias two-digit column words so "twelve" isn't heard as "to"/"two".
        "ten", "eleven", "twelve", "thirteen", "fourteen", "fifteen", "sixteen",
    ]
}
