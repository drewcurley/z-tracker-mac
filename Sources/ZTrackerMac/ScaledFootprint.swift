import SwiftUI

/// Scales a view **and shrinks its layout footprint to match** (T-127). Plain
/// `.scaleEffect` transforms only the rendering, leaving the original bounds (and
/// the empty space) behind; this measures the natural size and clamps the outer
/// frame to `size × scale`, so a scaled-down view actually frees the space around it.
/// Used to zoom the dungeon map and to size it to a neighbor's height in the wide
/// layout. A `scale` of 1 is a pass-through (no measuring, no flicker).
struct ScaledFootprint: ViewModifier {
    var scale: CGFloat
    var anchor: UnitPoint = .topLeading
    /// The view's natural width when it is a known constant. Supplying it keeps the
    /// scaled width **deterministic** (no measurement lag) — essential inside a
    /// `ViewThatFits`, which probes the ideal width to choose a layout; a measured
    /// width reads 0 during that probe and mis-triggers the reflow (T-127).
    var naturalWidth: CGFloat? = nil
    @State private var natural: CGSize = .zero

    func body(content: Content) -> some View {
        if scale == 1 {
            content
        } else {
            let w: CGFloat? = naturalWidth.map { $0 * scale }
                ?? (natural == .zero ? nil : natural.width * scale)
            content
                // Pin to intrinsic height so the outer `.frame(height:)` below can't
                // propose a taller height back into the content and grow it each
                // measure — a runaway loop when scale > 1 (T-128).
                .fixedSize(horizontal: false, vertical: true)
                .background(
                    GeometryReader { g in
                        Color.clear
                            .onAppear { natural = g.size }
                            .onChange(of: g.size) { _, newValue in natural = newValue }
                    }
                )
                .scaleEffect(scale, anchor: anchor)
                .frame(width: w,
                       height: natural == .zero ? nil : natural.height * scale,
                       alignment: .topLeading)
        }
    }
}

extension View {
    /// Scale the view and collapse its footprint to match — see `ScaledFootprint`.
    func scaledFootprint(_ scale: CGFloat, anchor: UnitPoint = .topLeading,
                         naturalWidth: CGFloat? = nil) -> some View {
        modifier(ScaledFootprint(scale: scale, anchor: anchor, naturalWidth: naturalWidth))
    }
}
