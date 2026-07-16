import Testing
import CoreGraphics
@testable import ZTrackerMac

/// T-046.2 — a restored window frame must never land off every connected screen
/// (the disconnected-external-display orphan bug). These exercise the pure
/// geometry that decides "reachable" vs "re-home onto the primary".
@Suite("Window frame clamp (T-046.2)")
struct WindowFrameClampTests {
    // A primary display at the origin and a secondary above-left of it (negative
    // y), mirroring the user's VM-side monitor setup.
    let primary = CGRect(x: 0, y: 0, width: 1512, height: 950)
    let secondary = CGRect(x: 2122, y: -1409, width: 1200, height: 1409)

    @Test("a frame fully on a live screen is reachable")
    func onScreen() {
        let frame = CGRect(x: 100, y: 100, width: 800, height: 600)
        #expect(WindowFrameClamp.isReachable(frame, screenFrames: [primary, secondary]))
    }

    @Test("a frame on the secondary is reachable while it's connected")
    func onSecondary() {
        let frame = CGRect(x: 2222, y: -1300, width: 1000, height: 800)
        #expect(WindowFrameClamp.isReachable(frame, screenFrames: [primary, secondary]))
    }

    @Test("a frame on a now-disconnected display is not reachable")
    func orphaned() {
        // Same secondary frame, but the secondary is gone — only primary remains.
        let frame = CGRect(x: 2222, y: -1300, width: 1000, height: 800)
        #expect(!WindowFrameClamp.isReachable(frame, screenFrames: [primary]))
    }

    @Test("a title bar barely peeking on-screen (< min width) is not reachable")
    func sliverIsNotReachable() {
        // Only 50pt of the window's title bar overlaps the primary's right edge.
        let frame = CGRect(x: primary.maxX - 50, y: 100, width: 800, height: 600)
        #expect(!WindowFrameClamp.isReachable(frame, screenFrames: [primary]))
    }

    @Test("orphaned frame is re-homed onto the primary, keeping its size")
    func rehomeKeepsSize() {
        let frame = CGRect(x: 2222, y: -1300, width: 1000, height: 800)
        let resolved = WindowFrameClamp.resolved(frame, screenFrames: [primary], primaryVisible: primary)
        let r = try! #require(resolved)
        // Size preserved (fits within the primary).
        #expect(r.width == 1000)
        #expect(r.height == 800)
        // Centered on the primary and fully within it.
        #expect(r.midX == primary.midX)
        #expect(r.midY == primary.midY)
        #expect(primary.contains(r))
    }

    @Test("a reachable frame is returned unchanged")
    func reachableUnchanged() {
        let frame = CGRect(x: 100, y: 100, width: 800, height: 600)
        let resolved = WindowFrameClamp.resolved(frame, screenFrames: [primary], primaryVisible: primary)
        #expect(resolved == frame)
    }

    @Test("an oversized orphaned frame is clamped to the primary's size")
    func rehomeClampsOversize() {
        let frame = CGRect(x: 5000, y: 5000, width: 4000, height: 3000)
        let resolved = WindowFrameClamp.resolved(frame, screenFrames: [primary], primaryVisible: primary)
        let r = try! #require(resolved)
        #expect(r.width == primary.width)
        #expect(r.height == primary.height)
        #expect(primary.contains(r))
    }

    @Test("no screens at all returns nil (caller skips the restore)")
    func headless() {
        let frame = CGRect(x: 100, y: 100, width: 800, height: 600)
        #expect(WindowFrameClamp.resolved(frame, screenFrames: [], primaryVisible: nil) == nil)
    }
}
