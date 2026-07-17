/// Per-type placement limits for overworld tile marks (T-058), ported from the
/// reference's map-square choice domain (`overworldTiles`,
/// `TrackerModel.fs:258-300`, the "maxuses" column). Once a type is placed its
/// maximum number of times, the picker disables it so you can't mark, e.g., a
/// second Dungeon 1, a fifth take-any, or a second Letter.
///
/// Types with no meaningful limit (shops, secrets, don't-care) use the
/// reference's `999` sentinel — effectively unlimited.
public enum OverworldTileLimits {
    /// The reference's "no real limit" sentinel.
    public static let unlimited = 999

    /// Max number of overworld tiles that may carry `mark` for `quest`.
    public static func maxUses(_ mark: OverworldTileMark, quest: OverworldQuest) -> Int {
        let fq = quest.isFirstQuestOverworld
        switch mark {
        // One of each numbered dungeon, any-road, sword cave; one letter/armos.
        case .dungeon, .anyRoad, .swordCave, .theLetter, .armos: return 1
        case .hintShop, .takeAny: return 4
        case .doorRepair: return fq ? 9 : 10
        case .moneyMakingGame: return fq ? 5 : 6
        case .potionShop: return fq ? 7 : 9
        // Sized money secrets are capped at the quest's known totals (T-108, user
        // request — the reference leaves these unlimited, but over-marking is easy
        // to do by mistake). 1Q large 3 / medium 7 / small 4; 2Q large 1 / small 6.
        case .secret(.large): return fq ? 3 : 1
        case .secret(.medium): return 7
        case .secret(.small): return fq ? 4 : 6
        // An *unknown* (unsized) secret has no size cap yet.
        case .secret(.unknown): return unlimited
        // Shops and don't-care/unmarked: unbounded.
        case .shop, .dontCare, .unmarked: return unlimited
        }
    }
}
