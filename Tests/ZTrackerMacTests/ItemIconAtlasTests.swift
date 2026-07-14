import Testing
import TrackerCore
@testable import ZTrackerMac

@Suite("ItemIconAtlas")
struct ItemIconAtlasTests {
    @Test("dimensions match icons7x7.png (224×7 = 32 icons of 7×7)")
    func dimensions() {
        #expect(ItemIconAtlas.iconWidth == 7)
        #expect(ItemIconAtlas.iconHeight == 7)
        #expect(ItemIconAtlas.iconCount == 32)
    }

    @Test("icon(at:) crops correctly for every index", arguments: 0..<32)
    func validCrops(index: Int) {
        let icon = ItemIconAtlas.icon(at: index)
        #expect(icon != nil)
        #expect(icon?.width == ItemIconAtlas.iconWidth)
        #expect(icon?.height == ItemIconAtlas.iconHeight)
    }

    @Test("out-of-range indices return nil")
    func outOfRange() {
        #expect(ItemIconAtlas.icon(at: -1) == nil)
        #expect(ItemIconAtlas.icon(at: 32) == nil)
    }

    @Test("ITEMS index -> icon mapping matches the reference's allItemBMPs order")
    func itemMapping() {
        #expect(ItemIconAtlas.icon(forItemIndex: ITEMS.bookOrShield) == .book)
        #expect(ItemIconAtlas.icon(forItemIndex: ITEMS.boomerang) == .boomerang)
        #expect(ItemIconAtlas.icon(forItemIndex: ITEMS.bow) == .bow)
        #expect(ItemIconAtlas.icon(forItemIndex: ITEMS.powerBracelet) == .powerBracelet)
        #expect(ItemIconAtlas.icon(forItemIndex: ITEMS.ladder) == .ladder)
        #expect(ItemIconAtlas.icon(forItemIndex: ITEMS.magicBoomerang) == .magicBoomerang)
        #expect(ItemIconAtlas.icon(forItemIndex: ITEMS.anyKey) == .key)
        #expect(ItemIconAtlas.icon(forItemIndex: ITEMS.raft) == .raft)
        #expect(ItemIconAtlas.icon(forItemIndex: ITEMS.recorder) == .recorder)
        #expect(ItemIconAtlas.icon(forItemIndex: ITEMS.redCandle) == .redCandle)
        #expect(ItemIconAtlas.icon(forItemIndex: ITEMS.redRing) == .redRing)
        #expect(ItemIconAtlas.icon(forItemIndex: ITEMS.silverArrow) == .silverArrow)
        #expect(ItemIconAtlas.icon(forItemIndex: ITEMS.wand) == .wand)
        #expect(ItemIconAtlas.icon(forItemIndex: ITEMS.whiteSword) == .whiteSword)
        #expect(ItemIconAtlas.icon(forItemIndex: ITEMS.heartContainer) == .heartContainer)
        #expect(ItemIconAtlas.icon(forItemIndex: -1) == nil)
    }

    @Test("named icons resolve to a crop (e.g. the basement stair)")
    func namedIcons() {
        #expect(ItemIconAtlas.cgImage(.basementStair) != nil)
        #expect(ItemIconAtlas.cgImage(.heartContainer) != nil)
    }
}

@Suite("DungeonCellIconAtlas")
struct DungeonCellIconAtlasTests {
    @Test("dimensions match zelda_items16x16.png (208×16 = 13 icons of 16×16)")
    func dimensions() {
        #expect(DungeonCellIconAtlas.iconWidth == 16)
        #expect(DungeonCellIconAtlas.iconHeight == 16)
        #expect(DungeonCellIconAtlas.iconCount == 13)
    }

    @Test("icon(at:) crops correctly for every index", arguments: 0..<13)
    func validCrops(index: Int) {
        let icon = DungeonCellIconAtlas.icon(at: index)
        #expect(icon != nil)
        #expect(icon?.width == DungeonCellIconAtlas.iconWidth)
        #expect(icon?.height == DungeonCellIconAtlas.iconHeight)
    }

    @Test("the staircase glyph (basement-stair, T-016.2) resolves")
    func staircase() {
        #expect(DungeonCellIconAtlas.cgImage(.staircase) != nil)
        #expect(DungeonCellIconAtlas.Icon.staircase.rawValue == 12)
    }

    @Test("out-of-range indices return nil")
    func outOfRange() {
        #expect(DungeonCellIconAtlas.icon(at: -1) == nil)
        #expect(DungeonCellIconAtlas.icon(at: 13) == nil)
    }
}
