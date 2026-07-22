import SwiftUI
import TrackerCore

/// The overworld map section (T-006) with all its wiring, extracted (T-124) so it can
/// render both inline and in a break-out window. Computes the live `MapStateSummary`
/// and recorder-destination marker from the shared model, and routes tile edits back
/// to the model / reminder controller.
struct OverworldSectionView: View {
    var model: TrackerModel
    var options: TrackerOptions
    var overlays: OverworldOverlayState
    var timer: TrackerTimer
    var reminders: ReminderController
    /// Shared focus state (T-134) — the keyboard cursor.
    var focus: TrackerFocusState

    /// The live overworld map-state summary feeding the map's true GYR highlight.
    private var mapState: MapStateSummary {
        MapStateSummary.compute(
            grid: model.overworldGrid,
            instance: OverworldInstance(quest: model.quest ?? .first),
            dungeonTracker: model.dungeonTracker,
            playerState: model.playerComputedStateSummary,
            progress: model.playerProgress,
            drawRoutes: options.drawRoutes,
            routesCanScreenScroll: options.showScreenScrolls,
            mirrorOverworld: model.mirrorOverworld,
            customMapActive: model.customMapImagePath != nil
        )
    }

    /// The overworld screen the recorder currently points at (T-081), or `nil`.
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

    var body: some View {
        OverworldMapView(
            grid: model.overworldGrid,
            quest: model.quest ?? .first,
            options: options,
            focus: focus,
            playerState: model.playerComputedStateSummary,
            mapState: mapState,
            overlays: overlays,
            armosClaimed: model.dungeonTracker.armosBox.isDone,
            dungeonTracker: model.dungeonTracker,
            iconOptions: model.iconOptions,
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
            customWaypoint: model.customWaypoint,
            onSetWaypoint: { c, r in model.customWaypoint = OverworldScreenCoordinate(x: c, y: r) },
            onClearWaypoint: { model.customWaypoint = nil },
            customMapImagePath: model.customMapImagePath,
            onSetTakeAny: { state, c, r in model.setOverworldTakeAny(state, column: c, row: r) },
            onCycleTakeAny: { c, r in model.cycleOverworldTakeAny(column: c, row: r) },
            onReleaseTakeAny: { c, r in model.releaseOverworldTakeAny(column: c, row: r) },
            onOverwrite: { old, new, c, r in
                // Overworld-overwrite reminder (T-096): fire immediately on a
                // destructive mark change, in case it was accidental.
                if let a = OverworldOverwriteReminder.announcement(
                    old: old, new: new, coordLabel: OverworldCoords.label(column: c, row: r)) {
                    reminders.handle([a], options: options,
                                     elapsedSeconds: timer.hasStarted ? Int(timer.mainElapsed(asOf: Date())) : 0)
                }
            },
            onPlaceDungeon: { number, c, r in
                guard (1...9).contains(number) else { return }
                model.levelHints[HintTarget.dungeon(number)] =
                    HintZone.forZoneChar(OverworldZones.zone(column: c, row: r))
            },
            onWoodSwordCaveUsedChanged: { used in
                // Collecting the wood sword at its cave grants the sword (T-118).
                model.playerProgress.hasWoodSword = used
            },
            onMagicalSwordCaveUsedChanged: { taken in
                // "Taking" the magical sword at its cave grants it (T-119).
                model.playerProgress.hasMagicalSword = taken
            }
        )
        .frame(maxWidth: .infinity)
    }
}
