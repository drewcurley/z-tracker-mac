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
    /// "Reset App" — discard the run and return to the startup screen (T-046),
    /// offered from the Info group's reset buttons (T-048).
    var onResetApp: () -> Void = {}

    /// Drives + presents the reminder engine's announcements (T-018.3).
    @State private var reminders = ReminderController()

    /// The top-section map-overlay toggles (T-035.2), shared between the item-
    /// grid icons (hover/click) and the overworld map (rendering).
    @State private var overlays = OverworldOverlayState()

    /// The run timer (T-035.4): main stopwatch + a lap that resets on each
    /// groundhog reset. Owned here so it survives view redraws.
    @State private var timer = TrackerTimer()

    /// The live overworld map-state summary (T-015.3) feeding the map's true
    /// GYR highlight. Recomputed here from the observable model each time the
    /// body evaluates, so the colors track marks / items / dungeon state.
    /// `mirrorOverworld` has no live source until T-015.5, so it's `false`.
    private var mapState: MapStateSummary {
        MapStateSummary.compute(
            grid: model.overworldGrid,
            instance: OverworldInstance(quest: model.quest ?? .first),
            dungeonTracker: model.dungeonTracker,
            playerState: model.playerComputedStateSummary,
            progress: model.playerProgress,
            drawRoutes: options.drawRoutes,
            routesCanScreenScroll: options.showScreenScrolls,
            mirrorOverworld: false
        )
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 14) {
                // Run timer (T-035.4), top-right. Just the clock + Pause/Resume;
                // the reset actions live under the Info group (T-048).
                HStack {
                    Spacer()
                    TimerView(timer: timer)
                }

                // The top section, split into four logical groups laid out
                // left-to-right and reflowing to new rows when the window is
                // narrowed (T-043): dungeons · obtainables · flags · info.
                FlowLayout(spacing: 12, lineSpacing: 12) {
                    TopSectionGroup(title: "Dungeons") {
                        DungeonTrackerView(model: model)
                    }
                    TopSectionGroup(title: "Items") {
                        ObtainableItemsView(model: model, playerState: model.playerComputedStateSummary, mapState: mapState)
                    }
                    TopSectionGroup(title: "Flags") {
                        SeedFlagsView(model: model)
                    }
                    TopSectionGroup(title: "Info") {
                        MapInfoView(model: model, playerState: model.playerComputedStateSummary, mapState: mapState, overlays: overlays, timer: timer, onResetApp: onResetApp)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                DisclosureGroup("Player state (debug — starting items / progress toggles)") {
                    PlayerStateDebugPanel(startingItems: model.startingItemsAndExtras, progress: model.playerProgress)
                }
                .font(.caption)
                .frame(maxWidth: 900)

                // ContentView only shows this view once model.quest is set
                // (docs/domain.md § 4.1); the fallback here is defensive, not
                // an expected path.
                OverworldMapView(
                    grid: model.overworldGrid,
                    quest: model.quest ?? .first,
                    options: options,
                    playerState: model.playerComputedStateSummary,
                    mapState: mapState,
                    overlays: overlays,
                    armosClaimed: model.dungeonTracker.armosBox.isDone
                )
                .frame(maxWidth: 900)
            }
            .padding(24)
            .frame(maxWidth: .infinity)
        }
        .frame(minWidth: 420, minHeight: 320)
        // Rescuing Zelda ends the run — pause the timer (both main and lap);
        // un-rescuing resumes it (the reference's PlayerHasRescuedZelda →
        // Pause/Resume, OverworldItemGridUI.fs:428-440).
        .onChange(of: model.playerProgress.hasRescuedZelda) { _, rescued in
            if rescued { timer.pause() } else { timer.resume() }
        }
        .overlay(alignment: .top) {
            ReminderOverlayView(controller: reminders)
                .padding(.top, 8)
        }
        // Poll the reminder engine ~once a second (the reference's cadence)
        // and speak/show the returned announcements.
        .task {
            while !Task.isCancelled {
                reminders.handle(model.pollReminders(), options: options)
                try? await Task.sleep(for: .seconds(1))
            }
        }
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
