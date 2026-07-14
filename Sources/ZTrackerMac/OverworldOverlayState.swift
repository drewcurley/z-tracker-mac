import Observation
import TrackerCore

/// The map-overlay toggles for the top section (T-035.2/.3). Each overlay is
/// **previewed on hover** and **locked on click** (the user's model — click the
/// icon to toggle, no separate checkbox). An overlay renders when it is locked
/// or currently hovered.
@Observable
@MainActor
final class OverworldOverlayState {
    enum Overlay: Hashable, CaseIterable {
        case openCaves   // highlight unmarked open caves (then armos, late game)
        case money       // highlight money-making-game / money secrets
        case zones       // tint each screen by its overworld region
        case coords      // overlay A1…H16 coordinates
    }

    /// Overlays the user has clicked to keep on.
    private(set) var locked: Set<Overlay> = []
    /// The overlay whose icon is currently hovered (transient preview).
    var hovered: Overlay?

    /// Whether an overlay should currently draw (locked or hovered).
    func isActive(_ overlay: Overlay) -> Bool {
        locked.contains(overlay) || hovered == overlay
    }
    func isLocked(_ overlay: Overlay) -> Bool { locked.contains(overlay) }

    /// Click toggles the persistent lock.
    func toggleLock(_ overlay: Overlay) {
        if locked.contains(overlay) { locked.remove(overlay) } else { locked.insert(overlay) }
    }

    /// Hover enter/leave for an icon.
    func setHover(_ overlay: Overlay, _ isHovering: Bool) {
        if isHovering { hovered = overlay }
        else if hovered == overlay { hovered = nil }
    }
}

/// Pure per-tile predicates for the map overlays — separated from the views so
/// the highlight logic is unit-testable.
enum OverworldOverlays {
    /// A money spot (`showLocatorRupees`, `WPFUI.fs:1467-1483`): the Money
    /// Making Game, an Unknown Secret, or a large/medium/small secret with a
    /// recorded rupee value (`extraData != 0`). (Priced secrets can't be set in
    /// the UI yet, so today this resolves to MMG + Unknown Secret.)
    static func isMoneyTile(_ mark: OverworldTileMark, secretValue: Int) -> Bool {
        switch mark {
        case .moneyMakingGame, .secret(.unknown): return true
        case .secret(.large), .secret(.medium), .secret(.small): return secretValue != 0
        default: return false
        }
    }

    /// An "open cave" highlight (`highlightOpenCavesCB`,
    /// `OverworldItemGridUI.fs:456-466`): highlight unmarked `nothingable`
    /// screens **until** the wood sword cave is marked or the player has both a
    /// sword and a candle; **after** that, highlight only the (unclaimed) Armos
    /// locations.
    static func isOpenCaveTile(
        mark: OverworldTileMark, nothingable: Bool, hasArmos: Bool,
        pastEarlyGame: Bool, armosClaimed: Bool
    ) -> Bool {
        if pastEarlyGame {
            return hasArmos && !armosClaimed
        } else {
            return mark == .unmarked && nothingable
        }
    }

    /// The early→late transition for the open-caves overlay: the wood sword cave
    /// is located, or the player has both a sword and a candle.
    static func openCavesPastEarlyGame(woodSwordCaveFound: Bool, swordLevel: Int, candleLevel: Int) -> Bool {
        woodSwordCaveFound || (swordLevel >= 1 && candleLevel >= 1)
    }
}
