import SwiftUI

/// The overworld "Zones" overlay data (T-035.3) — a color-coded map of the
/// game's regions. Ported from `OverworldData.owMapZone` (8 rows × 16 cols of
/// zone letters) and the per-letter colors in `UIComponents.fs:1006-1017`.
enum OverworldZones {
    /// `zone[row][col]` — one letter per overworld screen. Transcribed verbatim
    /// from `OverworldData.fs:51-59`.
    static let rows: [String] = [
        "MMMMMMMMMMLHHHCC",
        "MMMMMMMRRRRHHHCC",
        "GGGGGGLRDDDDDCCC",
        "GGGGLLLLLLDDFFCC",
        "GGLLLLLLLDDDFFFC",
        "GWWWLLLSSLLFFFFC",
        "GWWWWRSSSLLFFFFC",
        "WWWWWRSSSSSCCCCC",
    ]

    static func zone(column: Int, row: Int) -> Character? {
        guard rows.indices.contains(row) else { return nil }
        let r = Array(rows[row])
        guard r.indices.contains(column) else { return nil }
        return r[column]
    }

    /// The tint color for a zone letter (`UIComponents.fs:1006-1017`). `M` and
    /// `G` are the `avg` of two named colors, pre-computed here.
    static func color(_ zone: Character) -> Color {
        switch zone {
        case "M": return Color(red: 0.93, green: 0.415, blue: 0.52) // avg(Pink, Crimson)
        case "L": return Color(red: 0.54, green: 0.17, blue: 0.89)  // BlueViolet
        case "R": return Color(red: 0.13, green: 0.70, blue: 0.67)  // LightSeaGreen
        case "H": return Color(red: 0.50, green: 0.50, blue: 0.50)  // Gray
        case "C": return Color(red: 0.68, green: 0.85, blue: 0.90)  // LightBlue
        case "G": return Color(red: 0.48, green: 0.64, blue: 0.79)  // avg(LightSteelBlue, SteelBlue)
        case "D": return Color(red: 1.00, green: 0.65, blue: 0.00)  // Orange
        case "F": return Color(red: 0.56, green: 0.93, blue: 0.56)  // LightGreen
        case "S": return Color(red: 0.66, green: 0.66, blue: 0.66)  // DarkGray
        case "W": return Color(red: 0.65, green: 0.16, blue: 0.16)  // Brown
        default:  return .clear
        }
    }

    static func color(column: Int, row: Int) -> Color {
        guard let z = zone(column: column, row: row) else { return .clear }
        return color(z)
    }
}

/// The overworld "Coords" overlay (T-035.3). Ported from `WPFUI.fs:626/1305`
/// (`"%c%d"` = row letter A–H + column number 1–16) — so the coast at
/// (col 15, row 5) reads "F16", matching the reference's tooltip.
enum OverworldCoords {
    static func label(column: Int, row: Int) -> String {
        let rowLetter = Character(UnicodeScalar(UInt8(65 + row)))
        return "\(rowLetter)\(column + 1)"
    }
}
