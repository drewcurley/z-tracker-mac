/// The Hidden-Dungeon-Numbers color palette (T-016.3), ported from the
/// reference's `flatColorArray` (`Z1R_Avalonia/Dungeon.fs:129-186`): 14 hues ×
/// 3 shades (dark / medium / light) = 42 swatches, stored as `0xRRGGBB` ints.
/// The last hue is black×3 — the explicit "unset" default matching
/// `Dungeon.color == 0`.
///
/// In HDN the player assigns each dungeon a color (and a real number,
/// `Dungeon.labelChar`) that render together on the dungeon tracker card. The
/// overworld map tiles keep the fixed A–H slot letter (a separate concept), so
/// this palette drives only the tracker-side swatch.
public enum DungeonColorPalette {
    /// 14 hues, each `[dark, medium, light]`, transcribed from the reference.
    public static let hues: [[Int]] = [
        [0x808080, 0xADADAD, 0xE0E0E0], // grey
        [0x0050F1, 0x4BA0FF, 0xB6D8FF], // blue
        [0x3B34FF, 0x8A84FF, 0xD0CDFF], // indigo
        [0x8022E8, 0xD172FF, 0xEDC6FF], // purple
        [0xBB1EA5, 0xFF6DF7, 0xFFC4FC], // magenta
        [0xDB294E, 0xFF799E, 0xFFC8D8], // pink / red
        [0xD74000, 0xFF9047, 0xFFD2B4], // orange
        [0xB15E00, 0xFFAE0A, 0xFFDE9C], // brown / gold
        [0x737900, 0xC4CA00, 0xE7E994], // olive
        [0x2D8B00, 0x7DDC13, 0xCAF19F], // green
        [0x008F08, 0x41E157, 0xB2F3BB], // green2
        [0x008460, 0x21D5B0, 0xA5EEDF], // teal
        [0x006DB5, 0x25BEFF, 0xA6E5FF], // cyan / sky
        [0x000000, 0x000000, 0x000000], // black (default / unset)
    ]

    /// The swatches as the reference's 3-row × 14-column grid
    /// (`threeTallColorArray`): row 0 = all darks, row 1 = mediums, row 2 =
    /// lights — the exact layout the color chooser renders.
    public static let rows: [[Int]] = [
        hues.map { $0[0] },
        hues.map { $0[1] },
        hues.map { $0[2] },
    ]

    /// The 42 swatches flat (row-major over `rows`).
    public static var all: [Int] { rows.flatMap { $0 } }

    /// `Dungeon.color`'s unset sentinel (black), matching the model default.
    public static let unset = 0x000000

    /// Whether **black** glyph text reads better than white on `rgb` — the
    /// luminance test ported verbatim from `Graphics.isBlackGoodContrast`
    /// (`Z1R_Avalonia/Graphics.fs:73-83`): black when relative luminance
    /// (gamma-squared, Rec. 709 weights) exceeds `0.5² = 0.25`.
    public static func isBlackGoodContrast(_ rgb: Int) -> Bool {
        let r = Double((rgb & 0xFF0000) >> 16) / 255.0
        let g = Double((rgb & 0x00FF00) >> 8) / 255.0
        let b = Double(rgb & 0x0000FF) / 255.0
        let l = 0.2126 * r * r + 0.7152 * g * g + 0.0722 * b * b
        return l > 0.25
    }
}
