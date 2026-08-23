import SwiftUI
import TrackerCore

/// The Timeline (T-098, phase 1): a horizontal minute-axis retrospective of when
/// each item / triforce / heart was acquired, with the finish time. Ported from
/// the reference's item strip (`Z1R_WPF/Timeline.fs`); the overworld-progress
/// line graph is phase 2. Each icon sits above the minute it was acquired; hover
/// shows the exact split.
struct GameTimelineView: View {
    @Bindable var timeline: TimelineModel

    /// Fallback px/min used only before the pane width is measured.
    private let fallbackPxPerMinute: CGFloat = 26
    /// Right-edge margin reserved for the finish label / last icon so they don't clip.
    private let rightMargin: CGFloat = 60
    private let iconSize: CGFloat = 18
    private let rowHeight: CGFloat = 21
    private let axisHeight: CGFloat = 16
    private let topPad: CGFloat = 4

    /// The index (into `placed`) of the icon under the cursor, for the hover label.
    @State private var hovered: Int?
    /// The pane's width, measured by the background `GeometryReader`, so the timeline always
    /// fits the whole run to the window (T-209).
    @State private var availableWidth: CGFloat = 0

    /// Minutes-per-pixel that makes the **whole run always fill the pane width** — never capped,
    /// so a short run spans the full width and each pixel simply represents more time as the run
    /// grows (time-compressed, entire duration always in view; no scrolling). Falls back until
    /// the width is measured.
    private var pxPerMinute: CGFloat {
        guard availableWidth > rightMargin else { return fallbackPxPerMinute }
        return (availableWidth - rightMargin) / CGFloat(maxMinute + 1)
    }

    /// Events sorted by time, each with a stacking row so overlapping icons stack vertically.
    /// Bucketed by *pixel proximity* (an icon-width's worth of run-time at the current scale),
    /// not a fixed minute — so a compressed long run stacks nearby pickups instead of overlapping.
    private var placed: [(event: TimelineEvent, seconds: Int, row: Int)] {
        let sorted = timeline.acquiredAt.sorted {
            $0.value != $1.value ? $0.value < $1.value : $0.key.displayName < $1.key.displayName
        }
        let bucketSeconds = max(60, Int((Double(iconSize) / Double(pxPerMinute) * 60).rounded(.up)))
        var perBucket: [Int: Int] = [:]
        return sorted.map { (event, seconds) in
            let bucket = seconds / bucketSeconds
            let row = perBucket[bucket, default: 0]
            perBucket[bucket] = row + 1
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

    // The whole run always fits the pane, so the content is exactly the pane width (never scrolls).
    private var contentWidth: CGFloat {
        availableWidth > rightMargin ? availableWidth : CGFloat(maxMinute + 1) * fallbackPxPerMinute + rightMargin
    }

    /// Minutes between minor gridlines, grown so lines stay ≥ ~14px apart at the current scale.
    private var gridStep: Int { niceStep(minPx: 14) }
    /// Minutes between labeled/major gridlines, grown so labels (~"NNNm") don't collide.
    private var labelStep: Int { niceStep(minPx: 48) }
    /// The smallest "nice" step (1,2,3,5,10,15,…) giving at least `minPx` between marks.
    private func niceStep(minPx: CGFloat) -> Int {
        let raw = Int((minPx / pxPerMinute).rounded(.up))
        for n in [1, 2, 3, 5, 10, 15, 20, 30, 60, 120, 240] where n >= raw { return n }
        return 480
    }
    // +45 (was +20): the freed space from moving the recorder widget gives the
    // timeline ~25px more height (T-107), mostly for the OW-progress graph.
    private var contentHeight: CGFloat { topPad + CGFloat(maxRows) * rowHeight + axisHeight + 45 }

    var body: some View {
        ScrollView(.horizontal, showsIndicators: true) {
            ZStack(alignment: .topLeading) {
                minuteGrid
                owProgressGraph
                ForEach(Array(placed.enumerated()), id: \.offset) { index, p in
                    icon(for: p.event)
                        .frame(width: iconSize, height: iconSize)
                        .contentShape(Rectangle())
                        // A visible hover label (T-119) — macOS `.help` tooltips are
                        // unreliable inside a ScrollView + `.position`, so we track the
                        // hovered icon and draw the split label ourselves (below).
                        .onHover { inside in
                            if inside { hovered = index }
                            else if hovered == index { hovered = nil }
                        }
                        .position(x: x(forSeconds: p.seconds),
                                  y: topPad + CGFloat(p.row) * rowHeight + iconSize / 2)
                }
                hoverLabel
                finishMarker
            }
            .frame(width: contentWidth, height: contentHeight, alignment: .topLeading)
        }
        .frame(height: contentHeight)
        // Measure the pane width (T-209) so `pxPerMinute` can fit the whole run. Measured on
        // the outer frame, not the content, so there's no layout feedback loop.
        .background(GeometryReader { geo in
            Color.clear
                .onAppear { availableWidth = geo.size.width }
                .onChange(of: geo.size.width) { _, w in availableWidth = w }
        })
    }

    /// Vertical minute gridlines + labels along the bottom.
    private var minuteGrid: some View {
        let gridTop = topPad
        let gridBottom = contentHeight - axisHeight - 4
        let minor = gridStep, major = labelStep
        return ZStack(alignment: .topLeading) {
            Canvas { ctx, _ in
                func line(_ m: Int, opacity: Double, width: CGFloat) {
                    let px = CGFloat(m) * pxPerMinute + iconSize / 2
                    var path = Path()
                    path.move(to: CGPoint(x: px, y: gridTop))
                    path.addLine(to: CGPoint(x: px, y: gridBottom))
                    ctx.stroke(path, with: .color(Color.primary.opacity(opacity)), lineWidth: width)
                }
                for m in stride(from: 0, through: maxMinute, by: minor) { line(m, opacity: 0.22, width: 0.5) }
                // Bold lines exactly at the labeled minutes (drawn second so they read as major
                // regardless of whether `major` is a multiple of `minor`).
                for m in stride(from: 0, through: maxMinute, by: major) { line(m, opacity: 0.45, width: 1) }
            }
            ForEach(Array(stride(from: 0, through: maxMinute, by: major)), id: \.self) { m in
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

    /// The split label for the icon under the cursor — "31:03  Silver Arrow —
    /// LEVEL-3 Box 1" — drawn just above the icon, clamped to the content width, and
    /// non-interactive so it never eats the hover (T-119).
    @ViewBuilder
    private var hoverLabel: some View {
        if let i = hovered, i < placed.count {
            let p = placed[i]
            let text = "\(split(p.seconds))  \(p.event.displayName)"
                + (timeline.acquiredLocation[p.event].map { " — \($0)" } ?? "")
            let iconX = x(forSeconds: p.seconds)
            let iconY = topPad + CGFloat(p.row) * rowHeight + iconSize / 2
            // Estimate the label width (monospaced ~6pt/char + padding) to keep it
            // clamped on screen and centered above the icon.
            let estWidth = CGFloat(text.count) * 6 + 12
            let labelX = min(max(iconX, estWidth / 2 + 2), contentWidth - estWidth / 2 - 2)
            Text(text)
                .font(.system(size: 10, weight: .semibold, design: .monospaced))
                .foregroundStyle(.white)
                .fixedSize()
                .padding(.horizontal, 6)
                .padding(.vertical, 3)
                .background(RoundedRectangle(cornerRadius: 4).fill(.black.opacity(0.9)))
                .overlay(RoundedRectangle(cornerRadius: 4).strokeBorder(.white.opacity(0.25)))
                .position(x: labelX, y: max(iconY - rowHeight, 8))
                .allowsHitTesting(false)
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
