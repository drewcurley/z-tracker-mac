import SwiftUI
import QuartzCore

/// A live FPS / main-thread-responsiveness readout (dev diagnostic, toggled by
/// `TrackerOptions.showFPS`). It measures how many `CADisplayLink` callbacks the
/// **main thread** actually delivers per second: when the main thread stalls
/// (e.g. a full-tree SwiftUI re-layout while mousing the dungeon map), callbacks
/// are delayed and the count drops — so the number reflects perceived jank, not
/// just the display's refresh rate.
@Observable
@MainActor
final class FPSMonitor {
    var fps: Int = 0
}

/// The small pill readout. Hosts the invisible `FPSProbe` so the display link is
/// alive only while the readout is on screen.
struct FPSReadout: View {
    let monitor: FPSMonitor

    var body: some View {
        Text("\(monitor.fps) fps")
            .font(.system(size: 11, weight: .bold, design: .monospaced))
            .monospacedDigit()
            .foregroundStyle(color)
            .padding(.horizontal, 6).padding(.vertical, 2)
            .background(.black.opacity(0.6), in: Capsule())
            .overlay(FPSProbe(monitor: monitor).frame(width: 0, height: 0))
            .allowsHitTesting(false)
    }

    private var color: Color {
        switch monitor.fps {
        case ..<20: .red
        case ..<45: .yellow
        default: .green
        }
    }
}

/// A zero-size AppKit view that drives a `CADisplayLink` on the main run loop and
/// reports the delivered frame rate to the monitor once per second.
private struct FPSProbe: NSViewRepresentable {
    let monitor: FPSMonitor
    func makeNSView(context: Context) -> ProbeView { ProbeView(monitor: monitor) }
    func updateNSView(_ nsView: ProbeView, context: Context) {}

    final class ProbeView: NSView {
        private let monitor: FPSMonitor
        private var link: CADisplayLink?
        private var count = 0
        private var lastReport: CFTimeInterval = 0

        init(monitor: FPSMonitor) {
            self.monitor = monitor
            super.init(frame: .zero)
        }
        required init?(coder: NSCoder) { nil }

        override func viewDidMoveToWindow() {
            super.viewDidMoveToWindow()
            link?.invalidate()
            link = nil
            guard window != nil else { return }          // detached → stop the link
            let newLink = displayLink(target: self, selector: #selector(step(_:)))
            newLink.add(to: .main, forMode: .common)
            link = newLink
            count = 0
            lastReport = CACurrentMediaTime()
        }

        @objc private func step(_ link: CADisplayLink) {
            count += 1
            let elapsed = link.timestamp - lastReport
            if elapsed >= 1.0 {
                monitor.fps = Int((Double(count) / elapsed).rounded())
                count = 0
                lastReport = link.timestamp
            }
        }
    }
}
