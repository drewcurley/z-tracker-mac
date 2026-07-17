import SwiftUI
import TrackerCore

/// The Timeline (T-098, phase 1): a horizontal minute-axis retrospective of when
/// each item / triforce / heart was acquired, with the finish time. Ported from
/// the reference's item strip (`Z1R_WPF/Timeline.fs`); the overworld-progress
/// line graph is phase 2. Each icon sits above the minute it was acquired; hover
/// shows the exact split.
struct GameTimelineView: View {
    @Bindable var timeline: TimelineModel

    private let pxPerMinute: CGFloat = 26
    private let iconSize: CGFloat = 18
    private let rowHeight: CGFloat = 21
    private let axisHeight: CGFloat = 16
    private let topPad: CGFloat = 4

    /// Events sorted by time, each with a stacking row within its minute bucket.
    private var placed: [(event: TimelineEvent, seconds: Int, row: Int)] {
        let sorted = timeline.acquiredAt.sorted {
            $0.value != $1.value ? $0.value < $1.value : $0.key.displayName < $1.key.displayName
        }
        var perMinute: [Int: Int] = [:]
        return sorted.map { (event, seconds) in
            let minute = seconds / 60
            let row = perMinute[minute, default: 0]
            perMinute[minute] = row + 1
            return (event, seconds, row)
        }
    }

    /// The last minute the axis needs to cover (≥ 10 for a sensible empty axis).
    private var maxMinute: Int {
        let lastEvent = timeline.acquiredAt.values.max() ?? 0
        let finish = timeline.finishSeconds ?? 0
        return max(10, (max(lastEvent, finish, timeline.latestSeconds)) / 60 + 1)
    }

    private var maxRows: Int {
        max(1, placed.map(\.row).max().map { $0 + 1 } ?? 1)
    }

    private var contentWidth: CGFloat { CGFloat(maxMinute + 1) * pxPerMinute + 60 }
    // +45 (was +20): the freed space from moving the recorder widget gives the
    // timeline ~25px more height (T-107), mostly for the OW-progress graph.
    private var contentHeight: CGFloat { topPad + CGFloat(maxRows) * rowHeight + axisHeight + 45 }

    var body: some View {
        ScrollView(.horizontal, showsIndicators: true) {
            ZStack(alignment: .topLeading) {
                minuteGrid
                owProgressGraph
                ForEach(Array(placed.enumerated()), id: \.offset) { _, p in
                    icon(for: p.event)
                        .frame(width: iconSize, height: iconSize)
                        .contentShape(Rectangle())
                        // Hover: split time first, then the item, then where it was
                        // found if known — e.g. "31:03  Silver Arrow — LEVEL-3 Box 1"
                        // (T-114). The `.help` must wrap the *sized* icon, before
                        // `.position` (which expands the frame to fill the ZStack —
                        // applying `.help` after made every tooltip cover the whole
                        // timeline, so none tracked its icon, T-118).
                        .help("\(split(p.seconds))  \(p.event.displayName)"
                              + (timeline.acquiredLocation[p.event].map { " — \($0)" } ?? ""))
                        .position(x: x(forSeconds: p.seconds),
                                  y: topPad + CGFloat(p.row) * rowHeight + iconSize / 2)
                }
                finishMarker
            }
            .frame(width: contentWidth, height: contentHeight, alignment: .topLeading)
        }
        .frame(height: contentHeight)
    }

    /// Vertical minute gridlines + labels along the bottom.
    private var minuteGrid: some View {
        let gridTop = topPad
        let gridBottom = contentHeight - axisHeight - 4
        return ZStack(alignment: .topLeading) {
            Canvas { ctx, _ in
                for m in 0...maxMinute {
                    let px = CGFloat(m) * pxPerMinute + iconSize / 2
                    var path = Path()
                    path.move(to: CGPoint(x: px, y: gridTop))
                    path.addLine(to: CGPoint(x: px, y: gridBottom))
                    ctx.stroke(path, with: .color(Color(white: m % 5 == 0 ? 0.32 : 0.16)),
                               lineWidth: m % 5 == 0 ? 1 : 0.5)
                }
            }
            ForEach(Array(stride(from: 0, through: maxMinute, by: 5)), id: \.self) { m in
                Text("\(m)m")
                    .font(.system(size: 9, design: .monospaced))
                    .foregroundStyle(.secondary)
                    .position(x: CGFloat(m) * pxPerMinute + iconSize / 2, y: contentHeight - axisHeight)
            }
        }
    }

    /// The overworld-progress line (T-099): remaining unmarked screens over time,
    /// trending toward 0 at the top as you clear the map (reference DarkCyan line).
    @ViewBuilder
    private var owProgressGraph: some View {
        let samples = timeline.owRemainingSamples
        if samples.count >= 1 {
            let maxRemain = max(samples.map(\.remaining).max() ?? 1, 1)
            let graphTop = topPad
            let graphBottom = contentHeight - axisHeight - 4
            let graphH = graphBottom - graphTop
            Canvas { ctx, _ in
                func y(_ r: Int) -> CGFloat { graphTop + graphH * CGFloat(r) / CGFloat(maxRemain) }
                var path = Path()
                path.move(to: CGPoint(x: x(forSeconds: samples[0].seconds), y: y(samples[0].remaining)))
                for s in samples.dropFirst() {
                    path.addLine(to: CGPoint(x: x(forSeconds: s.seconds), y: y(s.remaining)))
                }
                // Hold the last value out to "now" (the graph's right edge).
                let lastX = x(forSeconds: max(timeline.latestSeconds, samples.last!.seconds))
                path.addLine(to: CGPoint(x: lastX, y: y(samples.last!.remaining)))
                ctx.stroke(path, with: .color(Color(red: 0, green: 0.55, blue: 0.55)), lineWidth: 2)
            }
            Text("OW").font(.system(size: 8)).foregroundStyle(Color(red: 0, green: 0.55, blue: 0.55))
                .position(x: 10, y: topPad + 6)
        }
    }

    @ViewBuilder
    private var finishMarker: some View {
        if let f = timeline.finishSeconds {
            let label = "Finish \(split(f))" + (timeline.finishOwRemaining.map { " · \($0) OW left" } ?? "")
            Text(label)
                .font(.system(size: 10, weight: .bold))
                .foregroundStyle(.green)
                .fixedSize()
                .position(x: x(forSeconds: f) + 4, y: contentHeight - axisHeight - 12)
        }
    }

    private func x(forSeconds seconds: Int) -> CGFloat {
        CGFloat(Double(seconds) / 60.0) * pxPerMinute + iconSize / 2
    }

    private func split(_ seconds: Int) -> String {
        String(format: "%d:%02d", seconds / 60, seconds % 60)
    }

    /// The icon for a timeline event — the item atlas where it maps, else an SF
    /// Symbol (triforces have no atlas icon).
    @ViewBuilder
    private func icon(for event: TimelineEvent) -> some View {
        if case .triforce = event {
            Image(systemName: "triangle.fill").font(.system(size: 12)).foregroundStyle(.yellow)
        } else if let atlas = Self.atlasIcon(for: event),
                  let img = Image(atlasIcon: ItemIconAtlas.cgImage(atlas)) {
            img.interpolation(.none).resizable()
        } else {
            Image(systemName: "circle.fill").font(.system(size: 10)).foregroundStyle(.secondary)
        }
    }

    private static func atlasIcon(for event: TimelineEvent) -> ItemIconAtlas.Icon? {
        switch event {
        case .woodSword: .brownSword
        case .whiteSword: .whiteSword
        case .magicalSword: .magicalSword
        case .boomerang: .boomerang
        case .magicBoomerang: .magicBoomerang
        case .woodArrow: .woodArrow
        case .silverArrow: .silverArrow
        case .blueCandle: .blueCandle
        case .redCandle: .redCandle
        case .blueRing: .blueRing
        case .redRing: .redRing
        case .book: .book
        case .boomstickBook: .boomBook
        case .bow: .bow
        case .wand: .wand
        case .powerBracelet: .powerBracelet
        case .raft: .raft
        case .recorder: .recorder
        case .anyKey: .key
        case .ladder: .ladder
        case .defeatedGanon: .ganon
        case .rescuedZelda: .zelda
        case .takeAnyHeart, .dungeonHeart, .coastHeart: .heartContainer
        case .bait: .bait
        case .triforce: nil
        }
    }
}
