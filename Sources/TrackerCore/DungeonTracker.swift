import Observation

/// Which flavor of dungeon tracking is in effect. Ported from
/// `DungeonTrackerInstanceKind` (`TrackerModel.fs:667-670`).
///
/// Both modes' **model core** is implemented (box counts, completion,
/// triforce indexing, `color`/`labelChar` state — T-013 for `.default`,
/// T-016.1 for `.hideDungeonNumbers`). HDN's *rendering* pieces — the
/// basement-stair metadata (`StairKind`/`BoxOwner`/`CurrentlyHasBasement-
/// Stair`) and the label/color-assignment UI — are deferred until the
/// dungeon-tracker room-grid UI they feed exists (T-016.2/T-016.3).
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

    /// Hidden-Dungeon-Numbers player-assigned color (`0xRRGGBB`, default 0)
    /// and label char (`"?"`, `"1"…"8"`, default `"?"`). Meaningful only in
    /// `.hideDungeonNumbers` mode; "just ignore this for dungeon 9"
    /// (`id == 8`), per the reference. Ported from `Color`/`LabelChar`
    /// (`TrackerModel.fs:816-818`). The assignment UI is T-016.3.
    public var color: Int
    public var labelChar: Character

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
        self.color = 0
        self.labelChar = "?"
        let kind = instance.kind
        self.baseBoxes = (0..<numBoxes).map { j in
            Box(stair: Dungeon.stairKind(id: id, j: j, kind: kind),
                owner: .dungeonIndexAndNth(id, j))
        }
        self.instance = instance
    }

    /// The basement `StairKind` for box `j` of dungeon `id`. Ported from the
    /// box-construction table (`TrackerModel.fs:742-753`): HDN uses `.never`
    /// (basements are computed from `labelChar` instead); DEFAULT keys on the
    /// vanilla dungeon shapes.
    private static func stairKind(id: Int, j: Int, kind: DungeonTrackerInstanceKind) -> StairKind {
        switch kind {
        case .hideDungeonNumbers:
            return .never
        case .default:
            if id == 8 || (j == 1 && !(id == 0 || id == 1 || id == 2)) || j == 2 {
                return .always
            } else if j == 1 && id == 1 {
                return .likeL2
            } else if j == 1 && id == 2 {
                return .likeL3
            } else {
                return .never
            }
        }
    }

    /// Toggles triforce possession. Ported from `ToggleTriforce()`
    /// (`TrackerModel.fs:774`).
    public func toggleTriforce() {
        playerHasTriforce.toggle()
    }

    /// The dungeon's effective box list. In DEFAULT mode, dungeon 1 (first
    /// quest) or dungeon 4 (second quest) gets the shared `finalBoxOf1Or4`
    /// appended as its third box. In HDN mode there is no shared box — every
    /// dungeon uses its own fixed `baseBoxes`. Ported from `Boxes`
    /// (`TrackerModel.fs:779-787`).
    public var boxes: [Box] {
        switch instance.kind {
        case .hideDungeonNumbers:
            return baseBoxes
        case .default:
            if (id == 0 && !instance.isSecondQuestDungeons)
                || (id == 3 && instance.isSecondQuestDungeons) {
                return baseBoxes + [instance.finalBoxOf1Or4]
            }
            return baseBoxes
        }
    }

    /// Whether this dungeon is complete. Ported from `IsComplete`
    /// (`TrackerModel.fs:789-813`).
    /// - DEFAULT: triforce held AND every effective box done.
    /// - HDN: triforce held AND (all 3 boxes done, OR exactly 2 done when
    ///   this dungeon's assigned `labelChar` is a known "two-boxer" — the
    ///   quest-dependent whitelist `"123567"` (2nd quest) / `"234567"`
    ///   (1st quest), since in HDN you may not know a dungeon's box count
    ///   until you've identified it).
    public var isComplete: Bool {
        switch instance.kind {
        case .default:
            return playerHasTriforce && boxes.allSatisfy { $0.isDone }
        case .hideDungeonNumbers:
            guard playerHasTriforce else { return false }
            let numBoxesDone = baseBoxes.reduce(0) { $0 + ($1.isDone ? 1 : 0) }
            let twoBoxers = instance.isSecondQuestDungeons ? "123567" : "234567"
            return numBoxesDone == 3 || (numBoxesDone == 2 && twoBoxers.contains(labelChar))
        }
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
        self.kind = kind
        self.isSecondQuestDungeons = isSecondQuestDungeons
        self.finalBoxOf1Or4 = Box(stair: .always, owner: .dungeon1or4)
        self.ladderBox = Box(playerHas: .skipped, stair: .never, owner: .none)
        self.armosBox = Box(playerHas: .skipped, stair: .never, owner: .none)
        self.sword2Box = Box(playerHas: .skipped, stair: .never, owner: .none)
        self.dungeons = []
        // Base box counts, transcribed exactly from `makeDungeons()`
        // (`TrackerModel.fs:682-704`):
        //   DEFAULT — dungeons 1–7 and 9 have 2, dungeon 8 has 3
        //             (the shared `finalBoxOf1Or4` is added per-quest in
        //              `Dungeon.boxes`).
        //   HDN     — dungeons 1–8 have 3, dungeon 9 has 2.
        let baseBoxCounts: [Int]
        switch kind {
        case .default: baseBoxCounts = [2, 2, 2, 2, 2, 2, 2, 3, 2]
        case .hideDungeonNumbers: baseBoxCounts = [3, 3, 3, 3, 3, 3, 3, 3, 2]
        }
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

    /// The 8-element "does the player have this triforce piece" array. Ported
    /// from `GetTriforceHaves()` (`TrackerModel.fs:823-836`).
    /// - DEFAULT: dungeon `i` → piece `i` (the `hdnStartingTriforcePieces`
    ///   argument is ignored, matching the reference).
    /// - HDN: a dungeon contributes piece `labelChar - '1'` only once the
    ///   player has both its triforce *and* has identified it (`labelChar`
    ///   in `"1"…"8"`); plus any HDN starting triforce pieces
    ///   (`startingItemsAndExtras.HDNStartingTriforcePieces`, index `i` →
    ///   piece `i`).
    public func getTriforceHaves(hdnStartingTriforcePieces: [Bool] = Array(repeating: false, count: 8)) -> [Bool] {
        switch kind {
        case .default:
            return (0...7).map { dungeons[$0].playerHasTriforce }
        case .hideDungeonNumbers:
            precondition(hdnStartingTriforcePieces.count == 8, "expected 8 HDN starting pieces")
            var haves = Array(repeating: false, count: 8)
            for i in 0...7 {
                let d = dungeons[i]
                if d.playerHasTriforce, let n = triforceIndex(for: d.labelChar) {
                    haves[n] = true
                }
                if hdnStartingTriforcePieces[i] {
                    haves[i] = true
                }
            }
            return haves
        }
    }

    /// Whether `box` currently renders a basement-stair icon. Ported from
    /// `Box.CurrentlyHasBasementStair` (`TrackerModel.fs:607-632`) — computed
    /// here rather than on `Box` because the HDN branch needs this instance's
    /// `kind`/`isSecondQuestDungeons` and the owning dungeon's `labelChar`.
    /// In HDN, basement-ness is keyed on the identified dungeon's label +
    /// quest + box index; in DEFAULT, on the box's `StairKind` + quest.
    public func currentlyHasBasementStair(_ box: Box) -> Bool {
        switch kind {
        case .hideDungeonNumbers:
            guard case let .dungeonIndexAndNth(i, n) = box.owner else { return false }
            if i == 8 { return true } // dungeon 9 has all basements
            let lc = dungeons[i].labelChar
            if isSecondQuestDungeons {
                switch lc {
                case "1", "3": return false
                case "2", "5", "6", "7": return n == 1
                case "4", "8": return n == 1 || n == 2
                default: return false
                }
            } else {
                switch lc {
                case "1": return n == 2
                case "2": return false
                case "3", "4", "5", "6", "7": return n == 1
                case "8": return n == 1 || n == 2
                default: return false
                }
            }
        case .default:
            switch box.stair {
            case .likeL2: return isSecondQuestDungeons
            case .likeL3: return !isSecondQuestDungeons
            case .always: return true
            case .never: return false
            }
        }
    }

    /// Maps an HDN label char `"1"…"8"` to triforce-piece index `0…7`, or
    /// `nil` for an unidentified (`"?"`) or out-of-range label.
    private func triforceIndex(for labelChar: Character) -> Int? {
        guard let ascii = labelChar.asciiValue,
              let one = Character("1").asciiValue,
              let eight = Character("8").asciiValue,
              ascii >= one && ascii <= eight else { return nil }
        return Int(ascii - one)
    }
}
