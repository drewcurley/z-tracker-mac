import Testing
import TrackerCore
@testable import ZTrackerMac

/// Voice item-box commands (T-143) — "coast ladder" sets the coast picker box, with
/// the user's overworld scoping and the shared `ItemBoxMark` path.
@MainActor
struct ItemBoxVoiceApplyTests {
    @Test func setsTheNamedBoxInOverworldRegion() {
        let model = TrackerModel(quest: .first)
        #expect(ItemBoxVoiceApply.apply(boxID: "Box_Coast", itemID: "Item_Recorder",
                                        region: .overworld, tracker: model.dungeonTracker))
        #expect(model.dungeonTracker.ladderBox.cellCurrent == ITEMS.recorder)
    }

    @Test func coastBoxCannotHoldTheLadder() {
        // Deliberate rule beyond the reference: the coast box can't hold the ladder.
        let model = TrackerModel(quest: .first)
        #expect(ItemBoxVoiceApply.apply(boxID: "Box_Coast", itemID: "Item_Ladder",
                                        region: .overworld, tracker: model.dungeonTracker) == false)
        #expect(model.dungeonTracker.ladderBox.cellCurrent != ITEMS.ladder)
    }

    @Test func overworldScopedNotAppliedElsewhere() {
        let model = TrackerModel(quest: .first)
        #expect(ItemBoxVoiceApply.apply(boxID: "Box_Armos", itemID: "Item_Bow",
                                        region: .items, tracker: model.dungeonTracker) == false)
        #expect(model.dungeonTracker.armosBox.cellCurrent != ITEMS.bow)
    }

    @Test func nothingClearsTheBox() {
        let model = TrackerModel(quest: .first)
        ItemBoxVoiceApply.apply(boxID: "Box_WhiteSword", itemID: "Item_Bow",
                                region: .overworld, tracker: model.dungeonTracker)
        #expect(model.dungeonTracker.sword2Box.cellCurrent == ITEMS.bow)
        #expect(ItemBoxVoiceApply.apply(boxID: "Box_WhiteSword", itemID: "Item_Nothing",
                                        region: .overworld, tracker: model.dungeonTracker))
        #expect(model.dungeonTracker.sword2Box.cellCurrent == -1)
    }

    @Test func unknownIdsNotApplied() {
        let model = TrackerModel(quest: .first)
        #expect(ItemBoxVoiceApply.apply(boxID: "Box_Nope", itemID: "Item_Bow",
                                        region: .overworld, tracker: model.dungeonTracker) == false)
        #expect(ItemBoxVoiceApply.apply(boxID: "Box_Coast", itemID: "Item_Nope",
                                        region: .overworld, tracker: model.dungeonTracker) == false)
    }

    @Test func everyCatalogBoxAndItemIdMaps() {
        for action in VoiceCatalog.all where action.category == .itemBoxes {
            #expect(ItemBoxVoiceApply.box(forID: action.id) != nil, "no box for \(action.id)")
        }
        for action in VoiceCatalog.all where action.category == .items {
            #expect(ItemBoxVoiceApply.itemIndex(forID: action.id) != nil, "no item index for \(action.id)")
        }
    }
}
