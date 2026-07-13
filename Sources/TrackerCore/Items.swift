/// The item-identity indices a `Box`'s `cellCurrent` can hold. Ported
/// value-for-value from the reference's `ITEMS` module
/// (`Zelda1RandoTools/Z1R_Tracker/Z1R_Tracker/TrackerModel.fs:179-208`,
/// the `itemNamesAndCounts` table and its named index constants). These are
/// the `0…14` identifiers referenced throughout `Box`/`Cell` and consumed
/// by `PlayerComputedStateSummary` (T-014).
///
/// Kept as a caseless namespace of `Int` constants (rather than an enum)
/// so it maps 1:1 onto the reference's `ITEMS.RECORDER` etc. and compares
/// directly against `Box.cellCurrent` (a raw `Int`, `-1` = empty). The
/// per-item max-use counts (`itemNamesAndCounts`' second column — Ladder 1,
/// Heart Container 9, …) belong to the deferred `ChoiceDomain` and are not
/// modeled until the item-picker needs them (T-015).
public enum ITEMS {
    public static let bookOrShield = 0
    public static let boomerang = 1
    public static let bow = 2
    public static let powerBracelet = 3
    public static let ladder = 4
    public static let magicBoomerang = 5
    public static let anyKey = 6
    public static let raft = 7
    public static let recorder = 8
    public static let redCandle = 9
    public static let redRing = 10
    public static let silverArrow = 11
    public static let wand = 12
    public static let whiteSword = 13
    public static let heartContainer = 14

    /// The number of distinct item identities (`itemNamesAndCounts.Length`).
    public static let count = 15
}
