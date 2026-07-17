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

    @Test("non-unique location totals per quest, remaining = total − marked (T-076)")
    func nonUniqueCounts() {
        // Empty 1Q: reference maxUses (door 9, MMG 5, hint 4, take-any 4, potion 7).
        let s1 = SpotSummary.compute(grid: OverworldGrid(), quest: .first)
        func total(_ m: OverworldTileMark) -> Int { s1.nonUniques.first { $0.mark == m }!.total }
        #expect(total(.doorRepair) == 9)
        #expect(total(.moneyMakingGame) == 5)
        #expect(total(.hintShop) == 4)
        #expect(total(.takeAny) == 4)
        #expect(total(.potionShop) == 7)
        #expect(s1.nonUniques.allSatisfy { $0.marked == 0 && $0.remaining == $0.total })

        // 2Q totals differ (door 10, MMG 6, potion 9).
        let s2 = SpotSummary.compute(grid: OverworldGrid(), quest: .second)
        func total2(_ m: OverworldTileMark) -> Int { s2.nonUniques.first { $0.mark == m }!.total }
        #expect(total2(.doorRepair) == 10)
        #expect(total2(.moneyMakingGame) == 6)
        #expect(total2(.potionShop) == 9)

        // Marking some reduces remaining.
        let grid = OverworldGrid()
        grid.setMark(.doorRepair, column: 0, row: 0)
        grid.setMark(.doorRepair, column: 1, row: 0)
        grid.setMark(.takeAny, column: 2, row: 0)
        let s = SpotSummary.compute(grid: grid, quest: .first)
        let door = s.nonUniques.first { $0.mark == .doorRepair }!
        #expect(door.marked == 2 && door.remaining == 7)
        let takeAny = s.nonUniques.first { $0.mark == .takeAny }!
        #expect(takeAny.marked == 1 && takeAny.remaining == 3)
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

        // Collect the large secret (map toggle). The armos derives its collected
        // state from the model (armosBox.isDone), passed to `compute` (T-110).
        grid.toggleUsed(column: 1, row: 1)
        #expect(grid.isUsed(column: 1, row: 1))

        let s = SpotSummary.compute(grid: grid, quest: .first, armosDone: true)
        // One large collected → 2 large remaining; medium untouched.
        #expect(s.secretsUsed == .init(large: 1, medium: 0, small: 0))
        #expect(s.secretsRemaining == .init(large: 2, medium: 7, small: 4))
        // Armos collected (used, from the model); the letter placed but not collected.
        #expect(s.uniques.first { $0.mark == .armos }?.used == true)
        #expect(s.uniques.first { $0.mark == .theLetter }?.used == false)
        #expect(s.uniques.first { $0.mark == .theLetter }?.placed == true)

        // Toggling used off restores it.
        grid.toggleUsed(column: 1, row: 1)
        #expect(!grid.isUsed(column: 1, row: 1))
        #expect(SpotSummary.compute(grid: grid, quest: .first).secretsRemaining
                == .init(large: 3, medium: 7, small: 4))
    }

    @Test("sword caves are claimable: placed→found, used→collected/done (T-065)")
    func swordCaveClaimed() {
        let grid = OverworldGrid()
        grid.setMark(.swordCave(1), column: 0, row: 0)
        grid.setMark(.swordCave(2), column: 1, row: 0)

        // Placed but not collected.
        let placed = SpotSummary.compute(grid: grid, quest: .first)
        #expect(placed.uniques.first { $0.mark == .swordCave(1) }?.placed == true)
        #expect(placed.uniques.first { $0.mark == .swordCave(1) }?.used == false)
        // A claimable spot is "done" only once used, not merely placed.
        #expect(placed.uniques.first { $0.mark == .swordCave(1) }?.done == false)

        // Collect the wood-sword cave.
        grid.setUsed(true, column: 0, row: 0)
        let done = SpotSummary.compute(grid: grid, quest: .first)
        #expect(done.uniques.first { $0.mark == .swordCave(1) }?.used == true)
        #expect(done.uniques.first { $0.mark == .swordCave(1) }?.done == true)
        // The other sword cave stays found-not-collected.
        #expect(done.uniques.first { $0.mark == .swordCave(2) }?.done == false)
    }

    @Test("sword2/sword3/armos derive done from model state, not a map toggle (T-110)")
    func derivedCavesDone() {
        let grid = OverworldGrid()
        grid.setMark(.swordCave(2), column: 1, row: 0)
        grid.setMark(.swordCave(3), column: 2, row: 0)
        grid.setMark(.armos, column: 3, row: 0)

        // Placed on the map but nothing collected → all bright (not done).
        let none = SpotSummary.compute(grid: grid, quest: .first)
        #expect(none.uniques.first { $0.mark == .swordCave(2) }?.done == false)
        #expect(none.uniques.first { $0.mark == .swordCave(3) }?.done == false)
        #expect(none.uniques.first { $0.mark == .armos }?.done == false)

        // Model state drives collected/done, independent of any map `used` flag.
        let got = SpotSummary.compute(grid: grid, quest: .first,
                                      armosDone: true, whiteSwordItemDone: true, hasMagicalSword: true)
        #expect(got.uniques.first { $0.mark == .swordCave(2) }?.done == true)
        #expect(got.uniques.first { $0.mark == .swordCave(3) }?.done == true)
        #expect(got.uniques.first { $0.mark == .armos }?.done == true)
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
        // Armos is no longer a manual toggle — its dim derives from the model (T-110).
        #expect(!OverworldTileMark.armos.isUsedToggleable)
    }
}
