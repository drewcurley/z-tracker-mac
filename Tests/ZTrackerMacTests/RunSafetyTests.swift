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

    // MARK: Groundhog reset — one press, backup + Undo (T-246)

    private func midRun() -> (TrackerModel, TrackerTimer) {
        let model = TrackerModel(quest: .first)
        model.playerProgress.hasBlueRing = true
        model.playerProgress.hasWoodSword = true
        model.dungeonTracker.dungeon(0).toggleTriforce()
        _ = model.pollReminders()                 // the engine has seen the items
        let timer = TrackerTimer()
        timer.start()
        return (model, timer)
    }

    @Test("one press resets at once and saves a loadable copy of the run first")
    func groundhogResetsAndBacksUp() throws {
        let dir = try tempDir(); defer { try? FileManager.default.removeItem(at: dir) }
        let (model, timer) = midRun()
        let reset = GroundhogReset(directory: dir)
        let backup = try #require(reset.perform(model: model, timer: timer))
        #expect(!model.playerProgress.hasBlueRing)
        #expect(!model.dungeonTracker.dungeon(0).playerHasTriforce)
        #expect(timer.hasLap)
        #expect(backup.lastPathComponent.hasPrefix("ztracker-pre-groundhog-"))
        let saved = try GameSave.readThrowing(backup)
        let copy = TrackerModel(quest: .first)
        copy.restore(saved.model)
        #expect(copy.playerProgress.hasBlueRing)
        #expect(copy.dungeonTracker.dungeon(0).playerHasTriforce)
    }

    @Test("Undo restores items, triforces, the lap and the reminder memory — nothing re-announces")
    func groundhogUndo() throws {
        let dir = try tempDir(); defer { try? FileManager.default.removeItem(at: dir) }
        let (model, timer) = midRun()
        let memory = model.reminderEngine.groundhogMemory
        let lap = timer.lapState
        let reset = GroundhogReset(directory: dir)
        reset.perform(model: model, timer: timer)
        _ = model.pollReminders()                 // a poll lands during the Undo window
        reset.undo(model: model, timer: timer)
        #expect(model.playerProgress.hasBlueRing && model.playerProgress.hasWoodSword)
        #expect(model.dungeonTracker.dungeon(0).playerHasTriforce)
        #expect(timer.lapState == lap)
        #expect(model.reminderEngine.groundhogMemory == memory)
        let again = model.pollReminders().filter {
            if case .triforceCount = $0 { return true }
            if case .remindShortly = $0 { return true }
            return false
        }
        #expect(again.isEmpty)
        #expect(reset.pending == nil)
    }

    @Test("a quick double-tap still undoes to before the first press, with one backup")
    func groundhogDoubleTapUndoesToOriginal() throws {
        let dir = try tempDir(); defer { try? FileManager.default.removeItem(at: dir) }
        let (model, timer) = midRun()
        let reset = GroundhogReset(directory: dir)
        #expect(reset.perform(model: model, timer: timer) != nil)
        #expect(reset.perform(model: model, timer: timer) == nil)   // no second backup
        #expect(try FileManager.default.contentsOfDirectory(atPath: dir.path).count == 1)
        reset.undo(model: model, timer: timer)
        #expect(model.playerProgress.hasBlueRing)
    }

    @Test("after the Undo window, Undo does nothing (the backup file remains)")
    func groundhogUndoExpires() throws {
        let dir = try tempDir(); defer { try? FileManager.default.removeItem(at: dir) }
        let (model, timer) = midRun()
        let reset = GroundhogReset(directory: dir)
        reset.perform(model: model, timer: timer)
        reset.expire()
        reset.undo(model: model, timer: timer)
        #expect(!model.playerProgress.hasBlueRing)
    }

    @Test("the Undo toast runs its action and isn't pushed off screen by a burst of reminders")
    func undoToastSurvivesBurst() {
        let reminders = ReminderController()
        var undone = false
        let id = reminders.toast("Inventory reset", duration: .seconds(60),
                                 action: .init(title: "Undo") { undone = true })
        for n in 0..<8 { reminders.toast("reminder \(n)", duration: .seconds(60)) }
        #expect(reminders.visible.count == 5)
        let item = try? #require(reminders.visible.first { $0.id == id })
        item?.action?.perform()
        #expect(undone)
        reminders.dismiss(id)
        #expect(!reminders.visible.contains { $0.id == id })
    }
}
