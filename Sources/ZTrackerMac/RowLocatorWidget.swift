import SwiftUI
import TrackerCore

/// The dungeon "row locator" (T-078, reference `DungeonUI.fs:556-577`): a compact
/// widget by the old-man counter with the **always-visible** rupee / key / bomb
/// icons that key the 8 in-game-HUD-map rows into bands (rows 1-2 = rupee,
/// 3-4 = blank, 5-6 = key, 7-8 = bomb). Hovering a room in the editor reveals a
/// gray marker at that room's row, so you can read off which HUD row it's on.
struct RowLocatorWidget: View {
    /// The hovered grid row (0…7), or nil when not hovering.
    let hoveredRow: Int?

    private let rowH: CGFloat = 10
    private let iconSize: CGFloat = 18
    private let markerW: CGFloat = 14
    private var totalH: CGFloat { rowH * 8 }

    var body: some View {
        HStack(spacing: 3) {
            // The 8 row slots — normally empty; the hovered row's marker reveals.
            ZStack(alignment: .topLeading) {
                Color.clear.frame(width: markerW, height: totalH)
                if let hoveredRow {
                    RoundedRectangle(cornerRadius: 1.5)
                        .fill(Color.gray.opacity(0.85))
                        .frame(width: markerW, height: rowH)
                        .offset(y: CGFloat(hoveredRow) * rowH)
                }
            }
            // The rupee / key / bomb icons, aligned to their row bands.
            ZStack(alignment: .topLeading) {
                Color.clear.frame(width: iconSize, height: totalH)
                bandIcon(.fiveRupee, topRow: 0)   // rows 1-2
                bandIcon(.key, topRow: 4)          // rows 5-6
                bandIcon(.bombPack, topRow: 6)     // rows 7-8
            }
        }
        .help("Row locator: hover a room to see which in-game HUD-map row it's on (rows 1-2 = rupee, 5-6 = key, 7-8 = bomb).")
        .accessibilityHidden(true)
    }

    @ViewBuilder private func bandIcon(_ drop: FloorDropDetail, topRow: Int) -> some View {
        if let image = Image(atlasIcon: DungeonFloorDropAtlas.sprite(drop)) {
            let bandCenter = (CGFloat(topRow) * rowH + CGFloat(topRow + 2) * rowH) / 2
            image.interpolation(.none).resizable()
                .frame(width: iconSize, height: iconSize)
                .offset(y: bandCenter - iconSize / 2)
        }
    }
}
