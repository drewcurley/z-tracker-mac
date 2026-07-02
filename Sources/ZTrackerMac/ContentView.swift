import SwiftUI
import TrackerCore

/// Root view: shows the startup screen (docs/domain.md § 4.1, T-003) until a
/// quest is selected, then hands off to the main tracker view (a placeholder
/// until a future task builds it for real).
struct ContentView: View {
    var model: TrackerModel

    var body: some View {
        if model.quest == nil {
            StartupView(model: model, onQuestSelected: model.selectQuest)
        } else {
            MainTrackerPlaceholderView(model: model)
        }
    }
}

#Preview {
    ContentView(model: TrackerModel())
}
