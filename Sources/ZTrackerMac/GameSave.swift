import Foundation
import AppKit
import TrackerCore

/// Save/Load service (T-165, Phase 2). Combines the model snapshot (T-164) and the
/// timer state into one versioned JSON `SaveFile`, and owns the on-disk layout:
/// manual saves go to a user-chosen file (default `~/Documents/ztracker/`), and a
/// rolling `last-session.json` autosave in that same folder is the resume source and
/// crash backstop.
@MainActor
enum GameSave {
    /// The whole-app save payload. `completed` is stamped at save time from the live
    /// model so the loader can decide about the resume prompt without decoding the
    /// full progress sub-state.
    struct SaveFile: Codable {
        var version = 1
        var savedAt: Date
        var completed: Bool
        var model: TrackerModel.State
        var timer: TrackerTimer.State
    }

    // MARK: Paths
    static var defaultDirectory: URL {
        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first
            ?? URL(fileURLWithPath: NSHomeDirectory()).appendingPathComponent("Documents")
        return docs.appendingPathComponent("ztracker", isDirectory: true)
    }
    static var lastSessionURL: URL { defaultDirectory.appendingPathComponent("last-session.json") }
    /// Optional user-provided template that pre-fills the Notes box at quest start
    /// (reference `WPFUI.fs:1223`), living alongside the saves in `~/Documents/ztracker/`.
    static var notesTemplateURL: URL { defaultDirectory.appendingPathComponent("Notes.txt") }

    /// Seed the Notes box from `Notes.txt` at quest start (T-195, reference parity). No-op if
    /// the template is absent or the notes already have content (e.g. a resumed save), so it
    /// never clobbers real work. The `url` is injectable for tests.
    static func seedNotesFromTemplate(into model: TrackerModel, at url: URL = notesTemplateURL) {
        guard model.notes.isEmpty,
              let text = try? String(contentsOf: url, encoding: .utf8) else { return }
        model.notes = text
    }

    /// A timestamped filename for a manual save, e.g. `ztracker-2026-07-20-1430.json`.
    static func timestampedName(date: Date = Date()) -> String {
        let f = DateFormatter()
        f.locale = Locale(identifier: "en_US_POSIX")
        f.dateFormat = "yyyy-MM-dd-HHmm"
        return "ztracker-\(f.string(from: date)).json"
    }

    /// A timestamped filename for an auto-save written when a run finishes (T-196),
    /// e.g. `ztracker-completed-2026-07-20-143055.json`. Seconds are included so back-to-back
    /// finishes never collide. Mirrors the reference's `zt-save-completed-…` (SaveAndLoad.fs:382).
    static func completedName(date: Date = Date()) -> String {
        let f = DateFormatter()
        f.locale = Locale(identifier: "en_US_POSIX")
        f.dateFormat = "yyyy-MM-dd-HHmmss"
        return "ztracker-completed-\(f.string(from: date)).json"
    }

    /// True while a save is being applied, so the completion observer doesn't fire a
    /// (redundant) completed-save when a *finished* run is loaded (T-196; the reference
    /// guards the same case with `not isCurrentlyLoadingASave`).
    @MainActor static private(set) var isApplyingSave = false

    @discardableResult
    static func ensureDirectory() -> Bool {
        (try? FileManager.default.createDirectory(at: defaultDirectory, withIntermediateDirectories: true)) != nil
    }

    // MARK: Build / apply
    static func makeFile(model: TrackerModel, timer: TrackerTimer, date: Date = Date()) -> SaveFile {
        SaveFile(savedAt: date, completed: model.playerProgress.hasRescuedZelda,
                 model: model.snapshot(), timer: timer.snapshot())
    }
    /// Restore a decoded save into the live model + timer. The timer **resumes** by
    /// default (T-192, crash recovery — a reopened session keeps timing instead of
    /// silently staying paused), honoring the real-time-vs-active restart mode when
    /// `options` is supplied.
    static func apply(_ file: SaveFile, to model: TrackerModel, timer: TrackerTimer,
                      options: TrackerOptions? = nil) {
        // Suppress save-on-completion while a finished run is being loaded. The flag is
        // cleared on the next runloop tick, after the `hasRescuedZelda` onChange (which
        // SwiftUI defers to the following view update) has already seen it set.
        isApplyingSave = true
        defer { DispatchQueue.main.async { isApplyingSave = false } }
        model.restore(file.model)
        timer.restore(file.timer, resuming: true,
                      realTimeSinceStart: options?.timerRealTimeSinceStart ?? false)
    }

    /// Auto-save a finished run to a timestamped `ztracker-completed-…` file when the
    /// "Save on completion" option is on (T-196). No-op while a save is being loaded, so
    /// loading a finished run doesn't spawn a duplicate. Best-effort (errors swallowed).
    @MainActor
    static func saveOnCompletionIfEnabled(model: TrackerModel, timer: TrackerTimer,
                                          options: TrackerOptions) {
        guard options.saveOnCompletion, !isApplyingSave else { return }
        try? write(makeFile(model: model, timer: timer),
                   to: defaultDirectory.appendingPathComponent(completedName()))
    }

    // MARK: Disk I/O
    static func encode(_ file: SaveFile) throws -> Data {
        let e = JSONEncoder()
        e.outputFormatting = [.prettyPrinted, .sortedKeys]
        e.dateEncodingStrategy = .iso8601
        return try e.encode(file)
    }
    static func write(_ file: SaveFile, to url: URL) throws {
        ensureDirectory()
        try encode(file).write(to: url, options: .atomic)
    }
    static func read(_ url: URL) -> SaveFile? {
        guard let data = try? Data(contentsOf: url) else { return nil }
        let d = JSONDecoder()
        d.dateDecodingStrategy = .iso8601
        return try? d.decode(SaveFile.self, from: data)
    }

    // MARK: Autosave / last session (resume)
    /// Best-effort autosave to `last-session.json`; failures are swallowed (it's a
    /// backstop, not a user action).
    static func autosave(model: TrackerModel, timer: TrackerTimer) {
        try? write(makeFile(model: model, timer: timer), to: lastSessionURL)
    }
    static func clearLastSession() {
        try? FileManager.default.removeItem(at: lastSessionURL)
    }
    /// The last autosaved session, if one exists on disk.
    static func lastSession() -> SaveFile? { read(lastSessionURL) }

    // MARK: Interactive flows (T-165)

    /// Quit-time confirmation. Nothing to save (still on the startup screen, or the run
    /// is finished) → allow the quit and clear the resume session. Otherwise the
    /// standard Save / Don't Save / Cancel: Save flushes `last-session.json`, Don't Save
    /// discards it (choice A), Cancel aborts the quit. Returns whether to proceed.
    static func confirmQuitSaving(model: TrackerModel, timer: TrackerTimer,
                                  options: TrackerOptions? = nil) -> Bool {
        guard model.quest != nil, !model.playerProgress.hasRescuedZelda else {
            clearLastSession()       // finished or not started → no run to resume
            return true
        }
        // "Auto-save and quit" (T-207): skip the dialog entirely — autosave the run and quit.
        // (Resume on next launch still offers it.)
        if options?.autoSaveOnQuit == true {
            autosave(model: model, timer: timer)
            return true
        }
        let alert = NSAlert()
        alert.messageText = "Save your run before quitting?"
        alert.informativeText = "You haven't rescued Zelda yet. Save so you can resume where you left off."
        alert.addButton(withTitle: "Save")        // .alertFirstButtonReturn
        alert.addButton(withTitle: "Don't Save")  // .alertSecondButtonReturn
        alert.addButton(withTitle: "Cancel")      // .alertThirdButtonReturn
        switch alert.runModal() {
        case .alertFirstButtonReturn:  autosave(model: model, timer: timer); return true
        case .alertSecondButtonReturn: clearLastSession(); return true
        default:                       return false
        }
    }

    /// The unfinished session to offer resuming on launch, or nil (clearing a finished
    /// one). The prompt itself is presented by `ContentView` as a SwiftUI dialog —
    /// firing a raw `NSAlert` from `.onAppear` at launch doesn't reliably display,
    /// since the app isn't active yet.
    static func pendingResume() -> SaveFile? {
        guard let file = lastSession() else { return nil }
        guard !file.completed else { clearLastSession(); return nil }
        return file
    }

    /// Manual Save button → a timestamped file via the standard save panel (defaulting
    /// to `~/Documents/ztracker/`).
    static func manualSave(model: TrackerModel, timer: TrackerTimer) {
        ensureDirectory()
        let panel = NSSavePanel()
        panel.directoryURL = defaultDirectory
        panel.nameFieldStringValue = timestampedName()
        panel.allowedContentTypes = [.json]
        guard panel.runModal() == .OK, let url = panel.url else { return }
        do { try write(makeFile(model: model, timer: timer), to: url) }
        catch { presentError("Couldn't save", error) }
    }

    /// Manual Load button → pick a save file (confirming, since it replaces the current
    /// in-memory run).
    static func manualLoad(model: TrackerModel, timer: TrackerTimer, options: TrackerOptions? = nil) {
        let panel = NSOpenPanel()
        panel.directoryURL = defaultDirectory
        panel.allowedContentTypes = [.json]
        panel.allowsMultipleSelection = false
        guard panel.runModal() == .OK, let url = panel.url, let file = read(url) else { return }
        if model.quest != nil {
            let confirm = NSAlert()
            confirm.messageText = "Replace the current run?"
            confirm.informativeText = "Loading this save discards the tracker's current state."
            confirm.addButton(withTitle: "Load")
            confirm.addButton(withTitle: "Cancel")
            guard confirm.runModal() == .alertFirstButtonReturn else { return }
        }
        apply(file, to: model, timer: timer, options: options)
    }

    private static func presentError(_ title: String, _ error: Error) {
        let a = NSAlert()
        a.messageText = title
        a.informativeText = error.localizedDescription
        a.runModal()
    }
}
