import Testing
@testable import TrackerCore

/// Structured voice-command grammar (T-137/T-138) — cursor-driven, region-aware.
struct VoiceGrammarTests {
    // MARK: parse → command shape

    @Test func coordinateOnlyMovesCursor() {
        // "E7" = row E (4), column 7 (index 6).
        #expect(VoiceGrammar.parse("E7") == .cursorTo(column: 6, row: 4))
        #expect(VoiceGrammar.parse("A1") == .cursorTo(column: 0, row: 0))
        #expect(VoiceGrammar.parse("H16") == .cursorTo(column: 15, row: 7))
    }

    @Test func coordinatePlusActionMovesAndMarks() {
        #expect(VoiceGrammar.parse("D5 bomb shop") == .actionAt(column: 4, row: 3, words: ["bomb", "shop"]))
    }

    @Test func actionOnlyActsAtCursor() {
        #expect(VoiceGrammar.parse("potion") == .actionAtCursor(words: ["potion"]))
        #expect(VoiceGrammar.parse("meat shop") == .actionAtCursor(words: ["meat", "shop"]))
    }

    @Test func directionsMoveCursor() {
        #expect(VoiceGrammar.parse("up") == .moveCursor(dcol: 0, drow: -1))
        #expect(VoiceGrammar.parse("go down") == .moveCursor(dcol: 0, drow: 1))
        #expect(VoiceGrammar.parse("right") == .moveCursor(dcol: 1, drow: 0))
        #expect(VoiceGrammar.parse("left") == .moveCursor(dcol: -1, drow: 0))
        // Compass words dropped: "east" no longer moves the cursor.
        #expect(VoiceGrammar.parse("east") == .actionAtCursor(words: ["east"]))
    }

    @Test func regionNavAndStart() {
        #expect(VoiceGrammar.parse("overworld") == .exitToOverworld)
        #expect(VoiceGrammar.parse("leave dungeon") == .exitToOverworld)
        #expect(VoiceGrammar.parse("start") == .gotoStart)
        #expect(VoiceGrammar.parse("go to start") == .gotoStart)
        // "set start" still marks (not a goto).
        #expect(VoiceGrammar.parse("set start") == .actionAtCursor(words: ["set", "start"]))
    }

    @Test func dungeonTabSwitch() {
        #expect(VoiceGrammar.parse("enter level 5") == .dungeonTab(5))
        #expect(VoiceGrammar.parse("level five") == .dungeonTab(5))
        #expect(VoiceGrammar.parse("dungeon 3") == .dungeonTab(3))
    }

    @Test func natoLettersAndNumberWords() {
        // "echo seven" = E7; dodges the "E"/"east" homophone clash.
        #expect(VoiceGrammar.parse("echo seven") == .cursorTo(column: 6, row: 4))
        #expect(VoiceGrammar.parse("charlie three bomb shop") == .actionAt(column: 2, row: 2, words: ["bomb", "shop"]))
        #expect(VoiceGrammar.parse("echo twelve") == .cursorTo(column: 11, row: 4))
    }

    @Test func gibberishIsAnActionAtCursorButResolvesToNothing() {
        #expect(VoiceGrammar.parse("") == nil)
        // Non-coordinate words become an action-at-cursor; overworldAction rejects them.
        #expect(VoiceGrammar.overworldAction(["hello", "there"]) == nil)
    }

    // MARK: overworldAction resolution

    @Test func overworldActionResolvesMarks() {
        #expect(VoiceGrammar.overworldAction(["bomb", "shop"]) == .mark(.shop(.bomb)))
        #expect(VoiceGrammar.overworldAction(["potion"]) == .mark(.potionShop))           // "shop" optional
        #expect(VoiceGrammar.overworldAction(["meat"]) == .mark(.shop(.meat)))
        #expect(VoiceGrammar.overworldAction(["bookshop"]) == .mark(.shop(.book)))         // glued
        #expect(VoiceGrammar.overworldAction(["armas"]) == .mark(.armos))                  // homophone
        #expect(VoiceGrammar.overworldAction(["white", "sword"]) == .mark(.swordCave(2)))
        #expect(VoiceGrammar.overworldAction(["don", "t", "care"]) == .mark(.dontCare))
        #expect(VoiceGrammar.overworldAction(["nothing"]) == .mark(.unmarked))
    }

    @Test func overworldActionTakeAnyAndStart() {
        #expect(VoiceGrammar.overworldAction(["take", "any", "potion"]) == .takeAny(.takenPotion))
        #expect(VoiceGrammar.overworldAction(["take", "any", "heart"]) == .takeAny(.takenHeart))
        #expect(VoiceGrammar.overworldAction(["take", "any"]) == .takeAny(.untaken))
        #expect(VoiceGrammar.overworldAction(["set", "start"]) == .setStart)
        #expect(VoiceGrammar.overworldAction(["clear", "start"]) == .clearStart)
    }

    @Test func takeAnyBeatsPotionShop() {
        // "take any potion" must be a take-any (potion), not a potion shop.
        #expect(VoiceGrammar.overworldAction(["take", "any", "potion"]) != .mark(.potionShop))
    }
}

extension VoiceGrammarTests {
    @Test func setLevelMarksVsEnterSwitches() {
        // Bare / "enter" level → switch the tab.
        #expect(VoiceGrammar.parse("enter level 1") == .dungeonTab(1))
        #expect(VoiceGrammar.parse("level 1") == .dungeonTab(1))
        // A mark verb → mark the CURSOR tile as that dungeon (no coordinate needed).
        #expect(VoiceGrammar.parse("set level 1") == .actionAtCursor(words: ["set", "level", "1"]))
        #expect(VoiceGrammar.parse("mark level 3") == .actionAtCursor(words: ["mark", "level", "3"]))
        // …and that resolves to a dungeon mark for the overworld.
        #expect(VoiceGrammar.overworldAction(["set", "level", "1"]) == .mark(.dungeon(1)))
    }
}
