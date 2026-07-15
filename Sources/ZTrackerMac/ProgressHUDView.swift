import SwiftUI
import TrackerCore

/// The "Progress" HUD (T-035.10) — the reference's faux items+hearts inventory
/// HUD (`FauxItemsHUD`), rendered as a crisp, freely-scalable image. Shown
/// transiently on hover of the Flags/overlay "Progress" icon, and broken out
/// into a separate resizable window when it's toggled on.
struct ProgressHUDView: View {
    @Bindable var model: TrackerModel

    /// The HUD's letter slot lights up once the overworld letter cave is
    /// **used** (claimed) — the user's model, and simpler than the map-derived
    /// `havePotionLetter` (which tracks *holding* the letter, i.e. placed but
    /// not yet turned in).
    private var haveLetter: Bool {
        let grid = model.overworldGrid
        for c in 0..<OverworldGrid.columnCount {
            for r in 0..<OverworldGrid.rowCount where grid.mark(column: c, row: r) == .theLetter {
                if grid.isUsed(column: c, row: r) { return true }
            }
        }
        return false
    }

    /// "Have the book" = the dungeon book/shield slot or a purchased boomstick.
    private var haveBook: Bool {
        model.playerComputedStateSummary.haveBookOrShield || model.playerProgress.hasBoomBook
    }

    var body: some View {
        Group {
            if let cg = FauxItemsHUD.render(
                state: model.playerComputedStateSummary, progress: model.playerProgress,
                havePotionLetter: haveLetter, haveBook: haveBook),
               let image = Image(atlasIcon: cg) {
                image
                    .interpolation(.none)
                    .resizable()
                    .aspectRatio(CGFloat(FauxItemsHUD.width) / CGFloat(FauxItemsHUD.height), contentMode: .fit)
            } else {
                Color.black
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.black)
    }
}
