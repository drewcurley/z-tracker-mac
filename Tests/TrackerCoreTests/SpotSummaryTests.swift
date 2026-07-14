import Testing
@testable import TrackerCore

@Suite("Spot Summary (T-053 / T-054)")
struct SpotSummaryTests {
    @Test("empty grid: 18 uniques unplaced; per-quest secret totals")
    func emptyGrid() {
        let s1 = SpotSummary.compute(grid: OverworldGrid(), quest: .first)
        #expect(s1.uniques.count == 18)
        #expect(s1.uniques.allSatisfy { !$0.placed && !$0.used })
        #expect(s1.secretsTotal == .init(large: 3, medium: 7, small: 4))
        #expect(s1.secretsRemaining == .init(large: 3, medium: 7, small: 4))

        // 2Q overworld totals (also for mixed-second).
        #expect(SpotSummary.compute(grid: OverworldGrid(), quest: .second).secretsTotal
                == .init(large: 1, medium: 7, small: 6))
        #expect(SpotSummary.compute(grid: OverworldGrid(), quest: .mixedSecond).secretsTotal
                == .init(large: 1, medium: 7, small: 6))
        #expect(SpotSummary.compute(grid: OverworldGrid(), quest: .mixedFirst).secretsTotal
                == .init(large: 3, medium: 7, small: 4))
    }

    @Test("placing a unique flags it placed; placing a secret alone doesn't reduce remaining")
    func placement() {
        let grid = OverworldGrid()
        grid.setMark(.dungeon(3), column: 2, row: 2)
        grid.setMark(.armos, column: 5, row: 5)
        grid.setMark(.secret(.large), column: 1, row: 1)
        grid.setMark(.secret(.small), column: 6, row: 1)
        grid.setMark(.secret(.unknown), column: 8, row: 1)

        let s = SpotSummary.compute(grid: grid, quest: .first)
        #expect(s.uniques.first { $0.mark == .dungeon(3) }?.placed == true)
        #expect(s.uniques.first { $0.mark == .armos }?.placed == true)
        #expect(s.uniques.first { $0.mark == .armos }?.used == false)
        #expect(s.uniques.first { $0.mark == .dungeon(1) }?.placed == false)

        #expect(s.secretsPlaced == .init(large: 1, medium: 0, small: 1, unknown: 1))
        // Nothing collected yet → still all remaining.
        #expect(s.secretsRemaining == .init(large: 3, medium: 7, small: 4))
    }

    @Test("marking a claimable tile used reduces remaining / flags the unique collected")
    func usedTracked() {
        let grid = OverworldGrid()
        grid.setMark(.secret(.large), column: 1, row: 1)
        grid.setMark(.secret(.medium), column: 2, row: 1)
        grid.setMark(.armos, column: 5, row: 5)
        grid.setMark(.theLetter, column: 6, row: 5)

        // Collect the large secret and the armos.
        grid.toggleUsed(column: 1, row: 1)
        grid.toggleUsed(column: 5, row: 5)
        #expect(grid.isUsed(column: 1, row: 1))
        #expect(grid.isUsed(column: 5, row: 5))

        let s = SpotSummary.compute(grid: grid, quest: .first)
        // One large collected → 2 large remaining; medium untouched.
        #expect(s.secretsUsed == .init(large: 1, medium: 0, small: 0))
        #expect(s.secretsRemaining == .init(large: 2, medium: 7, small: 4))
        // Armos collected (used); the letter placed but not collected.
        #expect(s.uniques.first { $0.mark == .armos }?.used == true)
        #expect(s.uniques.first { $0.mark == .theLetter }?.used == false)
        #expect(s.uniques.first { $0.mark == .theLetter }?.placed == true)

        // Toggling used off restores it.
        grid.toggleUsed(column: 1, row: 1)
        #expect(!grid.isUsed(column: 1, row: 1))
        #expect(SpotSummary.compute(grid: grid, quest: .first).secretsRemaining
                == .init(large: 3, medium: 7, small: 4))
    }

    @Test("setUsed sets/clears used on a claimable mark; no-op otherwise (T-056)")
    func setUsed() {
        let grid = OverworldGrid()
        grid.setMark(.secret(.medium), column: 3, row: 3)
        grid.setUsed(true, column: 3, row: 3)
        #expect(grid.isUsed(column: 3, row: 3))
        grid.setUsed(false, column: 3, row: 3)
        #expect(!grid.isUsed(column: 3, row: 3))
        // Non-toggleable → no-op.
        grid.setMark(.shop(.bomb), column: 4, row: 4)
        grid.setUsed(true, column: 4, row: 4)
        #expect(!grid.isUsed(column: 4, row: 4))
    }

    @Test("a non-toggleable mark can't be used")
    func nonToggleable() {
        let grid = OverworldGrid()
        grid.setMark(.dungeon(1), column: 0, row: 0)
        grid.toggleUsed(column: 0, row: 0) // no-op
        #expect(!grid.isUsed(column: 0, row: 0))
        #expect(!OverworldTileMark.dungeon(1).isUsedToggleable)
        #expect(OverworldTileMark.secret(.large).isUsedToggleable)
        #expect(OverworldTileMark.armos.isUsedToggleable)
    }
}
