import SwiftUI
import Testing
import TrackerCore
@testable import ZTrackerMac

@Suite("Zones + Coords overlays")
struct ZonesAndCoordsTests {
    @Test("owMapZone is 8 rows × 16 cols with only the known zone letters")
    func zoneData() {
        #expect(OverworldZones.rows.count == 8)
        #expect(OverworldZones.rows.allSatisfy { $0.count == 16 })
        let letters = Set("MLRHCGDFSW")
        #expect(OverworldZones.rows.joined().allSatisfy { letters.contains($0) })
    }

    @Test("zone lookups match the reference grid at representative screens")
    func zoneLookups() {
        // Row 0 = "MMMMMMMMMMLHHHCC".
        #expect(OverworldZones.zone(column: 0, row: 0) == "M")
        #expect(OverworldZones.zone(column: 10, row: 0) == "L")
        #expect(OverworldZones.zone(column: 15, row: 0) == "C")
        // Bottom-left corner (row 7) = "WWWWWRSSSSSCCCCC".
        #expect(OverworldZones.zone(column: 0, row: 7) == "W")
        // Out of range → nil.
        #expect(OverworldZones.zone(column: 16, row: 0) == nil)
        #expect(OverworldZones.zone(column: 0, row: 8) == nil)
    }

    @Test("every zone letter maps to a non-clear color; unknown → clear")
    func zoneColors() {
        for ch in "MLRHCGDFSW" {
            #expect(OverworldZones.color(ch) != Color.clear)
        }
        #expect(OverworldZones.color("Z") == Color.clear)
    }

    @Test("coord format = row letter (A–H) + column number (1–16); coast = F16")
    @MainActor func coordFormat() {
        #expect(OverworldCoords.label(column: 0, row: 0) == "A1")
        #expect(OverworldCoords.label(column: 15, row: 7) == "H16")
        // The coast item screen (col 15, row 5) — the reference's "F16".
        #expect(OverworldCoords.label(column: 15, row: 5) == "F16")
        // The coast-picker trigger (T-205) is wired to exactly that screen.
        #expect(OverworldMapView.coastColumn == 15 && OverworldMapView.coastRow == 5)
        #expect(OverworldCoords.label(column: OverworldMapView.coastColumn,
                                      row: OverworldMapView.coastRow) == "F16")
    }
}
