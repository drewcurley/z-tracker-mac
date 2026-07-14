import AppKit
import SwiftUI

/// Catches a secondary (right) click while letting normal taps and hover pass
/// through to SwiftUI — macOS SwiftUI has no native right-click gesture. Used
/// to set a box / item to "don't have it". Shared by the dungeon tracker and
/// the overworld item grid.
///
/// Implemented as an **overlay** (in front of the content), not a background:
/// a background NSView sits behind SwiftUI's own gesture layer, which swallows
/// the event before the catcher sees it. To avoid stealing left-clicks/hover,
/// `hitTest` only claims the point during a right-mouse event and returns nil
/// otherwise, so every other interaction falls through to the view behind.
struct RightClickCatcher: NSViewRepresentable {
    var action: () -> Void
    func makeNSView(context: Context) -> NSView { CatcherView(action: action) }
    func updateNSView(_ nsView: NSView, context: Context) {
        (nsView as? CatcherView)?.action = action
    }

    /// Whether the catcher should claim the point for the given in-flight event
    /// — true only for right-mouse events, so left-click / hover / scroll fall
    /// through to the SwiftUI content behind. Pulled out so it is unit-testable.
    static func intercepts(_ eventType: NSEvent.EventType?) -> Bool {
        switch eventType {
        case .rightMouseDown, .rightMouseUp, .rightMouseDragged: true
        default: false
        }
    }

    private final class CatcherView: NSView {
        var action: () -> Void
        init(action: @escaping () -> Void) { self.action = action; super.init(frame: .zero) }
        required init?(coder: NSCoder) { nil }

        override func hitTest(_ point: NSPoint) -> NSView? {
            RightClickCatcher.intercepts(NSApp.currentEvent?.type) ? super.hitTest(point) : nil
        }

        override func rightMouseDown(with event: NSEvent) { action() }
    }
}

extension View {
    func onRightClick(perform action: @escaping () -> Void) -> some View {
        overlay(RightClickCatcher(action: action))
    }
}
