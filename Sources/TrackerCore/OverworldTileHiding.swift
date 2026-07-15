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
/// **Scope:** the 12 non-shop kinds. Shop-item relevance hiding
/// (`hideNoLongerRelevantShopItems` / `alwaysHideMeatShops`, which filter
/// no-longer-needed items out of a shop tile) is a separate follow-up (T-004.4)
/// — those two checkboxes don't take effect yet.
public enum OverworldTileHiding {
    /// Whether `mark`'s icon should be dimmed/hidden on the map given the
    /// "More settings" per-kind hide list. `false` once Zelda is rescued (the
    /// endgame reveal). Shops are never hidden by this path (see scope note).
    public static func isKindHidden(mark: OverworldTileMark,
                                    options: TrackerOptions,
                                    hasRescuedZelda: Bool) -> Bool {
        if hasRescuedZelda { return false }
        guard let kind = mark.hideableKind else { return false }
        return options.hiddenOverworldTiles[kind] == true
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
