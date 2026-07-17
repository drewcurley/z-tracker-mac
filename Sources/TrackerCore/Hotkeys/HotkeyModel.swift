import Foundation

/// The seven hotkey contexts (docs/domain.md § 4.11) — which region the mouse is
/// over decides what a key does. Ported from `HotKeys.fs`. Keys are unique *within*
/// a context; the same key may be reused across different contexts. **Global** keys
/// must additionally be unique across every non-contextual context.
public enum HotkeyContext: String, CaseIterable, Sendable, Codable {
    case items, overworld, blockers, dungeonRoom, hintZones, contextual, global

    public var displayName: String {
        switch self {
        case .items: "Items — hovering an item box"
        case .overworld: "Overworld — hovering a map tile"
        case .blockers: "Blockers — hovering a blocker box"
        case .dungeonRoom: "Dungeon rooms — hovering a room"
        case .hintZones: "Hint zones — hovering a hint-zone box"
        case .contextual: "Contextual menus (Take-Any / Take-This)"
        case .global: "Global — anywhere"
        }
    }

    /// Contextual keys only apply while their menu is on-screen, so they're exempt
    /// from the Global cross-context uniqueness rule.
    public var isContextual: Bool { self == .contextual }

    /// Editor display order — **Global first** (its keys must stay unique across
    /// every other non-contextual context, so they're surfaced up top where they
    /// won't be accidentally displaced), contextual last.
    public static let editorOrder: [HotkeyContext] =
        [.global, .items, .overworld, .blockers, .dungeonRoom, .hintZones, .contextual]
}

/// One bindable action within a context. `id` is the exact `HotKeys.txt` selector
/// name (e.g. `Overworld_Level1`) so files round-trip; `displayName` is the friendly
/// label shown in the editor.
public struct HotkeySelector: Identifiable, Equatable, Sendable {
    public let id: String
    public let context: HotkeyContext
    public let displayName: String
    public init(_ id: String, _ context: HotkeyContext, _ displayName: String) {
        self.id = id; self.context = context; self.displayName = displayName
    }
}

/// A key + optional modifier bound to a selector. Mirrors the `HotKeys.txt` value
/// grammar: an optional `SHIFT`/`CTRL`/`ALT` prefix, then either a printable key
/// (`0-9`, `a-z`) or `\nnn` for a raw key code.
public struct HotkeyChord: Equatable, Hashable, Sendable {
    public enum Modifier: String, CaseIterable, Sendable {
        case none = "", shift = "SHIFT", control = "CTRL", option = "ALT"
        public var symbol: String {
            switch self { case .none: ""; case .shift: "⇧"; case .control: "⌃"; case .option: "⌥" }
        }
    }
    public var modifier: Modifier
    /// The key token: a single lowercased printable char (`"a"`, `"5"`) or a raw
    /// code (`"\\75"`). Lowercased so `a` and `A` (without a modifier) are one key.
    public var key: String

    public init(modifier: Modifier = .none, key: String) {
        self.modifier = modifier
        self.key = key
    }

    /// The `HotKeys.txt` value form, e.g. `"SHIFT 4"`, `"a"`, `"\75"`.
    public var fileToken: String {
        modifier == .none ? key : "\(modifier.rawValue) \(key)"
    }

    /// A friendly label for the editor, e.g. `"⇧ 4"`, `"A"`, `"\75"`.
    public var displayName: String {
        let k = key.hasPrefix("\\") ? key : key.uppercased()
        return modifier == .none ? k : "\(modifier.symbol) \(k)"
    }
}

/// The canonical, ordered catalog of every bindable selector — transcribed from the
/// reference `HotKeys.txt` (v1.3.1) so import/export is byte-faithful. Grouped by
/// context in the order the editor lists them.
public enum HotkeyCatalog {
    public static let all: [HotkeySelector] = items + overworld + blockers
        + dungeonRoom + hintZones + contextual + global

    /// Selectors for one context, in catalog order.
    public static func selectors(in context: HotkeyContext) -> [HotkeySelector] {
        all.filter { $0.context == context }
    }

    /// Look up a selector by its `HotKeys.txt` id.
    public static func selector(id: String) -> HotkeySelector? {
        byID[id]
    }
    private static let byID: [String: HotkeySelector] =
        Dictionary(uniqueKeysWithValues: all.map { ($0.id, $0) })

    // MARK: Catalog data (exact ids from HotKeys.txt) ------------------------------

    private static func rows(_ ctx: HotkeyContext, _ prefix: String,
                             _ pairs: [(String, String)]) -> [HotkeySelector] {
        pairs.map { HotkeySelector(prefix + $0.0, ctx, $0.1) }
    }

    private static let items = rows(.items, "Item_", [
        ("BookOrShield", "Book / Shield"), ("Boomerang", "Boomerang"), ("Bow", "Bow"),
        ("PowerBracelet", "Power Bracelet"), ("Ladder", "Ladder"),
        ("MagicBoomerang", "Magic Boomerang"), ("AnyKey", "Any Key"), ("Raft", "Raft"),
        ("Recorder", "Recorder"), ("RedCandle", "Red Candle"), ("RedRing", "Red Ring"),
        ("SilverArrow", "Silver Arrow"), ("Wand", "Wand"), ("WhiteSword", "White Sword"),
        ("HeartContainer", "Heart Container"), ("Nothing", "Nothing (clear)"),
    ])

    private static let overworld = rows(.overworld, "Overworld_", [
        ("Level1", "Level 1"), ("Level2", "Level 2"), ("Level3", "Level 3"),
        ("Level4", "Level 4"), ("Level5", "Level 5"), ("Level6", "Level 6"),
        ("Level7", "Level 7"), ("Level8", "Level 8"), ("Level9", "Level 9"),
        ("AnyRoad1", "Any Road 1"), ("AnyRoad2", "Any Road 2"), ("AnyRoad3", "Any Road 3"),
        ("AnyRoad4", "Any Road 4"), ("Sword3", "Magical Sword cave"),
        ("Sword2", "White Sword cave"), ("Sword1", "Wood Sword cave"),
        ("ArrowShop", "Arrow shop"), ("BombShop", "Bomb shop"), ("BookShop", "Book shop"),
        ("CandleShop", "Candle shop"), ("BlueRingShop", "Blue Ring shop"),
        ("MeatShop", "Meat shop"), ("KeyShop", "Key shop"), ("ShieldShop", "Shield shop"),
        ("UnknownSecret", "Unknown secret"), ("LargeSecret", "Large secret"),
        ("MediumSecret", "Medium secret"), ("SmallSecret", "Small secret"),
        ("DoorRepairCharge", "Door repair"), ("MoneyMakingGame", "Money-making game"),
        ("Letter", "The letter"), ("Armos", "Armos"), ("HintShop", "Hint shop"),
        ("TakeAny", "Take-any"), ("PotionShop", "Potion shop"),
        ("DarkX", "Dark X (nothing)"), ("Nothing", "Nothing (clear)"),
    ])

    private static let blockers = rows(.blockers, "Blocker_", [
        ("Bow_And_Arrow", "Bow & arrow"), ("Recorder", "Recorder"), ("Ladder", "Ladder"),
        ("Key", "Key"), ("Bait", "Bait"), ("Money", "Money"), ("Bomb", "Bomb"),
        ("Combat", "Combat"),
        ("Maybe_Bow_And_Arrow", "Maybe bow & arrow"), ("Maybe_Recorder", "Maybe recorder"),
        ("Maybe_Ladder", "Maybe ladder"), ("Maybe_Key", "Maybe key"),
        ("Maybe_Bait", "Maybe bait"), ("Maybe_Money", "Maybe money"),
        ("Maybe_Bomb", "Maybe bomb"), ("Nothing", "Nothing (clear)"),
    ])

    private static let dungeonRoom: [HotkeySelector] =
        rows(.dungeonRoom, "DungeonRoom_RoomType_", [
            ("NonDescript", "Non-descript"), ("MaybePushBlock", "Maybe push block"),
            ("ItemBasement", "Item basement"), ("StaircaseToUnknown", "Staircase to unknown"),
            ("Transport1", "Transport 1"), ("Transport2", "Transport 2"),
            ("Transport3", "Transport 3"), ("Transport4", "Transport 4"),
            ("Transport5", "Transport 5"), ("Transport6", "Transport 6"),
            ("Transport7", "Transport 7"), ("Transport8", "Transport 8"),
            ("Chevy", "Chevy"), ("DoubleMoat", "Double moat"), ("TopMoat", "Top moat"),
            ("RightMoat", "Right moat"), ("CircleMoat", "Circle moat"), ("Tee", "Tee"),
            ("LavaMoat", "Lava moat"), ("VChute", "V chute"), ("HChute", "H chute"),
            ("Turnstile", "Turnstile"), ("OldManHint", "Old-man hint"),
            ("BombUpgrade", "Bomb upgrade"), ("LifeOrMoney", "Life or money"),
            ("HungryGoriyaMeatBlock", "Hungry Goriya (meat block)"),
            ("StartEnterFromE", "Start (enter from E)"), ("StartEnterFromW", "Start (enter from W)"),
            ("StartEnterFromN", "Start (enter from N)"), ("StartEnterFromS", "Start (enter from S)"),
            ("OffTheMap", "Off the map"), ("Gannon", "Ganon"), ("Zelda", "Zelda"),
            ("Unmarked", "Unmarked (clear)"),
        ])
        + rows(.dungeonRoom, "DungeonRoom_MonsterDetail_", [
            ("Gleeok", "Gleeok"), ("Bow", "Gohma"), ("Digdogger", "Digdogger"),
            ("Dodongo", "Dodongo"), ("Patra", "Patra"), ("Manhandla", "Manhandla"),
            ("Aquamentus", "Aquamentus"), ("Moldorm", "Moldorm"), ("BlueLanmola", "Lanmola"),
            ("BlueWizzrobe", "Wizzrobe"), ("BlueDarknut", "Darknut"), ("RedLynel", "Lynel"),
            ("PolsVoice", "Pols Voice"), ("RedGoriya", "Goriya"), ("Gibdo", "Gibdo"),
            ("Rope", "Rope"), ("Vire", "Vire"), ("Keese", "Keese"), ("Zol", "Zol"),
            ("Gel", "Gel"), ("Stalfos", "Stalfos"), ("Wallmaster", "Wallmaster"),
            ("Likelike", "Likelike"), ("BlueMoblin", "Moblin"), ("Other", "Other"),
            ("Other2", "Other 2"), ("Traps", "Traps"), ("RedTektite", "Tektite"),
            ("BlueBubble", "Blue Bubble"), ("RedBubble", "Red Bubble"),
            ("RupeeBoss", "Rupee Boss"), ("Unmarked", "Unmarked (clear)"),
        ])
        + rows(.dungeonRoom, "DungeonRoom_FloorDropDetail_", [
            ("Triforce", "Triforce"), ("Heart", "Heart"), ("OtherKeyItem", "Other key item"),
            ("BombPack", "Bomb pack"), ("Key", "Key"), ("FiveRupee", "Five rupee"),
            ("Map", "Map"), ("Compass", "Compass"), ("Unmarked", "Unmarked (clear)"),
        ])
        + rows(.dungeonRoom, "DungeonRoom_", [
            ("WestDoorIncrement", "West door +"), ("WestDoorDecrement", "West door −"),
            ("EastDoorIncrement", "East door +"), ("EastDoorDecrement", "East door −"),
            ("NorthDoorIncrement", "North door +"), ("NorthDoorDecrement", "North door −"),
            ("SouthDoorIncrement", "South door +"), ("SouthDoorDecrement", "South door −"),
        ])

    private static let hintZones = rows(.hintZones, "HintZone_", [
        ("Unknown", "Unknown"), ("DeathMountain", "Death Mountain"), ("Lake", "Lake"),
        ("LostHills", "Lost Hills"), ("River", "River"), ("Grave", "Grave"),
        ("Desert", "Desert"), ("Coast", "Coast"), ("DeadWoods", "Dead Woods"),
        ("CloseToStart", "Close to start"), ("Forest", "Forest"),
    ])

    private static let contextual = rows(.contextual, "Contextual_", [
        ("TakeAny_None", "Take-Any: none"), ("TakeAny_Potion", "Take-Any: potion"),
        ("TakeAny_Candle", "Take-Any: candle"), ("TakeAny_Heart", "Take-Any: heart"),
        ("TakeThis_None", "Take-This: none"), ("TakeThis_Candle", "Take-This: candle"),
        ("TakeThis_Sword", "Take-This: sword"),
    ])

    private static let global = rows(.global, "Global_", [
        ("ToggleMagicalSword", "Toggle magical sword"), ("ToggleWoodSword", "Toggle wood sword"),
        ("ToggleBoomBook", "Toggle boomstick book"), ("ToggleBlueCandle", "Toggle blue candle"),
        ("ToggleWoodArrow", "Toggle wood arrow"), ("ToggleBlueRing", "Toggle blue ring"),
        ("ToggleBombs", "Toggle bombs"), ("ToggleGannon", "Toggle Ganon"),
        ("ToggleZelda", "Toggle Zelda"),
        ("DungeonTab1", "Dungeon tab 1"), ("DungeonTab2", "Dungeon tab 2"),
        ("DungeonTab3", "Dungeon tab 3"), ("DungeonTab4", "Dungeon tab 4"),
        ("DungeonTab5", "Dungeon tab 5"), ("DungeonTab6", "Dungeon tab 6"),
        ("DungeonTab7", "Dungeon tab 7"), ("DungeonTab8", "Dungeon tab 8"),
        ("DungeonTab9", "Dungeon tab 9"), ("DungeonTabS", "Dungeon tab Summary"),
        ("MoveCursorLeft", "Move cursor left"), ("MoveCursorRight", "Move cursor right"),
        ("MoveCursorUp", "Move cursor up"), ("MoveCursorDown", "Move cursor down"),
        ("ToggleCursorOverworldOrDungeon", "Toggle cursor: overworld / dungeon"),
        ("LeftClick", "Left click"), ("MiddleClick", "Middle click"),
        ("RightClick", "Right click"), ("ScrollUp", "Scroll up"), ("ScrollDown", "Scroll down"),
        // Beyond the Windows app (T-131, user request) — these ids won't round-trip
        // into the reference tracker, which is expected (Mac-only actions).
        ("StartTimer", "Start timer"),
        ("GroundhogReset", "Groundhog reset (skip confirmation)"),
    ])
}
