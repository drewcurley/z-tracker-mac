import Testing
@testable import TrackerCore

@Suite("Dungeon item-use rules (ChoiceDomain) + floor hearts")
struct DungeonItemRulesTests {
    @Test("max uses: every item is unique (1) except heart containers (9)")
    func maxUses() {
        #expect(DungeonTrackerInstance.maxUses(ofItem: ITEMS.heartContainer) == 9)
        for item in [ITEMS.ladder, ITEMS.bow, ITEMS.recorder, ITEMS.whiteSword, ITEMS.anyKey] {
            #expect(DungeonTrackerInstance.maxUses(ofItem: item) == 1)
        }
    }

    @Test("a unique item is unavailable once placed elsewhere")
    func uniqueItemExhausts() {
        let inst = DungeonTrackerInstance()
        let a = inst.dungeon(0).boxes[0]
        let b = inst.dungeon(1).boxes[0]
        // Place the ladder in box a.
        a.set(cellCurrent: ITEMS.ladder, playerHas: .yes)
        #expect(inst.itemUseCount(ITEMS.ladder) == 1)
        // b can no longer select the ladder...
        #expect(inst.canSelectItem(ITEMS.ladder, forBox: b) == false)
        // ...but a can still "re-pick" the ladder it already holds.
        #expect(inst.canSelectItem(ITEMS.ladder, forBox: a) == true)
        // A different unique item is still available to b.
        #expect(inst.canSelectItem(ITEMS.bow, forBox: b) == true)
    }

    @Test("heart containers remain available up to 9 uses")
    func heartAllowsNine() {
        let inst = DungeonTrackerInstance()
        let boxes = inst.allBoxes()
        // Place 8 hearts.
        for i in 0..<8 { boxes[i].set(cellCurrent: ITEMS.heartContainer, playerHas: .no) }
        #expect(inst.itemUseCount(ITEMS.heartContainer) == 8)
        // A 9th box can still take a heart...
        #expect(inst.canSelectItem(ITEMS.heartContainer, forBox: boxes[8]) == true)
        boxes[8].set(cellCurrent: ITEMS.heartContainer, playerHas: .no)
        // ...but a 10th cannot.
        #expect(inst.itemUseCount(ITEMS.heartContainer) == 9)
        #expect(inst.canSelectItem(ITEMS.heartContainer, forBox: boxes[9]) == false)
    }

    @Test("floor hearts: Heart Shuffle off seeds L1-8 box[0] with an unobtained heart; L9 excluded")
    func floorHeartsOff() {
        let inst = DungeonTrackerInstance()
        inst.applyFloorItemHearts(heartShuffle: false)
        for i in 0..<8 {
            let floor = inst.dungeon(i).baseBoxes[0]
            #expect(floor.cellCurrent == ITEMS.heartContainer)
            #expect(floor.playerHas == .no)
        }
        // Dungeon 9 (index 8) has no floor heart.
        #expect(inst.dungeon(8).baseBoxes[0].cellCurrent == -1)
        // 8 hearts placed -> one heart use remains (the coast heart).
        #expect(inst.itemUseCount(ITEMS.heartContainer) == 8)
    }

    @Test("floor hearts: Heart Shuffle on leaves the floor boxes empty")
    func floorHeartsOn() {
        let inst = DungeonTrackerInstance()
        inst.applyFloorItemHearts(heartShuffle: false) // seed first
        inst.applyFloorItemHearts(heartShuffle: true)  // then shuffle on
        for i in 0..<8 {
            #expect(inst.dungeon(i).baseBoxes[0].cellCurrent == -1)
        }
        #expect(inst.itemUseCount(ITEMS.heartContainer) == 0)
    }

    @Test("selectQuest seeds floor hearts from the model's heartShuffle flag")
    func selectQuestSeedsHearts() {
        let noShuffle = TrackerModel(heartShuffle: false)
        noShuffle.selectQuest(.first)
        #expect(noShuffle.dungeonTracker.dungeon(0).baseBoxes[0].cellCurrent == ITEMS.heartContainer)

        let shuffle = TrackerModel(heartShuffle: true)
        shuffle.selectQuest(.first)
        #expect(shuffle.dungeonTracker.dungeon(0).baseBoxes[0].cellCurrent == -1)
    }
}
