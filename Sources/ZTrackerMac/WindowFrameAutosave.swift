import AppKit
import SwiftUI

/// Pure geometry for validating a restored window frame against the currently
/// connected displays (T-046.2). Kept free of AppKit so it's unit-testable:
/// `NSRect` is `CGRect` on macOS, so the persister passes screen `visibleFrame`s
/// straight in.
///
/// The hazard this guards against: a frame saved on an external display that is
/// later disconnected (or re-arranged) restores off every live screen, orphaning
/// the window where it can't be seen or grabbed. When the title bar no longer
/// lands on any screen, we re-home the window (keeping its size) onto the primary.
enum WindowFrameClamp {
    /// How much of the title bar's width must overlap a screen to count as
    /// grabbable (enough to reach the traffic lights / drag region).
    static let minTitleBarVisible: CGFloat = 120
    /// The title bar strip height sampled at the top of the window.
    static let titleBarHeight: CGFloat = 24

    /// Whether the window's title bar lands on any connected screen, so the user
    /// can still see and drag it. `screenFrames` are `NSScreen.screens`' visible
    /// frames (global coordinates; +y is up, matching the window frame).
    static func isReachable(_ frame: CGRect, screenFrames: [CGRect]) -> Bool {
        let strip = CGRect(x: frame.minX, y: frame.maxY - titleBarHeight,
                           width: frame.width, height: titleBarHeight)
        return screenFrames.contains { screen in
            let overlap = screen.intersection(strip)
            return !overlap.isNull && overlap.width >= minTitleBarVisible && overlap.height >= 1
        }
    }

    /// The frame to actually use: the saved one if its title bar is reachable,
    /// otherwise the same size re-centered on `primaryVisible`. `nil` only when
    /// there are no screens at all (headless) — then the caller skips the restore.
    static func resolved(_ frame: CGRect, screenFrames: [CGRect], primaryVisible: CGRect?) -> CGRect? {
        if isReachable(frame, screenFrames: screenFrames) { return frame }
        guard let vis = primaryVisible else { return nil }
        let w = min(frame.width, vis.width)
        let h = min(frame.height, vis.height)
        return CGRect(x: vis.midX - w / 2, y: vis.midY - h / 2, width: w, height: h)
    }
}

/// Persists and restores the main window's frame (position + size) across app
/// launches (T-046.1). SwiftUI's `WindowGroup` has no native frame-persistence
/// modifier, so this bridges to the underlying `NSWindow`.
///
/// Rather than AppKit's `setFrameAutosaveName` (which only saves on AppKit-driven
/// moves and relies on a clean termination flush), this saves the frame
/// explicitly to `UserDefaults` on every move/resize **and** on window-close /
/// app-terminate, and restores it directly when the window appears — so the app
/// reopens exactly where the user last left it, on whichever display.
@MainActor
final class WindowFramePersister: NSObject {
    private let key: String
    private weak var window: NSWindow?

    init(key: String) {
        self.key = key
        super.init()
    }

    func attach(to window: NSWindow) {
        guard self.window == nil else { return }
        self.window = window
        restore()
        let center = NotificationCenter.default
        center.addObserver(self, selector: #selector(save), name: NSWindow.didMoveNotification, object: window)
        center.addObserver(self, selector: #selector(save), name: NSWindow.didEndLiveResizeNotification, object: window)
        center.addObserver(self, selector: #selector(save), name: NSWindow.willCloseNotification, object: window)
        center.addObserver(self, selector: #selector(save), name: NSApplication.willTerminateNotification, object: nil)
    }

    private func restore() {
        guard let window, let saved = UserDefaults.standard.string(forKey: key) else { return }
        let frame = NSRectFromString(saved)
        // Ignore a degenerate/empty saved rect (e.g. from a bad write).
        guard frame.size.width >= 200, frame.size.height >= 200 else { return }
        // Guard against orphaning: if the display the frame was saved on is gone,
        // re-home the window onto the primary screen instead of restoring it
        // off-screen (T-046.2).
        let screenFrames = NSScreen.screens.map(\.visibleFrame)
        let primary = (NSScreen.main ?? NSScreen.screens.first)?.visibleFrame
        guard let resolved = WindowFrameClamp.resolved(frame, screenFrames: screenFrames, primaryVisible: primary) else { return }
        window.setFrame(resolved, display: true)
    }

    @objc private func save() {
        guard let window else { return }
        UserDefaults.standard.set(NSStringFromRect(window.frame), forKey: key)
    }
}

/// Attaches a `WindowFramePersister` to the window hosting this view.
struct WindowFrameAutosave: NSViewRepresentable {
    let key: String

    func makeCoordinator() -> WindowFramePersister { WindowFramePersister(key: key) }

    func makeNSView(context: Context) -> NSView {
        let view = NSView()
        let coordinator = context.coordinator
        // `view.window` is nil until the view joins the hierarchy; defer a tick.
        DispatchQueue.main.async { [weak view] in
            guard let window = view?.window else { return }
            coordinator.attach(to: window)
        }
        return view
    }

    func updateNSView(_ nsView: NSView, context: Context) {}
}

extension View {
    /// Remembers this window's frame across launches under `key` (T-046.1).
    func persistWindowFrame(_ key: String) -> some View {
        background(WindowFrameAutosave(key: key))
    }
}
