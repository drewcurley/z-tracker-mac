import Observation

/// Which flavor of dungeon tracking is in effect. Ported from
/// `DungeonTrackerInstanceKind` (`TrackerModel.fs:667-670`).
///
/// **T-013 implements `.default` only.** `.hideDungeonNumbers` is modeled
/// here (so the public shape matches the reference) but constructing an
/// instance with it is guarded off until T-016 builds the HDN box-count /
/// completion / labeling variant — an honest scope boundary rather than a
/// silently-wrong code path.
public enum DungeonTrackerInstanceKind: Sendable {
    case `default`
    case hideDungeonNumbers
}

/// One of the nine dungeons: triforce possession, a map flag, and its item
/// boxes. Ported from the reference's `Dungeon` class
/// (`TrackerModel.fs:739-818`), DEFAULT mode only.
///
/// **`@Observable` replaces the reference's five `Event<_>` change
/// publishers** — SwiftUI observation notifies on mutation automatically
/// (the established pattern here). `isComplete` is a plain computed property
/// rather than the reference's cached/reentrancy-guarded member: that guard
/// existed only because reading `IsComplete` *fired an event* that could
/// recurse; a pure computed getter has no such hazard and is behaviorally
/// identical.
///
/// **Deferred out of T-013:** `color`/`labelChar` (HDN labeling — T-016),
/// `playerCanSeeMapOfThisDungeon` (needs book/atlas state — T-014/T-015),
/// and `hasBeenLocated` (needs the overworld map-square domain — T-015).
/// `playerHasMap` is a plain stored flag with no such dependency and is
/// ported now.
@Observable
public final class Dungeon {
    /// `0...8` for dungeons 1–9.
    public let id: Int

    /// Just ignore this for dungeon 9 (`id == 8`) — mirrors the reference's
    /// note; dungeon 9 has no triforce piece.
    public var playerHasTriforce: Bool

    /// Whether the player has this dungeon's map item. (The book/atlas does
    /// not affect this flag — that interaction is `playerCanSeeMapOfThis-
    /// Dungeon`, deferred to T-014/T-015.)
    public var playerHasMap: Bool

    /// The dungeon's own fixed item boxes (2 or 3), before the quest-
    /// dependent shared `finalBoxOf1Or4` is appended. Prefer `boxes`.
    public let baseBoxes: [Box]

    /// Back-reference to the owning instance, read for `kind`,
    /// `isSecondQuestDungeons`, and the shared `finalBoxOf1Or4`. `unowned`
    /// because the instance owns every dungeon (no retain cycle risk; the
    /// dungeon never outlives its instance).
    private unowned let instance: DungeonTrackerInstance

    init(id: Int, numBoxes: Int, instance: DungeonTrackerInstance) {
        self.id = id
        self.playerHasTriforce = false
        self.playerHasMap = false
        self.baseBoxes = (0..<numBoxes).map { _ in Box() }
        self.instance = instance
    }

    /// Toggles triforce possession. Ported from `ToggleTriforce()`
    /// (`TrackerModel.fs:774`).
    public func toggleTriforce() {
        playerHasTriforce.toggle()
    }

    /// The dungeon's effective box list. In DEFAULT mode, dungeon 1 (first
    /// quest) or dungeon 4 (second quest) gets the shared `finalBoxOf1Or4`
    /// appended as its third box. Ported from `Boxes`
    /// (`TrackerModel.fs:779-787`).
    public var boxes: [Box] {
        if (id == 0 && !instance.isSecondQuestDungeons)
            || (id == 3 && instance.isSecondQuestDungeons) {
            return baseBoxes + [instance.finalBoxOf1Or4]
        }
        return baseBoxes
    }

    /// DEFAULT-mode completion: the player has this dungeon's triforce AND
    /// every effective box is done. Ported from `IsComplete`
    /// (`TrackerModel.fs:789-813`, DEFAULT branch). HDN-mode completion
    /// (2-vs-3-box quest-dependent) is T-016.
    public var isComplete: Bool {
        playerHasTriforce && boxes.allSatisfy { $0.isDone }
    }
}

/// Owns the nine `Dungeon` objects plus the three standalone item boxes,
/// and exposes the flattened `allBoxes()` list. Ported from
/// `DungeonTrackerInstance` (`TrackerModel.fs:673-737`), DEFAULT mode only.
///
/// The reference reaches every `Dungeon` back to a mutable
/// `static TheDungeonTrackerInstance` singleton and reads a mutable global
/// `TrackerModel.IsSecondQuestDungeons`. This port replaces both with plain
/// instance state: each `Dungeon` holds an `unowned` reference to its owner,
/// and `isSecondQuestDungeons` is a settable property here (kept in sync by
/// whatever owns the instance) — no Swift globals, unit-testable in
/// isolation, behaviorally identical.
@Observable
public final class DungeonTrackerInstance {
    public let kind: DungeonTrackerInstanceKind

    /// Drives which dungeon (1 or 4) carries the third `finalBoxOf1Or4`
    /// box. Mirrors the reference's `TrackerModel.IsSecondQuestDungeons`
    /// option (default `false`). Wiring the settings-panel checkbox that
    /// toggles it is a later UI task; the model just reads it.
    public var isSecondQuestDungeons: Bool

    /// The shared third box of dungeon 1 or 4 (`StairKind.Always` in the
    /// reference; stair metadata deferred to T-016). Only meaningful in
    /// DEFAULT mode. Ported from `finalBoxOf1Or4`
    /// (`TrackerModel.fs:675`).
    public let finalBoxOf1Or4: Box

    /// The three standalone boxes that don't belong to any dungeon, each
    /// pre-set to `.skipped`. Ported from the module-level `ladderBox`,
    /// `armosBox`, `sword2Box` (`TrackerModel.fs:664-666`) — confirmed
    /// during T-012 scoping to be plain `Box` instances, not a distinct
    /// subsystem.
    public let ladderBox: Box
    public let armosBox: Box
    public let sword2Box: Box

    public private(set) var dungeons: [Dungeon]

    public init(
        kind: DungeonTrackerInstanceKind = .default,
        isSecondQuestDungeons: Bool = false
    ) {
        precondition(
            kind == .default,
            "HIDE_DUNGEON_NUMBERS is deferred to T-016; construct with .default"
        )
        self.kind = kind
        self.isSecondQuestDungeons = isSecondQuestDungeons
        self.finalBoxOf1Or4 = Box()
        self.ladderBox = Box(playerHas: .skipped)
        self.armosBox = Box(playerHas: .skipped)
        self.sword2Box = Box(playerHas: .skipped)
        self.dungeons = []
        // DEFAULT-mode base box counts, transcribed exactly from
        // `makeDungeons()` (`TrackerModel.fs:695-704`): dungeons 1–7 and 9
        // have 2 base boxes, dungeon 8 has 3.
        let baseBoxCounts = [2, 2, 2, 2, 2, 2, 2, 3, 2]
        self.dungeons = baseBoxCounts.enumerated().map { index, count in
            Dungeon(id: index, numBoxes: count, instance: self)
        }
    }

    /// `dungeons[i]`, `0...8`. Ported from `Dungeons(i)`
    /// (`TrackerModel.fs:730`) / the module-level `GetDungeon(i)`.
    public func dungeon(_ i: Int) -> Dungeon { dungeons[i] }

    /// Every box, flattened: each dungeon's effective boxes (including the
    /// quest-dependent `finalBoxOf1Or4`) followed by the three standalone
    /// boxes. 23 total in DEFAULT mode (19 base + 1 finalBox + 3 standalone).
    /// Ported from `AllBoxes()` / `all()` (`TrackerModel.fs:712-721`).
    public func allBoxes() -> [Box] {
        dungeons.flatMap { $0.boxes } + [ladderBox, armosBox, sword2Box]
    }

    /// A 0...1 UI-progress float: fraction of boxes that are no longer
    /// "empty red", capped at 1.0. Ported from `allBoxProgress`
    /// (`TrackerModel.fs:722-729`) — divisor 20 and the cap are the
    /// reference's ("23 items exist; be max red when few left").
    public var allBoxProgress: Double {
        let touched = allBoxes().reduce(0) { $0 + ($1.isEmptyRedBox ? 0 : 1) }
        return min(Double(touched) / 20.0, 1.0)
    }

    /// The 8-element "does the player have this triforce piece" array,
    /// DEFAULT-mode indexing (dungeon `i` → piece `i`). Ported from
    /// `GetTriforceHaves()` (`TrackerModel.fs:823-836`, DEFAULT branch). The
    /// HDN-mode variant (label-char driven + HDN starting pieces) is T-016.
    public func getTriforceHaves() -> [Bool] {
        (0...7).map { dungeons[$0].playerHasTriforce }
    }
}
