import Testing
@testable import TrackerCore

@Suite("Overworld tile enemies (T-117)")
struct OverworldEnemiesTests {
    @Test("the reduced overworld enemy set is the 10 requested types")
    func reducedSet() {
        #expect(MonsterDetail.overworldEnemies == [
            .blueWizzrobe, .blueDarknut, .redLynel, .polsVoice, .redGoriya,
            .gibdo, .rope, .stalfos, .redTektite, .blueMoblin,
        ])
        // Each is renderable via the shared monster atlas mapping (non-unmarked).
        for e in MonsterDetail.overworldEnemies { #expect(!e.isNotMarked) }
    }

    @Test("toggleEnemy stores up to two per tile, independent of other tiles")
    func togglesUpToTwo() {
        let g = OverworldGrid()
        #expect(g.enemies(column: 2, row: 3).isEmpty)
        g.toggleEnemy(.blueMoblin, column: 2, row: 3)
        #expect(g.enemies(column: 2, row: 3) == [.blueMoblin])
        g.toggleEnemy(.rope, column: 2, row: 3)
        #expect(g.enemies(column: 2, row: 3) == [.blueMoblin, .rope])
        // A third replaces the secondary (normalized pair).
        g.toggleEnemy(.gibdo, column: 2, row: 3)
        #expect(g.enemies(column: 2, row: 3) == [.blueMoblin, .gibdo])
        // Another tile is unaffected.
        #expect(g.enemies(column: 0, row: 0).isEmpty)
    }

    @Test("toggling a present enemy removes it; unmarked clears both")
    func removeAndClear() {
        let g = OverworldGrid()
        g.toggleEnemy(.rope, column: 1, row: 1)
        g.toggleEnemy(.gibdo, column: 1, row: 1)
        g.toggleEnemy(.rope, column: 1, row: 1)               // remove primary → gibdo promotes
        #expect(g.enemies(column: 1, row: 1) == [.gibdo])
        g.toggleEnemy(.unmarked, column: 1, row: 1)           // clear both
        #expect(g.enemies(column: 1, row: 1).isEmpty)
    }

    @Test("clearAll wipes enemy annotations")
    func clearAllWipes() {
        let g = OverworldGrid()
        g.toggleEnemy(.rope, column: 5, row: 5)
        g.clearAll()
        #expect(g.enemies(column: 5, row: 5).isEmpty)
    }
}
