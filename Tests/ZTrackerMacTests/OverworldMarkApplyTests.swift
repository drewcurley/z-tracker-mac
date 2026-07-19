import Testing
import TrackerCore
@testable import ZTrackerMac

/// The shared overworld mark-apply used by both the click path and the keyboard
/// hotkey path (T-134), so the two can't drift.
@MainActor
struct OverworldMarkApplyTests {
    private func noop(_ a: Int, _ b: Int) {}
    private func noopPlace(_ a: Int, _ b: Int, _ c: Int) {}

    @Test func setsTheMark() {
        let model = TrackerModel(quest: .first)
        OverworldMark.apply(.shop(.bomb), column: 4, row: 3, grid: model.overworldGrid,
                            releaseTakeAny: noop, placeDungeon: noopPlace)
        #expect(model.overworldGrid.mark(column: 4, row: 3) == .shop(.bomb))
    }

    @Test func secretPlacesUsed() {
        let model = TrackerModel(quest: .first)
        OverworldMark.apply(.secret(.large), column: 5, row: 2, grid: model.overworldGrid,
                            releaseTakeAny: noop, placeDungeon: noopPlace)
        #expect(model.overworldGrid.isUsed(column: 5, row: 2))
    }

    @Test func takeAnyStaysBright() {
        let model = TrackerModel(quest: .first)
        OverworldMark.apply(.takeAny, column: 6, row: 1, grid: model.overworldGrid,
                            releaseTakeAny: noop, placeDungeon: noopPlace)
        #expect(model.overworldGrid.isUsed(column: 6, row: 1) == false)
    }

    @Test func changingATakeAnyReleasesItsSlot() {
        let model = TrackerModel(quest: .first)
        model.overworldGrid.setMark(.takeAny, column: 7, row: 4)
        var released: (Int, Int)?
        OverworldMark.apply(.shop(.key), column: 7, row: 4, grid: model.overworldGrid,
                            releaseTakeAny: { c, r in released = (c, r) }, placeDungeon: noopPlace)
        #expect(released?.0 == 7 && released?.1 == 4)
    }

    @Test func placingADungeonFiresPlaceCallback() {
        let model = TrackerModel(quest: .first)
        var placed: (Int, Int, Int)?
        OverworldMark.apply(.dungeon(5), column: 8, row: 3, grid: model.overworldGrid,
                            releaseTakeAny: noop, placeDungeon: { n, c, r in placed = (n, c, r) })
        #expect(placed?.0 == 5 && placed?.1 == 8 && placed?.2 == 3)
    }

    @Test func shopCantHoldSameItemTwice() {
        let model = TrackerModel(quest: .first)
        model.overworldGrid.setMark(.shop(.arrow), column: 2, row: 2)
        model.overworldGrid.setShopSecondItem(.bomb, column: 2, row: 2)
        // Re-marking the primary as the second item clears the duplicate second.
        OverworldMark.apply(.shop(.bomb), column: 2, row: 2, grid: model.overworldGrid,
                            releaseTakeAny: noop, placeDungeon: noopPlace)
        #expect(model.overworldGrid.shopSecondItem(column: 2, row: 2) == nil)
    }

    @Test func armosReturnsItemPromptFlag() {
        let model = TrackerModel(quest: .first)
        let r1 = OverworldMark.apply(.armos, column: 1, row: 1, grid: model.overworldGrid,
                                     releaseTakeAny: noop, placeDungeon: noopPlace)
        #expect(r1.itemPromptIsArmos == true)
        let r2 = OverworldMark.apply(.swordCave(2), column: 1, row: 2, grid: model.overworldGrid,
                                     releaseTakeAny: noop, placeDungeon: noopPlace)
        #expect(r2.itemPromptIsArmos == false)
        let r3 = OverworldMark.apply(.shop(.meat), column: 1, row: 3, grid: model.overworldGrid,
                                     releaseTakeAny: noop, placeDungeon: noopPlace)
        #expect(r3.itemPromptIsArmos == nil)
    }

    @Test func voiceSecondShopWordSetsSecondItem() {
        let model = TrackerModel(quest: .first)
        model.overworldGrid.setMark(.shop(.bomb), column: 4, row: 4)
        // Saying a second, distinct shop name adds it as the second item.
        let handled = OverworldMark.applyVoiceSecondShopItem(.shop(.candle), column: 4, row: 4,
                                                             grid: model.overworldGrid)
        #expect(handled)
        #expect(model.overworldGrid.mark(column: 4, row: 4) == .shop(.bomb))   // primary kept
        #expect(model.overworldGrid.shopSecondItem(column: 4, row: 4) == .candle)
    }

    @Test func voiceSecondShopIgnoredWhenNotAShopOrSameKind() {
        let model = TrackerModel(quest: .first)
        // Empty tile → not handled (normal apply should place the primary).
        #expect(OverworldMark.applyVoiceSecondShopItem(.shop(.bomb), column: 5, row: 5,
                                                       grid: model.overworldGrid) == false)
        // Same kind as primary → not handled (no self-duplicate second).
        model.overworldGrid.setMark(.shop(.meat), column: 5, row: 5)
        #expect(OverworldMark.applyVoiceSecondShopItem(.shop(.meat), column: 5, row: 5,
                                                       grid: model.overworldGrid) == false)
        // A non-shop mark → not handled.
        #expect(OverworldMark.applyVoiceSecondShopItem(.armos, column: 5, row: 5,
                                                       grid: model.overworldGrid) == false)
    }

    @Test func twoItemShopUtteranceSetsPrimaryAndSecond() {
        // T-158: the controller resolves a two-shop utterance to (primary, second),
        // then applies the primary mark and sets the second item. This is that outcome.
        let config = VoiceConfig()
        let pair = VoiceGrammar.overworldShopPair(["bomb", "shop", "and", "meat"], config: config)
        #expect(pair?.primary == .bomb)
        #expect(pair?.second == .meat)

        let model = TrackerModel(quest: .first)
        OverworldMark.apply(.shop(pair!.primary), column: 6, row: 4, grid: model.overworldGrid,
                            releaseTakeAny: noop, placeDungeon: noopPlace)
        model.overworldGrid.setShopSecondItem(pair!.second, column: 6, row: 4)
        #expect(model.overworldGrid.mark(column: 6, row: 4) == .shop(.bomb))
        #expect(model.overworldGrid.shopSecondItem(column: 6, row: 4) == .meat)
    }

    @Test func reportsPriorMark() {
        let model = TrackerModel(quest: .first)
        model.overworldGrid.setMark(.armos, column: 3, row: 3)
        let result = OverworldMark.apply(.unmarked, column: 3, row: 3, grid: model.overworldGrid,
                                         releaseTakeAny: noop, placeDungeon: noopPlace)
        #expect(result.oldMark == .armos)
    }
}
