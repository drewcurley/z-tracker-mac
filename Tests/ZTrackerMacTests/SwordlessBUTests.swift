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

    @Test("sword-cave selector labels: relabeled, BU-annotated for WS/MS only")
    func swordCaveLabels() {
        // Off: plain relabels.
        #expect(OverworldMapView.swordCaveLabel(1, wsmsReplacedByBU: false) == "Wood Sword")
        #expect(OverworldMapView.swordCaveLabel(2, wsmsReplacedByBU: false) == "White Sword Item")
        #expect(OverworldMapView.swordCaveLabel(3, wsmsReplacedByBU: false) == "Magical Sword")
        // On: only white/magical note the Bomb Upgrade; wood sword unchanged.
        #expect(OverworldMapView.swordCaveLabel(1, wsmsReplacedByBU: true) == "Wood Sword")
        #expect(OverworldMapView.swordCaveLabel(2, wsmsReplacedByBU: true) == "White Sword Item (Bomb Upgrade)")
        #expect(OverworldMapView.swordCaveLabel(3, wsmsReplacedByBU: true) == "Magical Sword (Bomb Upgrade)")
    }
}
