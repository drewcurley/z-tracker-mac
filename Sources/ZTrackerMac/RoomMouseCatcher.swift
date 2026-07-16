import AppKit
import SwiftUI
import TrackerCore

/// Bridges precise mouse + trackpad input for a dungeon room cell / door to
/// SwiftUI (T-019.6/.11/T-072). SwiftUI's tap gestures can't tell left from right
/// from middle click, read modifiers, see scroll, or paint across a drag — all of
/// which the reference's interactions need (`Z1R_WPF/DungeonUI.fs:1348-1382`,
/// `:717-748`). This overlays a transparent `NSView` that forwards each gesture,
/// mapped to Mac conventions:
///
/// - left = primary, right = secondary picker
/// - two-finger scroll = the reference wheel (room details / door cycle)
/// - ⌥-click = the reference middle-click (room circle/brightness; door yellow)
/// - Shift+click = the reference Shift gestures (accessible fallback)
/// - **drag** (rooms only) = the reference drag-paint: left over off-map → unmarked,
///   right over unmarked → off-map, ⌥/middle over unmarked → default room
///
/// `dragContext`/`onDragPaint` are opt-in: when set (rooms), clicks fire on
/// mouse-**up** so a press-drag paints instead of clicking, and the drag maps the
/// cursor to the room under it. When nil (doors), clicks fire on mouse-**down** as
/// before — so door behavior is unchanged.
struct RoomMouseCatcher: NSViewRepresentable {
    enum Gesture: Equatable {
        case left, right, shiftLeft, shiftRight, middle, optionLeft, scrollUp, scrollDown
    }

    /// This cell's grid position + the column/row pitch, so a drag can be mapped
    /// to whichever room the cursor is over.
    struct DragContext: Equatable {
        var col: Int, row: Int
        var pitchX: CGFloat, pitchY: CGFloat
    }

    let onGesture: (Gesture) -> Void
    var dragContext: DragContext? = nil
    var onDragPaint: ((DungeonRoomMap.DragPaintButton, Int, Int) -> Void)? = nil

    /// Claim only the button-downs + scroll it acts on, so hover/drag-move to
    /// other views and page-scroll (elsewhere) fall through. Unit-testable.
    static func intercepts(_ eventType: NSEvent.EventType?) -> Bool {
        switch eventType {
        case .leftMouseDown, .rightMouseDown, .otherMouseDown, .scrollWheel: true
        default: false
        }
    }

    func makeNSView(context: Context) -> NSView {
        let view = MouseView()
        view.configure(onGesture: onGesture, dragContext: dragContext, onDragPaint: onDragPaint)
        view.setAccessibilityElement(false)
        return view
    }

    func updateNSView(_ nsView: NSView, context: Context) {
        (nsView as? MouseView)?.configure(onGesture: onGesture, dragContext: dragContext, onDragPaint: onDragPaint)
    }

    private final class MouseView: NSView {
        private var onGesture: ((Gesture) -> Void)?
        private var dragContext: DragContext?
        private var onDragPaint: ((DungeonRoomMap.DragPaintButton, Int, Int) -> Void)?

        private var scrollArmed = true
        // In-flight press bookkeeping (for click-on-release + drag detection).
        private var downButton: Int?
        private var downOption = false
        private var downShift = false
        private var didDrag = false
        private var downLocation: NSPoint = .zero
        /// Movement past this (in window points) counts as a drag, not a click —
        /// so a jittery press can't misfire as a paint.
        private let dragThreshold: CGFloat = 4

        // Flipped so local y is top-down, matching the grid's row order.
        override var isFlipped: Bool { true }

        func configure(onGesture: @escaping (Gesture) -> Void,
                       dragContext: DragContext?,
                       onDragPaint: ((DungeonRoomMap.DragPaintButton, Int, Int) -> Void)?) {
            self.onGesture = onGesture
            self.dragContext = dragContext
            self.onDragPaint = onDragPaint
        }

        private var dragEnabled: Bool { dragContext != nil }

        override func hitTest(_ point: NSPoint) -> NSView? {
            RoomMouseCatcher.intercepts(NSApp.currentEvent?.type) ? super.hitTest(point) : nil
        }

        // MARK: Mouse down — fire immediately (doors) or defer to up (rooms).

        override func mouseDown(with event: NSEvent) { beginPress(0, event) }
        override func rightMouseDown(with event: NSEvent) { beginPress(1, event) }
        override func otherMouseDown(with event: NSEvent) {
            if event.buttonNumber == 2 { beginPress(2, event) }
        }

        private func beginPress(_ button: Int, _ event: NSEvent) {
            downButton = button
            downOption = event.modifierFlags.contains(.option)
            downShift = event.modifierFlags.contains(.shift)
            downLocation = event.locationInWindow
            didDrag = false
            // Fire immediately for doors (no drag), and for the LEFT button even on
            // rooms — left-click and left-drag-paint don't conflict (both no-op on
            // a non-off-map room), so the primary click stays on mouse-down and is
            // unaffected. Only right/middle on rooms defer to release (their click
            // — picker / circle — would clash with a right/middle drag-paint).
            if !dragEnabled || button == 0 {
                fireClick(button: button, option: downOption, shift: downShift)
            }
        }

        // MARK: Drag — paint the room under the cursor (rooms only).

        override func mouseDragged(with event: NSEvent) { handleDrag(0, event) }
        override func rightMouseDragged(with event: NSEvent) { handleDrag(1, event) }
        override func otherMouseDragged(with event: NSEvent) { handleDrag(2, event) }

        private func handleDrag(_ button: Int, _ event: NSEvent) {
            guard dragEnabled, let ctx = dragContext, let onDragPaint else { return }
            // Ignore sub-threshold jitter so a click isn't mistaken for a drag.
            let moved = hypot(event.locationInWindow.x - downLocation.x,
                              event.locationInWindow.y - downLocation.y)
            guard didDrag || moved >= dragThreshold else { return }
            didDrag = true
            let p = convert(event.locationInWindow, from: nil)
            let gridX = CGFloat(ctx.col) * ctx.pitchX + p.x
            let gridY = CGFloat(ctx.row) * ctx.pitchY + p.y
            let col = min(max(Int((gridX / ctx.pitchX).rounded(.down)), 0), DungeonRoomMap.cols - 1)
            let row = min(max(Int((gridY / ctx.pitchY).rounded(.down)), 0), DungeonRoomMap.rows - 1)
            let paint: DungeonRoomMap.DragPaintButton = switch button {
                case 1: .right
                case 2: .middle
                default: downOption ? .middle : .left   // ⌥+left-drag stands in for middle
            }
            onDragPaint(paint, col, row)
        }

        // MARK: Mouse up — a click if it wasn't a drag (rooms defer here).

        override func mouseUp(with event: NSEvent) { endPress(0) }
        override func rightMouseUp(with event: NSEvent) { endPress(1) }
        override func otherMouseUp(with event: NSEvent) { endPress(2) }

        private func endPress(_ button: Int) {
            defer { downButton = nil }
            // Left (and all door buttons) already fired on mouse-down; only the
            // deferred right/middle room buttons fire here, and only on a click.
            guard dragEnabled, button != 0, downButton == button, !didDrag else { return }
            fireClick(button: button, option: downOption, shift: downShift)
        }

        private func fireClick(button: Int, option: Bool, shift: Bool) {
            switch button {
            case 1: onGesture?(shift ? .shiftRight : .right)
            case 2: onGesture?(.middle)
            default:
                if shift { onGesture?(.shiftLeft) }
                else if option { onGesture?(.optionLeft) }
                else { onGesture?(.left) }
            }
        }

        // MARK: Scroll — the reference wheel gesture (unchanged).

        override func scrollWheel(with event: NSEvent) {
            if event.momentumPhase != [] { return }
            let dy = event.scrollingDeltaY
            if event.hasPreciseScrollingDeltas {
                switch event.phase {
                case .began: scrollArmed = true
                case .ended, .cancelled: scrollArmed = true; return
                default: break
                }
                guard scrollArmed, abs(dy) > 1.5 else { return }
                scrollArmed = false
            } else {
                guard dy != 0 else { return }
            }
            onGesture?(dy > 0 ? .scrollUp : .scrollDown)
        }
    }
}
