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
    /// Sparkle in-place updater (T-211), for the startup banner's "Update now". Optional so
    /// previews render without starting an updater.
    var updater: SparkleUpdaterController? = nil

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
                    // Pre-fill Notes from a user Notes.txt template if present (T-195).
                    GameSave.seedNotesFromTemplate(into: model)
                }, onLoadSavedState: {
                    // Load a saved run (T-177): the picker + apply live in GameSave;
                    // applying sets model.quest, which flips this view to the tracker.
                    GameSave.manualLoad(model: model, timer: timer, options: options)
                }, updater: updater)
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
        // Prime the confirmation sounds too (T-208) — the reference notes the first play lags.
        .task { ConfirmationSound.warmUp() }
        // Apply the chosen dock icon at launch and whenever the setting changes (T-178).
        .onAppear { AppIconController.apply(useDetailed: options.useDetailedAppIcon) }
        .onChange(of: options.useDetailedAppIcon) { _, v in AppIconController.apply(useDetailed: v) }
        // Apply the color theme app-wide at launch and on change (T-187).
        .onAppear { AppThemeController.apply(options.appTheme) }
        .onChange(of: options.appTheme) { _, t in AppThemeController.apply(t) }
        // Wire the render-perf logging switch (T-179). Reclaim any crash-leftover logs
        // first, then honor the current setting (which redirects stdout/stderr to a temp
        // file while on). Runs once — Reset App reuses this ContentView, not a new one.
        .onAppear {
            PerfLog.garbageCollectOldLogs()
            PerfLog.setEnabled(options.logRenderPerf)
        }
        .onChange(of: options.logRenderPerf) { _, v in PerfLog.setEnabled(v) }
        // Gate app termination on the run-timer warning (T-109). Captures the
        // hoisted timer + options; `Reset App` resets the timer in place so this
        // closure stays valid across a reset.
        .onAppear {
            // Quit gate (T-165): the Save / Don't Save / Cancel dialog for an
            // unfinished run supersedes the plain timer-running warning.
            // Chain the perf-log save prompt (T-179.1) after the save-run dialog: save the
            // run first, then offer to keep the captured render-perf log. Either canceling
            // aborts the quit.
            AppDelegate.confirmQuit = {
                GameSave.confirmQuitSaving(model: model, timer: timer, options: options) && PerfLog.confirmSaveOnExit()
            }
            // One-time startup resume check; the dialog below presents it.
            if !resumeChecked {
                resumeChecked = true
                pendingResume = GameSave.pendingResume()
            }
        }
        // Startup "resume your last run?" — a custom overlay (not a confirmationDialog)
        // so it can show a live countdown and auto-resume after 5s (T-192). Any button,
        // or hovering the card, cancels the countdown.
        .overlay {
            if let file = pendingResume {
                ResumeSessionPrompt(
                    savedAt: file.savedAt,
                    onResume: {
                        GameSave.apply(file, to: model, timer: timer, options: options)
                        pendingResume = nil
                    },
                    onDiscard: {
                        GameSave.clearLastSession()
                        pendingResume = nil
                    },
                    onCancel: { pendingResume = nil }
                )
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
