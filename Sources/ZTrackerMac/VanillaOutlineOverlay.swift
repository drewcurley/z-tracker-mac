import SwiftUI
import TrackerCore

/// Draws a vanilla dungeon's footprint over the room grid (T-071) — the FQ/SQ
/// overlay. Mirrors the reference `makeOutlineShapesImpl` (`DungeonUI.fs:254-288`):
/// MediumPurple boundary lines where a vanilla room meets a non-room, plus a
/// translucent purple wash on the non-room cells. Sits in the room grid's
/// coordinate system (same cell size + gap), non-interactive.
struct VanillaOutlineOverlay: View {
    let quest: VanillaQuest
    /// Dungeon index 0–8.
    let dungeon: Int
    let cellW: CGFloat
    let cellH: CGFloat
    let gap: CGFloat

    /// Reference `Brushes.MediumPurple` (147, 112, 219).
    private let color = Color(red: 147/255, green: 112/255, blue: 219/255)

    private var pitchX: CGFloat { cellW + gap }
    private var pitchY: CGFloat { cellH + gap }

    var body: some View {
        Canvas { ctx, _ in
            let g = gap
            // Wash the non-room cells (extended into the surrounding half-gaps so
            // the footprint reads as one continuous region).
            for row in 0..<8 {
                for col in 0..<8 where !isRoom(col, row) {
                    let rect = CGRect(x: CGFloat(col) * pitchX - g / 2,
                                      y: CGFloat(row) * pitchY - g / 2,
                                      width: cellW + g, height: cellH + g)
                    ctx.fill(Path(rect), with: .color(color.opacity(0.16)))
                }
            }
            // Boundary lines where a room borders a non-room.
            var boundary = Path()
            for row in 0..<8 {
                for col in 0..<7 where isRoom(col, row) != isRoom(col + 1, row) {
                    let x = CGFloat(col) * pitchX + cellW + g / 2
                    boundary.move(to: CGPoint(x: x, y: CGFloat(row) * pitchY - g / 2))
                    boundary.addLine(to: CGPoint(x: x, y: CGFloat(row) * pitchY + cellH + g / 2))
                }
            }
            for col in 0..<8 {
                for row in 0..<7 where isRoom(col, row) != isRoom(col, row + 1) {
                    let y = CGFloat(row) * pitchY + cellH + g / 2
                    boundary.move(to: CGPoint(x: CGFloat(col) * pitchX - g / 2, y: y))
                    boundary.addLine(to: CGPoint(x: CGFloat(col) * pitchX + cellW + g / 2, y: y))
                }
            }
            ctx.stroke(boundary, with: .color(color), lineWidth: 3)
        }
        .allowsHitTesting(false)
    }

    private func isRoom(_ col: Int, _ row: Int) -> Bool {
        VanillaDungeonData.isRoom(quest, dungeon: dungeon, col: col, row: row)
    }
}
