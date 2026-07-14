import Testing
@testable import TrackerCore

@Suite("Overworld claiming correctness (T-058)")
struct OverworldClaimCorrectnessTests {
    @Test("per-type max uses match the reference choice domain")
    func maxUses() {
        // Uniques: 1 each.
        #expect(OverworldTileLimits.maxUses(.dungeon(1), quest: .first) == 1)
        #expect(OverworldTileLimits.maxUses(.anyRoad(3), quest: .first) == 1)
        #expect(OverworldTileLimits.maxUses(.swordCave(2), quest: .first) == 1)
        #expect(OverworldTileLimits.maxUses(.theLetter, quest: .first) == 1)
        #expect(OverworldTileLimits.maxUses(.armos, quest: .first) == 1)
        // Take-any / hint shop: 4.
        #expect(OverworldTileLimits.maxUses(.takeAny, quest: .first) == 4)
        #expect(OverworldTileLimits.maxUses(.hintShop, quest: .second) == 4)
        // Quest-dependent.
        #expect(OverworldTileLimits.maxUses(.potionShop, quest: .first) == 7)
        #expect(OverworldTileLimits.maxUses(.potionShop, quest: .second) == 9)
        #expect(OverworldTileLimits.maxUses(.moneyMakingGame, quest: .first) == 5)
        #expect(OverworldTileLimits.maxUses(.doorRepair, quest: .second) == 10)
        // Unbounded.
        #expect(OverworldTileLimits.maxUses(.shop(.bomb), quest: .first) == OverworldTileLimits.unlimited)
        #expect(OverworldTileLimits.maxUses(.secret(.large), quest: .first) == OverworldTileLimits.unlimited)
    }

    @Test("unknown secret is never claimable (always unclaimed)")
    func unknownSecretUnclaimable() {
        #expect(!OverworldTileMark.secret(.unknown).isUsedToggleable)
        #expect(OverworldTileMark.secret(.large).isUsedToggleable)
        // Setting used on an unknown secret is a no-op.
        let grid = OverworldGrid()
        grid.setMark(.secret(.unknown), column: 0, row: 0)
        grid.setUsed(true, column: 0, row: 0)
        grid.toggleUsed(column: 0, row: 0)
        #expect(!grid.isUsed(column: 0, row: 0))
    }

    @Test("clearAllUsed resets claimed state but keeps marks")
    func clearAllUsed() {
        let grid = OverworldGrid()
        grid.setMark(.takeAny, column: 1, row: 1)
        grid.setUsed(true, column: 1, row: 1)
        grid.setMark(.secret(.large), column: 2, row: 2)
        grid.setUsed(true, column: 2, row: 2)
        #expect(grid.isUsed(column: 1, row: 1) && grid.isUsed(column: 2, row: 2))

        grid.clearAllUsed()
        #expect(!grid.isUsed(column: 1, row: 1) && !grid.isUsed(column: 2, row: 2))
        // Marks are kept.
        #expect(grid.mark(column: 1, row: 1) == .takeAny)
        #expect(grid.mark(column: 2, row: 2) == .secret(.large))
    }

    @Test("shop second item: set/clear + ordered display (T-060)")
    func shopTwoItems() {
        let grid = OverworldGrid()
        grid.setMark(.shop(.book), column: 0, row: 0) // book = index 2
        #expect(grid.shopSecondItem(column: 0, row: 0) == nil)
        #expect(grid.shopItems(column: 0, row: 0) == [.book])

        // Add arrow (index 0) as the second item; display is dropdown order.
        grid.setShopSecondItem(.arrow, column: 0, row: 0)
        #expect(grid.shopSecondItem(column: 0, row: 0) == .arrow)
        #expect(grid.shopItems(column: 0, row: 0) == [.arrow, .book]) // arrow < book

        // The encoding is the reference toItem format (arrow → 1).
        #expect(grid.extraData(column: 0, row: 0, key: OverworldTileMark.shopExtraDataKey) == 1)

        // Clearing removes the second item.
        grid.setShopSecondItem(nil, column: 0, row: 0)
        #expect(grid.shopItems(column: 0, row: 0) == [.book])

        // A non-shop tile has no shop items.
        grid.setMark(.armos, column: 1, row: 1)
        #expect(grid.shopItems(column: 1, row: 1).isEmpty)
    }

    @Test("groundhog reset clears the overworld claimed state")
    func groundhogClearsUsed() {
        let model = TrackerModel(quest: .first)
        model.selectQuest(.first)
        model.overworldGrid.setMark(.armos, column: 3, row: 3)
        model.overworldGrid.setUsed(true, column: 3, row: 3)
        #expect(model.overworldGrid.isUsed(column: 3, row: 3))

        model.resetForGroundhogOrRouters()
        #expect(!model.overworldGrid.isUsed(column: 3, row: 3))
        #expect(model.overworldGrid.mark(column: 3, row: 3) == .armos) // mark kept
    }
}
