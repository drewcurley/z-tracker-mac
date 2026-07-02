import SwiftUI
import TrackerCore

/// The startup screen's embedded settings panel (docs/domain.md § 4.1, T-004)
/// — 3 columns confirmed by direct screenshot of the running reference app.
/// Responsive per `docs/decisions/0003-responsive-layout-not-fixed-presets.md`:
/// uses an adaptive grid rather than a fixed 3-column HStack, so columns
/// reflow to fewer per row as the window narrows instead of clipping.
struct SettingsPanelView: View {
    var options: TrackerOptions

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
            // "More settings…" button — its contents weren't confirmed by
            // screenshot (cut off), so it's a placeholder, not a guessed
            // expansion. See tasks/T-004.md "Out of scope".
            Button("More settings…") {}
                .disabled(true)
                .help("Not implemented yet — the expanded panel's exact contents weren't confirmed against the reference app")

            settingsHeader("Dungeon settings")
            Toggle("BOARD instead of LEVEL", isOn: Bindable(options).boardInsteadOfLevel)
            Toggle("Show basement info", isOn: Bindable(options).showBasementInfo)
            Toggle("Do door inference", isOn: Bindable(options).doDoorInference)
            Toggle("Book for Helpful Hints", isOn: Bindable(options).bookForHelpfulHints)
            Toggle("Left-drag auto-inverts", isOn: Bindable(options).leftDragAutoInverts)
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
                    Text("").frame(width: 1)
                    Text("Voice").font(.caption).foregroundStyle(.secondary)
                    Text("Visual").font(.caption).foregroundStyle(.secondary)
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

            Button("Change voice…") {}
                .disabled(true)
                .help("Voice picker not implemented yet")
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
