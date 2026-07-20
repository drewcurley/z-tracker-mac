/// The per-room enums for the dungeon room-map grid (T-019.3), ported verbatim
/// from `Z1R_WPF/DungeonRoomState.fs`. Case names match the reference (camelCased)
/// so the save hot-key tokens derive exactly (`RoomType_Bow` etc.) for the future
/// save format. Display strings are the reference's `DisplayDescription`.

/// Turns a camelCased case name into the reference's PascalCase hot-key token,
/// e.g. `("RoomType", "startEnterFromE")` → `"RoomType_StartEnterFromE"`.
private func hotKeyToken(_ prefix: String, _ caseName: String) -> String {
    prefix + "_" + caseName.prefix(1).uppercased() + caseName.dropFirst()
}

/// What kind of room this is (`RoomType`, `DungeonRoomState.fs:230-272`).
public enum RoomType: CaseIterable, Sendable, Equatable, Codable {
    case unmarked
    case nonDescript
    // staircase family
    case maybePushBlock, itemBasement, staircaseToUnknown
    case transport1, transport2, transport3, transport4
    case transport5, transport6, transport7, transport8
    // moats
    case chevy, doubleMoat, topMoat, rightMoat, circleMoat
    // other geometry
    case tee, lavaMoat, vChute, hChute, turnstile
    // NPCs
    case oldManHint, bombUpgrade, lifeOrMoney, hungryGoriyaMeatBlock
    // entrances
    case startEnterFromE, startEnterFromW, startEnterFromN, startEnterFromS
    case offTheMap
    // level-9 only
    case gannon, zelda

    public var isNotMarked: Bool { self == .unmarked }
    public var isOffMap: Bool { self == .offTheMap }

    /// An "old man" NPC room — feeds the Old-Man count (`IsOldMan`).
    public var isOldMan: Bool {
        self == .oldManHint || self == .bombUpgrade
            || self == .hungryGoriyaMeatBlock || self == .lifeOrMoney
    }

    /// Whether this room is a dungeon entrance (a `startEnterFrom*`). Used by voice's
    /// contextual "restart" → jump to the entrance (T-138).
    public var isEntrance: Bool {
        switch self {
        case .startEnterFromE, .startEnterFromW, .startEnterFromN, .startEnterFromS: true
        default: false
        }
    }

    /// The next entrance direction on click (`NextEntranceRoom`): S→W→N→E→S.
    /// `nil` for non-entrance rooms.
    public var nextEntranceRoom: RoomType? {
        switch self {
        case .startEnterFromS: .startEnterFromW
        case .startEnterFromW: .startEnterFromN
        case .startEnterFromN: .startEnterFromE
        case .startEnterFromE: .startEnterFromS
        default: nil
        }
    }

    /// `1…8` for a transport-stair room, else `nil` (`KnownTransportNumber`).
    public var transportNumber: Int? {
        switch self {
        case .transport1: 1
        case .transport2: 2
        case .transport3: 3
        case .transport4: 4
        case .transport5: 5
        case .transport6: 6
        case .transport7: 7
        case .transport8: 8
        default: nil
        }
    }

    public var hotKeyName: String { hotKeyToken("RoomType", String(describing: self)) }
    public static func fromHotKeyName(_ name: String) -> RoomType {
        allCases.first { $0.hotKeyName == name } ?? .unmarked
    }

    public var displayDescription: String {
        switch self {
        case .unmarked: "(Unmarked)"
        case .nonDescript: "Empty/non-descript room"
        case .maybePushBlock: "Room which might have a staircase"
        case .itemBasement: "Room with staircase to a basement item"
        case .staircaseToUnknown: "Room with staircase (unknown destination)"
        case .transport1: "Transport staircase #1 (one of matched pair)"
        case .transport2: "Transport staircase #2 (one of matched pair)"
        case .transport3: "Transport staircase #3 (one of matched pair)"
        case .transport4: "Transport staircase #4 (one of matched pair)"
        case .transport5: "Transport staircase #5 (one of matched pair)"
        case .transport6: "Transport staircase #6 (one of matched pair)"
        case .transport7: "Transport staircase #7 (one of matched pair)"
        case .transport8: "Transport staircase #8 (one of matched pair)"
        case .chevy: "Chevy (four-way moat-ladder-block)"
        case .doubleMoat: "Double moat"
        case .topMoat: "North moat"
        case .rightMoat: "East moat"
        case .circleMoat: "Circle moat"
        case .tee: "Tee (moat isolating south exit)"
        case .lavaMoat: "Lava moat (weird shaped moat)"
        case .vChute: "Vertical chute"
        case .hChute: "Horizontal chute"
        case .turnstile: "Turnstile"
        case .oldManHint: "NPC with hint"
        case .bombUpgrade: "Bomb Upgrade (75-125 rupees)"
        case .lifeOrMoney: "Life or Money (pay to escape) room"
        case .hungryGoriyaMeatBlock: "Hungry Goriya (meat block)"
        case .startEnterFromE: "Dungeon entrance (from east)"
        case .startEnterFromW: "Dungeon entrance (from west)"
        case .startEnterFromN: "Dungeon entrance (from north)"
        case .startEnterFromS: "Dungeon entrance (from south)"
        case .offTheMap: "(Off the map)"
        case .gannon: "Gannon"
        case .zelda: "Zelda"
        }
    }
}

/// The monster marked in a room (`MonsterDetail`, `DungeonRoomState.fs:26-59`).
/// Note the internal case `bow` displays as **"Gohma"** (the bow-blocker boss).
public enum MonsterDetail: CaseIterable, Sendable, Equatable, Codable {
    case unmarked
    case gleeok, bow, digdogger, blueBubble, redBubble, dodongo, patra
    case blueWizzrobe, blueDarknut, manhandla, vire, zol, polsVoice, redTektite
    case redGoriya, rope, stalfos, wallmaster, gel, keese, likelike, gibdo
    case redLynel, blueMoblin, aquamentus, blueLanmola, moldorm, rupeeBoss
    case traps, other, other2

    public var isNotMarked: Bool { self == .unmarked }

    public var hotKeyName: String { hotKeyToken("MonsterDetail", String(describing: self)) }
    public static func fromHotKeyName(_ name: String) -> MonsterDetail {
        allCases.first { $0.hotKeyName == name } ?? .unmarked
    }

    /// The reduced set of enemies offered for **overworld** tile annotation
    /// (T-117, user request): wizrobes, darknuts, lynels, pols voice, goriyas,
    /// gibdos, ropes, stalfos, tektites, moblins.
    public static let overworldEnemies: [MonsterDetail] = [
        .blueWizzrobe, .blueDarknut, .redLynel, .polsVoice, .redGoriya,
        .gibdo, .rope, .stalfos, .redTektite, .blueMoblin,
    ]

    /// Toggle `m` into a normalized up-to-two monster pair (T-116/T-117), shared
    /// by dungeon rooms and overworld tiles: `unmarked` clears both; a present
    /// monster is removed (secondary promotes); a new monster fills the empty slot,
    /// or replaces the secondary when both are full.
    public static func togglingPair(_ m: MonsterDetail,
                                    in pair: (MonsterDetail, MonsterDetail)) -> (MonsterDetail, MonsterDetail) {
        let (a, b) = pair
        if m.isNotMarked { return (.unmarked, .unmarked) }
        if m == a { return (b, .unmarked) }
        if m == b { return (a, .unmarked) }
        if a.isNotMarked { return (m, .unmarked) }
        if b.isNotMarked { return (a, m) }
        return (a, m)
    }

    public var displayName: String {
        switch self {
        case .unmarked: "(None)"
        case .gleeok: "Gleeok"
        case .bow: "Gohma"
        case .digdogger: "Digdogger"
        case .blueBubble: "Blue Bubble"
        case .redBubble: "Red Bubble"
        case .dodongo: "Dodongo"
        case .patra: "Patra"
        case .blueWizzrobe: "Wizzrobe"
        case .blueDarknut: "Darknut"
        case .manhandla: "Manhandla"
        case .vire: "Vire"
        case .zol: "Zol"
        case .polsVoice: "Pols Voice"
        case .redTektite: "Tektite"
        case .redGoriya: "Goriya"
        case .rope: "Rope"
        case .stalfos: "Stalfos"
        case .wallmaster: "Wallmaster"
        case .gel: "Gel"
        case .keese: "Keese"
        case .likelike: "Likelike"
        case .gibdo: "Gibdo"
        case .redLynel: "Lynel"
        case .blueMoblin: "Moblin"
        case .aquamentus: "Aquamentus"
        case .blueLanmola: "Lanmola"
        case .moldorm: "Moldorm"
        case .rupeeBoss: "Rupee Boss"
        case .traps: "Traps"
        case .other: "Other"
        case .other2: "Other2"
        }
    }
}

/// The floor/standing item in a room (`FloorDropDetail`, `DungeonRoomState.fs:175-197`).
public enum FloorDropDetail: CaseIterable, Sendable, Equatable, Codable {
    case unmarked, triforce, heart, otherKeyItem, bombPack, key, fiveRupee, map, compass

    public var isNotMarked: Bool { self == .unmarked }

    public var hotKeyName: String { hotKeyToken("FloorDropDetail", String(describing: self)) }
    public static func fromHotKeyName(_ name: String) -> FloorDropDetail {
        allCases.first { $0.hotKeyName == name } ?? .unmarked
    }

    public var displayName: String {
        switch self {
        case .unmarked: "(None)"
        case .triforce: "Triforce"
        case .heart: "Heart Container"
        case .otherKeyItem: "Other Key Item"
        case .bombPack: "Bomb Pack"
        case .key: "Key (single use)"
        case .fiveRupee: "Five-Rupee"
        case .map: "Map"
        case .compass: "Compass"
        }
    }
}
