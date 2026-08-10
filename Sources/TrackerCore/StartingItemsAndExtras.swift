import Observation

/// Seed-configured starting inventory — items the player begins a run
/// already holding, configured once per seed/run rather than earned by
/// play. Ported field-for-field from `StartingItemsAndExtras`
/// (`Zelda1RandoTools/Z1R_Tracker/Z1R_Tracker/TrackerModel.fs:535-570`);
/// every field defaults to `false`/`0`, confirmed against
/// `StartingItemsAndExtrasModel`'s save/load shape
/// (`SaveAndLoad.fs:94-151`), which never applies a non-default value on a
/// fresh save.
///
/// Note ported verbatim from the reference source (`TrackerModel.fs:554-555`):
/// unlike the item-box/cave versions of the sword fields consumed by
/// `PlayerComputedStateSummary` (`T-014`), these starting-item versions mean
/// the player actually has a sword, even when the "White Sword/Magical
/// Sword boxes replaced by Bomb Upgrade" seed flag is on.
@Observable
public final class StartingItemsAndExtras {
    /// Hidden-Dungeon-Numbers mode lets a seed start with pre-known
    /// triforce pieces not tied to a located dungeon. Always 8 entries,
    /// one per triforce piece.
    public var hdnStartingTriforcePieces: [Bool]

    public var hasWhiteSword: Bool
    public var hasMagicalSword: Bool
    public var hasSilverArrow: Bool
    public var hasBow: Bool
    public var hasWand: Bool
    public var hasRedCandle: Bool
    public var hasBoomerang: Bool
    public var hasMagicBoomerang: Bool
    public var hasRedRing: Bool
    public var hasPowerBracelet: Bool
    public var hasLadder: Bool
    public var hasRaft: Bool
    public var hasRecorder: Bool
    public var hasAnyKey: Bool
    public var hasBook: Bool

    /// Starting heart bonus/penalty applied on top of the base 3 hearts.
    public var maxHeartsDifferential: Int

    public init(
        hdnStartingTriforcePieces: [Bool] = Array(repeating: false, count: 8),
        hasWhiteSword: Bool = false,
        hasMagicalSword: Bool = false,
        hasSilverArrow: Bool = false,
        hasBow: Bool = false,
        hasWand: Bool = false,
        hasRedCandle: Bool = false,
        hasBoomerang: Bool = false,
        hasMagicBoomerang: Bool = false,
        hasRedRing: Bool = false,
        hasPowerBracelet: Bool = false,
        hasLadder: Bool = false,
        hasRaft: Bool = false,
        hasRecorder: Bool = false,
        hasAnyKey: Bool = false,
        hasBook: Bool = false,
        maxHeartsDifferential: Int = 0
    ) {
        precondition(hdnStartingTriforcePieces.count == 8, "expected exactly 8 triforce pieces")
        self.hdnStartingTriforcePieces = hdnStartingTriforcePieces
        self.hasWhiteSword = hasWhiteSword
        self.hasMagicalSword = hasMagicalSword
        self.hasSilverArrow = hasSilverArrow
        self.hasBow = hasBow
        self.hasWand = hasWand
        self.hasRedCandle = hasRedCandle
        self.hasBoomerang = hasBoomerang
        self.hasMagicBoomerang = hasMagicBoomerang
        self.hasRedRing = hasRedRing
        self.hasPowerBracelet = hasPowerBracelet
        self.hasLadder = hasLadder
        self.hasRaft = hasRaft
        self.hasRecorder = hasRecorder
        self.hasAnyKey = hasAnyKey
        self.hasBook = hasBook
        self.maxHeartsDifferential = maxHeartsDifferential
    }

    /// A `Codable` snapshot of the seed's starting inventory for save/load (T-196). The
    /// reference persists these in `StartingItemsAndExtrasModel` (`SaveAndLoad.fs:94-151`).
    public struct State: Codable, Sendable {
        var hdnStartingTriforcePieces: [Bool]
        var hasWhiteSword, hasMagicalSword, hasSilverArrow, hasBow, hasWand, hasRedCandle: Bool
        var hasBoomerang, hasMagicBoomerang, hasRedRing, hasPowerBracelet, hasLadder: Bool
        var hasRaft, hasRecorder, hasAnyKey, hasBook: Bool
        var maxHeartsDifferential: Int
    }

    public var state: State {
        State(hdnStartingTriforcePieces: hdnStartingTriforcePieces,
              hasWhiteSword: hasWhiteSword, hasMagicalSword: hasMagicalSword,
              hasSilverArrow: hasSilverArrow, hasBow: hasBow, hasWand: hasWand,
              hasRedCandle: hasRedCandle, hasBoomerang: hasBoomerang,
              hasMagicBoomerang: hasMagicBoomerang, hasRedRing: hasRedRing,
              hasPowerBracelet: hasPowerBracelet, hasLadder: hasLadder, hasRaft: hasRaft,
              hasRecorder: hasRecorder, hasAnyKey: hasAnyKey, hasBook: hasBook,
              maxHeartsDifferential: maxHeartsDifferential)
    }

    public func restore(_ s: State) {
        // Guard the fixed-size array so a malformed save can't trip the init precondition.
        if s.hdnStartingTriforcePieces.count == 8 { hdnStartingTriforcePieces = s.hdnStartingTriforcePieces }
        hasWhiteSword = s.hasWhiteSword
        hasMagicalSword = s.hasMagicalSword
        hasSilverArrow = s.hasSilverArrow
        hasBow = s.hasBow
        hasWand = s.hasWand
        hasRedCandle = s.hasRedCandle
        hasBoomerang = s.hasBoomerang
        hasMagicBoomerang = s.hasMagicBoomerang
        hasRedRing = s.hasRedRing
        hasPowerBracelet = s.hasPowerBracelet
        hasLadder = s.hasLadder
        hasRaft = s.hasRaft
        hasRecorder = s.hasRecorder
        hasAnyKey = s.hasAnyKey
        hasBook = s.hasBook
        maxHeartsDifferential = s.maxHeartsDifferential
    }
}
