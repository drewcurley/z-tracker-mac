import Testing
import TrackerCore
@testable import ZTrackerMac

@Suite("DungeonTrackerView.locatedDungeonIndices")
struct DungeonTrackerViewTests {
    @Test("an empty overworld locates no dungeons")
    func empty() {
        #expect(DungeonTrackerView.locatedDungeonIndices(in: OverworldGrid()).isEmpty)
    }

    @Test("dungeon marks map to their 0-based indices")
    func marks() {
        let grid = OverworldGrid()
        grid.setMark(.dungeon(1), column: 3, row: 2) // -> index 0
        grid.setMark(.dungeon(9), column: 10, row: 5) // -> index 8
        let located = DungeonTrackerView.locatedDungeonIndices(in: grid)
        #expect(located == [0, 8])
    }

    @Test("non-dungeon marks are ignored")
    func nonDungeon() {
        let grid = OverworldGrid()
        grid.setMark(.shop(.arrow), column: 1, row: 1)
        grid.setMark(.anyRoad(2), column: 2, row: 2)
        grid.setMark(.armos, column: 3, row: 3)
        #expect(DungeonTrackerView.locatedDungeonIndices(in: grid).isEmpty)
    }
}
