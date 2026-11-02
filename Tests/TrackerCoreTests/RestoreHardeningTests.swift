import Testing
import Foundation
@testable import TrackerCore

/// T-241 — a corrupt or hand-edited save must load safely (sanitized), never trap. Before,
/// several decoded values reached preconditions / unchecked indexing, and the 5-second
/// auto-resume turned a bad autosave into a crash on every launch.
@Suite("Restore hardening (T-241)")
@MainActor
struct RestoreHardeningTests {

    @Test("out-of-range dungeon box items are sanitized to unknown, not trapped")
    func badBoxItemsSanitized() {
        let model = TrackerModel(quest: .first)
        var s = model.snapshot()
        s.tracker.finalBox.cellCurrent = 9_999
        s.tracker.ladderBox.cellCurrent = -42
        if !s.tracker.dungeons.isEmpty, !s.tracker.dungeons[0].boxes.isEmpty {
            s.tracker.dungeons[0].boxes[0].cellCurrent = Int.max
        }
        let restored = TrackerModel(quest: .first)
        restored.restore(s)
        #expect(restored.dungeonTracker.finalBoxOf1Or4.cellCurrent == -1)
        #expect(restored.dungeonTracker.ladderBox.cellCurrent == -1)
        #expect(restored.dungeonTracker.dungeons[0].baseBoxes[0].cellCurrent == -1)
    }

    @Test("a short or long levelHints array is normalized to HintTarget.count")
    func levelHintsNormalized() {
        let model = TrackerModel(quest: .first)
        var s = model.snapshot()
        s.levelHints = [.unknown]
        let a = TrackerModel(quest: .first); a.restore(s)
        #expect(a.levelHints.count == HintTarget.count)
        s.levelHints = Array(repeating: .unknown, count: 40)
        let b = TrackerModel(quest: .first); b.restore(s)
        #expect(b.levelHints.count == HintTarget.count)
    }

    @Test("an absurd recorder index is bounded so stepping can't overflow")
    func recorderIndexBounded() {
        let model = TrackerModel(quest: .first)
        var s = model.snapshot()
        s.recorderDestinationIndex = Int.max
        let r = TrackerModel(quest: .first); r.restore(s)
        #expect(r.recorderDestinationIndex <= 10_000)
        r.recorderDestinationIndex += 1          // must not overflow
    }

    @Test("take-any links outside the 4 slots are unlinked")
    func takeAnyLinksSanitized() {
        let g = OverworldGrid()
        var s = g.state
        s.takeAnySlotLinks[0] = 99
        s.takeAnySlotLinks[1] = 2
        let r = OverworldGrid(); r.restore(s)
        #expect(r.takeAnySlot(column: 0, row: 0) == nil)
        #expect(r.takeAnySlot(column: 1, row: 0) == 2)
    }

    @Test("a save without an optional sub-state resets it instead of keeping the current run's")
    func missingSubstateResets() {
        let saved = TrackerModel(quest: .first)
        var s = saved.snapshot()
        s.commentary = nil                        // e.g. a pre-commentary save
        let live = TrackerModel(quest: .first)
        live.commentary.runner1Name = "Alice"     // left over from the run that was open
        live.restore(s)
        #expect(live.commentary.runner1Name == CommentaryLayer().runner1Name)
    }

    @Test("a spoiler cave line with no coordinate is skipped, not trapped")
    func spoilerLineWithoutCoordinate() {
        _ = SpoilerLog.parse("Location contains: MAGICAL SWORD CAVE\nLocation  contains: X\n")
    }
}
