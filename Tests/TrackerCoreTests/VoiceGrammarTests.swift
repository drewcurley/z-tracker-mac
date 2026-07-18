import Testing
@testable import TrackerCore

/// Structured voice-command grammar (T-137/T-138/T-139) — cursor-driven, region-aware,
/// config-matched.
struct VoiceGrammarTests {
    private let config = VoiceConfig()

    @Test func coordinateOnlyMovesCursor() {
        #expect(VoiceGrammar.parse("E7", config: config) == .cursorTo(column: 6, row: 4))
        #expect(VoiceGrammar.parse("A1", config: config) == .cursorTo(column: 0, row: 0))
        #expect(VoiceGrammar.parse("H16", config: config) == .cursorTo(column: 15, row: 7))
    }

    @Test func coordinatePlusActionMovesAndMarks() {
        #expect(VoiceGrammar.parse("D5 bomb shop", config: config)
            == .actionAt(column: 4, row: 3, words: ["bomb", "shop"]))
    }

    @Test func actionOnlyActsAtCursor() {
        #expect(VoiceGrammar.parse("potion", config: config) == .actionAtCursor(words: ["potion"]))
        #expect(VoiceGrammar.parse("meat shop", config: config) == .actionAtCursor(words: ["meat", "shop"]))
    }

    @Test func directionsMoveCursor() {
        #expect(VoiceGrammar.parse("up", config: config) == .moveCursor(dcol: 0, drow: -1))
        #expect(VoiceGrammar.parse("go down", config: config) == .moveCursor(dcol: 0, drow: 1))
        #expect(VoiceGrammar.parse("right", config: config) == .moveCursor(dcol: 1, drow: 0))
        #expect(VoiceGrammar.parse("left", config: config) == .moveCursor(dcol: -1, drow: 0))
    }

    @Test func regionNavAndStart() {
        #expect(VoiceGrammar.parse("overworld", config: config) == .exitToOverworld)
        #expect(VoiceGrammar.parse("leave dungeon", config: config) == .exitToOverworld)
        #expect(VoiceGrammar.parse("start", config: config) == .gotoStart)
        #expect(VoiceGrammar.parse("go to start", config: config) == .gotoStart)
    }

    @Test func dungeonEnterVsMark() {
        #expect(VoiceGrammar.parse("enter level 5", config: config) == .dungeonTab(5))
        #expect(VoiceGrammar.parse("level five", config: config) == .dungeonTab(5))
        #expect(VoiceGrammar.parse("set level 1", config: config) == .actionAtCursor(words: ["set", "level", "1"]))
        #expect(VoiceGrammar.overworldAction(["set", "level", "1"], config: config) == .mark(.dungeon(1)))
    }

    @Test func natoLettersAndNumberWords() {
        #expect(VoiceGrammar.parse("echo seven", config: config) == .cursorTo(column: 6, row: 4))
        #expect(VoiceGrammar.parse("charlie three bomb shop", config: config)
            == .actionAt(column: 2, row: 2, words: ["bomb", "shop"]))
        #expect(VoiceGrammar.parse("echo twelve", config: config) == .cursorTo(column: 11, row: 4))
    }

    @Test func gibberishIsRejected() {
        #expect(VoiceGrammar.parse("", config: config) == nil)
        #expect(VoiceGrammar.parse("hello there", config: config) == nil)
    }

    @Test func overworldActionResolvesMarks() {
        #expect(VoiceGrammar.overworldAction(["bomb", "shop"], config: config) == .mark(.shop(.bomb)))
        #expect(VoiceGrammar.overworldAction(["potion"], config: config) == .mark(.potionShop))
        #expect(VoiceGrammar.overworldAction(["meat"], config: config) == .mark(.shop(.meat)))
        #expect(VoiceGrammar.overworldAction(["armas"], config: config) == .mark(.armos))
        #expect(VoiceGrammar.overworldAction(["white", "sword"], config: config) == .mark(.swordCave(2)))
        #expect(VoiceGrammar.overworldAction(["any", "road", "2"], config: config) == .mark(.anyRoad(2)))
        #expect(VoiceGrammar.overworldAction(["nothing"], config: config) == .mark(.unmarked))
    }

    @Test func overworldActionTakeAnyAndStart() {
        #expect(VoiceGrammar.overworldAction(["take", "any", "potion"], config: config) == .takeAny(.takenPotion))
        #expect(VoiceGrammar.overworldAction(["take", "any"], config: config) == .takeAny(.untaken))
        #expect(VoiceGrammar.overworldAction(["set", "start"], config: config) == .setStart)
        #expect(VoiceGrammar.overworldAction(["clear", "start"], config: config) == .clearStart)
        #expect(VoiceGrammar.overworldAction(["take", "any", "potion"], config: config) != .mark(.potionShop))
    }

    @Test func userAddedPhraseWorks() {
        let c = VoiceConfig()
        c.addPhrase("boom", to: "OW_BombShop")
        #expect(VoiceGrammar.overworldAction(["boom"], config: c) == .mark(.shop(.bomb)))
    }
}
