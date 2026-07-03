/// One overworld screen selected as a route destination, and whether it's
/// among the cheapest (`isBold`) or merely nearby (`!isBold`) — mirrors the
/// reference app's bold/pale highlight distinction (`OverworldRouteDrawing.fs`'s
/// `drawPathsImpl`), minus true GYR's red/yellow accessibility distinctions,
/// which require the item/dungeon state layer tracked as `T-012` (see
/// `docs/domain.md` § 6).
public struct OverworldRouteHighlightEntry: Hashable, Sendable {
    public let coordinate: OverworldScreenCoordinate
    public let isBold: Bool

    public init(coordinate: OverworldScreenCoordinate, isBold: Bool) {
        self.coordinate = coordinate
        self.isBold = isBold
    }
}

/// One segment of a route line between two adjacent vertices, with the total
/// path cost to the destination end of the chain (used by the UI layer to
/// fade the line's opacity — farther destinations draw fainter).
public struct OverworldRouteLineSegment: Hashable, Sendable {
    public let from: OverworldVertex
    public let to: OverworldVertex
    public let cost: Int

    public init(from: OverworldVertex, to: OverworldVertex, cost: Int) {
        self.from = from
        self.to = to
        self.cost = cost
    }
}

/// The full result of hovering one overworld screen: which nearby unmarked
/// screens to highlight, and the route-line segments connecting them back to
/// the hovered screen.
public struct OverworldRouteHighlight: Sendable, Equatable {
    public let highlightedTiles: [OverworldRouteHighlightEntry]
    public let lines: [OverworldRouteLineSegment]

    public init(highlightedTiles: [OverworldRouteHighlightEntry], lines: [OverworldRouteLineSegment]) {
        self.highlightedTiles = highlightedTiles
        self.lines = lines
    }
}

extension OverworldRoutingGraph {
    /// Computes the hover-triggered route highlight and route lines from
    /// `source`, ported structurally from `drawPathsImpl`
    /// (`Z1R_Avalonia/OverworldRouteDrawing.fs:30-153`), with two deliberate,
    /// documented simplifications for this task's minimal-slice scope
    /// (`tasks/T-011.md`):
    ///
    /// 1. **Destination set.** The reference distinguishes "routeworthy"
    ///    (draw a route line to it) from "unmarked" (also rank it for
    ///    bold/pale highlighting) using `TrackerModel.mapStateSummary`'s
    ///    gettable-location logic, which requires the item/dungeon state
    ///    layer (`T-012`). Here both are simply "currently unmarked" —
    ///    correct given only the state that exists today, not a stand-in for
    ///    the real logic.
    /// 2. **Warp-edge line styling.** The reference distinguishes solid
    ///    (normal walk), dashed (non-walkable any-road/recorder warp), and
    ///    skipped (recorder-warp destination — "patently obvious, don't
    ///    clutter") line styles by checking `recorderDests`/`anyRoads`. This
    ///    task always calls `dynamicGraph` with empty
    ///    `recorderWarpDestinations`/`anyRoads` (no live state to source
    ///    them from yet — see `docs/domain.md` § 6), so no warp edges exist
    ///    in `adjacency` at all and every line is a normal solid walk; the
    ///    style distinction is reinstated in `T-012` once real warp
    ///    destinations are wired in.
    public static func routeHighlight(
        from source: OverworldVertex,
        unmarkedScreens: Set<OverworldScreenCoordinate>,
        screenTypes: [OverworldScreenCoordinate: OverworldScreenType],
        adjacency: [OverworldVertex: [(vertex: OverworldVertex, cost: Int)]],
        maxBold: Int,
        maxPale: Int
    ) -> OverworldRouteHighlight {
        // A non-existent goal makes findAllBestPaths map every reachable
        // vertex instead of stopping at one target -- ported from the
        // reference's own "non-existent goal will map all reachable
        // locations" comment.
        let sentinelGoal = OverworldVertex(-1, -1, .full)
        let paths = findAllBestPaths(adjacency: adjacency, from: source, to: sentinelGoal)

        var visited: Set<OverworldVertex> = []
        var lines: [OverworldRouteLineSegment] = []
        func draw(_ vertex: OverworldVertex) {
            guard visited.insert(vertex).inserted, let info = paths[vertex] else { return }
            for predecessor in info.predecessors {
                lines.append(OverworldRouteLineSegment(from: vertex, to: predecessor, cost: info.cost))
                draw(predecessor)
            }
        }

        var candidates: [(coordinate: OverworldScreenCoordinate, cost: Int)] = []
        for coordinate in unmarkedScreens.sorted(by: { ($0.x, $0.y) < ($1.x, $1.y) }) {
            guard let goal = canonicalVertex(x: coordinate.x, y: coordinate.y, screenTypes: screenTypes, portionDetail: .stairs) else { continue }
            draw(goal)
            if let info = paths[goal] {
                candidates.append((coordinate, info.cost))
            }
        }
        candidates.sort { $0.cost < $1.cost }

        return OverworldRouteHighlight(
            highlightedTiles: selectHighlights(sortedCandidates: candidates, maxBold: maxBold, maxPale: maxPale),
            lines: lines
        )
    }

    /// Ported from the bold/pale selection loop in `drawPathsImpl`
    /// (`Z1R_Avalonia/OverworldRouteDrawing.fs:109-126`): highlight the
    /// cheapest `maxBold` candidates bold (extending past `maxBold` to cover
    /// any tie at the cutoff cost, so equally-good destinations aren't
    /// arbitrarily split), then the next `maxPale` pale, then stop.
    private static func selectHighlights(
        sortedCandidates: [(coordinate: OverworldScreenCoordinate, cost: Int)],
        maxBold: Int,
        maxPale: Int
    ) -> [OverworldRouteHighlightEntry] {
        guard maxBold + maxPale > 0, let first = sortedCandidates.first else { return [] }

        var result = [OverworldRouteHighlightEntry(coordinate: first.coordinate, isBold: maxBold > 0)]
        var remaining = maxBold - 1
        var recentCost = first.cost

        for candidate in sortedCandidates.dropFirst() {
            if remaining > 0 || candidate.cost == recentCost {
                result.append(OverworldRouteHighlightEntry(coordinate: candidate.coordinate, isBold: true))
                recentCost = candidate.cost
            } else if remaining > -maxPale {
                result.append(OverworldRouteHighlightEntry(coordinate: candidate.coordinate, isBold: false))
                recentCost = Int.max
            } else {
                break
            }
            remaining -= 1
        }
        return result
    }
}
