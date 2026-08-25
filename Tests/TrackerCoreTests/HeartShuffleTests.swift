import Foundation
import Testing
@testable import TrackerCore

@Suite("Heart Shuffle 3-state + intra deduction (T-212)")
struct HeartShuffleTests {
    private struct Wrap: Codable { var h: HeartShuffle }

    @Test("legacy Bool saves decode: false→off, true→full")
    func legacyBoolDecodes() throws {
        let off = try JSONDecoder().decode(Wrap.self, from: Data(#"{"h": false}"#.utf8))
        #expect(off.h == .off)
        let full = try JSONDecoder().decode(Wrap.self, from: Data(#"{"h": true}"#.utf8))
        #expect(full.h == .full)
    }

    @Test("new string form round-trips")
    func stringRoundTrips() throws {
        for mode in HeartShuffle.allCases {
            let data = try JSONEncoder().encode(Wrap(h: mode))
            #expect(try JSONDecoder().decode(Wrap.self, from: data).h == mode)
        }
    }

    @Test("cycle order: off → intra → full → off")
    func cycleOrder() {
        #expect(HeartShuffle.off.next == .intra)
        #expect(HeartShuffle.intra.next == .full)
        #expect(HeartShuffle.full.next == .off)
    }

    @Test("off pre-places dungeon hearts; intra/full do not")
    func preplacement() {
        let model = TrackerModel(quest: .first)
        model.setHeartShuffle(.off)
        #expect(model.dungeonTracker.dungeon(0).boxes.contains { $0.cellCurrent == ITEMS.heartContainer })
        model.setHeartShuffle(.full)
        #expect(!model.dungeonTracker.dungeon(0).boxes.contains { $0.cellCurrent == ITEMS.heartContainer })
    }

    @Test("intra: last unknown slot is deduced as the heart once the others are known non-hearts")
    func intraDeduction() {
        let model = TrackerModel(quest: .first)
        model.setHeartShuffle(.intra)                     // hearts not pre-placed
        let boxes = model.dungeonTracker.dungeon(1).boxes // dungeon 2 (two boxes, non-1/4)
        #expect(boxes.count >= 2)
        // Nothing identified yet → no deduction (all slots unknown).
        model.applyIntraHeartDeduction()
        #expect(!boxes.contains { $0.cellCurrent == ITEMS.heartContainer })
        // Identify all but the last as a non-heart item → the last must be the heart.
        for b in boxes.dropLast() { b.set(cellCurrent: ITEMS.bow, playerHas: .yes) }
        model.applyIntraHeartDeduction()
        let last = boxes.last!
        #expect(last.cellCurrent == ITEMS.heartContainer)
        #expect(last.playerHas == .no)                    // dimmed / untaken
    }

    @Test("intra: no deduction while two or more slots are still unknown")
    func intraHoldsUntilOneLeft() {
        let model = TrackerModel(quest: .first)
        model.setHeartShuffle(.intra)
        // Dungeon 1 (first quest) has the shared third box → 3 slots; identify only one.
        let boxes = model.dungeonTracker.dungeon(0).boxes
        boxes.first!.set(cellCurrent: ITEMS.bow, playerHas: .yes)
        model.applyIntraHeartDeduction()
        #expect(!boxes.contains { $0.cellCurrent == ITEMS.heartContainer })
    }

    @Test("intra: heart pinned to a category once the other category is fully non-heart (D8 / SQ-L4)")
    func intraCategoryDeductionFloorFound() {
        // Dungeon 8 (index 7): 1 floor + 2 basement slots. Find the floor item ⇒ the heart must
        // be a basement, even though which of the two basements is unknown.
        let model = TrackerModel(quest: .first)
        model.setHeartShuffle(.intra)
        let dt = model.dungeonTracker
        let boxes = dt.dungeon(7).boxes
        let floor = boxes.filter { !dt.currentlyHasBasementStair($0) }
        let basement = boxes.filter { dt.currentlyHasBasementStair($0) }
        #expect(floor.count == 1 && basement.count == 2)
        floor[0].set(cellCurrent: ITEMS.bow, playerHas: .yes)      // identify the floor item
        model.applyIntraHeartDeduction()
        // Exactly one basement is now the (untaken) heart; the other stays unknown.
        #expect(basement.filter { $0.cellCurrent == ITEMS.heartContainer }.count == 1)
        #expect(basement.filter { $0.cellCurrent == -1 }.count == 1)
        #expect(floor[0].cellCurrent == ITEMS.bow)                 // floor item untouched
    }

    @Test("intra: find the basement ⇒ heart is one of the floor slots (FQ-L1)")
    func intraCategoryDeductionBasementFound() {
        // First-quest dungeon 1 (index 0): 2 floor + 1 basement slots.
        let model = TrackerModel(quest: .first)
        model.setHeartShuffle(.intra)
        let dt = model.dungeonTracker
        let boxes = dt.dungeon(0).boxes
        let floor = boxes.filter { !dt.currentlyHasBasementStair($0) }
        let basement = boxes.filter { dt.currentlyHasBasementStair($0) }
        #expect(floor.count == 2 && basement.count == 1)
        basement[0].set(cellCurrent: ITEMS.bow, playerHas: .yes)   // identify the basement item
        model.applyIntraHeartDeduction()
        #expect(floor.filter { $0.cellCurrent == ITEMS.heartContainer }.count == 1)
        #expect(floor.filter { $0.cellCurrent == -1 }.count == 1)
    }

    @Test("off mode never deduces")
    func offNeverDeduces() {
        let model = TrackerModel(quest: .first)
        model.setHeartShuffle(.off)
        let boxes = model.dungeonTracker.dungeon(1).boxes
        for b in boxes.dropLast() { b.set(cellCurrent: ITEMS.bow, playerHas: .yes) }
        boxes.last!.set(cellCurrent: -1, playerHas: .no)   // force an unknown last slot
        model.applyIntraHeartDeduction()
        #expect(boxes.last!.cellCurrent == -1)             // unchanged — deduction is intra-only
    }
}
