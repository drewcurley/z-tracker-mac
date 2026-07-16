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

    /// The overworld screen the recorder currently points at, for the map's lone
    /// diamond marker (T-081) — driven by the same Info-widget selection so the
    /// marker and the widget always agree. `nil` when there's no destination or
    /// the selected dungeon isn't located on the map yet.
    private var recorderDestinationCoordinate: OverworldScreenCoordinate? {
        guard model.playerComputedStateSummary.haveRecorder else { return nil }
        let entries = RecorderDestinations.infoEntries(
            dungeonTracker: model.dungeonTracker,
            hideDungeonNumbers: model.hideDungeonNumbers,
            dungeonLocations: mapState.dungeonLocations,
            toNewDungeons: model.recorderToNewDungeons,
            toUnbeatenDungeons: model.recorderToUnbeatenDungeons)
        return RecorderDestinations.selectedEntry(
            entries: entries,
            manualIndex: model.recorderDestinationManual ? model.recorderDestinationIndex : nil)?.coordinate
    }

    /// The dungeon band (T-019.5): the room-map grid + the blockers/notes column.
    /// Side-by-side (map left) when there's room; the column wraps below the map
    /// when the window narrows (`ViewThatFits`, per the responsive-layout ADR).
    private var dungeonBand: some View {
        ViewThatFits(in: .horizontal) {
            HStack(alignment: .top, spacing: 12) {
                dungeonMapGroup
                blockersNotesColumn
                    .frame(maxHeight: .infinity)   // Notes fills the map's height
            }
            VStack(alignment: .leading, spacing: 12) {
                dungeonMapGroup
                blockersNotesColumn
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .fixedSize(horizontal: false, vertical: true)
    }

    private var dungeonMapGroup: some View {
        TopSectionGroup(title: "Dungeon Map") {
            DungeonMapView(model: model, options: options)
        }
    }

    /// Blockers over Notes; both fill the 390-wide column so their edges align.
    private var blockersNotesColumn: some View {
        VStack(alignment: .leading, spacing: 12) {
            TopSectionGroup(title: "Blockers") {
                BlockersView(model: model)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            TopSectionGroup(title: "Notes") {
                NotesView(model: model)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            .frame(maxHeight: .infinity)
        }
        // Was a fixed 390; now grows to absorb window width the (capped) map
        // can't use, so a wide window gives Notes room instead of dead space.
        .frame(minWidth: 390, maxWidth: .infinity)
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
                    recorderDestination: recorderDestinationCoordinate,
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

                // (T-081) The recorder destination moved into the Info group
                // (RecorderInfoWidget) below the six overlay toggles; it no longer
                // occupies a full-width bar between the maps.

                // The dungeon band (T-019+): the reference's room-map grid +
                // blockers + notes below the map. Blockers over Notes as a narrow
                // right-column stack (matching the reference), so the per-dungeon
                // room-map grid — coming next — gets the horizontal space to its
                // left; the map is tall, so the short blockers grid + notes stack
                // beside it add no height.
                dungeonBand
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
