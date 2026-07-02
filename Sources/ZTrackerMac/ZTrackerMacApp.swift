import SwiftUI
import TrackerCore

@main
struct ZTrackerMacApp: App {
    @State private var model = TrackerModel()

    var body: some Scene {
        WindowGroup {
            ContentView(model: model)
        }
    }
}
