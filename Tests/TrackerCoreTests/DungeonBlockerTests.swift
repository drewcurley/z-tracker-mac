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
}
