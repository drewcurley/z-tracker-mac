import SwiftUI
import TrackerCore

/// The dungeon band (T-019+): the per-dungeon room-map grid + the blockers/notes
/// column. Extracted into its own view (T-123) so it can render both inline and in
/// a break-out window. Side-by-side (map left) when there's room; the column wraps
/// below the map when narrow (`ViewThatFits`, per the responsive-layout ADR).
struct DungeonBandView: View {
    var model: TrackerModel
    var options: TrackerOptions
    /// Shared focus state (T-133) — the selected dungeon tab, so it survives this
    /// band's reflow and Global hotkeys can switch it.
    var focus: TrackerFocusState
    /// The dungeon map's zoom, owned here (T-129) so it survives the band's reflow.
    /// A layout swap recreates whichever branch it shows, which would reset the map
    /// view's own `@State` zoom; holding it in this stable parent and passing a
    /// binding keeps it across the row↔column swap.
    @State private var mapScale: CGFloat = 1.0
    /// The band's available width, measured once via a background reader (T-179).
    /// We pick side-by-side vs stacked from this instead of `ViewThatFits`, because
    /// `ViewThatFits` re-measured *both* candidate layouts — each containing the full
    /// map AND the blockers/notes column — on **every** cursor hover, re-rendering the
    /// whole band 2–3× per mouse-move (the ~15fps dungeon-hover stall). Reading the
    /// width into `@State` means the layout decision only recomputes on an actual
    /// resize, so a hover re-renders just the map, not the blockers/notes beside it.
    /// Defaults wide so a normal (roomy) window starts side-by-side with no flash.
    @State private var availableWidth: CGFloat = 100_000

    /// Side-by-side fits when the (zoom-scaled) map card + spacing + the blockers/notes
    /// column's minimum width all fit; otherwise the column wraps below. Mirrors what
    /// `ViewThatFits` computed, but from a single cached measurement.
    private var useSideBySide: Bool {
        availableWidth >= DungeonMapView.contentWidth * mapScale + 12 + 360
    }

    var body: some View {
        let _ = perfTrace()
        // Outer, plain full-width wrapper. The width reader lives HERE, not on the
        // `.fixedSize` node below: a `.fixedSize(horizontal:false, vertical:true)` node
        // reports a **0-width** frame to its own `.background`, so measuring it directly
        // pinned `availableWidth` at 0 → always stacked (T-179 regression). This wrapper
        // fills the parent's real proposed width regardless of what `.fixedSize` reports,
        // so the reader sees the true available width and updates on resize.
        bandContent
            .frame(maxWidth: .infinity, alignment: .leading)
            .background {
                // Read the width directly off the proxy (via onAppear/onChange) rather
                // than routing through a PreferenceKey — the preference path delivered a
                // stuck 0 here, but this direct-read pattern (the same one ScaledFootprint
                // uses for the map-zoom footprint) reports the true width and updates on
                // resize.
                GeometryReader { proxy in
                    Color.clear
                        .onAppear { updateWidth(proxy.size.width) }
                        .onChange(of: proxy.size.width) { _, w in updateWidth(w) }
                }
            }
    }

    /// The switching map+column layout. Pinned to its ideal height via `.fixedSize`
    /// (vertical) so the `maxHeight: .infinity` inside (Notes filling the map's height)
    /// doesn't run away under the enclosing ScrollView's unbounded height proposal.
    private var bandContent: some View {
        Group {
            if useSideBySide {
                HStack(alignment: .top, spacing: 12) {
                    dungeonMapGroup
                    blockersNotesColumn
                        .frame(maxHeight: .infinity)   // Notes fills the map's height
                }
            } else {
                VStack(alignment: .leading, spacing: 12) {
                    dungeonMapGroup
                    blockersNotesColumn
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .fixedSize(horizontal: false, vertical: true)
    }

    /// Store the latest measured width, ignoring degenerate 0-width measurement passes
    /// (which would otherwise pin the band to the stacked layout).
    private func updateWidth(_ w: CGFloat) {
        guard w > 0, w != availableWidth else { return }
        availableWidth = w
    }

    private var dungeonMapGroup: some View {
        TopSectionGroup(title: "Dungeon Map") {
            DungeonMapView(model: model, options: options, focus: focus, mapScale: $mapScale)
        }
    }

    /// Blockers over Notes; both fill the 390-wide column so their edges align.
    private var blockersNotesColumn: some View {
        VStack(alignment: .leading, spacing: 12) {
            TopSectionGroup(title: "Blockers") {
                BlockersView(model: model, options: options, focus: focus)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            TopSectionGroup(title: "Notes") {
                NotesView(model: model, focus: focus)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            .frame(maxHeight: .infinity)
        }
        // Grows to absorb window width the (capped) map can't use, so a wide window
        // gives Notes room instead of dead space. Min trimmed to 360 (T-127) so all
        // three columns fit side-by-side at a narrower window.
        .frame(minWidth: 360, maxWidth: .infinity)
    }
}
