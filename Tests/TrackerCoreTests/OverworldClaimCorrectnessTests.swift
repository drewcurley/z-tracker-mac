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
        // Sized secrets are capped at the quest totals (T-108): 1Q 3/7/4, 2Q 1/7/6.
        #expect(OverworldTileLimits.maxUses(.secret(.large), quest: .first) == 3)
        #expect(OverworldTileLimits.maxUses(.secret(.small), quest: .first) == 4)
        #expect(OverworldTileLimits.maxUses(.secret(.medium), quest: .first) == 7)
        #expect(OverworldTileLimits.maxUses(.secret(.large), quest: .second) == 1)
        #expect(OverworldTileLimits.maxUses(.secret(.small), quest: .second) == 6)
        // Unbounded: shops, unsized (unknown) secret.
        #expect(OverworldTileLimits.maxUses(.shop(.bomb), quest: .first) == OverworldTileLimits.unlimited)
        #expect(OverworldTileLimits.maxUses(.secret(.unknown), quest: .first) == OverworldTileLimits.unlimited)
    }

    @Test("unknown secret is never claimable (always unclaimed)")
    func unknownSecretUnclaimable() {
        #expect(!OverworldTileMark.secret(.unknown).isUsedToggleable)
        #expect(OverworldTileMark.secret(.large).isUsedToggleable)
        // Only the wood-sword cave (SWORD1) is a manual toggle; the White-Sword-Item
        // and Magical-Sword caves derive their dim from model state (T-110), as does
        // the armos item — so they're not manually toggleable.
        #expect(OverworldTileMark.swordCave(1).isUsedToggleable)
        #expect(!OverworldTileMark.swordCave(2).isUsedToggleable)
        #expect(!OverworldTileMark.swordCave(3).isUsedToggleable)
        #expect(!OverworldTileMark.armos.isUsedToggleable)
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
        model.overworldGrid.setMark(.secret(.large), column: 3, row: 3)
        model.overworldGrid.setUsed(true, column: 3, row: 3)
        #expect(model.overworldGrid.isUsed(column: 3, row: 3))

        model.resetForGroundhogOrRouters()
        #expect(!model.overworldGrid.isUsed(column: 3, row: 3))
        #expect(model.overworldGrid.mark(column: 3, row: 3) == .secret(.large)) // mark kept
    }
}

@Suite("Letter + wood-sword-cave semantics (T-118)")
struct LetterAndWoodSwordCaveTests {
    @Test("the letter is not force-used on placement (you hold the potion letter)")
    func letterPlacesUnused() {
        #expect(!OverworldTileMark.theLetter.placesUsedWhenMarked)
        // Secrets/hint shop still place used (dark).
        #expect(OverworldTileMark.secret(.large).placesUsedWhenMarked)
        #expect(OverworldTileMark.hintShop.placesUsedWhenMarked)

        // Placing the letter leaves it un-used → havePotionLetter true in map state.
        let model = TrackerModel(quest: .first)
        model.selectQuest(.first)
        model.overworldGrid.setMark(.theLetter, column: 4, row: 4)
        #expect(!model.overworldGrid.isUsed(column: 4, row: 4))
        // Toggling marks it delivered/used.
        model.overworldGrid.toggleUsed(column: 4, row: 4)
        #expect(model.overworldGrid.isUsed(column: 4, row: 4))
    }

    @Test("taking the magical sword drives swordLevel (dims the magical-sword cave)")
    func magicalSwordCaveGrant() {
        let model = TrackerModel(quest: .first)
        model.selectQuest(.first)
        #expect(model.playerComputedStateSummary.swordLevel < 3)   // cave bright
        // Clicking the magical-sword cave grants the sword (view wires this).
        model.playerProgress.hasMagicalSword = true
        #expect(model.playerComputedStateSummary.swordLevel == 3)  // cave now dims
        model.playerProgress.hasMagicalSword = false
        #expect(model.playerComputedStateSummary.swordLevel < 3)
    }

    @Test("wood-sword cave used state round-trips through the grid toggle")
    func woodSwordCaveToggles() {
        let g = OverworldGrid()
        g.setMark(.swordCave(1), column: 0, row: 0)
        #expect(!g.isUsed(column: 0, row: 0))       // places bright (not collected)
        g.toggleUsed(column: 0, row: 0)
        #expect(g.isUsed(column: 0, row: 0))        // collected → grants wood sword (view wires this)
    }
}
