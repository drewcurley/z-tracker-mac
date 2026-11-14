import Testing
import Foundation
import TrackerCore
@testable import ZTrackerMac

/// T-248 — voice only confirms (cue + ✓) a command that actually applied, and a recognizer that
/// keeps failing stops instead of restarting silently forever.
@Suite("Voice feedback (T-248)")
@MainActor
struct VoiceFeedbackTests {

    private func controller() -> (VoiceController, TrackerModel) {
        let model = TrackerModel(quest: .first)
        let voice = VoiceController(model: model, focus: TrackerFocusState(), config: VoiceConfig(),
                                    options: TrackerOptions(), timer: TrackerTimer())
        return (voice, model)
    }

    private func firstCell(of model: TrackerModel, dead: Bool) throws -> (Int, Int) {
        for r in 0..<OverworldGrid.rowCount {
            for c in 0..<OverworldGrid.columnCount where model.isDeadSpot(x: c, y: r) == dead {
                return (c, r)
            }
        }
        throw CocoaError(.featureUnsupported)
    }

    @Test("a mark on a real spot applies; the same mark on a dead spot reports failure")
    func overworldMarkReportsResult() throws {
        let (voice, model) = controller()
        let (lc, lr) = try firstCell(of: model, dead: false)
        #expect(voice.execute(.actionAt(column: lc, row: lr, words: ["bomb", "shop"])))
        #expect(model.overworldGrid.mark(column: lc, row: lr) != .unmarked)
        let (dc, dr) = try firstCell(of: model, dead: true)
        #expect(!voice.execute(.actionAt(column: dc, row: dr, words: ["bomb", "shop"])))
    }

    @Test("words that name no overworld action report failure")
    func unknownWordsFail() throws {
        let (voice, model) = controller()
        let (c, r) = try firstCell(of: model, dead: false)
        #expect(!voice.execute(.actionAt(column: c, row: r, words: ["banana"])))
    }

    @Test("navigation always applies")
    func navigationApplies() {
        let (voice, _) = controller()
        #expect(voice.execute(.moveCursor(dcol: 1, drow: 0)))
        #expect(voice.execute(.dungeonTab(3)))
    }

    @Test("'no speech' never counts; three other errors in a row give up")
    func persistentErrorsGiveUp() {
        var n = 0
        #expect(!VoiceController.shouldGiveUp(errorCode: 1110, consecutive: &n))
        #expect(n == 0)
        #expect(!VoiceController.shouldGiveUp(errorCode: 203, consecutive: &n))
        #expect(!VoiceController.shouldGiveUp(errorCode: 203, consecutive: &n))
        #expect(VoiceController.shouldGiveUp(errorCode: 203, consecutive: &n))
    }
}

@Suite("Voice notes apply (T-251)")
@MainActor
struct VoiceNoteApplyTests {
    @Test("a note lands on its own line at the end of Notes")
    func appends() {
        #expect(VoiceController.notes("", appending: "a") == "a")
        #expect(VoiceController.notes("route", appending: "a") == "route\na")
        #expect(VoiceController.notes("route\n", appending: "a") == "route\na")
        let model = TrackerModel(quest: .first)
        let voice = VoiceController(model: model, focus: TrackerFocusState(), config: VoiceConfig(),
                                    options: TrackerOptions(), timer: TrackerTimer())
        #expect(voice.execute(.appendNote(text: "L3 needs ladder")))
        #expect(model.notes == "L3 needs ladder")
    }
}
