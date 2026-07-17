import Testing
@testable import TrackerCore

@Suite("Timeline model (T-098)")
struct TimelineModelTests {
    @Test("current() reflects item/triforce/take-any/ganon-zelda acquisition")
    func currentEvents() {
        let dt = DungeonTrackerInstance()
        dt.dungeon(0).toggleTriforce()          // triforce 1
        dt.dungeon(4).toggleTriforce()          // triforce 5
        let progress = PlayerProgressAndTakeAnyHearts()
        progress.hasDefeatedGanon = true
        progress.takeAnyHearts[1] = .takenHeart // heart 2
        let player = PlayerComputedStateSummary(haveRecorder: true, haveLadder: true, swordLevel: 2)

        let s = TimelineEvents.current(playerState: player, progress: progress,
                                       dungeonTracker: dt, isCurrentlyBook: true)
        #expect(s.contains(.recorder))
        #expect(s.contains(.ladder))
        #expect(s.contains(.woodSword))      // swordLevel 2 → wood + white
        #expect(s.contains(.whiteSword))
        #expect(!s.contains(.magicalSword))  // not level 3
        #expect(s.contains(.triforce(1)))
        #expect(s.contains(.triforce(5)))
        #expect(!s.contains(.triforce(2)))
        #expect(s.contains(.takeAnyHeart(2)))
        #expect(!s.contains(.takeAnyHeart(1)))
        #expect(s.contains(.defeatedGanon))
        #expect(!s.contains(.rescuedZelda))
    }

    @Test("record stamps first acquisition, ignores later ticks, drops un-marked")
    func recordStampsAndDrops() {
        let m = TimelineModel()
        m.record(elapsedSeconds: 65, acquired: [.recorder], owRemaining: 80, finished: false)
        #expect(m.acquiredAt[.recorder] == 65)                 // stamped at first sight
        m.record(elapsedSeconds: 130, acquired: [.recorder, .ladder], owRemaining: 78, finished: false)
        #expect(m.acquiredAt[.recorder] == 65)                 // unchanged
        #expect(m.acquiredAt[.ladder] == 130)                  // new
        m.record(elapsedSeconds: 200, acquired: [.ladder], owRemaining: 70, finished: false)
        #expect(m.acquiredAt[.recorder] == nil)                // un-marked → dropped
        // Re-acquiring re-stamps at the new time.
        m.record(elapsedSeconds: 260, acquired: [.ladder, .recorder], owRemaining: 60, finished: false)
        #expect(m.acquiredAt[.recorder] == 260)
    }

    @Test("finish snapshot captured on finished, cleared when un-finished")
    func finishSnapshot() {
        let m = TimelineModel()
        m.record(elapsedSeconds: 3600, acquired: [.rescuedZelda], owRemaining: 5, finished: true)
        #expect(m.finishSeconds == 3600)
        #expect(m.finishOwRemaining == 5)
        // Later ticks keep the first finish time.
        m.record(elapsedSeconds: 3700, acquired: [.rescuedZelda], owRemaining: 5, finished: true)
        #expect(m.finishSeconds == 3600)
        // Un-rescuing clears it.
        m.record(elapsedSeconds: 3800, acquired: [], owRemaining: 5, finished: false)
        #expect(m.finishSeconds == nil)
    }
}
