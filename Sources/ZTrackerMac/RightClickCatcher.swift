import AppKit
import SwiftUI

/// Catches a secondary (right) click while letting normal taps pass through
/// to SwiftUI — macOS SwiftUI has no native right-click gesture. Used to set
/// a box / item to "don't have it". Shared by the dungeon tracker and the
/// overworld item grid.
struct RightClickCatcher: NSViewRepresentable {
    var action: () -> Void
    func makeNSView(context: Context) -> NSView { CatcherView(action: action) }
    func updateNSView(_ nsView: NSView, context: Context) {
        (nsView as? CatcherView)?.action = action
    }
    private final class CatcherView: NSView {
        var action: () -> Void
        init(action: @escaping () -> Void) { self.action = action; super.init(frame: .zero) }
        required init?(coder: NSCoder) { nil }
        override func rightMouseDown(with event: NSEvent) { action() }
    }
}

extension View {
    func onRightClick(perform action: @escaping () -> Void) -> some View {
        background(RightClickCatcher(action: action))
    }
}
