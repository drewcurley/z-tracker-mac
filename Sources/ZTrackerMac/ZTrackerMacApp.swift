import AppKit
import SwiftUI
import TrackerCore

/// The id of the detachable "Progress" HUD window (T-035.10).
let ProgressHUDWindowID = "z-progress-hud"

/// Forces a regular foreground activation policy (T-019.1). An unbundled
/// SwiftPM executable launches with an accessory/background policy — its windows
/// show and take mouse clicks, but the app never becomes the *key* window, so
/// text fields blink a caret yet keystrokes go to whatever app was active before.
/// Setting `.regular` + activating fixes keyboard focus (needed for Notes now,
/// and hotkeys later) regardless of how the binary is launched.
final class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.regular)
        NSApp.activate(ignoringOtherApps: true)
    }
}

@main
struct ZTrackerMacApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    @State private var model = TrackerModel()
    // Reminder settings (volume, per-category voice/visual, preferred voice)
    // persist across launches (T-004.1); other options are session-only for now.
    @State private var options = TrackerOptions.withReminderPersistence()

    var body: some Scene {
        WindowGroup {
            ContentView(model: model, options: options, onResetApp: resetApp)
        }

        // The break-out Progress HUD (T-035.10) — opened on demand by the
        // "Progress" toggle (a secondary WindowGroup doesn't open at launch).
        // Freely resizable; the HUD image stretches to fill (nearest-neighbor).
        WindowGroup(id: ProgressHUDWindowID) {
            ProgressHUDView(model: model)
                .frame(minWidth: 196, minHeight: 158)
                .onDisappear { model.showProgressWindow = false }
        }
        .defaultSize(width: 600, height: 484)
    }

    /// "Reset App" (T-046): discard the whole run and return to the startup /
    /// quest-selection screen, exactly as if the app were relaunched. Replacing
    /// the model with a fresh instance is the robust way to guarantee a clean
    /// slate (no field left un-reset) and tears down the main tracker view — and
    /// with it the run timer. User settings (`options`) are intentionally kept,
    /// like reopening the app on the same machine.
    private func resetApp() {
        model = TrackerModel()
    }
}
