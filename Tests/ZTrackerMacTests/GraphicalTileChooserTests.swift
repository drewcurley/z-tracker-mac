import Foundation
import Testing
import TrackerCore
@testable import ZTrackerMac

/// The graphical overworld tile chooser's fixed layout (T-185).
struct GraphicalTileChooserTests {
    @Test("layout is 5 rows × 8, 40 cells total")
    func shape() {
        #expect(OverworldChooserLayout.rows.count == 5)
        #expect(OverworldChooserLayout.rows.allSatisfy { $0.count == 8 })
        #expect(OverworldChooserLayout.all.count == 40)
    }

    @Test("rows hold the user-specified marks in order")
    func contents() {
        let rows = OverworldChooserLayout.rows
        // Row 1: the 8 shops.
        #expect(rows[0] == ShopKind.allCases.map { .mark(.shop($0)) })
        // Row 2: 4 secrets, door repair, money game, hint, potion.
        #expect(rows[1] == [.mark(.secret(.small)), .mark(.secret(.medium)), .mark(.secret(.large)),
                            .mark(.secret(.unknown)), .mark(.doorRepair), .mark(.moneyMakingGame),
                            .mark(.hintShop), .mark(.potionShop)])
        // Row 3: letter, armos, 3 take-anys, don't-care, unmarked, start.
        #expect(rows[2] == [.mark(.theLetter), .mark(.armos),
                            .takeAny(.takenPotion), .takeAny(.takenHeart), .takeAny(.takenCandle),
                            .mark(.dontCare), .mark(.unmarked), .startSpot])
        // Row 4: levels 1–8.
        #expect(rows[3] == (1...8).map { .mark(.dungeon($0)) })
        // Row 5: level 9, any-road 1–4, swords 1–3.
        #expect(rows[4] == [.mark(.dungeon(9)), .mark(.anyRoad(1)), .mark(.anyRoad(2)), .mark(.anyRoad(3)),
                            .mark(.anyRoad(4)), .mark(.swordCave(1)), .mark(.swordCave(2)), .mark(.swordCave(3))])
    }

    @Test("the '?' (unknown-order) any-road is not offered in the chooser")
    func noUnknownAnyRoad() {
        #expect(!OverworldChooserLayout.all.contains(.mark(.anyRoad(0))))
    }

    @Test("graphicalOverworldChooser persists across launches")
    func optionPersists() {
        let suite = "test.graphicalChooser.\(UInt64.random(in: 0..<UInt64.max))"
        let store = UserDefaults(suiteName: suite)!
        defer { store.removePersistentDomain(forName: suite) }
        let a = TrackerOptions(); a.enableSettingsPersistence(store: store)
        a.graphicalOverworldChooser = true
        a.saveSettings()
        let b = TrackerOptions(); b.enableSettingsPersistence(store: store)
        #expect(b.graphicalOverworldChooser == true)
    }
}
