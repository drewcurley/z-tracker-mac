import Testing
@testable import TrackerCore

@Suite("More-settings tile hiding (T-004.3)")
struct OverworldTileHidingTests {
    @Test("each of the 12 hideable kinds maps to its OverworldHiddenTileKind")
    func hideableKindMapping() {
        #expect(OverworldTileMark.swordCave(1).hideableKind == .sword1)
        #expect(OverworldTileMark.swordCave(2).hideableKind == .sword2)
        #expect(OverworldTileMark.swordCave(3).hideableKind == .sword3)
        #expect(OverworldTileMark.secret(.large).hideableKind == .largeSecret)
        #expect(OverworldTileMark.secret(.medium).hideableKind == .mediumSecret)
        #expect(OverworldTileMark.secret(.small).hideableKind == .smallSecret)
        #expect(OverworldTileMark.doorRepair.hideableKind == .doorRepair)
        #expect(OverworldTileMark.moneyMakingGame.hideableKind == .moneyMakingGame)
        #expect(OverworldTileMark.theLetter.hideableKind == .theLetter)
        #expect(OverworldTileMark.armos.hideableKind == .armos)
        #expect(OverworldTileMark.hintShop.hideableKind == .hintShop)
        #expect(OverworldTileMark.takeAny.hideableKind == .takeAny)
    }

    @Test("non-hideable marks map to nil")
    func nonHideableKinds() {
        #expect(OverworldTileMark.unmarked.hideableKind == nil)
        #expect(OverworldTileMark.dontCare.hideableKind == nil)
        #expect(OverworldTileMark.dungeon(1).hideableKind == nil)
        #expect(OverworldTileMark.anyRoad(1).hideableKind == nil)
        #expect(OverworldTileMark.shop(.arrow).hideableKind == nil)   // shops: T-004.4
        #expect(OverworldTileMark.potionShop.hideableKind == nil)
        #expect(OverworldTileMark.secret(.unknown).hideableKind == nil) // not in hide list
    }

    @Test("isKindHidden: only when the kind is checked to hide")
    func hiddenOnlyWhenChecked() {
        let options = TrackerOptions()
        // Nothing hidden by default.
        #expect(!OverworldTileHiding.isKindHidden(mark: .armos, options: options, hasRescuedZelda: false))
        options.hiddenOverworldTiles[.armos] = true
        #expect(OverworldTileHiding.isKindHidden(mark: .armos, options: options, hasRescuedZelda: false))
        // A different kind is unaffected.
        #expect(!OverworldTileHiding.isKindHidden(mark: .theLetter, options: options, hasRescuedZelda: false))
    }

    @Test("rescuing Zelda reveals everything")
    func rescueReveals() {
        let options = TrackerOptions()
        for kind in OverworldHiddenTileKind.allCases { options.hiddenOverworldTiles[kind] = true }
        #expect(OverworldTileHiding.isKindHidden(mark: .armos, options: options, hasRescuedZelda: false))
        #expect(!OverworldTileHiding.isKindHidden(mark: .armos, options: options, hasRescuedZelda: true))
    }
}
