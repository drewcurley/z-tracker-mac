import Testing
@testable import TrackerCore

/// Structured voice-command grammar (T-137).
struct VoiceGrammarTests {
    @Test func overworldMarkWithGluedCoord() {
        // "D5" = row D (3), column 5 (index 4).
        #expect(VoiceGrammar.parse("D5 bomb shop") == .overworldMark(column: 4, row: 3, mark: .shop(.bomb)))
    }

    @Test func overworldMarkWithSpacedCoordAndNumberWord() {
        #expect(VoiceGrammar.parse("d five arrow shop") == .overworldMark(column: 4, row: 3, mark: .shop(.arrow)))
    }

    @Test func coordRowLetterMapsToRowNotColumn() {
        // "A1" = row A (0), column 1 (index 0); "H16" = row H (7), column 16 (index 15).
        #expect(VoiceGrammar.parse("A1 take any") == .overworldTakeAny(column: 0, row: 0, state: .untaken))
        #expect(VoiceGrammar.parse("H16 armos") == .overworldMark(column: 15, row: 7, mark: .armos))
    }

    @Test func variousMarks() {
        #expect(VoiceGrammar.parse("C3 potion shop") == .overworldMark(column: 2, row: 2, mark: .potionShop))
        #expect(VoiceGrammar.parse("C3 white sword") == .overworldMark(column: 2, row: 2, mark: .swordCave(2)))
        #expect(VoiceGrammar.parse("C3 large secret") == .overworldMark(column: 2, row: 2, mark: .secret(.large)))
        #expect(VoiceGrammar.parse("C3 letter") == .overworldMark(column: 2, row: 2, mark: .theLetter))
        #expect(VoiceGrammar.parse("C3 level 5") == .overworldMark(column: 2, row: 2, mark: .dungeon(5)))
        #expect(VoiceGrammar.parse("C3 nothing") == .overworldMark(column: 2, row: 2, mark: .unmarked))
    }

    @Test func dungeonTabSwitch() {
        #expect(VoiceGrammar.parse("enter level 5") == .dungeonTab(5))
        #expect(VoiceGrammar.parse("level five") == .dungeonTab(5))
        #expect(VoiceGrammar.parse("dungeon 3") == .dungeonTab(3))
    }

    @Test func directions() {
        #expect(VoiceGrammar.parse("north") == .moveCursor(dcol: 0, drow: -1))
        #expect(VoiceGrammar.parse("go south") == .moveCursor(dcol: 0, drow: 1))
        #expect(VoiceGrammar.parse("east") == .moveCursor(dcol: 1, drow: 0))
        #expect(VoiceGrammar.parse("west") == .moveCursor(dcol: -1, drow: 0))
    }

    @Test func coordVsTabDisambiguation() {
        // A coordinate present → cell mark, not a tab switch.
        #expect(VoiceGrammar.parse("D5 level 5") == .overworldMark(column: 4, row: 3, mark: .dungeon(5)))
        // No coordinate → tab switch.
        #expect(VoiceGrammar.parse("level 5") == .dungeonTab(5))
    }

    @Test func gibberishReturnsNil() {
        #expect(VoiceGrammar.parse("") == nil)
        #expect(VoiceGrammar.parse("hello there") == nil)
        #expect(VoiceGrammar.parse("D5") == nil)   // coord but no action
    }
}

extension VoiceGrammarTests {
    @Test func gluedAndHomophoneMarks() {
        // "bookshop" as one word still resolves to the book shop.
        #expect(VoiceGrammar.parse("E5 bookshop") == .overworldMark(column: 4, row: 4, mark: .shop(.book)))
        // Common armos mishears.
        #expect(VoiceGrammar.parse("H2 armas") == .overworldMark(column: 1, row: 7, mark: .armos))
        // "don't care" → the dark-X (don't-care) mark.
        #expect(VoiceGrammar.parse("G2 don't care") == .overworldMark(column: 1, row: 6, mark: .dontCare))
        // "any road 2".
        #expect(VoiceGrammar.parse("D5 any road 2") == .overworldMark(column: 4, row: 3, mark: .anyRoad(2)))
    }
}

extension VoiceGrammarTests {
    @Test func twoDigitColumnWords() {
        #expect(VoiceGrammar.parse("E twelve bomb shop") == .overworldMark(column: 11, row: 4, mark: .shop(.bomb)))
        #expect(VoiceGrammar.parse("E12 bomb shop") == .overworldMark(column: 11, row: 4, mark: .shop(.bomb)))
        #expect(VoiceGrammar.parse("H sixteen armos") == .overworldMark(column: 15, row: 7, mark: .armos))
    }
}

extension VoiceGrammarTests {
    @Test func takeAnyStates() {
        #expect(VoiceGrammar.parse("E6 take any potion") == .overworldTakeAny(column: 5, row: 4, state: .takenPotion))
        #expect(VoiceGrammar.parse("E6 take any heart") == .overworldTakeAny(column: 5, row: 4, state: .takenHeart))
        #expect(VoiceGrammar.parse("E6 take any candle") == .overworldTakeAny(column: 5, row: 4, state: .takenCandle))
        #expect(VoiceGrammar.parse("E6 take any") == .overworldTakeAny(column: 5, row: 4, state: .untaken))
        // Regression: "take any potion" must NOT become a potion shop.
        #expect(VoiceGrammar.parse("E6 take any potion") != .overworldMark(column: 5, row: 4, mark: .potionShop))
    }
}
