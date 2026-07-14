import SwiftUI
import TrackerCore

@main
struct ZTrackerMacApp: App {
    @State private var model = TrackerModel()
    @State private var options = TrackerOptions()

    var body: some Scene {
        WindowGroup {
            ContentView(model: model, options: options, onResetApp: resetApp)
        }
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
