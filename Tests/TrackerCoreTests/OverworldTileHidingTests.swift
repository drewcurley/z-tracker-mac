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

    @Test("hide no-longer-relevant shop items: hide once every item is owned (T-207)")
    func shopHiding() {
        let options = TrackerOptions()
        options.hideNoLongerRelevantShopItems = true
        func hidden(_ primary: ShopKind, second: ShopKind? = nil, _ ps: PlayerComputedStateSummary) -> Bool {
            OverworldTileHiding.isKindHidden(mark: .shop(primary), options: options,
                                             hasRescuedZelda: false, playerState: ps, shopSecondItem: second)
        }
        let haveCandle = PlayerComputedStateSummary(candleLevel: 1)
        let haveKey = PlayerComputedStateSummary(haveAnyKey: true)
        let haveBoth = PlayerComputedStateSummary(haveAnyKey: true, candleLevel: 1)

        // Owned single-item shops hide.
        #expect(hidden(.candle, haveCandle))
        #expect(hidden(.key, haveKey))
        // Combo candle/key with both owned hides; with only one owned, stays (other still needed).
        #expect(hidden(.candle, second: .key, haveBoth))
        #expect(!hidden(.candle, second: .key, haveCandle))
        // Not owned → stays.
        #expect(!hidden(.candle, PlayerComputedStateSummary()))
        // Bomb & shield are always relevant — never hidden, even "owned".
        #expect(!hidden(.bomb, haveBoth))
        #expect(!hidden(.shield, haveBoth))
        #expect(!hidden(.candle, second: .bomb, haveCandle))   // bomb keeps the shop visible
        // Off → nothing hides.
        options.hideNoLongerRelevantShopItems = false
        #expect(!hidden(.candle, haveCandle))
    }

    @Test("always hide meat shops is independent of relevance (T-207)")
    func alwaysHideMeat() {
        let options = TrackerOptions()
        options.alwaysHideMeatShops = true   // hideNoLongerRelevant stays OFF
        let none = PlayerComputedStateSummary()
        #expect(OverworldTileHiding.isKindHidden(mark: .shop(.meat), options: options,
                                                 hasRescuedZelda: false, playerState: none))
        // A non-meat shop is unaffected by the meat option alone.
        #expect(!OverworldTileHiding.isKindHidden(mark: .shop(.candle), options: options,
                                                  hasRescuedZelda: false, playerState: none))
    }

    @Test("per-item hiding: drop only the owned items, keep the relevant ones (T-207)")
    func perItemShopHiding() {
        let options = TrackerOptions()
        options.hideNoLongerRelevantShopItems = true
        let haveRing = PlayerComputedStateSummary(ringLevel: 1)
        func hidden(_ primary: ShopKind, second: ShopKind? = nil, _ ps: PlayerComputedStateSummary) -> Set<ShopKind> {
            OverworldTileHiding.hiddenShopItems(primary: primary, second: second,
                                                options: options, playerState: ps, haveBook: false)
        }
        // Combo bomb/ring with the ring owned → hide just the ring; bomb (consumable) stays.
        #expect(hidden(.bomb, second: .blueRing, haveRing) == [.blueRing])
        // Nothing owned → nothing hidden.
        #expect(hidden(.bomb, second: .blueRing, PlayerComputedStateSummary()).isEmpty)
        // Both consumables (bomb + meat, meat option off) → never hidden.
        #expect(hidden(.bomb, second: .meat, haveRing).isEmpty)
    }

    @Test("book shop hides on haveBook (boomstick book counts) (T-207)")
    func bookShopHiding() {
        let options = TrackerOptions()
        options.hideNoLongerRelevantShopItems = true
        let none = PlayerComputedStateSummary()
        func hidden(_ haveBook: Bool) -> Bool {
            OverworldTileHiding.isKindHidden(mark: .shop(.book), options: options,
                                             hasRescuedZelda: false, playerState: none, haveBook: haveBook)
        }
        #expect(!hidden(false))   // no book yet → stays
        #expect(hidden(true))     // have the book (any form) → hides
    }

    @Test("END TO END: candle shop dims when the item grid marks blue candle (T-207 debug)")
    func shopHidingEndToEnd() {
        let model = TrackerModel(quest: .first)
        model.selectQuest(.first)
        model.playerProgress.hasBlueCandle = true
        let ps = model.playerComputedStateSummary
        #expect(ps.candleLevel > 0, "candleLevel should be >0 after hasBlueCandle")
        let options = TrackerOptions()
        options.hideNoLongerRelevantShopItems = true
        #expect(OverworldTileHiding.isKindHidden(mark: .shop(.candle), options: options,
                                                 hasRescuedZelda: false, playerState: ps))
    }
}
