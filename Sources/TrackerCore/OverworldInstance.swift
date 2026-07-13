/// Per-screen overworld terrain capabilities — which of the 16×8 overworld
/// screens can be uncovered by a whistle, bomb, candle-burn, raft, ladder,
/// power-bracelet push, etc., and which are always/sometimes empty. Ported
/// value-for-value from the reference's `OverworldData.OverworldInstance`
/// and its `PrivateInternals` character masks
/// (`Zelda1RandoTools/Z1R_Tracker/Z1R_Tracker/OverworldData.fs:62-339`).
///
/// This is pure, table-driven data keyed on the quest; it is the foundation
/// `recomputeMapStateSummary` (T-015.3) needs to decide gettable/routeworthy
/// spots and true GYR coloring. Each mask is 8 rows of 16 characters
/// (`X` = capability present) indexed `[y][x]` exactly as the reference's
/// `mask.[y].Chars(x) = 'X'`.
///
/// **`OWQuest.BLANK` is not modeled** — it is the reference's "no quest /
/// alternative custom overworld" mode, already deliberately omitted from the
/// Swift `OverworldQuest` enum (see its doc comment). Its terrain rules
/// (`AlwaysEmpty=false`, `SometimesEmpty=true`, every capability `false`)
/// are deferred with that custom-overworld mode.
public struct OverworldInstance: Sendable {
    public let quest: OverworldQuest

    public init(quest: OverworldQuest) {
        self.quest = quest
    }

    // MARK: - Predicates (ported from OverworldData.fs:275-335)

    /// A screen that never holds anything in this quest.
    public func alwaysEmpty(x: Int, y: Int) -> Bool {
        switch quest {
        case .first: Masks.firstQuestAlwaysEmpty.isX(x, y)
        case .second: Masks.secondQuestAlwaysEmpty.isX(x, y)
        case .mixedFirst, .mixedSecond: Masks.mixedQuestAlwaysEmpty.isX(x, y)
        }
    }

    /// Reachable only with the ladder. First quest: never (the ladder opens
    /// nothing on the 1Q overworld); all other quests use the 2Q mask.
    public func ladderable(x: Int, y: Int) -> Bool {
        switch quest {
        case .first: false
        case .second, .mixedFirst, .mixedSecond: Masks.secondQuestLadderable.isX(x, y)
        }
    }

    /// Screens that hold an Armos-guarded item (quest-independent).
    public func hasArmos(x: Int, y: Int) -> Bool {
        Masks.armos.isX(x, y)
    }

    /// Reachable only with the raft (quest-independent).
    public func raftable(x: Int, y: Int) -> Bool {
        Masks.raftable.isX(x, y)
    }

    /// Uncovered by playing the recorder/whistle. MIXED = first OR second.
    public func whistleable(x: Int, y: Int) -> Bool {
        switch quest {
        case .first: Masks.firstQuestWhistleable.isX(x, y)
        case .second: Masks.secondQuestWhistleable.isX(x, y)
        case .mixedFirst, .mixedSecond:
            Masks.firstQuestWhistleable.isX(x, y) || Masks.secondQuestWhistleable.isX(x, y)
        }
    }

    /// Uncovered by pushing with the power bracelet. MIXED = first OR second.
    public func powerBraceletable(x: Int, y: Int) -> Bool {
        switch quest {
        case .first: Masks.firstQuestPowerBraceletable.isX(x, y)
        case .second: Masks.secondQuestPowerBraceletable.isX(x, y)
        case .mixedFirst, .mixedSecond:
            Masks.firstQuestPowerBraceletable.isX(x, y) || Masks.secondQuestPowerBraceletable.isX(x, y)
        }
    }

    /// Uncovered by pushing a gravestone. MIXED = first OR second. (Not read
    /// by `recomputeMapStateSummary`, but part of the reference's instance;
    /// ported for completeness/parity.)
    public func gravePushable(x: Int, y: Int) -> Bool {
        switch quest {
        case .first: Masks.firstQuestGravePushable.isX(x, y)
        case .second: Masks.secondQuestGravePushable.isX(x, y)
        case .mixedFirst, .mixedSecond:
            Masks.firstQuestGravePushable.isX(x, y) || Masks.secondQuestGravePushable.isX(x, y)
        }
    }

    /// Uncovered by burning a bush with the candle. MIXED = first OR second.
    public func burnable(x: Int, y: Int) -> Bool {
        switch quest {
        case .first: Masks.firstQuestBurnable.isX(x, y)
        case .second: Masks.secondQuestBurnable.isX(x, y)
        case .mixedFirst, .mixedSecond:
            Masks.firstQuestBurnable.isX(x, y) || Masks.secondQuestBurnable.isX(x, y)
        }
    }

    /// Uncovered by bombing a wall. MIXED = first OR second.
    public func bombable(x: Int, y: Int) -> Bool {
        switch quest {
        case .first: Masks.firstQuestBombable.isX(x, y)
        case .second: Masks.secondQuestBombable.isX(x, y)
        case .mixedFirst, .mixedSecond:
            Masks.firstQuestBombable.isX(x, y) || Masks.secondQuestBombable.isX(x, y)
        }
    }

    /// An open cave with no special uncovering requirement: not always-empty,
    /// and not gated behind bomb/burn/ladder/bracelet/raft/whistle. Ported
    /// from `Nothingable` (`OverworldData.fs:330-332`); used by the
    /// destination picker's "open caves" target (T-015.6).
    public func nothingable(x: Int, y: Int) -> Bool {
        !alwaysEmpty(x: x, y: y)
            && !(bombable(x: x, y: y) || burnable(x: x, y: y) || ladderable(x: x, y: y)
                 || powerBraceletable(x: x, y: y) || raftable(x: x, y: y) || whistleable(x: x, y: y))
    }

    /// A screen that is empty in some quests but not others — drives the
    /// yellow GYR color (T-015.4). Only MIXED quests have any; FIRST/SECOND
    /// never. Ported from `SometimesEmpty` (`OverworldData.fs:333-338`).
    public func sometimesEmpty(x: Int, y: Int) -> Bool {
        switch quest {
        case .first, .second: false
        case .mixedFirst, .mixedSecond: Masks.mixedQuestSometimesEmpty.isX(x, y)
        }
    }
}

/// The 16×8 `.`/`X` character masks backing `OverworldInstance`, transcribed
/// verbatim from `OverworldData.PrivateInternals` (`OverworldData.fs:62-249`)
/// plus the two derived quest-only masks (`:251-271`). Kept as raw strings so
/// they diff line-for-line against the reference source.
enum Masks {
    /// One 8-row × 16-column terrain mask. `isX(x, y)` mirrors the
    /// reference's `mask.[y].Chars(x) = 'X'`.
    struct Grid: Sendable {
        let rows: [String]
        init(_ rows: [String]) {
            precondition(rows.count == 8, "expected 8 rows, got \(rows.count)")
            precondition(rows.allSatisfy { $0.count == 16 }, "every row must be 16 chars")
            self.rows = rows
        }
        func isX(_ x: Int, _ y: Int) -> Bool {
            precondition((0..<16).contains(x) && (0..<8).contains(y), "(\(x),\(y)) out of 16×8")
            let row = rows[y]
            return row[row.index(row.startIndex, offsetBy: x)] == "X"
        }
    }

    static let armos = Grid([
        "................",
        "............X...",
        "....X...........",
        "....X........X..",
        "..............X.",
        "................",
        "................",
        "................",
    ])

    static let raftable = Grid([
        "................",
        "................",
        "...............X",
        "................",
        ".....X..........",
        "................",
        "................",
        "................",
    ])

    static let firstQuestBombable = Grid([
        ".X.X.X.X.....X..",
        "X.XXX.X.......X.",
        "......XX....XX..",
        "...X............",
        "................",
        "................",
        ".......X........",
        ".X....X....XXX..",
    ])

    static let secondQuestBombable = Grid([
        "XXXX...X.....X..",
        "X.XXXXX.XX....X.",
        "......X......X..",
        "...X............",
        "................",
        "................",
        "................",
        "......X.....XX..",
    ])

    static let firstQuestBurnable = Grid([
        "................",
        "................",
        "........X.......",
        "................",
        "......XXX..X.X..",
        ".X....X....X....",
        "..XX....X.XX.X..",
        "........X.......",
    ])

    static let secondQuestBurnable = Grid([
        "................",
        "................",
        "........X.......",
        "................",
        "......X.X..X.X..",
        ".X.X..X....X....",
        "...X....X.X.X...",
        "........X.......",
    ])

    static let firstQuestPowerBraceletable = Grid([
        "................",
        ".............X..",
        "...X............",
        "................",
        ".........X......",
        "................",
        "................",
        ".........X......",
    ])

    static let secondQuestPowerBraceletable = Grid([
        ".........X......",
        ".X.........X.X..",
        "...X............",
        "................",
        ".........X......",
        "................",
        "................",
        ".........X......",
    ])

    static let secondQuestLadderable = Grid([
        "................",
        "........XX......",
        "................",
        "................",
        "................",
        "................",
        "................",
        "................",
    ])

    static let firstQuestWhistleable = Grid([
        "................",
        "................",
        "................",
        "................",
        "..X.............",
        "................",
        "................",
        "................",
    ])

    static let secondQuestWhistleable = Grid([
        "......X.........",
        "................",
        ".........X.X....",
        "X.........X.X...",
        "................",
        "........X.......",
        "X.............X.",
        "..X.............",
    ])

    static let firstQuestGravePushable = Grid([
        "................",
        "................",
        ".X..............",
        "................",
        "................",
        "................",
        "................",
        "................",
    ])

    static let secondQuestGravePushable = Grid([
        "................",
        "................",
        "X...............",
        "................",
        "................",
        "................",
        "................",
        "................",
    ])

    static let firstQuestAlwaysEmpty = Grid([
        "X.X...X.XX......",
        ".X...X.XXX.X....",
        "X........XXX..X.",
        "XXX..XX.XXXX..XX",
        "XX.X........X..X",
        "X.XXXX.XXXX.XX.X",
        "XX...X...X..X.X.",
        "..XX......X...XX",
    ])

    static let secondQuestAlwaysEmpty = Grid([
        ".....X..X..X....",
        ".......X........",
        ".X.....X..X.X.X.",
        ".XX..XX.XX.X..XX",
        "XXXX...X....X..X",
        "X.X.XX.X.XX.XX.X",
        ".XX..X.X.X.X.X..",
        ".X.X......XX..XX",
    ])

    static let mixedQuestSometimesEmpty = Grid([
        "X.X..XX..X......",
        ".X...X..XX.X....",
        "XX.....X.X.XX...",
        "X.........X.....",
        ".......X........",
        "...X....X.......",
        "X.X....X...XXXX.",
        ".XX........X....",
    ])

    /// Derived: `X` where BOTH first- and second-quest are always-empty.
    /// Computed exactly as `OverworldData.fs:239-248`.
    static let mixedQuestAlwaysEmpty = deriveGrid { x, y in
        firstQuestAlwaysEmpty.isX(x, y) && secondQuestAlwaysEmpty.isX(x, y)
    }

    /// Derived: `X` where a screen exists only in second quest (1Q always-
    /// empty AND not 2Q always-empty). `OverworldData.fs:251-261`.
    static let secondQuestOnly = deriveGrid { x, y in
        firstQuestAlwaysEmpty.isX(x, y) && !secondQuestAlwaysEmpty.isX(x, y)
    }

    /// Derived: `X` where a screen exists only in first quest.
    /// `OverworldData.fs:262-271`.
    static let firstQuestOnly = deriveGrid { x, y in
        !firstQuestAlwaysEmpty.isX(x, y) && secondQuestAlwaysEmpty.isX(x, y)
    }

    private static func deriveGrid(_ predicate: (Int, Int) -> Bool) -> Grid {
        Grid((0..<8).map { y in
            String((0..<16).map { x in predicate(x, y) ? "X" : "." })
        })
    }
}
