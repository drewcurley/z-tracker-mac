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

    /// Which of the reference app's real icon sources renders this mark's
    /// small interior icon (composited centered within the tile, not a
    /// full-tile image).
    ///
    /// **Correction, not the original design:** an earlier version of this
    /// property returned a single flat index into
    /// `s_icon_overworld_strip39.png`. That file turned out to be dead code
    /// in the reference app itself — loaded into a variable literally named
    /// `zhMapIcons` (`Z1R_WPF/Graphics.fs:767`) and never referenced
    /// anywhere else, a leftover from the ZHelper tool that inspired
    /// Z-Tracker before its overworld tiles were redesigned with smaller
    /// icons (`Zelda1RandoTools/doc/about.md`: *"Overworld tiles in
    /// particular required redesigning new, slimmer icons, rather than the
    /// full-tile icons I had copied from ZHelper"*). The real interior-icon
    /// system, confirmed by reading `Graphics.fs`'s `theInteriorBmpTable`
    /// construction (`:850-945`) and its consumers
    /// (`OverworldMapTileCustomization.fs`), draws from three sources:
    /// `ow_icons5x9.png` (14 icons, 5×9px), `icons3x7.png` (8 shop icons,
    /// 3×7px, composited on an orange background), and painted digits on a
    /// colored background for dungeons/any-roads — grounded exactly in
    /// `MapSquareChoiceDomainHelper` (`TrackerModel.fs:310-354`) for which
    /// logical value maps to which source.
    ///
    /// Always resolves to the "available" variant. The reference app also
    /// darkens/grays several of these once the player has obtained the
    /// thing (sword cave once its box is done, armos once taken, etc.) —
    /// that depends on player-state this project hasn't built yet
    /// (`docs/domain.md` § 6, `T-013`/`T-014`), so it's correctly deferred
    /// rather than guessed at here.
    public var iconSource: OverworldTileIconSource {
        switch self {
        case .unmarked:
            .none
        case .dungeon(let number) where (1...9).contains(number):
            .dungeonDigit(number)
        case .anyRoad(let number) where (1...4).contains(number):
            .anyRoadDigit(number)
        case .swordCave(3): .interiorSprite(0)
        case .swordCave(2): .interiorSprite(1)
        case .swordCave(1): .interiorSprite(2)
        case .shop(.arrow): .shopSprite(0)
        case .shop(.bomb): .shopSprite(1)
        case .shop(.book): .shopSprite(2)
        case .shop(.candle): .shopSprite(3)
        case .shop(.blueRing): .shopSprite(4)
        case .shop(.meat): .shopSprite(5)
        case .shop(.key): .shopSprite(6)
        case .shop(.shield): .shopSprite(7)
        case .secret(.unknown): .interiorSprite(11)
        case .secret(.large): .interiorSprite(8)
        case .secret(.medium): .interiorSprite(6)
        case .secret(.small): .interiorSprite(9)
        case .doorRepair: .interiorSprite(12)
        case .moneyMakingGame: .interiorSprite(10)
        case .theLetter: .interiorSprite(13)
        case .armos: .interiorSprite(7)
        case .hintShop: .interiorSprite(3)
        case .takeAny: .interiorSprite(4)
        case .potionShop: .interiorSprite(5)
        case .dontCare: .solidBlackTile
        case .dungeon, .anyRoad, .swordCave:
            .none // out-of-documented-range associated value
        }
    }
}

/// Describes which real reference-app icon source renders a tile mark's
/// interior icon. See `OverworldTileMark.iconSource` for the grounding.
public enum OverworldTileIconSource: Hashable, Sendable {
    /// No interior icon (`.unmarked`).
    case none
    /// A whole-tile solid black fill (`.dontCare`/`DarkX`) — the reference
    /// app blacks out the entire 16×11 tile, not just the interior icon
    /// region.
    case solidBlackTile
    /// A painted digit 1...9 on a yellow background (dungeons, non-HDN
    /// variant only — HDN's lettered variant needs `Dungeon.LabelChar`,
    /// deferred to `T-016`).
    case dungeonDigit(Int)
    /// A painted digit 1...4 on an orchid background (any-roads).
    case anyRoadDigit(Int)
    /// A 0-based index into `ow_icons5x9.png` (14 icons, 5×9px each,
    /// background baked into the sprite).
    case interiorSprite(Int)
    /// A 0-based index into `icons3x7.png` (8 icons, 3×7px each), to be
    /// composited onto a 5×9 orange background.
    case shopSprite(Int)
}
