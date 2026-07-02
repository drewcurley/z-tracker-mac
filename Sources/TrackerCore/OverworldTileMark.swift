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
/// **Count discrepancy resolved (T-007), not left open:** an earlier draft
/// flagged 36 modeled states vs. `domain.md`'s "38" vs. 39 icon-strip images
/// as an unresolved discrepancy. Reading
/// `MapSquareChoiceDomainHelper` directly (`TrackerModel.fs:310-354`) — the
/// reference app's own authoritative tile-index enumeration — confirms
/// exactly **36** indices (0...35, `DUNGEON_1` through `DARK_X`), matching
/// this enum's 36 cases exactly. `domain.md`'s "38" was itself the
/// unverified number; it should be corrected to 36. The icon strip's extra 3
/// images (36...38) are unaccounted for — unused/reserved slots, most
/// likely — and don't need cases here since nothing in the reference app's
/// own tile-index enum reaches them.
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

    /// The 0-based index into the reference app's `s_icon_overworld_strip39.png`
    /// icon strip (each icon 16×11px, T-006/T-007), grounded exactly in
    /// `MapSquareChoiceDomainHelper` (`TrackerModel.fs:310-354`). `nil` for
    /// `.unmarked` (this project's own default state, no reference-app
    /// equivalent) and for any out-of-range associated value.
    public var iconStripIndex: Int? {
        switch self {
        case .unmarked:
            nil
        case .dungeon(let number) where (1...9).contains(number):
            number - 1
        case .anyRoad(let number) where (1...4).contains(number):
            8 + number
        case .swordCave(3): 13
        case .swordCave(2): 14
        case .swordCave(1): 15
        case .shop(.arrow): 16
        case .shop(.bomb): 17
        case .shop(.book): 18
        case .shop(.candle): 19
        case .shop(.blueRing): 20
        case .shop(.meat): 21
        case .shop(.key): 22
        case .shop(.shield): 23
        case .secret(.unknown): 24
        case .secret(.large): 25
        case .secret(.medium): 26
        case .secret(.small): 27
        case .doorRepair: 28
        case .moneyMakingGame: 29
        case .theLetter: 30
        case .armos: 31
        case .hintShop: 32
        case .takeAny: 33
        case .potionShop: 34
        case .dontCare: 35
        case .dungeon, .anyRoad, .swordCave:
            nil // out-of-documented-range associated value
        }
    }
}
