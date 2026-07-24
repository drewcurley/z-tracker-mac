import Testing
import TrackerCore
@testable import ZTrackerMac

/// T-169 — the per-context hotkey "smarts" whose logic lives in the apply enums:
/// item-box possession cycling, and overworld shop add/remove/replace.
@Suite("Hotkey smarts (T-169)")
@MainActor
struct HotkeySmartsTests {

    // MARK: item box possession cycle

    @Test("a fresh item hotkey claims possession (YES)")
    func freshPressIsYes() {
        let m = TrackerModel(quest: .first)
        let box = m.dungeonTracker.armosBox
        ItemBoxMark.cycleHotkey(itemIndex: ITEMS.raft, box: box, instance: m.dungeonTracker)
        #expect(box.cellCurrent == ITEMS.raft)
        #expect(box.playerHas == .yes)
    }

    @Test("repeat presses of the held item cycle YES → skipped → NO → YES")
    func repeatCyclesPossession() {
        let m = TrackerModel(quest: .first)
        let box = m.dungeonTracker.armosBox
        ItemBoxMark.cycleHotkey(itemIndex: ITEMS.raft, box: box, instance: m.dungeonTracker)
        #expect(box.playerHas == .yes)
        ItemBoxMark.cycleHotkey(itemIndex: ITEMS.raft, box: box, instance: m.dungeonTracker)
        #expect(box.playerHas == .skipped)
        ItemBoxMark.cycleHotkey(itemIndex: ITEMS.raft, box: box, instance: m.dungeonTracker)
        #expect(box.playerHas == .no)
        #expect(box.cellCurrent == ITEMS.raft)      // item unchanged through the cycle
        ItemBoxMark.cycleHotkey(itemIndex: ITEMS.raft, box: box, instance: m.dungeonTracker)
        #expect(box.playerHas == .yes)              // wraps
    }

    @Test("a different item key replaces the item at YES, not a cycle step")
    func differentItemReplaces() {
        let m = TrackerModel(quest: .first)
        let box = m.dungeonTracker.armosBox
        ItemBoxMark.cycleHotkey(itemIndex: ITEMS.raft, box: box, instance: m.dungeonTracker)
        ItemBoxMark.cycleHotkey(itemIndex: ITEMS.ladder, box: box, instance: m.dungeonTracker)
        #expect(box.cellCurrent == ITEMS.ladder)
        #expect(box.playerHas == .yes)
    }

    @Test("the Nothing key clears a filled box, then toggles the empty outline red ⇄ white")
    func nothingKeyClearsThenTogglesOutline() {
        let m = TrackerModel(quest: .first)
        let box = m.dungeonTracker.armosBox
        ItemBoxMark.cycleHotkey(itemIndex: ITEMS.raft, box: box, instance: m.dungeonTracker)
        ItemBoxMark.cycleHotkey(itemIndex: -1, box: box, instance: m.dungeonTracker)   // clear
        #expect(box.cellCurrent == -1)
        #expect(box.playerHas == .no)               // empty-red
        ItemBoxMark.cycleHotkey(itemIndex: -1, box: box, instance: m.dungeonTracker)   // red → white
        #expect(box.playerHas == .skipped)
        ItemBoxMark.cycleHotkey(itemIndex: -1, box: box, instance: m.dungeonTracker)   // white → red
        #expect(box.playerHas == .no)
    }

    // MARK: overworld shop add / remove / replace

    private func shopKind(_ mark: OverworldTileMark) -> ShopKind? {
        if case .shop(let k) = mark { return k }; return nil
    }

    @Test("a fresh shop tile is left to normal placement (smart returns false)")
    func freshShopNotHandledBySmart() {
        let g = OverworldGrid()
        #expect(OverworldMark.applyShopHotkeySmart(.bomb, column: 4, row: 4, grid: g) == false)
    }

    @Test("a second, different item fills the free slot")
    func secondItemFillsSlot() {
        let g = OverworldGrid()
        g.setMark(.shop(.bomb), column: 4, row: 4)
        #expect(OverworldMark.applyShopHotkeySmart(.arrow, column: 4, row: 4, grid: g))
        #expect(shopKind(g.mark(column: 4, row: 4)) == .bomb)
        #expect(g.shopSecondItem(column: 4, row: 4) == .arrow)
    }

    @Test("pressing the primary item removes it; a present secondary is promoted")
    func removingPrimaryPromotesSecondary() {
        let g = OverworldGrid()
        g.setMark(.shop(.bomb), column: 4, row: 4)
        g.setShopSecondItem(.arrow, column: 4, row: 4)
        #expect(OverworldMark.applyShopHotkeySmart(.bomb, column: 4, row: 4, grid: g))
        #expect(shopKind(g.mark(column: 4, row: 4)) == .arrow)
        #expect(g.shopSecondItem(column: 4, row: 4) == nil)
    }

    @Test("pressing the only item empties the tile")
    func removingOnlyItemClearsTile() {
        let g = OverworldGrid()
        g.setMark(.shop(.bomb), column: 4, row: 4)
        #expect(OverworldMark.applyShopHotkeySmart(.bomb, column: 4, row: 4, grid: g))
        #expect(g.mark(column: 4, row: 4) == .unmarked)
    }

    @Test("pressing the secondary item removes just it")
    func removingSecondary() {
        let g = OverworldGrid()
        g.setMark(.shop(.bomb), column: 4, row: 4)
        g.setShopSecondItem(.arrow, column: 4, row: 4)
        #expect(OverworldMark.applyShopHotkeySmart(.arrow, column: 4, row: 4, grid: g))
        #expect(shopKind(g.mark(column: 4, row: 4)) == .bomb)
        #expect(g.shopSecondItem(column: 4, row: 4) == nil)
    }

    @Test("a third item, with both slots full, replaces the primary and keeps the secondary")
    func thirdItemReplacesPrimary() {
        let g = OverworldGrid()
        g.setMark(.shop(.bomb), column: 4, row: 4)
        g.setShopSecondItem(.arrow, column: 4, row: 4)
        #expect(OverworldMark.applyShopHotkeySmart(.candle, column: 4, row: 4, grid: g))
        #expect(shopKind(g.mark(column: 4, row: 4)) == .candle)
        #expect(g.shopSecondItem(column: 4, row: 4) == .arrow)
    }
}
