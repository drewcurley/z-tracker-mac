import Testing
import TrackerCore
@testable import ZTrackerMac

@Suite("Top-section status fields (spots left / gettable)")
struct StatusFieldsTests {
    private func mapState(quest: OverworldQuest, playerState: PlayerComputedStateSummary) -> MapStateSummary {
        MapStateSummary.compute(
            grid: OverworldGrid(), instance: OverworldInstance(quest: quest),
            dungeonTracker: DungeonTrackerInstance(), playerState: playerState,
            progress: PlayerProgressAndTakeAnyHearts(), drawRoutes: false,
            routesCanScreenScroll: false, mirrorOverworld: false)
    }

    @Test("gettableCount reads owGettableLocations.trueCount")
    func gettableCountWiring() {
        let s = mapState(quest: .first, playerState: PlayerComputedStateSummary())
        #expect(ItemProgressGrid.gettableCount(s) == s.owGettableLocations.trueCount)
    }

    @Test("gettable rises as capabilities are gained (raft opens raftable spots)")
    func raftOpensSpots() {
        let empty = mapState(quest: .first, playerState: PlayerComputedStateSummary())
        let withRaft = mapState(quest: .first, playerState: PlayerComputedStateSummary(haveRaft: true))
        // First-quest raft opens exactly its raftable spots (2 in the reference).
        #expect(ItemProgressGrid.gettableCount(withRaft) == ItemProgressGrid.gettableCount(empty) + 2)
    }

    @Test("recorder gettable differs by quest (1 in 1Q, 10 in 2Q)")
    func recorderPerQuest() {
        let recorder = PlayerComputedStateSummary(haveRecorder: true)
        let noItems = PlayerComputedStateSummary()

        let fq0 = ItemProgressGrid.gettableCount(mapState(quest: .first, playerState: noItems))
        let fqR = ItemProgressGrid.gettableCount(mapState(quest: .first, playerState: recorder))
        #expect(fqR - fq0 == 1) // one whistle spot in first quest

        let sq0 = ItemProgressGrid.gettableCount(mapState(quest: .second, playerState: noItems))
        let sqR = ItemProgressGrid.gettableCount(mapState(quest: .second, playerState: recorder))
        #expect(sqR - sq0 == 10) // ten whistle spots in second quest
    }
}
