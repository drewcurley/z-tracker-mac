import Testing
@testable import TrackerCore

@Suite("Spot Summary (T-053)")
struct SpotSummaryTests {
    @Test("empty grid: 18 uniques all unfound; per-quest secret totals")
    func emptyGrid() {
        let s1 = SpotSummary.compute(grid: OverworldGrid(), quest: .first)
        #expect(s1.uniques.count == 18)
        #expect(s1.uniques.allSatisfy { !$0.found })
        // 1Q overworld totals.
        #expect(s1.secretsTotal == .init(large: 3, medium: 7, small: 4))
        #expect(s1.secretsRemaining == .init(large: 3, medium: 7, small: 4))

        // 2Q overworld totals (also for mixed-second).
        let s2 = SpotSummary.compute(grid: OverworldGrid(), quest: .second)
        #expect(s2.secretsTotal == .init(large: 1, medium: 7, small: 6))
        #expect(SpotSummary.compute(grid: OverworldGrid(), quest: .mixedSecond).secretsTotal
                == .init(large: 1, medium: 7, small: 6))
        #expect(SpotSummary.compute(grid: OverworldGrid(), quest: .mixedFirst).secretsTotal
                == .init(large: 3, medium: 7, small: 4))
    }

    @Test("marking a unique flags it found; marking secrets reduces remaining")
    func marksTracked() {
        let grid = OverworldGrid()
        grid.setMark(.dungeon(3), column: 2, row: 2)
        grid.setMark(.armos, column: 5, row: 5)
        grid.setMark(.secret(.large), column: 1, row: 1)
        grid.setMark(.secret(.small), column: 6, row: 1)
        grid.setMark(.secret(.small), column: 7, row: 1)
        grid.setMark(.secret(.unknown), column: 8, row: 1)

        let s = SpotSummary.compute(grid: grid, quest: .first)
        // Dungeon 3 and armos found; dungeon 1 and the letter not.
        #expect(s.uniques.first { $0.mark == .dungeon(3) }?.found == true)
        #expect(s.uniques.first { $0.mark == .armos }?.found == true)
        #expect(s.uniques.first { $0.mark == .dungeon(1) }?.found == false)
        #expect(s.uniques.first { $0.mark == .theLetter }?.found == false)

        // Secrets: 1 large + 2 small placed (+1 unknown-size).
        #expect(s.secretsPlaced == .init(large: 1, medium: 0, small: 2, unknown: 1))
        // Remaining vs the 1Q totals (3/7/4): 2 large, 7 medium, 2 small.
        #expect(s.secretsRemaining == .init(large: 2, medium: 7, small: 2))
    }
}
