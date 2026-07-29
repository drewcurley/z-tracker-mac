import Testing
import Foundation
@testable import TrackerCore

/// T-164 — the full save-state snapshot survives a JSON round-trip and restores every
/// tracked field. Builds a richly-mutated model, snapshots it → JSON → back → restores
/// into a fresh model, and checks the state matches.
@Suite("Save-state round trip (T-164)")
@MainActor
struct SaveStateRoundTripTests {

    /// Mutate a model across every subsystem so the round trip exercises all of them.
    private func makeMutated() -> TrackerModel {
        let m = TrackerModel(quest: .first)
        m.selectQuest(.first)
        // scalars / flags
        m.heartShuffle = true
        m.isWSMSReplacedByBU = true
        m.isCurrentlyBook = false
        m.mirrorOverworld = true
        m.notes = "found bomb shop at D5\nlevel 3 has the ladder"
        m.startSpot = OverworldScreenCoordinate(x: 7, y: 3)
        m.customWaypoint = OverworldScreenCoordinate(x: 2, y: 5)
        m.recorderDestinationIndex = 4
        m.recorderDestinationManual = true
        m.levelHints[1] = .deathMountain
        m.setHideDungeonNumbers(true)
        // overworld grid
        m.overworldGrid.setMark(.shop(.bomb), column: 4, row: 3)
        m.overworldGrid.setShopSecondItem(.meat, column: 4, row: 3)
        m.overworldGrid.setMark(.dungeon(3), column: 8, row: 2)
        // dungeon room map 0
        let map = m.dungeonRoomMaps[0]
        map.setRoom(DungeonRoom(roomType: .staircaseToUnknown, monsterDetail: .gleeok,
                                floorDropDetail: .triforce), col: 2, row: 3)
        map.setHorizontalDoor(.yes, col: 1, row: 3)
        // blockers
        m.dungeonBlockers.setDungeonBlocker(.maybeLadder, dungeon: 4, slot: 1)
        // progress
        m.playerProgress.hasMagicalSword = true
        m.playerProgress.hasBombs = true
        m.playerProgress.hasRescuedZelda = false
        // dungeon item box
        m.dungeonTracker.dungeon(0).baseBoxes[0].set(cellCurrent: ITEMS.ladder, playerHas: .yes)
        m.dungeonTracker.dungeon(0).playerHasTriforce = true
        // timeline (T-098) — historical acquisition times, which can't be re-derived.
        m.timeline.record(elapsedSeconds: 125, acquired: [.ladder, .triforce(1)],
                          owRemaining: 60, finished: false, locations: [.ladder: "LEVEL-1 Box 1"])
        return m
    }

    @Test("snapshot → JSON → restore reproduces every subsystem")
    func roundTrips() throws {
        let original = makeMutated()
        let snap = original.snapshot()

        let data = try JSONEncoder().encode(snap)
        let decoded = try JSONDecoder().decode(TrackerModel.State.self, from: data)

        let restored = TrackerModel(quest: .first)
        restored.restore(decoded)

        // Flags / scalars
        #expect(restored.heartShuffle == true)
        #expect(restored.hideDungeonNumbers == true)
        #expect(restored.isWSMSReplacedByBU == true)
        #expect(restored.isCurrentlyBook == false)
        #expect(restored.mirrorOverworld == true)
        #expect(restored.notes == original.notes)
        #expect(restored.startSpot == OverworldScreenCoordinate(x: 7, y: 3))
        #expect(restored.customWaypoint == OverworldScreenCoordinate(x: 2, y: 5))
        #expect(restored.recorderDestinationIndex == 4)
        #expect(restored.recorderDestinationManual == true)
        #expect(restored.levelHints[1] == .deathMountain)
        // Overworld
        #expect(restored.overworldGrid.mark(column: 4, row: 3) == .shop(.bomb))
        #expect(restored.overworldGrid.shopSecondItem(column: 4, row: 3) == .meat)
        #expect(restored.overworldGrid.mark(column: 8, row: 2) == .dungeon(3))
        // Dungeon room map
        let rm = restored.dungeonRoomMaps[0].room(col: 2, row: 3)
        #expect(rm.roomType == .staircaseToUnknown)
        #expect(rm.monsterDetail == .gleeok)
        #expect(rm.floorDropDetail == .triforce)
        #expect(restored.dungeonRoomMaps[0].horizontalDoor(col: 1, row: 3) == .yes)
        // Blockers
        #expect(restored.dungeonBlockers.dungeonBlocker(dungeon: 4, slot: 1) == .maybeLadder)
        // Progress
        #expect(restored.playerProgress.hasMagicalSword == true)
        #expect(restored.playerProgress.hasBombs == true)
        // Dungeon item box
        #expect(restored.dungeonTracker.dungeon(0).baseBoxes[0].cellCurrent == ITEMS.ladder)
        #expect(restored.dungeonTracker.dungeon(0).baseBoxes[0].playerHas == .yes)
        #expect(restored.dungeonTracker.dungeon(0).playerHasTriforce == true)
        // Timeline (was previously lost on restore — the bug this fixes)
        #expect(restored.timeline.acquiredAt[.ladder] == 125)
        #expect(restored.timeline.acquiredAt[.triforce(1)] == 125)
        #expect(restored.timeline.acquiredLocation[.ladder] == "LEVEL-1 Box 1")
        #expect(restored.timeline.latestSeconds == 125)
    }

    @Test("a pre-timeline save (no timeline field) still decodes, with an empty timeline")
    func preTimelineSaveDecodes() throws {
        let snap = makeMutated().snapshot()
        var json = try JSONSerialization.jsonObject(with: JSONEncoder().encode(snap)) as! [String: Any]
        json.removeValue(forKey: "timeline")               // simulate an older save
        let data = try JSONSerialization.data(withJSONObject: json)
        let decoded = try JSONDecoder().decode(TrackerModel.State.self, from: data)  // must not throw
        #expect(decoded.timeline == nil)
        let restored = TrackerModel(quest: .first)
        restored.restore(decoded)                          // no crash; timeline stays empty
        #expect(restored.timeline.acquiredAt.isEmpty)
    }

    @Test("a corrupt (wrong-size) sub-array is ignored, not crashed on")
    func corruptGuard() {
        let m = TrackerModel(quest: .first)
        var bad = OverworldGrid.State(tiles: [.unmarked], extraData: [], takeAnySlotLinks: [], enemyPairs: [])
        m.overworldGrid.restore(bad)     // wrong sizes → no-op, no crash
        #expect(m.overworldGrid.mark(column: 0, row: 0) == .unmarked)
        bad.tiles = []
        m.overworldGrid.restore(bad)
        #expect(true)   // reached here without trapping
    }
}
