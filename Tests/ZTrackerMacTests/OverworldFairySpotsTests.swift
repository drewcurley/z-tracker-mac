import Testing
import TrackerCore
@testable import ZTrackerMac

@Suite("Overworld fairy spots")
struct OverworldFairySpotsTests {
    @Test("the two always-quest fairy spots are fairy spots in every quest")
    func alwaysQuestSpots() {
        for quest in [OverworldQuest.first, .second, .mixedFirst, .mixedSecond] {
            #expect(OverworldFairySpots.isFairySpot(column: 9, row: 3, quest: quest))
            #expect(OverworldFairySpots.isFairySpot(column: 3, row: 4, quest: quest))
        }
    }

    @Test("(11,0) is a fairy spot only in second quest")
    func secondQuestOnlySpot() {
        #expect(OverworldFairySpots.isFairySpot(column: 11, row: 0, quest: .second))
        #expect(!OverworldFairySpots.isFairySpot(column: 11, row: 0, quest: .first))
        #expect(!OverworldFairySpots.isFairySpot(column: 11, row: 0, quest: .mixedFirst))
        #expect(!OverworldFairySpots.isFairySpot(column: 11, row: 0, quest: .mixedSecond))
    }

    @Test("ordinary tiles are not fairy spots")
    func nonSpots() {
        #expect(!OverworldFairySpots.isFairySpot(column: 0, row: 0, quest: .first))
        #expect(!OverworldFairySpots.isFairySpot(column: 7, row: 7, quest: .second))
        #expect(!OverworldFairySpots.isFairySpot(column: 9, row: 4, quest: .first))
    }

    @Test("every fairy spot is an always-empty screen in its quest")
    func fairySpotsAreAlwaysEmpty() {
        // The fairy is only drawn on always-empty tiles, so the spots must be
        // always-empty for the quest that shows them (guards the two data sets
        // agreeing).
        #expect(OverworldInstance(quest: .first).alwaysEmpty(x: 9, y: 3))
        #expect(OverworldInstance(quest: .first).alwaysEmpty(x: 3, y: 4))
        #expect(OverworldInstance(quest: .second).alwaysEmpty(x: 9, y: 3))
        #expect(OverworldInstance(quest: .second).alwaysEmpty(x: 3, y: 4))
        #expect(OverworldInstance(quest: .second).alwaysEmpty(x: 11, y: 0))
    }

    @Test("the fairy sprite loads")
    func spriteLoads() {
        #expect(FairyIconAtlas.image != nil)
        #expect(FairyIconAtlas.image?.width == 8)
        #expect(FairyIconAtlas.image?.height == 16)
    }
}
