import Testing
@testable import ZTrackerMac

@Suite("OverworldInteriorIconAtlas")
struct OverworldInteriorIconAtlasTests {
    @Test("dimensions match the real reference app strip, ow_icons5x9.png (bugfix: not s_icon_overworld_strip39.png, a dead ZHelper leftover)")
    func dimensions() {
        #expect(OverworldInteriorIconAtlas.iconWidth == 5)
        #expect(OverworldInteriorIconAtlas.iconHeight == 9)
        #expect(OverworldInteriorIconAtlas.iconCount == 14)
    }

    @Test("icon(at:) returns a correctly-sized crop for every valid index", arguments: 0..<14)
    func validIndicesReturnCorrectlySizedIcon(index: Int) {
        let icon = OverworldInteriorIconAtlas.icon(at: index)
        #expect(icon != nil)
        #expect(icon?.width == OverworldInteriorIconAtlas.iconWidth)
        #expect(icon?.height == OverworldInteriorIconAtlas.iconHeight)
    }

    @Test("icon(at:) returns nil for out-of-range indices")
    func outOfRangeIndicesReturnNil() {
        #expect(OverworldInteriorIconAtlas.icon(at: -1) == nil)
        #expect(OverworldInteriorIconAtlas.icon(at: 14) == nil)
        #expect(OverworldInteriorIconAtlas.icon(at: 1000) == nil)
    }

    @Test("distinct indices produce distinct (non-identical) pixel content")
    func distinctIndicesProduceDistinctContent() throws {
        let first = try #require(OverworldInteriorIconAtlas.icon(at: 0)) // sword cave 3
        let other = try #require(OverworldInteriorIconAtlas.icon(at: 13)) // the letter
        let firstData = try #require(first.dataProvider?.data)
        let otherData = try #require(other.dataProvider?.data)
        #expect(firstData != otherData)
    }
}

@Suite("OverworldShopIconAtlas")
struct OverworldShopIconAtlasTests {
    @Test("dimensions match the real reference app strip, icons3x7.png")
    func dimensions() {
        #expect(OverworldShopIconAtlas.iconWidth == 3)
        #expect(OverworldShopIconAtlas.iconHeight == 7)
        #expect(OverworldShopIconAtlas.iconCount == 8)
    }

    @Test("icon(at:) returns a correctly-sized crop for every valid index", arguments: 0..<8)
    func validIndicesReturnCorrectlySizedIcon(index: Int) {
        let icon = OverworldShopIconAtlas.icon(at: index)
        #expect(icon != nil)
        #expect(icon?.width == OverworldShopIconAtlas.iconWidth)
        #expect(icon?.height == OverworldShopIconAtlas.iconHeight)
    }

    @Test("icon(at:) returns nil for out-of-range indices")
    func outOfRangeIndicesReturnNil() {
        #expect(OverworldShopIconAtlas.icon(at: -1) == nil)
        #expect(OverworldShopIconAtlas.icon(at: 8) == nil)
        #expect(OverworldShopIconAtlas.icon(at: 1000) == nil)
    }

    @Test("distinct indices produce distinct (non-identical) pixel content")
    func distinctIndicesProduceDistinctContent() throws {
        let first = try #require(OverworldShopIconAtlas.icon(at: 0)) // arrow
        let other = try #require(OverworldShopIconAtlas.icon(at: 7)) // shield
        let firstData = try #require(first.dataProvider?.data)
        let otherData = try #require(other.dataProvider?.data)
        #expect(firstData != otherData)
    }
}
