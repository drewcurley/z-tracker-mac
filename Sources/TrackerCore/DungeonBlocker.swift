import Observation

/// A player annotation of *why* they got stuck in a dungeon — missing an
/// item or a combat obstacle — so the tracker can later remind them the
/// blocker is stale (item since acquired) and they can return. Ported from
/// the reference's `DungeonBlocker` union
/// (`Zelda1RandoTools/Z1R_Tracker/Z1R_Tracker/TrackerModel.fs:1147-1248`).
///
/// The `maybe*` variants are "might need this" (softer) versions;
/// `hardCanonical` collapses each back to its definite form. `allCases`
/// order is the reference's `All` array order exactly, so `next()`/`prev()`
/// cycle identically.
public enum DungeonBlocker: String, CaseIterable, Sendable, Codable {
    case bowAndArrow
    case recorder
    case ladder
    case key
    case bait
    case money      // money or life room? bomb upgrade?
    case bomb
    case combat     // need better weapon/armor
    case maybeBowAndArrow
    case maybeRecorder
    case maybeLadder
    case maybeKey
    case maybeBait
    case maybeMoney
    case maybeBomb
    case nothing

    /// Collapses a `maybe*` variant to its definite form. Ported from
    /// `HardCanonical()` (`TrackerModel.fs:1219-1228`).
    public var hardCanonical: DungeonBlocker {
        switch self {
        case .maybeBowAndArrow: .bowAndArrow
        case .maybeRecorder: .recorder
        case .maybeLadder: .ladder
        case .maybeBait: .bait
        case .maybeKey: .key
        case .maybeBomb: .bomb
        case .maybeMoney: .money
        default: self
        }
    }

    /// A `maybe*` (uncertain) blocker — rendered with the green→red gradient
    /// border rather than the solid definite one (T-019.2).
    public var isMaybe: Bool { hardCanonical != self }

    /// Whether the player *could still* be blocked by this, given current
    /// derived state — i.e. the annotation isn't yet stale. Ported from
    /// `PlayerCouldBeBlockedByThis()` (`TrackerModel.fs:1188-1194`): only
    /// ladder/recorder/bow+arrow/key have a staleness check (the item can be
    /// acquired); everything else (combat, bait, money, bomb, nothing)
    /// returns `true`.
    public func playerCouldBeBlockedByThis(_ playerState: PlayerComputedStateSummary) -> Bool {
        switch hardCanonical {
        case .ladder: !playerState.haveLadder
        case .recorder: !playerState.haveRecorder
        case .bowAndArrow: !(playerState.haveBow && playerState.arrowLevel > 0)
        case .key: !playerState.haveAnyKey
        default: true
        }
    }

    /// The save/hotkey identifier. Ported from `AsHotKeyName()`
    /// (`TrackerModel.fs:1196-1218`) — these exact strings are the save-file
    /// blocker `Kind` values.
    public var asHotKeyName: String {
        switch self {
        case .combat: "Blocker_Combat"
        case .bowAndArrow: "Blocker_Bow_And_Arrow"
        case .recorder: "Blocker_Recorder"
        case .ladder: "Blocker_Ladder"
        case .bait: "Blocker_Bait"
        case .key: "Blocker_Key"
        case .bomb: "Blocker_Bomb"
        case .money: "Blocker_Money"
        case .maybeBowAndArrow: "Blocker_Maybe_Bow_And_Arrow"
        case .maybeRecorder: "Blocker_Maybe_Recorder"
        case .maybeLadder: "Blocker_Maybe_Ladder"
        case .maybeBait: "Blocker_Maybe_Bait"
        case .maybeKey: "Blocker_Maybe_Key"
        case .maybeBomb: "Blocker_Maybe_Bomb"
        case .maybeMoney: "Blocker_Maybe_Money"
        case .nothing: "Blocker_Nothing"
        }
    }

    /// Reverse of `asHotKeyName`; unknown names map to `.nothing`. Ported
    /// from `FromHotKeyName()` (`TrackerModel.fs:1181-1186`).
    public static func fromHotKeyName(_ hotKeyName: String) -> DungeonBlocker {
        allCases.first { $0.asHotKeyName == hotKeyName } ?? .nothing
    }

    /// The multi-line UI label. Ported from `DisplayDescription()`
    /// (`TrackerModel.fs:1229-1246`).
    public var displayDescription: String {
        switch self {
        case .combat: "Need better\nweapon/armor"
        case .bowAndArrow: "Need bow&arrow"
        case .maybeBowAndArrow: "Might need bow&arrow"
        case .recorder: "Need recorder"
        case .maybeRecorder: "Might need recorder"
        case .ladder: "Need ladder"
        case .maybeLadder: "Might need ladder"
        case .bait: "Need meat"
        case .maybeBait: "Might need meat"
        case .key: "Need keys"
        case .maybeKey: "Might need keys"
        case .bomb: "Need bombs"
        case .maybeBomb: "Might need bombs"
        case .money: "Need money\n(e.g. mugger)"
        case .maybeMoney: "Might need money\n(e.g. mugger)"
        case .nothing: "Unmarked"
        }
    }

    /// Next/previous in the `allCases` cycle. Ported from `Next()`/`Prev()`
    /// (`TrackerModel.fs:1247-1254`).
    public var next: DungeonBlocker {
        let all = Self.allCases
        return all[(all.firstIndex(of: self)! + 1) % all.count]
    }

    public var prev: DungeonBlocker {
        let all = Self.allCases
        return all[(all.count + all.firstIndex(of: self)! - 1) % all.count]
    }
}

/// The specific way a `combat` blocker can be resolved. Ported from
/// `CombatUnblockerDetail` (`TrackerModel.fs:1250-1253`).
public enum CombatUnblockerDetail: String, CaseIterable, Sendable, Codable {
    case betterSword
    case betterArmor
    case wand
}

/// Which of a dungeon's UI elements a blocker annotation attaches to —
/// map, compass, triforce, box1, box2, box3 (6 flags). Ported from
/// `DungeonBlockerAppliesTo` (`TrackerModel.fs:1254-1256`).
public struct DungeonBlockerAppliesTo: Sendable, Equatable {
    public static let max = 6
    /// `[map, compass, triforce, box1, box2, box3]`.
    public var data: [Bool]

    public init() {
        data = Array(repeating: false, count: Self.max)
    }

    /// Named indices into `data` (the reference's fixed element order). Box `n`
    /// (0-based) is `box0 + n`.
    public enum Element: Int, CaseIterable, Sendable {
        case map = 0, compass, triforce, box0, box1, box2
        /// The applies-to element for item box `n` (0-based).
        public static func box(_ n: Int) -> Int { Element.box0.rawValue + n }
    }
}

/// The 8×3 grid of dungeon blockers (up to 3 per dungeon) plus the parallel
/// applies-to grid. Ported from `DungeonBlockersContainer`
/// (`TrackerModel.fs:1257-1273`). The reference's `static` singleton +
/// change event + load-ignore flag become plain `@Observable` instance
/// state (mutations notify automatically); the load-ignore flag is a
/// save/load optimization deferred with persistence.
@Observable
public final class DungeonBlockersContainer {
    public static let maxBlockersPerDungeon = 3
    /// Nine, not the reference's eight (T-090): the user tracks blockers for
    /// Level 9 too (what's preventing progress there). A deliberate deviation —
    /// the reference excludes L9; the save format (deferred) will need the extra slot.
    public static let dungeonCount = 9

    private var blockers: [DungeonBlocker]
    private var appliesTo: [DungeonBlockerAppliesTo]

    public init() {
        blockers = Array(repeating: .nothing, count: Self.dungeonCount * Self.maxBlockersPerDungeon)
        appliesTo = (0..<(Self.dungeonCount * Self.maxBlockersPerDungeon)).map { _ in DungeonBlockerAppliesTo() }
    }

    /// `i` = dungeon index (0–7), `j` = which blocker slot (0–2).
    public func dungeonBlocker(dungeon i: Int, slot j: Int) -> DungeonBlocker {
        blockers[Self.index(i, j)]
    }

    public func setDungeonBlocker(_ db: DungeonBlocker, dungeon i: Int, slot j: Int) {
        blockers[Self.index(i, j)] = db
    }

    /// `k` = which UI element (0–5: map, compass, triforce, box1, box2, box3).
    public func dungeonBlockerAppliesTo(dungeon i: Int, slot j: Int, element k: Int) -> Bool {
        precondition((0..<DungeonBlockerAppliesTo.max).contains(k), "element \(k) out of range")
        return appliesTo[Self.index(i, j)].data[k]
    }

    public func setDungeonBlockerAppliesTo(_ b: Bool, dungeon i: Int, slot j: Int, element k: Int) {
        precondition((0..<DungeonBlockerAppliesTo.max).contains(k), "element \(k) out of range")
        appliesTo[Self.index(i, j)].data[k] = b
    }

    /// The set blockers (kind ≠ `.nothing`) whose "applies to" flag for UI
    /// element `k` is on — i.e. the chips to draw on that dungeon's map / compass
    /// / triforce / item-box cell (`Views.fs:134,306`). Ordered by slot.
    public func blockersApplyingTo(dungeon i: Int, element k: Int) -> [DungeonBlocker] {
        (0..<Self.maxBlockersPerDungeon).compactMap { j in
            let b = dungeonBlocker(dungeon: i, slot: j)
            return (b != .nothing && dungeonBlockerAppliesTo(dungeon: i, slot: j, element: k)) ? b : nil
        }
    }

    /// The save-file JSON fragment for one blocker slot. Ported from
    /// `AsJsonString(i,j)` (`TrackerModel.fs:1269-1271`) — exact shape so a
    /// future persistence layer round-trips identically.
    public func asJsonString(dungeon i: Int, slot j: Int) -> String {
        let flags = appliesTo[Self.index(i, j)].data.map { $0 ? "true" : "false" }.joined(separator: ", ")
        return "{ \"Kind\": \"\(blockers[Self.index(i, j)].asHotKeyName)\", \"AppliesTo\": [ \(flags) ] }"
    }

    private static func index(_ i: Int, _ j: Int) -> Int {
        precondition((0..<dungeonCount).contains(i), "dungeon \(i) out of range")
        precondition((0..<maxBlockersPerDungeon).contains(j), "slot \(j) out of range")
        return i * maxBlockersPerDungeon + j
    }
}
