import Foundation
import Observation

/// The UI-agnostic tracker state, mirroring the reference app's
/// UI-framework-agnostic F# core (see docs/architecture.md § 2).
///
/// This is a deliberately minimal scaffold (T-002) — it holds only the quest
/// selection from the startup screen (docs/domain.md § 4.1). The full state
/// (dungeon items, overworld tiles, blockers, timeline, options — see
/// docs/domain.md) is out of scope for this task and lands incrementally in
/// later feature tasks, each updating docs/contracts.md as it goes.
@Observable
public final class TrackerModel {
    public private(set) var quest: OverworldQuest?

    public init(quest: OverworldQuest? = nil) {
        self.quest = quest
    }

    /// Selects the overworld quest for this run. Mirrors the reference app's
    /// startup-screen quest buttons (docs/domain.md § 4.1) — once a quest is
    /// chosen, the reference app moves from the startup screen to the main
    /// tracker view; that transition is a later task's concern, not this one.
    public func selectQuest(_ quest: OverworldQuest) {
        self.quest = quest
    }
}
