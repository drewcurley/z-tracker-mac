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
    public let defaultPhrases: [String]

    public init(_ id: String, _ displayName: String, _ category: VoiceCategory,
                takesNumber: Bool = false, _ defaultPhrases: [String]) {
        self.id = id; self.displayName = displayName; self.category = category
        self.takesNumber = takesNumber; self.defaultPhrases = defaultPhrases
    }
}

public enum VoiceCategory: String, CaseIterable, Sendable, Codable {
    case cursor, navigation, dungeon, overworldShops, overworldMarks, takeAny

    public var title: String {
        switch self {
        case .cursor: "Cursor"
        case .navigation: "Navigation"
        case .dungeon: "Dungeon"
        case .overworldShops: "Overworld — shops"
        case .overworldMarks: "Overworld — marks"
        case .takeAny: "Take-any"
        }
    }
}

public enum VoiceCatalog {
    public static let all: [VoiceAction] =
        cursor + navigation + dungeon + overworldShops + overworldMarks + takeAny

    public static func action(id: String) -> VoiceAction? { all.first { $0.id == id } }
    public static func actions(in category: VoiceCategory) -> [VoiceAction] {
        all.filter { $0.category == category }
    }
    /// Categories in editor order.
    public static let categoryOrder: [VoiceCategory] =
        [.cursor, .navigation, .dungeon, .overworldShops, .overworldMarks, .takeAny]

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
        VoiceAction("OW_MoneyGame", "Money-making game", .overworldMarks, ["money making game", "money game", "gamble"]),
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
}
