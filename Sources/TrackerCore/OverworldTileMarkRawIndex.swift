/// The bridge between the typed `OverworldTileMark` and the reference's raw
/// integer tile-index space (`MapSquareChoiceDomainHelper`,
/// `Zelda1RandoTools/Z1R_Tracker/Z1R_Tracker/TrackerModel.fs:310-352`).
///
/// `recomputeMapStateSummary` (T-015.3) and the destination picker (T-015.6)
/// are written as integer arithmetic over `overworldMapMarks.[i,j].Current()`
/// — range checks (`16..23` = a shop), offset math (`state-15` = the shop's
/// item value). Porting that logic 1:1 is far lower-risk with a faithful
/// raw-index bridge than by rewriting every branch against enum cases, so
/// this exposes exactly the `MapSquareChoiceDomainHelper` numbering and its
/// three helpers (`SHOP`, `IsItem`, `ToItem`) plus `MaxKey`.
extension OverworldTileMark {
    /// The reference's `mapSquareChoiceDomain` index for this mark
    /// (`0…35`), or `-1` for `.unmarked` (the reference's empty
    /// `Cell.Current() = -1`). Inverse of `fromRawIndex(_:)`. Explicit per
    /// case — not derived from `CaseIterable` order — so the numbering can't
    /// silently drift from the reference.
    public var rawIndex: Int {
        switch self {
        case .unmarked: -1
        case .dungeon(let n) where (1...9).contains(n): n - 1                // 0…8
        case .anyRoad(let n) where (1...4).contains(n): 9 + (n - 1)          // 9…12
        case .swordCave(3): 13
        case .swordCave(2): 14
        case .swordCave(1): 15
        case .shop(.arrow): 16
        case .shop(.bomb): 17
        case .shop(.book): 18
        case .shop(.candle): 19
        case .shop(.blueRing): 20
        case .shop(.meat): 21
        case .shop(.key): 22
        case .shop(.shield): 23
        case .secret(.unknown): 24
        case .secret(.large): 25
        case .secret(.medium): 26
        case .secret(.small): 27
        case .doorRepair: 28
        case .moneyMakingGame: 29
        case .theLetter: 30
        case .armos: 31
        case .hintShop: 32
        case .takeAny: 33
        case .potionShop: 34
        case .dontCare: 35
        // Out-of-documented-range associated values (defensive; the public
        // API only ever constructs in-range marks).
        case .dungeon, .anyRoad, .swordCave: -1
        }
    }

    /// The mark for a raw `mapSquareChoiceDomain` index (`-1` → `.unmarked`,
    /// `0…35` → the matching mark), or `nil` for anything out of range.
    /// Inverse of `rawIndex`.
    public static func fromRawIndex(_ i: Int) -> OverworldTileMark? {
        switch i {
        case -1: .unmarked
        case 0...8: .dungeon(i + 1)
        case 9...12: .anyRoad(i - 9 + 1)
        case 13: .swordCave(3)
        case 14: .swordCave(2)
        case 15: .swordCave(1)
        case 16: .shop(.arrow)
        case 17: .shop(.bomb)
        case 18: .shop(.book)
        case 19: .shop(.candle)
        case 20: .shop(.blueRing)
        case 21: .shop(.meat)
        case 22: .shop(.key)
        case 23: .shop(.shield)
        case 24: .secret(.unknown)
        case 25: .secret(.large)
        case 26: .secret(.medium)
        case 27: .secret(.small)
        case 28: .doorRepair
        case 29: .moneyMakingGame
        case 30: .theLetter
        case 31: .armos
        case 32: .hintShop
        case 33: .takeAny
        case 34: .potionShop
        case 35: .dontCare
        default: nil
        }
    }

    /// The shared extra-data key under which every shop stores its second
    /// item (`MapSquareChoiceDomainHelper.SHOP = ARROW = 16`).
    public static let shopExtraDataKey = 16

    /// The number of trackable item-shop types
    /// (`MapSquareChoiceDomainHelper.NUM_ITEMS = 8`).
    public static let numShopItems = 8

    /// The last domain index (`DARK_X = 35`), which the reference treats as
    /// the "not interesting" sentinel (`mapSquareChoiceDomain.MaxKey`,
    /// verified: the domain has exactly 36 entries `0…35`). Ported for the
    /// recompute's `isInteresting` check (`TrackerModel.fs:1123`).
    public static let maxRawIndex = 35

    /// Is this raw index an item-shop tile (`16…23`)? Ported from
    /// `MapSquareChoiceDomainHelper.IsItem` (`TrackerModel.fs:337`).
    public static func isItem(rawIndex: Int) -> Bool {
        rawIndex >= 16 && rawIndex <= 23
    }

    /// Converts a shop's raw index into the `1…8` value stored in the
    /// extra-data array (`state - 15`), or `0` for a non-shop index. Ported
    /// from `MapSquareChoiceDomainHelper.ToItem` (`TrackerModel.fs:338`).
    public static func toItem(rawIndex: Int) -> Int {
        isItem(rawIndex: rawIndex) ? rawIndex - 15 : 0
    }
}
