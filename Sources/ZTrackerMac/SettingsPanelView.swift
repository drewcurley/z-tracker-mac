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

    @State private var showMoreSettings = false
    @State private var showVoicePicker = false

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
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var overworldAndDungeonColumn: some View {
        VStack(alignment: .leading, spacing: 10) {
            settingsHeader("Overworld settings")
            Toggle("Draw routes", isOn: Bindable(options).drawRoutes)
            Toggle("Show screen scrolls", isOn: Bindable(options).showScreenScrolls)
            Toggle("Highlight nearby", isOn: Bindable(options).highlightNearby)
            Toggle("Show magnifier", isOn: Bindable(options).showMagnifier)
            Toggle("Shops before dungeons", isOn: Bindable(options).shopsBeforeDungeons)
            // Opens the overworld-tile-hiding checklist (OptionsMenu.fs:115-205).
            Button("More settings…") { showMoreSettings = true }
                .popover(isPresented: $showMoreSettings) {
                    MoreSettingsPopoverView(options: options)
                }

            settingsHeader("Dungeon settings")
            Toggle("BOARD instead of LEVEL", isOn: Bindable(options).boardInsteadOfLevel)
            Toggle("Show basement info", isOn: Bindable(options).showBasementInfo)
            Toggle("Do door inference", isOn: Bindable(options).doDoorInference)
            Toggle("Book for Helpful Hints", isOn: Bindable(options).bookForHelpfulHints)
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
                        Toggle("", isOn: visualBinding(for: category))
                            .labelsHidden()
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
            Toggle("Animate tile changes", isOn: Bindable(options).animateTileChanges)
            Toggle("Animate shop highlights", isOn: Bindable(options).animateShopHighlights)
            Toggle("Save on completion", isOn: Bindable(options).saveOnCompletion)
            Toggle("Snoop for seed&flags", isOn: Bindable(options).snoopSeedAndFlags)
            Toggle("Display seed&flags", isOn: Bindable(options).displaySeedAndFlags)
            Toggle("Listen for speech", isOn: Bindable(options).listenForSpeech)
            Toggle("Confirmation sound", isOn: Bindable(options).confirmationSound)

            Text("Broadcast window")
                .font(.caption)
                .foregroundStyle(.secondary)
            Toggle("Broadcast window", isOn: Bindable(options).showBroadcastWindow)
                .labelsHidden()
            Picker("", selection: Bindable(options).broadcastWindowSize) {
                ForEach(BroadcastWindowSize.allCases, id: \.self) { size in
                    Text(size.displayName).tag(size)
                }
            }
            .pickerStyle(.radioGroup)
            .disabled(!options.showBroadcastWindow)
            Toggle("Include overworld magnifier", isOn: Bindable(options).broadcastWindowIncludesOverworldMagnifier)
                .disabled(!options.showBroadcastWindow)

            Toggle("Mouse magnifier window", isOn: Bindable(options).showMouseMagnifierWindow)
            Toggle("Hide timer", isOn: Bindable(options).hideTimer)
        }
        .toggleStyle(.checkbox)
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
