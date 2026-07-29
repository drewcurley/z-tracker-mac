import AVFoundation
import SwiftUI
import TrackerCore

/// The startup screen's embedded settings panel (docs/domain.md § 4.1,
/// T-004/T-005) — 3 columns confirmed by direct screenshot of the running
/// reference app and by reading `OptionsMenu.fs` directly. Responsive per
/// `docs/decisions/0003-responsive-layout-not-fixed-presets.md`: uses an
/// adaptive grid rather than a fixed 3-column HStack, so columns reflow to
/// fewer per row as the window narrows instead of clipping.
struct SettingsPanelView: View {
    var options: TrackerOptions

    @Environment(\.openWindow) private var openWindow
    @State private var showMoreSettings = false
    @State private var showVoicePicker = false
    @State private var showLevelPrefixEditor = false

    private let columns = [
        GridItem(.adaptive(minimum: 220), alignment: .top)
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Settings (most can be changed later, using 'Options...' button above timeline):")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            LazyVGrid(columns: columns, alignment: .leading, spacing: 20) {
                overworldAndDungeonColumn
                remindersColumn
                otherColumn
            }

            Divider()
            HStack(spacing: 8) {
                settingsHeader("Hotkeys")
                Button("Edit hotkeys…") { openWindow(id: HotkeyWindowID) }
                Text("Bind keys per context; import/export the Windows HotKeys.txt.")
                    .font(.caption).foregroundStyle(.secondary)
            }
            HStack(spacing: 8) {
                settingsHeader("Voice")
                Button("Edit voice commands…") { openWindow(id: VoiceWindowID) }
                Text("Customize the phrases that trigger each voice action.")
                    .font(.caption).foregroundStyle(.secondary)
            }
            Divider()
            // About / version (audit #23): the clickable version, this project's
            // link, and credit + link to the original Windows Z-Tracker this is a
            // port of (T-172/T-175). Named "Z-Tracker for macOS" here to distinguish
            // it from the original in the credits; the window title stays "Z-Tracker".
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 8) {
                    settingsHeader("About")
                    Text("Z-Tracker for macOS \(Self.appVersion)")
                        .font(.caption).foregroundStyle(.secondary)
                        .textSelection(.enabled)
                    Link("Project page ↗", destination: Self.projectURL)
                        .font(.caption)
                    Link("Original Z-Tracker ↗", destination: Self.originalProjectURL)
                        .font(.caption)
                }
                Text("A native macOS port of the original Windows Z-Tracker (F#) by Brian McNamara.")
                    .font(.caption2).foregroundStyle(.secondary)
                // Build stamp (T-179): git hash + build time, to confirm you're running
                // the latest local build. "dev" when unbundled.
                Text("Build \(Self.buildStamp)")
                    .font(.system(size: 10, design: .monospaced))
                    .foregroundStyle(.tertiary)
                    .textSelection(.enabled)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    /// The app's short version string from the bundle Info.plist (built from the
    /// top-level `VERSION` file); `vdev` when unbundled (e.g. `swift run`, tests).
    static var appVersion: String {
        let v = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String
        return "v" + (v ?? "dev")
    }
    /// The build stamp from Info.plist (git hash + build time), or "dev" unbundled.
    static var buildStamp: String {
        (Bundle.main.object(forInfoDictionaryKey: "ZTrackerBuildStamp") as? String) ?? "dev"
    }
    static let projectURL = URL(string: "https://github.com/drewcurley/z-tracker-mac")!
    /// The original Windows Z-Tracker (F#) by Brian McNamara that this app ports.
    static let originalProjectURL = URL(string: "https://github.com/brianmcn/Zelda1RandoTools")!

    private var overworldAndDungeonColumn: some View {
        VStack(alignment: .leading, spacing: 10) {
            settingsHeader("Overworld settings")
            Toggle("Draw routes", isOn: Bindable(options).drawRoutes)
            Toggle("Show screen scrolls", isOn: Bindable(options).showScreenScrolls)
            Toggle("Highlight nearby", isOn: Bindable(options).highlightNearby)
            Toggle("Show magnifier", isOn: Bindable(options).showMagnifier)
            Toggle("Shops before dungeons", isOn: Bindable(options).shopsBeforeDungeons)
            Toggle("Graphical tile chooser", isOn: Bindable(options).graphicalOverworldChooser)
                .help("Pick overworld marks from a grid of icons (faster to recognize) instead of the text menu. Scroll up on a tile to set its enemies.")
            // Opens the overworld-tile-hiding checklist (OptionsMenu.fs:115-205).
            Button("More settings…") { showMoreSettings = true }
                .popover(isPresented: $showMoreSettings) {
                    MoreSettingsPopoverView(options: options)
                }

            settingsHeader("Dungeon settings")
            renameLevelsRow
            Toggle("Show basement info", isOn: Bindable(options).showBasementInfo)
            Toggle("Do door inference", isOn: Bindable(options).doDoorInference)
            // "Book for Helpful Hints" is a seed flag now — it lives in the Flags
            // section (T-092), not here.
            Toggle("Left-drag auto-inverts", isOn: Bindable(options).leftDragAutoInverts)
            Toggle("Default to NonDescript", isOn: Bindable(options).defaultToNonDescript)
            Toggle("Dungeon 'sunglasses'", isOn: Bindable(options).dungeonSunglasses)
        }
        .toggleStyle(.checkbox)
    }

    private var remindersColumn: some View {
        VStack(alignment: .leading, spacing: 10) {
            settingsHeader("Reminders")

            HStack {
                Text("Volume")
                Slider(value: Bindable(options).reminderVolume.doubleBinding, in: 0...100)
                    .accessibilityLabel("Reminder volume")
            }

            Button("Disable all") { options.disableAllReminders() }

            Grid(alignment: .leading, horizontalSpacing: 8, verticalSpacing: 4) {
                GridRow {
                    // Center each header over its checkbox column; the third
                    // column (category name) has no header.
                    Text("Voice").font(.caption).foregroundStyle(.secondary)
                        .gridColumnAlignment(.center)
                    Text("Visual").font(.caption).foregroundStyle(.secondary)
                        .gridColumnAlignment(.center)
                    Text("")
                }
                ForEach(ReminderCategory.allCases, id: \.self) { category in
                    GridRow {
                        Toggle("", isOn: voiceBinding(for: category))
                            .labelsHidden()
                            .accessibilityLabel("Voice reminder: \(category.displayName)")
                        Toggle("", isOn: visualBinding(for: category))
                            .labelsHidden()
                            .accessibilityLabel("Visual reminder: \(category.displayName)")
                        Text(category.displayName)
                    }
                }
            }
            .toggleStyle(.checkbox)

            // Reference app only shows this button when >1 voice is
            // installed (OptionsMenu.fs:275) — same gate here.
            if AVSpeechSynthesisVoice.speechVoices().count > 1 {
                Button("Change voice…") { showVoicePicker = true }
                    .popover(isPresented: $showVoicePicker) {
                        VoicePickerView(options: options)
                    }
            }
        }
    }

    private var otherColumn: some View {
        VStack(alignment: .leading, spacing: 10) {
            settingsHeader("Other")
            Toggle("Check for updates on launch", isOn: Bindable(options).checkForUpdatesOnLaunch)
                .help("On launch, check GitHub for a newer release and show a notice. Sends no data.")
            Toggle("Animate tile changes", isOn: Bindable(options).animateTileChanges)
            Toggle("Animate shop highlights", isOn: Bindable(options).animateShopHighlights)
            Toggle("Save on completion", isOn: Bindable(options).saveOnCompletion)
            Toggle("Snoop for seed&flags", isOn: Bindable(options).snoopSeedAndFlags)
            Toggle("Display seed&flags", isOn: Bindable(options).displaySeedAndFlags)
            Toggle("Listen for speech", isOn: Bindable(options).listenForSpeech)
            Toggle("Confirmation sound", isOn: Bindable(options).confirmationSound)

            // Show/hide the top Info panel (T-178) — for players who don't use it and
            // want a tighter layout / cleaner broadcast. The broadcast mirror window
            // itself is opened from the Window menu, not a persisted toggle.
            Toggle("Show Info panel", isOn: Bindable(options).showInfoPanel)
            Toggle("Use detailed app icon", isOn: Bindable(options).useDetailedAppIcon)
                .help("Swap the dock icon to the original, more detailed design (while the app is open).")

            Toggle("Mouse magnifier window", isOn: Bindable(options).showMouseMagnifierWindow)
            Toggle("Hide timer", isOn: Bindable(options).hideTimer)
            Toggle("Warn when quitting while the timer is running", isOn: Bindable(options).warnOnCloseWhileTimerRunning)
            Toggle("Show FPS counter (diagnostic)", isOn: Bindable(options).showFPS)
            Toggle("Log render perf to file (diagnostic)", isOn: Bindable(options).logRenderPerf)
                .help("Capture which views re-render on each hover, why, and how long the main thread is busy — for diagnosing frame-rate issues. Writes to a temp file; on Reset App or Quit you're asked where to save it (or to discard it).")
        }
        .toggleStyle(.checkbox)
    }

    /// Rename-levels row (T-171): a checkbox to enable the custom dungeon label, and
    /// an Edit button (live only when enabled) that opens the prefix editor.
    private var renameLevelsRow: some View {
        HStack(spacing: 8) {
            Toggle("Rename levels", isOn: Bindable(options).renameLevelsEnabled)
            Button("Edit…") { showLevelPrefixEditor = true }
                .controlSize(.small)
                .disabled(!options.renameLevelsEnabled)
        }
        .sheet(isPresented: $showLevelPrefixEditor) {
            LevelPrefixEditorSheet(options: options)
        }
    }

    private func settingsHeader(_ title: String) -> some View {
        Text(title)
            .font(.headline)
            .underline()
    }

    private func voiceBinding(for category: ReminderCategory) -> Binding<Bool> {
        Binding(
            get: { options.voiceReminders[category] ?? false },
            set: { options.voiceReminders[category] = $0 }
        )
    }

    private func visualBinding(for category: ReminderCategory) -> Binding<Bool> {
        Binding(
            get: { options.visualReminders[category] ?? false },
            set: { options.visualReminders[category] = $0 }
        )
    }
}

/// The "More settings…" popup (`OptionsMenu.fs:115-205`) — overworld tiles
/// that can be hidden (rendered as "Don't Care" spots) once marked, plus the
/// two shop-hiding modifiers.
private struct MoreSettingsPopoverView: View {
    var options: TrackerOptions

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Overworld marks to hide")
                .font(.headline)
            Text(
                "Sometimes you want to mark certain map tiles so the tracker can help you, "
                    + "but don't want to clutter your overworld map with icons you don't need "
                    + "to see. Check each tile kind you'd prefer to hide after marking it."
            )
            .font(.callout)
            .foregroundStyle(.secondary)
            .fixedSize(horizontal: false, vertical: true)

            LazyVGrid(columns: [GridItem(.adaptive(minimum: 140))], alignment: .leading) {
                ForEach(OverworldHiddenTileKind.allCases, id: \.self) { kind in
                    Toggle(kind.displayName, isOn: hiddenTileBinding(for: kind))
                }
            }
            .toggleStyle(.checkbox)

            Divider()

            Toggle("Hide no-longer-relevant shop items", isOn: Bindable(options).hideNoLongerRelevantShopItems)
                .toggleStyle(.checkbox)
            Toggle("Always hide meat shops", isOn: Bindable(options).alwaysHideMeatShops)
                .toggleStyle(.checkbox)
                .disabled(!options.hideNoLongerRelevantShopItems)
                .padding(.leading, 20)
        }
        .padding()
        .frame(width: 420)
    }

    private func hiddenTileBinding(for kind: OverworldHiddenTileKind) -> Binding<Bool> {
        Binding(
            get: { options.hiddenOverworldTiles[kind] ?? false },
            set: { options.hiddenOverworldTiles[kind] = $0 }
        )
    }
}

/// The "Change voice…" popup (`OptionsMenu.fs:275-325`) — lists installed
/// system voices with a way to preview and select one. `AVSpeechSynthesizer`
/// is this project's macOS-native replacement for the reference app's
/// `System.Speech` (see `docs/stack.md`).
private struct VoicePickerView: View {
    var options: TrackerOptions

    private let synthesizer = AVSpeechSynthesizer()

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Select preferred voice")
                .font(.headline)
            ScrollView {
                VStack(alignment: .leading, spacing: 6) {
                    ForEach(AVSpeechSynthesisVoice.speechVoices(), id: \.identifier) { voice in
                        HStack {
                            Text(voice.name)
                                .frame(width: 180, alignment: .leading)
                            Button("Test it") { speak(voice, text: "Hello") }
                            Button("Choose this") {
                                options.preferredVoiceIdentifier = voice.identifier
                                speak(voice, text: "Voice chosen")
                            }
                        }
                    }
                }
            }
            .frame(maxHeight: 300)
        }
        .padding()
        .frame(width: 420)
    }

    private func speak(_ voice: AVSpeechSynthesisVoice, text: String) {
        let utterance = AVSpeechUtterance(string: text)
        utterance.voice = voice
        synthesizer.speak(utterance)
    }
}

private extension Binding where Value == Int {
    /// `Slider` needs a `Double` binding; the reference app's `Volume` field
    /// is an `Int` (`TrackerModelOptions.fs:80`), so this bridges the two
    /// without changing the underlying model type.
    var doubleBinding: Binding<Double> {
        Binding<Double>(
            get: { Double(wrappedValue) },
            set: { wrappedValue = Int($0) }
        )
    }
}

#Preview {
    SettingsPanelView(options: TrackerOptions())
        .padding()
        .frame(width: 700)
}

/// The "Rename levels" editor (T-171): a text field for the label prefix, a live
/// preview, and Cancel / Save. The prefix carries its own separator (`"area-"` →
/// `area-1`, `"DUNGEON"` → `DUNGEON1`) and is capped so prefix + digit fills the
/// 8-cell dungeon header. Edits a draft so Cancel discards.
private struct LevelPrefixEditorSheet: View {
    var options: TrackerOptions
    @Environment(\.dismiss) private var dismiss
    @State private var draft = ""

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Rename dungeon levels").font(.title2.bold())
            Text("The text shown before each dungeon number. It carries its own "
                 + "separator, so “area-” makes area-1 … area-9, and “DUNGEON” makes "
                 + "DUNGEON1 … DUNGEON9. Up to \(TrackerOptions.maxLevelPrefixLength) characters.")
                .font(.caption).foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)

            TextField("Label prefix", text: $draft)
                .textFieldStyle(.roundedBorder)
                .onChange(of: draft) { _, v in
                    // Enforce the cap as they type (prefix + 1 digit = 8-cell header).
                    if v.count > TrackerOptions.maxLevelPrefixLength {
                        draft = String(v.prefix(TrackerOptions.maxLevelPrefixLength))
                    }
                }

            VStack(alignment: .leading, spacing: 4) {
                Text("Preview").font(.caption).foregroundStyle(.secondary)
                Text(previewText)
                    .font(.system(size: 15, weight: .heavy, design: .monospaced))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 10).padding(.vertical, 6)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(RoundedRectangle(cornerRadius: 6).fill(.black.opacity(0.4)))
            }

            Divider()

            HStack {
                Button("Reset to default") { draft = TrackerOptions.defaultLevelPrefix }
                Spacer()
                Button("Cancel", role: .cancel) { dismiss() }
                    .keyboardShortcut(.cancelAction)
                Button("Save") {
                    // An empty prefix falls back to the default rather than blanking labels.
                    options.customLevelPrefix = draft.isEmpty ? TrackerOptions.defaultLevelPrefix : draft
                    dismiss()
                }
                .keyboardShortcut(.defaultAction)
            }
        }
        .padding(24)
        .frame(width: 420)
        .onAppear { draft = options.customLevelPrefix }
    }

    /// A few sample labels for the chosen prefix (falls back to the default when blank).
    private var previewText: String {
        let p = draft.isEmpty ? TrackerOptions.defaultLevelPrefix : draft
        return (1...3).map { "\(p)\($0)" }.joined(separator: "   ") + "   …   \(p)9"
    }
}
