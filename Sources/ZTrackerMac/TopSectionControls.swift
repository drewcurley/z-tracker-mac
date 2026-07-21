import SwiftUI
import TrackerCore

/// The prominent OW-spots readout (T-035.11) — enlarged and moved into the open
/// space left of the timer, since it's the number the player glances at most.
struct StatusReadoutView: View {
    var mapState: MapStateSummary

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text("\(mapState.owSpotsRemain) OW spots left")
                .font(.system(size: 20, weight: .semibold))
                .foregroundStyle(.orange)
                .help("Unmarked overworld screens remaining")
            Text("\(ItemProgressGrid.gettableCount(mapState)) gettable")
                .font(.system(size: 17, weight: .semibold))
                .foregroundStyle(.green)
                .help("Unmarked spots you can currently uncover with your items (raft / recorder / bracelet / candle / bombs), for this quest")
        }
    }
}

/// The three always-visible reset actions (T-048), now to the right of the timer
/// (T-035.11). All three confirm first (T-051).
struct ResetButtonsView: View {
    @Bindable var model: TrackerModel
    var timer: TrackerTimer
    var onResetApp: () -> Void = {}

    @State private var confirmingResetApp = false
    @State private var confirmingResetTimer = false
    @State private var confirmingGroundhog = false

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Button("Reset App") { confirmingResetApp = true }
                .help("Discard everything and return to the startup screen, as if you'd just reopened the app")
            Button("Reset Timer") { confirmingResetTimer = true }
                .help("Set the run timer back to 0:00:00 (keeps your marks and items)")
            Button("Reset (keep maps)") { confirmingGroundhog = true }
                .help("Groundhog/routers restart: clear inventory but keep your overworld marks and known item locations. Does not pause the timer.")
            Divider().frame(width: 96)
            Button("Save…") { GameSave.manualSave(model: model, timer: timer) }
                .help("Save the current run to a file (default: ~/Documents/ztracker)")
            Button("Load…") { GameSave.manualLoad(model: model, timer: timer) }
                .help("Load a previously saved run, replacing the current tracker state")
        }
        .font(.system(size: 10))
        .controlSize(.small)
        .confirmationDialog("Reset the app?", isPresented: $confirmingResetApp, titleVisibility: .visible) {
            Button("Reset App (discard everything)", role: .destructive, action: onResetApp)
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Returns to the startup screen as if you'd just reopened the app. All marks, items, hints, and the timer are discarded. Use Save first if you want to keep it.")
        }
        .confirmationDialog("Reset the timer to 0:00:00?", isPresented: $confirmingResetTimer, titleVisibility: .visible) {
            Button("Reset Timer", role: .destructive) { timer.reset() }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Sets the run timer back to 0:00:00. Your marks and items are kept. This can't be undone.")
        }
        .confirmationDialog("Reset inventory for a groundhog/routers restart?",
                            isPresented: $confirmingGroundhog, titleVisibility: .visible) {
            Button("Reset inventory (keep maps)", role: .destructive) {
                model.resetForGroundhogOrRouters()
                timer.startLap()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Removes all items, triforces, and take-any hearts so you can replay the same seed. Your overworld marks and known item locations stay, and the lap timer restarts while the main timer keeps running. Use Save first if you want to keep it.")
        }
    }
}

/// "Auto-map dungeons" (T-035.5), now under Flags (T-035.11) since it's game
/// config. Destructive (replaces the current dungeon markers), so it confirms.
struct AutoMapDungeonsMenu: View {
    @Bindable var model: TrackerModel

    @State private var confirmingVanilla = false
    @State private var pendingVanillaSecondQuest = false

    var body: some View {
        Menu("Auto-map dungeons…") {
            Button("First Quest vanilla") { pendingVanillaSecondQuest = false; confirmingVanilla = true }
            Button("Second Quest vanilla") { pendingVanillaSecondQuest = true; confirmingVanilla = true }
        }
        .menuStyle(.borderlessButton)
        .font(.system(size: 11))
        .controlSize(.small)
        .fixedSize()
        .help("Place the vanilla First/Second-Quest dungeon locations on the map. Replaces your current dungeon markers.")
        .confirmationDialog("Auto-map \(pendingVanillaSecondQuest ? "Second" : "First") Quest dungeons?",
                            isPresented: $confirmingVanilla, titleVisibility: .visible) {
            Button("Replace dungeon markers", role: .destructive) {
                model.autoMapVanillaDungeons(secondQuest: pendingVanillaSecondQuest)
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Removes your current dungeon markers and places the \(pendingVanillaSecondQuest ? "second" : "first")-quest vanilla dungeon locations. Use Save first if you want to keep it.")
        }
    }
}
