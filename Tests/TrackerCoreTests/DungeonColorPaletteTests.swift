import Testing
@testable import TrackerCore

@Suite("DungeonColorPalette (T-016.3)")
struct DungeonColorPaletteTests {
    @Test("14 hues × 3 shades = 42 swatches, laid out as 3 rows of 14")
    func shape() {
        #expect(DungeonColorPalette.hues.count == 14)
        #expect(DungeonColorPalette.hues.allSatisfy { $0.count == 3 })
        #expect(DungeonColorPalette.rows.count == 3)
        #expect(DungeonColorPalette.rows.allSatisfy { $0.count == 14 })
        #expect(DungeonColorPalette.all.count == 42)
    }

    @Test("rows are dark/medium/light slices of the hues; last hue is the unset black")
    func layout() {
        #expect(DungeonColorPalette.rows[0] == DungeonColorPalette.hues.map { $0[0] })
        #expect(DungeonColorPalette.rows[1] == DungeonColorPalette.hues.map { $0[1] })
        #expect(DungeonColorPalette.rows[2] == DungeonColorPalette.hues.map { $0[2] })
        #expect(DungeonColorPalette.hues.last == [0, 0, 0])
        #expect(DungeonColorPalette.unset == 0)
    }

    @Test("isBlackGoodContrast: black text on light colors, white on dark (reference formula)")
    func contrast() {
        // White / very light → black text.
        #expect(DungeonColorPalette.isBlackGoodContrast(0xFFFFFF))
        #expect(DungeonColorPalette.isBlackGoodContrast(0xE0E0E0)) // light grey
        // Black / dark → white text.
        #expect(!DungeonColorPalette.isBlackGoodContrast(0x000000))
        #expect(!DungeonColorPalette.isBlackGoodContrast(0x0050F1)) // dark blue
        // Green is bright (0.7152 weight) → black text.
        #expect(DungeonColorPalette.isBlackGoodContrast(0x7DDC13))
    }
}
