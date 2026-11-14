import Testing
@testable import TrackerCore

/// T-252 — marks stranded on screens with no spot after a mid-run quest switch.
@Suite("Stale marks after a quest switch (T-252)")
struct StaleMarksTests {
    /// A screen that's live in first quest but always-empty in second.
    private func firstOnlyScreen() throws -> (Int, Int) {
        let first = OverworldInstance(quest: .first), second = OverworldInstance(quest: .second)
        for r in 0..<OverworldGrid.rowCount {
            for c in 0..<OverworldGrid.columnCount
            where !first.alwaysEmpty(x: c, y: r) && second.alwaysEmpty(x: c, y: r) {
                return (c, r)
            }
        }
        throw StaleMarksError.none
    }
    enum StaleMarksError: Error { case none }

    @Test("a mark on a screen the new quest doesn't have becomes stale; it can be cleared")
    func staleAfterSwitch() throws {
        let (c, r) = try firstOnlyScreen()
        let model = TrackerModel(quest: .first)
        model.overworldGrid.setMark(.dungeon(3), column: c, row: r)
        #expect(model.staleMarks().isEmpty)
        #expect(model.staleMarks(for: .second).count == 1)     // the preview before switching
        model.changeQuest(.second)
        #expect(model.isStaleMark(column: c, row: r))
        model.clearStaleMark(column: c, row: r)
        #expect(model.overworldGrid.mark(column: c, row: r) == .unmarked)
        #expect(model.staleMarks().isEmpty)
    }

    @Test("Don't-Care isn't stale; a custom map has no stale marks")
    func notStale() throws {
        let (c, r) = try firstOnlyScreen()
        let model = TrackerModel(quest: .second)
        model.overworldGrid.setMark(.dontCare, column: c, row: r)
        #expect(model.staleMarks().isEmpty)
        model.overworldGrid.setMark(.dungeon(1), column: c, row: r)
        model.customMapImagePath = "/tmp/map.png"
        #expect(model.staleMarks().isEmpty)
    }

    @Test("clearing a stale take-any frees its Items heart slot")
    func staleTakeAnyReleasesSlot() throws {
        let (c, r) = try firstOnlyScreen()
        let model = TrackerModel(quest: .first)
        model.setOverworldTakeAny(.takenHeart, column: c, row: r)
        let slot = try #require(model.overworldGrid.takeAnySlot(column: c, row: r))
        model.changeQuest(.second)
        model.clearStaleMarks()
        #expect(model.overworldGrid.mark(column: c, row: r) == .unmarked)
        #expect(model.playerProgress.takeAnyHearts[slot] == .untaken)
    }
}
