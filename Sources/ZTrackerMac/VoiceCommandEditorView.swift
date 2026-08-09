import SwiftUI
import TrackerCore

/// The voice-command editor (T-139) — the voice analogue of `HotkeyEditorView`. Lists
/// every action grouped by category; each row's trigger phrases are edited as a
/// comma-separated list. Edits persist immediately via `VoiceConfig`.
struct VoiceCommandEditorView: View {
    @Bindable var config: VoiceConfig
    @State private var filter = ""
    /// Show all actions, only those with trigger phrases ("Bound"), or only those with
    /// none ("Unbound") (T-170.1) — mirrors the hotkey editor. An action with no phrases
    /// can't be spoken, so this surfaces exactly what's missing.
    @State private var boundFilter: BoundFilter = .all
    /// Categories the user has collapsed (T-170.1).
    @State private var collapsed: Set<VoiceCategory> = []

    enum BoundFilter: String, CaseIterable { case all = "All", bound = "Bound", unbound = "Unbound" }

    private var filterText: String { filter.lowercased().trimmingCharacters(in: .whitespaces) }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            header
            Divider()
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 14, pinnedViews: [.sectionHeaders]) {
                    ForEach(VoiceCatalog.categoryOrder, id: \.self) { category in
                        let actions = self.actions(in: category)
                        if !actions.isEmpty {
                            Section {
                                if !collapsed.contains(category) {
                                    ForEach(actions) { action in actionRow(action) }
                                }
                            } header: {
                                sectionHeader(category, count: actions.count)
                            }
                        }
                    }
                }
                .padding(12)
            }
        }
        .frame(minWidth: 460, minHeight: 500)
    }

    private var header: some View {
        VStack(spacing: 6) {
            HStack(spacing: 10) {
                Text("Voice Commands").font(.headline)
                Spacer()
                TextField("Filter", text: $filter)
                    .textFieldStyle(.roundedBorder).frame(width: 140)
                Button("Reset all") { config.resetToDefaults() }
            }
            HStack(spacing: 8) {
                Picker("", selection: $boundFilter) {
                    ForEach(BoundFilter.allCases, id: \.self) { Text($0.rawValue).tag($0) }
                }
                .pickerStyle(.segmented).labelsHidden().fixedSize()
                .help("Bound = has trigger phrases; Unbound = none (can't be spoken)")
                Spacer()
                Button("Expand all") { collapsed.removeAll() }
                    .disabled(collapsed.isEmpty)
                Button("Collapse all") { collapsed = Set(VoiceCatalog.categoryOrder) }
                    .disabled(collapsed.count == VoiceCatalog.categoryOrder.count)
            }
            .controlSize(.small)
        }
        .padding(12)
    }

    /// A collapsible category header (T-170.1) with a live count of its visible rows.
    private func sectionHeader(_ category: VoiceCategory, count: Int) -> some View {
        Button {
            if collapsed.contains(category) { collapsed.remove(category) } else { collapsed.insert(category) }
        } label: {
            HStack(spacing: 6) {
                Image(systemName: collapsed.contains(category) ? "chevron.right" : "chevron.down")
                    .font(.system(size: 9, weight: .bold)).frame(width: 10)
                Text(category.title.uppercased()).font(.system(size: 10, weight: .semibold))
                Text("\(count)").font(.caption2)
                    .padding(.horizontal, 5).padding(.vertical, 1)
                    .background(Capsule().fill(Theme.panelFill))
                Spacer()
            }
            .foregroundStyle(.secondary)
            .padding(.vertical, 3).padding(.horizontal, 2)
            .contentShape(Rectangle())
            .background(.bar)
        }
        .buttonStyle(.plain)
    }

    private func actions(in category: VoiceCategory) -> [VoiceAction] {
        VoiceCatalog.actions(in: category).filter { action in
            switch boundFilter {
            case .all: break
            case .bound where config.phrases(for: action.id).isEmpty: return false
            case .unbound where !config.phrases(for: action.id).isEmpty: return false
            default: break
            }
            return filterText.isEmpty
                || action.displayName.lowercased().contains(filterText)
                || config.phrases(for: action.id).contains { $0.contains(filterText) }
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
                if action.takesDirection {
                    Text("\u{2194}").font(.system(size: 9, weight: .bold))
                        .foregroundStyle(.secondary)
                        .help("Takes a direction: left/right/up/down (or west/east/north/south)")
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
