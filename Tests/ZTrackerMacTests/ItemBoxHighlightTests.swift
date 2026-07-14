import Testing
import TrackerCore
@testable import ZTrackerMac

@Suite("Item-box located / superseded highlighting")
struct ItemBoxHighlightTests {
    private typealias Toggle = ItemProgressGrid.ItemToggle

    /// A `MapStateSummary` with a single overworld mark placed on a safe
    /// (non-always-empty) first-quest screen, so exactly one discovery flag
    /// flips.
    private func mapState(mark: OverworldTileMark) -> MapStateSummary {
        let grid = OverworldGrid()
        grid.setMark(mark, column: 0, row: 7) // safe first-quest screen
        return MapStateSummary.compute(
            grid: grid, instance: OverworldInstance(quest: .first),
            dungeonTracker: DungeonTrackerInstance(), playerState: PlayerComputedStateSummary(),
            progress: PlayerProgressAndTakeAnyHearts(), drawRoutes: false,
            routesCanScreenScroll: false, mirrorOverworld: false)
    }
    private var emptyMap: MapStateSummary {
        MapStateSummary.compute(
            grid: OverworldGrid(), instance: OverworldInstance(quest: .first),
            dungeonTracker: DungeonTrackerInstance(), playerState: PlayerComputedStateSummary(),
            progress: PlayerProgressAndTakeAnyHearts(), drawRoutes: false,
            routesCanScreenScroll: false, mirrorOverworld: false)
    }

    // MARK: superseded (player levels only)

    @Test("superseded: only wood sword/arrow and blue candle/ring, at their thresholds")
    func superseded() {
        #expect(Toggle.woodSword.superseded(playerState: PlayerComputedStateSummary(swordLevel: 1)))
        #expect(!Toggle.woodSword.superseded(playerState: PlayerComputedStateSummary(swordLevel: 0)))
        #expect(Toggle.woodArrow.superseded(playerState: PlayerComputedStateSummary(arrowLevel: 2)))
        #expect(!Toggle.woodArrow.superseded(playerState: PlayerComputedStateSummary(arrowLevel: 1)))
        #expect(Toggle.blueCandle.superseded(playerState: PlayerComputedStateSummary(candleLevel: 2)))
        #expect(!Toggle.blueCandle.superseded(playerState: PlayerComputedStateSummary(candleLevel: 1)))
        #expect(Toggle.blueRing.superseded(playerState: PlayerComputedStateSummary(ringLevel: 2)))
        #expect(!Toggle.blueRing.superseded(playerState: PlayerComputedStateSummary(ringLevel: 1)))
        // Items that can never be superseded.
        let maxed = PlayerComputedStateSummary(swordLevel: 3, candleLevel: 2, ringLevel: 2, arrowLevel: 2)
        for t in [Toggle.magicalSword, .boomBook, .bomb, .ganon, .zelda] {
            #expect(!t.superseded(playerState: maxed))
        }
    }

    // MARK: located (level == 0 AND shop/cave found)

    @Test("wood sword located: sword cave found and no sword yet")
    func woodSwordLocated() {
        let found = mapState(mark: .swordCave(1))
        #expect(Toggle.woodSword.located(playerState: PlayerComputedStateSummary(swordLevel: 0), mapState: found))
        // Once you have a sword, it's no longer "located" (it's superseded).
        #expect(!Toggle.woodSword.located(playerState: PlayerComputedStateSummary(swordLevel: 1), mapState: found))
        // No cave found → not located.
        #expect(!Toggle.woodSword.located(playerState: PlayerComputedStateSummary(swordLevel: 0), mapState: emptyMap))
    }

    @Test("shop/cave-only located flags map to the right box")
    func shopLocated() {
        let zero = PlayerComputedStateSummary()
        #expect(Toggle.bomb.located(playerState: zero, mapState: mapState(mark: .shop(.bomb))))
        #expect(Toggle.boomBook.located(playerState: zero, mapState: mapState(mark: .shop(.book))))
        #expect(Toggle.magicalSword.located(playerState: zero, mapState: mapState(mark: .swordCave(3))))
        #expect(Toggle.woodArrow.located(playerState: zero, mapState: mapState(mark: .shop(.arrow))))
        #expect(Toggle.blueCandle.located(playerState: zero, mapState: mapState(mark: .shop(.candle))))
        #expect(Toggle.blueRing.located(playerState: zero, mapState: mapState(mark: .shop(.blueRing))))
    }

    @Test("a found shop does not light the wrong box")
    func noCrossTalk() {
        let zero = PlayerComputedStateSummary()
        let arrowShop = mapState(mark: .shop(.arrow))
        #expect(!Toggle.blueCandle.located(playerState: zero, mapState: arrowShop))
        #expect(!Toggle.blueRing.located(playerState: zero, mapState: arrowShop))
        #expect(!Toggle.bomb.located(playerState: zero, mapState: arrowShop))
    }

    @Test("bomb/candle located respects the level==0 gate where it applies")
    func levelGate() {
        // Blue candle only lights located when candleLevel == 0.
        let candleShop = mapState(mark: .shop(.candle))
        #expect(!Toggle.blueCandle.located(playerState: PlayerComputedStateSummary(candleLevel: 1), mapState: candleShop))
        // Bomb has no level gate — always located once the shop is found.
        #expect(Toggle.bomb.located(playerState: PlayerComputedStateSummary(), mapState: mapState(mark: .shop(.bomb))))
    }

    @Test("ganon and zelda never light up")
    func bossesNeverLight() {
        let zero = PlayerComputedStateSummary()
        for t in [Toggle.ganon, .zelda] {
            #expect(!t.located(playerState: zero, mapState: mapState(mark: .shop(.bomb))))
            #expect(!t.superseded(playerState: zero))
        }
    }
}
