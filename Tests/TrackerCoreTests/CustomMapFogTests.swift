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

    @Test("a custom map counts every screen toward 'OW spots left'")
    func spotCountIncludesFormerDeadSpots() {
        let m = TrackerModel(quest: .first)
        m.selectQuest(.first)
        func spotsRemaining(customMap: Bool) -> Int {
            MapStateSummary.compute(
                grid: m.overworldGrid,
                instance: OverworldInstance(quest: .first),
                dungeonTracker: m.dungeonTracker,
                playerState: m.playerComputedStateSummary,
                progress: m.playerProgress,
                drawRoutes: false,
                routesCanScreenScroll: false,
                mirrorOverworld: false,
                customMapActive: customMap
            ).owSpotsRemain
        }
        // The vanilla count skips quest dead spots; a custom map has none, so its
        // remaining-count must be strictly larger on an otherwise-identical board.
        #expect(spotsRemaining(customMap: true) > spotsRemaining(customMap: false))
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
