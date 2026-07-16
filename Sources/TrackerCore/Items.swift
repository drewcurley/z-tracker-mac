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

    /// A spoken/display name for an item id, for reminder text (`AsPronounceString`,
    /// `TrackerModel.fs:212-228`). Item 0 is book or shield depending on the seed.
    /// Deviation: the reference spells item 2 "beau" as a phonetic hack for the old
    /// TTS voice; we keep "bow" (correct on screen; the live voice reads it fine).
    public static func spokenName(_ id: Int, isBook: Bool) -> String {
        switch id {
        case bookOrShield: return isBook ? "book" : "shield"
        case boomerang: return "boomerang"
        case bow: return "bow"
        case powerBracelet: return "power bracelet"
        case ladder: return "ladder"
        case magicBoomerang: return "magic boomerang"
        case anyKey: return "magic key"
        case raft: return "raft"
        case recorder: return "recorder"
        case redCandle: return "red candle"
        case redRing: return "red ring"
        case silverArrow: return "silver arrow"
        case wand: return "wand"
        case whiteSword: return "white sword"
        case heartContainer: return "heart container"
        default: return "item"
        }
    }
}
