import Testing
@testable import TrackerCore

@Suite("TrackerModel")
struct TrackerModelTests {
    @Test("starts with no quest selected")
    func startsWithNoQuest() {
        let model = TrackerModel()
        #expect(model.quest == nil)
    }

    @Test("selectQuest sets the quest", arguments: OverworldQuest.allCases)
    func selectQuestSetsQuest(quest: OverworldQuest) {
        let model = TrackerModel()
        model.selectQuest(quest)
        #expect(model.quest == quest)
    }

    @Test("selectQuest overwrites a previous selection")
    func selectQuestOverwrites() {
        let model = TrackerModel(quest: .first)
        model.selectQuest(.mixedSecond)
        #expect(model.quest == .mixedSecond)
    }

    @Test("heartShuffle and hideDungeonNumbers default to off")
    func togglesDefaultOff() {
        let model = TrackerModel()
        #expect(model.heartShuffle == false)
        #expect(model.hideDungeonNumbers == false)
    }

    @Test("mirrorOverworld defaults off and is settable (T-047)")
    func mirrorOverworldFlag() {
        let model = TrackerModel()
        #expect(model.mirrorOverworld == false)
        model.mirrorOverworld = true
        #expect(model.mirrorOverworld == true)
        // Init override also works.
        #expect(TrackerModel(mirrorOverworld: true).mirrorOverworld == true)
    }

    @Test("heartShuffle and hideDungeonNumbers can be set independently")
    func togglesAreIndependent() {
        let model = TrackerModel()
        model.heartShuffle = true
        #expect(model.heartShuffle == true)
        #expect(model.hideDungeonNumbers == false)
        model.hideDungeonNumbers = true
        #expect(model.heartShuffle == true)
        #expect(model.hideDungeonNumbers == true)
    }

    @Test("initializer accepts explicit toggle values")
    func initializerAcceptsToggles() {
        let model = TrackerModel(quest: .second, heartShuffle: true, hideDungeonNumbers: true)
        #expect(model.quest == .second)
        #expect(model.heartShuffle == true)
        #expect(model.hideDungeonNumbers == true)
    }

    @Test("owns a fresh, fully-unmarked overworldGrid by default")
    func ownsFreshOverworldGrid() {
        let model = TrackerModel()
        #expect(model.overworldGrid.mark(column: 0, row: 0) == .unmarked)
    }

    @Test("mutating overworldGrid through the model is visible on the same instance")
    func overworldGridMutationVisible() {
        let model = TrackerModel()
        model.overworldGrid.setMark(.dungeon(4), column: 7, row: 3)
        #expect(model.overworldGrid.mark(column: 7, row: 3) == .dungeon(4))
    }
}

@Suite("Overworld take-any ⇄ Items-group heart-slot sync (T-066)")
struct TakeAnySyncTests {
    /// Re-marking the SAME take-any tile a different way updates its own slot,
    /// never a second slot (the reported bug).
    @Test("re-marking a take-any tile reuses its slot, doesn't fill a second")
    func reMarkReusesSlot() {
        let m = TrackerModel()
        m.setOverworldTakeAny(.takenHeart, column: 2, row: 2)
        #expect(m.playerProgress.takeAnyHearts == [.takenHeart, .untaken, .untaken, .untaken])
        #expect(m.overworldGrid.takeAnySlot(column: 2, row: 2) == 0)

        // Change the same tile to a potion → same slot 0 becomes potion.
        m.setOverworldTakeAny(.takenPotion, column: 2, row: 2)
        #expect(m.playerProgress.takeAnyHearts == [.takenPotion, .untaken, .untaken, .untaken])
        #expect(m.overworldGrid.takeAnySlot(column: 2, row: 2) == 0)
    }

    /// Changing a take-any tile to another mark frees its Items-group slot back
    /// to an empty heart (the reported bug's second half).
    @Test("changing a take-any tile away frees its slot")
    func changingAwayFreesSlot() {
        let m = TrackerModel()
        m.setOverworldTakeAny(.takenHeart, column: 1, row: 1)
        #expect(m.playerProgress.takeAnyHearts[0] == .takenHeart)

        // The view calls releaseOverworldTakeAny before re-marking the tile.
        m.releaseOverworldTakeAny(column: 1, row: 1)
        m.overworldGrid.setMark(.armos, column: 1, row: 1)
        #expect(m.playerProgress.takeAnyHearts.allSatisfy { $0 == .untaken })
        #expect(m.overworldGrid.takeAnySlot(column: 1, row: 1) == nil)
    }

    /// Marking a take-any as `.untaken` frees its slot; two tiles keep distinct
    /// slots and one changing doesn't disturb the other.
    @Test("distinct tiles own distinct slots; untaken frees just its own")
    func distinctSlots() {
        let m = TrackerModel()
        m.setOverworldTakeAny(.takenHeart, column: 0, row: 0)   // slot 0
        m.setOverworldTakeAny(.takenPotion, column: 5, row: 5)  // slot 1
        #expect(m.overworldGrid.takeAnySlot(column: 0, row: 0) == 0)
        #expect(m.overworldGrid.takeAnySlot(column: 5, row: 5) == 1)
        #expect(m.playerProgress.takeAnyHearts == [.takenHeart, .takenPotion, .untaken, .untaken])

        // Set the first tile back to unclaimed → frees slot 0 only.
        m.setOverworldTakeAny(.untaken, column: 0, row: 0)
        #expect(m.overworldGrid.takeAnySlot(column: 0, row: 0) == nil)
        #expect(m.playerProgress.takeAnyHearts == [.untaken, .takenPotion, .untaken, .untaken])
    }

    /// A newly-claimed tile skips slots already owned by another tile even if
    /// that owned slot was emptied directly, so it never double-links.
    @Test("a new tile skips slots owned by another tile")
    func newTileSkipsOwnedSlots() {
        let m = TrackerModel()
        m.setOverworldTakeAny(.takenHeart, column: 0, row: 0)   // owns slot 0
        // Empty slot 0 via its heart box (reverse sync) — still owned by (0,0).
        m.cycleTakeAnySlot(0, by: -1) // heart → untaken
        #expect(m.playerProgress.takeAnyHearts[0] == .untaken)
        // The linked tile's dim clears in sync.
        #expect(!m.overworldGrid.isUsed(column: 0, row: 0))

        // A new take-any tile must NOT grab slot 0 (still owned) — takes slot 1.
        m.setOverworldTakeAny(.takenPotion, column: 3, row: 3)
        #expect(m.overworldGrid.takeAnySlot(column: 3, row: 3) == 1)
    }

    /// Left-click cycling a take-any tile advances its state and its slot.
    @Test("cycling a take-any tile advances its state and slot together")
    func cycleTile() {
        let m = TrackerModel()
        m.setOverworldTakeAny(.untaken, column: 4, row: 4) // unclaimed take-any, no slot
        #expect(m.overworldGrid.takeAnySlot(column: 4, row: 4) == nil)

        m.cycleOverworldTakeAny(column: 4, row: 4) // untaken → heart, claims slot 0
        #expect(m.playerProgress.takeAnyHearts[0] == .takenHeart)
        #expect(m.overworldGrid.takeAnySlot(column: 4, row: 4) == 0)
        #expect(m.overworldGrid.isUsed(column: 4, row: 4))
    }

    /// Groundhog reset clears both the hearts and the tile links.
    @Test("groundhog reset clears take-any hearts and their tile links")
    func groundhogClearsLinks() {
        let m = TrackerModel(quest: .first)
        m.selectQuest(.first)
        m.setOverworldTakeAny(.takenHeart, column: 2, row: 3)
        #expect(m.overworldGrid.takeAnySlot(column: 2, row: 3) == 0)

        m.resetForGroundhogOrRouters()
        #expect(m.playerProgress.takeAnyHearts.allSatisfy { $0 == .untaken })
        #expect(m.overworldGrid.takeAnySlot(column: 2, row: 3) == nil)
        // The mark itself is kept (map knowledge).
        #expect(m.overworldGrid.mark(column: 2, row: 3) == .takeAny)
    }
}
