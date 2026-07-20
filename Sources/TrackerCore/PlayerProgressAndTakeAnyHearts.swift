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
public enum TakeAnyHeartState: Int, Sendable, CaseIterable, Codable {
    case untaken = 0
    case takenHeart = 1
    case takenPotion = 2
    case takenCandle = 3

    /// The state advanced by `delta`, wrapping over all four states
    /// (untaken → heart → potion → candle → untaken). Shared by the overworld
    /// take-any tiles and the Items-group heart boxes so they cycle identically.
    public func cycled(by delta: Int) -> TakeAnyHeartState {
        let n = TakeAnyHeartState.allCases.count
        return TakeAnyHeartState(rawValue: ((rawValue + delta) % n + n) % n) ?? self
    }
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
    /// Taking the candle from a take-any cave means you now hold the blue candle,
    /// so auto-activate it in the items area (T-103). Covers every write path
    /// (overworld tile, Items-group heart box) since they all mutate this array.
    /// Only turns it on — a candle held from elsewhere isn't cleared.
    public var takeAnyHearts: [TakeAnyHeartState] {
        didSet { if takeAnyHearts.contains(.takenCandle) { hasBlueCandle = true } }
    }

    public var hasBoomBook: Bool
    public var hasWoodSword: Bool
    public var hasWoodArrow: Bool
    public var hasBlueRing: Bool
    public var hasBlueCandle: Bool
    public var hasMagicalSword: Bool
    public var hasDefeatedGanon: Bool
    public var hasRescuedZelda: Bool
    public var hasBombs: Bool
    /// Obtained the meat/bait (T-035.10). Beyond the reference, which never
    /// tracks meat (its HUD always greys it out); the user wants an explicit
    /// toggle so the Progress HUD's meat slot can light up.
    public var hasMeat: Bool

    /// A `Codable` snapshot of all progress for save/load (T-164).
    public struct State: Codable, Sendable {
        var takeAnyHearts: [TakeAnyHeartState]
        var hasBoomBook, hasWoodSword, hasWoodArrow, hasBlueRing, hasBlueCandle: Bool
        var hasMagicalSword, hasDefeatedGanon, hasRescuedZelda, hasBombs, hasMeat: Bool
    }
    public var state: State {
        State(takeAnyHearts: takeAnyHearts, hasBoomBook: hasBoomBook, hasWoodSword: hasWoodSword,
              hasWoodArrow: hasWoodArrow, hasBlueRing: hasBlueRing, hasBlueCandle: hasBlueCandle,
              hasMagicalSword: hasMagicalSword, hasDefeatedGanon: hasDefeatedGanon,
              hasRescuedZelda: hasRescuedZelda, hasBombs: hasBombs, hasMeat: hasMeat)
    }
    public func restore(_ s: State) {
        hasBoomBook = s.hasBoomBook; hasWoodSword = s.hasWoodSword; hasWoodArrow = s.hasWoodArrow
        hasBlueRing = s.hasBlueRing; hasBlueCandle = s.hasBlueCandle; hasMagicalSword = s.hasMagicalSword
        hasDefeatedGanon = s.hasDefeatedGanon; hasRescuedZelda = s.hasRescuedZelda
        hasBombs = s.hasBombs; hasMeat = s.hasMeat
        if s.takeAnyHearts.count == 4 { takeAnyHearts = s.takeAnyHearts }
    }

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
        hasBombs: Bool = false,
        hasMeat: Bool = false
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
        self.hasMeat = hasMeat
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
        hasMeat = false
    }
}
