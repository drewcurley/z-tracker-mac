import Testing
import TrackerCore
@testable import ZTrackerMac

@Suite("ItemProgressGrid layout")
struct ItemProgressGridLayoutTests {
    @Test("grid is the reference's 5×3 owItemGrid shape")
    func shape() {
        #expect(ItemProgressGrid.columns == 5)
        #expect(ItemProgressGrid.rows == 3)
        #expect(ItemProgressGrid.layout.count == 3)
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
    }

    @Test("out-of-range positions are nil")
    func outOfRange() {
        #expect(ItemProgressGrid.cell(row: -1, col: 0) == nil)
        #expect(ItemProgressGrid.cell(row: 3, col: 0) == nil)
        #expect(ItemProgressGrid.cell(row: 0, col: 5) == nil)
    }

    @Test("every toggle appears exactly once and covers all nine flags")
    func togglesComplete() {
        let toggles = ItemProgressGrid.layout.flatMap { $0 }.compactMap { cell -> ItemProgressGrid.ItemToggle? in
            if case .toggle(let t) = cell { return t } else { return nil }
        }
        #expect(toggles.count == 9)
        #expect(Set(toggles).count == 9)
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

    @Test("coast boxes resolve to the dungeon tracker's standalone boxes")
    func coastBoxes() {
        let dt = DungeonTrackerInstance()
        #expect(ItemProgressGrid.CoastBox.coast.box(in: dt) === dt.ladderBox)
        #expect(ItemProgressGrid.CoastBox.armos.box(in: dt) === dt.armosBox)
        #expect(ItemProgressGrid.CoastBox.whiteSword.box(in: dt) === dt.sword2Box)
    }
}
