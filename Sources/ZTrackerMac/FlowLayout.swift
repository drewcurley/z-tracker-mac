import SwiftUI

/// Pure row-packing for `FlowLayout` (T-043), split out so the wrap logic is
/// unit-testable without hosting a real layout. Given each item's width, groups
/// their indices into rows left-to-right, starting a new row whenever the next
/// item (plus `spacing`) would overflow `maxWidth`. An item wider than
/// `maxWidth` still occupies its own row alone (it can't be split).
enum FlowPacking {
    static func rows(widths: [CGFloat], maxWidth: CGFloat, spacing: CGFloat) -> [[Int]] {
        var rows: [[Int]] = []
        var current: [Int] = []
        var currentWidth: CGFloat = 0
        for (i, w) in widths.enumerated() {
            let prospective = current.isEmpty ? w : currentWidth + spacing + w
            if !current.isEmpty && prospective > maxWidth {
                rows.append(current)
                current = [i]
                currentWidth = w
            } else {
                current.append(i)
                currentWidth = prospective
            }
        }
        if !current.isEmpty { rows.append(current) }
        return rows
    }
}

/// A left-to-right flow layout: lays subviews in a row until the next won't fit
/// the proposed width, then wraps to a new line. Used so the top-section groups
/// (dungeons · obtainables · flags · info) reflow when the window is narrowed
/// (T-043). Rows are top-aligned; each subview is measured at its ideal size.
struct FlowLayout: Layout {
    var spacing: CGFloat = 10
    var lineSpacing: CGFloat = 10

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let sizes = subviews.map { $0.sizeThatFits(.unspecified) }
        let maxWidth = proposal.width ?? sizes.map(\.width).max() ?? 0
        let rows = FlowPacking.rows(widths: sizes.map(\.width), maxWidth: maxWidth, spacing: spacing)
        let width = rows.map { row in
            row.reduce(0) { $0 + sizes[$1].width } + spacing * CGFloat(max(0, row.count - 1))
        }.max() ?? 0
        let height = rows.map { row in
            row.map { sizes[$0].height }.max() ?? 0
        }.reduce(0, +) + lineSpacing * CGFloat(max(0, rows.count - 1))
        return CGSize(width: width, height: height)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let sizes = subviews.map { $0.sizeThatFits(.unspecified) }
        let rows = FlowPacking.rows(widths: sizes.map(\.width), maxWidth: bounds.width, spacing: spacing)
        var y = bounds.minY
        for row in rows {
            var x = bounds.minX
            let rowHeight = row.map { sizes[$0].height }.max() ?? 0
            for i in row {
                subviews[i].place(
                    at: CGPoint(x: x, y: y),
                    anchor: .topLeading,
                    proposal: ProposedViewSize(sizes[i])
                )
                x += sizes[i].width + spacing
            }
            y += rowHeight + lineSpacing
        }
    }
}

/// A titled card that wraps one top-section group so the four groups read as
/// distinct areas (T-043). Kept lightweight — a small caption header over a
/// dark rounded panel.
struct TopSectionGroup<Content: View>: View {
    let title: String
    @ViewBuilder var content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.caption2.weight(.semibold))
                .foregroundStyle(.secondary)
                .textCase(.uppercase)
            content
        }
        .padding(8)
        .background(RoundedRectangle(cornerRadius: 8).fill(Color(white: 0.09)))
        .overlay(RoundedRectangle(cornerRadius: 8).strokeBorder(Color(white: 0.16), lineWidth: 1))
    }
}
