/// Which portion of an overworld screen a vertex represents. Most screens
/// are a single `.full` vertex; ~12 screens with narrow internal passages
/// (rivers, canyon walls) are split into two half-screen vertices. Ported
/// exactly from `OverworldScreenPortion`
/// (`Zelda1RandoTools/Z1R_Tracker/Z1R_Tracker/OverworldRouting.fs:16-21`).
public enum OverworldScreenPortion: Hashable, Sendable, Comparable, CaseIterable {
    case full
    case north
    case south
    case east
    case west

    /// Arbitrary but consistent ordering — exists only so `OverworldVertex`
    /// can be `Comparable` for deterministic priority-queue tie-breaking in
    /// `findAllBestPaths`. The order itself carries no meaning from the
    /// reference app (it doesn't order portions at all).
    public static func < (lhs: Self, rhs: Self) -> Bool {
        Self.allCases.firstIndex(of: lhs)! < Self.allCases.firstIndex(of: rhs)!
    }
}

/// A node in the overworld routing graph: an overworld screen (or half of
/// one). `(0,0)` is the upper-left screen (Death Mountain), matching the
/// reference app's own coordinate convention exactly
/// (`OverworldRouting.fs:23-24`).
public struct OverworldVertex: Hashable, Sendable, Comparable {
    public let x: Int
    public let y: Int
    public let portion: OverworldScreenPortion

    public init(_ x: Int, _ y: Int, _ portion: OverworldScreenPortion) {
        self.x = x
        self.y = y
        self.portion = portion
    }

    /// Lexicographic (x, y, portion) — exists only for deterministic
    /// priority-queue tie-breaking in `findAllBestPaths`, not a concept
    /// from the reference app.
    public static func < (lhs: OverworldVertex, rhs: OverworldVertex) -> Bool {
        if lhs.x != rhs.x { return lhs.x < rhs.x }
        if lhs.y != rhs.y { return lhs.y < rhs.y }
        return lhs.portion < rhs.portion
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
public struct OverworldScreenCoordinate: Hashable, Sendable, Codable {
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

extension OverworldRoutingGraph {
    /// Screen-scroll edges for a **mirrored** overworld (`docs/domain.md`
    /// § 4.1 "Mirror overworld" toggle). Ported directly, one line per
    /// `table.Add`, from `staticMirrorScreenScrolls`
    /// (`OverworldRouting.fs:210-232`). These are one-directional (unlike
    /// `symmetricAdd`) — reflecting that a screen-scroll transition is only
    /// "free" going one way in the reference app's model.
    public static let mirrorScreenScrollEdges: [OverworldAdjacencyEdge] = [
        // R -> L
        OverworldAdjacencyEdge(from: OverworldVertex(3, 0, .full), to: OverworldVertex(4, 0, .full), cost: 2),
        OverworldAdjacencyEdge(from: OverworldVertex(9, 0, .full), to: OverworldVertex(10, 0, .full), cost: 2),
        OverworldAdjacencyEdge(from: OverworldVertex(1, 1, .full), to: OverworldVertex(2, 1, .full), cost: 2),
        OverworldAdjacencyEdge(from: OverworldVertex(5, 2, .full), to: OverworldVertex(6, 2, .full), cost: 2),
        OverworldAdjacencyEdge(from: OverworldVertex(14, 2, .full), to: OverworldVertex(15, 2, .full), cost: 2),
        OverworldAdjacencyEdge(from: OverworldVertex(3, 3, .full), to: OverworldVertex(4, 3, .full), cost: 2),
        OverworldAdjacencyEdge(from: OverworldVertex(8, 3, .full), to: OverworldVertex(9, 3, .full), cost: 2),
        OverworldAdjacencyEdge(from: OverworldVertex(11, 3, .full), to: OverworldVertex(12, 3, .full), cost: 2),
        OverworldAdjacencyEdge(from: OverworldVertex(1, 4, .full), to: OverworldVertex(2, 4, .full), cost: 2),
        OverworldAdjacencyEdge(from: OverworldVertex(4, 7, .full), to: OverworldVertex(5, 7, .west), cost: 2),
        // cross rivers / coast splits
        OverworldAdjacencyEdge(from: OverworldVertex(7, 1, .east), to: OverworldVertex(7, 1, .west), cost: 2),
        OverworldAdjacencyEdge(from: OverworldVertex(7, 1, .west), to: OverworldVertex(7, 1, .east), cost: 2),
        OverworldAdjacencyEdge(from: OverworldVertex(7, 2, .east), to: OverworldVertex(7, 2, .west), cost: 2),
        OverworldAdjacencyEdge(from: OverworldVertex(7, 2, .west), to: OverworldVertex(7, 2, .east), cost: 2),
        OverworldAdjacencyEdge(from: OverworldVertex(5, 5, .east), to: OverworldVertex(5, 5, .west), cost: 2),
        OverworldAdjacencyEdge(from: OverworldVertex(5, 5, .west), to: OverworldVertex(5, 5, .east), cost: 2),
        OverworldAdjacencyEdge(from: OverworldVertex(13, 1, .east), to: OverworldVertex(13, 1, .west), cost: 2),
        OverworldAdjacencyEdge(from: OverworldVertex(13, 1, .west), to: OverworldVertex(13, 1, .east), cost: 2)
    ]

    /// Screen-scroll edges for a **normal** (non-mirrored) overworld. Ported
    /// directly from `staticNormalScreenScrolls` (`OverworldRouting.fs:233-258`).
    /// The reference source's commented-out "warp to start" edge and its
    /// explanatory comment are intentionally not ported — dead code in the
    /// source, not a contract this project needs to honor.
    public static let normalScreenScrollEdges: [OverworldAdjacencyEdge] = [
        // R -> L
        OverworldAdjacencyEdge(from: OverworldVertex(12, 0, .full), to: OverworldVertex(11, 0, .full), cost: 2),
        OverworldAdjacencyEdge(from: OverworldVertex(2, 1, .full), to: OverworldVertex(1, 1, .full), cost: 2),
        OverworldAdjacencyEdge(from: OverworldVertex(6, 2, .full), to: OverworldVertex(5, 2, .full), cost: 2),
        OverworldAdjacencyEdge(from: OverworldVertex(5, 3, .full), to: OverworldVertex(4, 3, .full), cost: 2),
        OverworldAdjacencyEdge(from: OverworldVertex(14, 3, .full), to: OverworldVertex(13, 3, .full), cost: 2),
        OverworldAdjacencyEdge(from: OverworldVertex(1, 5, .full), to: OverworldVertex(0, 5, .full), cost: 2),
        OverworldAdjacencyEdge(from: OverworldVertex(5, 7, .east), to: OverworldVertex(4, 7, .full), cost: 2),
        OverworldAdjacencyEdge(from: OverworldVertex(5, 7, .east), to: OverworldVertex(5, 7, .west), cost: 2),
        // cross rivers splits
        OverworldAdjacencyEdge(from: OverworldVertex(7, 1, .east), to: OverworldVertex(7, 1, .west), cost: 2),
        OverworldAdjacencyEdge(from: OverworldVertex(7, 1, .west), to: OverworldVertex(7, 1, .east), cost: 2),
        OverworldAdjacencyEdge(from: OverworldVertex(7, 2, .east), to: OverworldVertex(7, 2, .west), cost: 2),
        OverworldAdjacencyEdge(from: OverworldVertex(7, 2, .west), to: OverworldVertex(7, 2, .east), cost: 2),
        OverworldAdjacencyEdge(from: OverworldVertex(5, 5, .east), to: OverworldVertex(5, 5, .west), cost: 2),
        OverworldAdjacencyEdge(from: OverworldVertex(5, 5, .west), to: OverworldVertex(5, 5, .east), cost: 2),
        // cross coast split
        OverworldAdjacencyEdge(from: OverworldVertex(13, 1, .east), to: OverworldVertex(13, 1, .west), cost: 2),
        OverworldAdjacencyEdge(from: OverworldVertex(13, 1, .west), to: OverworldVertex(13, 1, .east), cost: 2)
    ]
}

/// Disambiguates which half of a split screen is meant, for screens
/// reachable multiple ways (a stairs/cave entrance vs. arriving via an any
/// road or the recorder-warp tornado). Ported from `PortionDetail`
/// (`OverworldRouting.fs:321-325`).
public enum OverworldPortionDetail: Sendable {
    case stairs
    case anyRoadArrival
    case tornadoArrival
}

extension OverworldRoutingGraph {
    /// Resolves a screen coordinate to its one canonical vertex, given which
    /// half matters for the situation (`portionDetail`). Ported exactly from
    /// `convertToCanonicalVertex` (`OverworldRouting.fs:326-350`), including
    /// its per-coordinate special cases (several marked "TODO check" in the
    /// reference source itself — transcribed as-is, not resolved or guessed
    /// at, since second-guessing an upstream TODO would be inventing a fact).
    /// Returns `nil` if the coordinate isn't in `screenTypes` at all
    /// (mirrors the reference's `failwith "impossible st"` — turned into an
    /// honest `nil` here since this is reachable from live tracker state).
    public static func canonicalVertex(
        x: Int,
        y: Int,
        screenTypes: [OverworldScreenCoordinate: OverworldScreenType],
        portionDetail: OverworldPortionDetail
    ) -> OverworldVertex? {
        guard let type = screenTypes[OverworldScreenCoordinate(x: x, y: y)] else { return nil }
        switch type {
        case .whole:
            return OverworldVertex(x, y, .full)
        case .northSouth:
            // "the only NS screen with a destination (2,7) has it all in the south"
            return OverworldVertex(x, y, .south)
        case .eastWest:
            let portion: OverworldScreenPortion
            switch (x, y, portionDetail) {
            case (3, 2, .tornadoArrival): portion = .east
            case (3, 2, _): portion = .west
            case (13, 1, .tornadoArrival): portion = .east
            case (13, 1, _): portion = .west
            case (13, 6, _): portion = .west // TODO check (ported from reference's own TODO)
            case (5, 7, .stairs): portion = .west
            case (5, 7, _): portion = .east // TODO check (ported from reference's own TODO)
            case (12, 6, .stairs): portion = .west
            case (12, 6, _): portion = .east // TODO check (ported from reference's own TODO)
            case (11, 4, .stairs): portion = .east
            case (11, 4, _): portion = .west
            case (2, 6, .stairs): portion = .east
            case (2, 6, _): portion = .west
            default: portion = .east
            }
            return OverworldVertex(x, y, portion)
        }
    }
}

/// The fully-assembled routing graph for a specific tracker state (item
/// possession + live marks), ready for pathfinding. Ported from
/// `populateDynamic`'s return value (`OverworldRouting.fs:351-378`).
public struct OverworldDynamicGraph: Sendable {
    public let screenTypes: [OverworldScreenCoordinate: OverworldScreenType]
    public let adjacency: [OverworldVertex: [(vertex: OverworldVertex, cost: Int)]]
}

extension OverworldRoutingGraph {
    /// Assembles the full graph (static + screen-scrolls + recorder-warp +
    /// any-road edges) for the given live state. Ported from
    /// `populateDynamic` (`OverworldRouting.fs:351-378`). Returns `nil` if
    /// the resulting edge set fails the screen-type consistency check
    /// (`screenTypes(from:)`) — mirrors the reference's own guard, turned
    /// into an honest `nil` rather than a crash.
    public static func dynamicGraph(
        ladder: Bool,
        raft: Bool,
        recorderWarpDestinations: [(x: Int, y: Int)],
        anyRoads: [(x: Int, y: Int)],
        isMirror: Bool,
        canScreenScroll: Bool
    ) -> OverworldDynamicGraph? {
        var edges: [OverworldAdjacencyEdge] = []

        if canScreenScroll {
            if isMirror {
                edges.append(contentsOf: mirrorScreenScrollEdges)
                if ladder {
                    edges.append(OverworldAdjacencyEdge(from: OverworldVertex(15, 4, .full), to: OverworldVertex(14, 4, .full), cost: 2))
                    edges.append(OverworldAdjacencyEdge(from: OverworldVertex(15, 5, .full), to: OverworldVertex(14, 5, .full), cost: 2))
                }
            } else {
                edges.append(contentsOf: normalScreenScrollEdges)
                if ladder {
                    edges.append(OverworldAdjacencyEdge(from: OverworldVertex(0, 6, .full), to: OverworldVertex(15, 5, .full), cost: 3)) // world wrap
                    edges.append(OverworldAdjacencyEdge(from: OverworldVertex(15, 4, .full), to: OverworldVertex(14, 4, .full), cost: 2))
                    edges.append(OverworldAdjacencyEdge(from: OverworldVertex(15, 5, .full), to: OverworldVertex(14, 5, .full), cost: 2))
                }
            }
        }
        edges.append(contentsOf: staticEdges(ladder: ladder, raft: raft))

        guard let screenTypes = screenTypes(from: edges) else { return nil }

        var allVertices: Set<OverworldVertex> = []
        for edge in edges {
            allVertices.insert(edge.from)
            allVertices.insert(edge.to)
        }

        func addExtra(sources: [OverworldVertex], destinations: [(x: Int, y: Int)], portionDetail: OverworldPortionDetail, cost: Int) {
            for destination in destinations {
                guard let canonicalDestination = canonicalVertex(x: destination.x, y: destination.y, screenTypes: screenTypes, portionDetail: portionDetail)
                else { continue }
                for source in sources {
                    edges.append(OverworldAdjacencyEdge(from: source, to: canonicalDestination, cost: cost))
                }
            }
        }
        // From anywhere, the recorder can warp to any whistleable (marked) dungeon.
        addExtra(sources: Array(allVertices), destinations: recorderWarpDestinations, portionDetail: .tornadoArrival, cost: 7)
        // Any marked any-road warps to any other marked any-road.
        let anyRoadSources = anyRoads.compactMap {
            canonicalVertex(x: $0.x, y: $0.y, screenTypes: screenTypes, portionDetail: .stairs)
        }
        addExtra(sources: anyRoadSources, destinations: anyRoads, portionDetail: .anyRoadArrival, cost: 4)

        var adjacency: [OverworldVertex: [(vertex: OverworldVertex, cost: Int)]] = [:]
        for edge in edges {
            adjacency[edge.from, default: []].append((edge.to, edge.cost))
        }
        return OverworldDynamicGraph(screenTypes: screenTypes, adjacency: adjacency)
    }
}

/// One entry in `findAllBestPaths`'s result: the best (minimum) cost to
/// reach a vertex, and every immediate predecessor that achieves that best
/// cost (there can be more than one — that's the "all" in the name).
public struct OverworldPathInfo: Sendable, Equatable {
    public let cost: Int
    public let predecessors: [OverworldVertex]
}

extension OverworldRoutingGraph {
    /// Breadth-first, minimum-cost search from `source`, recording every
    /// vertex's best cost and *every* predecessor that achieves it (not
    /// just one arbitrary shortest path) — this is what lets the reference
    /// app's UI show all equally-good routes, not an arbitrary single one.
    /// Ported structurally from `findAllBestPaths` (`OverworldRouting.fs:415-465`),
    /// including its early-stop condition (`bestCost` once the target is
    /// reached) and its equal-cost tie accumulation. The reference's F#
    /// `Set`-backed priority queue naturally deduplicates identical
    /// (cost, vertex, predecessor) entries before they're processed —
    /// replicated here via `OverworldPriorityQueueEntry: Hashable` backed
    /// by a `Set`, not a plain array, to preserve that exact behavior
    /// (skipping it would let a duplicate predecessor slip into the result).
    public static func findAllBestPaths(
        adjacency: [OverworldVertex: [(vertex: OverworldVertex, cost: Int)]],
        from source: OverworldVertex,
        to target: OverworldVertex
    ) -> [OverworldVertex: OverworldPathInfo] {
        var visited: [OverworldVertex: OverworldPathInfo] = [:]
        var queue: Set<OverworldPriorityQueueEntry> = [OverworldPriorityQueueEntry(cost: 0, vertex: source, predecessor: nil)]
        var bestCost = Int.max

        while let minCost = queue.map(\.cost).min(), minCost <= bestCost {
            // Dequeue the minimum entry. Tie-break is an arbitrary but
            // deterministic total order (see OverworldVertex/OverworldPortion's
            // Comparable conformances) -- which entry wins a tie among equal
            // (cost, vertex) never changes the final `visited` result, only
            // the order intermediate work happens in, so this doesn't need to
            // match the reference's exact structural-comparison tie-break.
            let entry = queue.min(by: { lhs, rhs in
                if lhs.cost != rhs.cost { return lhs.cost < rhs.cost }
                if lhs.vertex != rhs.vertex { return lhs.vertex < rhs.vertex }
                switch (lhs.predecessor, rhs.predecessor) {
                case (nil, nil): return false
                case (nil, _): return true
                case (_, nil): return false
                case let (l?, r?): return l < r
                }
            })!
            queue.remove(entry)

            let cost = entry.cost
            let current = entry.vertex
            let predecessor = entry.predecessor

            if current == target, cost < bestCost {
                bestCost = cost
            }

            if let existing = visited[current] {
                if existing.cost < cost {
                    // Already have a strictly better path here -- discard this entry.
                    continue
                } else if cost < existing.cost {
                    // This entry is strictly better than what we'd recorded -- replace.
                    visited.removeValue(forKey: current)
                    visited[current] = OverworldPathInfo(cost: cost, predecessors: predecessor.map { [$0] } ?? [])
                    if let neighbors = adjacency[current] {
                        for neighbor in neighbors {
                            queue.insert(OverworldPriorityQueueEntry(cost: cost + neighbor.cost, vertex: neighbor.vertex, predecessor: current))
                        }
                    }
                } else {
                    // Equal cost -- another optimal predecessor; accumulate it.
                    // `predecessor` is non-nil here: the only nil-predecessor entry is the
                    // source's own initial enqueue, which is always the very first vertex
                    // visited (at cost 0, before any tie is possible).
                    guard let thisPredecessor = predecessor else { continue }
                    visited[current] = OverworldPathInfo(cost: existing.cost, predecessors: [thisPredecessor] + existing.predecessors)
                }
            } else {
                visited[current] = OverworldPathInfo(cost: cost, predecessors: predecessor.map { [$0] } ?? [])
                if let neighbors = adjacency[current] {
                    for neighbor in neighbors {
                        queue.insert(OverworldPriorityQueueEntry(cost: cost + neighbor.cost, vertex: neighbor.vertex, predecessor: current))
                    }
                }
            }
        }
        return visited
    }
}

/// One entry in `findAllBestPaths`'s internal priority queue. `Hashable` so
/// duplicate `(cost, vertex, predecessor)` entries collapse naturally when
/// stored in a `Set`, matching the reference app's `Set`-backed priority
/// queue exactly (see `findAllBestPaths`'s doc comment for why this matters).
private struct OverworldPriorityQueueEntry: Hashable {
    let cost: Int
    let vertex: OverworldVertex
    let predecessor: OverworldVertex?
}
