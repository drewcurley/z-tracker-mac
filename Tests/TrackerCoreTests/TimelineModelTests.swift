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
        progress.hasWoodSword = true            // actual wood-sword pickup
        progress.takeAnyHearts[1] = .takenHeart // heart 2
        let starting = StartingItemsAndExtras()
        starting.hasWhiteSword = true           // actual white-sword pickup
        let player = PlayerComputedStateSummary(haveRecorder: true, haveLadder: true)

        let s = TimelineEvents.current(playerState: player, progress: progress,
                                       startingItems: starting, dungeonTracker: dt,
                                       isWSMSReplacedByBU: false, isCurrentlyBook: true)
        #expect(s.contains(.recorder))
        #expect(s.contains(.ladder))
        #expect(s.contains(.woodSword))
        #expect(s.contains(.whiteSword))
        #expect(!s.contains(.magicalSword))
        #expect(s.contains(.triforce(1)))
        #expect(s.contains(.triforce(5)))
        #expect(!s.contains(.triforce(2)))
        #expect(s.contains(.takeAnyHeart(2)))
        #expect(!s.contains(.takeAnyHeart(1)))
        #expect(s.contains(.defeatedGanon))
        #expect(!s.contains(.rescuedZelda))
    }

    @Test("tiered items reflect actual pickups, not a derived lower tier (T-113)")
    func actualPickupsNoPhantomTier() {
        let dt = DungeonTrackerInstance()
        let progress = PlayerProgressAndTakeAnyHearts()
        let starting = StartingItemsAndExtras()
        // Got the SILVER arrow directly (no wood arrow ever picked up).
        starting.hasSilverArrow = true
        // Got the RED candle directly (no blue candle).
        starting.hasRedCandle = true
        let player = PlayerComputedStateSummary()

        let s = TimelineEvents.current(playerState: player, progress: progress,
                                       startingItems: starting, dungeonTracker: dt,
                                       isWSMSReplacedByBU: false, isCurrentlyBook: false)
        #expect(s.contains(.silverArrow))
        #expect(!s.contains(.woodArrow))     // no phantom wood arrow
        #expect(s.contains(.redCandle))
        #expect(!s.contains(.blueCandle))    // no phantom blue candle
    }

    @Test("bait + dungeon/coast heart containers appear on the timeline (T-113)")
    func heartsAndBait() {
        let dt = DungeonTrackerInstance()
        // A dungeon-1 box holds a collected heart container.
        dt.dungeon(0).boxes[0].set(cellCurrent: ITEMS.heartContainer, playerHas: .yes)
        // The coast item is a heart container.
        dt.ladderBox.set(cellCurrent: ITEMS.heartContainer, playerHas: .yes)
        let progress = PlayerProgressAndTakeAnyHearts()
        progress.hasMeat = true
        let s = TimelineEvents.current(playerState: PlayerComputedStateSummary(), progress: progress,
                                       startingItems: StartingItemsAndExtras(), dungeonTracker: dt,
                                       isWSMSReplacedByBU: false, isCurrentlyBook: false)
        #expect(s.contains(.dungeonHeart(1)))
        #expect(!s.contains(.dungeonHeart(2)))
        #expect(s.contains(.coastHeart))
        #expect(s.contains(.bait))
    }

    @Test("locations map box items to LEVEL/BOARD box labels and coast (T-114)")
    func boxLocations() {
        let dt = DungeonTrackerInstance()
        // Dungeon 3, box 1 holds a collected silver arrow.
        dt.dungeon(2).boxes[0].set(cellCurrent: ITEMS.silverArrow, playerHas: .yes)
        // Dungeon 1, box 2 holds a collected heart container.
        dt.dungeon(0).boxes[1].set(cellCurrent: ITEMS.heartContainer, playerHas: .yes)
        // The coast item is the ladder.
        dt.ladderBox.set(cellCurrent: ITEMS.ladder, playerHas: .yes)

        let loc = TimelineEvents.locations(dungeonTracker: dt, boardInsteadOfLevel: false,
                                           hideDungeonNumbers: false)
        #expect(loc[.silverArrow] == "LEVEL-3 Box 1")
        #expect(loc[.dungeonHeart(1)] == "LEVEL-1 Box 2")
        #expect(loc[.ladder] == "Coast")

        // BOARD naming + HDN letters flow through.
        let board = TimelineEvents.locations(dungeonTracker: dt, boardInsteadOfLevel: true,
                                             hideDungeonNumbers: true)
        #expect(board[.silverArrow] == "BOARD-C Box 1")
    }

    @Test("record stores locations for acquired events and prunes the rest (T-114)")
    func recordLocations() {
        let m = TimelineModel()
        m.record(elapsedSeconds: 100, acquired: [.silverArrow], owRemaining: 50, finished: false,
                 locations: [.silverArrow: "LEVEL-3 Box 1", .ladder: "Coast"])
        // Only the acquired event's location is kept.
        #expect(m.acquiredLocation[.silverArrow] == "LEVEL-3 Box 1")
        #expect(m.acquiredLocation[.ladder] == nil)
        // Dropping the event drops its location.
        m.record(elapsedSeconds: 160, acquired: [], owRemaining: 50, finished: false)
        #expect(m.acquiredLocation[.silverArrow] == nil)
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

    @Test("OW-remaining series samples only on change; extends latestSeconds (T-099)")
    func owSeries() {
        let m = TimelineModel()
        m.record(elapsedSeconds: 0, acquired: [], owRemaining: 100, finished: false)
        m.record(elapsedSeconds: 30, acquired: [], owRemaining: 100, finished: false)  // no change
        m.record(elapsedSeconds: 60, acquired: [], owRemaining: 98, finished: false)   // change
        m.record(elapsedSeconds: 90, acquired: [], owRemaining: 98, finished: false)   // no change
        m.record(elapsedSeconds: 120, acquired: [], owRemaining: 95, finished: false)  // change
        #expect(m.owRemainingSamples == [
            .init(seconds: 0, remaining: 100),
            .init(seconds: 60, remaining: 98),
            .init(seconds: 120, remaining: 95),
        ])
        #expect(m.latestSeconds == 120)
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
