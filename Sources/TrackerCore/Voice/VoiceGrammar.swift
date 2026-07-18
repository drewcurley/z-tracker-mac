import Foundation

/// A parsed voice command (T-137/T-138). Voice drives the **keyboard cursor**: a
/// coordinate moves the cursor (in whatever region is active), an action applies at
/// the cursor cell, and the two combine. Execution (region-aware) lives in the app.
public enum VoiceCommand: Equatable, Sendable {
    case moveCursor(dcol: Int, drow: Int)                 // "up" / "down"
    case cursorTo(column: Int, row: Int)                  // "E7" (coordinate only)
    case actionAtCursor(words: [String])                  // "potion" (act at cursor)
    case actionAt(column: Int, row: Int, words: [String]) // "E7 bomb shop"
    case dungeonTab(Int)                                  // "enter level 5"
    case exitToOverworld                                  // "overworld" / "leave dungeon"
    case gotoStart                                        // "start" / "restart"
}

/// A resolved overworld action — the app calls it once it knows the cursor is on the
/// overworld region.
public enum OverworldAction: Equatable, Sendable {
    case mark(OverworldTileMark)
    case takeAny(TakeAnyHeartState)
    case setStart
    case clearStart
}

/// Parses a spoken phrase into a `VoiceCommand` using the user-editable `VoiceConfig`
/// (T-139): coordinates (A–H + numbers + NATO) are parsed **structurally**; the action
/// words are matched against the config's phrase lists. Action id → meaning stays here
/// in code; only the trigger phrases are user-editable.
public enum VoiceGrammar {
    public static func parse(_ raw: String, config: VoiceConfig) -> VoiceCommand? {
        let tokens = normalize(raw)
        guard !tokens.isEmpty else { return nil }
        let coord = coordinate(in: tokens)
        let words = coord?.rest ?? tokens

        // Match across ALL actions so the longest phrase wins regardless of scope
        // (so "set level" [region: mark] beats "level" [structural: enter tab]), then
        // branch on the winner's scope.
        if let m = config.match(words, scope: .any), let action = VoiceCatalog.action(id: m.actionID) {
            switch VoiceConfig.scope(of: action) {
            case .structural:
                if let cmd = structuralCommand(m) { return cmd }
            default:
                // A region action applies at the cursor cell (execution resolves it
                // per-region); with a coordinate, move there first.
                if let coord {
                    return .actionAt(column: coord.coord.column, row: coord.coord.row, words: words)
                }
                return .actionAtCursor(words: words)
            }
        }
        // A coordinate alone → just move the cursor.
        if let coord, coord.rest.isEmpty {
            return .cursorTo(column: coord.coord.column, row: coord.coord.row)
        }
        return nil
    }

    /// Resolve action words for the **overworld** region via the config.
    public static func overworldAction(_ words: [String], config: VoiceConfig) -> OverworldAction? {
        guard let m = config.match(words, scope: .region) else { return nil }
        return overworldMeaning(m)
    }

    /// All phrases + the structural vocabulary, to bias the recognizer.
    public static func contextualVocabulary(_ config: VoiceConfig) -> [String] {
        config.allPhrases + [
            "ten", "eleven", "twelve", "thirteen", "fourteen", "fifteen", "sixteen",
            "alpha", "bravo", "charlie", "delta", "echo", "foxtrot", "golf", "hotel",
        ]
    }

    // MARK: id → meaning (code, not user-editable)

    private static func structuralCommand(_ m: (actionID: String, number: Int?)) -> VoiceCommand? {
        switch m.actionID {
        case "Cursor_Up":     return .moveCursor(dcol: 0, drow: -1)
        case "Cursor_Down":   return .moveCursor(dcol: 0, drow: 1)
        case "Cursor_Left":   return .moveCursor(dcol: -1, drow: 0)
        case "Cursor_Right":  return .moveCursor(dcol: 1, drow: 0)
        case "Nav_Overworld": return .exitToOverworld
        case "Nav_Start":     return .gotoStart
        case "Dungeon_Enter":
            if let n = m.number, (1...9).contains(n) { return .dungeonTab(n) }
            return nil
        default: return nil
        }
    }

    private static func overworldMeaning(_ m: (actionID: String, number: Int?)) -> OverworldAction? {
        switch m.actionID {
        case "OW_BombShop":     return .mark(.shop(.bomb))
        case "OW_ArrowShop":    return .mark(.shop(.arrow))
        case "OW_CandleShop":   return .mark(.shop(.candle))
        case "OW_BookShop":     return .mark(.shop(.book))
        case "OW_BlueRingShop": return .mark(.shop(.blueRing))
        case "OW_MeatShop":     return .mark(.shop(.meat))
        case "OW_KeyShop":      return .mark(.shop(.key))
        case "OW_ShieldShop":   return .mark(.shop(.shield))
        case "OW_PotionShop":   return .mark(.potionShop)
        case "OW_HintShop":     return .mark(.hintShop)
        case "OW_Dungeon":
            if let n = m.number, (1...9).contains(n) { return .mark(.dungeon(n)) }
            return nil
        case "OW_AnyRoad":
            if let n = m.number, (1...4).contains(n) { return .mark(.anyRoad(n)) }
            return nil
        case "OW_SwordCave1": return .mark(.swordCave(1))
        case "OW_SwordCave2": return .mark(.swordCave(2))
        case "OW_SwordCave3": return .mark(.swordCave(3))
        case "OW_Armos":      return .mark(.armos)
        case "OW_Letter":     return .mark(.theLetter)
        case "OW_DoorRepair": return .mark(.doorRepair)
        case "OW_MoneyGame":  return .mark(.moneyMakingGame)
        case "OW_LargeSecret":  return .mark(.secret(.large))
        case "OW_MediumSecret": return .mark(.secret(.medium))
        case "OW_SmallSecret":  return .mark(.secret(.small))
        case "OW_DontCare":   return .mark(.dontCare)
        case "OW_Nothing":    return .mark(.unmarked)
        case "OW_SetStart":   return .setStart
        case "OW_ClearStart": return .clearStart
        case "TakeAny_None":   return .takeAny(.untaken)
        case "TakeAny_Potion": return .takeAny(.takenPotion)
        case "TakeAny_Candle": return .takeAny(.takenCandle)
        case "TakeAny_Heart":  return .takeAny(.takenHeart)
        default: return nil
        }
    }

    // MARK: Structural parsing (coordinates, numbers) — not user-editable

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
            if let prev = curIsDigit, prev != isDigit { parts.append(cur); cur = "" }
            cur.append(ch); curIsDigit = isDigit
        }
        if !cur.isEmpty { parts.append(cur) }
        return parts
    }

    private static let numberWords: [String: Int] = [
        "one": 1, "two": 2, "three": 3, "four": 4, "five": 5, "six": 6, "seven": 7,
        "eight": 8, "nine": 9, "ten": 10, "eleven": 11, "twelve": 12, "thirteen": 13,
        "fourteen": 14, "fifteen": 15, "sixteen": 16,
    ]

    /// NATO phonetic for row letters A–H (index 0–7) — cleaner than single letters,
    /// which speech-to-text mangles ("E" → "east").
    private static let natoRows: [String: Int] = [
        "alpha": 0, "bravo": 1, "charlie": 2, "delta": 3,
        "echo": 4, "foxtrot": 5, "golf": 6, "hotel": 7,
    ]

    static func asInt(_ token: String) -> Int? { Int(token) ?? numberWords[token] }

    static func rowLetter(_ token: String) -> Int? {
        if token.count == 1, let c = token.first, ("a"..."h").contains(c) {
            return Int(c.asciiValue! - Character("a").asciiValue!)
        }
        return natoRows[token]
    }

    /// The first row-letter immediately followed by a number (1–16). Returns the
    /// 0-based (column, row) and the remaining tokens.
    static func coordinate(in tokens: [String]) -> (coord: (column: Int, row: Int), rest: [String])? {
        for i in 0..<tokens.count {
            guard let row = rowLetter(tokens[i]),
                  i + 1 < tokens.count, let num = asInt(tokens[i + 1]), (1...16).contains(num)
            else { continue }
            let rest = Array(tokens[..<i] + tokens[(i + 2)...])
            return ((column: num - 1, row: row), rest)
        }
        return nil
    }
}
