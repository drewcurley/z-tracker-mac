import Testing
@testable import TrackerCore

@Suite("DungeonBlocker")
struct DungeonBlockerTests {
    @Test("all 16 cases in the reference's order")
    func allCases() {
        #expect(DungeonBlocker.allCases.count == 16)
        #expect(DungeonBlocker.allCases.first == .bowAndArrow)
        #expect(DungeonBlocker.allCases.last == .nothing)
        // The 8 definite blockers come first, then 7 maybe*, then nothing.
        #expect(DungeonBlocker.allCases[7] == .combat)
        #expect(DungeonBlocker.allCases[8] == .maybeBowAndArrow)
    }

    @Test("hardCanonical collapses maybe* to the definite form")
    func hardCanonical() {
        #expect(DungeonBlocker.maybeBowAndArrow.hardCanonical == .bowAndArrow)
        #expect(DungeonBlocker.maybeRecorder.hardCanonical == .recorder)
        #expect(DungeonBlocker.maybeLadder.hardCanonical == .ladder)
        #expect(DungeonBlocker.maybeBait.hardCanonical == .bait)
        #expect(DungeonBlocker.maybeKey.hardCanonical == .key)
        #expect(DungeonBlocker.maybeBomb.hardCanonical == .bomb)
        #expect(DungeonBlocker.maybeMoney.hardCanonical == .money)
        // Definite forms and combat/nothing map to themselves.
        #expect(DungeonBlocker.ladder.hardCanonical == .ladder)
        #expect(DungeonBlocker.combat.hardCanonical == .combat)
        #expect(DungeonBlocker.nothing.hardCanonical == .nothing)
    }

    @Test("isMaybe: only the maybe* variants (T-019.2)")
    func isMaybe() {
        for b in DungeonBlocker.allCases {
            let expected = String(describing: b).hasPrefix("maybe")
            #expect(b.isMaybe == expected)
        }
        #expect(!DungeonBlocker.nothing.isMaybe)
        #expect(!DungeonBlocker.combat.isMaybe)
        #expect(DungeonBlocker.maybeBomb.isMaybe)
    }

    @Test("playerCouldBeBlockedByThis is stale only once the gating item is held")
    func playerCouldBeBlocked() {
        let none = PlayerComputedStateSummary()
        // Ladder: blocked until haveLadder.
        #expect(DungeonBlocker.ladder.playerCouldBeBlockedByThis(none))
        #expect(!DungeonBlocker.ladder.playerCouldBeBlockedByThis(PlayerComputedStateSummary(haveLadder: true)))
        // maybe* uses hardCanonical, same staleness.
        #expect(!DungeonBlocker.maybeLadder.playerCouldBeBlockedByThis(PlayerComputedStateSummary(haveLadder: true)))

        // Recorder.
        #expect(DungeonBlocker.recorder.playerCouldBeBlockedByThis(none))
        #expect(!DungeonBlocker.recorder.playerCouldBeBlockedByThis(PlayerComputedStateSummary(haveRecorder: true)))

        // Bow & arrow needs BOTH bow and arrowLevel > 0.
        #expect(DungeonBlocker.bowAndArrow.playerCouldBeBlockedByThis(PlayerComputedStateSummary(haveBow: true, arrowLevel: 0)))
        #expect(DungeonBlocker.bowAndArrow.playerCouldBeBlockedByThis(PlayerComputedStateSummary(haveBow: false, arrowLevel: 2)))
        #expect(!DungeonBlocker.bowAndArrow.playerCouldBeBlockedByThis(PlayerComputedStateSummary(haveBow: true, arrowLevel: 1)))

        // Key.
        #expect(DungeonBlocker.key.playerCouldBeBlockedByThis(none))
        #expect(!DungeonBlocker.key.playerCouldBeBlockedByThis(PlayerComputedStateSummary(haveAnyKey: true)))

        // Everything else is always "could be blocked".
        for b in [DungeonBlocker.combat, .bait, .money, .bomb, .nothing] {
            #expect(b.playerCouldBeBlockedByThis(PlayerComputedStateSummary(
                haveRecorder: true, haveLadder: true, haveAnyKey: true, haveBow: true, arrowLevel: 2)))
        }
    }

    @Test("asHotKeyName round-trips through fromHotKeyName; unknown -> nothing")
    func hotKeyNameRoundTrip() {
        for b in DungeonBlocker.allCases {
            #expect(DungeonBlocker.fromHotKeyName(b.asHotKeyName) == b)
        }
        #expect(DungeonBlocker.ladder.asHotKeyName == "Blocker_Ladder")
        #expect(DungeonBlocker.maybeBowAndArrow.asHotKeyName == "Blocker_Maybe_Bow_And_Arrow")
        #expect(DungeonBlocker.fromHotKeyName("nonsense") == .nothing)
    }

    @Test("next/prev cycle through allCases with wraparound")
    func nextPrev() {
        #expect(DungeonBlocker.bowAndArrow.next == .recorder)
        #expect(DungeonBlocker.nothing.next == .bowAndArrow)   // wrap forward
        #expect(DungeonBlocker.bowAndArrow.prev == .nothing)   // wrap backward
        #expect(DungeonBlocker.recorder.prev == .bowAndArrow)
    }

    @Test("displayDescription spot-check")
    func displayDescription() {
        #expect(DungeonBlocker.combat.displayDescription == "Need better\nweapon/armor")
        #expect(DungeonBlocker.bait.displayDescription == "Need meat")
        #expect(DungeonBlocker.nothing.displayDescription == "Unmarked")
    }
}

@Suite("DungeonBlockersContainer")
struct DungeonBlockersContainerTests {
    @Test("defaults to NOTHING everywhere with no applies-to")
    func defaults() {
        let c = DungeonBlockersContainer()
        for i in 0..<8 {
            for j in 0..<3 {
                #expect(c.dungeonBlocker(dungeon: i, slot: j) == .nothing)
                for k in 0..<DungeonBlockerAppliesTo.max {
                    #expect(c.dungeonBlockerAppliesTo(dungeon: i, slot: j, element: k) == false)
                }
            }
        }
    }

    @Test("blocker + applies-to set/get are independent per (dungeon, slot, element)")
    func setGet() {
        let c = DungeonBlockersContainer()
        c.setDungeonBlocker(.ladder, dungeon: 2, slot: 1)
        c.setDungeonBlockerAppliesTo(true, dungeon: 2, slot: 1, element: 3) // box1

        #expect(c.dungeonBlocker(dungeon: 2, slot: 1) == .ladder)
        #expect(c.dungeonBlockerAppliesTo(dungeon: 2, slot: 1, element: 3))
        // Neighbors untouched.
        #expect(c.dungeonBlocker(dungeon: 2, slot: 0) == .nothing)
        #expect(c.dungeonBlockerAppliesTo(dungeon: 2, slot: 1, element: 0) == false)
    }

    @Test("asJsonString matches the reference save shape")
    func asJsonString() {
        let c = DungeonBlockersContainer()
        c.setDungeonBlocker(.bomb, dungeon: 0, slot: 0)
        c.setDungeonBlockerAppliesTo(true, dungeon: 0, slot: 0, element: 1) // compass
        #expect(c.asJsonString(dungeon: 0, slot: 0)
            == "{ \"Kind\": \"Blocker_Bomb\", \"AppliesTo\": [ false, true, false, false, false, false ] }")
    }

    @Test("Element indices + box(n) helper match the reference order")
    func elementIndices() {
        #expect(DungeonBlockerAppliesTo.Element.triforce.rawValue == 2)
        #expect(DungeonBlockerAppliesTo.Element.box(0) == 3)
        #expect(DungeonBlockerAppliesTo.Element.box(2) == 5)
    }

    @Test("blockersApplyingTo: only set kinds with the element flag on, by slot")
    func blockersApplyingTo() {
        let c = DungeonBlockersContainer()
        let triforce = DungeonBlockerAppliesTo.Element.triforce.rawValue
        // Slot 0: ladder applies to triforce. Slot 1: key applies to a box, not triforce.
        c.setDungeonBlocker(.ladder, dungeon: 3, slot: 0)
        c.setDungeonBlockerAppliesTo(true, dungeon: 3, slot: 0, element: triforce)
        c.setDungeonBlocker(.key, dungeon: 3, slot: 1)
        c.setDungeonBlockerAppliesTo(true, dungeon: 3, slot: 1, element: DungeonBlockerAppliesTo.Element.box(0))
        // Slot 2: nothing kind, flag on → excluded (a cleared blocker chips nothing).
        c.setDungeonBlockerAppliesTo(true, dungeon: 3, slot: 2, element: triforce)

        #expect(c.blockersApplyingTo(dungeon: 3, element: triforce) == [.ladder])
        #expect(c.blockersApplyingTo(dungeon: 3, element: DungeonBlockerAppliesTo.Element.box(0)) == [.key])
        #expect(c.blockersApplyingTo(dungeon: 3, element: DungeonBlockerAppliesTo.Element.box(1)).isEmpty)
    }
}
