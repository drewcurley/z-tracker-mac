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

    /// Notes with the run's finish line set (T-107/T-238): replaces the last existing
    /// "Finished in …" line — e.g. one left by an accidental Zelda toggle — or appends one.
    static func notesWithFinishLine(_ notes: String, line: String) -> String {
        var lines = notes.components(separatedBy: "\n")
        if let i = lines.lastIndex(where: { $0.hasPrefix("Finished in ") }) {
            lines[i] = line
            return lines.joined(separator: "\n")
        }
        return notes + (notes.isEmpty ? "" : "\n") + line
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
    static func read(_ url: URL) -> SaveFile? { try? readThrowing(url) }
    /// Read + decode a save, surfacing *why* it failed (missing, unreadable, or a format this
    /// version can't decode) so callers can tell the user instead of silently doing nothing.
    static func readThrowing(_ url: URL) throws -> SaveFile {
        let data = try Data(contentsOf: url)
        let d = JSONDecoder()
        d.dateDecodingStrategy = .iso8601
        return try d.decode(SaveFile.self, from: data)
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

    /// A timestamped archive name, e.g. `ztracker-unfinished-2026-11-01-143055.json`.
    static func archivedName(_ kind: String, date: Date = Date()) -> String {
        let f = DateFormatter()
        f.locale = Locale(identifier: "en_US_POSIX")
        f.dateFormat = "yyyy-MM-dd-HHmmss"
        return "ztracker-\(kind)-\(f.string(from: date)).json"
    }

    /// Move `url` aside into `directory` under a timestamped `kind` name (never overwriting an
    /// existing file), returning the new location — `nil` if there was nothing to move or the
    /// move failed. Used so a session we can't (or shouldn't) resume is **kept**, loadable via
    /// Load, rather than deleted or silently overwritten by the next autosave (T-238).
    @discardableResult
    static func moveAside(_ url: URL, kind: String, into directory: URL,
                          date: Date = Date()) -> URL? {
        let fm = FileManager.default
        guard fm.fileExists(atPath: url.path) else { return nil }
        let base = archivedName(kind, date: date)
        var dest = directory.appendingPathComponent(base)
        var n = 2
        while fm.fileExists(atPath: dest.path) {
            dest = directory.appendingPathComponent(base.replacingOccurrences(of: ".json", with: "-\(n).json"))
            n += 1
        }
        do { try fm.moveItem(at: url, to: dest); return dest } catch { return nil }
    }

    /// A session left on disk that the user deferred ("Not now") is about to be superseded by
    /// a new run — archive it as `ztracker-unfinished-…` so the new run's autosave can't
    /// overwrite it (T-238). No-op if there's no session file.
    @discardableResult
    static func archiveDeferredSession(from url: URL = lastSessionURL,
                                       into directory: URL = defaultDirectory) -> URL? {
        moveAside(url, kind: "unfinished", into: directory)
    }

    /// "Reset App" discards the run in memory (T-238). Keep it recoverable: an unfinished,
    /// started run is written out as `ztracker-unfinished-…`, and the resume session is cleared
    /// so the next launch doesn't resurrect the run the user just discarded.
    static func archiveRunForReset(model: TrackerModel, timer: TrackerTimer) {
        if model.quest != nil, !model.playerProgress.hasRescuedZelda, timer.hasStarted {
            try? write(makeFile(model: model, timer: timer),
                       to: defaultDirectory.appendingPathComponent(archivedName("unfinished")))
        }
        clearLastSession()
    }

    // MARK: Crash-loop guard (T-241)
    /// Set while a resumed session is being applied and first rendered. If it's still set at
    /// the next launch, that resume crashed the app — so we must not auto-resume it again.
    static let resumeGuardKey = "ztracker.resumeInProgress"
    static func beginResumeGuard(_ defaults: UserDefaults = .standard) {
        defaults.set(true, forKey: resumeGuardKey)
    }
    static func endResumeGuard(_ defaults: UserDefaults = .standard) {
        defaults.removeObject(forKey: resumeGuardKey)
    }

    // MARK: Interactive flows (T-165)

    /// What quitting should do with the on-disk resume session (T-238). Pure, so it's testable.
    enum QuitDecision: Equatable {
        /// No run in memory (startup screen, resume prompt pending, or "Not now") — quit and
        /// leave any on-disk session untouched.
        case proceed
        /// The run is finished — nothing to resume; clear the session and quit.
        case clearSessionAndProceed
        /// "Auto-save and quit" (T-207) — save silently and quit.
        case autosaveAndProceed
        /// Unfinished run — ask Save / Don't Save / Cancel.
        case ask
    }
    static func quitDecision(runInMemory: Bool, finished: Bool, autoSaveOnQuit: Bool) -> QuitDecision {
        guard runInMemory else { return .proceed }
        if finished { return .clearSessionAndProceed }
        return autoSaveOnQuit ? .autosaveAndProceed : .ask
    }

    /// Quit-time confirmation. Returns whether to proceed. Crucially, with **no run in
    /// memory** it never touches `last-session.json` — so quitting while the resume prompt is
    /// up, after "Not now", or via the startup banner's "Update now" keeps the saved run
    /// (previously it was deleted, T-238).
    static func confirmQuitSaving(model: TrackerModel, timer: TrackerTimer,
                                  options: TrackerOptions? = nil) -> Bool {
        switch quitDecision(runInMemory: model.quest != nil,
                            finished: model.playerProgress.hasRescuedZelda,
                            autoSaveOnQuit: options?.autoSaveOnQuit == true) {
        case .proceed:
            return true
        case .clearSessionAndProceed:
            clearLastSession()
            return true
        case .autosaveAndProceed:
            autosave(model: model, timer: timer)
            return true
        case .ask:
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
    }

    /// The outcome of the launch-time look at `last-session.json` (T-238/T-241).
    enum ResumeCheck {
        /// Nothing to offer.
        case none
        /// An unfinished session to offer resuming.
        case offer(SaveFile)
        /// The session couldn't be offered safely; it was moved aside (kept) — explain why.
        case problem(String)
    }

    /// Inspect the last session at launch. A finished session is cleared; one that can't be
    /// decoded, or whose previous resume crashed the app, is **moved aside** (never deleted,
    /// never left for the next autosave to overwrite) and reported. Pure-ish: paths and
    /// defaults are injectable for tests. The prompt itself is presented by `ContentView` as
    /// a SwiftUI overlay — a raw `NSAlert` from `.onAppear` at launch doesn't reliably show.
    static func checkLastSession(url: URL = lastSessionURL, directory: URL = defaultDirectory,
                                 defaults: UserDefaults = .standard) -> ResumeCheck {
        let fm = FileManager.default
        let crashedLastResume = defaults.bool(forKey: resumeGuardKey)
        endResumeGuard(defaults)
        guard fm.fileExists(atPath: url.path) else { return .none }
        if crashedLastResume {
            let kept = moveAside(url, kind: "crashed-resume", into: directory)
            return .problem("Resuming your last run closed the app unexpectedly, so it wasn't resumed again."
                            + (kept.map { " It was kept as “\($0.lastPathComponent)” — you can try Load." } ?? ""))
        }
        do {
            let file = try readThrowing(url)
            guard !file.completed else { clearLastSession(at: url); return .none }
            return .offer(file)
        } catch {
            let kept = moveAside(url, kind: "unreadable-session", into: directory)
            return .problem("Your last run's autosave couldn't be read by this version, so it can't be resumed."
                            + (kept.map { " It was kept as “\($0.lastPathComponent)”." } ?? ""))
        }
    }
    private static func clearLastSession(at url: URL) {
        try? FileManager.default.removeItem(at: url)
    }

    /// Auto-resume (the 5-second countdown) only for a recent session — an old save waits for
    /// an explicit choice instead of restarting its clock on its own (T-240).
    static let autoResumeMaxAge: TimeInterval = 6 * 3600
    static func shouldAutoResume(_ file: SaveFile, now: Date = Date()) -> Bool {
        now.timeIntervalSince(file.savedAt) <= autoResumeMaxAge
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
        guard panel.runModal() == .OK, let url = panel.url else { return }
        let file: SaveFile
        do { file = try readThrowing(url) }
        catch { presentError("Couldn't load “\(url.lastPathComponent)”", error); return }
        if model.quest == nil {
            // Loading from the startup screen supersedes any session the user deferred with
            // "Not now" — keep it as an archive so the loaded run's autosave can't overwrite it.
            archiveDeferredSession()
        } else {
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
