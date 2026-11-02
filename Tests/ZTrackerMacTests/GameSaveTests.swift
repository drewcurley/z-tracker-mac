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
        timer.start()   // saved while running

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
        // T-192/T-240: a run that was running when saved resumes on reopen (crash recovery).
        #expect(restoredTimer.hasStarted)
        #expect(restoredTimer.isRunning)
    }

    @Test("a run saved while paused reopens paused (T-240)")
    func pausedSaveStaysPaused() {
        let timer = TrackerTimer()
        let t0 = Date(timeIntervalSince1970: 1_000_000)
        timer.start(asOf: t0)
        timer.pause(asOf: t0.addingTimeInterval(10))
        let state = timer.snapshot(asOf: t0.addingTimeInterval(20))
        let restored = TrackerTimer()
        restored.restore(state, resuming: true, realTimeSinceStart: true, asOf: t0.addingTimeInterval(3600))
        #expect(restored.hasStarted)
        #expect(restored.isRunning == false)
        #expect(abs(restored.mainElapsed(asOf: t0.addingTimeInterval(9999)) - 10) < 0.01)
    }

    @Test("real-time restore counts the closed gap of a running run, but not pauses (T-192/T-240)")
    func restartModeElapsed() throws {
        let model = TrackerModel(quest: .first)
        let began = Date(timeIntervalSince1970: 1_000_000)
        let timer = TrackerTimer()
        timer.start(asOf: began)
        timer.pause(asOf: began.addingTimeInterval(10))     // 10s of play…
        timer.resume(asOf: began.addingTimeInterval(610))   // …a 10-minute deliberate pause…
        // …10 more seconds of play, then the app goes away while running (autosave at +620).
        var file = GameSave.makeFile(model: model, timer: timer, date: began.addingTimeInterval(620))
        file.timer = timer.snapshot(asOf: began.addingTimeInterval(620))
        let reopen = began.addingTimeInterval(3620)          // reopened 50 minutes later

        let active = TrackerTimer()
        active.restore(file.timer, resuming: true, realTimeSinceStart: false, asOf: reopen)
        #expect(abs(active.mainElapsed(asOf: reopen) - 20) < 0.01)     // the saved 20s

        let realTime = TrackerTimer()
        realTime.restore(file.timer, resuming: true, realTimeSinceStart: true, asOf: reopen)
        // 20s played + 3000s closed while running; the 600s pause is NOT counted.
        #expect(abs(realTime.mainElapsed(asOf: reopen) - 3020) < 0.01)
        #expect(realTime.isRunning)
    }

    @Test("legacy timer states (no pause data) still restore (T-240)")
    func legacyTimerStateRestores() {
        let began = Date(timeIntervalSince1970: 1_000_000)
        let legacy = TrackerTimer.State(elapsed: 10, hasStarted: true, runStart: began)
        let t = TrackerTimer()
        t.restore(legacy, resuming: true, realTimeSinceStart: true, asOf: began.addingTimeInterval(3600))
        #expect(abs(t.mainElapsed(asOf: began.addingTimeInterval(3600)) - 3600) < 0.01)
        #expect(t.isRunning)
    }

    @Test("the lap survives save/restore (T-240)")
    func lapRestores() {
        let t0 = Date(timeIntervalSince1970: 1_000_000)
        let timer = TrackerTimer()
        timer.start(asOf: t0)
        timer.startLap(asOf: t0.addingTimeInterval(100))
        let state = timer.snapshot(asOf: t0.addingTimeInterval(130))
        let restored = TrackerTimer()
        restored.restore(state, resuming: false, asOf: t0.addingTimeInterval(500))
        #expect(restored.hasLap)
        #expect(abs(restored.lapElapsed(asOf: t0.addingTimeInterval(500)) - 30) < 0.01)
    }

    @Test("absurd saved elapsed values are clamped, not trapped (T-241)")
    func absurdElapsedClamped() {
        let bad = TrackerTimer.State(elapsed: 1e300, hasStarted: true, runStart: nil)
        let t = TrackerTimer()
        t.restore(bad, asOf: Date(timeIntervalSince1970: 0))
        let e = t.mainElapsed(asOf: Date(timeIntervalSince1970: 0))
        #expect(e <= TimerFormatting.maxInterval)
        _ = TimerFormatting.hmsMillis(e)            // must not trap
        _ = TimerFormatting.hms(.infinity)
        _ = TimerFormatting.hms(.nan)
    }

    @Test("completed flag tracks whether Zelda was rescued")
    func completedFlag() {
        let model = TrackerModel(quest: .first)
        let timer = TrackerTimer()
        #expect(GameSave.makeFile(model: model, timer: timer).completed == false)
        model.playerProgress.hasRescuedZelda = true
        #expect(GameSave.makeFile(model: model, timer: timer).completed == true)
    }

    @Test("Notes.txt template seeds empty notes at quest start, never clobbers real notes (T-195)")
    func notesTemplateSeeding() throws {
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("ztracker-notes-\(UUID().uuidString).txt")
        defer { try? FileManager.default.removeItem(at: url) }
        try "Kill sword\nARROW: check bomb shop\n".write(to: url, atomically: true, encoding: .utf8)

        // Empty notes → seeded from the template.
        let fresh = TrackerModel(quest: .first)
        GameSave.seedNotesFromTemplate(into: fresh, at: url)
        #expect(fresh.notes == "Kill sword\nARROW: check bomb shop\n")

        // Existing notes → left untouched (e.g. a resumed save).
        let used = TrackerModel(quest: .first)
        used.notes = "my run"
        GameSave.seedNotesFromTemplate(into: used, at: url)
        #expect(used.notes == "my run")

        // Missing template → no-op, no crash.
        let noFile = FileManager.default.temporaryDirectory.appendingPathComponent("nope-\(UUID().uuidString).txt")
        let m = TrackerModel(quest: .first)
        GameSave.seedNotesFromTemplate(into: m, at: noFile)
        #expect(m.notes == "")
    }

    @Test("timestamped name is well-formed and json")
    func timestampFormat() {
        let name = GameSave.timestampedName(date: Date(timeIntervalSince1970: 1_770_000_000))
        #expect(name.hasPrefix("ztracker-"))
        #expect(name.hasSuffix(".json"))
    }

    @Test("completed-save name is well-formed, timestamped to the second (T-196)")
    func completedNameFormat() {
        let name = GameSave.completedName(date: Date(timeIntervalSince1970: 1_770_000_000))
        #expect(name.hasPrefix("ztracker-completed-"))
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
