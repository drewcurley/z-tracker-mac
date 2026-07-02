import SwiftUI
import TrackerCore

@main
struct ZTrackerMacApp: App {
    @State private var model = TrackerModel()
    @State private var options = TrackerOptions()

    var body: some Scene {
        WindowGroup {
            ContentView(model: model, options: options)
        }
    }
}
