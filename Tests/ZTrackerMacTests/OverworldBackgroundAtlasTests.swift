import Testing
import TrackerCore
@testable import ZTrackerMac

@Suite("OverworldBackgroundAtlas")
struct OverworldBackgroundAtlasTests {
    @Test("dimensions match the reference app's confirmed tile/section sizes")
    func dimensions() {
        #expect(OverworldBackgroundAtlas.tileWidth == 16)
        #expect(OverworldBackgroundAtlas.tileHeight == 11)
        #expect(OverworldBackgroundAtlas.sectionWidth == 256)
        #expect(OverworldBackgroundAtlas.questCount == 4)
    }

    @Test(
        "tile(quest:column:row:) returns a correctly-sized crop for every valid quest/column/row",
        arguments: OverworldQuest.allCases
    )
    func validRequestsReturnCorrectlySizedTile(quest: OverworldQuest) {
        for column in [0, 8, 15] {
            for row in [0, 4, 7] {
                let tile = OverworldBackgroundAtlas.tile(quest: quest, column: column, row: row)
                #expect(tile != nil)
                #expect(tile?.width == OverworldBackgroundAtlas.tileWidth)
                #expect(tile?.height == OverworldBackgroundAtlas.tileHeight)
            }
        }
    }

    @Test("out-of-range column/row returns nil")
    func outOfRangeReturnsNil() {
        #expect(OverworldBackgroundAtlas.tile(quest: .first, column: -1, row: 0) == nil)
        #expect(OverworldBackgroundAtlas.tile(quest: .first, column: 16, row: 0) == nil)
        #expect(OverworldBackgroundAtlas.tile(quest: .first, column: 0, row: -1) == nil)
        #expect(OverworldBackgroundAtlas.tile(quest: .first, column: 0, row: 8) == nil)
    }

    @Test("different quests are not byte-for-byte identical across their full section")
    func differentQuestsProduceDistinctContent() throws {
        // A single arbitrary tile can legitimately match between quests --
        // Zelda 1's First/Second Quest overworlds share most terrain, only
        // some screens differ. Comparing every tile in the 16x8 section
        // (not just one) is the well-founded version of this check: if
        // every tile matched, that would indicate a real cropping bug
        // (e.g. reading the same section twice), not shared terrain.
        var anyDiffers = false
        for column in 0..<OverworldGrid.columnCount {
            for row in 0..<OverworldGrid.rowCount {
                let first = try #require(OverworldBackgroundAtlas.tile(quest: .first, column: column, row: row))
                let second = try #require(OverworldBackgroundAtlas.tile(quest: .second, column: column, row: row))
                if first.dataProvider?.data != second.dataProvider?.data {
                    anyDiffers = true
                }
            }
        }
        #expect(anyDiffers)
    }
}
