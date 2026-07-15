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
    private var mapState: MapStateSummary {
        MapStateSummary.compute(
            grid: model.overworldGrid,
            instance: OverworldInstance(quest: model.quest ?? .first),
            dungeonTracker: model.dungeonTracker,
            playerState: model.playerComputedStateSummary,
            progress: model.playerProgress,
            drawRoutes: options.drawRoutes,
            routesCanScreenScroll: options.showScreenScrolls,
            mirrorOverworld: model.mirrorOverworld
        )
    }

    /// The ordered available recorder-warp destinations for the current state
    /// (T-035.7). Empty unless the player has the recorder.
    private var recorderDestinations: [RecorderDestinations.Destination] {
        RecorderDestinations.compute(
            haveRecorder: model.playerComputedStateSummary.haveRecorder,
            dungeonTracker: model.dungeonTracker,
            hideDungeonNumbers: model.hideDungeonNumbers,
            dungeonLocations: mapState.dungeonLocations,
            toNewDungeons: model.recorderToNewDungeons,
            toUnbeatenDungeons: model.recorderToUnbeatenDungeons)
    }

    /// The destination the stepper currently points at (wrapping the whistle
    /// index against the live list), or `nil` when there are none.
    private var currentRecorderDestination: RecorderDestinations.Destination? {
        let d = recorderDestinations
        guard !d.isEmpty else { return nil }
        let i = ((model.recorderDestinationIndex % d.count) + d.count) % d.count
        return d[i]
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 14) {
                // Top strip (T-035.11): the enlarged OW-spots readout in the open
                // space on the left, the run timer, and the three reset actions
                // to its right.
                HStack(alignment: .center, spacing: 16) {
                    StatusReadoutView(mapState: mapState)
                    Spacer()
                    TimerView(timer: timer)
                    ResetButtonsView(model: model, timer: timer, onResetApp: onResetApp)
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
                        SeedFlagsView(model: model, timer: timer)
                    }
                    TopSectionGroup(title: "Info") {
                        MapInfoView(model: model, playerState: model.playerComputedStateSummary, mapState: mapState, overlays: overlays, timer: timer, onResetApp: onResetApp)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                // ContentView only shows this view once model.quest is set
                // (docs/domain.md § 4.1); the fallback here is defensive, not
                // an expected path. The map stretches to the full window width
                // (no upper bound, T-055).
                OverworldMapView(
                    grid: model.overworldGrid,
                    quest: model.quest ?? .first,
                    options: options,
                    playerState: model.playerComputedStateSummary,
                    mapState: mapState,
                    overlays: overlays,
                    armosClaimed: model.dungeonTracker.armosBox.isDone,
                    mirrored: model.mirrorOverworld,
                    hideDungeonNumbers: model.hideDungeonNumbers,
                    hasRescuedZelda: model.playerProgress.hasRescuedZelda,
                    dungeonComplete: { slot in
                        (1...9).contains(slot) && model.dungeonTracker.dungeon(slot - 1).isComplete
                    },
                    recorderDestination: currentRecorderDestination?.coordinate,
                    startSpot: model.startSpot,
                    onSetStartSpot: { c, r in model.startSpot = OverworldScreenCoordinate(x: c, y: r) },
                    onClearStartSpot: { model.startSpot = nil },
                    onSetTakeAny: { state, c, r in model.setOverworldTakeAny(state, column: c, row: r) },
                    onCycleTakeAny: { c, r in model.cycleOverworldTakeAny(column: c, row: r) },
                    onReleaseTakeAny: { c, r in model.releaseOverworldTakeAny(column: c, row: r) },
                    onPlaceDungeon: { number, c, r in
                        guard (1...9).contains(number) else { return }
                        model.levelHints[HintTarget.dungeon(number)] =
                            HintZone.forZoneChar(OverworldZones.zone(column: c, row: r))
                    }
                )
                .frame(maxWidth: .infinity)

                // The recorder-destination stepper (T-035.7): the single place to
                // see where the whistle would take you, with arrows to step your
                // whistle count. Lives directly below the map.
                RecorderDestinationBar(
                    model: model,
                    destinations: recorderDestinations,
                    current: currentRecorderDestination,
                    hideDungeonNumbers: model.hideDungeonNumbers
                )

                // The dungeon band (T-019+): the reference's room-map grid +
                // blockers + notes below the map. Blockers over Notes as a narrow
                // right-column stack (matching the reference), so the per-dungeon
                // room-map grid — coming next — gets the horizontal space to its
                // left; the map is tall, so the short blockers grid + notes stack
                // beside it add no height.
                HStack(alignment: .top, spacing: 12) {
                    VStack(alignment: .leading, spacing: 12) {
                        TopSectionGroup(title: "Blockers") {
                            BlockersView(model: model)
                        }
                        TopSectionGroup(title: "Notes") {
                            NotesView(model: model)
                                .frame(minHeight: 150)
                        }
                    }
                    .frame(width: 420)
                    // The per-dungeon room-map grid lands in this reserved space
                    // to the right of the column next (D1).
                    Spacer(minLength: 0)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
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

#Preview {
    MainTrackerPlaceholderView(model: TrackerModel(quest: .first, heartShuffle: true), options: TrackerOptions())
}
