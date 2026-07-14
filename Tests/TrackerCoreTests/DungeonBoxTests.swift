import Testing
@testable import TrackerCore

@Suite("PlayerHas")
struct PlayerHasTests {
    @Test("raw values pin the reference's AsInt/FromInt mapping (NO=0, YES=1, SKIPPED=2)")
    func rawValuesPinReference() {
        #expect(PlayerHas.no.rawValue == 0)
        #expect(PlayerHas.yes.rawValue == 1)
        #expect(PlayerHas.skipped.rawValue == 2)
        #expect(PlayerHas.allCases.count == 3)
    }
}

@Suite("Box")
struct BoxTests {
    @Test("a fresh box is empty and not done")
    func freshBox() {
        let box = Box()
        #expect(box.cellCurrent == -1)
        #expect(box.playerHas == .no)
        #expect(box.isDone == false)
        #expect(box.isEmptyRedBox == true)
    }

    @Test("isDone requires both a known item and playerHas != NO")
    func isDoneMatrix() {
        // known item, not obtained -> not done
        let notObtained = Box(cellCurrent: 4, playerHas: .no)
        #expect(notObtained.isDone == false)

        // known item + obtained -> done
        let obtained = Box(cellCurrent: 4, playerHas: .yes)
        #expect(obtained.isDone == true)

        // known item + skipped -> done (intentionally skipped counts as done)
        let skipped = Box(cellCurrent: 4, playerHas: .skipped)
        #expect(skipped.isDone == true)

        // no known item but marked obtained -> not done (needs a known item)
        let obtainedUnknown = Box(cellCurrent: -1, playerHas: .yes)
        #expect(obtainedUnknown.isDone == false)
    }

    @Test("isEmptyRedBox only when neither known nor obtained")
    func isEmptyRedBox() {
        #expect(Box(cellCurrent: -1, playerHas: .no).isEmptyRedBox == true)
        #expect(Box(cellCurrent: 0, playerHas: .no).isEmptyRedBox == false)
        #expect(Box(cellCurrent: -1, playerHas: .skipped).isEmptyRedBox == false)
    }

    @Test("set and setPlayerHas mutate the expected fields")
    func mutation() {
        let box = Box()
        box.set(cellCurrent: 10, playerHas: .yes)
        #expect(box.cellCurrent == 10)
        #expect(box.playerHas == .yes)

        box.setPlayerHas(.skipped)
        #expect(box.cellCurrent == 10) // unchanged
        #expect(box.playerHas == .skipped)

        box.set(cellCurrent: -1, playerHas: .no)
        #expect(box.isEmptyRedBox == true)
    }
}

@Suite("DungeonTrackerInstance (DEFAULT mode)")
struct DungeonTrackerInstanceTests {
    @Test("nine dungeons with base box counts [2,2,2,2,2,2,2,3,2]")
    func baseBoxCounts() {
        let inst = DungeonTrackerInstance()
        #expect(inst.dungeons.count == 9)
        let counts = inst.dungeons.map { $0.baseBoxes.count }
        #expect(counts == [2, 2, 2, 2, 2, 2, 2, 3, 2])
    }

    @Test("first quest: dungeon 1 gets the third box, dungeon 4 does not")
    func firstQuestEffectiveBoxes() {
        let inst = DungeonTrackerInstance(isSecondQuestDungeons: false)
        let counts = inst.dungeons.map { $0.boxes.count }
        // L1=3, L2..L7=2, L8=3, L9=2
        #expect(counts == [3, 2, 2, 2, 2, 2, 2, 3, 2])
        // finalBoxOf1Or4 is the shared instance, appended to dungeon 1 only
        #expect(inst.dungeon(0).boxes.last === inst.finalBoxOf1Or4)
        #expect(inst.dungeon(3).boxes.allSatisfy { $0 !== inst.finalBoxOf1Or4 })
    }

    @Test("second quest: dungeon 4 gets the third box, dungeon 1 does not")
    func secondQuestEffectiveBoxes() {
        let inst = DungeonTrackerInstance(isSecondQuestDungeons: true)
        let counts = inst.dungeons.map { $0.boxes.count }
        // L1=2, L2=2, L3=2, L4=3, L5..L7=2, L8=3, L9=2
        #expect(counts == [2, 2, 2, 3, 2, 2, 2, 3, 2])
        #expect(inst.dungeon(3).boxes.last === inst.finalBoxOf1Or4)
        #expect(inst.dungeon(0).boxes.allSatisfy { $0 !== inst.finalBoxOf1Or4 })
    }

    @Test("toggling isSecondQuestDungeons moves the third box from dungeon 1 to dungeon 4")
    func toggleMovesThirdBox() {
        let inst = DungeonTrackerInstance(isSecondQuestDungeons: false)
        #expect(inst.dungeon(0).boxes.count == 3)
        #expect(inst.dungeon(3).boxes.count == 2)

        inst.isSecondQuestDungeons = true
        #expect(inst.dungeon(0).boxes.count == 2)
        #expect(inst.dungeon(3).boxes.count == 3)
    }

    @Test("ghost box + toggle: the non-owning of L1/L4 hosts the movable extra item")
    func ghostBoxAndToggle() {
        let inst = DungeonTrackerInstance(isSecondQuestDungeons: false)
        // 1Q: L1 owns the extra box, so the ghost placeholder sits under L4.
        #expect(inst.ghostBoxDungeonId == 3)

        // Mark an item in the shared box, then move it via the ghost toggle.
        inst.finalBoxOf1Or4.set(cellCurrent: ITEMS.whiteSword, playerHas: .yes)
        inst.toggleSecondQuestDungeons()

        // 2Q: the extra box (and its item) is now under L4; the ghost is under L1.
        #expect(inst.isSecondQuestDungeons)
        #expect(inst.ghostBoxDungeonId == 0)
        #expect(inst.dungeon(3).boxes.last === inst.finalBoxOf1Or4)
        #expect(inst.dungeon(3).boxes.last?.cellCurrent == ITEMS.whiteSword)
        #expect(inst.dungeon(0).boxes.allSatisfy { $0 !== inst.finalBoxOf1Or4 })

        // Toggling back restores the first-quest arrangement.
        inst.toggleSecondQuestDungeons()
        #expect(inst.ghostBoxDungeonId == 3)
        #expect(inst.dungeon(0).boxes.last === inst.finalBoxOf1Or4)
    }

    @Test("HDN mode has no shared box, so no ghost placeholder")
    func ghostBoxNoneInHDN() {
        let inst = DungeonTrackerInstance(kind: .hideDungeonNumbers)
        #expect(inst.ghostBoxDungeonId == nil)
    }

    @Test("allBoxes flattens to 23 (19 base + finalBox + 3 standalone) in either quest")
    func allBoxesCount() {
        for isSecond in [false, true] {
            let inst = DungeonTrackerInstance(isSecondQuestDungeons: isSecond)
            #expect(inst.allBoxes().count == 23)
        }
    }

    @Test("the three standalone boxes are pre-set to SKIPPED and included in allBoxes")
    func standaloneBoxes() {
        let inst = DungeonTrackerInstance()
        #expect(inst.ladderBox.playerHas == .skipped)
        #expect(inst.armosBox.playerHas == .skipped)
        #expect(inst.sword2Box.playerHas == .skipped)

        let all = inst.allBoxes()
        #expect(all.contains { $0 === inst.ladderBox })
        #expect(all.contains { $0 === inst.armosBox })
        #expect(all.contains { $0 === inst.sword2Box })
    }

    @Test("allBoxProgress: 0 when all empty-red, rises as boxes are touched, caps at 1.0")
    func allBoxProgress() {
        let inst = DungeonTrackerInstance()
        // standalone boxes are SKIPPED (not empty-red), so start is 3/20
        #expect(inst.allBoxProgress == 3.0 / 20.0)

        // touch enough boxes to exceed the divisor and confirm the 1.0 cap
        for box in inst.allBoxes() {
            box.set(cellCurrent: 0, playerHas: .yes)
        }
        #expect(inst.allBoxProgress == 1.0)
    }
}

@Suite("Dungeon completion & triforce (DEFAULT mode)")
struct DungeonCompletionTests {
    @Test("toggleTriforce flips and getTriforceHaves reflects per-dungeon state")
    func triforce() {
        let inst = DungeonTrackerInstance()
        #expect(inst.getTriforceHaves() == Array(repeating: false, count: 8))
        #expect(inst.getTriforceHaves().count == 8)

        inst.dungeon(2).toggleTriforce()
        inst.dungeon(5).toggleTriforce()
        var expected = Array(repeating: false, count: 8)
        expected[2] = true
        expected[5] = true
        #expect(inst.getTriforceHaves() == expected)

        // dungeon 9 (index 8) is excluded from the 8-piece array entirely
        inst.dungeon(8).toggleTriforce()
        #expect(inst.getTriforceHaves() == expected)
    }

    @Test("complete requires triforce AND every effective box done")
    func completionScenarios() {
        let inst = DungeonTrackerInstance(isSecondQuestDungeons: false)
        let d1 = inst.dungeon(0) // 3 boxes in first quest

        // nothing done -> not complete
        #expect(d1.isComplete == false)

        // all boxes done but no triforce -> not complete
        for box in d1.boxes { box.set(cellCurrent: 0, playerHas: .yes) }
        #expect(d1.isComplete == false)

        // triforce added -> complete
        d1.toggleTriforce()
        #expect(d1.isComplete == true)

        // undo one box -> not complete again
        d1.boxes[1].set(cellCurrent: -1, playerHas: .no)
        #expect(d1.isComplete == false)
    }

    @Test("a skipped box still counts toward completion")
    func skippedBoxCompletes() {
        let inst = DungeonTrackerInstance()
        let d2 = inst.dungeon(1) // 2 boxes
        d2.toggleTriforce()
        d2.boxes[0].set(cellCurrent: 5, playerHas: .yes)
        d2.boxes[1].set(cellCurrent: 3, playerHas: .skipped)
        #expect(d2.isComplete == true)
    }

    @Test("completing dungeon 1's shared third box is visible only in the quest that owns it")
    func sharedBoxQuestScoping() {
        let inst = DungeonTrackerInstance(isSecondQuestDungeons: false)
        // In first quest, finalBoxOf1Or4 belongs to dungeon 1.
        inst.dungeon(0).toggleTriforce()
        for box in inst.dungeon(0).boxes { box.set(cellCurrent: 0, playerHas: .yes) }
        #expect(inst.dungeon(0).isComplete == true)

        // Switching to second quest re-parents that box to dungeon 4, so
        // dungeon 1 now has only its 2 base boxes (both still done) — and
        // dungeon 4 inherits the now-done shared box but lacks triforce.
        inst.isSecondQuestDungeons = true
        #expect(inst.dungeon(0).boxes.count == 2)
        #expect(inst.dungeon(0).isComplete == true) // 2 base boxes done + triforce
        #expect(inst.dungeon(3).isComplete == false) // no triforce
    }
}
