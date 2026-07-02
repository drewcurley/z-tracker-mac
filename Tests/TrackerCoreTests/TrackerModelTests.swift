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
}
