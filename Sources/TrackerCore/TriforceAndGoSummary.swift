/// A heuristic-scored "are you basically done — should you beeline to the
/// final dungeon?" advisor. Ported from the reference's `TriforceAndGoSummary`
/// (`Zelda1RandoTools/Z1R_Tracker/Z1R_Tracker/TrackerModel.fs:1439-1485`) and
/// its helper `unreachablePossibleDungeonSpotCount()` (`:1422-1438`).
///
/// A pure computation over already-derived state, so — like
/// `PlayerComputedStateSummary` and `MapStateSummary` — it's a value struct
/// built on demand by `compute(...)`. The `ITrackerEvents`/`allUIEventing-
/// Logic` announcement machinery that *broadcasts* this (and the reactive-
/// vs-delegate architecture decision it carries) is the separate T-018.2.
public struct TriforceAndGoSummary: Sendable, Equatable {
    /// `103` = Triforce-and-Go, `102` = probably-TAG, `101` = might-be-TAG,
    /// `1…100` = a heuristic readiness score, `0` = not worth reporting.
    /// Ported from `Level` (`TrackerModel.fs:1481`).
    public let level: Int
    public let haveBow: Bool
    public let haveSilvers: Bool
    public let silversKnownToBeInLevel9: Bool
    public let haveLadder: Bool
    /// **Upstream bug, preserved for 1:1 parity.** The reference sets
    /// `haveRecorder = playerComputedStateSummary.HaveLadder`
    /// (`TrackerModel.fs:1444`) — a copy-paste error; it reads *ladder*
    /// possession, not recorder. This means the recorder penalty (`-5`) and
    /// the 103-vs-102 TAG gate are actually keyed on the ladder. Replicated
    /// exactly so this clone's TAG scores match the original's; flagged here
    /// (and in `docs/domain.md` § 6) so the divergence is a deliberate,
    /// visible choice rather than a silent one.
    public let haveRecorder: Bool
    public let missingDungeonCount: Int

    public init(
        level: Int,
        haveBow: Bool,
        haveSilvers: Bool,
        silversKnownToBeInLevel9: Bool,
        haveLadder: Bool,
        haveRecorder: Bool,
        missingDungeonCount: Int
    ) {
        self.level = level
        self.haveBow = haveBow
        self.haveSilvers = haveSilvers
        self.silversKnownToBeInLevel9 = silversKnownToBeInLevel9
        self.haveLadder = haveLadder
        self.haveRecorder = haveRecorder
        self.missingDungeonCount = missingDungeonCount
    }

    /// Counts overworld screens that *might* still hide an unfound dungeon
    /// but which the player can't currently uncover (missing bomb/candle/
    /// raft/ladder/recorder). Ported from
    /// `unreachablePossibleDungeonSpotCount()` (`TrackerModel.fs:1422-1438`):
    /// a screen contributes once per unmet tool. Only screens whose mark is
    /// `< 9` (unmarked, or already dungeon-marked) are considered.
    public static func unreachablePossibleDungeonSpotCount(
        grid: OverworldGrid,
        instance: OverworldInstance,
        playerState: PlayerComputedStateSummary,
        progress: PlayerProgressAndTakeAnyHearts
    ) -> Int {
        var count = 0
        for x in 0..<16 {
            for y in 0..<8 {
                let cur = grid.mark(column: x, row: y).rawIndex
                guard cur < 9 else { continue }
                if instance.bombable(x: x, y: y) && !progress.hasBombs { count += 1 }
                if instance.burnable(x: x, y: y) && !(playerState.candleLevel > 0) { count += 1 }
                if instance.raftable(x: x, y: y) && !playerState.haveRaft { count += 1 }
                if instance.ladderable(x: x, y: y) && !playerState.haveLadder { count += 1 }
                if instance.whistleable(x: x, y: y) && !playerState.haveRecorder { count += 1 }
            }
        }
        return count
    }

    /// Recomputes the TAG summary. Structure-preserving port of the
    /// `TriforceAndGoSummary` constructor body (`TrackerModel.fs:1440-1480`).
    /// `mapState.dungeonLocations[i] != nil` is the Swift equivalent of the
    /// reference's `GetDungeon(i).HasBeenLocated()`.
    public static func compute(
        playerState: PlayerComputedStateSummary,
        dungeonTracker: DungeonTrackerInstance,
        mapState: MapStateSummary,
        progress: PlayerProgressAndTakeAnyHearts,
        grid: OverworldGrid,
        instance: OverworldInstance
    ) -> TriforceAndGoSummary {
        let haveBow = playerState.haveBow
        let haveSilvers = playerState.arrowLevel == 2
        let d9 = dungeonTracker.dungeon(8)
        let silversKnownToBeInLevel9 =
            d9.boxes[0].cellCurrent == ITEMS.silverArrow || d9.boxes[1].cellCurrent == ITEMS.silverArrow
        let haveLadder = playerState.haveLadder
        // NOTE: upstream bug preserved — see `haveRecorder` doc above.
        let haveRecorder = playerState.haveLadder
        let unreachableCount = unreachablePossibleDungeonSpotCount(
            grid: grid, instance: instance, playerState: playerState, progress: progress)

        var missingTriforceFromLocatedDungeonCount = 0
        var missingDungeonCount = 0
        for i in 0...8 where !dungeonTracker.dungeon(i).playerHasTriforce {
            if mapState.dungeonLocations[i] == nil {
                missingDungeonCount += 1
            } else if i != 8 { // L9 has no triforce
                missingTriforceFromLocatedDungeonCount += 1
            }
        }

        func computeScore() -> Int {
            var score = 100
            score -= missingDungeonCount * 20
            score -= missingTriforceFromLocatedDungeonCount * 8
            if !haveBow { score -= 35 }
            if !haveSilvers { score -= 30 }
            if !haveLadder { score -= 15 }
            if !haveRecorder { score -= 5 }
            return score < 0 ? 0 : score
        }

        // You might need e.g. power bracelet or raft to find a missing
        // dungeon, so never TAG unless every remaining dungeon is locatable.
        let knowSilvers = haveSilvers || silversKnownToBeInLevel9
        let level: Int
        if missingDungeonCount == 0 || unreachableCount == 0 {
            if haveBow && knowSilvers && haveLadder && haveRecorder {
                level = 103
            } else if haveBow && knowSilvers && haveLadder {
                level = 102
            } else if haveBow && knowSilvers {
                level = 101
            } else {
                level = computeScore()
            }
        } else {
            level = computeScore()
        }

        return TriforceAndGoSummary(
            level: level,
            haveBow: haveBow,
            haveSilvers: haveSilvers,
            silversKnownToBeInLevel9: silversKnownToBeInLevel9,
            haveLadder: haveLadder,
            haveRecorder: haveRecorder,
            missingDungeonCount: missingDungeonCount
        )
    }
}
