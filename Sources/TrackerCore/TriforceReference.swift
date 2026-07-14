/// The Hidden-Dungeon-Numbers triforce reference layout (T-050) — which dungeon
/// number sits in each of the 8 triforce-piece positions, for First-Quest/Shapes
/// vs Second-Quest dungeons. Ported exactly from the reference's
/// `DrawTriforceMapCore` (`Z1R_WPF/Dungeon.fs:248-309`): position `i` shows
/// `ordering[i]`, drawn at `positions[i]` (in TRIFORCE-size units on a 4×2 grid).
///
/// Newer runners rely on this to identify which dungeon is which — and, via the
/// number, whether a dungeon is a two- or three-item dungeon.
public enum TriforceReference {
    /// Position → dungeon digit for First-Quest / Shapes dungeons.
    public static let firstQuest = "12345678"
    /// Position → dungeon digit for Second-Quest dungeons. In *Mixed* quest, 7
    /// and 8 may be swapped (hence the reference's on-screen caveat).
    public static let secondQuest = "13254687"

    /// The (x, y) center of each of the 8 positions, in TRIFORCE-size units:
    /// the canvas is 4 units wide × 2 tall, apex at top. Transcribed from
    /// `labelLocations` (`Dungeon.fs:274-283`).
    public static let positions: [(x: Double, y: Double)] = [
        (1.5, 0.5), // pos 0 — top-left
        (2.0, 0.5), // pos 1 — top-right
        (0.5, 1.5), // pos 2 — bottom far-left
        (3.0, 1.5), // pos 3 — bottom far-right
        (1.5, 1.0), // pos 4 — middle-left
        (1.0, 1.5), // pos 5 — bottom center-left
        (2.0, 1.0), // pos 6 — middle-right
        (2.5, 1.5), // pos 7 — bottom center-right
    ]

    /// The outer triangle vertices (apex, bottom-left, bottom-right) in the same
    /// units, for drawing the triforce outline.
    public static let outerTriangle: [(x: Double, y: Double)] = [
        (2.0, 0.0), (0.0, 2.0), (4.0, 2.0),
    ]

    /// The 9 grid points `p1…p9` the triforce sub-triangles are built from
    /// (`Dungeon.fs:251-261`), in TRIFORCE-size units:
    /// `p1`(apex), `p2 p3 p4`(mid row), `p5 p6 p7 p8 p9`(base row).
    public static let gridPoints: [(x: Double, y: Double)] = [
        (2, 0),                       // p1
        (1, 1), (2, 1), (3, 1),       // p2 p3 p4
        (0, 2), (1, 2), (2, 2), (3, 2), (4, 2), // p5 p6 p7 p8 p9
    ]

    /// Each of the 8 positions' sub-triangle, as indices into `gridPoints`.
    /// Transcribed from the `triforces` polygons (`Dungeon.fs:264-273`).
    public static let triangles: [[Int]] = [
        [0, 1, 2], // pos 0 — p1 p2 p3
        [0, 2, 3], // pos 1 — p1 p3 p4
        [1, 4, 5], // pos 2 — p2 p5 p6
        [3, 7, 8], // pos 3 — p4 p8 p9
        [1, 2, 6], // pos 4 — p2 p3 p7
        [1, 5, 6], // pos 5 — p2 p6 p7
        [2, 3, 6], // pos 6 — p3 p4 p7
        [3, 6, 7], // pos 7 — p4 p7 p8
    ]

    /// The centroid of position `i`'s sub-triangle (where its number is drawn).
    public static func centroid(_ i: Int) -> (x: Double, y: Double) {
        let pts = triangles[i].map { gridPoints[$0] }
        let x = pts.reduce(0) { $0 + $1.x } / 3
        let y = pts.reduce(0) { $0 + $1.y } / 3
        return (x, y)
    }
}
