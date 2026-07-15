import SwiftUI
import TrackerCore

/// The id of the detachable "Progress" HUD window (T-035.10).
let ProgressHUDWindowID = "z-progress-hud"

@main
struct ZTrackerMacApp: App {
    @State private var model = TrackerModel()
    @State private var options = TrackerOptions()

    var body: some Scene {
        WindowGroup {
            ContentView(model: model, options: options, onResetApp: resetApp)
        }

        // The break-out Progress HUD (T-035.10) — opened on demand by the
        // "Progress" toggle (a secondary WindowGroup doesn't open at launch).
        // Freely resizable; the HUD image stretches to fill (nearest-neighbor).
        WindowGroup(id: ProgressHUDWindowID) {
            ProgressHUDView(model: model)
                .frame(minWidth: 196, minHeight: 158)
                .onDisappear { model.showProgressWindow = false }
        }
        .defaultSize(width: 600, height: 484)
    }

    /// "Reset App" (T-046): discard the whole run and return to the startup /
    /// quest-selection screen, exactly as if the app were relaunched. Replacing
    /// the model with a fresh instance is the robust way to guarantee a clean
    /// slate (no field left un-reset) and tears down the main tracker view — and
    /// with it the run timer. User settings (`options`) are intentionally kept,
    /// like reopening the app on the same machine.
    private func resetApp() {
        model = TrackerModel()
    }
}
