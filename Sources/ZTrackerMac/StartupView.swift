import SwiftUI
import AppKit
import UniformTypeIdentifiers
import TrackerCore

/// The startup screen (docs/domain.md § 4.1) — quest selection and the core
/// pre-run toggles. Unlike the reference app (whose startup screen is always
/// a fixed "Tall" shape, confirmed via `doc/screenshots/size-and-shape-options.png`
/// and a live VM check), this view is responsive and reflows with the window
/// per `docs/decisions/0003-responsive-layout-not-fixed-presets.md`.
///
/// Out of scope here (see tasks/T-003.md): the alternative-overworld-map
/// custom mode, and real save-file loading (the "start from saved state"
/// button is present but disabled until persistence exists). The embedded
/// settings panel (T-004) is now included — see `SettingsPanelView`.
struct StartupView: View {
    var model: TrackerModel
    var options: TrackerOptions
    var onQuestSelected: (OverworldQuest) -> Void

    @State private var tip: Tip = TipProvider.random()
    /// A picked custom-map image awaiting the overworld-type choice (T-167).
    @State private var pendingCustomMapPath: String?
    /// The overworld type chosen in the custom-map setup sheet (defaults to First).
    @State private var customMapQuest: OverworldQuest = .first

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                VStack(spacing: 24) {
                    Text("Z-Tracker Mac")
                        .font(.largeTitle.bold())

                    questSection
                    savedStateSection
                    tipSection
                }
                .frame(maxWidth: 640)
                .frame(maxWidth: .infinity)

                SettingsPanelView(options: options)
                    .frame(maxWidth: 900)
                    .frame(maxWidth: .infinity)
            }
            .padding(32)
        }
        .frame(minWidth: 420, minHeight: 320)
    }

    private var questSection: some View {
        VStack(spacing: 12) {
            ForEach(OverworldQuest.allCases, id: \.self) { quest in
                Button {
                    onQuestSelected(quest)
                } label: {
                    Text(startLabel(for: quest))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                }
                .buttonStyle(.bordered)
            }
        }
    }

    private var savedStateSection: some View {
        VStack(spacing: 12) {
            Text("- OR -")
                .foregroundStyle(.secondary)
            Button("Start: from a previously saved state") {
                // Disabled until save-file persistence exists — see
                // tasks/T-003.md "Out of scope" and data-model.md § 4.
            }
            .buttonStyle(.bordered)
            .frame(maxWidth: .infinity)
            .disabled(true)
            .help("Coming soon — needs save-file persistence (see data-model.md)")

            // Custom-map fog-of-war (T-167): import a custom overworld image and start
            // with every screen hidden until marked/revealed.
            Button("Start: with a custom overworld map…") {
                pendingCustomMapPath = StartupView.pickCustomMapImage()
            }
            .buttonStyle(.bordered)
            .frame(maxWidth: .infinity)
            .help("Pick a custom overworld map image (e.g. from the Infinite Hyrule generator). Screens start under fog and reveal as you mark them.")
        }
        // Custom-map setup (T-167): a real sheet, not a confirmationDialog — macOS
        // alert-backed dialogs silently drop buttons past ~3, which hid Mixed-Second.
        .sheet(isPresented: Binding(get: { pendingCustomMapPath != nil },
                                    set: { if !$0 { pendingCustomMapPath = nil } })) {
            customMapSetupSheet
        }
    }

    /// The "Custom map setup" dialog: shows the picked image and lets the user choose
    /// the overworld type (all four), then starts.
    private var customMapSetupSheet: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Custom map setup").font(.title2.bold())

            HStack(spacing: 6) {
                Text("Map:").bold()
                Text((pendingCustomMapPath as NSString?)?.lastPathComponent ?? "—")
                    .lineLimit(1).truncationMode(.middle)
                    .foregroundStyle(.secondary)
            }

            Divider()

            Text("Overworld type").font(.headline)
            Text("Your image replaces the overworld art and every screen starts under fog. "
                 + "The quest you pick sets the secrets / door-repair rules — dead spots, fixed "
                 + "fairy fountains, and routing are turned off for custom maps (place fairies "
                 + "yourself by right-clicking a screen).")
                .font(.caption).foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)

            Picker("", selection: $customMapQuest) {
                ForEach(OverworldQuest.allCases, id: \.self) { quest in
                    Text(customMapQuestLabel(for: quest)).tag(quest)
                }
            }
            .pickerStyle(.radioGroup)
            .labelsHidden()

            Divider()

            HStack {
                Spacer()
                Button("Cancel") { pendingCustomMapPath = nil }
                    .keyboardShortcut(.cancelAction)
                Button("Start") {
                    if let path = pendingCustomMapPath {
                        model.customMapImagePath = path
                        onQuestSelected(customMapQuest)
                    }
                    pendingCustomMapPath = nil
                }
                .keyboardShortcut(.defaultAction)
            }
        }
        .padding(24)
        .frame(width: 460)
    }

    /// Quest labels for the custom-map dialog (without the "Start:" prefix).
    private func customMapQuestLabel(for quest: OverworldQuest) -> String {
        switch quest {
        case .first: "First Quest"
        case .second: "Second Quest"
        case .mixedFirst: "Mixed — First Quest rules"
        case .mixedSecond: "Mixed — Second Quest rules"
        }
    }

    /// Open panel for a custom-map image; returns the chosen file path or nil.
    static func pickCustomMapImage() -> String? {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [.png, .jpeg, .image]
        panel.allowsMultipleSelection = false
        panel.message = "Choose a custom overworld map image (16×8 screens)."
        guard panel.runModal() == .OK, let url = panel.url else { return nil }
        return url.path
    }

    private var tipSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Random tip:")
                .font(.headline)
            Text(tip.text)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .overlay(RoundedRectangle(cornerRadius: 8).stroke(.secondary.opacity(0.4)))
    }

    /// User-facing button labels, confirmed against the live reference app
    /// (docs/domain.md § 4.1) rather than invented.
    private func startLabel(for quest: OverworldQuest) -> String {
        switch quest {
        case .first: "Start: First Quest Overworld"
        case .second: "Start: Second Quest Overworld"
        case .mixedFirst: "Start: Mixed - First Quest Overworld"
        case .mixedSecond: "Start: Mixed - Second Quest Overworld (or randomized quest)"
        }
    }
}

#Preview {
    StartupView(model: TrackerModel(), options: TrackerOptions(), onQuestSelected: { _ in })
}
