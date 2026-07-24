import Testing
@testable import TrackerCore

/// T-169 — the Unmark–Remark "Blocker(X) logic": promote a maybe to full, else mark a
/// fresh maybe, else no-op; skip dungeon 9 and skip blockers whose unblocker is held.
@Suite("Maybe-blocker logic (T-169)")
@MainActor
struct MaybeBlockerLogicTests {

    @Test("first press marks a fresh maybe in the first empty slot")
    func addsMaybe() {
        let c = DungeonBlockersContainer()
        let outcome = c.applyMaybeBlockerLogic(.maybeLadder, dungeon: 2, playerState: .init())
        #expect(outcome == .addedMaybe)
        #expect(c.dungeonBlocker(dungeon: 2, slot: 0) == .maybeLadder)
    }

    @Test("second press promotes the maybe to the hard blocker in place")
    func promotesMaybe() {
        let c = DungeonBlockersContainer()
        c.setDungeonBlocker(.maybeLadder, dungeon: 2, slot: 1)
        let outcome = c.applyMaybeBlockerLogic(.maybeLadder, dungeon: 2, playerState: .init())
        #expect(outcome == .promotedToFull)
        #expect(c.dungeonBlocker(dungeon: 2, slot: 1) == .ladder)   // promoted in the SAME slot
        #expect(c.dungeonBlocker(dungeon: 2, slot: 0) == .nothing)  // no new slot used
    }

    @Test("a hard blocker already present is a no-op")
    func alreadyBlocked() {
        let c = DungeonBlockersContainer()
        c.setDungeonBlocker(.ladder, dungeon: 2, slot: 0)
        let outcome = c.applyMaybeBlockerLogic(.maybeLadder, dungeon: 2, playerState: .init())
        #expect(outcome == .alreadyBlocked)
        #expect(c.dungeonBlocker(dungeon: 2, slot: 1) == .nothing)  // nothing added
    }

    @Test("promotion wins over an empty slot when both a maybe and a gap exist")
    func promotePreferredOverAdd() {
        let c = DungeonBlockersContainer()
        c.setDungeonBlocker(.maybeLadder, dungeon: 3, slot: 2)      // maybe in the last slot
        let outcome = c.applyMaybeBlockerLogic(.maybeLadder, dungeon: 3, playerState: .init())
        #expect(outcome == .promotedToFull)
        #expect(c.dungeonBlocker(dungeon: 3, slot: 2) == .ladder)
        #expect(c.dungeonBlocker(dungeon: 3, slot: 0) == .nothing)
    }

    @Test("no empty slot and no matching maybe → no-op")
    func noEmptySlot() {
        let c = DungeonBlockersContainer()
        c.setDungeonBlocker(.bomb, dungeon: 4, slot: 0)
        c.setDungeonBlocker(.recorder, dungeon: 4, slot: 1)
        c.setDungeonBlocker(.bait, dungeon: 4, slot: 2)
        let outcome = c.applyMaybeBlockerLogic(.maybeLadder, dungeon: 4, playerState: .init())
        #expect(outcome == .noEmptySlot)
    }

    @Test("dungeon 9 (index 8) never takes a blocker")
    func dungeon9Skipped() {
        let c = DungeonBlockersContainer()
        let outcome = c.applyMaybeBlockerLogic(.maybeLadder, dungeon: 8, playerState: .init())
        #expect(outcome == .dungeon9)
        #expect(c.dungeonBlocker(dungeon: 8, slot: 0) == .nothing)
    }

    @Test("a blocker whose unblocker the player already holds is skipped as stale")
    func staleUnblockerHeld() {
        let c = DungeonBlockersContainer()
        let outcome = c.applyMaybeBlockerLogic(.maybeLadder, dungeon: 2,
                                               playerState: .init(haveLadder: true))
        #expect(outcome == .unblockerHeld)
        #expect(c.dungeonBlocker(dungeon: 2, slot: 0) == .nothing)
    }
}
