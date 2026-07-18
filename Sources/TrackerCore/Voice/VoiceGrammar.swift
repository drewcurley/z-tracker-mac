import Foundation

/// A parsed voice command (T-137/T-138). Voice drives the **keyboard cursor**: a
/// coordinate moves the cursor (in whatever region is active), an action applies at
/// the cursor cell, and the two combine. Execution (region-aware) lives in the app.
public enum VoiceCommand: Equatable, Sendable {
    /// Nudge the cursor — "north" / "down".
    case moveCursor(dcol: Int, drow: Int)
    /// Move the cursor to a cell (0-based) in the active region — a coordinate alone,
    /// e.g. "E7".
    case cursorTo(column: Int, row: Int)
    /// Apply an action (raw words, resolved per region) at the current cursor cell —
    /// e.g. "potion".
    case actionAtCursor(words: [String])
    /// Move the cursor to a cell, then apply an action there — "E7 bomb shop".
    case actionAt(column: Int, row: Int, words: [String])
    /// Switch the dungeon tab (1–9) and drop the cursor into that dungeon — "enter
    /// level 5".
    case dungeonTab(Int)
    /// Move the cursor back to the overworld region — "overworld" / "leave dungeon".
    case exitToOverworld
    /// Move the cursor to the marked start tile — "go to start" / "start".
    case gotoStart
}

/// A resolved overworld action (T-138). The word→action resolution stays in the pure
/// grammar so it's testable; the app calls it once it knows the cursor is on the
/// overworld region.
public enum OverworldAction: Equatable, Sendable {
    case mark(OverworldTileMark)
    case takeAny(TakeAnyHeartState)
    case setStart
    case clearStart
}

/// Parses a spoken phrase into a `VoiceCommand`. Pure and testable; no speech
/// dependency. Coordinates use the app's tile labels (`OverworldCoords.label`):
/// **letter = row, number = column** — with NATO letters ("echo seven" = E7)
/// supported to dodge the "E" / "east" homophone clash.
public enum VoiceGrammar {
    public static func parse(_ raw: String) -> VoiceCommand? {
        let tokens = normalize(raw)
        guard !tokens.isEmpty else { return nil }

        // A coordinate is the strongest signal — move the cursor there (+ act if more).
        if let (coord, rest) = coordinate(in: tokens) {
            return rest.isEmpty
                ? .cursorTo(column: coord.column, row: coord.row)
                : .actionAt(column: coord.column, row: coord.row, words: rest)
        }
        let joined = tokens.joined(separator: " ")
        // Region navigation.
        if joined.contains("overworld") || joined.contains("over world")
            || joined.contains("leave dungeon") || joined.contains("exit dungeon")
        {
            return .exitToOverworld
        }
        // Jump to the start tile (but not "set start" / "clear start", which mark).
        if joined == "start" || joined == "restart" || joined == "home"
            || joined.contains("go to start") || joined.contains("goto start")
            || joined.contains("go to the start")
        {
            return .gotoStart
        }
        // A bare direction moves the cursor.
        if let move = direction(in: tokens) { return move }
        // "enter level N" / "level N" / "dungeon N" switches tabs — UNLESS a mark verb
        // is present ("set/mark/place level N"), which marks the cursor tile instead
        // (so you can label a dungeon on the tile you've navigated to, T-138).
        let markVerb = tokens.contains("set") || tokens.contains("mark")
            || tokens.contains("place") || tokens.contains("put")
        if !markVerb, let n = levelNumber(in: tokens), (1...9).contains(n) { return .dungeonTab(n) }
        // Otherwise treat the words as an action on the current cursor cell; execution
        // resolves them for the active region (or no-ops if they mean nothing there).
        return .actionAtCursor(words: tokens)
    }

    /// Resolve action words for the **overworld** region.
    public static func overworldAction(_ words: [String]) -> OverworldAction? {
        let joined = words.joined(separator: " ")
        if joined.contains("clear start") || joined.contains("remove start") { return .clearStart }
        if joined.contains("set start") || joined.contains("start here")
            || joined.contains("start spot") || joined.contains("starting")
        {
            return .setStart
        }
        if let state = takeAnyState(words) { return .takeAny(state) }
        if let mark = markPhrase(words) { return .mark(mark) }
        return nil
    }

    // MARK: Normalization

    static func normalize(_ raw: String) -> [String] {
        let cleaned = raw.lowercased().map { $0.isLetter || $0.isNumber ? $0 : " " }
        var out: [String] = []
        for word in String(cleaned).split(separator: " ") {
            out.append(contentsOf: splitLetterDigits(String(word)))
        }
        return out
    }

    private static func splitLetterDigits(_ word: String) -> [String] {
        var parts: [String] = []
        var cur = ""
        var curIsDigit: Bool?
        for ch in word {
            let isDigit = ch.isNumber
            if let prev = curIsDigit, prev != isDigit {
                parts.append(cur)
                cur = ""
            }
            cur.append(ch)
            curIsDigit = isDigit
        }
        if !cur.isEmpty { parts.append(cur) }
        return parts
    }

    // MARK: Pieces

    private static let numberWords: [String: Int] = [
        "one": 1, "two": 2, "three": 3, "four": 4, "five": 5, "six": 6, "seven": 7,
        "eight": 8, "nine": 9, "ten": 10, "eleven": 11, "twelve": 12, "thirteen": 13,
        "fourteen": 14, "fifteen": 15, "sixteen": 16,
    ]

    /// NATO phonetic for the row letters A–H (index 0–7) — cleaner than single letters,
    /// which speech-to-text mangles ("E" → "east"/"eat", "B" → "be").
    private static let natoRows: [String: Int] = [
        "alpha": 0, "bravo": 1, "charlie": 2, "delta": 3,
        "echo": 4, "foxtrot": 5, "golf": 6, "hotel": 7,
    ]

    static func asInt(_ token: String) -> Int? { Int(token) ?? numberWords[token] }

    /// A row index (0–7) from a single letter A–H or its NATO word.
    static func rowLetter(_ token: String) -> Int? {
        if token.count == 1, let c = token.first, ("a"..."h").contains(c) {
            return Int(c.asciiValue! - Character("a").asciiValue!)
        }
        return natoRows[token]
    }

    /// Only up/down/left/right — the compass words (north/south/**east**/west) were
    /// dropped because "east"/"west" collide with the recognizer hearing the letters
    /// E/W (T-138, user request).
    private static func direction(in tokens: [String]) -> VoiceCommand? {
        for t in tokens {
            switch t {
            case "up": return .moveCursor(dcol: 0, drow: -1)
            case "down": return .moveCursor(dcol: 0, drow: 1)
            case "right": return .moveCursor(dcol: 1, drow: 0)
            case "left": return .moveCursor(dcol: -1, drow: 0)
            default: continue
            }
        }
        return nil
    }

    /// The first row-letter immediately followed by a number (1–16). Returns the
    /// 0-based (column, row) and the remaining tokens.
    static func coordinate(in tokens: [String]) -> (coord: (column: Int, row: Int), rest: [String])?
    {
        for i in 0..<tokens.count {
            guard let row = rowLetter(tokens[i]),
                i + 1 < tokens.count, let num = asInt(tokens[i + 1]), (1...16).contains(num)
            else { continue }
            let rest = Array(tokens[..<i] + tokens[(i + 2)...])
            return ((column: num - 1, row: row), rest)
        }
        return nil
    }

    private static func levelNumber(in tokens: [String]) -> Int? {
        for i in 0..<tokens.count where tokens[i] == "level" || tokens[i] == "dungeon" {
            if i + 1 < tokens.count, let n = asInt(tokens[i + 1]) { return n }
        }
        return nil
    }

    /// "take any [potion/candle/heart]" → the claimed take-any state.
    static func takeAnyState(_ tokens: [String]) -> TakeAnyHeartState? {
        let joined = tokens.joined(separator: " ")
        guard
            joined.contains("take any") || joined.contains("take-any")
                || joined.contains("takeany") || joined.contains("take-in")
        else { return nil }
        if joined.contains("potion") { return .takenPotion }
        if joined.contains("candle") { return .takenCandle }
        if joined.contains("heart") { return .takenHeart }
        return .untaken
    }

    /// Map action words to an overworld mark (substring matching handles glued words
    /// and homophones). "shop" is optional — "potion" alone → potion shop.
    static func markPhrase(_ tokens: [String]) -> OverworldTileMark? {
        let joined = tokens.joined(separator: " ")
        func has(_ needles: String...) -> Bool { needles.contains { joined.contains($0) } }

        if has("shop") {
            if has("bomb") { return .shop(.bomb) }
            if has("arrow") { return .shop(.arrow) }
            if has("candle") { return .shop(.candle) }
            if has("book") { return .shop(.book) }
            if has("ring", "blue") { return .shop(.blueRing) }
            if has("meat", "food", "bait") { return .shop(.meat) }
            if has("key") { return .shop(.key) }
            if has("shield") { return .shop(.shield) }
            if has("potion") { return .potionShop }
            if has("hint") { return .hintShop }
        }
        if has("sword") {
            if has("wood", "brown") { return .swordCave(1) }
            if has("white") { return .swordCave(2) }
            if has("magical", "magic") { return .swordCave(3) }
        }
        if has("secret") {
            if has("large", "big") { return .secret(.large) }
            if has("medium") { return .secret(.medium) }
            if has("small") { return .secret(.small) }
            return .secret(.unknown)
        }
        if has("road", "any road"), let n = tokens.compactMap(asInt).first, (1...4).contains(n) {
            return .anyRoad(n)
        }
        if has("level", "dungeon"), let n = tokens.compactMap(asInt).first, (1...9).contains(n) {
            return .dungeon(n)
        }
        // Singles — "shop" optional where the word is unambiguous.
        if has("armos", "armas", "armoss", "almos", "amos") { return .armos }
        if has("letter") { return .theLetter }
        if has("bomb") { return .shop(.bomb) }  // "bomb" → bomb shop
        if has("arrow") { return .shop(.arrow) }
        if has("candle") { return .shop(.candle) }
        if has("book") { return .shop(.book) }
        if has("meat", "food", "bait", "meet") { return .shop(.meat) }
        if has("potion") { return .potionShop }
        if has("ring", "blue") { return .shop(.blueRing) }
        if has("shield") { return .shop(.shield) }
        if has("hint") { return .hintShop }
        if has("door") { return .doorRepair }
        if has("money", "gamble", "gambling", "making game") { return .moneyMakingGame }
        if has("don t care", "dark", "dontcare", "ignore") { return .dontCare }
        if has("nothing", "clear", "empty", "erase") { return .unmarked }
        return nil
    }

    /// Phrases to bias the recognizer toward (`contextualStrings`).
    public static let contextualVocabulary: [String] = [
        "bomb shop", "arrow shop", "candle shop", "book shop", "blue ring shop",
        "meat shop", "key shop", "shield shop", "potion shop", "hint shop",
        "armos", "the letter", "door repair", "take any", "money making game",
        "any road", "wood sword", "white sword", "magical sword",
        "large secret", "medium secret", "small secret", "don't care", "nothing",
        "level", "dungeon", "enter level", "up", "down", "left", "right",
        "set start", "clear start", "go to start", "overworld", "leave dungeon",
        "ten", "eleven", "twelve", "thirteen", "fourteen", "fifteen", "sixteen",
        // NATO rows — cleaner than single letters.
        "alpha", "bravo", "charlie", "delta", "echo", "foxtrot", "golf", "hotel",
    ]
}
