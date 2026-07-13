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
    var options: TrackerOptions

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

            PlayerStateDebugPanel(startingItems: model.startingItemsAndExtras, progress: model.playerProgress)

            // ContentView only shows this view once model.quest is set
            // (docs/domain.md § 4.1); the fallback here is defensive, not
            // an expected path.
            OverworldMapView(
                grid: model.overworldGrid,
                quest: model.quest ?? .first,
                options: options,
                playerState: model.playerComputedStateSummary
            )
            .frame(maxWidth: 900)
        }
        .padding(32)
        .frame(minWidth: 420, minHeight: 320)
    }
}

/// A bare-bones, reachable surface for the player-state foundation added in
/// T-012 (`StartingItemsAndExtras`, `PlayerProgressAndTakeAnyHearts`) — not
/// the reference app's real item-tracker UI (that's a later task, once
/// `T-013`/`T-014` give this state something to compute against). This
/// exists so the new state is exercised by something a person can actually
/// click, not just unit tests, per this task's own acceptance criterion.
private struct PlayerStateDebugPanel: View {
    @Bindable var startingItems: StartingItemsAndExtras
    @Bindable var progress: PlayerProgressAndTakeAnyHearts

    var body: some View {
        DisclosureGroup("Player state (debug — T-012 foundation, not the real item tracker)") {
            VStack(alignment: .leading, spacing: 8) {
                Text("Starting items").font(.caption).bold().foregroundStyle(.secondary)
                HStack {
                    Toggle("Ladder", isOn: $startingItems.hasLadder)
                    Toggle("Raft", isOn: $startingItems.hasRaft)
                    Toggle("Recorder", isOn: $startingItems.hasRecorder)
                }
                Stepper("Max hearts differential: \(startingItems.maxHeartsDifferential)", value: $startingItems.maxHeartsDifferential, in: -8...8)

                Text("Progress").font(.caption).bold().foregroundStyle(.secondary)
                HStack {
                    Toggle("Bombs", isOn: $progress.hasBombs)
                    Toggle("Magical Sword", isOn: $progress.hasMagicalSword)
                    Toggle("Defeated Ganon", isOn: $progress.hasDefeatedGanon)
                }
                Button("Reset progress") { progress.resetAll() }
            }
            .toggleStyle(.checkbox)
            .padding(.top, 4)
        }
        .font(.caption)
        .frame(maxWidth: 500)
    }
}

#Preview {
    MainTrackerPlaceholderView(model: TrackerModel(quest: .first, heartShuffle: true), options: TrackerOptions())
}
