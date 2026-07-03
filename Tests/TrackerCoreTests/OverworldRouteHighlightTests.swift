import Testing
@testable import TrackerCore

@Suite("OverworldRoutingGraph.routeHighlight")
struct OverworldRouteHighlightTests {
    private func graph() throws -> OverworldDynamicGraph {
        try #require(OverworldRoutingGraph.dynamicGraph(
            ladder: true, raft: true, recorderWarpDestinations: [], anyRoads: [],
            isMirror: false, canScreenScroll: false
        ))
    }

    @Test("bold-highlights the single cheapest destination, pale-highlights the next, with correct route lines")
    func basicBoldAndPale() throws {
        let g = try graph()
        let source = OverworldVertex(0, 0, .full)
        let unmarked: Set<OverworldScreenCoordinate> = [
            OverworldScreenCoordinate(x: 1, y: 0),
            OverworldScreenCoordinate(x: 2, y: 0)
        ]
        let result = OverworldRoutingGraph.routeHighlight(
            from: source, unmarkedScreens: unmarked, screenTypes: g.screenTypes, adjacency: g.adjacency,
            maxBold: 1, maxPale: 1
        )

        #expect(result.highlightedTiles == [
            OverworldRouteHighlightEntry(coordinate: OverworldScreenCoordinate(x: 1, y: 0), isBold: true),
            OverworldRouteHighlightEntry(coordinate: OverworldScreenCoordinate(x: 2, y: 0), isBold: false)
        ])

        let expectedLines: Set<OverworldRouteLineSegment> = [
            OverworldRouteLineSegment(from: OverworldVertex(1, 0, .full), to: OverworldVertex(0, 0, .full), cost: 2),
            OverworldRouteLineSegment(from: OverworldVertex(2, 0, .full), to: OverworldVertex(1, 0, .full), cost: 4)
        ]
        #expect(Set(result.lines) == expectedLines)
    }

    @Test("a tie at the cutoff cost extends bold highlighting past maxBold")
    func tieExtendsBoldHighlight() throws {
        let g = try graph()
        let source = OverworldVertex(0, 0, .full)
        let unmarked: Set<OverworldScreenCoordinate> = [
            OverworldScreenCoordinate(x: 1, y: 0), // cost 2
            OverworldScreenCoordinate(x: 0, y: 1)  // cost 2, tied
        ]
        let result = OverworldRoutingGraph.routeHighlight(
            from: source, unmarkedScreens: unmarked, screenTypes: g.screenTypes, adjacency: g.adjacency,
            maxBold: 1, maxPale: 0
        )

        #expect(result.highlightedTiles.count == 2)
        #expect(result.highlightedTiles.allSatisfy { $0.isBold })
        #expect(Set(result.highlightedTiles.map(\.coordinate)) == unmarked)
    }

    @Test("maxBold and maxPale both zero yields no highlights, but route lines are still computed")
    func zeroBudgetYieldsNoHighlights() throws {
        let g = try graph()
        let source = OverworldVertex(0, 0, .full)
        let unmarked: Set<OverworldScreenCoordinate> = [OverworldScreenCoordinate(x: 1, y: 0)]
        let result = OverworldRoutingGraph.routeHighlight(
            from: source, unmarkedScreens: unmarked, screenTypes: g.screenTypes, adjacency: g.adjacency,
            maxBold: 0, maxPale: 0
        )

        #expect(result.highlightedTiles.isEmpty)
        #expect(!result.lines.isEmpty)
    }

    @Test("no unmarked screens yields no highlights and no lines")
    func noUnmarkedScreensYieldsEmpty() throws {
        let g = try graph()
        let source = OverworldVertex(0, 0, .full)
        let result = OverworldRoutingGraph.routeHighlight(
            from: source, unmarkedScreens: [], screenTypes: g.screenTypes, adjacency: g.adjacency,
            maxBold: 5, maxPale: 5
        )

        #expect(result.highlightedTiles.isEmpty)
        #expect(result.lines.isEmpty)
    }

    @Test("a destination unreachable from source (not in screenTypes) is silently skipped, not crashed on")
    func unresolvableDestinationIsSkipped() throws {
        let g = try graph()
        let source = OverworldVertex(0, 0, .full)
        let unmarked: Set<OverworldScreenCoordinate> = [
            OverworldScreenCoordinate(x: 1, y: 0),
            OverworldScreenCoordinate(x: 99, y: 99) // not a real screen
        ]
        let result = OverworldRoutingGraph.routeHighlight(
            from: source, unmarkedScreens: unmarked, screenTypes: g.screenTypes, adjacency: g.adjacency,
            maxBold: 5, maxPale: 5
        )

        #expect(result.highlightedTiles == [
            OverworldRouteHighlightEntry(coordinate: OverworldScreenCoordinate(x: 1, y: 0), isBold: true)
        ])
    }
}
