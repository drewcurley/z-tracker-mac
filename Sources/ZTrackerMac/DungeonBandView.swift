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
    /// `ViewThatFits` recreates whichever branch it shows, which would reset the
    /// map view's own `@State` zoom; holding it in this stable parent and passing a
    /// binding keeps it across the row↔column swap. (`ViewThatFits` itself picks the
    /// layout that fits — the scaled map reports a deterministic width, so the reflow
    /// tracks the current zoom.)
    @State private var mapScale: CGFloat = 1.0

    var body: some View {
        ViewThatFits(in: .horizontal) {
            HStack(alignment: .top, spacing: 12) {
                dungeonMapGroup
                blockersNotesColumn
                    .frame(maxHeight: .infinity)   // Notes fills the map's height
            }
            VStack(alignment: .leading, spacing: 12) {
                dungeonMapGroup
                blockersNotesColumn
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .fixedSize(horizontal: false, vertical: true)
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
                BlockersView(model: model, focus: focus)
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
