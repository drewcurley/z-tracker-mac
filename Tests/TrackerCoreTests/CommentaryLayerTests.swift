import Testing
@testable import TrackerCore

@Suite("Commentary Mode overlay (T-215)")
struct CommentaryLayerTests {
    @Test("toggling a runner cycles neither → R1 → both → R2 → neither")
    func toggle() {
        let c = CommentaryLayer()
        #expect(c.knowledge(column: 3, row: 4).isEmpty)
        c.toggle(.runner1, column: 3, row: 4)
        #expect(c.knowledge(column: 3, row: 4) == .runner1)
        c.toggle(.runner2, column: 3, row: 4)
        #expect(c.knowledge(column: 3, row: 4) == [.runner1, .runner2])
        c.toggle(.runner1, column: 3, row: 4)
        #expect(c.knowledge(column: 3, row: 4) == .runner2)
        c.toggle(.runner2, column: 3, row: 4)
        #expect(c.knowledge(column: 3, row: 4).isEmpty)
    }

    @Test("cleared-to-empty screens don't linger in the map")
    func staysSparse() {
        let c = CommentaryLayer()
        c.toggle(.runner1, column: 1, row: 1)
        c.toggle(.runner1, column: 1, row: 1)   // back to empty
        #expect(c.marks.isEmpty)
    }

    @Test("clearOverworld wipes marks but keeps runner identities")
    func clear() {
        let c = CommentaryLayer()
        c.runner1Name = "Alice"; c.toggle(.runner2, column: 2, row: 2)
        c.clearAll()
        #expect(c.marks.isEmpty)
        #expect(c.runner1Name == "Alice")
    }

    @Test("per-surface keys are distinct so one store serves every surface")
    func namespacedKeys() {
        // The five surfaces must never collide on the same coordinates.
        let keys = Set([
            CommentaryLayer.overworldKey(column: 2, row: 3),
            CommentaryLayer.dungeonBoxKey(dungeon: 2, box: 3),
            CommentaryLayer.itemKey("2,3"),
            CommentaryLayer.roomKey(dungeon: 2, col: 2, row: 3),
            CommentaryLayer.blockerKey(dungeon: 2, slot: 3),
        ])
        #expect(keys.count == 5)

        // A generic toggle on a blocker key reads back through the generic accessor.
        let c = CommentaryLayer()
        let k = CommentaryLayer.blockerKey(dungeon: 4, slot: 1)
        c.toggle(.runner2, key: k)
        #expect(c.knowledge(k) == .runner2)
        #expect(c.knowledge(column: 4, row: 1).isEmpty)   // not the overworld cell 4,1
    }

    @Test("state round-trips through save/restore")
    func roundTrip() {
        let c = CommentaryLayer()
        c.runner1Name = "Alice"; c.runner2Name = "Bob"
        c.runner1ColorHex = "#112233"; c.runner2ColorHex = "#445566"
        c.toggle(.runner1, column: 5, row: 6)
        c.toggle(.runner2, column: 5, row: 6)
        c.toggle(.runner2, column: 0, row: 0)

        let restored = CommentaryLayer()
        restored.restore(c.state)
        #expect(restored.runner1Name == "Alice" && restored.runner2Name == "Bob")
        #expect(restored.runner1ColorHex == "#112233" && restored.runner2ColorHex == "#445566")
        #expect(restored.knowledge(column: 5, row: 6) == [.runner1, .runner2])
        #expect(restored.knowledge(column: 0, row: 0) == .runner2)
        #expect(restored.marks.count == 2)
    }
}
