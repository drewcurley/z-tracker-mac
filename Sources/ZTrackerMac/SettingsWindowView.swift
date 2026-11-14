import SwiftUI
import TrackerCore

/// The mid-game Settings window body (T-091): the same `SettingsPanelView` shown
/// on the startup screen, wrapped in a scroll view so it works at any window size.
/// Shares the live `options`, so changes apply to the running tracker immediately.
/// Also hosts the mid-run quest changer (T-237), which the startup screen doesn't need.
struct SettingsWindowView: View {
    var model: TrackerModel
    var options: TrackerOptions

    /// A quest the user picked that's awaiting confirmation (changing it may affect map markings).
    @State private var pendingQuest: OverworldQuest?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                questChanger
                Divider()
                SettingsPanelView(options: options)
            }
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .frame(minWidth: 380, minHeight: 360)
    }

    /// Change the overworld quest mid-run (T-237) — only shown once a quest is chosen (i.e. in a run;
    /// the startup screen has its own picker). Picking a different quest asks for confirmation first,
    /// since it re-derives which overworld spots are valid.
    /// The marks that would be stranded by switching to `pendingQuest` (T-252).
    private var pendingStale: [(column: Int, row: Int, mark: OverworldTileMark)] {
        guard let q = pendingQuest else { return [] }
        return model.staleMarks(for: q)
    }

    /// "C4 Level 3, H1 Bomb shop" — at most four, then "and N more". Pure.
    static func staleSummary(_ marks: [(column: Int, row: Int, mark: OverworldTileMark)]) -> String {
        let named = marks.prefix(4).map { "\(OverworldCoords.label(column: $0.column, row: $0.row)) \($0.mark.displayName)" }
        let more = marks.count > 4 ? ", and \(marks.count - 4) more" : ""
        return named.joined(separator: ", ") + more
    }

    @ViewBuilder private var questChanger: some View {
        if let current = model.quest {
            VStack(alignment: .leading, spacing: 6) {
                Text("Overworld quest").font(.caption).bold().foregroundStyle(.secondary)
                Picker("Quest", selection: Binding(
                    get: { current },
                    set: { newValue in if newValue != current { pendingQuest = newValue } }
                )) {
                    ForEach(OverworldQuest.allCases, id: \.self) { q in
                        Text(q.displayName).tag(q)
                    }
                }
                .pickerStyle(.menu)
                .help("Change the quest if you picked the wrong overworld at the start (e.g. First when it was really Mixed — First). Your markings are kept.")
                Text("Re-derives the map art, valid spots, and secret counts. Markings are kept.")
                    .font(.caption2).foregroundStyle(.secondary)
            }
            .confirmationDialog(
                "Change quest to “\(pendingQuest?.displayName ?? "")”?",
                isPresented: Binding(get: { pendingQuest != nil },
                                     set: { if !$0 { pendingQuest = nil } }),
                titleVisibility: .visible
            ) {
                // Marks on screens with no spot in the new quest (T-252) get their own choice.
                if !pendingStale.isEmpty {
                    Button("Change quest and clear them") {
                        if let q = pendingQuest { model.changeQuest(q); model.clearStaleMarks() }
                        pendingQuest = nil
                    }
                    Button("Change quest and keep them (flagged)") {
                        if let q = pendingQuest { model.changeQuest(q) }
                        pendingQuest = nil
                    }
                } else {
                    Button("Change quest") {
                        if let q = pendingQuest { model.changeQuest(q) }
                        pendingQuest = nil
                    }
                }
                Button("Cancel", role: .cancel) { pendingQuest = nil }
            } message: {
                if pendingStale.isEmpty {
                    Text("This re-derives which overworld spots are valid for the new quest. Your marks are kept.")
                } else {
                    Text("\(pendingStale.count) of your marks are on screens with no spot in the new quest: \(Self.staleSummary(pendingStale)). Clear them, or keep them flagged on the map to review.")
                }
            }
        }
    }
}
