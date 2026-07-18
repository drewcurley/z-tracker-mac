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
    case toggleProgression(id: String)                    // "took wood sword" (item acquired)
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

        // Player-progress toggles (T-142) need an action word ("took / got / bought…"),
        // so a bare "meat" still marks the meat shop while "took meat" flags the item.
        // Checked before region/structural so the action word wins the disambiguation.
        if let id = progressionToggle(words, config: config) {
            return .toggleProgression(id: id)
        }

        // Region actions win over structural, so a door command like "open left" isn't
        // swallowed by "left" (a cursor move). Execution resolves the words per-region
        // ("set level" beats "level" inside `match` via longest-phrase-wins).
        if config.match(words, scope: .region) != nil {
            if let coord {
                return .actionAt(column: coord.coord.column, row: coord.coord.row, words: words)
            }
            return .actionAtCursor(words: words)
        }
        // Otherwise a structural action (cursor / nav / dungeon tab).
        if let m = config.match(words, scope: .structural), let cmd = structuralCommand(m) {
            return cmd
        }
        // A coordinate alone → just move the cursor.
        if let coord, coord.rest.isEmpty {
            return .cursorTo(column: coord.coord.column, row: coord.coord.row)
        }
        return nil
    }

    // MARK: Progression toggles (T-142)

    /// Words that signal "I acquired this" — the disambiguator that turns a bare
    /// shop/cave word into a progression toggle. Grammar constants (like the NATO
    /// letters and number words), not user-editable phrases.
    static let actionWords: Set<String> = [
        "took", "take", "taking", "got", "get", "getting", "have", "has", "had",
        "grab", "grabbed", "grabbing", "bought", "buy", "buying", "purchase", "purchased",
        "acquired", "acquire", "obtained", "obtain", "found", "toggle",
        // Ganon / Zelda verbs.
        "killed", "kill", "defeated", "defeat", "beat", "rescued", "rescue", "saved", "save",
    ]

    /// The progression toggles the player can flag from **anywhere** (not scoped to the
    /// overworld): bombs (a near-gimme, droppable in dungeons) and the end-game
    /// Ganon/Zelda states. The rest are overworld-acquired, so execution scopes them.
    public static let globalProgressionIDs: Set<String> = ["Prog_Bomb", "Prog_Ganon", "Prog_Zelda"]
    public static func isGlobalProgression(_ id: String) -> Bool { globalProgressionIDs.contains(id) }

    /// The progression-item action id for spoken words, but **only** when an action word
    /// is present ("took wood sword"); returns nil otherwise so a bare "wood sword"
    /// stays a cave mark.
    static func progressionToggle(_ words: [String], config: VoiceConfig) -> String? {
        guard words.contains(where: { actionWords.contains($0) }) else { return nil }
        return config.match(words, scope: .progression)?.actionID
    }

    // MARK: Dungeon region resolution

    public enum VoiceDirection: Equatable, Sendable { case north, south, east, west }

    public enum DungeonAction: Equatable, Sendable {
        case roomType(RoomType)
        case monster(MonsterDetail)
        case floorDrop(FloorDropDetail)
        case door(DoorState, VoiceDirection)
        case entrance(VoiceDirection)
    }

    /// Resolve action words for the **dungeon** region. Returns an array to support
    /// compound door commands ("open west shutter east key north" → three doors).
    public static func dungeonActions(_ words: [String], config: VoiceConfig) -> [DungeonAction] {
        // 1) Doors — one or more "<state> <direction>" pairs.
        var doorPairs: [DungeonAction] = []
        var i = 0
        while i < words.count {
            if let state = doorState(words[i], config: config),
               i + 1 < words.count, let dir = direction(words[i + 1]) {
                doorPairs.append(.door(state, dir)); i += 2
            } else { i += 1 }
        }
        if !doorPairs.isEmpty { return doorPairs }

        // 2) Entrance — "<entrance word> <direction>".
        let entrancePhrases = Set(config.phrases(for: "Entrance"))
        for (idx, w) in words.enumerated() where entrancePhrases.contains(w) {
            if idx + 1 < words.count, let dir = direction(words[idx + 1]) { return [.entrance(dir)] }
        }

        // 3) A single room / monster / floor-drop.
        if let m = config.match(words, scope: .dungeon), let a = dungeonMeaning(m) { return [a] }
        return []
    }

    /// The door state a single word names (via the editable Door_* phrases).
    static func doorState(_ token: String, config: VoiceConfig) -> DoorState? {
        for (id, state): (String, DoorState) in [
            ("Door_Open", .yes), ("Door_Blocked", .no), ("Door_Key", .yellow),
            ("Door_Shutter", .purple), ("Door_None", .unknown),
        ] where config.phrases(for: id).contains(token) {
            return state
        }
        return nil
    }

    static func direction(_ token: String) -> VoiceDirection? {
        switch token {
        case "left", "west": .west
        case "right", "east": .east
        case "up", "north": .north
        case "down", "south": .south
        default: nil
        }
    }

    /// Resolve action words for the **overworld** region via the config.
    public static func overworldAction(_ words: [String], config: VoiceConfig) -> OverworldAction? {
        guard let m = config.match(words, scope: .region) else { return nil }
        return overworldMeaning(m)
    }

    /// All phrases + the structural vocabulary, to bias the recognizer.
    public static func contextualVocabulary(_ config: VoiceConfig) -> [String] {
        config.allPhrases + Array(actionWords) + [
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

    private static func dungeonMeaning(_ m: (actionID: String, number: Int?)) -> DungeonAction? {
        switch m.actionID {
        // Room types
        case "Room_NonDescript":   return .roomType(.nonDescript)
        case "Room_ItemBasement":  return .roomType(.itemBasement)
        case "Room_Staircase":     return .roomType(.staircaseToUnknown)
        case "Room_MaybePush":     return .roomType(.maybePushBlock)
        case "Room_Transport":
            switch m.number {
            case 1: return .roomType(.transport1); case 2: return .roomType(.transport2)
            case 3: return .roomType(.transport3); case 4: return .roomType(.transport4)
            case 5: return .roomType(.transport5); case 6: return .roomType(.transport6)
            case 7: return .roomType(.transport7); case 8: return .roomType(.transport8)
            default: return .roomType(.transport1)
            }
        case "Room_Chevy":         return .roomType(.chevy)
        case "Room_DoubleMoat":    return .roomType(.doubleMoat)
        case "Room_TopMoat":       return .roomType(.topMoat)
        case "Room_RightMoat":     return .roomType(.rightMoat)
        case "Room_CircleMoat":    return .roomType(.circleMoat)
        case "Room_Tee":           return .roomType(.tee)
        case "Room_LavaMoat":      return .roomType(.lavaMoat)
        case "Room_VChute":        return .roomType(.vChute)
        case "Room_HChute":        return .roomType(.hChute)
        case "Room_Turnstile":     return .roomType(.turnstile)
        case "Room_OldMan":        return .roomType(.oldManHint)
        case "Room_BombUpgrade":   return .roomType(.bombUpgrade)
        case "Room_LifeOrMoney":   return .roomType(.lifeOrMoney)
        case "Room_HungryGoriya":  return .roomType(.hungryGoriyaMeatBlock)
        case "Room_OffTheMap":     return .roomType(.offTheMap)
        case "Room_Gannon":        return .roomType(.gannon)
        case "Room_Zelda":         return .roomType(.zelda)
        case "Room_Unmarked":      return .roomType(.unmarked)
        // Monsters
        case "Mon_Gleeok":     return .monster(.gleeok)
        case "Mon_Gohma":      return .monster(.bow)
        case "Mon_Digdogger":  return .monster(.digdogger)
        case "Mon_Dodongo":    return .monster(.dodongo)
        case "Mon_Patra":      return .monster(.patra)
        case "Mon_Manhandla":  return .monster(.manhandla)
        case "Mon_Aquamentus": return .monster(.aquamentus)
        case "Mon_Moldorm":    return .monster(.moldorm)
        case "Mon_Lanmola":    return .monster(.blueLanmola)
        case "Mon_Wizzrobe":   return .monster(.blueWizzrobe)
        case "Mon_Darknut":    return .monster(.blueDarknut)
        case "Mon_Lynel":      return .monster(.redLynel)
        case "Mon_PolsVoice":  return .monster(.polsVoice)
        case "Mon_Goriya":     return .monster(.redGoriya)
        case "Mon_Gibdo":      return .monster(.gibdo)
        case "Mon_Rope":       return .monster(.rope)
        case "Mon_Vire":       return .monster(.vire)
        case "Mon_Keese":      return .monster(.keese)
        case "Mon_Zol":        return .monster(.zol)
        case "Mon_Gel":        return .monster(.gel)
        case "Mon_Stalfos":    return .monster(.stalfos)
        case "Mon_Wallmaster": return .monster(.wallmaster)
        case "Mon_Likelike":   return .monster(.likelike)
        case "Mon_Moblin":     return .monster(.blueMoblin)
        case "Mon_Tektite":    return .monster(.redTektite)
        case "Mon_BlueBubble": return .monster(.blueBubble)
        case "Mon_RedBubble":  return .monster(.redBubble)
        case "Mon_Traps":      return .monster(.traps)
        case "Mon_RupeeBoss":  return .monster(.rupeeBoss)
        // Floor drops
        case "Drop_Triforce":     return .floorDrop(.triforce)
        case "Drop_Heart":        return .floorDrop(.heart)
        case "Drop_OtherKeyItem": return .floorDrop(.otherKeyItem)
        case "Drop_BombPack":     return .floorDrop(.bombPack)
        case "Drop_Key":          return .floorDrop(.key)
        case "Drop_FiveRupee":    return .floorDrop(.fiveRupee)
        case "Drop_Map":          return .floorDrop(.map)
        case "Drop_Compass":      return .floorDrop(.compass)
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
