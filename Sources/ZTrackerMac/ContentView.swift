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
    var voiceConfig: VoiceConfig
    /// Shared UI focus state (T-133) — selected dungeon tab (+ later, the cursor).
    var focus: TrackerFocusState
    /// "Reset App" — discard everything and return here to the startup screen
    /// (T-046). Owned by the app (it replaces the model instance).
    var onResetApp: () -> Void

    /// Live FPS readout monitor (dev diagnostic) — only sampled while the readout
    /// is on screen (i.e. when `options.showFPS` is on).
    @State private var fpsMonitor = FPSMonitor()
    /// Guards the one-time startup "resume your last run?" prompt (T-165).
    @State private var resumeChecked = false
    /// The autosaved unfinished session offered on launch; drives the resume dialog.
    @State private var pendingResume: GameSave.SaveFile?
    /// Drives the ~60s autosave of the last session (T-165).
    private let autosaveTick = Timer.publish(every: 60, on: .main, in: .common).autoconnect()

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
                MainTrackerPlaceholderView(model: model, options: options, breakout: breakout, timer: timer, reminders: reminders, overlays: overlays, hotkeys: hotkeys, voiceConfig: voiceConfig, focus: focus, onResetApp: onResetApp)
            }
        }
        // Live FPS diagnostic (dev), pinned top-trailing when enabled in Settings.
        .overlay(alignment: .topTrailing) {
            if options.showFPS {
                FPSReadout(monitor: fpsMonitor).padding(6)
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
            // Quit gate (T-165): the Save / Don't Save / Cancel dialog for an
            // unfinished run supersedes the plain timer-running warning.
            AppDelegate.confirmQuit = { GameSave.confirmQuitSaving(model: model, timer: timer) }
            // One-time startup resume check; the dialog below presents it.
            if !resumeChecked {
                resumeChecked = true
                pendingResume = GameSave.pendingResume()
            }
        }
        // Startup "resume your last run?" — a SwiftUI dialog, so it displays reliably
        // once the window is up (a raw NSAlert from onAppear at launch doesn't).
        .confirmationDialog(
            "Resume your last run?",
            isPresented: Binding(get: { pendingResume != nil }, set: { if !$0 { pendingResume = nil } }),
            titleVisibility: .visible
        ) {
            Button("Resume") {
                if let file = pendingResume { GameSave.apply(file, to: model, timer: timer) }
                pendingResume = nil
            }
            Button("Discard", role: .destructive) {
                GameSave.clearLastSession()
                pendingResume = nil
            }
            Button("Cancel", role: .cancel) { pendingResume = nil }
        } message: {
            if let file = pendingResume {
                let when = DateFormatter.localizedString(from: file.savedAt, dateStyle: .medium, timeStyle: .short)
                Text("An unfinished run was auto-saved on \(when). The timer stays paused until you're ready.")
            }
        }
        // ~60s autosave of the last session while a run is active and unfinished.
        .onReceive(autosaveTick) { _ in
            if model.quest != nil, !model.playerProgress.hasRescuedZelda {
                GameSave.autosave(model: model, timer: timer)
            }
        }
        // Remember where the user puts the window, and restore it next launch
        // (T-046.1) — so it reopens on the same display/spot every time.
        .persistWindowFrame("ZTrackerMainWindow")
    }
}

#Preview {
    ContentView(model: TrackerModel(), options: TrackerOptions(), breakout: BreakoutWindows(), timer: TrackerTimer(), reminders: ReminderController(), overlays: OverworldOverlayState(), hotkeys: HotkeyConfig(), voiceConfig: VoiceConfig(), focus: TrackerFocusState(), onResetApp: {})
}
