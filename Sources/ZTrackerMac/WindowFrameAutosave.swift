import AppKit
import SwiftUI

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
        window.setFrame(frame, display: true)
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
