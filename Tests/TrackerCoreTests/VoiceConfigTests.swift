import Testing
@testable import TrackerCore

/// The data-driven voice catalog + config (T-139).
struct VoiceConfigTests {
    @Test func seedsFromCatalogDefaults() {
        let c = VoiceConfig()
        #expect(c.phrases(for: "OW_BombShop") == ["bomb shop", "bomb", "bombs"])
        #expect(!c.phrases(for: "Cursor_Up").isEmpty)
    }

    @Test func longestPhraseWins() {
        let c = VoiceConfig()
        // "take any potion" (specific) beats "take any".
        #expect(c.match(["take", "any", "potion"])?.actionID == "TakeAny_Potion")
        #expect(c.match(["take", "any"])?.actionID == "TakeAny_None")
        // "set level" (mark) beats bare "level" (enter).
        #expect(c.match(["set", "level", "1"])?.actionID == "OW_Dungeon")
        #expect(c.match(["enter", "level", "5"])?.actionID == "Dungeon_Enter")
    }

    @Test func parametricActionsCaptureTheNumber() {
        let c = VoiceConfig()
        #expect(c.match(["enter", "level", "5"])?.number == 5)
        #expect(c.match(["any", "road", "2"])?.number == 2)
        // Non-parametric actions don't capture a number.
        #expect(c.match(["bomb", "shop"])?.number == nil)
    }

    @Test func userPhrasesMatch() {
        let c = VoiceConfig()
        c.addPhrase("boom shop", to: "OW_BombShop")
        #expect(c.match(["boom", "shop"])?.actionID == "OW_BombShop")
    }

    @Test func gibberishMatchesNothing() {
        #expect(VoiceConfig().match(["hello", "there"]) == nil)
    }

    @Test func everyActionHasAtLeastOneDefaultPhrase() {
        for a in VoiceCatalog.all { #expect(!a.defaultPhrases.isEmpty, "\(a.id) has no phrases") }
    }
}
