import CoreGraphics
import Testing
@testable import ZTrackerMac

@Suite("FlowPacking — top-section reflow")
struct FlowPackingTests {
    @Test("everything fits on one row when wide enough")
    func oneRow() {
        let rows = FlowPacking.rows(widths: [100, 100, 100], maxWidth: 1000, spacing: 10)
        #expect(rows == [[0, 1, 2]])
    }

    @Test("wraps to a new row when the next item overflows (spacing counted)")
    func wraps() {
        // 100 + 10 + 100 = 210 fits in 210; adding +10+100 = 320 > 210 → wrap.
        let rows = FlowPacking.rows(widths: [100, 100, 100], maxWidth: 210, spacing: 10)
        #expect(rows == [[0, 1], [2]])
    }

    @Test("an item wider than maxWidth still gets its own row (never dropped)")
    func oversizeItemOwnRow() {
        let rows = FlowPacking.rows(widths: [50, 500, 50], maxWidth: 120, spacing: 10)
        // 50 alone; 500 can't fit so it wraps to its own row; 50 wraps again.
        #expect(rows == [[0], [1], [2]])
        // Every index is placed exactly once, in order.
        #expect(rows.flatMap { $0 } == [0, 1, 2])
    }

    @Test("narrowing to a single column stacks all four groups")
    func singleColumn() {
        let rows = FlowPacking.rows(widths: [700, 230, 120, 200], maxWidth: 250, spacing: 12)
        // 700 (own row), 230 (own row), 120+12+200=332>250 so 120 alone then 200.
        #expect(rows == [[0], [1], [2], [3]])
    }

    @Test("empty input yields no rows")
    func empty() {
        #expect(FlowPacking.rows(widths: [], maxWidth: 500, spacing: 10).isEmpty)
    }
}
