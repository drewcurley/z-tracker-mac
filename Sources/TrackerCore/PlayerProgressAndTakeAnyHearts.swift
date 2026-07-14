import Observation

/// One "Take Any" heart-cave slot's state — there are 4 such overworld
/// locations. The reference used a raw `int` tri-state (`TrackerModel.fs:494`:
/// "0 = untaken, 1 = taken heart, 2 = taken potion/candle").
///
/// **Beyond the reference (T-031):** the combined "potion/candle" state is
/// split into distinct `takenPotion` (2, preserving the reference's raw value)
/// and `takenCandle` (3), so the tracker can record which was taken — the
/// Extra Candles randomizer option makes a blue candle a possible take-any
/// item alongside the red potion and the heart.
public enum TakeAnyHeartState: Int, Sendable, CaseIterable {
    case untaken = 0
    case takenHeart = 1
    case takenPotion = 2
    case takenCandle = 3
}

/// Runtime-acquired player progress that isn't tied to a spatial dungeon-
/// box location — things the player toggles directly (the reference
/// app's "upper right portion of the UI"). Ported field-for-field from
/// `PlayerProgressAndTakeAnyHearts`
/// (`Zelda1RandoTools/Z1R_Tracker/Z1R_Tracker/TrackerModel.fs:492-532`);
/// every field defaults to `false`/`.untaken`, confirmed against
/// `PlayerProgressAndTakeAnyHeartsModel`'s save/load shape
/// (`SaveAndLoad.fs:56-92`).
@Observable
public final class PlayerProgressAndTakeAnyHearts {
    public var takeAnyHearts: [TakeAnyHeartState]

    public var hasBoomBook: Bool
    public var hasWoodSword: Bool
    public var hasWoodArrow: Bool
    public var hasBlueRing: Bool
    public var hasBlueCandle: Bool
    public var hasMagicalSword: Bool
    public var hasDefeatedGanon: Bool
    public var hasRescuedZelda: Bool
    public var hasBombs: Bool

    public init(
        takeAnyHearts: [TakeAnyHeartState] = Array(repeating: .untaken, count: 4),
        hasBoomBook: Bool = false,
        hasWoodSword: Bool = false,
        hasWoodArrow: Bool = false,
        hasBlueRing: Bool = false,
        hasBlueCandle: Bool = false,
        hasMagicalSword: Bool = false,
        hasDefeatedGanon: Bool = false,
        hasRescuedZelda: Bool = false,
        hasBombs: Bool = false
    ) {
        precondition(takeAnyHearts.count == 4, "expected exactly 4 take-any heart slots")
        self.takeAnyHearts = takeAnyHearts
        self.hasBoomBook = hasBoomBook
        self.hasWoodSword = hasWoodSword
        self.hasWoodArrow = hasWoodArrow
        self.hasBlueRing = hasBlueRing
        self.hasBlueCandle = hasBlueCandle
        self.hasMagicalSword = hasMagicalSword
        self.hasDefeatedGanon = hasDefeatedGanon
        self.hasRescuedZelda = hasRescuedZelda
        self.hasBombs = hasBombs
    }

    /// Ported from `ResetAll()` (`TrackerModel.fs:520-531`) — a full reset
    /// used by the reference app's "groundhog/routers" restart feature.
    public func resetAll() {
        takeAnyHearts = Array(repeating: .untaken, count: 4)
        hasBoomBook = false
        hasWoodSword = false
        hasWoodArrow = false
        hasBlueRing = false
        hasBlueCandle = false
        hasMagicalSword = false
        hasDefeatedGanon = false
        hasRescuedZelda = false
        hasBombs = false
    }
}
