import Testing
@testable import TrackerCore

@Suite("OverworldInstance terrain masks")
struct OverworldInstanceMaskTests {
    /// Count how many of the 128 screens satisfy a predicate.
    private func count(_ inst: OverworldInstance, _ pred: (OverworldInstance, Int, Int) -> Bool) -> Int {
        var n = 0
        for y in 0..<8 { for x in 0..<16 where pred(inst, x, y) { n += 1 } }
        return n
    }

    /// Transcription check: the `X` count of each literal mask must match the
    /// reference source exactly (counted from `OverworldData.fs`). A single
    /// mistyped square shifts one of these.
    @Test("literal mask X-counts match the reference source")
    func literalMaskCounts() {
        #expect(Masks.armos.rows.joined().filter { $0 == "X" }.count == 5)
        #expect(Masks.raftable.rows.joined().filter { $0 == "X" }.count == 2)
        #expect(Masks.firstQuestBombable.rows.joined().filter { $0 == "X" }.count == 22)
        #expect(Masks.secondQuestBombable.rows.joined().filter { $0 == "X" }.count == 21)
        #expect(Masks.firstQuestBurnable.rows.joined().filter { $0 == "X" }.count == 16)
        #expect(Masks.secondQuestBurnable.rows.joined().filter { $0 == "X" }.count == 14)
        #expect(Masks.firstQuestPowerBraceletable.rows.joined().filter { $0 == "X" }.count == 4)
        #expect(Masks.secondQuestPowerBraceletable.rows.joined().filter { $0 == "X" }.count == 7)
        #expect(Masks.secondQuestLadderable.rows.joined().filter { $0 == "X" }.count == 2)
        #expect(Masks.firstQuestWhistleable.rows.joined().filter { $0 == "X" }.count == 1)
        #expect(Masks.secondQuestWhistleable.rows.joined().filter { $0 == "X" }.count == 10)
        #expect(Masks.firstQuestGravePushable.rows.joined().filter { $0 == "X" }.count == 1)
        #expect(Masks.secondQuestGravePushable.rows.joined().filter { $0 == "X" }.count == 1)
        #expect(Masks.firstQuestAlwaysEmpty.rows.joined().filter { $0 == "X" }.count == 55)
        #expect(Masks.secondQuestAlwaysEmpty.rows.joined().filter { $0 == "X" }.count == 48)
        #expect(Masks.mixedQuestSometimesEmpty.rows.joined().filter { $0 == "X" }.count == 31)
    }

    @Test("derived masks match the reference's computed X-counts")
    func derivedMaskCounts() {
        #expect(Masks.mixedQuestAlwaysEmpty.rows.joined().filter { $0 == "X" }.count == 35)
        #expect(Masks.secondQuestOnly.rows.joined().filter { $0 == "X" }.count == 20)
        #expect(Masks.firstQuestOnly.rows.joined().filter { $0 == "X" }.count == 13)
    }

    @Test("armos is quest-independent and sits at the five known screens")
    func armosCoords() {
        let expected: Set<[Int]> = [[12, 1], [4, 2], [4, 3], [13, 3], [14, 4]]
        for quest in OverworldQuest.allCases {
            let inst = OverworldInstance(quest: quest)
            var found: Set<[Int]> = []
            for y in 0..<8 { for x in 0..<16 where inst.hasArmos(x: x, y: y) { found.insert([x, y]) } }
            #expect(found == expected)
        }
    }
}

@Suite("OverworldInstance quest branching")
struct OverworldInstanceQuestTests {
    private func count(_ inst: OverworldInstance, _ pred: (OverworldInstance, Int, Int) -> Bool) -> Int {
        var n = 0
        for y in 0..<8 { for x in 0..<16 where pred(inst, x, y) { n += 1 } }
        return n
    }

    @Test("ladderable is empty in first quest, the 2Q mask otherwise")
    func ladderableQuest() {
        #expect(count(OverworldInstance(quest: .first)) { i, x, y in i.ladderable(x: x, y: y) } == 0)
        for quest in [OverworldQuest.second, .mixedFirst, .mixedSecond] {
            #expect(count(OverworldInstance(quest: quest)) { i, x, y in i.ladderable(x: x, y: y) } == 2)
        }
    }

    @Test("alwaysEmpty uses per-quest tables; mixed uses the derived AND mask")
    func alwaysEmptyQuest() {
        #expect(count(OverworldInstance(quest: .first)) { i, x, y in i.alwaysEmpty(x: x, y: y) } == 55)
        #expect(count(OverworldInstance(quest: .second)) { i, x, y in i.alwaysEmpty(x: x, y: y) } == 48)
        #expect(count(OverworldInstance(quest: .mixedFirst)) { i, x, y in i.alwaysEmpty(x: x, y: y) } == 35)
        #expect(count(OverworldInstance(quest: .mixedSecond)) { i, x, y in i.alwaysEmpty(x: x, y: y) } == 35)
    }

    @Test("mixed-quest OR predicates equal the union of the two single-quest masks")
    func mixedIsOr() {
        let first = OverworldInstance(quest: .first)
        let second = OverworldInstance(quest: .second)
        let mixed = OverworldInstance(quest: .mixedFirst)
        for y in 0..<8 {
            for x in 0..<16 {
                #expect(mixed.whistleable(x: x, y: y)
                    == (first.whistleable(x: x, y: y) || second.whistleable(x: x, y: y)))
                #expect(mixed.bombable(x: x, y: y)
                    == (first.bombable(x: x, y: y) || second.bombable(x: x, y: y)))
                #expect(mixed.burnable(x: x, y: y)
                    == (first.burnable(x: x, y: y) || second.burnable(x: x, y: y)))
                #expect(mixed.powerBraceletable(x: x, y: y)
                    == (first.powerBraceletable(x: x, y: y) || second.powerBraceletable(x: x, y: y)))
            }
        }
    }

    @Test("sometimesEmpty is empty for single quests, the mixed mask for mixed quests")
    func sometimesEmptyQuest() {
        #expect(count(OverworldInstance(quest: .first)) { i, x, y in i.sometimesEmpty(x: x, y: y) } == 0)
        #expect(count(OverworldInstance(quest: .second)) { i, x, y in i.sometimesEmpty(x: x, y: y) } == 0)
        #expect(count(OverworldInstance(quest: .mixedFirst)) { i, x, y in i.sometimesEmpty(x: x, y: y) } == 31)
        #expect(count(OverworldInstance(quest: .mixedSecond)) { i, x, y in i.sometimesEmpty(x: x, y: y) } == 31)
    }

    @Test("nothingable = not-always-empty and not gated by any tool")
    func nothingable() {
        let inst = OverworldInstance(quest: .first)
        for y in 0..<8 {
            for x in 0..<16 {
                let expected = !inst.alwaysEmpty(x: x, y: y)
                    && !(inst.bombable(x: x, y: y) || inst.burnable(x: x, y: y)
                         || inst.ladderable(x: x, y: y) || inst.powerBraceletable(x: x, y: y)
                         || inst.raftable(x: x, y: y) || inst.whistleable(x: x, y: y))
                #expect(inst.nothingable(x: x, y: y) == expected)
            }
        }
    }
}
