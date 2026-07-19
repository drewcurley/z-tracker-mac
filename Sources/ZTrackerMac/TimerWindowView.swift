import SwiftUI

/// The duplicate Timer window (T-101): a large stopwatch readout that mirrors the
/// same `TrackerTimer` as the inline timer — handy as a stream overlay. Ticks via
/// SwiftUI's built-in `TimelineView(.periodic)`; the values come from the timer's
/// pure `…Elapsed(asOf:)`. Green while running, orange while paused.
///
/// The readout **scales with the window** (T-115): resize the pop-out and the
/// digits grow/shrink to fill it, so it works as a big stream overlay or a small
/// corner clock.
struct TimerWindowView: View {
    var timer: TrackerTimer
    @State private var refreshAnchor = Date()

    var body: some View {
        GeometryReader { geo in
            let main = Self.mainFontSize(for: geo.size, hasLap: timer.hasLap)
            // Only tick while running — a paused (or not-yet-started) clock is
            // constant, so we render it once instead of driving 33 redraws/sec.
            if timer.isRunning {
                TimelineView(.periodic(from: refreshAnchor, by: timerDisplayRefreshInterval)) { context in
                    readout(asOf: context.date, main: main)
                }
            } else {
                readout(asOf: Date(), main: main)
            }
        }
    }

    private func readout(asOf now: Date, main: CGFloat) -> some View {
        VStack(spacing: main * 0.1) {
            Text(TimerFormatting.hms(timer.mainElapsed(asOf: now)))
                .font(.system(size: main, weight: .bold, design: .monospaced))
                .foregroundStyle(timer.hasStarted ? (timer.isRunning ? .green : .orange) : .secondary)
                .minimumScaleFactor(0.4)
                .lineLimit(1)
            if timer.hasLap {
                Text(TimerFormatting.hms(timer.lapElapsed(asOf: now)))
                    .font(.system(size: main * 0.5, weight: .semibold, design: .monospaced))
                    .foregroundStyle(.yellow)
                    .minimumScaleFactor(0.4)
                    .lineLimit(1)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(main * 0.15)
    }

    /// A main-readout font size that fills the window. The monospaced readout is
    /// ~11 chars ("0:00:00.00"); width caps the size at ~1/7 of the char run, and
    /// height caps it at the vertical share (leaving room for the half-size lap
    /// line + padding). We take the smaller so the text always fits, then let
    /// `minimumScaleFactor` handle any residual.
    static func mainFontSize(for size: CGSize, hasLap: Bool) -> CGFloat {
        let byWidth = size.width / 6.6
        let byHeight = size.height / (hasLap ? 2.6 : 1.7)
        return max(12, min(byWidth, byHeight))
    }
}
