/// The four overworld layouts a Zelda 1 Randomizer seed can use.
/// Ported from the reference app's quest selection (see docs/domain.md § 4.1).
/// A 5th case in the reference app, `OWQuest.BLANK`, corresponds to the
/// already-deferred "alternative overworld map" custom mode (`domain.md`
/// § 4.1) and is intentionally not modeled here.
public enum OverworldQuest: String, Codable, CaseIterable, Sendable {
    case first
    case second
    case mixedFirst
    case mixedSecond

    /// The reference app's own integer index for this quest, grounded
    /// exactly in `OverworldData.fs:38-41` (`OWQuest.AsInt`) — used to
    /// locate this quest's 256px-wide section in the background-art strip
    /// (T-008, `OverworldBackgroundAtlas`).
    public var referenceAppIndex: Int {
        switch self {
        case .first: 0
        case .second: 1
        case .mixedFirst: 2
        case .mixedSecond: 3
        }
    }

    /// Whether this quest uses the **first-quest overworld** layout (`.first`
    /// and `.mixedFirst`). Ported from `OWQuest.IsFirstQuestOW`
    /// (`OverworldData.fs:35`) — drives, e.g., the per-quest secret counts
    /// (T-053).
    public var isFirstQuestOverworld: Bool {
        switch self {
        case .first, .mixedFirst: true
        case .second, .mixedSecond: false
        }
    }

    /// The fixed number of overworld **spots** (screens that hold something) a seed of this quest
    /// contains — a property of the quest's rules, not of the map art. First-quest overworld uses
    /// **73**, second-quest **80**; the mixed quests draw from 93 potential screen positions but
    /// still resolve to the same *used* totals (mixed-first 73, mixed-second 80), so this keys off
    /// `isFirstQuestOverworld`. Source: the Z1R quest ruleset (per the project owner). Used for the
    /// custom-map "spots left" count (T-235), where the vanilla terrain masks don't apply and the
    /// count is `overworldSpotTotal − (screens marked as a real spot)`.
    public var overworldSpotTotal: Int { isFirstQuestOverworld ? 73 : 80 }

    /// A human-readable name for the quest, shared by the startup picker and the mid-run quest
    /// changer (T-237).
    public var displayName: String {
        switch self {
        case .first: "First Quest"
        case .second: "Second Quest"
        case .mixedFirst: "Mixed — First Quest rules"
        case .mixedSecond: "Mixed — Second Quest rules"
        }
    }
}
