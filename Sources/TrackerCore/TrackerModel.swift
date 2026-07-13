import Foundation
import Observation

/// The UI-agnostic tracker state, mirroring the reference app's
/// UI-framework-agnostic F# core (see docs/architecture.md § 2).
///
/// Covers the startup screen's core toggles (docs/domain.md § 4.1, T-003).
/// The full state (dungeon items, overworld tiles, blockers, timeline, the
/// embedded settings panel — see docs/domain.md) is out of scope here and
/// lands incrementally in later feature tasks, each updating
/// docs/contracts.md as it goes.
@Observable
public final class TrackerModel {
    public private(set) var quest: OverworldQuest?

    /// Pre-fills each dungeon's first item box with a Heart Container
    /// (docs/domain.md § 4.1). Off by default, matching the reference app.
    public var heartShuffle: Bool

    /// Hides which numbered dungeon is which, changing several UI behaviors
    /// elsewhere (docs/domain.md § 4.1–4.2). Off by default.
    public var hideDungeonNumbers: Bool

    /// The overworld map's tile-mark state (docs/domain.md § 4.5, T-006).
    /// Owned here since `TrackerModel` is documented as the eventual home
    /// for all main-tracker-view state, not a separate parallel container.
    public let overworldGrid: OverworldGrid

    /// Seed-configured starting inventory (docs/domain.md § 6, T-012 —
    /// foundation piece of the player-state layer; `PlayerComputedStateSummary`
    /// derivation that actually consumes this lands in T-014).
    public let startingItemsAndExtras: StartingItemsAndExtras

    /// Runtime-acquired player progress not tied to a dungeon-box location
    /// (docs/domain.md § 6, T-012).
    public let playerProgress: PlayerProgressAndTakeAnyHearts

    /// The nine dungeons' item/completion/triforce state plus the three
    /// standalone boxes (docs/domain.md § 6, T-013). DEFAULT mode only —
    /// Hidden Dungeon Numbers is T-016. `PlayerComputedStateSummary`, the
    /// glue that turns these boxes into `HaveLadder`/`SwordLevel`/etc., is
    /// T-014.
    public let dungeonTracker: DungeonTrackerInstance

    public init(
        quest: OverworldQuest? = nil,
        heartShuffle: Bool = false,
        hideDungeonNumbers: Bool = false,
        overworldGrid: OverworldGrid = OverworldGrid(),
        startingItemsAndExtras: StartingItemsAndExtras = StartingItemsAndExtras(),
        playerProgress: PlayerProgressAndTakeAnyHearts = PlayerProgressAndTakeAnyHearts(),
        dungeonTracker: DungeonTrackerInstance = DungeonTrackerInstance()
    ) {
        self.quest = quest
        self.heartShuffle = heartShuffle
        self.hideDungeonNumbers = hideDungeonNumbers
        self.overworldGrid = overworldGrid
        self.startingItemsAndExtras = startingItemsAndExtras
        self.playerProgress = playerProgress
        self.dungeonTracker = dungeonTracker
    }

    /// Selects the overworld quest for this run. Mirrors the reference app's
    /// startup-screen quest buttons (docs/domain.md § 4.1) — once a quest is
    /// chosen, the reference app moves from the startup screen to the main
    /// tracker view; wiring that transition is `StartupView`'s concern, not
    /// this model's (the model just records the choice).
    public func selectQuest(_ quest: OverworldQuest) {
        self.quest = quest
    }
}
