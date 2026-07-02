import SwiftUI
import TrackerCore

/// Placeholder window content for the initial scaffold (T-002). Replaced by
/// the real startup screen / tracker view in a later feature task — see
/// docs/domain.md § 4.1 for what that screen needs to do.
struct ContentView: View {
    var model: TrackerModel

    var body: some View {
        VStack(spacing: 12) {
            Text("Z-Tracker Mac")
                .font(.title)
            Text("Scaffold — no tracker UI yet. See tasks/INDEX.md.")
                .font(.callout)
                .foregroundStyle(.secondary)
        }
        .padding(40)
        .frame(minWidth: 400, minHeight: 250)
    }
}

#Preview {
    ContentView(model: TrackerModel())
}
