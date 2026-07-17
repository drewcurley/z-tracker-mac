import SwiftUI
import TrackerCore

/// Root view: shows the startup screen (docs/domain.md § 4.1, T-003) until a
/// quest is selected, then hands off to the main tracker view (a placeholder
/// until a future task builds it for real).
struct ContentView: View {
    var model: TrackerModel
    var options: TrackerOptions
    /// Which major areas are broken out into their own windows (T-100).
    var breakout: BreakoutWindows
    /// The run timer, hoisted to app level (T-101) so it can also show in a window.
    var timer: TrackerTimer
    /// The reminder controller (toasts + log), hoisted to app level (T-122).
    var reminders: ReminderController
    /// The map-overlay toggles, hoisted to app level (T-124).
    var overlays: OverworldOverlayState
    /// The hotkey bindings (T-131); Global keys are dispatched at runtime (T-132).
    var hotkeys: HotkeyConfig
    /// "Reset App" — discard everything and return here to the startup screen
    /// (T-046). Owned by the app (it replaces the model instance).
    var onResetApp: () -> Void

    var body: some View {
        Group {
            if model.quest == nil {
                StartupView(model: model, options: options, onQuestSelected: { quest in
                    // Persist the startup settings at the commit point (T-004.2),
                    // then start the run.
                    options.saveSettings()
                    model.selectQuest(quest)
                })
            } else {
                MainTrackerPlaceholderView(model: model, options: options, breakout: breakout, timer: timer, reminders: reminders, overlays: overlays, hotkeys: hotkeys, onResetApp: onResetApp)
            }
        }
        // Prime live TTS at launch (T-069/T-045): speaking a silent space loads
        // the speech service, the Zoe voice model, and the audio-output stack
        // (coreaudiod) now, on the startup screen, so the first real spoken
        // reminder mid-game is instant. The synth speaks async — no UI hang.
        .task { SpeechEngine.warmUp(preferredVoiceIdentifier: options.preferredVoiceIdentifier) }
        // Gate app termination on the run-timer warning (T-109). Captures the
        // hoisted timer + options; `Reset App` resets the timer in place so this
        // closure stays valid across a reset.
        .onAppear {
            AppDelegate.confirmQuit = { confirmQuitWhileTimerRunning(timer: timer, options: options) }
        }
        // Remember where the user puts the window, and restore it next launch
        // (T-046.1) — so it reopens on the same display/spot every time.
        .persistWindowFrame("ZTrackerMainWindow")
    }
}

#Preview {
    ContentView(model: TrackerModel(), options: TrackerOptions(), breakout: BreakoutWindows(), timer: TrackerTimer(), reminders: ReminderController(), overlays: OverworldOverlayState(), hotkeys: HotkeyConfig(), onResetApp: {})
}
