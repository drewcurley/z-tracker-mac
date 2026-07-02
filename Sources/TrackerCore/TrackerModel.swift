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

    public init(
        quest: OverworldQuest? = nil,
        heartShuffle: Bool = false,
        hideDungeonNumbers: Bool = false
    ) {
        self.quest = quest
        self.heartShuffle = heartShuffle
        self.hideDungeonNumbers = hideDungeonNumbers
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
