import SwiftUI
import TrackerCore

/// Root view: shows the startup screen (docs/domain.md § 4.1, T-003) until a
/// quest is selected, then hands off to the main tracker view (a placeholder
/// until a future task builds it for real).
struct ContentView: View {
    var model: TrackerModel
    var options: TrackerOptions
    /// "Reset App" — discard everything and return here to the startup screen
    /// (T-046). Owned by the app (it replaces the model instance).
    var onResetApp: () -> Void

    var body: some View {
        Group {
            if model.quest == nil {
                StartupView(model: model, options: options, onQuestSelected: model.selectQuest)
            } else {
                MainTrackerPlaceholderView(model: model, options: options, onResetApp: onResetApp)
            }
        }
        // Warm the audio-output stack at launch, off the main thread (T-045),
        // so the first spoken reminder doesn't pay the coreaudiod cold-start
        // cost mid-game — and warming it never hangs the UI. Fires once here on
        // the very first appearance (the startup screen), before any reminder.
        .task { ReminderAudioPlayer.primeAudioStack() }
    }
}

#Preview {
    ContentView(model: TrackerModel(), options: TrackerOptions(), onResetApp: {})
}
