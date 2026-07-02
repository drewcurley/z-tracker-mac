import Testing
@testable import TrackerCore

@Suite("OverworldGrid")
struct OverworldGridTests {
    @Test("is 16x8")
    func dimensions() {
        #expect(OverworldGrid.columnCount == 16)
        #expect(OverworldGrid.rowCount == 8)
    }

    @Test("every tile starts unmarked")
    func startsUnmarked() {
        let grid = OverworldGrid()
        for row in 0..<OverworldGrid.rowCount {
            for column in 0..<OverworldGrid.columnCount {
                #expect(grid.mark(column: column, row: row) == .unmarked)
            }
        }
    }

    @Test("setMark sets exactly the targeted tile")
    func setMarkIsScoped() {
        let grid = OverworldGrid()
        grid.setMark(.dungeon(1), column: 3, row: 2)
        #expect(grid.mark(column: 3, row: 2) == .dungeon(1))
        // neighbors unaffected
        #expect(grid.mark(column: 2, row: 2) == .unmarked)
        #expect(grid.mark(column: 4, row: 2) == .unmarked)
        #expect(grid.mark(column: 3, row: 1) == .unmarked)
        #expect(grid.mark(column: 3, row: 3) == .unmarked)
    }

    @Test("setMark overwrites a previous mark on the same tile")
    func setMarkOverwrites() {
        let grid = OverworldGrid()
        grid.setMark(.dontCare, column: 0, row: 0)
        grid.setMark(.shop(.key), column: 0, row: 0)
        #expect(grid.mark(column: 0, row: 0) == .shop(.key))
    }

    @Test("clearAll resets every tile to unmarked")
    func clearAll() {
        let grid = OverworldGrid()
        grid.setMark(.armos, column: 5, row: 5)
        grid.setMark(.hintShop, column: 10, row: 1)
        grid.clearAll()
        for row in 0..<OverworldGrid.rowCount {
            for column in 0..<OverworldGrid.columnCount {
                #expect(grid.mark(column: column, row: row) == .unmarked)
            }
        }
    }

    @Test("corner tiles are addressable")
    func cornerTilesAddressable() {
        let grid = OverworldGrid()
        let corners = [(0, 0), (15, 0), (0, 7), (15, 7)]
        for (column, row) in corners {
            grid.setMark(.dontCare, column: column, row: row)
            #expect(grid.mark(column: column, row: row) == .dontCare)
        }
    }
}
