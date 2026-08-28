import AppKit
import SwiftUI
import TrackerCore

extension Color {
    /// A `Color` from a `#RRGGBB` string (the commentary runner colors, T-215). Falls back to
    /// black on a malformed string.
    init(commentaryHex hex: String) {
        let s = hex.hasPrefix("#") ? String(hex.dropFirst()) : hex
        self.init(rgb: Int(s, radix: 16) ?? 0)
    }

    /// This color as `#RRGGBB` (sRGB), for storing a `ColorPicker` value back into the model.
    func commentaryHexString() -> String {
        let ns = NSColor(self).usingColorSpace(.sRGB) ?? .black
        return String(format: "#%02X%02X%02X",
                      Int((ns.redComponent * 255).rounded()),
                      Int((ns.greenComponent * 255).rounded()),
                      Int((ns.blueComponent * 255).rounded()))
    }
}

extension Binding where Value == String {
    /// Bridges a `#RRGGBB` string binding to a `Color` binding for a SwiftUI `ColorPicker` (T-215).
    var commentaryColor: Binding<Color> {
        Binding<Color>(get: { Color(commentaryHex: wrappedValue) },
                       set: { wrappedValue = $0.commentaryHexString() })
    }
}

/// True while the ⌥ (option) key is down for the current event — used to route Commentary-Mode
/// clicks (⌥-click = runner 1, ⌥-right-click = runner 2) apart from normal marking (T-215).
@MainActor func commentaryOptionKeyDown() -> Bool {
    NSApp.currentEvent?.modifierFlags.contains(.option) == true
}

/// Catches **only ⌥+right-click**, letting every normal right-click fall through to the tile's
/// usual handling (the context menu in menu mode, the graphical chooser otherwise). Layered on a
/// tile only while Commentary Mode is on, so ⌥-right-click can toggle runner 2 (T-215).
struct OptionRightClickCatcher: NSViewRepresentable {
    var action: () -> Void
    func makeNSView(context: Context) -> NSView { CatcherView(action: action) }
    func updateNSView(_ nsView: NSView, context: Context) { (nsView as? CatcherView)?.action = action }

    private final class CatcherView: NSView {
        var action: () -> Void
        init(action: @escaping () -> Void) { self.action = action; super.init(frame: .zero) }
        required init?(coder: NSCoder) { nil }
        override func hitTest(_ point: NSPoint) -> NSView? {
            guard let e = NSApp.currentEvent else { return nil }
            let isRight = e.type == .rightMouseDown || e.type == .rightMouseUp || e.type == .rightMouseDragged
            return (isRight && e.modifierFlags.contains(.option)) ? super.hitTest(point) : nil
        }
        override func rightMouseDown(with event: NSEvent) { action() }
    }
}

extension View {
    /// Toggle runner 2's knowledge on ⌥-right-click, without disturbing plain right-clicks.
    func onOptionRightClick(perform action: @escaping () -> Void) -> some View {
        overlay(OptionRightClickCatcher(action: action))
    }

    /// Adds the Commentary-Mode knowledge overlay + the ⌥-right-click (runner 2) catcher to an
    /// item cell (T-215). The cell must still handle ⌥-left-click (runner 1) in its own tap via
    /// `commentaryOptionKeyDown()`. No-op when `active` is false.
    func commentaryCell(knowledge: CommentaryKnowledge, encoding: CommentaryEncoding,
                        r1: Color, r2: Color, active: Bool, size: CGFloat,
                        onRunner2: @escaping () -> Void) -> some View {
        overlay { if active { OptionRightClickCatcher(action: onRunner2) } }
            .overlay {
                CommentaryTileOverlay(knowledge: active ? knowledge : [], encoding: encoding, r1: r1, r2: r2)
                    .frame(width: size, height: size)
            }
    }
}

/// One tile's Commentary-Mode knowledge overlay (T-215): corner pips (runner 1 top-left, runner 2
/// top-right) or a colored edge border (one runner colors the whole frame; both splits it
/// left/right, meeting in the middle). Renders nothing when neither runner knows the tile.
struct CommentaryTileOverlay: View {
    let knowledge: CommentaryKnowledge
    let encoding: CommentaryEncoding
    let r1: Color
    let r2: Color
    /// Which corner each runner's pip sits in. Default top-left / top-right; room cells override to
    /// the free corners (the monster owns top-left, the drop bottom-right) — T-215.
    var r1Corner: PipCorner = .topLeading
    var r2Corner: PipCorner = .topTrailing

    var body: some View {
        // Purely decorative — never intercept clicks (the filled pips / border would otherwise
        // block taps on those areas of the cell).
        content.allowsHitTesting(false)
    }

    @ViewBuilder
    private var content: some View {
        let has1 = knowledge.contains(.runner1)
        let has2 = knowledge.contains(.runner2)
        if has1 || has2 {
            switch encoding {
            case .pips:
                ZStack {
                    if has1 { CornerPip(color: r1, corner: r1Corner) }
                    if has2 { CornerPip(color: r2, corner: r2Corner) }
                }
            case .border:
                Rectangle().strokeBorder(borderStyle(has1: has1, has2: has2), lineWidth: 3)
            }
        }
    }

    /// Whole-frame in one runner's color; both = a hard left/right split (runner 1 | runner 2).
    private func borderStyle(has1: Bool, has2: Bool) -> AnyShapeStyle {
        if has1 && has2 {
            return AnyShapeStyle(LinearGradient(
                stops: [.init(color: r1, location: 0), .init(color: r1, location: 0.5),
                        .init(color: r2, location: 0.5), .init(color: r2, location: 1)],
                startPoint: .leading, endPoint: .trailing))
        }
        return AnyShapeStyle(has1 ? r1 : r2)
    }
}

/// The runner legend shown in the open band above the overworld while Commentary Mode is on
/// (T-215) — the two runners' names on their color chips, sized to be readable without crowding.
struct CommentaryLegendBanner: View {
    @Bindable var commentary: CommentaryLayer

    var body: some View {
        HStack(spacing: 14) {
            Text("COMMENTARY")
                .font(.system(size: 10, weight: .semibold, design: .monospaced))
                .tracking(1.5).foregroundStyle(.secondary)
            chip(Color(commentaryHex: commentary.runner1ColorHex), commentary.runner1Name, "Runner 1")
            chip(Color(commentaryHex: commentary.runner2ColorHex), commentary.runner2Name, "Runner 2")
            Spacer(minLength: 0)
        }
        .padding(.vertical, 6).padding(.horizontal, 12)
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func chip(_ color: Color, _ name: String, _ fallback: String) -> some View {
        HStack(spacing: 7) {
            RoundedRectangle(cornerRadius: 3).fill(color).frame(width: 16, height: 16)
            Text(name.trimmingCharacters(in: .whitespaces).isEmpty ? fallback : name)
                .font(.system(size: 14, weight: .semibold))
        }
        .padding(.horizontal, 11).padding(.vertical, 4)
        .background(Capsule().fill(color.opacity(0.14)))
        .overlay(Capsule().strokeBorder(color.opacity(0.55), lineWidth: 1))
    }
}

/// Which corner a commentary pip occupies.
enum PipCorner { case topLeading, topTrailing, bottomLeading, bottomTrailing }

/// A filled triangle tucked into a corner — the commentary "pip" for one runner.
private struct CornerPip: View {
    let color: Color
    let corner: PipCorner
    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width, h = geo.size.height
            let s = min(w, h) * 0.42
            Path { p in
                switch corner {
                case .topLeading:
                    p.move(to: .zero); p.addLine(to: CGPoint(x: s, y: 0)); p.addLine(to: CGPoint(x: 0, y: s))
                case .topTrailing:
                    p.move(to: CGPoint(x: w, y: 0)); p.addLine(to: CGPoint(x: w - s, y: 0)); p.addLine(to: CGPoint(x: w, y: s))
                case .bottomLeading:
                    p.move(to: CGPoint(x: 0, y: h)); p.addLine(to: CGPoint(x: s, y: h)); p.addLine(to: CGPoint(x: 0, y: h - s))
                case .bottomTrailing:
                    p.move(to: CGPoint(x: w, y: h)); p.addLine(to: CGPoint(x: w - s, y: h)); p.addLine(to: CGPoint(x: w, y: h - s))
                }
                p.closeSubpath()
            }
            .fill(color)
            .shadow(color: .black.opacity(0.5), radius: 0.5)
        }
    }
}
