import Testing
import CoreGraphics
@testable import ZTrackerMac

/// T-255 — the mouse magnifier shows `viewSize ÷ 3` of the tracker, centered on the pointer.
@Suite("Mouse magnifier (T-255)")
@MainActor
struct MouseMagnifierTests {
    @Test("the captured region is a third of the window, centered on the pointer")
    func captureRect() {
        let r = MouseMagnifierCapture.captureRect(pointer: CGPoint(x: 300, y: 200),
                                                  viewSize: CGSize(width: 600, height: 450))
        #expect(r == CGRect(x: 200, y: 125, width: 200, height: 150))
        #expect(r.midX == 300 && r.midY == 200)
    }

    @Test("a degenerate window size still yields a non-empty region")
    func tinyView() {
        let r = MouseMagnifierCapture.captureRect(pointer: .zero, viewSize: .zero)
        #expect(r.width >= 1 && r.height >= 1)
    }
}
