import Testing
import CoreGraphics
@testable import ZTrackerMac

/// T-256 — the room pickers' NSPopover stand-in: placement math.
@Suite("Picker panel placement (T-256)")
@MainActor
struct PickerPanelTests {
    let screen = CGRect(x: 0, y: 0, width: 1000, height: 800)

    @Test("centered just below the anchor (screen coordinates, bottom-left origin)")
    func below() {
        let f = PickerPanelHost.frame(size: CGSize(width: 200, height: 100),
                                      anchor: CGRect(x: 400, y: 500, width: 40, height: 30), visible: screen)
        #expect(f == CGRect(x: 320, y: 396, width: 200, height: 100))
    }

    @Test("flips above the anchor when there's no room below, and stays on screen")
    func aboveAndClamped() {
        let f = PickerPanelHost.frame(size: CGSize(width: 200, height: 100),
                                      anchor: CGRect(x: -50, y: 40, width: 40, height: 30), visible: screen)
        #expect(f.minY == 74)        // anchor.maxY + gap
        #expect(f.minX == 0)         // clamped to the left edge
    }

    @Test("the anchor follows the UI zoom (global size ÷ local size)")
    func zoomedAnchor() {
        let a = pickerPanelGlobalAnchor(CGRect(x: 10, y: 20, width: 30, height: 40),
                                        frame: CGRect(x: 100, y: 200, width: 400, height: 400),
                                        localSize: CGSize(width: 200, height: 200))
        #expect(a == CGRect(x: 120, y: 240, width: 60, height: 80))
        let whole = CGRect(x: 1, y: 2, width: 3, height: 4)
        #expect(pickerPanelGlobalAnchor(.zero, frame: whole, localSize: CGSize(width: 3, height: 4)) == whole)
    }
}
