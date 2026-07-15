import Testing
@testable import TrackerCore

@Suite("Hint phrase decoding (T-039.1)")
struct HintPhrasesTests {
    @Test("11 level hints, one per target, in target order")
    func levelHintsCoverAllTargets() {
        let hints = HintPhrases.levelHints
        #expect(hints.count == HintTarget.count)
        // Targets are exactly 0…10, in order.
        #expect(hints.map(\.target) == Array(0..<HintTarget.count))
    }

    @Test("boss phrases decode to their level")
    func bossPhrases() {
        let byTarget = Dictionary(uniqueKeysWithValues: HintPhrases.levelHints.map { ($0.target, $0) })
        #expect(byTarget[HintTarget.dungeon(1)]?.phrase == "Aquamentus Awaits")
        #expect(byTarget[HintTarget.dungeon(1)]?.meaning == "Level 1")
        #expect(byTarget[HintTarget.dungeon(9)]?.phrase == "entrance to death")
        #expect(byTarget[HintTarget.dungeon(9)]?.meaning == "Level 9")
    }

    @Test("sword phrases decode to the item, not the weapon")
    func swordPhrases() {
        let ws = HintPhrases.levelHints[HintTarget.whiteSwordCave]
        let ms = HintPhrases.levelHints[HintTarget.magicalSwordCave]
        #expect(ws.phrase == "(npc) has (item) at")
        #expect(ws.meaning == "White Sword item")   // the cave's random item
        #expect(ms.phrase == "Meet (npc) at")
        #expect(ms.meaning == "Magical Sword")
    }

    @Test("other hints are informational; feat/sail included, no map effect")
    func otherHints() {
        let phrases = HintPhrases.otherHints.map(\.phrase)
        #expect(phrases.contains("A feat of strength will lead to..."))
        #expect(phrases.contains("Sail across the water..."))
        #expect(phrases.contains("Play a melody..."))
        #expect(phrases.contains("Fire the arrow..."))
        #expect(phrases.contains("Step over the water..."))
        #expect(phrases.contains("No feat of strength..."))
        #expect(phrases.contains("Sail not..."))
        #expect(HintPhrases.otherHints.allSatisfy { !$0.meaning.isEmpty })
    }
}
