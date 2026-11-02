import Testing
import Foundation
import TrackerCore
@testable import ZTrackerMac

/// T-238 / T-239 — the save, quit and resume flows must never silently lose or overwrite a
/// run, and one stray keypress must not wipe a run's progress.
@Suite("Run safety (T-238/T-239)", .serialized)
@MainActor
struct RunSafetyTests {

    private func tempDir() throws -> URL {
        let d = FileManager.default.temporaryDirectory
            .appendingPathComponent("ztracker-runsafety-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: d, withIntermediateDirectories: true)
        return d
    }
    private func defaults() -> UserDefaults {
        let name = "ztracker-runsafety-\(UUID().uuidString)"
        let d = UserDefaults(suiteName: name)!
        d.removePersistentDomain(forName: name)
        return d
    }
    private func unfinishedFile(savedAt: Date = Date()) -> GameSave.SaveFile {
        let model = TrackerModel(quest: .first)
        let timer = TrackerTimer()
        timer.start()
        return GameSave.makeFile(model: model, timer: timer, date: savedAt)
    }

    // MARK: Quit decision

    @Test("with no run in memory, quitting never touches the on-disk session")
    func quitWithoutRunKeepsSession() {
        // Startup screen, resume prompt pending, "Not now", or Sparkle "Update now".
        #expect(GameSave.quitDecision(runInMemory: false, finished: false, autoSaveOnQuit: false) == .proceed)
        #expect(GameSave.quitDecision(runInMemory: false, finished: true, autoSaveOnQuit: true) == .proceed)
    }

    @Test("finished runs clear the session; unfinished ones ask or auto-save")
    func quitWithRun() {
        #expect(GameSave.quitDecision(runInMemory: true, finished: true, autoSaveOnQuit: false) == .clearSessionAndProceed)
        #expect(GameSave.quitDecision(runInMemory: true, finished: false, autoSaveOnQuit: false) == .ask)
        #expect(GameSave.quitDecision(runInMemory: true, finished: false, autoSaveOnQuit: true) == .autosaveAndProceed)
    }

    // MARK: Launch-time session check

    @Test("an unfinished session is offered; a finished one is cleared; none is none")
    func checkOffersUnfinished() throws {
        let dir = try tempDir(); defer { try? FileManager.default.removeItem(at: dir) }
        let url = dir.appendingPathComponent("last-session.json")
        let d = defaults()
        if case .none = GameSave.checkLastSession(url: url, directory: dir, defaults: d) {} else {
            Issue.record("expected .none with no file")
        }
        try GameSave.write(unfinishedFile(), to: url)
        guard case .offer = GameSave.checkLastSession(url: url, directory: dir, defaults: d) else {
            Issue.record("expected an offer"); return
        }
        var done = unfinishedFile(); done.completed = true
        try GameSave.write(done, to: url)
        if case .none = GameSave.checkLastSession(url: url, directory: dir, defaults: d) {} else {
            Issue.record("expected a finished session to be cleared")
        }
        #expect(!FileManager.default.fileExists(atPath: url.path))
    }

    @Test("an unreadable session is moved aside (kept) and reported, never left to be overwritten")
    func unreadableSessionMovedAside() throws {
        let dir = try tempDir(); defer { try? FileManager.default.removeItem(at: dir) }
        let url = dir.appendingPathComponent("last-session.json")
        try Data("{ not a save".utf8).write(to: url)
        guard case .problem = GameSave.checkLastSession(url: url, directory: dir, defaults: defaults()) else {
            Issue.record("expected a problem"); return
        }
        #expect(!FileManager.default.fileExists(atPath: url.path))
        let kept = try FileManager.default.contentsOfDirectory(atPath: dir.path)
        #expect(kept.contains { $0.hasPrefix("ztracker-unreadable-session-") })
    }

    @Test("if the previous resume crashed, the session is not offered again (crash-loop guard)")
    func crashedResumeNotReoffered() throws {
        let dir = try tempDir(); defer { try? FileManager.default.removeItem(at: dir) }
        let url = dir.appendingPathComponent("last-session.json")
        let d = defaults()
        try GameSave.write(unfinishedFile(), to: url)
        GameSave.beginResumeGuard(d)              // …and the app never got to end it
        guard case .problem = GameSave.checkLastSession(url: url, directory: dir, defaults: d) else {
            Issue.record("expected a problem"); return
        }
        let kept = try FileManager.default.contentsOfDirectory(atPath: dir.path)
        #expect(kept.contains { $0.hasPrefix("ztracker-crashed-resume-") })
        #expect(d.bool(forKey: GameSave.resumeGuardKey) == false)   // guard cleared
    }

    @Test("a deferred session is archived (not overwritten) when a new run starts")
    func deferredSessionArchived() throws {
        let dir = try tempDir(); defer { try? FileManager.default.removeItem(at: dir) }
        let url = dir.appendingPathComponent("last-session.json")
        try GameSave.write(unfinishedFile(), to: url)
        let a = try #require(GameSave.archiveDeferredSession(from: url, into: dir))
        #expect(a.lastPathComponent.hasPrefix("ztracker-unfinished-"))
        #expect(GameSave.read(a) != nil)          // still loadable
        #expect(!FileManager.default.fileExists(atPath: url.path))
        // Archiving twice in the same second never overwrites the first archive.
        try GameSave.write(unfinishedFile(), to: url)
        let b = try #require(GameSave.archiveDeferredSession(from: url, into: dir))
        #expect(a != b)
        #expect(GameSave.archiveDeferredSession(from: url, into: dir) == nil)   // nothing left
    }

    @Test("old sessions don't auto-resume")
    func staleSessionsWaitForChoice() {
        #expect(GameSave.shouldAutoResume(unfinishedFile(savedAt: Date())))
        #expect(!GameSave.shouldAutoResume(unfinishedFile(savedAt: Date().addingTimeInterval(-7 * 3600))))
    }

    // MARK: Finish line

    @Test("a re-finish replaces the earlier Finished line instead of keeping a stale time")
    func finishLineReplaced() {
        #expect(GameSave.notesWithFinishLine("", line: "Finished in 1:00:00.000") == "Finished in 1:00:00.000")
        #expect(GameSave.notesWithFinishLine("route notes", line: "Finished in 1:00:00.000")
                == "route notes\nFinished in 1:00:00.000")
        #expect(GameSave.notesWithFinishLine("a\nFinished in 0:10:00.000\nb", line: "Finished in 1:00:00.000")
                == "a\nFinished in 1:00:00.000\nb")
    }

    // MARK: Groundhog hotkey guard (T-239)

    @Test("the groundhog hotkey needs a second press within the window")
    func groundhogDoublePress() {
        let t0 = Date(timeIntervalSince1970: 1_000)
        #expect(!GlobalHotkeyDispatcher.isGroundhogConfirmed(armedAt: nil, now: t0))
        #expect(GlobalHotkeyDispatcher.isGroundhogConfirmed(armedAt: t0, now: t0.addingTimeInterval(1.0)))
        #expect(!GlobalHotkeyDispatcher.isGroundhogConfirmed(armedAt: t0, now: t0.addingTimeInterval(3.0)))
        #expect(!GlobalHotkeyDispatcher.isGroundhogConfirmed(armedAt: t0, now: t0.addingTimeInterval(-1)))
    }
}
