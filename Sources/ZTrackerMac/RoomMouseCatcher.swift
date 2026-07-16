import AppKit
import SwiftUI

/// Bridges precise mouse + trackpad input for a dungeon room cell / door to
/// SwiftUI (T-019.6/.11). SwiftUI's tap gestures can't tell left from right from
/// middle click, read modifiers, or see scroll — all of which the reference's
/// interactions need (`Z1R_WPF/DungeonUI.fs:1348-1472`, `:717-748`). This overlays
/// a transparent `NSView` that forwards each gesture, mapped to Mac conventions:
///
/// - left = primary, right = secondary picker
/// - **two-finger scroll** = the reference wheel gesture (room monster/floor-drop
///   popups; door cycle) — the shift-free, Windows-like path (user choice)
/// - **⌥-click** = the reference middle-click (room circle/brightness; door yellow)
///   — since Mac mice/trackpads have no middle button
/// - Shift+click = the reference Shift gestures (kept as an accessible fallback)
///
/// `hitTest` claims the point only during the events it handles (incl. scroll),
/// so hover and untouched regions fall through. Consuming scroll over a cell is
/// the deliberate tradeoff for the wheel gesture (doors are tiny; the room grid
/// is larger — accepted per the user).
struct RoomMouseCatcher: NSViewRepresentable {
    enum Gesture: Equatable {
        case left, right, shiftLeft, shiftRight, middle, optionLeft, scrollUp, scrollDown
    }
    let onGesture: (Gesture) -> Void

    /// Whether the catcher should claim the point for the given in-flight event —
    /// the button-downs and scroll it acts on, so hover/drag fall through. Pulled
    /// out so it's unit-testable.
    static func intercepts(_ eventType: NSEvent.EventType?) -> Bool {
        switch eventType {
        case .leftMouseDown, .rightMouseDown, .otherMouseDown, .scrollWheel: true
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
        /// One scroll action per trackpad gesture (a flick emits many events).
        private var scrollArmed = true

        override func hitTest(_ point: NSPoint) -> NSView? {
            RoomMouseCatcher.intercepts(NSApp.currentEvent?.type) ? super.hitTest(point) : nil
        }

        override func mouseDown(with event: NSEvent) {
            let flags = event.modifierFlags
            if flags.contains(.shift) { onGesture?(.shiftLeft) }
            else if flags.contains(.option) { onGesture?(.optionLeft) }
            else { onGesture?(.left) }
        }

        override func rightMouseDown(with event: NSEvent) {
            onGesture?(event.modifierFlags.contains(.shift) ? .shiftRight : .right)
        }

        override func otherMouseDown(with event: NSEvent) {
            if event.buttonNumber == 2 { onGesture?(.middle) }
        }

        override func scrollWheel(with event: NSEvent) {
            // Ignore the inertial momentum tail so a flick fires exactly once.
            if event.momentumPhase != [] { return }
            let dy = event.scrollingDeltaY
            if event.hasPreciseScrollingDeltas {
                // Trackpad: one action per gesture, re-armed at each phase boundary.
                switch event.phase {
                case .began: scrollArmed = true
                case .ended, .cancelled: scrollArmed = true; return
                default: break
                }
                guard scrollArmed, abs(dy) > 1.5 else { return }
                scrollArmed = false
            } else {
                guard dy != 0 else { return }   // classic wheel: one per detent
            }
            onGesture?(dy > 0 ? .scrollUp : .scrollDown)
        }
    }
}
