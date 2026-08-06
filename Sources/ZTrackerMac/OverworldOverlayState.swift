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
        case hideMarks   // suppress the tile-selection icons to reveal the terrain (T-062)
    }

    /// The open-caves overlay is a **3-way** cycle (T-189, user request), unlike the
    /// binary overlays: off → open caves only → all currently-gettable locations → off.
    enum OpenCavesMode: CaseIterable, Sendable {
        case off, openCaves, allGettable
        /// The next mode in the click cycle.
        var next: OpenCavesMode {
            switch self {
            case .off: .openCaves
            case .openCaves: .allGettable
            case .allGettable: .off
            }
        }
    }

    /// Binary overlays the user has clicked to keep on (open-caves is tracked separately).
    private(set) var locked: Set<Overlay> = []
    /// The open-caves overlay's current locked mode.
    private(set) var openCavesMode: OpenCavesMode = .off
    /// The overlay whose icon is currently hovered (transient preview).
    var hovered: Overlay?

    /// Whether an overlay should currently draw (locked or hovered).
    func isActive(_ overlay: Overlay) -> Bool {
        if overlay == .openCaves { return openCavesMode != .off || hovered == .openCaves }
        return locked.contains(overlay) || hovered == overlay
    }
    func isLocked(_ overlay: Overlay) -> Bool {
        overlay == .openCaves ? openCavesMode != .off : locked.contains(overlay)
    }

    /// The effective open-caves mode to render, folding in the hover preview: hovering
    /// the icon while off previews the first mode (open caves only).
    var effectiveOpenCavesMode: OpenCavesMode {
        openCavesMode != .off ? openCavesMode : (hovered == .openCaves ? .openCaves : .off)
    }

    /// Click toggles the persistent lock — a binary flip for most overlays, the 3-way
    /// cycle for open caves.
    func toggleLock(_ overlay: Overlay) {
        if overlay == .openCaves { openCavesMode = openCavesMode.next; return }
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
    /// A money spot the locator should highlight (`showLocatorRupees`,
    /// `WPFUI.fs:1467-1483`): the Money Making Game and an Unknown Secret always,
    /// plus a large/medium/small secret. The reference highlights sized secrets
    /// that carry a recorded rupee value; this port has no per-secret pricing, so
    /// it instead highlights any sized money secret you've **marked but not yet
    /// collected** (`!secretCollected`) — the ones still worth walking to for
    /// money (T-111, user request). A collected (used) secret is spent, so it's
    /// dropped from the highlight.
    static func isMoneyTile(_ mark: OverworldTileMark, secretCollected: Bool) -> Bool {
        switch mark {
        case .moneyMakingGame, .secret(.unknown): return true
        case .secret(.large), .secret(.medium), .secret(.small): return !secretCollected
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
