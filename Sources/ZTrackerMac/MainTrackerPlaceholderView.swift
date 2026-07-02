import SwiftUI
import TrackerCore

/// Stands in for the real main tracker view (dungeon items, overworld map,
/// blockers, timeline — docs/domain.md § 4.2 onward), which is a future
/// task's scope. Confirms the startup screen actually handed off the
/// selected quest + toggle state, so this placeholder is a real integration
/// check, not just a label.
struct MainTrackerPlaceholderView: View {
    var model: TrackerModel

    var body: some View {
        VStack(spacing: 12) {
            Text("Main tracker view — not built yet")
                .font(.title2)
            if let quest = model.quest {
                Text("Quest: \(quest.rawValue)")
            }
            Text("Heart Shuffle: \(model.heartShuffle ? "on" : "off")")
            Text("Hide Dungeon Numbers: \(model.hideDungeonNumbers ? "on" : "off")")
        }
        .foregroundStyle(.secondary)
        .padding(32)
        .frame(minWidth: 420, minHeight: 320)
    }
}

#Preview {
    MainTrackerPlaceholderView(model: TrackerModel(quest: .first, heartShuffle: true))
}
