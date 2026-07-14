import Testing
@testable import TrackerCore

@Suite("Triforce reference layout (T-050)")
struct TriforceReferenceTests {
    @Test("orderings match the reference DrawTriforceMapCore labels")
    func orderings() {
        #expect(TriforceReference.firstQuest == "12345678")
        #expect(TriforceReference.secondQuest == "13254687")
        #expect(TriforceReference.firstQuest.count == 8)
        #expect(TriforceReference.secondQuest.count == 8)
        // Every ordering is a permutation of the digits 1–8.
        #expect(Set(TriforceReference.firstQuest) == Set("12345678"))
        #expect(Set(TriforceReference.secondQuest) == Set("12345678"))
    }

    @Test("8 label positions on a 4×2 grid")
    func positions() {
        #expect(TriforceReference.positions.count == 8)
        for p in TriforceReference.positions {
            #expect(p.x >= 0 && p.x <= 4)
            #expect(p.y >= 0 && p.y <= 2)
        }
        // Row layout: two at y=0.5 (top), two at y=1.0 (middle), four at y=1.5.
        #expect(TriforceReference.positions.filter { $0.y == 0.5 }.count == 2)
        #expect(TriforceReference.positions.filter { $0.y == 1.0 }.count == 2)
        #expect(TriforceReference.positions.filter { $0.y == 1.5 }.count == 4)
    }

    @Test("8 sub-triangles over 9 grid points; centroids land inside the figure")
    func triangles() {
        #expect(TriforceReference.gridPoints.count == 9)
        #expect(TriforceReference.triangles.count == 8)
        for tri in TriforceReference.triangles {
            #expect(tri.count == 3)
            #expect(tri.allSatisfy { (0..<9).contains($0) })
        }
        // Each centroid is within the 4×2 figure.
        for i in 0..<8 {
            let c = TriforceReference.centroid(i)
            #expect(c.x > 0 && c.x < 4)
            #expect(c.y > 0 && c.y < 2)
        }
        // Top two centroids are highest (smallest y), bottom four are lowest.
        let ys = (0..<8).map { TriforceReference.centroid($0).y }.sorted()
        #expect(ys[0] < 1 && ys[1] < 1)   // two in the top row
    }
}
