/// Which portion of an overworld screen a vertex represents. Most screens
/// are a single `.full` vertex; ~12 screens with narrow internal passages
/// (rivers, canyon walls) are split into two half-screen vertices. Ported
/// exactly from `OverworldScreenPortion`
/// (`Zelda1RandoTools/Z1R_Tracker/Z1R_Tracker/OverworldRouting.fs:16-21`).
public enum OverworldScreenPortion: Hashable, Sendable {
    case full
    case north
    case south
    case east
    case west
}

/// A node in the overworld routing graph: an overworld screen (or half of
/// one). `(0,0)` is the upper-left screen (Death Mountain), matching the
/// reference app's own coordinate convention exactly
/// (`OverworldRouting.fs:23-24`).
public struct OverworldVertex: Hashable, Sendable {
    public let x: Int
    public let y: Int
    public let portion: OverworldScreenPortion

    public init(_ x: Int, _ y: Int, _ portion: OverworldScreenPortion) {
        self.x = x
        self.y = y
        self.portion = portion
    }
}

/// One traversal edge in the routing graph: moving from `from` to `to`
/// costs `cost` (screen-scroll units — 2 for a normal adjacent screen, more
/// for warps/detours, less for shortcuts like the ladder-crossed river).
public struct OverworldAdjacencyEdge: Sendable {
    public let from: OverworldVertex
    public let to: OverworldVertex
    public let cost: Int

    public init(from: OverworldVertex, to: OverworldVertex, cost: Int) {
        self.from = from
        self.to = to
        self.cost = cost
    }
}

/// The overworld routing graph's **static** layer (T-009) — the fixed
/// screen-to-screen adjacencies that don't depend on live tracker state
/// (recorder warp destinations, marked any-roads, mirror/screen-scroll
/// settings — those are the **dynamic** layer, `populateDynamic` in the
/// reference app, not yet ported, see `tasks/T-009.md` "Out of scope").
///
/// Ported edge-for-edge from `populateStaticOverworldData`
/// (`OverworldRouting.fs:26-209`) — every call in this type mirrors one
/// line of that function in the same order, so a future diff against the
/// reference source stays easy. Grounded, not summarized: this is not a
/// simplified approximation of the graph, it is the graph.
public enum OverworldRoutingGraph {
    /// All static edges for the given item state. `ladder`/`raft` gate a
    /// handful of conditional crossings (`OverworldRouting.fs:198-209`).
    public static func staticEdges(ladder: Bool, raft: Bool) -> [OverworldAdjacencyEdge] {
        var edges: [OverworldAdjacencyEdge] = []

        func symmetricAdd(_ f: OverworldVertex, _ t: OverworldVertex, _ c: Int) {
            edges.append(OverworldAdjacencyEdge(from: f, to: t, cost: c))
            edges.append(OverworldAdjacencyEdge(from: t, to: f, cost: c))
        }
        func add(_ f: OverworldVertex, _ t: OverworldVertex, _ c: Int) {
            edges.append(OverworldAdjacencyEdge(from: f, to: t, cost: c))
        }
        func commonAddRight(_ x: Int, _ y: Int) {
            symmetricAdd(OverworldVertex(x, y, .full), OverworldVertex(x + 1, y, .full), 2)
        }
        func commonAddDown(_ x: Int, _ y: Int) {
            symmetricAdd(OverworldVertex(x, y, .full), OverworldVertex(x, y + 1, .full), 2)
        }
        func commonAddRightAndDown(_ x: Int, _ y: Int) {
            commonAddRight(x, y)
            commonAddDown(x, y)
        }

        commonAddRightAndDown(0, 0)
        commonAddRightAndDown(1, 0)
        commonAddRightAndDown(2, 0)
        commonAddDown(3, 0)
        commonAddRight(4, 0)
        commonAddRight(5, 0)
        commonAddRight(6, 0)
        commonAddRight(7, 0)
        commonAddRight(8, 0)
        commonAddDown(10, 0)
        commonAddRightAndDown(12, 0)
        commonAddDown(14, 0)
        commonAddDown(15, 0)
        commonAddRight(0, 1)
        commonAddRight(2, 1)
        commonAddRight(3, 1)
        commonAddRightAndDown(4, 1)
        commonAddRightAndDown(5, 1)
        commonAddRight(8, 1)
        commonAddRight(9, 1)
        commonAddRight(10, 1)
        commonAddDown(12, 1)
        commonAddRight(14, 1)
        commonAddRightAndDown(0, 2)
        commonAddDown(1, 2)
        commonAddDown(2, 2)
        commonAddRight(4, 2)
        commonAddDown(5, 2)
        commonAddDown(6, 2)
        commonAddRightAndDown(8, 2)
        commonAddRight(9, 2)
        commonAddRightAndDown(10, 2)
        commonAddRightAndDown(11, 2)
        commonAddRight(12, 2)
        commonAddRightAndDown(13, 2)
        commonAddDown(14, 2)
        commonAddRightAndDown(0, 3)
        commonAddRightAndDown(1, 3)
        commonAddRight(2, 3)
        commonAddDown(4, 3)
        commonAddRight(5, 3)
        commonAddRight(7, 3)
        commonAddDown(8, 3)
        commonAddDown(9, 3)
        commonAddRightAndDown(10, 3)
        commonAddDown(12, 3)
        commonAddDown(13, 3)
        commonAddRight(14, 3)
        commonAddDown(15, 3)
        commonAddRightAndDown(0, 4)
        commonAddDown(2, 4)
        commonAddDown(3, 4)
        commonAddDown(4, 4)
        commonAddRightAndDown(6, 4)
        commonAddRight(7, 4)
        commonAddDown(8, 4)
        commonAddRightAndDown(9, 4)
        commonAddRight(12, 4)
        commonAddRightAndDown(13, 4)
        commonAddDown(15, 4)
        commonAddDown(0, 5)
        commonAddRight(1, 5)
        commonAddRight(2, 5)
        commonAddRightAndDown(3, 5)
        commonAddDown(4, 5)
        commonAddRight(6, 5)
        commonAddRight(7, 5)
        commonAddRightAndDown(8, 5)
        commonAddRightAndDown(9, 5)
        commonAddRightAndDown(10, 5)
        commonAddDown(11, 5)
        commonAddRight(13, 5)
        commonAddDown(15, 5)
        commonAddRightAndDown(3, 6)
        commonAddRight(4, 6)
        commonAddRight(5, 6)
        commonAddRightAndDown(6, 6)
        commonAddRightAndDown(7, 6)
        commonAddRightAndDown(8, 6)
        commonAddRight(9, 6)
        commonAddRight(10, 6)
        commonAddDown(11, 6)
        commonAddRight(14, 6)
        commonAddDown(15, 6)
        commonAddRight(0, 7)
        commonAddRight(3, 7)
        commonAddRight(6, 7)
        commonAddRight(7, 7)
        commonAddRight(8, 7)
        commonAddRight(9, 7)
        commonAddRight(10, 7)
        commonAddRight(11, 7)
        commonAddRight(12, 7)
        commonAddRight(13, 7)
        commonAddRight(14, 7)

        // 3,2 is an EW portion
        symmetricAdd(OverworldVertex(3, 2, .west), OverworldVertex(3, 3, .full), 2)
        symmetricAdd(OverworldVertex(3, 2, .east), OverworldVertex(3, 3, .full), 2)
        symmetricAdd(OverworldVertex(3, 2, .east), OverworldVertex(4, 2, .full), 2)
        // 7,1 is an EW portion
        symmetricAdd(OverworldVertex(7, 1, .west), OverworldVertex(7, 0, .full), 2)
        symmetricAdd(OverworldVertex(7, 1, .west), OverworldVertex(6, 1, .full), 2)
        symmetricAdd(OverworldVertex(7, 1, .east), OverworldVertex(8, 1, .full), 2)
        symmetricAdd(OverworldVertex(7, 1, .east), OverworldVertex(7, 2, .east), 2)
        // 7,2 is an EW portion
        symmetricAdd(OverworldVertex(7, 2, .west), OverworldVertex(6, 2, .full), 2)
        symmetricAdd(OverworldVertex(7, 2, .east), OverworldVertex(8, 2, .full), 2)
        // 13,1 is an EW portion
        symmetricAdd(OverworldVertex(13, 1, .west), OverworldVertex(12, 1, .full), 2)
        symmetricAdd(OverworldVertex(13, 1, .west), OverworldVertex(13, 2, .full), 2)
        symmetricAdd(OverworldVertex(13, 1, .east), OverworldVertex(13, 0, .full), 2)
        symmetricAdd(OverworldVertex(13, 1, .east), OverworldVertex(14, 1, .full), 2)
        symmetricAdd(OverworldVertex(13, 1, .east), OverworldVertex(13, 2, .full), 2)
        // 11,4 is an EW portion
        symmetricAdd(OverworldVertex(11, 4, .west), OverworldVertex(10, 4, .full), 2)
        symmetricAdd(OverworldVertex(11, 4, .west), OverworldVertex(11, 5, .full), 2)
        symmetricAdd(OverworldVertex(11, 4, .east), OverworldVertex(11, 3, .full), 2)
        symmetricAdd(OverworldVertex(11, 4, .east), OverworldVertex(11, 5, .full), 2)
        // 2,6 is an EW portion
        symmetricAdd(OverworldVertex(2, 6, .west), OverworldVertex(1, 6, .full), 2)
        symmetricAdd(OverworldVertex(2, 6, .west), OverworldVertex(2, 5, .full), 2)
        symmetricAdd(OverworldVertex(2, 6, .east), OverworldVertex(3, 6, .full), 2)
        symmetricAdd(OverworldVertex(2, 6, .east), OverworldVertex(2, 5, .full), 2)
        // 2,7 is a "NW portion" per the reference source's own comment (its actual
        // portions used are north/south, not north/west -- transcribed faithfully
        // as-is, not corrected, since this is a direct port of the source comment).
        symmetricAdd(OverworldVertex(2, 7, .north), OverworldVertex(2, 6, .west), 2)
        symmetricAdd(OverworldVertex(2, 7, .north), OverworldVertex(3, 7, .full), 2)
        symmetricAdd(OverworldVertex(2, 7, .south), OverworldVertex(1, 7, .full), 2)
        symmetricAdd(OverworldVertex(2, 7, .south), OverworldVertex(3, 7, .full), 2)
        // 5,5 is an EW portion
        symmetricAdd(OverworldVertex(5, 5, .west), OverworldVertex(4, 5, .full), 2)
        symmetricAdd(OverworldVertex(5, 5, .west), OverworldVertex(5, 6, .full), 2)
        symmetricAdd(OverworldVertex(5, 5, .east), OverworldVertex(6, 5, .full), 2)
        symmetricAdd(OverworldVertex(5, 5, .east), OverworldVertex(5, 6, .full), 2)
        // 5,7 is an EW portion
        symmetricAdd(OverworldVertex(5, 7, .west), OverworldVertex(5, 6, .full), 2)
        symmetricAdd(OverworldVertex(5, 7, .east), OverworldVertex(6, 7, .full), 2)
        // 12,5 is a NS portion and 12,6 is an EW portion
        symmetricAdd(OverworldVertex(11, 5, .full), OverworldVertex(12, 5, .north), 2)
        symmetricAdd(OverworldVertex(11, 5, .full), OverworldVertex(12, 5, .south), 2)
        symmetricAdd(OverworldVertex(13, 5, .full), OverworldVertex(12, 5, .north), 2)
        symmetricAdd(OverworldVertex(12, 6, .west), OverworldVertex(11, 6, .full), 2)
        symmetricAdd(OverworldVertex(12, 6, .west), OverworldVertex(12, 5, .south), 2)
        symmetricAdd(OverworldVertex(12, 6, .east), OverworldVertex(13, 6, .west), 2)
        symmetricAdd(OverworldVertex(12, 6, .east), OverworldVertex(12, 5, .north), 2)
        // 13,6 is an EW portion
        symmetricAdd(OverworldVertex(13, 5, .full), OverworldVertex(13, 6, .west), 2)
        symmetricAdd(OverworldVertex(13, 6, .east), OverworldVertex(14, 6, .full), 2)
        symmetricAdd(OverworldVertex(13, 6, .east), OverworldVertex(13, 5, .full), 2)

        // static asymmetries (NOT symmetricAdd -- these are genuinely one-directional)
        // Lost Woods: walking right is free, but wandering back left without the
        // correct sequence costs much more (models "you get lost and looped back").
        add(OverworldVertex(0, 6, .full), OverworldVertex(1, 6, .full), 2)
        add(OverworldVertex(1, 6, .full), OverworldVertex(0, 6, .full), 8)
        add(OverworldVertex(1, 5, .full), OverworldVertex(1, 6, .full), 2)
        add(OverworldVertex(1, 7, .full), OverworldVertex(1, 6, .full), 2)
        // Lost Hills: same shape as Lost Woods.
        add(OverworldVertex(11, 0, .full), OverworldVertex(11, 1, .full), 2)
        add(OverworldVertex(11, 1, .full), OverworldVertex(11, 0, .full), 8)
        add(OverworldVertex(12, 1, .full), OverworldVertex(11, 1, .full), 2)

        // conditional state
        if ladder {
            symmetricAdd(OverworldVertex(7, 1, .east), OverworldVertex(7, 1, .west), 1)
            symmetricAdd(OverworldVertex(7, 2, .east), OverworldVertex(7, 2, .west), 1)
        }
        if raft {
            symmetricAdd(OverworldVertex(15, 2, .full), OverworldVertex(15, 3, .full), 2)
            symmetricAdd(OverworldVertex(5, 4, .full), OverworldVertex(5, 5, .east), 2)
        } else {
            // Reference app's own comment: "we want every vertex in the table, so
            // add dummy edge from raft spot to itself" -- ensures these screens are
            // still present as graph vertices even without the raft.
            symmetricAdd(OverworldVertex(15, 2, .full), OverworldVertex(15, 2, .full), 1)
            symmetricAdd(OverworldVertex(5, 4, .full), OverworldVertex(5, 4, .full), 1)
        }

        return edges
    }
}

/// An overworld screen coordinate, independent of which portion(s) of it
/// are modeled as separate vertices.
public struct OverworldScreenCoordinate: Hashable, Sendable {
    public let x: Int
    public let y: Int

    public init(x: Int, y: Int) {
        self.x = x
        self.y = y
    }
}

/// Whether a screen is one full vertex, split north/south, or split
/// east/west in the routing graph. Ported from `ScreenType`
/// (`OverworldRouting.fs:283-286`).
public enum OverworldScreenType: Sendable {
    case whole
    case northSouth
    case eastWest
}

extension OverworldRoutingGraph {
    /// Derives each screen's `OverworldScreenType` from a set of edges and
    /// validates that every screen's vertices agree on a single type — e.g.
    /// a screen can't have both a `.full` vertex and an `.east` vertex.
    /// Returns `nil` on any mismatch, mirroring the reference app's own
    /// `failwith "mismatch"` guard in `generateScreenTypeListImpl`
    /// (`OverworldRouting.fs:287-307`) — a thrown exception there becomes an
    /// honest "couldn't compute" `nil` here rather than a Swift `fatalError`,
    /// since this is reachable from live tracker state, not just at startup.
    public static func screenTypes(
        from edges: [OverworldAdjacencyEdge]
    ) -> [OverworldScreenCoordinate: OverworldScreenType]? {
        var result: [OverworldScreenCoordinate: OverworldScreenType] = [:]

        func typeFor(_ portion: OverworldScreenPortion) -> OverworldScreenType {
            switch portion {
            case .full: .whole
            case .north, .south: .northSouth
            case .east, .west: .eastWest
            }
        }

        func agrees(_ existing: OverworldScreenType, with portion: OverworldScreenPortion) -> Bool {
            switch (existing, portion) {
            case (.whole, .full): true
            case (.northSouth, .north), (.northSouth, .south): true
            case (.eastWest, .east), (.eastWest, .west): true
            default: false
            }
        }

        func tryAdd(_ vertex: OverworldVertex) -> Bool {
            let coordinate = OverworldScreenCoordinate(x: vertex.x, y: vertex.y)
            if let existing = result[coordinate] {
                return agrees(existing, with: vertex.portion)
            } else {
                result[coordinate] = typeFor(vertex.portion)
                return true
            }
        }

        for edge in edges {
            guard tryAdd(edge.from), tryAdd(edge.to) else { return nil }
        }
        return result
    }
}
