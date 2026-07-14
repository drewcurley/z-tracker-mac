import Testing
@testable import TrackerCore

@Suite("Basement-stair metadata (StairKind / currentlyHasBasementStair)")
struct BasementStairTests {
    @Test("DEFAULT box StairKind assignment matches the reference table")
    func defaultStairKinds() {
        let inst = DungeonTrackerInstance() // default, first quest
        // L1 (id 0): both never.
        #expect(inst.dungeon(0).baseBoxes.map(\.stair) == [.never, .never])
        // L2 (id 1): j1 = likeL2.
        #expect(inst.dungeon(1).baseBoxes[1].stair == .likeL2)
        // L3 (id 2): j1 = likeL3.
        #expect(inst.dungeon(2).baseBoxes[1].stair == .likeL3)
        // L8 (id 7): j0 never, j1 always, j2 always.
        #expect(inst.dungeon(7).baseBoxes.map(\.stair) == [.never, .always, .always])
        // L9 (id 8): all always.
        #expect(inst.dungeon(8).baseBoxes.allSatisfy { $0.stair == .always })
        // The shared box is always; standalone boxes are never.
        #expect(inst.finalBoxOf1Or4.stair == .always)
        #expect(inst.ladderBox.stair == .never)
    }

    @Test("DEFAULT currentlyHasBasementStair keys on StairKind + quest")
    func defaultBasement() {
        let firstQ = DungeonTrackerInstance(isSecondQuestDungeons: false)
        // likeL3 (L3 box) -> basement in FIRST quest only.
        #expect(firstQ.currentlyHasBasementStair(firstQ.dungeon(2).baseBoxes[1]) == true)
        // likeL2 (L2 box) -> not basement in first quest.
        #expect(firstQ.currentlyHasBasementStair(firstQ.dungeon(1).baseBoxes[1]) == false)
        // always / never.
        #expect(firstQ.currentlyHasBasementStair(firstQ.finalBoxOf1Or4) == true)
        #expect(firstQ.currentlyHasBasementStair(firstQ.dungeon(0).baseBoxes[0]) == false)

        let secondQ = DungeonTrackerInstance(isSecondQuestDungeons: true)
        // Quest flips likeL2/likeL3.
        #expect(secondQ.currentlyHasBasementStair(secondQ.dungeon(1).baseBoxes[1]) == true)  // likeL2
        #expect(secondQ.currentlyHasBasementStair(secondQ.dungeon(2).baseBoxes[1]) == false) // likeL3
    }

    @Test("HDN currentlyHasBasementStair keys on label + box index + quest")
    func hdnBasementFirstQuest() {
        let inst = DungeonTrackerInstance(kind: .hideDungeonNumbers, isSecondQuestDungeons: false)
        let d = inst.dungeon(0)

        d.labelChar = "3" // first quest: '3'..'7' -> basement iff n == 1
        #expect(inst.currentlyHasBasementStair(d.baseBoxes[0]) == false)
        #expect(inst.currentlyHasBasementStair(d.baseBoxes[1]) == true)
        #expect(inst.currentlyHasBasementStair(d.baseBoxes[2]) == false)

        d.labelChar = "1" // first quest: '1' -> basement iff n == 2
        #expect(inst.currentlyHasBasementStair(d.baseBoxes[2]) == true)
        #expect(inst.currentlyHasBasementStair(d.baseBoxes[1]) == false)

        d.labelChar = "2" // first quest: '2' -> never
        #expect(inst.currentlyHasBasementStair(d.baseBoxes[1]) == false)

        d.labelChar = "?" // unidentified -> false
        #expect(inst.currentlyHasBasementStair(d.baseBoxes[1]) == false)
    }

    @Test("HDN second-quest label table differs; dungeon 9 always has basements")
    func hdnBasementSecondQuestAndL9() {
        let inst = DungeonTrackerInstance(kind: .hideDungeonNumbers, isSecondQuestDungeons: true)
        let d = inst.dungeon(0)

        d.labelChar = "4" // second quest: '4'/'8' -> basement iff n == 1 || n == 2
        #expect(inst.currentlyHasBasementStair(d.baseBoxes[0]) == false)
        #expect(inst.currentlyHasBasementStair(d.baseBoxes[1]) == true)
        #expect(inst.currentlyHasBasementStair(d.baseBoxes[2]) == true)

        d.labelChar = "1" // second quest: '1'/'3' -> never
        #expect(inst.currentlyHasBasementStair(d.baseBoxes[1]) == false)

        // Dungeon 9 (id 8) has all basements regardless of label.
        let d9 = inst.dungeon(8)
        #expect(d9.baseBoxes.allSatisfy { inst.currentlyHasBasementStair($0) })
    }
}
