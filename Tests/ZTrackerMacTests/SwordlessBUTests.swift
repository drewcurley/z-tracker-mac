import Testing
import TrackerCore
@testable import ZTrackerMac

@Suite("Swordless (WSMS→Bomb Upgrade)")
struct SwordlessBUTests {
    @Test("white-sword item swaps to bomb-upgrade only under BU")
    func whiteSwordSwaps() {
        #expect(ItemIconAtlas.icon(forItemIndex: ITEMS.whiteSword, options: .init(wsmsReplacedByBU: false)) == .whiteSword)
        #expect(ItemIconAtlas.icon(forItemIndex: ITEMS.whiteSword, options: .init(wsmsReplacedByBU: true)) == .wsMsBombUpgrade)
    }

    @Test("no other item is affected by BU (incl. the wood sword's sprite)")
    func othersUnaffected() {
        // Every non-white-sword item resolves identically with BU on or off
        // (holding book/shield at its default so slot 0 doesn't confound).
        for item in 0...ITEMS.heartContainer where item != ITEMS.whiteSword {
            #expect(
                ItemIconAtlas.icon(forItemIndex: item, options: .init(wsmsReplacedByBU: true))
                == ItemIconAtlas.icon(forItemIndex: item, options: .init(wsmsReplacedByBU: false))
            )
        }
        // The brown/wood sword sprite is a fixed atlas icon, not routed through
        // the box-item domain — nothing here touches it.
        #expect(ItemIconAtlas.icon(forItemIndex: ITEMS.ladder, options: .init(wsmsReplacedByBU: true)) == .ladder)
    }

    @Test("item slot 0 shows the book by default and the magic shield when toggled")
    func bookShieldSwaps() {
        #expect(ItemIconAtlas.icon(forItemIndex: ITEMS.bookOrShield, options: .init(isCurrentlyBook: true)) == .book)
        #expect(ItemIconAtlas.icon(forItemIndex: ITEMS.bookOrShield, options: .init(isCurrentlyBook: false)) == .magicShield)
        // Default options → book.
        #expect(ItemIconAtlas.icon(forItemIndex: ITEMS.bookOrShield, options: .init()) == .book)
    }

    @Test("the two swaps are independent")
    func swapsIndependent() {
        // BU on + shield on: white sword → BU, slot 0 → shield, others normal.
        let both = ItemIconOptions(wsmsReplacedByBU: true, isCurrentlyBook: false)
        #expect(ItemIconAtlas.icon(forItemIndex: ITEMS.whiteSword, options: both) == .wsMsBombUpgrade)
        #expect(ItemIconAtlas.icon(forItemIndex: ITEMS.bookOrShield, options: both) == .magicShield)
        #expect(ItemIconAtlas.icon(forItemIndex: ITEMS.ladder, options: both) == .ladder)
    }

    @Test("sword-cave selector labels are plain location names, not BU-annotated")
    func swordCaveLabels() {
        // These are cave *locations* (holding random items); swordless does not
        // annotate them — the bomb upgrade replaces the white-sword *weapon*
        // (a box item), rendered on the item boxes/picker, not here.
        #expect(OverworldMapView.swordCaveLabel(1) == "Wood Sword")
        #expect(OverworldMapView.swordCaveLabel(2) == "White Sword Item")
        #expect(OverworldMapView.swordCaveLabel(3) == "Magical Sword")
    }
}
