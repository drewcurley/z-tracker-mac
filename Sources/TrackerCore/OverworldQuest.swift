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
}
