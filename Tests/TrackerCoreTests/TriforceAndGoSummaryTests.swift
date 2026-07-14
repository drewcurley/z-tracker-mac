import Testing
@testable import TrackerCore

@Suite("TriforceAndGoSummary")
struct TriforceAndGoSummaryTests {
    private let instance = OverworldInstance(quest: .first)

    private func mapState(grid: OverworldGrid, dungeonTracker: DungeonTrackerInstance) -> MapStateSummary {
        MapStateSummary.compute(
            grid: grid, instance: instance, dungeonTracker: dungeonTracker,
            playerState: PlayerComputedStateSummary(), progress: PlayerProgressAndTakeAnyHearts(),
            drawRoutes: false, routesCanScreenScroll: false, mirrorOverworld: false)
    }

    private func compute(
        grid: OverworldGrid = OverworldGrid(),
        dungeonTracker: DungeonTrackerInstance = DungeonTrackerInstance(),
        playerState: PlayerComputedStateSummary = PlayerComputedStateSummary(),
        progress: PlayerProgressAndTakeAnyHearts = PlayerProgressAndTakeAnyHearts()
    ) -> TriforceAndGoSummary {
        TriforceAndGoSummary.compute(
            playerState: playerState, dungeonTracker: dungeonTracker,
            mapState: mapState(grid: grid, dungeonTracker: dungeonTracker),
            progress: progress, grid: grid, instance: instance)
    }

    /// Give every dungeon its triforce so the "missing dungeon" loop skips
    /// all — `missingDungeonCount == 0`, entering the TAG-level branch.
    private func allTriforce() -> DungeonTrackerInstance {
        let dt = DungeonTrackerInstance()
        for i in 0...8 { dt.dungeon(i).toggleTriforce() }
        return dt
    }

    @Test("unreachablePossibleDungeonSpotCount: empty first-quest, empty-handed = 41 (mask sum)")
    func unreachableCountPinned() {
        let n = TriforceAndGoSummary.unreachablePossibleDungeonSpotCount(
            grid: OverworldGrid(), instance: instance,
            playerState: PlayerComputedStateSummary(), progress: PlayerProgressAndTakeAnyHearts())
        #expect(n == 41) // bomb 22 + burn 16 + raft 2 + ladder 0 + whistle 1
    }

    @Test("all tools held -> unreachable count drops to 0")
    func unreachableCountWithTools() {
        let progress = PlayerProgressAndTakeAnyHearts()
        progress.hasBombs = true
        let player = PlayerComputedStateSummary(
            haveLadder: true, haveRaft: true, candleLevel: 1)
        // recorder (whistle) — the only whistleable first-quest screen needs it
        let playerWithRecorder = PlayerComputedStateSummary(
            haveRecorder: true, haveLadder: true, haveRaft: true, candleLevel: 1)
        #expect(TriforceAndGoSummary.unreachablePossibleDungeonSpotCount(
            grid: OverworldGrid(), instance: instance, playerState: player, progress: progress) == 1) // whistle spot remains
        #expect(TriforceAndGoSummary.unreachablePossibleDungeonSpotCount(
            grid: OverworldGrid(), instance: instance, playerState: playerWithRecorder, progress: progress) == 0)
    }

    @Test("a fresh game scores 0 (all dungeons missing, no items)")
    func freshGameLevelZero() {
        #expect(compute().level == 0)
    }

    @Test("bow + silvers + ladder, all triforce -> level 103 (full TAG)")
    func fullTag() {
        let s = compute(
            dungeonTracker: allTriforce(),
            playerState: PlayerComputedStateSummary(haveLadder: true, haveBow: true, arrowLevel: 2))
        #expect(s.missingDungeonCount == 0)
        #expect(s.level == 103)
    }

    @Test("bow + silvers, no ladder, all triforce -> level 101 (might-be-TAG)")
    func mightBeTag() {
        let s = compute(
            dungeonTracker: allTriforce(),
            playerState: PlayerComputedStateSummary(haveBow: true, arrowLevel: 2)) // no ladder
        #expect(s.level == 101)
    }

    @Test("silvers known to be in level 9 counts as knowing silvers")
    func silversInLevel9() {
        let dt = allTriforce()
        dt.dungeon(8).boxes[0].set(cellCurrent: ITEMS.silverArrow, playerHas: .no) // just 'known', not obtained
        let s = compute(
            dungeonTracker: dt,
            playerState: PlayerComputedStateSummary(haveLadder: true, haveBow: true, arrowLevel: 0))
        #expect(s.silversKnownToBeInLevel9)
        #expect(s.level == 103) // bow && knowSilvers && ladder (&& recorder==ladder)
    }

    @Test("all located but no items -> heuristic score (computeScore path)")
    func heuristicScore() {
        // all triforce (missingDungeon 0), but no bow/silvers/ladder.
        let s = compute(dungeonTracker: allTriforce())
        // 100 - 0 - 0 - 35(nobow) - 30(nosilvers) - 15(noladder) - 5(norecorder) = 15
        #expect(s.level == 15)
    }

    @Test("upstream bug preserved: haveRecorder always mirrors haveLadder")
    func recorderBugMirrorsLadder() {
        // Even with recorder held and ladder NOT held, the summary's
        // haveRecorder reflects LADDER (false), per the reference bug.
        let s = compute(playerState: PlayerComputedStateSummary(haveRecorder: true, haveLadder: false))
        #expect(s.haveLadder == false)
        #expect(s.haveRecorder == false) // == haveLadder, not the real recorder flag
        let s2 = compute(playerState: PlayerComputedStateSummary(haveRecorder: false, haveLadder: true))
        #expect(s2.haveRecorder == true) // == haveLadder
    }
}
