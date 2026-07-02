import Testing
@testable import ZTrackerMac

@Suite("OverworldIconAtlas")
struct OverworldIconAtlasTests {
    @Test("dimensions match the reference app's confirmed icon size (docs/domain.md § 4.5/§ 6)")
    func dimensions() {
        #expect(OverworldIconAtlas.iconWidth == 16)
        #expect(OverworldIconAtlas.iconHeight == 11)
        #expect(OverworldIconAtlas.iconCount == 39)
    }

    @Test("icon(at:) returns a correctly-sized crop for every valid index", arguments: 0..<39)
    func validIndicesReturnCorrectlySizedIcon(index: Int) {
        let icon = OverworldIconAtlas.icon(at: index)
        #expect(icon != nil)
        #expect(icon?.width == OverworldIconAtlas.iconWidth)
        #expect(icon?.height == OverworldIconAtlas.iconHeight)
    }

    @Test("icon(at:) returns nil for out-of-range indices")
    func outOfRangeIndicesReturnNil() {
        #expect(OverworldIconAtlas.icon(at: -1) == nil)
        #expect(OverworldIconAtlas.icon(at: 39) == nil)
        #expect(OverworldIconAtlas.icon(at: 1000) == nil)
    }

    @Test("distinct indices produce distinct (non-identical) pixel content")
    func distinctIndicesProduceDistinctContent() throws {
        let first = try #require(OverworldIconAtlas.icon(at: 0))
        let other = try #require(OverworldIconAtlas.icon(at: 35)) // DarkX, confirmed visually distinct
        let firstData = try #require(first.dataProvider?.data)
        let otherData = try #require(other.dataProvider?.data)
        #expect(firstData != otherData)
    }
}
