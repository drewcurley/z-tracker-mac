import AppKit
import Testing
@testable import ZTrackerMac

/// T-019.6 — the room mouse catcher must claim only the button-down events it
/// acts on, so scroll (page scrolling) and hover fall through to the content
/// behind the dungeon map.
@Suite("Room mouse catcher hit-test gating (T-019.6)")
struct RoomMouseCatcherTests {
    @Test("claims left/right/other mouse-down")
    func claimsButtonDowns() {
        #expect(RoomMouseCatcher.intercepts(.leftMouseDown))
        #expect(RoomMouseCatcher.intercepts(.rightMouseDown))
        #expect(RoomMouseCatcher.intercepts(.otherMouseDown))
    }

    @Test("falls through for scroll, drag, up, and hover (nil event)")
    func fallsThrough() {
        #expect(!RoomMouseCatcher.intercepts(.scrollWheel))
        #expect(!RoomMouseCatcher.intercepts(.leftMouseDragged))
        #expect(!RoomMouseCatcher.intercepts(.leftMouseUp))
        #expect(!RoomMouseCatcher.intercepts(.mouseMoved))
        #expect(!RoomMouseCatcher.intercepts(nil))
    }
}
