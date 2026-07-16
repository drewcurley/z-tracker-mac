import Foundation
import Testing
@testable import TrackerCore

@Suite("ReminderEngine")
struct ReminderEngineTests {
    private let instance = OverworldInstance(quest: .first)
    /// A safe non-always-empty first-quest screen to place marks on.
    private let safe = (x: 0, y: 7)
    private let safe2 = (x: 1, y: 2)

    private func poll(
        _ engine: ReminderEngine,
        grid: OverworldGrid = OverworldGrid(),
        dungeonTracker: DungeonTrackerInstance = DungeonTrackerInstance(),
        blockers: DungeonBlockersContainer = DungeonBlockersContainer(),
        playerState: PlayerComputedStateSummary = PlayerComputedStateSummary(),
        progress: PlayerProgressAndTakeAnyHearts = PlayerProgressAndTakeAnyHearts(),
        startingItems: StartingItemsAndExtras = StartingItemsAndExtras(),
        doorRepairFound: Int = 0,
        doorRepairMax: Int = 9,
        now: Date = Date(timeIntervalSince1970: 0),
        coastItemValue: Int = -1,
        isCurrentlyBook: Bool = true,
        whistleSpotsRemain: Int = 0,
        powerBraceletSpotsRemain: Int = 0,
        bookShopMarked: Bool = false,
        bookForHelpfulHints: Bool = false
    ) -> [ReminderAnnouncement] {
        let mapState = MapStateSummary.compute(
            grid: grid, instance: instance, dungeonTracker: dungeonTracker,
            playerState: playerState, progress: progress,
            drawRoutes: false, routesCanScreenScroll: false, mirrorOverworld: false)
        let tag = TriforceAndGoSummary.compute(
            playerState: playerState, dungeonTracker: dungeonTracker, mapState: mapState,
            progress: progress, grid: grid, instance: instance)
        return engine.poll(
            playerState: playerState, mapState: mapState, dungeonTracker: dungeonTracker,
            blockers: blockers, progress: progress, startingItems: startingItems, tagSummary: tag,
            doorRepairFound: doorRepairFound, doorRepairMax: doorRepairMax,
            now: now, coastItemValue: coastItemValue, isCurrentlyBook: isCurrentlyBook,
            whistleSpotsRemain: whistleSpotsRemain, powerBraceletSpotsRemain: powerBraceletSpotsRemain,
            bookShopMarked: bookShopMarked, bookForHelpfulHints: bookForHelpfulHints)
    }

    @Test("book → visit-hints fires once, only when the hints flag is on (T-092)")
    func visitHints() {
        let withBook = PlayerComputedStateSummary(haveBookOrShield: true)
        // Flag off → no nudge even with the book.
        #expect(!poll(ReminderEngine(), playerState: withBook, isCurrentlyBook: true,
                      bookForHelpfulHints: false).contains(.remindVisitHints))
        // Flag on + have the book → fires once, then goes quiet.
        let engine = ReminderEngine()
        #expect(poll(engine, playerState: withBook, isCurrentlyBook: true,
                     bookForHelpfulHints: true).contains(.remindVisitHints))
        #expect(!poll(engine, playerState: withBook, isCurrentlyBook: true,
                      bookForHelpfulHints: true).contains(.remindVisitHints))
        // Shield seed (item 0 is the shield, not the book) → no hints nudge.
        #expect(!poll(ReminderEngine(), playerState: withBook, isCurrentlyBook: false,
                      bookForHelpfulHints: true).contains(.remindVisitHints))
    }

    @Test("door-repair count announces on each increase, then goes quiet")
    func doorRepair() {
        let engine = ReminderEngine()
        // First charge marked → "1 of 9".
        #expect(poll(engine, doorRepairFound: 1, doorRepairMax: 9)
                .contains(.doorRepairCount(found: 1, max: 9)))
        // Same count next poll → nothing.
        #expect(!poll(engine, doorRepairFound: 1, doorRepairMax: 9)
                .contains(where: { if case .doorRepairCount = $0 { return true }; return false }))
        // Another charge → "2 of 9".
        #expect(poll(engine, doorRepairFound: 2, doorRepairMax: 9)
                .contains(.doorRepairCount(found: 2, max: 9)))
    }

    @Test("a fresh poll with nothing set emits nothing")
    func freshEmpty() {
        #expect(poll(ReminderEngine()).isEmpty)
    }

    // MARK: Periodic reminders (T-089)

    private func hasCoast(_ out: [ReminderAnnouncement]) -> Bool {
        out.contains { if case .getCoastItem = $0 { return true }; return false }
    }

    @Test("coast item: fires while ladder-but-no-coast, respects the 3-min cooldown")
    func coastItem() {
        let engine = ReminderEngine()
        let player = PlayerComputedStateSummary(haveLadder: true, haveCoastItem: false)
        let t0 = Date(timeIntervalSince1970: 0)
        // Unknown coast item → generic text; fires on the first poll.
        #expect(poll(engine, playerState: player, now: t0, coastItemValue: -1)
                .contains(.getCoastItem(itemName: nil)))
        // Same tick → cooldown blocks a repeat.
        #expect(!hasCoast(poll(engine, playerState: player, now: t0, coastItemValue: -1)))
        // 3+ minutes later, with a known item → names it.
        let t3 = Date(timeIntervalSince1970: 200)
        #expect(poll(engine, playerState: player, now: t3, coastItemValue: ITEMS.whiteSword)
                .contains(.getCoastItem(itemName: "white sword")))
    }

    @Test("coast item: white-sword nag suppressed once you have the magical sword")
    func coastItemWhiteSwordSuppressed() {
        let engine = ReminderEngine()
        let player = PlayerComputedStateSummary(haveLadder: true, haveCoastItem: false)
        let progress = PlayerProgressAndTakeAnyHearts(); progress.hasMagicalSword = true
        #expect(!hasCoast(poll(engine, playerState: player, progress: progress,
                               now: Date(timeIntervalSince1970: 0), coastItemValue: ITEMS.whiteSword)))
    }

    @Test("recorder spots: announces the count, stays quiet as the count shrinks")
    func recorderSpots() {
        let engine = ReminderEngine()
        let player = PlayerComputedStateSummary(haveRecorder: true)
        #expect(poll(engine, playerState: player, now: Date(timeIntervalSince1970: 0), whistleSpotsRemain: 3)
                .contains(.recorderSpots(3)))
        // 5+ min later with fewer spots (progress) → no nag.
        let out = poll(engine, playerState: player, now: Date(timeIntervalSince1970: 400), whistleSpotsRemain: 2)
        #expect(!out.contains { if case .recorderSpots = $0 { return true }; return false })
    }

    @Test("power-bracelet spots announce the count")
    func powerBraceletSpots() {
        let engine = ReminderEngine()
        let player = PlayerComputedStateSummary(havePowerBracelet: true)
        #expect(poll(engine, playerState: player, now: Date(timeIntervalSince1970: 0), powerBraceletSpotsRemain: 1)
                .contains(.powerBraceletSpots(1)))
    }

    @Test("boomstick book: fires with wand + no book + a marked book shop")
    func boomstickBook() {
        let engine = ReminderEngine()
        let player = PlayerComputedStateSummary(haveWand: true)
        #expect(poll(engine, playerState: player, now: Date(timeIntervalSince1970: 0), bookShopMarked: true)
                .contains(.considerBoomstickBook))
        // No book shop marked → nothing.
        #expect(!poll(ReminderEngine(), playerState: player,
                      now: Date(timeIntervalSince1970: 0), bookShopMarked: false)
                .contains(.considerBoomstickBook))
    }

    @Test("consider-sword2 fires once when hearts hit 4-6 with a known white-sword cave")
    func considerSword2() {
        let grid = OverworldGrid()
        grid.setMark(.swordCave(2), column: safe.x, row: safe.y)
        let engine = ReminderEngine()
        let player = PlayerComputedStateSummary(playerHearts: 4)

        #expect(poll(engine, grid: grid, playerState: player).contains(.considerSword2))
        // Second poll at the same heart count -> already announced.
        #expect(!poll(engine, grid: grid, playerState: player).contains(.considerSword2))
    }

    @Test("consider-sword2 suppressed once the white-sword item is held")
    func considerSword2Suppressed() {
        let grid = OverworldGrid()
        grid.setMark(.swordCave(2), column: safe.x, row: safe.y)
        let player = PlayerComputedStateSummary(haveWhiteSwordItem: true, playerHearts: 5)
        #expect(!poll(ReminderEngine(), grid: grid, playerState: player).contains(.considerSword2))
    }

    @Test("consider-sword3 fires at 10-14 hearts with a known magical-sword cave")
    func considerSword3() {
        let grid = OverworldGrid()
        grid.setMark(.swordCave(3), column: safe.x, row: safe.y)
        let player = PlayerComputedStateSummary(playerHearts: 11)
        #expect(poll(ReminderEngine(), grid: grid, playerState: player).contains(.considerSword3))
    }

    @Test("completed-dungeon fires once when a dungeon completes")
    func completedDungeon() {
        let dt = DungeonTrackerInstance()
        let engine = ReminderEngine()
        // Not complete yet.
        #expect(!poll(engine, dungeonTracker: dt).contains(.completedDungeon(0)))
        // Complete dungeon 1 (index 0).
        dt.dungeon(0).toggleTriforce()
        for box in dt.dungeon(0).boxes { box.set(cellCurrent: 0, playerHas: .yes) }
        let out = poll(engine, dungeonTracker: dt)
        #expect(out.contains(.completedDungeon(0)))
        // Not re-announced.
        #expect(!poll(engine, dungeonTracker: dt).contains(.completedDungeon(0)))
    }

    @Test("found-dungeon-count fires when a dungeon is marked on the map")
    func foundDungeonCount() {
        let grid = OverworldGrid()
        grid.setMark(.dungeon(1), column: safe.x, row: safe.y)
        let out = poll(ReminderEngine(), grid: grid)
        #expect(out.contains(.foundDungeonCount(1)))
    }

    @Test("triforce-count fires when a triforce is gained")
    func triforceCount() {
        let dt = DungeonTrackerInstance()
        let engine = ReminderEngine()
        dt.dungeon(0).toggleTriforce()
        #expect(poll(engine, dungeonTracker: dt).contains(.triforceCount(1)))
        #expect(!poll(engine, dungeonTracker: dt).contains(.triforceCount(1)))
    }

    @Test("triforce-and-go announces when the TAG level rises above 101")
    func triforceAndGo() {
        let dt = DungeonTrackerInstance()
        for i in 0...8 { dt.dungeon(i).toggleTriforce() }
        let player = PlayerComputedStateSummary(haveLadder: true, haveBow: true, arrowLevel: 2)
        let out = poll(ReminderEngine(), dungeonTracker: dt, playerState: player)
        #expect(out.contains { if case .triforceAndGo = $0 { return true } else { return false } })
    }

    @Test("acquiring an item unblocks dungeons blocked on it (generic blocker + item nudge)")
    func genericBlockerAndItemNudge() {
        let blockers = DungeonBlockersContainer()
        blockers.setDungeonBlocker(.ladder, dungeon: 1, slot: 0) // dungeon 2 is ladder-blocked
        let player = PlayerComputedStateSummary(haveLadder: true)
        let out = poll(ReminderEngine(), blockers: blockers, playerState: player)
        #expect(out.contains(.remindUnblock(blocker: .ladder, dungeons: [1], combatDetails: [])))
        #expect(out.contains(.remindShortly(itemId: ITEMS.ladder)))
    }

    @Test("a Level 9 blocker also produces an unblock reminder (T-090)")
    func level9BlockerReminds() {
        let blockers = DungeonBlockersContainer()
        blockers.setDungeonBlocker(.bomb, dungeon: 8, slot: 0) // L9 is bomb-blocked
        let progress = PlayerProgressAndTakeAnyHearts(); progress.hasBombs = true
        let out = poll(ReminderEngine(), blockers: blockers, progress: progress)
        #expect(out.contains(.remindUnblock(blocker: .bomb, dungeons: [8], combatDetails: [])))
    }

    @Test("maybe-blockers match via hardCanonical")
    func maybeBlockerMatches() {
        let blockers = DungeonBlockersContainer()
        blockers.setDungeonBlocker(.maybeLadder, dungeon: 3, slot: 2) // MAYBE_LADDER
        let player = PlayerComputedStateSummary(haveLadder: true)
        let out = poll(ReminderEngine(), blockers: blockers, playerState: player)
        #expect(out.contains(.remindUnblock(blocker: .ladder, dungeons: [3], combatDetails: [])))
    }

    @Test("a completed dungeon is not offered as an unblock target")
    func completedDungeonNotUnblocked() {
        let dt = DungeonTrackerInstance()
        let blockers = DungeonBlockersContainer()
        blockers.setDungeonBlocker(.ladder, dungeon: 1, slot: 0)
        // Complete dungeon 2 (index 1).
        dt.dungeon(1).toggleTriforce()
        for box in dt.dungeon(1).boxes { box.set(cellCurrent: 0, playerHas: .yes) }
        let player = PlayerComputedStateSummary(haveLadder: true)
        let out = poll(ReminderEngine(), dungeonTracker: dt, blockers: blockers, playerState: player)
        #expect(!out.contains { if case .remindUnblock = $0 { return true } else { return false } })
    }

    @Test("combat unblock fires on a sword upgrade for a combat-blocked dungeon")
    func combatUnblock() {
        let blockers = DungeonBlockersContainer()
        blockers.setDungeonBlocker(.combat, dungeon: 4, slot: 0)
        let player = PlayerComputedStateSummary(swordLevel: 2) // white sword acquired
        let out = poll(ReminderEngine(), blockers: blockers, playerState: player)
        #expect(out.contains(.remindUnblock(blocker: .combat, dungeons: [4], combatDetails: [.betterSword])))
    }

    @Test("blocker reminders are suppressed at full Triforce-and-Go (level 103)")
    func blockersSuppressedAtFullTag() {
        let dt = DungeonTrackerInstance()
        for i in 0...8 { dt.dungeon(i).toggleTriforce() }
        let blockers = DungeonBlockersContainer()
        blockers.setDungeonBlocker(.ladder, dungeon: 1, slot: 0)
        // level 103 requires bow + silvers + ladder; acquiring ladder also triggers the blocker path.
        let player = PlayerComputedStateSummary(haveLadder: true, haveBow: true, arrowLevel: 2)
        let out = poll(ReminderEngine(), dungeonTracker: dt, blockers: blockers, playerState: player)
        #expect(!out.contains { if case .remindUnblock = $0 { return true } else { return false } })
    }

    @Test("resetForGroundhogOrRouters re-arms one-shot announcements")
    func resetReArms() {
        let dt = DungeonTrackerInstance()
        let engine = ReminderEngine()
        dt.dungeon(0).toggleTriforce()
        for box in dt.dungeon(0).boxes { box.set(cellCurrent: 0, playerHas: .yes) }
        #expect(poll(engine, dungeonTracker: dt).contains(.completedDungeon(0)))
        #expect(!poll(engine, dungeonTracker: dt).contains(.completedDungeon(0)))
        engine.resetForGroundhogOrRouters()
        #expect(poll(engine, dungeonTracker: dt).contains(.completedDungeon(0)))
    }
}
