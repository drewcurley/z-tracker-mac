import Testing
@testable import TrackerCore

@Suite("OverworldRouteTint (GYR cascade)")
struct OverworldRouteTintTests {
    @Test("a marked dungeon 1-8 is always green, regardless of gettable/sometimesEmpty")
    func dungeon1to8AlwaysGreen() {
        for rawIndex in 0...7 { // dungeon 1-8
            for gettable in [true, false] {
                for sometimesEmpty in [true, false] {
                    #expect(OverworldRouteTint.forHighlightedTile(
                        markRawIndex: rawIndex,
                        gettable: gettable,
                        sometimesEmpty: sometimesEmpty) == .green)
                }
            }
        }
    }

    @Test("dungeon 9 (raw index 8) falls through to the gettable/sometimesEmpty logic")
    func dungeon9FallsThrough() {
        // Not a 0...7 dungeon, so a not-gettable dungeon-9 tile reads red.
        #expect(OverworldRouteTint.forHighlightedTile(
            markRawIndex: 8, gettable: false, sometimesEmpty: false) == .red)
        #expect(OverworldRouteTint.forHighlightedTile(
            markRawIndex: 8, gettable: true, sometimesEmpty: false) == .green)
    }

    @Test("not gettable -> red (before the sometimesEmpty check)")
    func notGettableIsRed() {
        // Red wins over yellow: not-gettable is checked first.
        #expect(OverworldRouteTint.forHighlightedTile(
            markRawIndex: -1, gettable: false, sometimesEmpty: true) == .red)
        #expect(OverworldRouteTint.forHighlightedTile(
            markRawIndex: -1, gettable: false, sometimesEmpty: false) == .red)
    }

    @Test("gettable + sometimesEmpty -> yellow")
    func gettableSometimesEmptyIsYellow() {
        #expect(OverworldRouteTint.forHighlightedTile(
            markRawIndex: -1, gettable: true, sometimesEmpty: true) == .yellow)
    }

    @Test("gettable + not sometimesEmpty -> green")
    func gettableNotSometimesEmptyIsGreen() {
        #expect(OverworldRouteTint.forHighlightedTile(
            markRawIndex: -1, gettable: true, sometimesEmpty: false) == .green)
    }

    @Test("a non-dungeon mark (e.g. a shop) still uses the gettable/sometimesEmpty cascade")
    func nonDungeonMarkUsesCascade() {
        // A shop (raw index 16) that isn't gettable reads red.
        #expect(OverworldRouteTint.forHighlightedTile(
            markRawIndex: 16, gettable: false, sometimesEmpty: false) == .red)
        // ...and yellow when gettable + sometimesEmpty.
        #expect(OverworldRouteTint.forHighlightedTile(
            markRawIndex: 16, gettable: true, sometimesEmpty: true) == .yellow)
    }
}
