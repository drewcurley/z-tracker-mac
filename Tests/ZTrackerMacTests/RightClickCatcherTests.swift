import AppKit
import Testing
@testable import ZTrackerMac

@Suite("RightClickCatcher.intercepts")
struct RightClickCatcherTests {
    @Test("only right-mouse events are intercepted")
    func rightMouseIntercepted() {
        #expect(RightClickCatcher.intercepts(.rightMouseDown))
        #expect(RightClickCatcher.intercepts(.rightMouseUp))
        #expect(RightClickCatcher.intercepts(.rightMouseDragged))
    }

    @Test("left-mouse, hover, scroll and 'no event' fall through")
    func othersPassThrough() {
        #expect(!RightClickCatcher.intercepts(.leftMouseDown))
        #expect(!RightClickCatcher.intercepts(.leftMouseUp))
        #expect(!RightClickCatcher.intercepts(.mouseMoved))
        #expect(!RightClickCatcher.intercepts(.scrollWheel))
        #expect(!RightClickCatcher.intercepts(nil))
    }
}
