import SwiftUI
import TrackerCore

/// The mid-game Settings window body (T-091): the same `SettingsPanelView` shown
/// on the startup screen, wrapped in a scroll view so it works at any window size.
/// Shares the live `options`, so changes apply to the running tracker immediately.
struct SettingsWindowView: View {
    var options: TrackerOptions

    var body: some View {
        ScrollView {
            SettingsPanelView(options: options)
                .padding(16)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .frame(minWidth: 380, minHeight: 360)
    }
}
