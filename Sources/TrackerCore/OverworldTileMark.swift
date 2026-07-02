/// The 8 shop kinds a shop tile can carry (docs/domain.md § 4.5).
public enum ShopKind: String, Codable, CaseIterable, Sendable {
    case arrow, bomb, book, candle, blueRing, meat, key, shield

    public var displayName: String {
        switch self {
        case .arrow: "Arrow shop"
        case .bomb: "Bomb shop"
        case .book: "Book shop"
        case .candle: "Candle shop"
        case .blueRing: "Blue Ring shop"
        case .meat: "Meat shop"
        case .key: "Key shop"
        case .shield: "Shield shop"
        }
    }
}

/// The 4 "secret" tile sizes (docs/domain.md § 4.5).
public enum SecretSize: String, Codable, CaseIterable, Sendable {
    case unknown, large, medium, small

    public var displayName: String {
        switch self {
        case .unknown: "Unknown secret"
        case .large: "Large secret"
        case .medium: "Medium secret"
        case .small: "Small secret"
        }
    }
}

/// What an overworld map tile can be marked as (docs/domain.md § 4.5),
/// grounded in the reference app's tile-mark inventory, plus `.unmarked` as
/// this project's explicit "nothing set yet" default (distinct from
/// `.dontCare`, the reference app's own explicit "DarkX" mark).
///
/// **Count note, not silently glossed over:** this enum has 9 dungeons + 4
/// any-roads + 3 sword caves + 8 shop kinds + 4 secret sizes + 7 standalone
/// kinds (DoorRepair, MoneyMakingGame, TheLetter, Armos, HintShop, TakeAny,
/// PotionShop) + `.dontCare` = 36 marked states, not the 38 `domain.md` §
/// 4.5 cites (which itself was derived from doc/source reading, not a
/// tile-by-tile source enumeration) or the 39 images in the reference app's
/// `s_icon_overworld_strip39.png` icon strip. The discrepancy is unresolved
/// — flagged here and in `tasks/T-006.md` rather than padding the enum with
/// guessed cases to hit a specific number.
public enum OverworldTileMark: Hashable, Codable, Sendable {
    case unmarked
    case dontCare
    /// 1...9
    case dungeon(Int)
    /// 1...4
    case anyRoad(Int)
    /// 1...3
    case swordCave(Int)
    case shop(ShopKind)
    case secret(SecretSize)
    case doorRepair
    case moneyMakingGame
    case theLetter
    case armos
    case hintShop
    case takeAny
    case potionShop

    public var displayName: String {
        switch self {
        case .unmarked: "Unmarked"
        case .dontCare: "Don't care"
        case .dungeon(let number): "Dungeon \(number)"
        case .anyRoad(let number): "Any road \(number)"
        case .swordCave(let number): "Sword cave \(number)"
        case .shop(let kind): kind.displayName
        case .secret(let size): size.displayName
        case .doorRepair: "Door repair"
        case .moneyMakingGame: "Money making game"
        case .theLetter: "The letter"
        case .armos: "Armos"
        case .hintShop: "Hint shop"
        case .takeAny: "Take any"
        case .potionShop: "Potion shop"
        }
    }
}
