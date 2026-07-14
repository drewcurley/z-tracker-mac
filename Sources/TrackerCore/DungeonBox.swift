import Observation

/// Whether a box represents a dungeon *basement* item, for rendering the
/// stair icon (non-Hidden-Dungeon-Numbers). Ported from `StairKind`
/// (`TrackerModel.fs:587-591`). Basement-ness depends on the vanilla dungeon
/// shape, which varies by quest — hence the `likeL2`/`likeL3` quest-
/// conditional kinds.
public enum StairKind: Sendable {
    case never
    case always
    /// 2nd box of 2 is a basement in 2nd quest.
    case likeL2
    /// 2nd box of 3 is a basement in 1st quest.
    case likeL3
}

/// Which dungeon (and which item slot) a box belongs to, for deciding what
/// blocker/stair projections to render in it. Ported from `BoxOwner`
/// (`TrackerModel.fs:593-597`).
public enum BoxOwner: Sendable, Equatable {
    /// `(dungeonIndex 0…8, nth 0…2)`.
    case dungeonIndexAndNth(Int, Int)
    /// The shared third box of dungeon 1 or 4 (quest-dependent).
    case dungeon1or4
    /// A box that belongs to no dungeon (e.g. the coast item).
    case none
}

/// Tri-state for whether the player has actually obtained the item known to
/// be at a `Box`'s location. Ported from the reference's `PlayerHas`
/// (`Zelda1RandoTools/Z1R_Tracker/Z1R_Tracker/TrackerModel.fs:582-585`).
///
/// The raw values pin the reference's `AsInt()`/`FromInt()` mapping exactly
/// (`NO=0`, `YES=1`, `SKIPPED=2`) so a future save/load layer round-trips
/// identically — the same discipline `TakeAnyHeartState` (T-012) used for
/// its own reference tri-state.
public enum PlayerHas: Int, Sendable, CaseIterable {
    case no = 0
    case yes = 1
    case skipped = 2
}

/// One dungeon (or standalone) item slot: what the player *knows* is at a
/// location (`cellCurrent`) plus whether they *have* it (`playerHas`).
/// Ported from the reference's `Box` class
/// (`TrackerModel.fs:598-662`).
///
/// **Scope (T-013): possession + completion model only.** The reference's
/// `Box` embeds a `Cell(allItemWithHeartShuffleChoiceDomain)` whose
/// `ChoiceDomain` enforces cross-box item max-uses (Ladder appears once,
/// Heart Container up to nine, etc.) and drives the item-picker's
/// `Next()`/`Prev()` cycling. That machinery is **not** ported here: the
/// completion predicate (`isDone`) needs only "is a value known"
/// (`cellCurrent != -1`), and the overworld map set the precedent of
/// deferring `ChoiceDomain` (its `OverworldGrid` uses a typed mark with no
/// cross-cell enforcement either). `cellCurrent` is therefore a plain item
/// index matching the reference's `Cell.Current()` return exactly (`-1`
/// empty, `0...14` = an `ITEMS.itemNamesAndCounts` index). The full
/// `ChoiceDomain`/`Cell` port + item-picker cycling lands with its first
/// real consumer (item identities in T-014, the box picker UI in T-015).
///
/// **Also deferred (T-016):** the `StairKind`/`BoxOwner` constructor
/// arguments and `CurrentlyHasBasementStair` — those are Hidden-Dungeon-
/// -Numbers / basement-icon *rendering* metadata, explicitly out of scope
/// for the core model (see `tasks/T-013.md`).
///
/// **`@Observable` replaces the reference's manual `Event`/`LastChangedTime`
/// plumbing** — mutating `cellCurrent`/`playerHas` notifies observers
/// automatically, the pattern already used by `OverworldGrid` and
/// `PlayerProgressAndTakeAnyHearts`. The reference's
/// `dungeonsAndBoxesLastChangedTime.SetNow()` (a save-dirty / animation
/// timestamp) is a cross-cutting save concern with no T-013 consumer, so it
/// is deferred with the persistence layer.
@Observable
public final class Box {
    /// The number of valid item identities (`ITEMS.count`, from
    /// `TrackerModel.fs:179-194`). A `cellCurrent` is either `-1` (empty) or
    /// in `0..<itemCount`. Identity meaning (which index is which item) is
    /// assigned by `ITEMS` and consumed by `PlayerComputedStateSummary`
    /// (both T-014).
    public static let itemCount = ITEMS.count

    /// `-1` = empty (nothing known here yet); `0...14` = a known item index.
    /// Mirrors the reference's `Cell.Current()` value space exactly.
    public private(set) var cellCurrent: Int

    /// Whether the player has obtained (or intentionally skipped) the item
    /// known to be here.
    public private(set) var playerHas: PlayerHas

    /// Basement-stair rendering metadata (T-016.2). `stair` is the non-HDN
    /// basement kind; `owner` identifies the dungeon/slot. Consumed by
    /// `DungeonTrackerInstance.currentlyHasBasementStair(_:)` — the reference
    /// exposes this as a `Box` member, but this port computes it on the
    /// instance (which has the `kind`/`isSecondQuestDungeons`/label context
    /// the HDN branch needs). Both were deferred from T-013.
    public let stair: StairKind
    public let owner: BoxOwner

    public init(
        cellCurrent: Int = -1,
        playerHas: PlayerHas = .no,
        stair: StairKind = .never,
        owner: BoxOwner = .none
    ) {
        precondition(
            cellCurrent == -1 || (0..<Self.itemCount).contains(cellCurrent),
            "cellCurrent \(cellCurrent) out of range (-1 or 0..<\(Self.itemCount))"
        )
        self.cellCurrent = cellCurrent
        self.playerHas = playerHas
        self.stair = stair
        self.owner = owner
    }

    /// The player knows the item here AND has gotten or intentionally
    /// skipped it. The core predicate consumed by `Dungeon.isComplete` and
    /// (in T-014) `PlayerComputedStateSummary`. Ported from `IsDone()`
    /// (`TrackerModel.fs:662`).
    public var isDone: Bool {
        cellCurrent != -1 && playerHas != .no
    }

    /// A slot the player has explicitly emptied: no item known and not
    /// obtained. Ported from `IsEmptyRedBox` (`TrackerModel.fs:605`); feeds
    /// the `DungeonTrackerInstance.allBoxProgress` UI meter.
    public var isEmptyRedBox: Bool {
        playerHas == .no && cellCurrent == -1
    }

    /// Sets both the known item and the possession state together. Ported
    /// from `Set(v, ph)` (`TrackerModel.fs:646-651`).
    public func set(cellCurrent: Int, playerHas: PlayerHas) {
        precondition(
            cellCurrent == -1 || (0..<Self.itemCount).contains(cellCurrent),
            "cellCurrent \(cellCurrent) out of range (-1 or 0..<\(Self.itemCount))"
        )
        self.cellCurrent = cellCurrent
        self.playerHas = playerHas
    }

    /// Sets only the possession tri-state, leaving the known item unchanged.
    /// Ported from `SetPlayerHas(v)` (`TrackerModel.fs:656-659`).
    public func setPlayerHas(_ playerHas: PlayerHas) {
        self.playerHas = playerHas
    }
}
