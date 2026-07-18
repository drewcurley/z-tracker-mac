import SwiftUI
import TrackerCore

/// The voice-command editor (T-139) — the voice analogue of `HotkeyEditorView`. Lists
/// every action grouped by category; each row's trigger phrases are edited as a
/// comma-separated list. Edits persist immediately via `VoiceConfig`.
struct VoiceCommandEditorView: View {
    @Bindable var config: VoiceConfig
    @State private var filter = ""

    private var filterText: String { filter.lowercased().trimmingCharacters(in: .whitespaces) }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            header
            Divider()
            ScrollView {
                VStack(alignment: .leading, spacing: 14) {
                    ForEach(VoiceCatalog.categoryOrder, id: \.self) { category in
                        let actions = self.actions(in: category)
                        if !actions.isEmpty {
                            Text(category.title.uppercased())
                                .font(.system(size: 10, weight: .semibold)).foregroundStyle(.secondary)
                            ForEach(actions) { action in actionRow(action) }
                        }
                    }
                }
                .padding(12)
            }
        }
        .frame(minWidth: 460, minHeight: 500)
    }

    private var header: some View {
        HStack(spacing: 10) {
            Text("Voice Commands").font(.headline)
            Spacer()
            TextField("Filter", text: $filter)
                .textFieldStyle(.roundedBorder).frame(width: 140)
            Button("Reset all") { config.resetToDefaults() }
        }
        .padding(12)
    }

    private func actions(in category: VoiceCategory) -> [VoiceAction] {
        VoiceCatalog.actions(in: category).filter {
            filterText.isEmpty
                || $0.displayName.lowercased().contains(filterText)
                || config.phrases(for: $0.id).contains { $0.contains(filterText) }
        }
    }

    private func actionRow(_ action: VoiceAction) -> some View {
        HStack(spacing: 8) {
            HStack(spacing: 4) {
                Text(action.displayName).font(.system(size: 11, weight: .medium)).lineLimit(1)
                if action.takesNumber {
                    Text("#").font(.system(size: 9, weight: .bold))
                        .foregroundStyle(.secondary)
                        .help("Takes a spoken number, e.g. \u{201C}level 5\u{201D}")
                }
            }
            .frame(width: 150, alignment: .leading)

            TextField("phrases, comma-separated", text: phrasesBinding(action.id))
                .textFieldStyle(.roundedBorder).font(.system(size: 11))

            Button {
                config.resetToDefault(id: action.id)
            } label: {
                Image(systemName: "arrow.uturn.backward").font(.system(size: 10))
            }
            .buttonStyle(.borderless)
            .help("Reset to default phrases")
        }
    }

    /// Two-way binding between the comma-joined phrase text and the config. Setting
    /// splits on commas; `VoiceConfig` lowercases, trims, and de-dupes.
    private func phrasesBinding(_ id: String) -> Binding<String> {
        Binding(
            get: { config.phrases(for: id).joined(separator: ", ") },
            set: { config.setPhrases($0.split(separator: ",").map(String.init), for: id) }
        )
    }
}
