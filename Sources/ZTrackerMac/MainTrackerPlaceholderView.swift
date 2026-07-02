import SwiftUI
import TrackerCore

/// Stands in for the real main tracker view (dungeon items, blockers,
/// timeline — docs/domain.md § 4.2, § 4.6 onward), which is future tasks'
/// scope. The overworld map (§ 4.5, T-006) is real, not a placeholder —
/// everything else here still is. Confirms the startup screen actually
/// handed off the selected quest + toggle state, so this view is a real
/// integration check, not just a label.
struct MainTrackerPlaceholderView: View {
    var model: TrackerModel

    var body: some View {
        VStack(spacing: 12) {
            Text("Main tracker view — mostly not built yet")
                .font(.title2)
                .foregroundStyle(.secondary)
            if let quest = model.quest {
                Text("Quest: \(quest.rawValue)")
                    .foregroundStyle(.secondary)
            }
            Text("Heart Shuffle: \(model.heartShuffle ? "on" : "off"), Hide Dungeon Numbers: \(model.hideDungeonNumbers ? "on" : "off")")
                .font(.caption)
                .foregroundStyle(.secondary)

            // ContentView only shows this view once model.quest is set
            // (docs/domain.md § 4.1); the fallback here is defensive, not
            // an expected path.
            OverworldMapView(grid: model.overworldGrid, quest: model.quest ?? .first)
                .frame(maxWidth: 900)
        }
        .padding(32)
        .frame(minWidth: 420, minHeight: 320)
    }
}

#Preview {
    MainTrackerPlaceholderView(model: TrackerModel(quest: .first, heartShuffle: true))
}
