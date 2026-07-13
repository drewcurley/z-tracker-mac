import Testing
@testable import TrackerCore

@Suite("OverworldTileMark raw-index bridge")
struct OverworldTileMarkRawIndexTests {
    /// Every documented mark, paired with its reference
    /// `MapSquareChoiceDomainHelper` index (`TrackerModel.fs:311-352`).
    private static let expected: [(OverworldTileMark, Int)] = [
        (.dungeon(1), 0), (.dungeon(2), 1), (.dungeon(3), 2), (.dungeon(4), 3),
        (.dungeon(5), 4), (.dungeon(6), 5), (.dungeon(7), 6), (.dungeon(8), 7),
        (.dungeon(9), 8),
        (.anyRoad(1), 9), (.anyRoad(2), 10), (.anyRoad(3), 11), (.anyRoad(4), 12),
        (.swordCave(3), 13), (.swordCave(2), 14), (.swordCave(1), 15),
        (.shop(.arrow), 16), (.shop(.bomb), 17), (.shop(.book), 18),
        (.shop(.candle), 19), (.shop(.blueRing), 20), (.shop(.meat), 21),
        (.shop(.key), 22), (.shop(.shield), 23),
        (.secret(.unknown), 24), (.secret(.large), 25), (.secret(.medium), 26),
        (.secret(.small), 27),
        (.doorRepair, 28), (.moneyMakingGame, 29), (.theLetter, 30),
        (.armos, 31), (.hintShop, 32), (.takeAny, 33), (.potionShop, 34),
        (.dontCare, 35),
    ]

    @Test("rawIndex matches the reference numbering for every mark")
    func rawIndexMatchesReference() {
        for (mark, index) in Self.expected {
            #expect(mark.rawIndex == index)
        }
        #expect(OverworldTileMark.unmarked.rawIndex == -1)
    }

    @Test("fromRawIndex is the exact inverse of rawIndex")
    func fromRawIndexInverts() {
        for (mark, index) in Self.expected {
            #expect(OverworldTileMark.fromRawIndex(index) == mark)
        }
        #expect(OverworldTileMark.fromRawIndex(-1) == .unmarked)
        // Round-trip the whole documented range.
        for i in -1...35 {
            let mark = OverworldTileMark.fromRawIndex(i)
            #expect(mark != nil)
            #expect(mark?.rawIndex == i)
        }
    }

    @Test("fromRawIndex returns nil outside the documented range")
    func fromRawIndexOutOfRange() {
        #expect(OverworldTileMark.fromRawIndex(-2) == nil)
        #expect(OverworldTileMark.fromRawIndex(36) == nil)
        #expect(OverworldTileMark.fromRawIndex(999) == nil)
    }

    @Test("isItem / toItem match the reference's shop arithmetic")
    func isItemAndToItem() {
        // Shops are exactly 16...23.
        for i in 0...40 {
            #expect(OverworldTileMark.isItem(rawIndex: i) == (i >= 16 && i <= 23))
        }
        // ToItem(state) = state-15 for shops, else 0.
        #expect(OverworldTileMark.toItem(rawIndex: 16) == 1) // ARROW -> 1
        #expect(OverworldTileMark.toItem(rawIndex: 20) == 5) // BLUE_RING -> 5
        #expect(OverworldTileMark.toItem(rawIndex: 23) == 8) // SHIELD -> 8
        #expect(OverworldTileMark.toItem(rawIndex: 15) == 0) // not a shop
        #expect(OverworldTileMark.toItem(rawIndex: 31) == 0) // armos, not a shop
    }

    @Test("named constants pin to the reference")
    func constants() {
        #expect(OverworldTileMark.shopExtraDataKey == 16) // SHOP == ARROW
        #expect(OverworldTileMark.numShopItems == 8)      // NUM_ITEMS
        #expect(OverworldTileMark.maxRawIndex == 35)      // DARK_X / MaxKey
    }
}

@Suite("OverworldGrid extra-data store")
struct OverworldGridExtraDataTests {
    @Test("defaults to zero everywhere and round-trips writes per (tile, key)")
    func roundTrip() {
        let grid = OverworldGrid()
        #expect(grid.extraData(column: 3, row: 2, key: OverworldTileMark.shopExtraDataKey) == 0)

        // Store a shop's second item (blue ring -> toItem 5) at one tile.
        grid.setExtraData(5, column: 3, row: 2, key: OverworldTileMark.shopExtraDataKey)
        #expect(grid.extraData(column: 3, row: 2, key: OverworldTileMark.shopExtraDataKey) == 5)

        // A different key on the same tile is independent.
        #expect(grid.extraData(column: 3, row: 2, key: 30) == 0)
        grid.setExtraData(1, column: 3, row: 2, key: 30) // potion-letter toggle
        #expect(grid.extraData(column: 3, row: 2, key: 30) == 1)

        // A different tile, same key, is independent.
        #expect(grid.extraData(column: 4, row: 2, key: OverworldTileMark.shopExtraDataKey) == 0)
    }

    @Test("keyCount is DARK_X + 1 = 36")
    func keyCount() {
        #expect(OverworldGrid.extraDataKeyCount == 36)
    }

    @Test("clearAll resets extra-data too")
    func clearAllResets() {
        let grid = OverworldGrid()
        grid.setExtraData(7, column: 0, row: 0, key: OverworldTileMark.shopExtraDataKey)
        grid.setMark(.shop(.arrow), column: 0, row: 0)
        grid.clearAll()
        #expect(grid.extraData(column: 0, row: 0, key: OverworldTileMark.shopExtraDataKey) == 0)
        #expect(grid.mark(column: 0, row: 0) == .unmarked)
    }
}
