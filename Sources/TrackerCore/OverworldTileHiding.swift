/// "More settings" overworld tile hiding (T-004.3) — ported from
/// `OverworldMapTileCustomization.ShouldHide` (`ShouldHide`, line 155) +
/// `AsTrackerModelOptionsOverworldTilesToHide` (`TrackerModel.fs:373-401`).
///
/// When the player checks a tile *kind* in the startup "More settings…" popup,
/// a marked tile of that kind renders **dimmed** on the map (so the map stays
/// uncluttered), and is revealed again on hover or once Zelda is rescued (the
/// reference's `temporarilyDisplayHiddenOverworldTileMarks` / `PlayerHasRescuedZelda`
/// gates). This is the icon-suppression *policy*; the view applies the dimming
/// and the hover reveal.
///
/// **Shops** (T-207): `hideNoLongerRelevantShopItems` dims a shop's *individual* items once the
/// player already owns them (`hiddenShopItems`) — a combo bomb/ring shop with the ring owned
/// keeps showing the bomb. When *every* item a shop sells is owned, the whole tile dims
/// (`isKindHidden`). Per the reference's `IsHideableShopItem`, an item is hideable when:
/// arrow → `arrowLevel > 0`, book → `haveBook`, candle → `candleLevel > 0`,
/// blue-ring → `ringLevel > 0`, key → `haveAnyKey`, meat → the `alwaysHideMeatShops` option.
/// **Bomb, meat, and magic shield are consumable — never hidden by relevance** (meat only via
/// its own `alwaysHideMeatShops`).
public enum OverworldTileHiding {
    /// Whether `mark`'s icon should be dimmed/hidden on the map. `false` once Zelda is rescued
    /// (the endgame reveal). Non-shop marks use the "More settings" per-kind hide list; shops
    /// use the no-longer-relevant policy above.
    public static func isKindHidden(mark: OverworldTileMark,
                                    options: TrackerOptions,
                                    hasRescuedZelda: Bool,
                                    playerState: PlayerComputedStateSummary = PlayerComputedStateSummary(),
                                    shopSecondItem: ShopKind? = nil,
                                    haveBook: Bool = false) -> Bool {
        if hasRescuedZelda { return false }
        if case .shop(let primary) = mark {
            // The whole shop tile hides only when *every* item it sells is hidden — then it's
            // effectively a "don't care". Per-item hiding (drop just the owned ones) is
            // `hiddenShopItems`, applied to the shop's icon render.
            let items = shopItems(primary, shopSecondItem)
            let hidden = hiddenShopItems(primary: primary, second: shopSecondItem,
                                         options: options, playerState: playerState, haveBook: haveBook)
            return !items.isEmpty && hidden.count == items.count
        }
        guard let kind = mark.hideableKind else { return false }
        return options.hiddenOverworldTiles[kind] == true
    }

    /// A shop's items (primary + optional distinct second), deduped.
    public static func shopItems(_ primary: ShopKind, _ second: ShopKind?) -> [ShopKind] {
        [primary] + (second.flatMap { $0 == primary ? nil : [$0] } ?? [])
    }

    /// The subset of a shop's items to hide (dim) — the owned/irrelevant ones. The shop's icon
    /// renders only the remaining items; when this is *all* of them the tile fully dims.
    public static func hiddenShopItems(primary: ShopKind, second: ShopKind?,
                                       options: TrackerOptions, playerState: PlayerComputedStateSummary,
                                       haveBook: Bool) -> Set<ShopKind> {
        Set(shopItems(primary, second).filter {
            shopItemHideable($0, playerState: playerState, options: options, haveBook: haveBook)
        })
    }

    /// Whether a single shop item is no-longer-relevant (owned). **Bomb, meat, and magic shield
    /// are consumable / always relevant** — never hidden by the relevance option (meat only via
    /// the explicit `alwaysHideMeatShops`). The rest hide once owned, when
    /// `hideNoLongerRelevantShopItems` is on.
    static func shopItemHideable(_ kind: ShopKind, playerState: PlayerComputedStateSummary,
                                 options: TrackerOptions, haveBook: Bool) -> Bool {
        switch kind {
        case .bomb, .shield: return false                       // consumable — always relevant
        case .meat: return options.alwaysHideMeatShops          // consumable, but its own opt-in
        default:
            guard options.hideNoLongerRelevantShopItems else { return false }
            switch kind {
            case .arrow: return playerState.arrowLevel > 0
            case .candle: return playerState.candleLevel > 0
            case .blueRing: return playerState.ringLevel > 0
            case .key: return playerState.haveAnyKey
            case .book: return haveBook
            default: return false
            }
        }
    }
}

public extension OverworldTileMark {
    /// The "hideable tile kind" this mark corresponds to in the "More settings"
    /// hide list, or `nil` if the mark isn't one of the 12 hideable kinds
    /// (dungeons, any-roads, shops, potion shops, unmarked/don't-care never
    /// hide). Mirrors `AsTrackerModelOptionsOverworldTilesToHide`.
    var hideableKind: OverworldHiddenTileKind? {
        switch self {
        case .swordCave(1): return .sword1
        case .swordCave(2): return .sword2
        case .swordCave(3): return .sword3
        case .secret(.large): return .largeSecret
        case .secret(.medium): return .mediumSecret
        case .secret(.small): return .smallSecret
        case .doorRepair: return .doorRepair
        case .moneyMakingGame: return .moneyMakingGame
        case .theLetter: return .theLetter
        case .armos: return .armos
        case .hintShop: return .hintShop
        case .takeAny: return .takeAny
        default: return nil
        }
    }
}
