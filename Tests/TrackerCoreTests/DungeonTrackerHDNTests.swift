import Testing
@testable import TrackerCore

@Suite("DungeonTrackerInstance — Hide Dungeon Numbers mode")
struct DungeonTrackerHDNTests {
    private func hdn(isSecondQuest: Bool = false) -> DungeonTrackerInstance {
        DungeonTrackerInstance(kind: .hideDungeonNumbers, isSecondQuestDungeons: isSecondQuest)
    }

    @Test("HDN constructs (no longer guarded) with box counts [3,3,3,3,3,3,3,3,2]")
    func hdnBoxCounts() {
        let inst = hdn()
        #expect(inst.kind == .hideDungeonNumbers)
        #expect(inst.dungeons.map { $0.baseBoxes.count } == [3, 3, 3, 3, 3, 3, 3, 3, 2])
        // No shared finalBoxOf1Or4 in HDN — even dungeon 1 in first quest.
        #expect(inst.dungeon(0).boxes.count == 3)
        #expect(inst.dungeon(0).boxes.allSatisfy { $0 !== inst.finalBoxOf1Or4 })
    }

    @Test("HDN allBoxes flattens to 29 (8×3 + 2 + 3 standalone)")
    func hdnAllBoxes() {
        #expect(hdn().allBoxes().count == 29)
    }

    @Test("HDN completion: 3 boxes done + triforce always completes")
    func hdnThreeBoxesComplete() {
        let inst = hdn()
        let d = inst.dungeon(0) // 3 boxes
        d.toggleTriforce()
        for box in d.baseBoxes { box.set(cellCurrent: 0, playerHas: .yes) }
        #expect(d.isComplete)
    }

    @Test("HDN completion: 2-of-3 boxes completes only for a whitelisted 'two-boxer' label")
    func hdnTwoBoxerWhitelistFirstQuest() {
        let inst = hdn(isSecondQuest: false) // twoBoxers = "234567"
        let d = inst.dungeon(0)
        d.toggleTriforce()
        d.baseBoxes[0].set(cellCurrent: 0, playerHas: .yes)
        d.baseBoxes[1].set(cellCurrent: 0, playerHas: .yes) // 2 of 3 done

        d.labelChar = "3" // in "234567" -> two-boxer -> complete
        #expect(d.isComplete)

        d.labelChar = "1" // not in "234567" -> needs all 3 -> not complete
        #expect(!d.isComplete)

        d.labelChar = "?" // unidentified -> not a two-boxer
        #expect(!d.isComplete)
    }

    @Test("HDN two-boxer whitelist is quest-dependent (\"123567\" in second quest)")
    func hdnTwoBoxerWhitelistSecondQuest() {
        let inst = hdn(isSecondQuest: true) // twoBoxers = "123567"
        let d = inst.dungeon(0)
        d.toggleTriforce()
        d.baseBoxes[0].set(cellCurrent: 0, playerHas: .yes)
        d.baseBoxes[1].set(cellCurrent: 0, playerHas: .yes)

        d.labelChar = "1" // in "123567" -> complete
        #expect(d.isComplete)
        d.labelChar = "4" // not in "123567" -> not complete
        #expect(!d.isComplete)
    }

    @Test("HDN completion needs triforce regardless of boxes")
    func hdnNeedsTriforce() {
        let inst = hdn()
        let d = inst.dungeon(0)
        for box in d.baseBoxes { box.set(cellCurrent: 0, playerHas: .yes) }
        d.labelChar = "3"
        #expect(!d.isComplete) // no triforce
    }

    @Test("HDN getTriforceHaves maps identified labels to piece indices")
    func hdnTriforceHavesByLabel() {
        let inst = hdn()
        // Dungeon 0 has triforce and is identified as '3' -> piece index 2.
        inst.dungeon(0).toggleTriforce()
        inst.dungeon(0).labelChar = "3"
        // Dungeon 1 has triforce but is unidentified ('?') -> contributes nothing.
        inst.dungeon(1).toggleTriforce()

        var expected = Array(repeating: false, count: 8)
        expected[2] = true
        #expect(inst.getTriforceHaves() == expected)
    }

    @Test("HDN getTriforceHaves folds in HDN starting triforce pieces by index")
    func hdnTriforceHavesStartingPieces() {
        let inst = hdn()
        var starting = Array(repeating: false, count: 8)
        starting[5] = true
        var expected = Array(repeating: false, count: 8)
        expected[5] = true
        #expect(inst.getTriforceHaves(hdnStartingTriforcePieces: starting) == expected)
    }

    @Test("DEFAULT getTriforceHaves ignores the HDN starting-pieces argument")
    func defaultIgnoresStartingPieces() {
        let inst = DungeonTrackerInstance() // default
        inst.dungeon(2).toggleTriforce()
        var starting = Array(repeating: false, count: 8)
        starting[7] = true // should be ignored in DEFAULT
        var expected = Array(repeating: false, count: 8)
        expected[2] = true
        #expect(inst.getTriforceHaves(hdnStartingTriforcePieces: starting) == expected)
    }
}
