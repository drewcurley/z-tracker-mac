import Testing
@testable import TrackerCore

@Suite("Groundhog / routers reset (remove inventory, preserve maps)")
struct GroundhogResetTests {
    /// Builds a model with a mix of run progress + map knowledge set.
    private func loadedModel() -> TrackerModel {
        let model = TrackerModel(quest: .first)
        model.selectQuest(.first)
        // Map knowledge: overworld marks + a dungeon-box item identity.
        model.overworldGrid.setMark(.dungeon(3), column: 5, row: 2)
        model.overworldGrid.setMark(.shop(.arrow), column: 0, row: 7)
        let box = model.dungeonTracker.dungeon(0).boxes[1]
        box.set(cellCurrent: ITEMS.ladder, playerHas: .yes)
        let skipped = model.dungeonTracker.dungeon(1).boxes[0]
        skipped.setPlayerHas(.skipped)
        // Run progress: triforce, a progress item, a taken take-any heart.
        model.dungeonTracker.dungeon(0).toggleTriforce()
        model.playerProgress.hasWoodSword = true
        model.playerProgress.takeAnyHearts[0] = .takenHeart
        // Starting item (seed config — should persist).
        model.startingItemsAndExtras.hasRaft = true
        return model
    }

    @Test("reset clears inventory: triforce, box possession, progress, take-any")
    func clearsInventory() {
        let model = loadedModel()
        model.resetForGroundhogOrRouters()

        #expect(!model.dungeonTracker.dungeon(0).playerHasTriforce)
        // The box's possession is reset to NO...
        #expect(model.dungeonTracker.dungeon(0).boxes[1].playerHas == .no)
        // ...progress + take-any cleared.
        #expect(!model.playerProgress.hasWoodSword)
        #expect(model.playerProgress.takeAnyHearts[0] == .untaken)
        // Derived state reflects an empty inventory.
        #expect(model.playerComputedStateSummary.swordLevel == 0)
        #expect(!model.playerComputedStateSummary.haveLadder)
    }

    @Test("reset preserves knowledge: marks, box item identities, skipped, starting items")
    func preservesKnowledge() {
        let model = loadedModel()
        model.resetForGroundhogOrRouters()

        // Overworld marks stay (you keep knowing where things are).
        #expect(model.overworldGrid.mark(column: 5, row: 2) == .dungeon(3))
        #expect(model.overworldGrid.mark(column: 0, row: 7) == .shop(.arrow))
        // The box keeps its item *identity* (the ladder is still known to be
        // here) — only possession was reset.
        #expect(model.dungeonTracker.dungeon(0).boxes[1].cellCurrent == ITEMS.ladder)
        // SKIPPED boxes stay skipped (not red-ified).
        #expect(model.dungeonTracker.dungeon(1).boxes[0].playerHas == .skipped)
        // The seed's starting items persist (same seed on replay).
        #expect(model.startingItemsAndExtras.hasRaft)
    }

    @Test("reset is idempotent on a fresh model")
    func idempotentOnFresh() {
        let model = TrackerModel(quest: .first)
        model.selectQuest(.first)
        model.resetForGroundhogOrRouters()
        #expect(!model.dungeonTracker.dungeon(0).playerHasTriforce)
        #expect(model.playerComputedStateSummary.swordLevel == 0)
    }
}
