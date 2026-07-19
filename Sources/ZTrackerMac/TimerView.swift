import SwiftUI

/// The run-timer display (T-035.4): the main `H:MM:SS.mmm` stopwatch (green
/// running / orange paused) with, once a groundhog reset has happened, a
/// smaller **yellow lap** timer beneath it, plus a Pause/Resume control. A
/// `TimelineView` refreshes it ~30×/sec so the milliseconds tick smoothly; the
/// values themselves come from `TrackerTimer`'s pure `…Elapsed(asOf:)`.
///
/// The three reset actions (Reset App / Reset Timer / Reset (keep maps)) are
/// **not** here — they're omnipresent buttons under the Info group (T-048), so
/// pausing is just pausing and a groundhog reset never pauses the main timer.
/// How often the on-screen stopwatch repaints — once per second. On macOS 27
/// every tick forces the main window's single `NSHostingView` to re-measure the
/// *entire* tracker layout (`sizeThatFits` over the whole tree, ~68 ms/pass), so
/// a 33 fps clock pegged a full core and lagged the game (measured). The visible
/// clock only shows `H:MM:SS`, so 1 fps is all it needs; the millisecond value
/// written to the notes (e.g. on Zelda capture) is read from the timer at that
/// instant, independent of this repaint rate.
let timerDisplayRefreshInterval: TimeInterval = 1.0

struct TimerView: View {
    var timer: TrackerTimer

    /// A **stable** refresh anchor, created once. Passing a fresh `Date()` to
    /// `.periodic(from:)` on every re-render re-phases the schedule and makes
    /// the ms display hitch (e.g. when a groundhog reset triggers a big
    /// re-render); a fixed anchor keeps the ticks smooth. The displayed value is
    /// wall-clock accurate regardless (`context.date` → `…Elapsed(asOf:)`).
    @State private var refreshAnchor = Date()

    var body: some View {
        if timer.hasStarted {
            runningTimer
        } else {
            // Before the run: a Go button, so the tracker can be loaded and
            // configured without the clock already ticking.
            Button {
                timer.start()
            } label: {
                Text("Go")
                    .font(.system(size: 22, weight: .heavy, design: .rounded))
                    .frame(minWidth: 90)
            }
            .buttonStyle(.borderedProminent)
            .tint(.green)
            .help("Start the run timer")
        }
    }

    private var runningTimer: some View {
        // Only the running timer needs to tick. A paused timer's elapsed is
        // constant regardless of `now`, so we render it **once** (no
        // `TimelineView`) — otherwise the paused clock would still drive 33
        // display-cycle re-layouts/sec for nothing.
        Group {
            if timer.isRunning {
                TimelineView(.periodic(from: refreshAnchor, by: timerDisplayRefreshInterval)) { context in
                    readout(asOf: context.date)
                }
            } else {
                readout(asOf: Date())
            }
        }
    }

    /// The timer readout — `H:MM:SS` (no ms; see `timerDisplayRefreshInterval`).
    private func readout(asOf now: Date) -> some View {
        HStack(alignment: .center, spacing: 10) {
            VStack(alignment: .trailing, spacing: 0) {
                Text(TimerFormatting.hms(timer.mainElapsed(asOf: now)))
                    .font(.system(size: 24, weight: .bold, design: .monospaced))
                    .foregroundStyle(timer.isRunning ? .green : .orange)
                // The lap line always reserves its height (hidden until a
                // lap starts), so it appearing doesn't shift the main timer.
                Text(TimerFormatting.hms(timer.lapElapsed(asOf: now)))
                    .font(.system(size: 15, weight: .semibold, design: .monospaced))
                    .foregroundStyle(.yellow)
                    .opacity(timer.hasLap ? 1 : 0)
                    .help("Lap timer — resets on each groundhog/routers reset; the main timer keeps running")
            }
            Button(timer.isRunning ? "Pause" : "Resume") { timer.togglePause() }
                .font(.caption)
                .controlSize(.small)
        }
    }
}
