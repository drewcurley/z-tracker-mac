import AppKit
import SwiftUI
import TrackerCore

/// The id of the single main tracker window (T-097).
let MainWindowID = "z-main"

/// The id of the detachable "Progress" HUD window (T-035.10).
let ProgressHUDWindowID = "z-progress-hud"

/// The id of the broken-out Timeline window (T-100).
let TimelineWindowID = "z-timeline"

/// The id of the duplicate Timer window (T-101).
let TimerWindowID = "z-timer"

/// The id of the mid-game Settings window (T-091) — the same preference panel as
/// the startup screen, reachable during play via a gear button or ⌘,.
let SettingsWindowID = "z-settings"

/// The Settings menu command (⌘,), replacing the default app-settings item so it
/// opens our resizable Settings window instead of a native Settings scene.
private struct OpenSettingsButton: View {
    @Environment(\.openWindow) private var openWindow
    var body: some View {
        Button("Settings…") { openWindow(id: SettingsWindowID) }
            .keyboardShortcut(",", modifiers: .command)
    }
}

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
    @State private var options = TrackerOptions.withPersistence()
    /// Which major areas are broken out into their own windows (T-100).
    @State private var breakout = BreakoutWindows()
    /// The run timer (T-035.4), hoisted to app level (T-101) so it can also be
    /// shown in a duplicate window; reset with the app.
    @State private var timer = TrackerTimer()

    var body: some Scene {
        // A single-instance `Window` (not `WindowGroup`) — the tracker is one
        // window (T-097). `WindowGroup` would let macOS spawn multiple full
        // trackers as tabs / new windows (⌘N), which only share the game state and
        // drift on view-local state; that was an unintended default, not a feature.
        Window("Z-Tracker", id: MainWindowID) {
            ContentView(model: model, options: options, breakout: breakout, timer: timer, onResetApp: resetApp)
        }
        .commands {
            // ⌘, opens the mid-game Settings window (T-091) instead of a native
            // Settings scene, so the same panel is reachable during play.
            CommandGroup(replacing: .appSettings) { OpenSettingsButton() }
            // No "New Window" for a single-window app.
            CommandGroup(replacing: .newItem) {}
        }

        // The mid-game Settings window (T-091): a single, resizable window sharing
        // the same `options` as the tracker — the startup preference panel, live.
        Window("Settings", id: SettingsWindowID) {
            SettingsWindowView(options: options)
        }
        .defaultSize(width: 460, height: 660)

        // The broken-out Timeline window (T-100) — opened by the timeline section's
        // pop-out button; its appear/disappear drives the inline placeholder.
        Window("Timeline", id: TimelineWindowID) {
            GameTimelineView(timeline: model.timeline)
                .padding(10)
                .frame(minWidth: 360, minHeight: 140)
                .onAppear { breakout.timelinePoppedOut = true }
                .onDisappear { breakout.timelinePoppedOut = false }
        }
        .defaultSize(width: 720, height: 200)

        // The duplicate Timer window (T-101) — a big stopwatch readout (e.g. for a
        // stream overlay); the main tracker keeps its own timer too.
        Window("Timer", id: TimerWindowID) {
            TimerWindowView(timer: timer)
                .frame(minWidth: 220, minHeight: 90)
        }
        .defaultSize(width: 340, height: 130)

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
        timer = TrackerTimer()   // hoisted (T-101): reset with the app
    }
}
