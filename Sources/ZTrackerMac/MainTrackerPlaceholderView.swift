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
    /// Which major areas are broken out into their own windows (T-100).
    var breakout: BreakoutWindows
    /// The run timer (T-035.4), owned at app level (T-101) so it can also show in a
    /// duplicate window.
    var timer: TrackerTimer
    /// The reminder controller (toasts + log), hoisted to app level (T-122) so the
    /// broken-out Log window shares it. Declared before `onResetApp` to keep the
    /// memberwise-init argument order matching the call site.
    var reminders: ReminderController
    /// "Reset App" — discard the run and return to the startup screen (T-046),
    /// offered from the Info group's reset buttons (T-048).
    var onResetApp: () -> Void = {}

    @Environment(\.openWindow) private var openWindow
    @Environment(\.dismissWindow) private var dismissWindow

    /// The top-section map-overlay toggles (T-035.2), shared between the item-
    /// grid icons (hover/click) and the overworld map (rendering).
    @State private var overlays = OverworldOverlayState()

    /// Timeline section collapsed state (T-098) — shown by default.
    @State private var timelineCollapsed = false

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
    /// The Timeline section (T-098): a collapsible header + the item strip, with a
    /// pop-out-into-a-window button (T-100).
    private var timelineSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 6) {
                Button {
                    withAnimation(.easeInOut(duration: 0.15)) { timelineCollapsed.toggle() }
                } label: {
                    Image(systemName: timelineCollapsed ? "chevron.right" : "chevron.down")
                        .font(.system(size: 11, weight: .semibold))
                    Text("TIMELINE").font(.system(size: 11, weight: .semibold))
                }
                .buttonStyle(.plain)
                .disabled(breakout.timelinePoppedOut)
                .help(timelineCollapsed ? "Show the timeline" : "Collapse the timeline")
                // Pop-out lives next to the label (T-121) so it reads as applying to
                // the whole timeline, not just the log beside it.
                Button { openWindow(id: TimelineWindowID) } label: {
                    Image(systemName: "rectangle.portrait.and.arrow.right").font(.system(size: 11))
                }
                .buttonStyle(.plain)
                .disabled(breakout.timelinePoppedOut)
                .help("Open the timeline in its own window")
                Spacer()
                if let f = model.timeline.finishSeconds {
                    Text(String(format: "Finish %d:%02d", f / 60, f % 60))
                        .font(.system(size: 10, weight: .bold)).foregroundStyle(.green)
                }
                // Reminder log (T-102) — opens in its own window (T-122) rather than
                // a popover, so it can stay open beside the tracker.
                Button { openWindow(id: LogWindowID) } label: {
                    Label("Log", systemImage: "list.bullet.rectangle").font(.system(size: 10))
                }
                .buttonStyle(.plain)
                .help("Open the reminder log in its own window")
            }
            .foregroundStyle(.secondary)
            if breakout.timelinePoppedOut {
                HStack(spacing: 8) {
                    Text("Timeline is in a separate window.")
                        .font(.system(size: 11)).foregroundStyle(.secondary)
                    Button("Bring back") { dismissWindow(id: TimelineWindowID) }
                        .font(.system(size: 11)).controlSize(.small)
                }
                .padding(.vertical, 8)
            } else if !timelineCollapsed {
                GameTimelineView(timeline: model.timeline)
                    .padding(6)
                    .background(RoundedRectangle(cornerRadius: 6).fill(.black.opacity(0.25)))
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

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
                    // Duplicate the timer into its own window (T-101), e.g. for a
                    // stream overlay; the inline timer stays.
                    Button { openWindow(id: TimerWindowID) } label: {
                        Image(systemName: "rectangle.portrait.and.arrow.right").font(.system(size: 12))
                    }
                    .buttonStyle(.plain)
                    .help("Show the timer in its own window")
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
                        SeedFlagsView(model: model, options: options, playerState: model.playerComputedStateSummary, mapState: mapState, timer: timer)
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

                // Timeline (T-098): an item-acquisition retrospective, inline and
                // collapsible (on by default). Pop-out into its own window is a
                // follow-up.
                timelineSection
            }
            .padding(24)
            .frame(maxWidth: .infinity)
        }
        .frame(minWidth: 420, minHeight: 320)
        // Rescuing Zelda ends the run — pause the timer (both main and lap);
        // un-rescuing resumes it (the reference's PlayerHasRescuedZelda →
        // Pause/Resume, OverworldItemGridUI.fs:428-440).
        .onChange(of: model.playerProgress.hasRescuedZelda) { _, rescued in
            if rescued {
                timer.pause()
                // Post the finish time to Notes, like the Windows app (T-107).
                // Includes milliseconds so close race ties are visible (T-118).
                let line = "Finished in " + TimerFormatting.hmsMillis(timer.mainElapsed(asOf: Date()))
                if !model.notes.contains("Finished in ") {
                    model.notes += (model.notes.isEmpty ? "" : "\n") + line
                }
            } else {
                timer.resume()
            }
        }
        .overlay(alignment: .top) {
            ReminderOverlayView(controller: reminders)
                .padding(.top, 8)
        }
        // Poll the reminder engine ~once a second (the reference's cadence)
        // and speak/show the returned announcements.
        .task {
            while !Task.isCancelled {
                reminders.handle(
                    model.pollReminders(bookForHelpfulHints: options.bookForHelpfulHints),
                    options: options,
                    hideDungeonNumbers: model.hideDungeonNumbers,
                    // Slot-indexed assigned label chars, for HDN completed-dungeon
                    // text ("Dungeon A is complete"), T-112.
                    assignedLabels: model.dungeonTracker.dungeons.prefix(8).map(\.labelChar),
                    // Fire-time context for the log's timestamp + icons (T-122).
                    elapsedSeconds: timer.hasStarted ? Int(timer.mainElapsed(asOf: Date())) : 0,
                    swordLevel: model.playerComputedStateSummary.swordLevel,
                    ringLevel: model.playerComputedStateSummary.ringLevel,
                    coastItemId: model.dungeonTracker.ladderBox.cellCurrent)
                // Feed the Timeline (T-098) with the current run time, once the
                // run has started (before "Go", elapsed is 0 and nothing's timed).
                if timer.hasStarted {
                    model.recordTimeline(elapsedSeconds: Int(timer.mainElapsed(asOf: Date())),
                                         boardInsteadOfLevel: options.boardInsteadOfLevel)
                }
                try? await Task.sleep(for: .seconds(1))
            }
        }
    }
}

#Preview {
    MainTrackerPlaceholderView(model: TrackerModel(quest: .first, heartShuffle: true), options: TrackerOptions(), breakout: BreakoutWindows(), timer: TrackerTimer(), reminders: ReminderController())
}
