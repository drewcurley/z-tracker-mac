import Testing
@testable import TrackerCore

@Suite("TrackerModel")
struct TrackerModelTests {
    @Test("starts with no quest selected")
    func startsWithNoQuest() {
        let model = TrackerModel()
        #expect(model.quest == nil)
    }

    @Test("selectQuest sets the quest", arguments: OverworldQuest.allCases)
    func selectQuestSetsQuest(quest: OverworldQuest) {
        let model = TrackerModel()
        model.selectQuest(quest)
        #expect(model.quest == quest)
    }

    @Test("selectQuest overwrites a previous selection")
    func selectQuestOverwrites() {
        let model = TrackerModel(quest: .first)
        model.selectQuest(.mixedSecond)
        #expect(model.quest == .mixedSecond)
    }

    @Test("heartShuffle and hideDungeonNumbers default to off")
    func togglesDefaultOff() {
        let model = TrackerModel()
        #expect(model.heartShuffle == false)
        #expect(model.hideDungeonNumbers == false)
    }

    @Test("mirrorOverworld defaults off and is settable (T-047)")
    func mirrorOverworldFlag() {
        let model = TrackerModel()
        #expect(model.mirrorOverworld == false)
        model.mirrorOverworld = true
        #expect(model.mirrorOverworld == true)
        // Init override also works.
        #expect(TrackerModel(mirrorOverworld: true).mirrorOverworld == true)
    }

    @Test("heartShuffle and hideDungeonNumbers can be set independently")
    func togglesAreIndependent() {
        let model = TrackerModel()
        model.heartShuffle = true
        #expect(model.heartShuffle == true)
        #expect(model.hideDungeonNumbers == false)
        model.hideDungeonNumbers = true
        #expect(model.heartShuffle == true)
        #expect(model.hideDungeonNumbers == true)
    }

    @Test("initializer accepts explicit toggle values")
    func initializerAcceptsToggles() {
        let model = TrackerModel(quest: .second, heartShuffle: true, hideDungeonNumbers: true)
        #expect(model.quest == .second)
        #expect(model.heartShuffle == true)
        #expect(model.hideDungeonNumbers == true)
    }

    @Test("owns a fresh, fully-unmarked overworldGrid by default")
    func ownsFreshOverworldGrid() {
        let model = TrackerModel()
        #expect(model.overworldGrid.mark(column: 0, row: 0) == .unmarked)
    }

    @Test("mutating overworldGrid through the model is visible on the same instance")
    func overworldGridMutationVisible() {
        let model = TrackerModel()
        model.overworldGrid.setMark(.dungeon(4), column: 7, row: 3)
        #expect(model.overworldGrid.mark(column: 7, row: 3) == .dungeon(4))
    }
}
