import Testing
import CoreGraphics
import TrackerCore
@testable import ZTrackerMac

/// T-245 — atlas lookups return the *same* cached `CGImage` every time. A fresh crop per call
/// made every overworld tile look changed to SwiftUI, re-running all 128 tile bodies per render.
@Suite("Render caching (T-245)")
struct RenderCachingTests {
    @Test("background tiles are cropped once and returned identically")
    func backgroundTilesCached() throws {
        for quest in OverworldQuest.allCases {
            let a = try #require(OverworldBackgroundAtlas.tile(quest: quest, column: 3, row: 2))
            let b = try #require(OverworldBackgroundAtlas.tile(quest: quest, column: 3, row: 2))
            #expect(a === b)
        }
        #expect(OverworldBackgroundAtlas.tile(quest: .first, column: 16, row: 0) == nil)
    }

    @Test("icon atlases return identical cached crops")
    func iconsCached() throws {
        let i1 = try #require(OverworldInteriorIconAtlas.icon(at: 2))
        #expect(i1 === OverworldInteriorIconAtlas.icon(at: 2))
        let s1 = try #require(OverworldShopIconAtlas.icon(at: 1))
        #expect(s1 === OverworldShopIconAtlas.icon(at: 1))
        let d1 = try #require(DungeonCellIconAtlas.icon(at: 0))
        #expect(d1 === DungeonCellIconAtlas.icon(at: 0))
        #expect(OverworldInteriorIconAtlas.icon(at: -1) == nil)
    }
}
