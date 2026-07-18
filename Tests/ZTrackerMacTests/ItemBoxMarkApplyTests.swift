import Testing
import TrackerCore
@testable import ZTrackerMac

/// Item-box hotkey mapping + apply (T-135).
@MainActor
struct ItemBoxMarkApplyTests {
    @Test func suffixesMapToItemIndices() {
        #expect(ItemBoxMark.itemIndex(forHotkeySuffix: "BookOrShield") == ITEMS.bookOrShield)
        #expect(ItemBoxMark.itemIndex(forHotkeySuffix: "Bow") == ITEMS.bow)
        #expect(ItemBoxMark.itemIndex(forHotkeySuffix: "Recorder") == ITEMS.recorder)
        #expect(ItemBoxMark.itemIndex(forHotkeySuffix: "HeartContainer") == ITEMS.heartContainer)
        #expect(ItemBoxMark.itemIndex(forHotkeySuffix: "Nothing") == -1)
        #expect(ItemBoxMark.itemIndex(forHotkeySuffix: "Bogus") == nil)
    }

    /// Every catalog items selector maps, or a bound key would do nothing.
    @Test func everyItemsSelectorMaps() {
        for sel in HotkeyCatalog.selectors(in: .items) {
            let suffix = String(sel.id.dropFirst("Item_".count))
            #expect(ItemBoxMark.itemIndex(forHotkeySuffix: suffix) != nil, "no mapping for \(sel.id)")
        }
    }

    @Test func placesAndClearsABox() {
        let model = TrackerModel(quest: .first)
        let box = model.dungeonTracker.armosBox
        #expect(ItemBoxMark.apply(itemIndex: ITEMS.raft, to: box, instance: model.dungeonTracker))
        #expect(box.cellCurrent == ITEMS.raft)
        #expect(box.playerHas == .yes)
        ItemBoxMark.apply(itemIndex: -1, to: box, instance: model.dungeonTracker)
        #expect(box.cellCurrent == -1)
    }
}
