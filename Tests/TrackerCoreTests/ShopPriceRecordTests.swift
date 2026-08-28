import Testing
@testable import TrackerCore

@Suite("Shop & Price tracker (T-218)")
struct ShopPriceRecordTests {
    @Test("a fresh record is the fixed shape and empty")
    func freshShape() {
        let r = ShopPriceRecord()
        #expect(r.shops.count == 4)
        #expect(r.shops.allSatisfy { $0.count == 3 })
        #expect(r.hints.count == 2)
        #expect(r.hints.allSatisfy { $0.count == 3 })
        #expect(r.isEmpty)
    }

    @Test("cycling a slot walks the eight staples then clears")
    func cycleKind() {
        let r = ShopPriceRecord()
        #expect(r.shops[0][0].kind == nil)
        r.cycleSlotKind(shop: 0, slot: 0)
        #expect(r.shops[0][0].kind == ShopKind.allCases.first)
        // Walk to the last staple.
        for _ in 1..<ShopKind.allCases.count { r.cycleSlotKind(shop: 0, slot: 0) }
        #expect(r.shops[0][0].kind == ShopKind.allCases.last)
        // One more wraps back to empty.
        r.cycleSlotKind(shop: 0, slot: 0)
        #expect(r.shops[0][0].kind == nil)
        #expect(r.isEmpty)   // no price was set, so a full kind round-trip leaves it blank
    }

    @Test("cycling preserves a slot's price")
    func cyclePreservesPrice() {
        let r = ShopPriceRecord()
        r.shops[1][2].price = 100
        r.cycleSlotKind(shop: 1, slot: 2)
        #expect(r.shops[1][2].price == 100)
        #expect(r.shops[1][2].kind == ShopKind.allCases.first)
        #expect(!r.isEmpty)
    }

    @Test("out-of-range cycle is a no-op")
    func cycleGuards() {
        let r = ShopPriceRecord()
        r.cycleSlotKind(shop: 9, slot: 9)   // must not crash
        #expect(r.isEmpty)
    }

    @Test("clearAll wipes everything back to blank")
    func clear() {
        let r = ShopPriceRecord()
        r.shops[0][0] = .init(kind: .bomb, price: 20)
        r.bluePotionPrice = 40; r.bombUpgradePrice = 100
        r.hints[1][2] = .init(price: 30, collected: true)
        #expect(!r.isEmpty)
        r.clearAll()
        #expect(r.isEmpty)
    }

    @Test("state round-trips through save/restore")
    func roundTrip() {
        let r = ShopPriceRecord()
        r.shops[0][0] = .init(kind: .arrow, price: 10)
        r.shops[3][2] = .init(kind: .shield, price: 90)
        r.bluePotionPrice = 20; r.redPotionPrice = 68; r.bombUpgradePrice = 100
        r.hints[0][1] = .init(price: 30, collected: true)
        r.hints[1][2] = .init(price: 100, collected: false)

        let restored = ShopPriceRecord()
        restored.restore(r.state)
        #expect(restored.shops[0][0] == ShopPriceRecord.Slot(kind: .arrow, price: 10))
        #expect(restored.shops[3][2] == ShopPriceRecord.Slot(kind: .shield, price: 90))
        #expect(restored.bluePotionPrice == 20 && restored.redPotionPrice == 68)
        #expect(restored.bombUpgradePrice == 100)
        #expect(restored.hints[0][1] == ShopPriceRecord.Hint(price: 30, collected: true))
        #expect(restored.hints[1][2] == ShopPriceRecord.Hint(price: 100, collected: false))
    }

    @Test("restore normalizes a ragged/short saved grid to the fixed shape")
    func restoreNormalizes() {
        // A malformed state (too few shops / short rows) must not leave an out-of-bounds grid.
        let ragged = ShopPriceRecord.State(
            shops: [[.init(kind: .book, price: 5)]],   // 1 shop, 1 slot
            bluePotionPrice: nil, redPotionPrice: nil, bombUpgradePrice: nil,
            hints: [])
        let r = ShopPriceRecord()
        r.restore(ragged)
        #expect(r.shops.count == 4 && r.shops.allSatisfy { $0.count == 3 })
        #expect(r.hints.count == 2 && r.hints.allSatisfy { $0.count == 3 })
        #expect(r.shops[0][0] == ShopPriceRecord.Slot(kind: .book, price: 5))
        #expect(r.shops[3][2] == ShopPriceRecord.Slot())
    }
}
