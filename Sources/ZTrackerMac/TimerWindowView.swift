import SwiftUI

/// The duplicate Timer window (T-101): a large stopwatch readout that mirrors the
/// same `TrackerTimer` as the inline timer — handy as a stream overlay. Ticks via
/// SwiftUI's built-in `TimelineView(.periodic)`; the values come from the timer's
/// pure `…Elapsed(asOf:)`. Green while running, orange while paused.
struct TimerWindowView: View {
    var timer: TrackerTimer
    @State private var refreshAnchor = Date()

    var body: some View {
        TimelineView(.periodic(from: refreshAnchor, by: 0.03)) { context in
            let now = context.date
            VStack(spacing: 4) {
                Text(TimerFormatting.hmsMillis(timer.mainElapsed(asOf: now)))
                    .font(.system(size: 44, weight: .bold, design: .monospaced))
                    .foregroundStyle(timer.hasStarted ? (timer.isRunning ? .green : .orange) : .secondary)
                    .minimumScaleFactor(0.4)
                    .lineLimit(1)
                if timer.hasLap {
                    Text(TimerFormatting.hmsMillis(timer.lapElapsed(asOf: now)))
                        .font(.system(size: 22, weight: .semibold, design: .monospaced))
                        .foregroundStyle(.yellow)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .padding()
        }
    }
}
