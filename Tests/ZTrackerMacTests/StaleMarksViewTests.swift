import Testing
import TrackerCore
@testable import ZTrackerMac

/// T-252 — one rule for "found": a stranded dungeon mark doesn't light its numeral.
@Suite("Stale marks in the views (T-252)")
@MainActor
struct StaleMarksViewTests {
    @Test("a dungeon on a dead spot isn't located")
    func deadSpotDungeonNotLocated() {
        let grid = OverworldGrid()
        grid.setMark(.dungeon(2), column: 0, row: 0)
        grid.setMark(.dungeon(5), column: 1, row: 0)
        let located = DungeonTrackerView.locatedDungeonIndices(in: grid, isDeadSpot: { c, _ in c == 0 })
        #expect(located == [4])
    }

    @Test("the quest-switch summary names the first four marks")
    func summary() {
        let marks: [(column: Int, row: Int, mark: OverworldTileMark)] =
            (0..<6).map { (column: $0, row: 0, mark: .dungeon(1)) }
        let text = SettingsWindowView.staleSummary(marks)
        #expect(text.hasSuffix(", and 2 more"))
        #expect(text.components(separatedBy: ", ").count == 5)
        #expect(OverworldMapView.isStaleMark(.dungeon(1)))
        #expect(!OverworldMapView.isStaleMark(.dontCare))
        #expect(!OverworldMapView.isStaleMark(.unmarked))
    }
}
