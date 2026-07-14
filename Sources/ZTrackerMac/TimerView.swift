import SwiftUI

/// The run-timer display (T-035.4): the main `H:MM:SS.mmm` stopwatch (green
/// running / orange paused) with, once a groundhog reset has happened, a
/// smaller **yellow lap** timer beneath it, plus Pause/Resume + Reset controls.
/// A `TimelineView` refreshes it ~30×/sec so the milliseconds tick smoothly;
/// the values themselves come from `TrackerTimer`'s pure `…Elapsed(asOf:)`.
struct TimerView: View {
    var timer: TrackerTimer

    /// A **stable** refresh anchor, created once. Passing a fresh `Date()` to
    /// `.periodic(from:)` on every re-render re-phases the schedule and makes
    /// the ms display hitch (e.g. when a groundhog reset triggers a big
    /// re-render); a fixed anchor keeps the ticks smooth. The displayed value is
    /// wall-clock accurate regardless (`context.date` → `…Elapsed(asOf:)`).
    @State private var refreshAnchor = Date()

    var body: some View {
        TimelineView(.periodic(from: refreshAnchor, by: 0.03)) { context in
            let now = context.date
            HStack(alignment: .center, spacing: 10) {
                VStack(alignment: .trailing, spacing: 0) {
                    Text(TimerFormatting.hmsMillis(timer.mainElapsed(asOf: now)))
                        .font(.system(size: 24, weight: .bold, design: .monospaced))
                        .foregroundStyle(timer.isRunning ? .green : .orange)
                    // The lap line always reserves its height (hidden until a
                    // lap starts), so it appearing doesn't shift the main timer.
                    Text(TimerFormatting.hmsMillis(timer.lapElapsed(asOf: now)))
                        .font(.system(size: 15, weight: .semibold, design: .monospaced))
                        .foregroundStyle(.yellow)
                        .opacity(timer.hasLap ? 1 : 0)
                        .help("Lap timer — resets on each groundhog/routers reset; the main timer keeps running")
                }
                VStack(spacing: 3) {
                    Button(timer.isRunning ? "Pause" : "Resume") { timer.togglePause() }
                    Button("Reset") { timer.reset() }
                }
                .font(.caption)
                .controlSize(.small)
            }
        }
    }
}
