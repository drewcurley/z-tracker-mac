import Foundation

/// The catalog of user-bindable **voice actions** (T-139) — the voice analogue of
/// `HotkeyCatalog`. Each action has an id, a display name, a category (for grouping in
/// the editor), and a **default phrase list** the user can extend/replace in
/// `VoiceConfig`. Coordinates (A–H + numbers + NATO) and the numeric argument of
/// parametric actions ("level **5**") are parsed structurally, not as phrases, so they
/// aren't in the catalog.
public struct VoiceAction: Identifiable, Equatable, Sendable {
    public let id: String
    public let displayName: String
    public let category: VoiceCategory
    /// True for actions that consume a spoken number ("level N", "any road N").
    public let takesNumber: Bool
    /// True for actions that consume a spoken direction ("open **left**", "entrance
    /// **south**").
    public let takesDirection: Bool
    public let defaultPhrases: [String]

    public init(_ id: String, _ displayName: String, _ category: VoiceCategory,
                takesNumber: Bool = false, takesDirection: Bool = false,
                _ defaultPhrases: [String]) {
        self.id = id; self.displayName = displayName; self.category = category
        self.takesNumber = takesNumber; self.takesDirection = takesDirection
        self.defaultPhrases = defaultPhrases
    }
}

public enum VoiceCategory: String, CaseIterable, Sendable, Codable {
    case cursor, navigation, dungeon, overworldShops, overworldMarks, takeAny
    case dungeonRooms, monsters, floorDrops, doors, entrances
    case progression, itemBoxes, items

    public var title: String {
        switch self {
        case .cursor: "Cursor"
        case .navigation: "Navigation"
        case .dungeon: "Dungeon"
        case .overworldShops: "Overworld — shops"
        case .overworldMarks: "Overworld — marks"
        case .takeAny: "Take-any"
        case .dungeonRooms: "Dungeon — room types"
        case .monsters: "Monsters"
        case .floorDrops: "Dungeon — floor drops"
        case .doors: "Dungeon — doors"
        case .entrances: "Dungeon — entrances"
        case .progression: "Items — acquired (say with \u{201C}took / got / bought\u{201D})"
        case .itemBoxes: "Item boxes (say box + item, e.g. \u{201C}coast ladder\u{201D})"
        case .items: "Items (for the item boxes)"
        }
    }
}

public enum VoiceCatalog {
    public static let all: [VoiceAction] =
        cursor + navigation + dungeon + overworldShops + overworldMarks + takeAny
        + dungeonRooms + monsters + floorDrops + doors + entrances + progression
        + itemBoxes + items

    public static func action(id: String) -> VoiceAction? { all.first { $0.id == id } }
    public static func actions(in category: VoiceCategory) -> [VoiceAction] {
        all.filter { $0.category == category }
    }
    /// Categories in editor order.
    public static let categoryOrder: [VoiceCategory] =
        [.cursor, .navigation, .dungeon, .doors, .entrances,
         .dungeonRooms, .monsters, .floorDrops, .overworldShops, .overworldMarks, .takeAny,
         .progression, .itemBoxes, .items]

    // MARK: Actions

    private static let cursor: [VoiceAction] = [
        VoiceAction("Cursor_Up", "Move up", .cursor, ["up"]),
        VoiceAction("Cursor_Down", "Move down", .cursor, ["down"]),
        VoiceAction("Cursor_Left", "Move left", .cursor, ["left"]),
        VoiceAction("Cursor_Right", "Move right", .cursor, ["right"]),
    ]

    private static let navigation: [VoiceAction] = [
        VoiceAction("Nav_Overworld", "Go to overworld", .navigation,
                    ["overworld", "over world", "leave dungeon", "exit dungeon"]),
        VoiceAction("Nav_Start", "Go to start / entrance", .navigation,
                    ["start", "restart", "home", "go to start"]),
        VoiceAction("Nav_StopVoice", "Stop listening", .navigation,
                    ["stop listening", "pause voice", "stop voice", "mute voice", "go to sleep", "stop recording"]),
    ]

    private static let dungeon: [VoiceAction] = [
        VoiceAction("Dungeon_Enter", "Enter level (switch tab)", .dungeon, takesNumber: true,
                    ["enter level", "go to level", "open level", "level", "dungeon"]),
    ]

    private static let overworldShops: [VoiceAction] = [
        VoiceAction("OW_BombShop", "Bomb shop", .overworldShops, ["bomb shop", "bomb", "bombs"]),
        VoiceAction("OW_ArrowShop", "Arrow shop", .overworldShops, ["arrow shop", "arrow"]),
        VoiceAction("OW_CandleShop", "Candle shop", .overworldShops, ["candle shop", "candle"]),
        VoiceAction("OW_BookShop", "Book shop", .overworldShops, ["book shop", "magic shop", "book"]),
        VoiceAction("OW_BlueRingShop", "Blue ring shop", .overworldShops, ["blue ring shop", "ring shop", "ring"]),
        VoiceAction("OW_MeatShop", "Meat shop", .overworldShops, ["meat shop", "meat", "food"]),
        VoiceAction("OW_KeyShop", "Key shop", .overworldShops, ["key shop"]),
        VoiceAction("OW_ShieldShop", "Shield shop", .overworldShops, ["shield shop", "shield"]),
        VoiceAction("OW_PotionShop", "Potion shop", .overworldShops, ["potion shop", "potion"]),
        VoiceAction("OW_HintShop", "Hint shop", .overworldShops, ["hint shop", "hint"]),
    ]

    private static let overworldMarks: [VoiceAction] = [
        VoiceAction("OW_Dungeon", "Mark dungeon", .overworldMarks, takesNumber: true,
                    ["set level", "mark level", "place level", "set dungeon", "mark dungeon"]),
        VoiceAction("OW_AnyRoad", "Any road", .overworldMarks, takesNumber: true, ["any road", "road"]),
        VoiceAction("OW_SwordCave1", "Wood sword cave", .overworldMarks, ["wood sword", "brown sword"]),
        VoiceAction("OW_SwordCave2", "White sword cave", .overworldMarks, ["white sword"]),
        VoiceAction("OW_SwordCave3", "Magical sword cave", .overworldMarks, ["magical sword"]),
        VoiceAction("OW_Armos", "Armos", .overworldMarks, ["armos", "armas"]),
        VoiceAction("OW_Letter", "The letter", .overworldMarks, ["letter"]),
        VoiceAction("OW_DoorRepair", "Door repair", .overworldMarks, ["door repair", "door"]),
        VoiceAction("OW_MoneyGame", "Money-making game", .overworldMarks,
                    ["money making game", "money making", "money game", "money", "gamble"]),
        VoiceAction("OW_LargeSecret", "Large secret", .overworldMarks, ["large secret", "big secret"]),
        VoiceAction("OW_MediumSecret", "Medium secret", .overworldMarks, ["medium secret"]),
        VoiceAction("OW_SmallSecret", "Small secret", .overworldMarks, ["small secret"]),
        VoiceAction("OW_DontCare", "Don't care (dark X)", .overworldMarks, ["don't care", "dark", "dark x"]),
        VoiceAction("OW_Nothing", "Nothing (clear)", .overworldMarks, ["nothing", "clear", "empty", "erase"]),
        VoiceAction("OW_SetStart", "Set start spot", .overworldMarks, ["set start", "start here", "start spot"]),
        VoiceAction("OW_ClearStart", "Clear start spot", .overworldMarks, ["clear start", "remove start"]),
    ]

    private static let takeAny: [VoiceAction] = [
        VoiceAction("TakeAny_None", "Take-any (unclaimed)", .takeAny, ["take any", "take-any"]),
        VoiceAction("TakeAny_Potion", "Take-any: potion", .takeAny, ["take any potion"]),
        VoiceAction("TakeAny_Candle", "Take-any: candle", .takeAny, ["take any candle"]),
        VoiceAction("TakeAny_Heart", "Take-any: heart", .takeAny, ["take any heart"]),
    ]

    /// Player-progress toggles (T-142) — the item-grid boxes marked "acquired". These
    /// only fire when an **action word** ("took / got / bought / grabbed…") is present,
    /// so a bare "meat" still marks the meat *shop* while "took meat" flags the item.
    /// The phrases below are the item words; the action word is matched by the grammar.
    private static let progression: [VoiceAction] = [
        VoiceAction("Prog_WoodSword", "Wood sword", .progression, ["wood sword", "wooden sword", "brown sword"]),
        VoiceAction("Prog_MagicalSword", "Magical sword", .progression, ["magical sword", "magic sword"]),
        VoiceAction("Prog_BoomBook", "Boomstick book", .progression, ["book", "boom book", "boomstick", "boomstick book"]),
        VoiceAction("Prog_BlueCandle", "Blue candle", .progression, ["blue candle", "candle"]),
        VoiceAction("Prog_WoodArrow", "Wood arrow", .progression, ["wood arrow", "wooden arrow", "arrow", "arrows"]),
        VoiceAction("Prog_BlueRing", "Blue ring", .progression, ["blue ring", "ring"]),
        VoiceAction("Prog_Bomb", "Bombs", .progression, ["bomb", "bombs"]),
        VoiceAction("Prog_Meat", "Meat / bait", .progression, ["meat", "bait", "food"]),
        VoiceAction("Prog_Ganon", "Ganon (defeated)", .progression, ["ganon", "gannon"]),
        VoiceAction("Prog_Zelda", "Zelda (rescued)", .progression, ["zelda", "princess"]),
    ]

    /// The three off-map item boxes (T-143). Said as **box + item** ("coast ladder").
    /// The `armos`/`white sword` boxes require a qualifier ("item"/"box") so a bare
    /// "armos" / "white sword" still marks the overworld cave.
    private static let itemBoxes: [VoiceAction] = [
        VoiceAction("Box_Coast", "Coast item box", .itemBoxes, ["coast item", "coast box", "coast"]),
        VoiceAction("Box_Armos", "Armos item box", .itemBoxes,
                    ["armos item", "armor item", "armos box", "armor box", "armos", "armor"]),
        VoiceAction("Box_WhiteSword", "White-sword item box", .itemBoxes,
                    ["white sword item", "white sword box", "white sword"]),
    ]

    /// The items an item box can hold (T-143). Ids are `Item_<suffix>` matching
    /// `ItemBoxMark.itemIndex(forHotkeySuffix:)`. Also reused for the dungeon item card
    /// later. Only matched *after* a box name, so "heart" here can't clash elsewhere.
    private static let items: [VoiceAction] = [
        VoiceAction("Item_Bow", "Bow", .items, ["bow"]),
        VoiceAction("Item_Raft", "Raft", .items, ["raft"]),
        VoiceAction("Item_Ladder", "Ladder", .items, ["ladder", "step ladder", "stepladder"]),
        VoiceAction("Item_Recorder", "Recorder", .items, ["recorder", "whistle", "flute"]),
        VoiceAction("Item_Wand", "Wand", .items, ["wand", "magic wand", "magical rod"]),
        VoiceAction("Item_RedCandle", "Red candle", .items, ["red candle"]),
        VoiceAction("Item_RedRing", "Red ring", .items, ["red ring"]),
        VoiceAction("Item_SilverArrow", "Silver arrow", .items, ["silver arrow", "silver arrows"]),
        VoiceAction("Item_MagicBoomerang", "Magic boomerang", .items, ["magic boomerang", "magical boomerang"]),
        VoiceAction("Item_Boomerang", "Boomerang", .items, ["boomerang"]),
        VoiceAction("Item_PowerBracelet", "Power bracelet", .items, ["power bracelet", "bracelet"]),
        VoiceAction("Item_WhiteSword", "White sword", .items, ["white sword"]),
        VoiceAction("Item_HeartContainer", "Heart container", .items, ["heart container", "heart"]),
        VoiceAction("Item_BookOrShield", "Book / magic shield", .items, ["book or shield", "magic book", "magic shield", "shield"]),
        VoiceAction("Item_AnyKey", "Any key (magical key)", .items, ["any key", "magical key", "master key"]),
        VoiceAction("Item_Nothing", "Nothing (clear box)", .items, ["nothing", "empty", "clear", "none"]),
    ]

    // MARK: Dungeon actions (apply to the cursor room when the cursor is in a dungeon)

    /// Doors — a state word + a direction ("open left"); compound utterances mark
    /// several ("open west shutter east key north"). Colors are the user's convention.
    private static let doors: [VoiceAction] = [
        VoiceAction("Door_Open", "Door: open (green)", .doors, takesDirection: true, ["open", "green"]),
        VoiceAction("Door_Blocked", "Door: blocked / wall (red)", .doors, takesDirection: true,
                    ["blocked", "wall", "no door", "red"]),
        VoiceAction("Door_Key", "Door: key (gold)", .doors, takesDirection: true,
                    ["key", "locked", "gold", "yellow"]),
        VoiceAction("Door_Shutter", "Door: shutter (purple)", .doors, takesDirection: true,
                    ["shutter", "purple"]),
        VoiceAction("Door_None", "Door: unknown / clear", .doors, takesDirection: true,
                    ["none", "unknown", "clear door"]),
    ]

    private static let entrances: [VoiceAction] = [
        VoiceAction("Entrance", "Mark entrance (from direction)", .entrances, takesDirection: true,
                    ["entrance", "entered", "enter from", "entered from", "came from", "entering"]),
    ]

    private static let dungeonRooms: [VoiceAction] = [
        VoiceAction("Room_NonDescript", "Non-descript", .dungeonRooms,
                    ["non descript", "nondescript", "empty room", "plain room", "descript", "plain", "blank", "normal room"]),
        VoiceAction("Room_ItemBasement", "Item basement", .dungeonRooms, ["item basement", "basement item", "stair item", "basement"]),
        VoiceAction("Room_Staircase", "Staircase (unknown)", .dungeonRooms, ["staircase", "stairs", "stairway"]),
        VoiceAction("Room_MaybePush", "Maybe push block", .dungeonRooms,
                    ["push block", "maybe push", "possible push", "pushable", "maybe stairs", "push"]),
        VoiceAction("Room_Transport", "Transport staircase", .dungeonRooms, takesNumber: true, ["transport"]),
        VoiceAction("Room_Chevy", "Chevy", .dungeonRooms, ["chevy"]),
        VoiceAction("Room_DoubleMoat", "Double moat", .dungeonRooms, ["double moat"]),
        VoiceAction("Room_TopMoat", "Top moat", .dungeonRooms, ["top moat", "north moat"]),
        VoiceAction("Room_RightMoat", "Right moat", .dungeonRooms, ["right moat", "east moat"]),
        VoiceAction("Room_CircleMoat", "Circle moat", .dungeonRooms, ["circle moat"]),
        VoiceAction("Room_Tee", "Tee", .dungeonRooms, ["tee moat", "tee room"]),
        VoiceAction("Room_LavaMoat", "Lava moat", .dungeonRooms, ["lava moat", "lava"]),
        VoiceAction("Room_VChute", "Vertical chute", .dungeonRooms, ["vertical chute", "v chute"]),
        VoiceAction("Room_HChute", "Horizontal chute", .dungeonRooms, ["horizontal chute", "h chute"]),
        VoiceAction("Room_Turnstile", "Turnstile", .dungeonRooms, ["turnstile"]),
        VoiceAction("Room_OldMan", "Old-man hint", .dungeonRooms, ["old man", "hint room", "npc"]),
        VoiceAction("Room_BombUpgrade", "Bomb upgrade", .dungeonRooms, ["bomb upgrade", "more bombs", "bomb pack room"]),
        VoiceAction("Room_LifeOrMoney", "Life or money", .dungeonRooms, ["life or money"]),
        VoiceAction("Room_HungryGoriya", "Hungry Goriya (meat block)", .dungeonRooms, ["hungry goriya", "meat block"]),
        VoiceAction("Room_OffTheMap", "Off the map", .dungeonRooms, ["off the map", "off map"]),
        VoiceAction("Room_Gannon", "Ganon", .dungeonRooms, ["ganon", "gannon"]),
        VoiceAction("Room_Zelda", "Zelda", .dungeonRooms, ["zelda"]),
        VoiceAction("Room_Unmarked", "Clear room", .dungeonRooms, ["clear room", "unmark room", "empty the room"]),
    ]

    /// Monsters — a shared category (a dungeon room's monster; overworld enemy support
    /// is a later slice).
    private static let monsters: [VoiceAction] = [
        VoiceAction("Mon_Gleeok", "Gleeok", .monsters, ["gleeok"]),
        VoiceAction("Mon_Gohma", "Gohma", .monsters, ["gohma"]),
        VoiceAction("Mon_Digdogger", "Digdogger", .monsters, ["digdogger"]),
        VoiceAction("Mon_Dodongo", "Dodongo", .monsters, ["dodongo"]),
        VoiceAction("Mon_Patra", "Patra", .monsters, ["patra"]),
        VoiceAction("Mon_Manhandla", "Manhandla", .monsters, ["manhandla"]),
        VoiceAction("Mon_Aquamentus", "Aquamentus", .monsters, ["aquamentus"]),
        VoiceAction("Mon_Moldorm", "Moldorm", .monsters, ["moldorm"]),
        VoiceAction("Mon_Lanmola", "Lanmola", .monsters, ["lanmola"]),
        VoiceAction("Mon_Wizzrobe", "Wizzrobe", .monsters, ["wizzrobe", "wizrobe"]),
        VoiceAction("Mon_Darknut", "Darknut", .monsters, ["darknut", "dark nut"]),
        VoiceAction("Mon_Lynel", "Lynel", .monsters, ["lynel"]),
        VoiceAction("Mon_PolsVoice", "Pols Voice", .monsters, ["pols voice", "pols"]),
        VoiceAction("Mon_Goriya", "Goriya", .monsters, ["goriya"]),
        VoiceAction("Mon_Gibdo", "Gibdo", .monsters, ["gibdo"]),
        VoiceAction("Mon_Rope", "Rope", .monsters, ["rope"]),
        VoiceAction("Mon_Vire", "Vire", .monsters, ["vire"]),
        VoiceAction("Mon_Keese", "Keese", .monsters, ["keese"]),
        VoiceAction("Mon_Zol", "Zol", .monsters, ["zol"]),
        VoiceAction("Mon_Gel", "Gel", .monsters, ["gel"]),
        VoiceAction("Mon_Stalfos", "Stalfos", .monsters, ["stalfos"]),
        VoiceAction("Mon_Wallmaster", "Wallmaster", .monsters, ["wallmaster", "wall master"]),
        VoiceAction("Mon_Likelike", "Like Like", .monsters, ["like like", "likelike"]),
        VoiceAction("Mon_Moblin", "Moblin", .monsters, ["moblin"]),
        VoiceAction("Mon_Tektite", "Tektite", .monsters, ["tektite"]),
        VoiceAction("Mon_BlueBubble", "Blue bubble", .monsters, ["blue bubble"]),
        VoiceAction("Mon_RedBubble", "Red bubble", .monsters, ["red bubble"]),
        VoiceAction("Mon_Traps", "Traps", .monsters, ["trap", "traps"]),
        VoiceAction("Mon_RupeeBoss", "Rupee boss", .monsters, ["rupee boss"]),
    ]

    private static let floorDrops: [VoiceAction] = [
        VoiceAction("Drop_Triforce", "Triforce", .floorDrops, ["triforce"]),
        VoiceAction("Drop_Heart", "Heart", .floorDrops, ["heart drop", "drop heart", "dropped heart", "floor heart"]),
        VoiceAction("Drop_OtherKeyItem", "Other key item", .floorDrops,
                    ["key item drop", "item drop", "dropped item", "floor drop", "drop", "dropped", "the drop"]),
        VoiceAction("Drop_BombPack", "Bomb pack", .floorDrops, ["bomb pack", "bomb drop"]),
        VoiceAction("Drop_Key", "Key", .floorDrops, ["key drop", "drop key", "dropped key"]),
        VoiceAction("Drop_FiveRupee", "Five rupee", .floorDrops, ["rupee drop", "five rupee", "dropped rupee"]),
        VoiceAction("Drop_Map", "Map", .floorDrops, ["map drop", "drop map", "map"]),
        VoiceAction("Drop_Compass", "Compass", .floorDrops, ["compass drop", "drop compass", "compass"]),
    ]
}
