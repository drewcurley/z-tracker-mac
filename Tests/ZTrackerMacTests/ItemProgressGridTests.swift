import CoreGraphics
import Testing
import TrackerCore
@testable import ZTrackerMac

@Suite("OverworldHeartAtlas")
struct OverworldHeartAtlasTests {
    /// Alpha of the given pixel in a CGImage (drawn into an RGBA context).
    private func alpha(of image: CGImage, x: Int, y: Int) -> UInt8? {
        let w = image.width, h = image.height
        var px = [UInt8](repeating: 0, count: w * h * 4)
        guard let ctx = CGContext(data: &px, width: w, height: h, bitsPerComponent: 8,
                                  bytesPerRow: w * 4, space: CGColorSpaceCreateDeviceRGB(),
                                  bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue) else { return nil }
        ctx.draw(image, in: CGRect(x: 0, y: 0, width: w, height: h))
        return px[(y * w + x) * 4 + 3]
    }

    @Test("empty and full heart sprites crop to 10×10")
    func cropsExist() {
        #expect(OverworldHeartAtlas.cgImage(.empty)?.width == 10)
        #expect(OverworldHeartAtlas.cgImage(.full)?.width == 10)
    }

    @Test("the white background is keyed transparent (corner pixel alpha 0)")
    func backgroundTransparent() throws {
        let empty = try #require(OverworldHeartAtlas.cgImage(.empty))
        // The heart sits centered; all four corners are background and must be
        // fully transparent after white-keying (the user-reported bug).
        #expect(alpha(of: empty, x: 0, y: 0) == 0)
        #expect(alpha(of: empty, x: 9, y: 0) == 0)
        #expect(alpha(of: empty, x: 0, y: 9) == 0)
        #expect(alpha(of: empty, x: 9, y: 9) == 0)
    }
}

@Suite("ItemProgressGrid layout")
struct ItemProgressGridLayoutTests {
    @Test("grid is the reference's 5×4 owItemGrid shape")
    func shape() {
        #expect(ItemProgressGrid.columns == 5)
        #expect(ItemProgressGrid.rows == 4)
        #expect(ItemProgressGrid.layout.count == 4)
        #expect(ItemProgressGrid.layout.allSatisfy { $0.count == 5 })
    }

    @Test("cells map to the reference OW_ITEM_GRID_LOCATIONS positions")
    func positions() {
        // Row 0: WS icon, WS item box, mags, wood sword, boomstick.
        #expect(ItemProgressGrid.cell(row: 0, col: 0) == .indicator(.whiteSword))
        #expect(ItemProgressGrid.cell(row: 0, col: 1) == .pickerBox(.whiteSword))
        #expect(ItemProgressGrid.cell(row: 0, col: 2) == .toggle(.magicalSword))
        #expect(ItemProgressGrid.cell(row: 0, col: 3) == .toggle(.woodSword))
        #expect(ItemProgressGrid.cell(row: 0, col: 4) == .toggle(.boomBook))
        // Row 1: ladder icon, coast item box, blue candle, wood arrow, blue ring.
        #expect(ItemProgressGrid.cell(row: 1, col: 0) == .indicator(.coast))
        #expect(ItemProgressGrid.cell(row: 1, col: 1) == .pickerBox(.coast))
        #expect(ItemProgressGrid.cell(row: 1, col: 2) == .toggle(.blueCandle))
        #expect(ItemProgressGrid.cell(row: 1, col: 3) == .toggle(.woodArrow))
        #expect(ItemProgressGrid.cell(row: 1, col: 4) == .toggle(.blueRing))
        // Row 2: armos icon, armos item box, bomb, ganon, zelda.
        #expect(ItemProgressGrid.cell(row: 2, col: 0) == .indicator(.armos))
        #expect(ItemProgressGrid.cell(row: 2, col: 1) == .pickerBox(.armos))
        #expect(ItemProgressGrid.cell(row: 2, col: 2) == .toggle(.bomb))
        #expect(ItemProgressGrid.cell(row: 2, col: 3) == .toggle(.ganon))
        #expect(ItemProgressGrid.cell(row: 2, col: 4) == .toggle(.zelda))
        // Row 3: four take-any hearts, then the meat toggle at col 4 (T-035.10).
        #expect(ItemProgressGrid.cell(row: 3, col: 0) == .takeAnyHeart(0))
        #expect(ItemProgressGrid.cell(row: 3, col: 1) == .takeAnyHeart(1))
        #expect(ItemProgressGrid.cell(row: 3, col: 2) == .takeAnyHeart(2))
        #expect(ItemProgressGrid.cell(row: 3, col: 3) == .takeAnyHeart(3))
        #expect(ItemProgressGrid.cell(row: 3, col: 4) == .toggle(.meat))
    }

    @Test("out-of-range positions are nil")
    func outOfRange() {
        #expect(ItemProgressGrid.cell(row: -1, col: 0) == nil)
        #expect(ItemProgressGrid.cell(row: 4, col: 0) == nil)
        #expect(ItemProgressGrid.cell(row: 0, col: 5) == nil)
    }

    @Test("every toggle appears exactly once and covers all ten flags")
    func togglesComplete() {
        let toggles = ItemProgressGrid.layout.flatMap { $0 }.compactMap { cell -> ItemProgressGrid.ItemToggle? in
            if case .toggle(let t) = cell { return t } else { return nil }
        }
        #expect(toggles.count == 10)
        #expect(Set(toggles).count == 10)
        #expect(Set(toggles) == Set(ItemProgressGrid.ItemToggle.allCases))
    }
}

@Suite("ItemProgressGrid toggle wiring")
struct ItemProgressGridToggleTests {
    @Test("each toggle's key path maps to the intended progress flag")
    func keyPaths() {
        let progress = PlayerProgressAndTakeAnyHearts()
        for toggle in ItemProgressGrid.ItemToggle.allCases {
            #expect(progress[keyPath: toggle.keyPath] == false)
            progress[keyPath: toggle.keyPath] = true
            #expect(progress[keyPath: toggle.keyPath] == true)
        }
        // Spot-check the specific bindings the summary cares about.
        let p = PlayerProgressAndTakeAnyHearts()
        p[keyPath: ItemProgressGrid.ItemToggle.blueCandle.keyPath] = true
        #expect(p.hasBlueCandle)
        p[keyPath: ItemProgressGrid.ItemToggle.magicalSword.keyPath] = true
        #expect(p.hasMagicalSword)
        p[keyPath: ItemProgressGrid.ItemToggle.bomb.keyPath] = true
        #expect(p.hasBombs)
    }

    @Test("toggling grid flags flows into PlayerComputedStateSummary")
    func flowsIntoSummary() {
        let model = TrackerModel(quest: .first)
        #expect(model.playerComputedStateSummary.swordLevel == 0)
        #expect(model.playerComputedStateSummary.candleLevel == 0)

        model.playerProgress[keyPath: ItemProgressGrid.ItemToggle.magicalSword.keyPath] = true
        #expect(model.playerComputedStateSummary.swordLevel == 3)

        model.playerProgress[keyPath: ItemProgressGrid.ItemToggle.blueCandle.keyPath] = true
        #expect(model.playerComputedStateSummary.candleLevel >= 1)

        model.playerProgress[keyPath: ItemProgressGrid.ItemToggle.blueRing.keyPath] = true
        #expect(model.playerComputedStateSummary.ringLevel >= 1)
    }

    @Test("take-any cycles all four states forward and backward, wrapping")
    func heartCycle() {
        // Forward: untaken -> heart -> potion -> candle -> untaken.
        #expect(ItemProgressGrid.cycledHeart(.untaken, by: 1) == .takenHeart)
        #expect(ItemProgressGrid.cycledHeart(.takenHeart, by: 1) == .takenPotion)
        #expect(ItemProgressGrid.cycledHeart(.takenPotion, by: 1) == .takenCandle)
        #expect(ItemProgressGrid.cycledHeart(.takenCandle, by: 1) == .untaken)
        // Backward wraps the other way.
        #expect(ItemProgressGrid.cycledHeart(.untaken, by: -1) == .takenCandle)
        #expect(ItemProgressGrid.cycledHeart(.takenCandle, by: -1) == .takenPotion)
        #expect(ItemProgressGrid.cycledHeart(.takenHeart, by: -1) == .untaken)
    }

    @Test("take-any hearts feed hearts into PlayerComputedStateSummary")
    func heartsFlowIntoSummary() {
        let model = TrackerModel(quest: .first)
        let base = model.playerComputedStateSummary.playerHearts
        model.playerProgress.takeAnyHearts[0] = .takenHeart
        #expect(model.playerComputedStateSummary.playerHearts == base + 1)
        // The potion/candle choice is not a heart, so it doesn't add one.
        model.playerProgress.takeAnyHearts[1] = .takenPotion
        #expect(model.playerComputedStateSummary.playerHearts == base + 1)
    }

    @Test("coast boxes resolve to the dungeon tracker's standalone boxes")
    func coastBoxes() {
        let dt = DungeonTrackerInstance()
        #expect(ItemProgressGrid.CoastBox.coast.box(in: dt) === dt.ladderBox)
        #expect(ItemProgressGrid.CoastBox.armos.box(in: dt) === dt.armosBox)
        #expect(ItemProgressGrid.CoastBox.whiteSword.box(in: dt) === dt.sword2Box)
    }
}
