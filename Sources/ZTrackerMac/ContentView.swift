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
                MainTrackerPlaceholderView(model: model, options: options, breakout: breakout, onResetApp: onResetApp)
            }
        }
        // Prime live TTS at launch (T-069/T-045): speaking a silent space loads
        // the speech service, the Zoe voice model, and the audio-output stack
        // (coreaudiod) now, on the startup screen, so the first real spoken
        // reminder mid-game is instant. The synth speaks async — no UI hang.
        .task { SpeechEngine.warmUp(preferredVoiceIdentifier: options.preferredVoiceIdentifier) }
        // Remember where the user puts the window, and restore it next launch
        // (T-046.1) — so it reopens on the same display/spot every time.
        .persistWindowFrame("ZTrackerMainWindow")
    }
}

#Preview {
    ContentView(model: TrackerModel(), options: TrackerOptions(), breakout: BreakoutWindows(), onResetApp: {})
}
