import Testing
@testable import TrackerCore

@Suite("TipProvider")
struct TipProviderTests {
    @Test("the full reference tip list is present (T-250)")
    func fullList() {
        #expect(TipProvider.noviceTips.count == 12)
        #expect(TipProvider.intermediateTips.count == 15)
        #expect(TipProvider.advancedTips.count == 8)
        #expect(TipProvider.zTrackerTips.count == 9)       // 12 in the reference, 3 not applicable here
        #expect(TipProvider.allTips.count == 12 + 15 + 8 + 9 + TipProvider.extraTips.count)
        #expect(TipProvider.allTips.contains { $0.id == "khananakey" || $0.text.contains("(khananakey)") })
    }

    @Test("every tip has real text, and ids are unique")
    func wellFormed() {
        for tip in TipProvider.allTips {
            #expect(!tip.text.isEmpty)
            #expect(!tip.id.isEmpty)
        }
        let ids = TipProvider.allTips.map(\.id)
        #expect(Set(ids).count == ids.count)
    }

    @Test("no tip points at a feature this app doesn't have")
    func noDeadFeatureTips() {
        for tip in TipProvider.allTips {
            #expect(!tip.text.contains("question mark"))       // the hover explainer
            #expect(!tip.text.contains("circle it"))           // overworld circles
            #expect(!tip.text.contains("right next to the dungeon map"))
            #expect(!tip.text.contains("application folder"))  // HotKeys.txt lives in Settings here
        }
    }

    @Test("random() always returns a tip from the list")
    func randomReturnsFromList() {
        for _ in 0..<20 {
            #expect(TipProvider.allTips.contains(TipProvider.random()))
        }
    }
}
