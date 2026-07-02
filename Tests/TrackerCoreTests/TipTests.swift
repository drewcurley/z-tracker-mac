import Testing
@testable import TrackerCore

@Suite("TipProvider")
struct TipProviderTests {
    @Test("placeholderTips is non-empty and every tip has real text")
    func placeholderTipsNonEmpty() {
        #expect(!TipProvider.placeholderTips.isEmpty)
        for tip in TipProvider.placeholderTips {
            #expect(!tip.text.isEmpty)
            #expect(!tip.id.isEmpty)
        }
    }

    @Test("placeholderTips has no duplicate ids")
    func noDuplicateIds() {
        let ids = TipProvider.placeholderTips.map(\.id)
        #expect(Set(ids).count == ids.count)
    }

    @Test("random() always returns a tip from the placeholder list")
    func randomReturnsFromList() {
        for _ in 0..<20 {
            let tip = TipProvider.random()
            #expect(TipProvider.placeholderTips.contains(tip))
        }
    }
}
