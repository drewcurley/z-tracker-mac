import AppKit
import SwiftUI

/// Bridges precise mouse input for a dungeon room cell to SwiftUI (T-019.6).
/// SwiftUI's tap gestures can't tell left from right from middle click, read the
/// modifier state, or see the button — all of which the reference's room
/// interactions need (`Z1R_WPF/DungeonUI.fs:1348-1472`). This overlays a
/// transparent `NSView` that forwards each gesture, mapped to Mac conventions:
/// left = primary, right = room-type picker, **Shift+**click = the monster /
/// floor-drop details (the user's chosen scheme, matching the reference's
/// Shift+click), middle = circle / floor-drop brightness.
///
/// Like `RightClickCatcher`, `hitTest` claims the point **only** during the
/// mouse-down events it handles, so hover and — crucially — scroll fall through
/// to the app's vertical `ScrollView` behind the map. (The reference's
/// scroll-for-details gesture is served here by Shift+click instead.)
struct RoomMouseCatcher: NSViewRepresentable {
    enum Gesture: Equatable {
        case left, right, shiftLeft, shiftRight, middle
    }
    let onGesture: (Gesture) -> Void

    /// Whether the catcher should claim the point for the given in-flight event —
    /// true only for the mouse-down button events it acts on, so scroll / hover /
    /// drag fall through to the content behind. Pulled out so it's unit-testable.
    static func intercepts(_ eventType: NSEvent.EventType?) -> Bool {
        switch eventType {
        case .leftMouseDown, .rightMouseDown, .otherMouseDown: true
        default: false
        }
    }

    func makeNSView(context: Context) -> NSView {
        let view = MouseView()
        view.onGesture = onGesture
        // The SwiftUI cell owns the accessibility element; keep this bridge out
        // of the a11y tree so VoiceOver sees one node per room.
        view.setAccessibilityElement(false)
        return view
    }

    func updateNSView(_ nsView: NSView, context: Context) {
        (nsView as? MouseView)?.onGesture = onGesture
    }

    private final class MouseView: NSView {
        var onGesture: ((Gesture) -> Void)?

        override func hitTest(_ point: NSPoint) -> NSView? {
            RoomMouseCatcher.intercepts(NSApp.currentEvent?.type) ? super.hitTest(point) : nil
        }

        override func mouseDown(with event: NSEvent) {
            onGesture?(event.modifierFlags.contains(.shift) ? .shiftLeft : .left)
        }
        override func rightMouseDown(with event: NSEvent) {
            onGesture?(event.modifierFlags.contains(.shift) ? .shiftRight : .right)
        }
        override func otherMouseDown(with event: NSEvent) {
            if event.buttonNumber == 2 { onGesture?(.middle) }
        }
    }
}
