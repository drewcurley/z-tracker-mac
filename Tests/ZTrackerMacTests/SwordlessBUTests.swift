import Testing
import TrackerCore
@testable import ZTrackerMac

@Suite("Swordless (WSMS→Bomb Upgrade)")
struct SwordlessBUTests {
    @Test("white-sword item swaps to bomb-upgrade only under BU")
    func whiteSwordSwaps() {
        #expect(ItemIconAtlas.icon(forItemIndex: ITEMS.whiteSword, wsmsReplacedByBU: false) == .whiteSword)
        #expect(ItemIconAtlas.icon(forItemIndex: ITEMS.whiteSword, wsmsReplacedByBU: true) == .wsMsBombUpgrade)
    }

    @Test("no other item is affected by BU (incl. the wood sword's sprite)")
    func othersUnaffected() {
        // Every non-white-sword item resolves identically with BU on or off.
        for item in 0...ITEMS.heartContainer where item != ITEMS.whiteSword {
            #expect(
                ItemIconAtlas.icon(forItemIndex: item, wsmsReplacedByBU: true)
                == ItemIconAtlas.icon(forItemIndex: item, wsmsReplacedByBU: false)
            )
        }
        // The brown/wood sword sprite is a fixed atlas icon, not routed through
        // the box-item domain — nothing here touches it.
        #expect(ItemIconAtlas.icon(forItemIndex: ITEMS.ladder, wsmsReplacedByBU: true) == .ladder)
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
