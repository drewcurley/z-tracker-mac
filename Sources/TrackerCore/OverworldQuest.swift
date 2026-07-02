/// The four overworld layouts a Zelda 1 Randomizer seed can use.
/// Ported from the reference app's quest selection (see docs/domain.md § 4.1).
public enum OverworldQuest: String, Codable, CaseIterable, Sendable {
    case first
    case second
    case mixedFirst
    case mixedSecond
}
