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

/// The id of the broken-out reminder Log window (T-122).
let LogWindowID = "z-log"

/// The id of the hotkey editor window (T-131).
let HotkeyWindowID = "z-hotkeys"

/// The id of the voice-command editor window (T-139).
let VoiceWindowID = "z-voice"

/// The id of the broken-out dungeon band (map + blockers + notes) window (T-123).
let DungeonBandWindowID = "z-dungeon-band"

/// The id of the broken-out overworld map window (T-124).
let OverworldWindowID = "z-overworld"
/// The broken-out Spot Summary window (T-199) — remaining locations/secrets, popped out
/// so it can stay up (e.g. on a second monitor) instead of a hover/click popover.
let SpotSummaryWindowID = "z-spot-summary"

/// The id of the broadcast **mirror** window (T-178) — a synced full-tracker clone.
let BroadcastWindowID = "z-broadcast"

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
    /// Returns `true` if it's OK to quit; set by `ContentView` (T-109). The default
    /// allows quitting until the app has wired in the timer/options.
    @MainActor static var confirmQuit: () -> Bool = { true }

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.regular)
        NSApp.activate(ignoringOtherApps: true)
    }

    func applicationShouldTerminate(_ sender: NSApplication) -> NSApplication.TerminateReply {
        AppDelegate.confirmQuit() ? .terminateNow : .terminateCancel
    }
}

/// Shows the "quit while the timer is running?" confirmation (T-109), returning
/// whether to proceed. No-op (proceeds) unless the setting is on and the timer is
/// actually running.
@MainActor
func confirmQuitWhileTimerRunning(timer: TrackerTimer, options: TrackerOptions) -> Bool {
    guard options.warnOnCloseWhileTimerRunning, timer.isRunning else { return true }
    let alert = NSAlert()
    alert.messageText = "The run timer is still running."
    alert.informativeText = "Quit anyway? The timer will be lost."
    alert.addButton(withTitle: "Quit")
    alert.addButton(withTitle: "Cancel")
    return alert.runModal() == .alertFirstButtonReturn
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
    /// A separate breakout state for the broadcast mirror (T-178) so it always shows the
    /// full inline layout regardless of what the primary window has popped out.
    @State private var mirrorBreakout = BreakoutWindows()
    /// The run timer (T-035.4), hoisted to app level (T-101) so it can also be
    /// shown in a duplicate window; reset with the app.
    @State private var timer = TrackerTimer()
    /// The reminder controller (toasts + log), hoisted to app level (T-122) so the
    /// broken-out Log window can read the same log the poll loop writes.
    @State private var reminders = ReminderController()
    /// The map-overlay toggles (T-035.2), hoisted to app level (T-124) so the info
    /// icons, the inline overworld, and the broken-out overworld window all share one.
    @State private var overlays = OverworldOverlayState()
    /// The hotkey bindings (T-131), persisted; edited in the hotkey editor window.
    @State private var hotkeys = HotkeyConfig.withPersistence()
    /// The voice-command phrases (T-139), persisted; edited in the voice editor window.
    @State private var voiceConfig = VoiceConfig.withPersistence()
    /// Shared UI focus state (T-133) — the selected dungeon tab (and, later, the
    /// keyboard cursor), so Global hotkeys can drive them.
    @State private var focus = TrackerFocusState()

    var body: some Scene {
        // A single-instance `Window` (not `WindowGroup`) — the tracker is one
        // window (T-097). `WindowGroup` would let macOS spawn multiple full
        // trackers as tabs / new windows (⌘N), which only share the game state and
        // drift on view-local state; that was an unintended default, not a feature.
        Window("Z-Tracker", id: MainWindowID) {
            ContentView(model: model, options: options, breakout: breakout, timer: timer, reminders: reminders, overlays: overlays, hotkeys: hotkeys, voiceConfig: voiceConfig, focus: focus, onResetApp: resetApp)
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
                // The pop-out control (main or mirror) flags its own window (T-178);
                // closing the shared window brings the section back inline in both.
                .onDisappear { breakout.timelinePoppedOut = false; mirrorBreakout.timelinePoppedOut = false }
        }
        .defaultSize(width: 720, height: 200)

        // The broadcast mirror window (T-178) — a second full tracker over the same
        // shared state, so it stays in sync and is mouse-editable. `isMirror` keeps the
        // hotkey dispatcher / voice / poll loop single-instance on the primary; its own
        // `mirrorBreakout` means it always shows the full inline layout. Titled
        // "Broadcast" (not "Z-Tracker") so the primary's key monitor doesn't fire for
        // keystrokes in this window.
        Window("Broadcast", id: BroadcastWindowID) {
            Group {
                if model.quest != nil {
                    MainTrackerPlaceholderView(model: model, options: options, breakout: mirrorBreakout, timer: timer, reminders: reminders, overlays: overlays, hotkeys: hotkeys, voiceConfig: voiceConfig, focus: focus, onResetApp: resetApp, isMirror: true)
                } else {
                    ContentUnavailableView("No run in progress", systemImage: "tv",
                        description: Text("Start a run in the main window and it will mirror here."))
                }
            }
        }
        .defaultSize(width: 900, height: 950)

        // The hotkey editor window (T-131) — opened from Settings' "Edit hotkeys…".
        Window("Hotkeys", id: HotkeyWindowID) {
            HotkeyEditorView(config: hotkeys)
        }
        .defaultSize(width: 480, height: 620)

        // The voice-command editor window (T-139) — opened from Settings.
        Window("Voice Commands", id: VoiceWindowID) {
            VoiceCommandEditorView(config: voiceConfig)
        }
        .defaultSize(width: 480, height: 620)

        // The broken-out reminder Log window (T-122) — opened by the timeline
        // section's "Log" button; a scrollable list of fired reminders with their
        // run-time and descriptive icons.
        Window("Reminder Log", id: LogWindowID) {
            ReminderLogView(log: reminders.log)
                .frame(minWidth: 320, minHeight: 200)
        }
        .defaultSize(width: 420, height: 460)

        // The broken-out dungeon band (T-123) — the room-map grid + blockers +
        // notes in their own window; its appear/disappear drives the inline
        // placeholder.
        Window("Dungeon", id: DungeonBandWindowID) {
            ScrollView {
                DungeonBandView(model: model, options: options, focus: focus).padding(12)
            }
            .frame(minWidth: 700, minHeight: 400)
            .onDisappear { breakout.dungeonBandPoppedOut = false; mirrorBreakout.dungeonBandPoppedOut = false }
        }
        .defaultSize(width: 1000, height: 700)

        // The broken-out overworld map (T-124) — the full overworld in its own
        // window, sharing the model + overlays so edits and highlights stay in sync.
        Window("Overworld", id: OverworldWindowID) {
            ScrollView {
                OverworldSectionView(model: model, options: options, overlays: overlays,
                                     timer: timer, reminders: reminders, focus: focus).padding(12)
            }
            .frame(minWidth: 640, minHeight: 360)
            .onDisappear { breakout.overworldPoppedOut = false; mirrorBreakout.overworldPoppedOut = false }
        }
        .defaultSize(width: 1100, height: 620)

        // The duplicate Timer window (T-101) — a big stopwatch readout (e.g. for a
        // stream overlay); the main tracker keeps its own timer too.
        Window("Timer", id: TimerWindowID) {
            TimerWindowView(timer: timer)
                .frame(minWidth: 220, minHeight: 90)
        }
        .defaultSize(width: 340, height: 130)

        // The broken-out Spot Summary window (T-199) — remaining unique locations + money
        // secrets, recomputed live from the model so it stays current while it's up.
        Window("Spot Summary", id: SpotSummaryWindowID) {
            SpotSummaryWindowView(model: model)
                .frame(minWidth: 240, minHeight: 200)
        }
        .defaultSize(width: 320, height: 460)

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
        // Offer to save the captured render-perf log before discarding the session
        // (T-179.1); canceling the prompt aborts the reset.
        guard PerfLog.confirmSaveOnExit() else { return }
        model = TrackerModel()
        // Reset the hoisted timer in place (T-101/T-109) rather than replacing the
        // instance, so the quit-warning closure captured in `ContentView` keeps
        // pointing at the live timer.
        timer.hardReset()
        reminders.log.clear()   // a fresh run starts with an empty log (T-122)
    }
}
