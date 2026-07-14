import SwiftUI
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
        }
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
