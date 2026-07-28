import AppKit
import Foundation
import SwiftUI
import UniformTypeIdentifiers

/// Render-path instrumentation (T-179) for diagnosing hover-time cost in the real app.
/// Toggle "Log render perf" in Settings → Other, mouse over an area, then — on **Reset
/// App** or **Quit** — you're offered where to save the captured log (so the app can be
/// launched normally from Finder; no terminal needed). Zero overhead when disabled.
///
/// While enabled, the whole process's stdout+stderr are redirected to a temp file via
/// `dup2`, so the capture includes SwiftUI's own `Self._printChanges()` reasons (which
/// write straight to the console and can't be intercepted per line). This is session-
/// global — all console output lands in the file for the rest of the session.
///
/// Per hover you get: the hover event, every instrumented view body that re-evaluated in
/// response (with SwiftUI's reason), and how long the main thread stayed busy afterward
/// (a proxy for the render+layout that hover triggered).
enum PerfLog {
    /// Flipped from the `logRenderPerf` setting. `nonisolated(unsafe)` — a plain diagnostic
    /// flag, only written from the main actor.
    nonisolated(unsafe) static var enabled = false

    /// A monotonically increasing hover id, so a hover and its "main-thread busy" line pair up.
    @MainActor private static var seq = 0

    // MARK: - File capture (T-179.1)

    /// True once stdout/stderr have been redirected to `logURL` this session.
    @MainActor private static var isCapturing = false
    /// The temp file the console is being captured to (nil until logging is first enabled).
    @MainActor private static var logURL: URL?

    /// A dedicated temp subfolder, so startup GC only ever deletes **our** logs.
    private static var logDir: URL {
        FileManager.default.temporaryDirectory.appendingPathComponent("ZTrackerPerfLogs", isDirectory: true)
    }

    /// Delete perf logs left over from a previous run (crash-safe garbage collection).
    /// Call once at launch, before any capture starts.
    @MainActor static func garbageCollectOldLogs() {
        guard !isCapturing else { return }   // never nuke an active capture
        try? FileManager.default.removeItem(at: logDir)
    }

    /// Turn perf logging on/off. On first enable, redirect stdout+stderr to a temp file.
    /// Disabling stops our prints but leaves the redirect in place for the session (there
    /// is no console to restore to when launched from Finder anyway).
    @MainActor static func setEnabled(_ on: Bool) {
        enabled = on
        if on { startCaptureIfNeeded() }
    }

    @MainActor private static func startCaptureIfNeeded() {
        guard !isCapturing else { return }
        try? FileManager.default.createDirectory(at: logDir, withIntermediateDirectories: true)
        let url = logDir.appendingPathComponent("render-perf.log")
        let fd = open(url.path, O_WRONLY | O_CREAT | O_TRUNC, 0o644)
        guard fd >= 0 else { return }
        dup2(fd, fileno(stdout))
        dup2(fd, fileno(stderr))
        close(fd)
        // Line-buffer stdout so a near-hang (the very thing we're diagnosing) still leaves
        // the captured tail on disk without waiting for a clean flush. A tty is line-
        // buffered too, so timings stay comparable to the old terminal runs.
        setvbuf(stdout, nil, _IOLBF, 0)
        logURL = url
        isCapturing = true
    }

    /// Present the on-exit save prompt (used by **Quit** and **Reset App**). Returns
    /// `true` to proceed, `false` to cancel and return to the app. No-op (returns `true`)
    /// when nothing was captured.
    @MainActor static func confirmSaveOnExit() -> Bool {
        guard isCapturing, let url = logURL,
              FileManager.default.fileExists(atPath: url.path) else { return true }
        fflush(stdout); fflush(stderr)

        let alert = NSAlert()
        alert.messageText = "Save the render-perf log?"
        alert.informativeText = "Render-perf logging captured this session to a temporary file. "
            + "Save it before it's discarded?"
        alert.addButton(withTitle: "Save…")       // .alertFirstButtonReturn
        alert.addButton(withTitle: "Don't Save")   // .alertSecondButtonReturn
        alert.addButton(withTitle: "Cancel")       // .alertThirdButtonReturn

        switch alert.runModal() {
        case .alertFirstButtonReturn:              // Save…
            let panel = NSSavePanel()
            panel.title = "Save Render-Perf Log"
            panel.nameFieldStringValue = "render-perf.log"
            panel.allowedContentTypes = [.plainText]
            panel.isExtensionHidden = false
            guard panel.runModal() == .OK, let dest = panel.url else {
                return false                        // save cancelled → back to app, keep file
            }
            try? FileManager.default.removeItem(at: dest)   // overwrite if the user picked an existing name
            try? FileManager.default.copyItem(at: url, to: dest)
            discardAndReopen()
            return true
        case .alertSecondButtonReturn:              // Don't Save → delete the temp file
            discardAndReopen()
            return true
        default:                                    // Cancel → return to the app
            return false
        }
    }

    /// Delete the captured file and, if logging is still on, open a fresh one so a
    /// **continuing** session (Reset App) keeps capturing. On Quit the fresh empty file
    /// is reclaimed by the next launch's GC.
    @MainActor private static func discardAndReopen() {
        if let url = logURL { try? FileManager.default.removeItem(at: url) }
        isCapturing = false
        logURL = nil
        if enabled { startCaptureIfNeeded() }
    }

    // MARK: - Hover / measure

    /// Log a hover (or other) event and measure how long the main thread stays busy handling
    /// the state change it caused — scheduled at the back of the main queue, so it runs after
    /// SwiftUI has re-evaluated/rendered in response.
    @MainActor static func hover(_ label: String) {
        guard enabled else { return }
        seq += 1
        let id = seq
        let t0 = DispatchTime.now().uptimeNanoseconds
        print("── [perf] #\(id) \(label)")
        DispatchQueue.main.async {
            let ms = Double(DispatchTime.now().uptimeNanoseconds - t0) / 1_000_000
            print(String(format: "   [perf] #%d main-thread busy ~%.1f ms", id, ms))
        }
    }

    /// Time a synchronous chunk of work (e.g. a heavy computed property) and log it.
    static func measure<T>(_ label: String, _ work: () -> T) -> T {
        guard enabled else { return work() }
        let t0 = DispatchTime.now().uptimeNanoseconds
        let r = work()
        let ms = Double(DispatchTime.now().uptimeNanoseconds - t0) / 1_000_000
        print(String(format: "   [perf] %@ %.2f ms", label, ms))
        return r
    }
}

// Instrument a view body by adding, as its first statement:
//     let _ = perfTrace()
// which, when logging is on, prints the view's name + SwiftUI's reason for the
// re-evaluation (`_printChanges`) each time the body runs. It's a View extension so
// `Self` inside resolves to the concrete view type being evaluated.
extension View {
    func perfTrace() {
        guard PerfLog.enabled else { return }
        print("   [perf] eval \(type(of: self))")   // which view re-evaluated
        Self._printChanges()                          // + SwiftUI's reason, when available
    }
}
