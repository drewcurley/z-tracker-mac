import Testing
@testable import TrackerCore

@Suite("OverworldQuest")
struct OverworldQuestTests {
    @Test("referenceAppIndex matches OverworldData.fs's OWQuest.AsInt exactly")
    func referenceAppIndexValues() {
        #expect(OverworldQuest.first.referenceAppIndex == 0)
        #expect(OverworldQuest.second.referenceAppIndex == 1)
        #expect(OverworldQuest.mixedFirst.referenceAppIndex == 2)
        #expect(OverworldQuest.mixedSecond.referenceAppIndex == 3)
    }

    @Test("every quest has a distinct index in 0...3")
    func distinctIndices() {
        let indices = OverworldQuest.allCases.map(\.referenceAppIndex)
        #expect(Set(indices) == Set(0...3))
    }
}
