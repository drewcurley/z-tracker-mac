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
                Button("Change quest") {
                    if let q = pendingQuest { model.changeQuest(q) }
                    pendingQuest = nil
                }
                Button("Cancel", role: .cancel) { pendingQuest = nil }
            } message: {
                Text("This re-derives which overworld spots are valid for the new quest. Spots you've already marked are kept, but any that aren't valid in the new quest may need review.")
            }
        }
    }
}
