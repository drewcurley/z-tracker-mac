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
    /// The map-overlay toggles (T-035.2), hoisted to app level (T-124) so the item-
    /// grid info icons, the inline overworld, and the overworld window share one.
    var overlays: OverworldOverlayState
    /// The hotkey bindings (T-131); Global keys fire at runtime via the dispatcher (T-132).
    var hotkeys: HotkeyConfig
    var voiceConfig: VoiceConfig
    /// Shared UI focus state (T-133) — selected dungeon tab (+ later, the cursor).
    var focus: TrackerFocusState
    /// "Reset App" — discard the run and return to the startup screen (T-046),
    /// offered from the Info group's reset buttons (T-048).
    var onResetApp: () -> Void = {}
    /// True for the broadcast **mirror** window (T-178): renders the same tracker over
    /// the same shared state (so it stays in sync and is mouse-editable), but does NOT
    /// install the app-global singletons — the hotkey dispatcher, voice, and the
    /// reminder/timeline poll loop stay owned by the primary window, or they'd
    /// double-fire.
    var isMirror: Bool = false

    @Environment(\.openWindow) private var openWindow
    @Environment(\.dismissWindow) private var dismissWindow

    /// Timeline section collapsed state (T-098) — shown by default.
    @State private var timelineCollapsed = false
    /// The runtime dispatcher for Global hotkeys (T-132), installed while on screen.
    @State private var globalHotkeys: GlobalHotkeyDispatcher?
    /// Voice control (T-137) — created on appear (needs model + focus).
    @State private var voice: VoiceController?
    /// Occasional post-run sponsor plug (T-225): a weekly cap + opt-out, and whether it's showing now.
    @AppStorage(Sponsor.lastPromptKey) private var sponsorLastPromptAt: Double = 0
    @AppStorage(Sponsor.optOutKey) private var sponsorOptOut = false
    @State private var showSponsorPrompt = false
    /// The main content-area (viewport) width, measured via a background reader (T-228), driving the
    /// responsive layout. Defaults wide so a normal window starts un-shrunk with no flash.
    @State private var contentWidth: CGFloat = 100_000
    /// Universal UI zoom (T-229): scales the whole tracker uniformly to fit a smaller screen. A pure
    /// display pref, shared across views via `@AppStorage`; never applied to the broadcast mirror.
    @AppStorage("ui.zoom") private var uiZoom: Double = 1.0
    /// Which auto-collapsed panels the user has temporarily expanded (T-228). Transient (not saved).
    @State private var flagsExpanded = false
    @State private var infoExpanded = false

    /// The active zoom (the mirror always renders full-size for streaming, T-229).
    private var effectiveZoom: CGFloat { isMirror ? 1.0 : CGFloat(uiZoom) }
    /// The content's **logical** width once the zoom is undone — what the layout actually gets to use
    /// (a zoomed-out tracker fits more), so the breakpoints compose with the zoom (T-228/T-229).
    private var effectiveWidth: CGFloat { contentWidth / max(effectiveZoom, 0.1) }

    /// Responsive breakpoints (T-228). Flags/Info collapse right where they'd otherwise wrap below
    /// the trackers (Info first, then Flags) — there's no case where wrapping them is useful.
    private var compactButtons: Bool { effectiveWidth <= 1100 }
    private var infoCollapse: Bool { effectiveWidth <= 1035 }
    private var flagsCollapse: Bool { effectiveWidth <= 900 }

    /// The forced layout width when zoomed (T-229): the content lays out at the enlarged logical
    /// width, and `scaledFootprint` then scales it down to the real viewport. `nil` when not zoomed
    /// (or before the first viewport measurement) so the normal `maxWidth: .infinity` layout — and
    /// the wide-window default — is left untouched, avoiding a giant-frame flash on first paint.
    private var zoomLayoutWidth: CGFloat? {
        guard effectiveZoom != 1, contentWidth < 50_000 else { return nil }
        return effectiveWidth
    }

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
            mirrorOverworld: model.mirrorOverworld,
            customMapActive: model.customMapImagePath != nil
        )
    }

    // The overworld's recorder-destination marker now lives in `OverworldSectionView`
    // (T-124), which computes it from the same model.

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
                Button {
                    breakout.timelinePoppedOut = true
                    openWindow(id: TimelineWindowID)
                } label: {
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
                    Button("Bring back") {
                        breakout.timelinePoppedOut = false
                        dismissWindow(id: TimelineWindowID)
                    }
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

    /// The dungeon band (map + blockers + notes) with a compact corner pop-out
    /// button (T-126 — the old header row was pure vertical cost); a slim placeholder
    /// while it's in its own window.
    private var dungeonBandSection: some View {
        Group {
            if breakout.dungeonBandPoppedOut {
                slimBreakoutPlaceholder("Dungeon area", windowID: DungeonBandWindowID,
                                        onBringBack: { breakout.dungeonBandPoppedOut = false })
            } else {
                DungeonBandView(model: model, options: options, focus: focus)
                    .overlay(alignment: .topTrailing) { cornerPopOutButton(windowID: DungeonBandWindowID) { breakout.dungeonBandPoppedOut = true } }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    /// A small pop-out button tucked into a section's top-trailing corner (T-126),
    /// so a break-out area costs no dedicated header row.
    /// Pop a section into its own window (T-178): the caller flags **its own**
    /// breakout state (`breakout` here is the main window's or the mirror's), so
    /// popping out from the broadcast window only affects the broadcast, not the main.
    private func cornerPopOutButton(windowID: String, onPop: @escaping () -> Void) -> some View {
        Button { onPop(); openWindow(id: windowID) } label: {
            Image(systemName: "rectangle.portrait.and.arrow.right")
                .font(.system(size: 10))
                .padding(3)
                .background(.black.opacity(0.55), in: RoundedRectangle(cornerRadius: 4))
        }
        .buttonStyle(.plain)
        .foregroundStyle(.secondary)
        .help("Open in its own window")
        .padding(2)
    }

    /// The one-line "… is in a separate window / Bring back" shown in place of a
    /// popped-out section (T-126). "Bring back" clears this window's own flag.
    private func slimBreakoutPlaceholder(_ area: String, windowID: String,
                                         onBringBack: @escaping () -> Void) -> some View {
        HStack(spacing: 8) {
            Text("\(area) is in a separate window.")
                .font(.system(size: 11)).foregroundStyle(.secondary)
            Button("Bring back") { onBringBack(); dismissWindow(id: windowID) }
                .font(.system(size: 11)).controlSize(.small)
            Spacer()
        }
        .padding(.vertical, 4)
    }

    /// Store the latest measured content width, ignoring degenerate 0-width passes (T-228).
    private func updateContentWidth(_ w: CGFloat) {
        guard w > 0, abs(w - contentWidth) > 0.5 else { return }
        contentWidth = w
    }

    /// A top-section group that, on a narrow window (T-228), collapses to a slim tap-to-expand
    /// toggle so the Flags/Info panels don't push the map down; otherwise it renders normally.
    @ViewBuilder
    private func collapsibleSection<Content: View>(title: String, collapse: Bool, expanded: Binding<Bool>,
                                                   @ViewBuilder content: () -> Content) -> some View {
        if collapse {
            VStack(alignment: .leading, spacing: 6) {
                Button { withAnimation(.easeInOut(duration: 0.15)) { expanded.wrappedValue.toggle() } } label: {
                    HStack(spacing: 4) {
                        Image(systemName: expanded.wrappedValue ? "chevron.down" : "chevron.right")
                            .font(.system(size: 9, weight: .bold))
                        Text(title).font(.system(size: 12, weight: .semibold))
                    }
                    .padding(.horizontal, 8).padding(.vertical, 4)
                    .background(RoundedRectangle(cornerRadius: 6).fill(Theme.panelFill))
                    .overlay(RoundedRectangle(cornerRadius: 6).strokeBorder(Theme.border, lineWidth: 1))
                }
                .buttonStyle(.plain)
                .help("\(expanded.wrappedValue ? "Hide" : "Show") the \(title) panel")
                if expanded.wrappedValue { content() }
            }
        } else {
            TopSectionGroup(title: title) { content() }
        }
    }

    var body: some View {
        let _ = perfTrace()
        ScrollView {
            VStack(spacing: 14) {
                // Top strip (T-035.11): the enlarged OW-spots readout in the open
                // space on the left, the run timer, and the three reset actions
                // to its right.
                HStack(alignment: .center, spacing: 16) {
                    StatusReadoutView(mapState: mapState, customMapActive: model.customMapImagePath != nil)
                    Spacer()
                    // "Hide timer" (T-206) — suppress the inline run-timer readout when set.
                    if !options.hideTimer { TimerView(timer: timer) }
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
                        DungeonTrackerView(model: model, options: options, focus: focus)
                    }
                    TopSectionGroup(title: "Items") {
                        ObtainableItemsView(model: model, options: options, playerState: model.playerComputedStateSummary, mapState: mapState, focus: focus)
                    }
                    // Flags / Info are suppressible (T-178) and, on a narrow window (T-228),
                    // auto-collapse to a slim toggle so they don't push the map down.
                    if options.showFlagsPanel {
                        collapsibleSection(title: "Flags", collapse: flagsCollapse, expanded: $flagsExpanded) {
                            SeedFlagsView(model: model, options: options, playerState: model.playerComputedStateSummary, mapState: mapState, timer: timer, voice: voice)
                        }
                    }
                    if options.showInfoPanel {
                        collapsibleSection(title: "Info", collapse: infoCollapse, expanded: $infoExpanded) {
                            MapInfoView(model: model, playerState: model.playerComputedStateSummary, mapState: mapState, overlays: overlays, timer: timer, onResetApp: onResetApp, options: options)
                        }
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                // Commentary Mode runner legend (T-215): in the open band above the map while the
                // mode is on, so the two runners' names/colors are clearly visible mid-cast.
                if options.commentaryMode, !breakout.overworldPoppedOut {
                    CommentaryLegendBanner(commentary: model.commentary)
                }

                // The overworld map (T-006), with a compact corner pop-out (T-126).
                // ContentView only shows this view once model.quest is set. The map
                // stretches to the full window width.
                Group {
                    if breakout.overworldPoppedOut {
                        slimBreakoutPlaceholder("Overworld", windowID: OverworldWindowID,
                                                onBringBack: { breakout.overworldPoppedOut = false })
                    } else {
                        OverworldSectionView(model: model, options: options, overlays: overlays,
                                             timer: timer, reminders: reminders, focus: focus)
                            .overlay(alignment: .topTrailing) { cornerPopOutButton(windowID: OverworldWindowID) { breakout.overworldPoppedOut = true } }
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                // (T-081) The recorder destination moved into the Info group
                // (RecorderInfoWidget) below the six overlay toggles; it no longer
                // occupies a full-width bar between the maps.

                // The dungeon band (T-019+): the reference's room-map grid +
                // blockers + notes below the map — with a pop-out window (T-123).
                dungeonBandSection

                // Timeline (T-098): an item-acquisition retrospective, inline and
                // collapsible (on by default). Pop-out into its own window is a
                // follow-up.
                timelineSection
            }
            .padding(24)
            .frame(maxWidth: .infinity)
            // Shrink the tracker's grid buttons on a narrow window (T-228) — applied to the whole
            // content so the top-section boxes AND the blockers grid track it.
            .environment(\.trackerCompact, compactButtons)
            // Universal UI zoom (T-229): lay the content out at the enlarged *logical* width
            // (viewport ÷ zoom) so the responsive breakpoints see the room the zoom frees, then
            // `scaledFootprint` scales it back down to the real viewport — a browser-style zoom that
            // shrinks the whole tracker to fit a small screen. Both are inert at zoom == 1.
            .frame(width: zoomLayoutWidth, alignment: .topLeading)
            .scaledFootprint(effectiveZoom)
        }
        // Force the ScrollView to always FILL the window (T-229): when zoomed, `scaledFootprint`
        // gives the content a fixed pixel width, and without this the vertical ScrollView shrinks to
        // fit that fixed content — so the viewport reader below would measure the shrunken ScrollView
        // instead of the window, `contentWidth` would never grow, and the canvas would stay cropped
        // after the window is widened (a stuck fixpoint). Filling keeps the reader on true window width.
        .frame(minWidth: 420, maxWidth: .infinity, minHeight: 320, maxHeight: .infinity, alignment: .topLeading)
        // Measure the **viewport** width for the responsive breakpoints (T-228) — reading the
        // ScrollView's own frame, not the content, so a wide child (top strip / dungeon cards) can't
        // pin the measurement above the narrow-window thresholds.
        .background {
            GeometryReader { proxy in
                Color.clear
                    .onAppear { updateContentWidth(proxy.size.width) }
                    .onChange(of: proxy.size.width) { _, w in updateContentWidth(w) }
            }
        }
        // Make the hotkey bindings available to leaf menus/pickers for inline hotkey
        // hints (T-197) without threading them through every intermediate view.
        .environment(hotkeys)
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
                // Auto-save the finished run if the option is on (T-196).
                GameSave.saveOnCompletionIfEnabled(model: model, timer: timer, options: options)
                // Occasional sponsor thank-you (T-225) — the real window only, at most once a week,
                // unless the user opted out.
                if !isMirror, !sponsorOptOut {
                    let now = Date().timeIntervalSinceReferenceDate
                    if now - sponsorLastPromptAt >= Sponsor.minInterval {
                        sponsorLastPromptAt = now
                        showSponsorPrompt = true
                    }
                }
            } else {
                timer.resume()
            }
        }
        .overlay(alignment: .top) {
            ReminderOverlayView(controller: reminders)
                .padding(.top, 8)
        }
        // The occasional post-run sponsor thank-you (T-225).
        .overlay(alignment: .bottom) {
            if showSponsorPrompt {
                SponsorCompletionBanner(
                    onDismiss: { withAnimation { showSponsorPrompt = false } },
                    onOptOut: { sponsorOptOut = true; withAnimation { showSponsorPrompt = false } })
                    .padding(.bottom, 12)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        // Poll the reminder engine ~once a second (the reference's cadence)
        // and speak/show the returned announcements. The mirror skips it — one poll
        // loop only, on the primary (T-178).
        .task {
            guard !isMirror else { return }
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
                                         levelPrefix: options.levelPrefix)
                }
                try? await Task.sleep(for: .seconds(1))
            }
        }
        // Global hotkey dispatch (T-132) + voice: live while the tracker is on screen,
        // but only on the primary window — the mirror shares the same app-global
        // dispatcher/voice, so installing a second would double-fire every key (T-178).
        .onAppear {
            guard !isMirror else { return }
            let isNewVoice = (voice == nil)
            let voiceController = voice ?? VoiceController(model: model, focus: focus, config: voiceConfig, options: options, timer: timer)
            voice = voiceController
            // "Listen for speech" (T-206): auto-start voice recognition at launch (once),
            // so the mic is live without clicking the FLAGS mic icon. Prompts for mic
            // permission the first time; a no-op if already listening.
            if isNewVoice, options.listenForSpeech, !voiceController.isListening { voiceController.toggle() }
            let dispatcher = GlobalHotkeyDispatcher(model: model, options: options, timer: timer, hotkeys: hotkeys, focus: focus, voice: voiceController)
            dispatcher.install()
            globalHotkeys = dispatcher
        }
        .onDisappear {
            guard !isMirror else { return }
            globalHotkeys?.uninstall()
            globalHotkeys = nil
            voice?.stop()
        }
    }
}

#Preview {
    MainTrackerPlaceholderView(model: TrackerModel(quest: .first, heartShuffle: .full), options: TrackerOptions(), breakout: BreakoutWindows(), timer: TrackerTimer(), reminders: ReminderController(), overlays: OverworldOverlayState(), hotkeys: HotkeyConfig(), voiceConfig: VoiceConfig(), focus: TrackerFocusState())
}
