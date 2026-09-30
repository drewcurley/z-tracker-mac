import Testing
import Foundation
@testable import TrackerCore

/// T-167 — custom-map fog-of-war: reveal-on-mark, persistence, and (critically)
/// that saves written before the feature still decode (the new fields default).
@Suite("Custom-map fog (T-167)")
@MainActor
struct CustomMapFogTests {

    @Test("marking a screen reveals it; clearing doesn't re-hide; manual re-hide works")
    func revealOnMark() {
        let g = OverworldGrid()
        #expect(g.isCustomMapRevealed(column: 3, row: 2) == false)
        g.setMark(.shop(.bomb), column: 3, row: 2)
        #expect(g.isCustomMapRevealed(column: 3, row: 2) == true)
        g.setMark(.unmarked, column: 3, row: 2)                 // clearing keeps it revealed
        #expect(g.isCustomMapRevealed(column: 3, row: 2) == true)
        g.setCustomMapRevealed(false, column: 3, row: 2)        // manual re-hide
        #expect(g.isCustomMapRevealed(column: 3, row: 2) == false)
    }

    @Test("map path + reveal state survive a save round-trip")
    func persists() throws {
        let m = TrackerModel(quest: .first)
        m.customMapImagePath = "/tmp/infinite-hyrule.png"
        m.overworldGrid.setMark(.armos, column: 5, row: 5)      // reveals (5,5)
        let data = try JSONEncoder().encode(m.snapshot())
        let decoded = try JSONDecoder().decode(TrackerModel.State.self, from: data)
        let r = TrackerModel(quest: .first)
        r.restore(decoded)
        #expect(r.customMapImagePath == "/tmp/infinite-hyrule.png")
        #expect(r.overworldGrid.isCustomMapRevealed(column: 5, row: 5) == true)
        #expect(r.overworldGrid.isCustomMapRevealed(column: 0, row: 0) == false)
    }

    @Test("a custom map has no dead spots — every screen stays markable")
    func customMapHasNoDeadSpots() throws {
        let m = TrackerModel(quest: .first)
        m.selectQuest(.first)
        // Find a screen the vanilla first quest treats as a dead spot (don't hardcode
        // coordinates — ask the model).
        var found: (x: Int, y: Int)?
        outer: for y in 0..<OverworldGrid.rowCount {
            for x in 0..<OverworldGrid.columnCount where m.isDeadSpot(x: x, y: y) {
                found = (x, y); break outer
            }
        }
        let spot = try #require(found, "the vanilla map should have at least one dead spot")
        #expect(m.isDeadSpot(x: spot.x, y: spot.y) == true)

        // With a custom map, nothing is a dead spot — every screen is markable.
        m.customMapImagePath = "/tmp/map.png"
        for y in 0..<OverworldGrid.rowCount {
            for x in 0..<OverworldGrid.columnCount {
                #expect(m.isDeadSpot(x: x, y: y) == false)
            }
        }
    }

    /// Compute a summary for a bare grid (default first-quest custom map, no dungeon/player state).
    private func summary(_ grid: OverworldGrid, quest: OverworldQuest = .first,
                         customMap: Bool = true) -> MapStateSummary {
        MapStateSummary.compute(
            grid: grid, instance: OverworldInstance(quest: quest),
            dungeonTracker: DungeonTrackerInstance(),
            playerState: PlayerComputedStateSummary(),
            progress: PlayerProgressAndTakeAnyHearts(),
            drawRoutes: false, routesCanScreenScroll: false, mirrorOverworld: false,
            customMapActive: customMap)
    }

    @Test("custom-map spots-left = quest total − real marks; undiscovered = fogged screens (T-235)")
    func customMapSpotAccounting() {
        let g = OverworldGrid()
        // Empty first-quest custom board: 73 spots to find, all 128 screens still fogged.
        var s = summary(g)
        #expect(s.owSpotsRemain == 73)
        #expect(s.owUndiscovered == 128)

        // Marking 5 real spots (dungeons) finds 5 and reveals their screens.
        for n in 1...5 { g.setMark(.dungeon(n), column: n, row: 0) }
        s = summary(g)
        #expect(s.owSpotsRemain == 68)      // 73 − 5 found
        #expect(s.owUndiscovered == 123)    // 128 − 5 revealed

        // A "confirmed-empty" DarkX (dontCare) mark reveals its screen but is NOT a found spot.
        g.setMark(.dontCare, column: 10, row: 0)
        s = summary(g)
        #expect(s.owSpotsRemain == 68)      // unchanged — dontCare isn't a spot
        #expect(s.owUndiscovered == 122)    // but one more screen is revealed
    }

    @Test("custom-map spots-left is clamped to never exceed undiscovered (T-235)")
    func customMapClampInvariant() {
        let g = OverworldGrid()
        // Reveal 70 screens without marking any spot → only 58 remain fogged, fewer than the 73
        // quest total, so spots-left must clamp down to the undiscovered count.
        var revealed = 0
        outer: for x in 0..<OverworldGrid.columnCount {
            for y in 0..<OverworldGrid.rowCount {
                g.setCustomMapRevealed(true, column: x, row: y)
                revealed += 1
                if revealed == 70 { break outer }
            }
        }
        let s = summary(g)
        #expect(s.owUndiscovered == 58)               // 128 − 70
        #expect(s.owSpotsRemain == 58)                // clamped from 73 down to 58
        #expect(s.owSpotsRemain <= s.owUndiscovered)  // the invariant the user asked for
    }

    @Test("second-quest custom map uses an 80-spot total; vanilla reports 0 undiscovered (T-235)")
    func customMapQuestTotalsAndVanilla() {
        #expect(summary(OverworldGrid(), quest: .second).owSpotsRemain == 80)
        #expect(summary(OverworldGrid(), quest: .mixedSecond).owSpotsRemain == 80)
        #expect(summary(OverworldGrid(), quest: .mixedFirst).owSpotsRemain == 73)
        // A vanilla (non-custom) map has no fog concept — undiscovered is always 0.
        #expect(summary(OverworldGrid(), customMap: false).owUndiscovered == 0)
    }

    @Test("manual fairy fountains toggle and persist")
    func manualFairies() throws {
        let m = TrackerModel(quest: .first)
        m.customMapImagePath = "/tmp/map.png"
        #expect(m.overworldGrid.isCustomFairy(column: 9, row: 3) == false)
        m.overworldGrid.toggleCustomFairy(column: 9, row: 3)
        #expect(m.overworldGrid.isCustomFairy(column: 9, row: 3) == true)

        let data = try JSONEncoder().encode(m.snapshot())
        let r = TrackerModel(quest: .first)
        r.restore(try JSONDecoder().decode(TrackerModel.State.self, from: data))
        #expect(r.overworldGrid.isCustomFairy(column: 9, row: 3) == true)
        #expect(r.overworldGrid.isCustomFairy(column: 0, row: 0) == false)

        r.overworldGrid.toggleCustomFairy(column: 9, row: 3)     // toggles back off
        #expect(r.overworldGrid.isCustomFairy(column: 9, row: 3) == false)
    }

    @Test("placing a fairy reveals its screen; removing it doesn't re-hide")
    func placingAFairyReveals() {
        let g = OverworldGrid()
        #expect(g.isCustomMapRevealed(column: 2, row: 6) == false)
        g.toggleCustomFairy(column: 2, row: 6)
        #expect(g.isCustomMapRevealed(column: 2, row: 6) == true)
        g.toggleCustomFairy(column: 2, row: 6)                   // removed
        #expect(g.isCustomFairy(column: 2, row: 6) == false)
        #expect(g.isCustomMapRevealed(column: 2, row: 6) == true) // stays revealed, like clearing a mark
    }

    @Test("a pre-T-167 save (no custom-map fields) still decodes, all hidden")
    func backwardCompatible() throws {
        // Encode a grid state, strip the new key, and confirm it still decodes.
        let g = OverworldGrid()
        var dict = try #require(
            try JSONSerialization.jsonObject(with: JSONEncoder().encode(g.state)) as? [String: Any])
        dict.removeValue(forKey: "customMapRevealed")
        let stripped = try JSONSerialization.data(withJSONObject: dict)
        let decoded = try JSONDecoder().decode(OverworldGrid.State.self, from: stripped)
        let g2 = OverworldGrid()
        g2.restore(decoded)                                     // must not throw / crash
        #expect(g2.isCustomMapRevealed(column: 0, row: 0) == false)
    }
}
