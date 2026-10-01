import Testing
import TrackerCore
@testable import ZTrackerMac

/// Voice item-box commands (T-143) — "coast ladder" sets the coast picker box, with
/// the user's overworld scoping and the shared `ItemBoxMark` path. The acquisition
/// gate (T-236) is covered at the bottom.
@MainActor
struct ItemBoxVoiceApplyTests {
    /// A player state with enough hearts/items that gated boxes default to taken.
    private let reachable = PlayerComputedStateSummary(haveLadder: true, playerHearts: 14)

    @Test func setsTheNamedBoxInOverworldRegion() {
        let model = TrackerModel(quest: .first)
        #expect(ItemBoxVoiceApply.apply(boxID: "Box_Coast", itemID: "Item_Recorder",
                                        region: .overworld, tracker: model.dungeonTracker,
                                        playerState: reachable))
        #expect(model.dungeonTracker.ladderBox.cellCurrent == ITEMS.recorder)
    }

    @Test func coastBoxCannotHoldTheLadder() {
        // Deliberate rule beyond the reference: the coast box can't hold the ladder.
        let model = TrackerModel(quest: .first)
        #expect(ItemBoxVoiceApply.apply(boxID: "Box_Coast", itemID: "Item_Ladder",
                                        region: .overworld, tracker: model.dungeonTracker,
                                        playerState: reachable) == false)
        #expect(model.dungeonTracker.ladderBox.cellCurrent != ITEMS.ladder)
    }

    @Test func overworldScopedNotAppliedElsewhere() {
        let model = TrackerModel(quest: .first)
        #expect(ItemBoxVoiceApply.apply(boxID: "Box_Armos", itemID: "Item_Bow",
                                        region: .items, tracker: model.dungeonTracker,
                                        playerState: reachable) == false)
        #expect(model.dungeonTracker.armosBox.cellCurrent != ITEMS.bow)
    }

    @Test func nothingClearsTheBox() {
        let model = TrackerModel(quest: .first)
        ItemBoxVoiceApply.apply(boxID: "Box_WhiteSword", itemID: "Item_Bow",
                                region: .overworld, tracker: model.dungeonTracker, playerState: reachable)
        #expect(model.dungeonTracker.sword2Box.cellCurrent == ITEMS.bow)
        #expect(ItemBoxVoiceApply.apply(boxID: "Box_WhiteSword", itemID: "Item_Nothing",
                                        region: .overworld, tracker: model.dungeonTracker, playerState: reachable))
        #expect(model.dungeonTracker.sword2Box.cellCurrent == -1)
    }

    @Test func unknownIdsNotApplied() {
        let model = TrackerModel(quest: .first)
        #expect(ItemBoxVoiceApply.apply(boxID: "Box_Nope", itemID: "Item_Bow",
                                        region: .overworld, tracker: model.dungeonTracker,
                                        playerState: reachable) == false)
        #expect(ItemBoxVoiceApply.apply(boxID: "Box_Coast", itemID: "Item_Nope",
                                        region: .overworld, tracker: model.dungeonTracker,
                                        playerState: reachable) == false)
    }

    @Test func everyCatalogBoxAndItemIdMaps() {
        for action in VoiceCatalog.all where action.category == .itemBoxes {
            #expect(ItemBoxVoiceApply.box(forID: action.id) != nil, "no box for \(action.id)")
        }
        for action in VoiceCatalog.all where action.category == .items {
            #expect(ItemBoxVoiceApply.itemIndex(forID: action.id) != nil, "no item index for \(action.id)")
        }
    }

    // MARK: Acquisition gate (T-236)

    @Test("white-sword item below the heart gate is identified, not taken")
    func whiteSwordItemBelowHeartGateIsIdentifiedNotTaken() {
        let model = TrackerModel(quest: .first)
        // 3 hearts (below the 4-heart white-sword minimum): record WHAT it is, not that you have it.
        #expect(ItemBoxVoiceApply.apply(boxID: "Box_WhiteSword", itemID: "Item_Bow",
                                        region: .overworld, tracker: model.dungeonTracker,
                                        playerState: PlayerComputedStateSummary(playerHearts: 3)))
        #expect(model.dungeonTracker.sword2Box.cellCurrent == ITEMS.bow)   // identified
        #expect(model.dungeonTracker.sword2Box.playerHas == .no)           // but NOT owned
    }

    @Test("white-sword item at the heart gate is taken")
    func whiteSwordItemAtHeartGateIsTaken() {
        let model = TrackerModel(quest: .first)
        #expect(ItemBoxVoiceApply.apply(boxID: "Box_WhiteSword", itemID: "Item_Bow",
                                        region: .overworld, tracker: model.dungeonTracker,
                                        playerState: PlayerComputedStateSummary(playerHearts: 4)))
        #expect(model.dungeonTracker.sword2Box.playerHas == .yes)
    }

    @Test("coast item follows the ladder gate")
    func coastItemFollowsLadderGate() {
        let noLadder = TrackerModel(quest: .first)
        #expect(ItemBoxVoiceApply.apply(boxID: "Box_Coast", itemID: "Item_Recorder",
                                        region: .overworld, tracker: noLadder.dungeonTracker,
                                        playerState: PlayerComputedStateSummary(haveLadder: false)))
        #expect(noLadder.dungeonTracker.ladderBox.playerHas == .no)        // can't reach without ladder

        let withLadder = TrackerModel(quest: .first)
        #expect(ItemBoxVoiceApply.apply(boxID: "Box_Coast", itemID: "Item_Recorder",
                                        region: .overworld, tracker: withLadder.dungeonTracker,
                                        playerState: PlayerComputedStateSummary(haveLadder: true)))
        #expect(withLadder.dungeonTracker.ladderBox.playerHas == .yes)
    }

    @Test("armos has no gate — always taken")
    func armosAlwaysTaken() {
        let model = TrackerModel(quest: .first)
        #expect(ItemBoxVoiceApply.apply(boxID: "Box_Armos", itemID: "Item_Bow",
                                        region: .overworld, tracker: model.dungeonTracker,
                                        playerState: PlayerComputedStateSummary(playerHearts: 3)))
        #expect(model.dungeonTracker.armosBox.playerHas == .yes)
    }
}
