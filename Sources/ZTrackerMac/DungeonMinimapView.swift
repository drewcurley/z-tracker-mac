import SwiftUI
import TrackerCore

/// The dungeon "minimap" (T-079) — a faux in-game HUD dungeon map of your marked
/// rooms, so you can eyeball whether what you've built matches the map you see
/// in-game. Ported from the reference `MakeLoZMinimapDisplayBmp` /
/// `showMinimaps` (`Dungeon.fs:774+`, `DungeonUI.fs:890-937`): a `LEVEL-N` header
/// over an 8×8 grid of blue room-blocks (lit = a marked room). When any room is
/// painted off-the-map, it also shows the **inverse** (everything not painted
/// off) — the shape the game actually reveals.
struct DungeonMinimapView: View {
    let map: DungeonRoomMap
    /// "LEVEL-N" / "BOARD-N".
    let headerText: String

    /// Reference room-block blue (`Dungeon.fs:745`, RGB 71,47,228).
    private let blue = Color(red: 71 / 255, green: 47 / 255, blue: 228 / 255)
    // Reference block 7×3 at 8×4 pitch — scaled ~2.5×.
    private let blockW: CGFloat = 17, blockH: CGFloat = 7
    private let pitchX: CGFloat = 20, pitchY: CGFloat = 10

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            if map.hasOffMapRoom {
                Text("Full map, minus your Off-The-Map marks:")
                    .font(.system(size: 10)).foregroundStyle(.secondary)
                board { !map.room(col: $0, row: $1).roomType.isOffMap }
                Text("Your room marks:")
                    .font(.system(size: 10)).foregroundStyle(.secondary)
            }
            board { !map.room(col: $0, row: $1).isEmpty }
        }
        .padding(12)
        .background(Color.black)
    }

    /// One HUD board: the header + the lit room-blocks.
    private func board(lit: @escaping (Int, Int) -> Bool) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(headerText)
                .font(.system(size: 13, weight: .heavy, design: .monospaced))
                .foregroundStyle(Color(white: 0.82))
            Canvas { ctx, _ in
                for row in 0..<DungeonRoomMap.rows {
                    for col in 0..<DungeonRoomMap.cols where lit(col, row) {
                        let rect = CGRect(x: CGFloat(col) * pitchX, y: CGFloat(row) * pitchY,
                                          width: blockW, height: blockH)
                        ctx.fill(Path(rect), with: .color(blue))
                    }
                }
            }
            .frame(width: CGFloat(DungeonRoomMap.cols) * pitchX,
                   height: CGFloat(DungeonRoomMap.rows) * pitchY)
        }
    }
}

/// The small thumbnail that reveals the minimap on hover (the reference's
/// `MakeMiniMiniMapBmp` hover icon): a black tile with two blue bars.
struct DungeonMinimapHoverIcon: View {
    @Bindable var map: DungeonRoomMap
    let headerText: String
    @State private var showing = false

    private let blue = Color(red: 71 / 255, green: 47 / 255, blue: 228 / 255)

    var body: some View {
        VStack(spacing: 2) {
            Rectangle().fill(blue).frame(width: 18, height: 6)
            Rectangle().fill(blue).frame(width: 18, height: 6)
        }
        .padding(3)
        .frame(width: 26, height: 22)
        .background(Color.black)
        .overlay(RoundedRectangle(cornerRadius: 3).strokeBorder(showing ? .cyan : .gray, lineWidth: 1))
        .onHover { showing = $0 }
        .popover(isPresented: $showing, arrowEdge: .leading) {
            DungeonMinimapView(map: map, headerText: headerText)
        }
        .help("Hover to preview the in-game HUD map of your marked rooms.")
        .accessibilityLabel("Minimap preview")
    }
}
