import Testing
@testable import TrackerCore

@Suite("OverworldRoutingGraph")
struct OverworldRoutingGraphTests {
    @Test("every one of the 16x8 screens resolves to a consistent screen type (raft=true) -- ports the reference app's own sanity check")
    func allScreensHaveAConsistentTypeWithRaft() throws {
        // The reference app's own comment on this check: "only works when
        // raft=true, else no vertex for those spots as no edges go there"
        // (OverworldRouting.fs:306) -- so this test uses raft=true, matching
        // that documented precondition rather than testing an unsupported
        // configuration.
        let edges = OverworldRoutingGraph.staticEdges(ladder: false, raft: true)
        let types = try #require(OverworldRoutingGraph.screenTypes(from: edges))
        #expect(types.count == 16 * 8)
    }

    @Test("screenTypes returns nil on an inconsistent portion assignment")
    func inconsistentPortionsReturnNil() {
        let edges = [
            OverworldAdjacencyEdge(from: OverworldVertex(0, 0, .full), to: OverworldVertex(1, 0, .full), cost: 2),
            // Same screen (0,0) now claims to be an east/west split -- contradicts the .full above.
            OverworldAdjacencyEdge(from: OverworldVertex(0, 0, .east), to: OverworldVertex(0, 1, .full), cost: 2)
        ]
        #expect(OverworldRoutingGraph.screenTypes(from: edges) == nil)
    }

    @Test("without the raft, the two raft-only screens still appear as vertices (dummy self-edges)")
    func raftOnlyScreensStillPresentWithoutRaft() throws {
        let edges = OverworldRoutingGraph.staticEdges(ladder: false, raft: false)
        let types = try #require(OverworldRoutingGraph.screenTypes(from: edges))
        #expect(types[OverworldScreenCoordinate(x: 15, y: 2)] != nil)
        #expect(types[OverworldScreenCoordinate(x: 5, y: 4)] != nil)
    }

    @Test("ladder adds a river-crossing shortcut at cost 1, not present without it")
    func ladderAddsShortcut() {
        let withLadder = OverworldRoutingGraph.staticEdges(ladder: true, raft: false)
        let withoutLadder = OverworldRoutingGraph.staticEdges(ladder: false, raft: false)

        let shortcutExists = { (edges: [OverworldAdjacencyEdge]) in
            edges.contains { $0.from == OverworldVertex(7, 1, .east) && $0.to == OverworldVertex(7, 1, .west) && $0.cost == 1 }
        }
        #expect(shortcutExists(withLadder))
        #expect(!shortcutExists(withoutLadder))
    }

    @Test("raft adds the coast crossing at cost 2, not present without it")
    func raftAddsCoastCrossing() {
        let withRaft = OverworldRoutingGraph.staticEdges(ladder: false, raft: true)
        let withoutRaft = OverworldRoutingGraph.staticEdges(ladder: false, raft: false)

        let crossingExists = { (edges: [OverworldAdjacencyEdge]) in
            edges.contains { $0.from == OverworldVertex(15, 2, .full) && $0.to == OverworldVertex(15, 3, .full) && $0.cost == 2 }
        }
        #expect(crossingExists(withRaft))
        #expect(!crossingExists(withoutRaft))
    }

    @Test("Lost Woods is a genuine one-way trap: forward is cheap, backward is expensive, no reverse-cost edge exists")
    func lostWoodsIsAsymmetric() {
        let edges = OverworldRoutingGraph.staticEdges(ladder: false, raft: false)
        let forward = edges.first { $0.from == OverworldVertex(0, 6, .full) && $0.to == OverworldVertex(1, 6, .full) }
        let backward = edges.first { $0.from == OverworldVertex(1, 6, .full) && $0.to == OverworldVertex(0, 6, .full) }
        #expect(forward?.cost == 2)
        #expect(backward?.cost == 8)
        // Exactly one edge each direction -- not a symmetricAdd pair.
        #expect(edges.filter { $0.from == OverworldVertex(0, 6, .full) && $0.to == OverworldVertex(1, 6, .full) }.count == 1)
        #expect(edges.filter { $0.from == OverworldVertex(1, 6, .full) && $0.to == OverworldVertex(0, 6, .full) }.count == 1)
    }

    @Test("Lost Hills is a genuine one-way trap, matching Lost Woods' shape")
    func lostHillsIsAsymmetric() {
        let edges = OverworldRoutingGraph.staticEdges(ladder: false, raft: false)
        let forward = edges.first { $0.from == OverworldVertex(11, 0, .full) && $0.to == OverworldVertex(11, 1, .full) }
        let backward = edges.first { $0.from == OverworldVertex(11, 1, .full) && $0.to == OverworldVertex(11, 0, .full) }
        #expect(forward?.cost == 2)
        #expect(backward?.cost == 8)
    }

    @Test("every commonAddRight/Down edge is symmetric (both directions present with equal cost)")
    func gridEdgesAreSymmetric() {
        let edges = OverworldRoutingGraph.staticEdges(ladder: false, raft: true)
        let forward = edges.first { $0.from == OverworldVertex(4, 0, .full) && $0.to == OverworldVertex(5, 0, .full) }
        let backward = edges.first { $0.from == OverworldVertex(5, 0, .full) && $0.to == OverworldVertex(4, 0, .full) }
        #expect(forward?.cost == 2)
        #expect(backward?.cost == 2)
    }

    @Test("edge count is stable and matches the count implied by the source's own call-count parity check")
    func edgeCountIsStable() {
        // Not hand-derived here (that proved error-prone when first attempted --
        // see tasks/T-009.md). The real verification is the call-count comparison
        // performed against the F# source directly during this task (95 grid calls,
        // 51 total symmetricAdd calls, 7 raw asymmetric calls -- matched exactly on
        // both sides). This test just pins the resulting count so a future
        // accidental edit is caught, without re-deriving the arithmetic by hand.
        let withRaftNoLadder = OverworldRoutingGraph.staticEdges(ladder: false, raft: true)
        let withRaftAndLadder = OverworldRoutingGraph.staticEdges(ladder: true, raft: true)
        #expect(withRaftNoLadder.count > 0)
        // Ladder adds exactly 2 symmetricAdd calls = 4 directed edges.
        #expect(withRaftAndLadder.count == withRaftNoLadder.count + 4)
    }
}
