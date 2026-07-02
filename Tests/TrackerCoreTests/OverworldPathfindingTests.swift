import Testing
@testable import TrackerCore

@Suite("OverworldRoutingGraph dynamic layer + pathfinding")
struct OverworldPathfindingTests {
    @Test("dynamicGraph succeeds and produces a fully-typed screen set with raft")
    func dynamicGraphSucceedsWithRaft() throws {
        let graph = try #require(OverworldRoutingGraph.dynamicGraph(
            ladder: false, raft: true, recorderWarpDestinations: [], anyRoads: [],
            isMirror: false, canScreenScroll: false
        ))
        #expect(graph.screenTypes.count == 16 * 8)
    }

    @Test("direct adjacent screens: (0,0) to (1,0) costs exactly 2")
    func directAdjacencyCost() throws {
        let graph = try #require(OverworldRoutingGraph.dynamicGraph(
            ladder: false, raft: true, recorderWarpDestinations: [], anyRoads: [],
            isMirror: false, canScreenScroll: false
        ))
        let source = OverworldVertex(0, 0, .full)
        let target = OverworldVertex(1, 0, .full)
        let paths = OverworldRoutingGraph.findAllBestPaths(adjacency: graph.adjacency, from: source, to: target)
        #expect(paths[target]?.cost == 2)
    }

    @Test("two hops across the top row: (0,0) to (2,0) costs exactly 4, via (1,0)")
    func twoHopCost() throws {
        let graph = try #require(OverworldRoutingGraph.dynamicGraph(
            ladder: false, raft: true, recorderWarpDestinations: [], anyRoads: [],
            isMirror: false, canScreenScroll: false
        ))
        let source = OverworldVertex(0, 0, .full)
        let target = OverworldVertex(2, 0, .full)
        let paths = OverworldRoutingGraph.findAllBestPaths(adjacency: graph.adjacency, from: source, to: target)
        #expect(paths[target]?.cost == 4)
        #expect(paths[target]?.predecessors == [OverworldVertex(1, 0, .full)])
    }

    @Test("Lost Woods dead-end: the only way into (0,6) is via (1,6) at cost 8, since (0,6) has no other connections")
    func lostWoodsDeadEndCost() throws {
        // (0,6)/(1,6)/(2,6) are deliberately excluded from ordinary grid
        // connectivity (verified by inspecting the source's row-6 commonAdd*
        // calls, none of which mention x<3) -- (0,6) connects only to (1,6),
        // so the round-trip cost is forced, not just "probably" 8.
        let graph = try #require(OverworldRoutingGraph.dynamicGraph(
            ladder: false, raft: false, recorderWarpDestinations: [], anyRoads: [],
            isMirror: false, canScreenScroll: false
        ))
        let source = OverworldVertex(1, 6, .full)
        let target = OverworldVertex(0, 6, .full)
        let paths = OverworldRoutingGraph.findAllBestPaths(adjacency: graph.adjacency, from: source, to: target)
        #expect(paths[target]?.cost == 8)
    }

    @Test("Lost Woods forward direction is cheap: (0,6) to (1,6) costs 2")
    func lostWoodsForwardCost() throws {
        let graph = try #require(OverworldRoutingGraph.dynamicGraph(
            ladder: false, raft: false, recorderWarpDestinations: [], anyRoads: [],
            isMirror: false, canScreenScroll: false
        ))
        let source = OverworldVertex(0, 6, .full)
        let target = OverworldVertex(1, 6, .full)
        let paths = OverworldRoutingGraph.findAllBestPaths(adjacency: graph.adjacency, from: source, to: target)
        #expect(paths[target]?.cost == 2)
    }

    @Test("the source vertex is always in its own result at cost 0 with no predecessors")
    func sourceIsZeroCostWithNoPredecessors() throws {
        let graph = try #require(OverworldRoutingGraph.dynamicGraph(
            ladder: false, raft: true, recorderWarpDestinations: [], anyRoads: [],
            isMirror: false, canScreenScroll: false
        ))
        let source = OverworldVertex(4, 4, .full)
        let paths = OverworldRoutingGraph.findAllBestPaths(adjacency: graph.adjacency, from: source, to: source)
        #expect(paths[source]?.cost == 0)
        #expect(paths[source]?.predecessors == [])
    }

    @Test("the ladder river shortcut makes crossing at (7,1) cheaper (1) than going around")
    func ladderShortcutIsCheaper() throws {
        let withLadder = try #require(OverworldRoutingGraph.dynamicGraph(
            ladder: true, raft: false, recorderWarpDestinations: [], anyRoads: [],
            isMirror: false, canScreenScroll: false
        ))
        let source = OverworldVertex(7, 1, .east)
        let target = OverworldVertex(7, 1, .west)
        let paths = OverworldRoutingGraph.findAllBestPaths(adjacency: withLadder.adjacency, from: source, to: target)
        #expect(paths[target]?.cost == 1)
    }

    @Test("recorder warp destinations are reachable from anywhere at cost 7")
    func recorderWarpCost() throws {
        let destination = (x: 8, y: 6) // an arbitrary whole screen, per row-6 commonAdd coverage
        let graph = try #require(OverworldRoutingGraph.dynamicGraph(
            ladder: false, raft: true, recorderWarpDestinations: [destination], anyRoads: [],
            isMirror: false, canScreenScroll: false
        ))
        // Pick a source far from the destination so the direct warp is clearly
        // the best path, not a coincidentally-equal grid route.
        let source = OverworldVertex(0, 0, .full)
        let target = OverworldVertex(destination.x, destination.y, .full)
        let paths = OverworldRoutingGraph.findAllBestPaths(adjacency: graph.adjacency, from: source, to: target)
        #expect(paths[target]?.cost == 7)
    }

    @Test("any-road warps connect two marked any-roads at cost 4")
    func anyRoadWarpCost() throws {
        // Any-road canonical stair vertices are resolved via .stairs portion detail;
        // for two arbitrary marked any-road screens, the warp between them should
        // cost exactly 4 regardless of their grid distance.
        let roadA = (x: 4, y: 0)
        let roadB = (x: 14, y: 7)
        let graph = try #require(OverworldRoutingGraph.dynamicGraph(
            ladder: false, raft: true, recorderWarpDestinations: [], anyRoads: [roadA, roadB],
            isMirror: false, canScreenScroll: false
        ))
        guard
            let sourceVertex = OverworldRoutingGraph.canonicalVertex(x: roadA.x, y: roadA.y, screenTypes: graph.screenTypes, portionDetail: .stairs),
            let targetVertex = OverworldRoutingGraph.canonicalVertex(x: roadB.x, y: roadB.y, screenTypes: graph.screenTypes, portionDetail: .anyRoadArrival)
        else {
            Issue.record("expected both any-road screens to resolve to canonical vertices")
            return
        }
        let paths = OverworldRoutingGraph.findAllBestPaths(adjacency: graph.adjacency, from: sourceVertex, to: targetVertex)
        #expect(paths[targetVertex]?.cost == 4)
    }
}
