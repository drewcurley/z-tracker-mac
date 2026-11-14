import AppKit
import SwiftUI

/// The id of the mouse-magnifier window (T-255).
let MouseMagnifierWindowID = "z-mouse-magnifier"

/// Live capture of the tracker around the mouse, for the mouse-magnifier window (T-255) — the
/// reference's `makeMouseMagnifierWindow` (`Layout.fs:428-511`), which shows the app canvas at 3×
/// centered on the pointer. Here the main window's content is snapshotted with
/// `cacheDisplay(in:to:)` on each mouse move (throttled to ~30 fps) — the app drawing itself, so
/// no screen-recording permission is involved.
@Observable
@MainActor
final class MouseMagnifierCapture {
    private(set) var image: CGImage?
    /// The magnifier window's content size, in points.
    @ObservationIgnored var viewSize = CGSize(width: 600, height: 600)
    /// Magnification (the reference's `SCALE = 3.0`).
    static let scale: CGFloat = 3
    @ObservationIgnored private var monitor: Any?
    @ObservationIgnored private var lastCapture = Date.distantPast
    @ObservationIgnored private var trailing: DispatchWorkItem?
    private static let interval: TimeInterval = 1.0 / 30

    private var mainWindow: NSWindow? { NSApp.windows.first { $0.title == "Z-Tracker" } }

    func start() {
        guard monitor == nil else { return }
        mainWindow?.acceptsMouseMovedEvents = true
        monitor = NSEvent.addLocalMonitorForEvents(
            matching: [.mouseMoved, .leftMouseDragged, .rightMouseDragged, .otherMouseDragged]
        ) { [weak self] event in
            self?.mouseMoved()
            return event
        }
        capture()
    }

    func stop() {
        if let monitor { NSEvent.removeMonitor(monitor) }
        monitor = nil
        trailing?.cancel()
        trailing = nil
    }

    /// Capture now, or — inside the throttle window — once it ends, so the final position of a
    /// fast move is still shown.
    private func mouseMoved() {
        let wait = Self.interval - Date().timeIntervalSince(lastCapture)
        if wait <= 0 { capture(); return }
        guard trailing == nil else { return }
        let work = DispatchWorkItem { [weak self] in
            self?.trailing = nil
            self?.capture()
        }
        trailing = work
        DispatchQueue.main.asyncAfter(deadline: .now() + wait, execute: work)
    }

    func capture() {
        guard let window = mainWindow, let view = window.contentView else { return }
        let pointer = view.convert(window.mouseLocationOutsideOfEventStream, from: nil)
        // Follow the mouse over the tracker only (the reference tracks its main canvas); over
        // another window, keep showing the last view.
        guard image == nil || view.bounds.contains(pointer) else { return }
        lastCapture = Date()
        let rect = Self.captureRect(pointer: pointer, viewSize: viewSize)
        guard let rep = view.bitmapImageRepForCachingDisplay(in: rect) else { return }
        view.cacheDisplay(in: rect, to: rep)
        image = rep.cgImage
    }

    /// The region of the main window to show: `viewSize ÷ scale`, centered on the pointer. Pure.
    static func captureRect(pointer: CGPoint, viewSize: CGSize) -> CGRect {
        let w = max(1, viewSize.width / scale), h = max(1, viewSize.height / scale)
        return CGRect(x: (pointer.x - w / 2).rounded(), y: (pointer.y - h / 2).rounded(), width: w, height: h)
    }
}

/// The mouse-magnifier window's content (T-255): the captured region scaled up with no smoothing,
/// on the reference's dark-slate-blue background, with a small white arrow marking where the
/// pointer is (the real one is over the main window).
struct MouseMagnifierView: View {
    @State private var capture = MouseMagnifierCapture()

    var body: some View {
        GeometryReader { geo in
            ZStack {
                Color(red: 72 / 255, green: 61 / 255, blue: 139 / 255)   // DarkSlateBlue
                if let image = capture.image {
                    Image(decorative: image, scale: 1, orientation: .up)
                        .interpolation(.none)
                        .resizable()
                        .frame(width: geo.size.width, height: geo.size.height)
                }
                PointerArrow()
                    .fill(Color.white)
                    .overlay(PointerArrow().stroke(Color.black, lineWidth: 1))
                    .frame(width: 12 * MouseMagnifierCapture.scale / 2, height: 12 * MouseMagnifierCapture.scale / 2)
                    .position(x: geo.size.width / 2 + 9, y: geo.size.height / 2 + 9)
            }
            .onAppear {
                capture.viewSize = geo.size
                capture.start()
            }
            .onChange(of: geo.size) { _, size in
                capture.viewSize = size
                capture.capture()
            }
            .onDisappear { capture.stop() }
        }
        .accessibilityHidden(true)
    }
}

/// The reference's fake cursor triangle: (0,0), (12,6), (6,12) — tip at the pointer.
private struct PointerArrow: Shape {
    func path(in rect: CGRect) -> Path {
        var p = Path()
        p.move(to: CGPoint(x: rect.minX, y: rect.minY))
        p.addLine(to: CGPoint(x: rect.maxX, y: rect.midY))
        p.addLine(to: CGPoint(x: rect.midX, y: rect.maxY))
        p.closeSubpath()
        return p
    }
}
