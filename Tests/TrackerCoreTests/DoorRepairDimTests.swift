import Testing
@testable import TrackerCore

/// T-077 — door repair dims permanently when marked (reference "always dark");
/// derived from the mark so it survives a groundhog reset (which only clears used).
@Suite("Door-repair permanent dim (T-077)")
struct DoorRepairDimTests {
    @Test("only door repair dims permanently when marked") 
    func onlyDoorRepair() {
        #expect(OverworldTileMark.doorRepair.dimsPermanentlyWhenMarked)
        for m: OverworldTileMark in [.moneyMakingGame, .hintShop, .takeAny, .potionShop,
                                     .armos, .theLetter, .shop(.bomb), .dungeon(1),
                                     .secret(.large), .swordCave(1), .unmarked, .dontCare] {
            #expect(!m.dimsPermanentlyWhenMarked)
        }
    }

    @Test("a groundhog reset keeps the door-repair mark (so its dim persists)")
    func survivesGroundhog() {
        let model = TrackerModel(quest: .first, heartShuffle: false)
        model.overworldGrid.setMark(.doorRepair, column: 3, row: 3)
        model.resetForGroundhogOrRouters()
        #expect(model.overworldGrid.mark(column: 3, row: 3) == .doorRepair)
        #expect(model.overworldGrid.mark(column: 3, row: 3).dimsPermanentlyWhenMarked)
    }
}
