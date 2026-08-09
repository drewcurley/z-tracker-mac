import Testing
import Foundation
import TrackerCore
@testable import ZTrackerMac

/// T-165 — the Save/Load file service: build → encode → write → read → apply, the
/// completed flag, and the timestamp format. (The AppKit panels/alerts aren't unit-
/// tested; this covers the pure logic they call.)
@MainActor
struct GameSaveTests {
    @Test("a save file round-trips through disk and restores the run")
    func fileRoundTrips() throws {
        let model = TrackerModel(quest: .first)
        model.selectQuest(.first)
        model.overworldGrid.setMark(.shop(.bomb), column: 4, row: 3)
        model.notes = "mid run"
        let timer = TrackerTimer()
        timer.start()
        timer.pause()

        let file = GameSave.makeFile(model: model, timer: timer)
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("ztracker-test-\(UUID().uuidString).json")
        defer { try? FileManager.default.removeItem(at: url) }
        try GameSave.write(file, to: url)

        let read = try #require(GameSave.read(url))
        let restoredModel = TrackerModel(quest: .first)
        let restoredTimer = TrackerTimer()
        GameSave.apply(read, to: restoredModel, timer: restoredTimer)

        #expect(restoredModel.overworldGrid.mark(column: 4, row: 3) == .shop(.bomb))
        #expect(restoredModel.notes == "mid run")
        // T-192: a reopened session now auto-resumes (crash recovery) rather than
        // staying paused, so long as the run had started.
        #expect(restoredTimer.hasStarted)
        #expect(restoredTimer.isRunning)
    }

    @Test("real-time restart mode counts the closed gap; active mode does not (T-192)")
    func restartModeElapsed() throws {
        let model = TrackerModel(quest: .first)
        let began = Date(timeIntervalSince1970: 1_000_000)
        let timer = TrackerTimer()
        timer.start(asOf: began)
        timer.pause(asOf: began.addingTimeInterval(10))   // 10s of active play, then paused

        let file = GameSave.makeFile(model: model, timer: timer)
        // Reopen an hour later.
        let reopen = began.addingTimeInterval(3600)

        let active = TrackerTimer()
        active.restore(file.timer, resuming: true, realTimeSinceStart: false, asOf: reopen)
        #expect(abs(active.mainElapsed(asOf: reopen) - 10) < 0.01)   // resumes at the saved 10s

        let realTime = TrackerTimer()
        realTime.restore(file.timer, resuming: true, realTimeSinceStart: true, asOf: reopen)
        #expect(abs(realTime.mainElapsed(asOf: reopen) - 3600) < 0.01) // wall-clock since Go
    }

    @Test("completed flag tracks whether Zelda was rescued")
    func completedFlag() {
        let model = TrackerModel(quest: .first)
        let timer = TrackerTimer()
        #expect(GameSave.makeFile(model: model, timer: timer).completed == false)
        model.playerProgress.hasRescuedZelda = true
        #expect(GameSave.makeFile(model: model, timer: timer).completed == true)
    }

    @Test("timestamped name is well-formed and json")
    func timestampFormat() {
        let name = GameSave.timestampedName(date: Date(timeIntervalSince1970: 1_770_000_000))
        #expect(name.hasPrefix("ztracker-"))
        #expect(name.hasSuffix(".json"))
    }

    @Test("reading a missing / garbage file returns nil, not a crash")
    func toleratesBadInput() {
        let missing = FileManager.default.temporaryDirectory.appendingPathComponent("nope-\(UUID().uuidString).json")
        #expect(GameSave.read(missing) == nil)
        let garbage = FileManager.default.temporaryDirectory.appendingPathComponent("garbage-\(UUID().uuidString).json")
        try? "not json".data(using: .utf8)!.write(to: garbage)
        defer { try? FileManager.default.removeItem(at: garbage) }
        #expect(GameSave.read(garbage) == nil)
    }
}
