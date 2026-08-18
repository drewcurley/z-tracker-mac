import Testing
@testable import TrackerCore

@Suite("In-menu hotkey hints (T-197)")
struct HotkeyHintsTests {
    @Test("maps overworld marks + hint zones to their HotKeys.txt selector ids")
    func selectorMapping() {
        #expect(HotkeyHints.selectorID(for: .shop(.bomb)) == "Overworld_BombShop")
        #expect(HotkeyHints.selectorID(for: .dungeon(3)) == "Overworld_Level3")
        #expect(HotkeyHints.selectorID(for: .secret(.unknown)) == "Overworld_UnknownSecret")
        #expect(HotkeyHints.selectorID(for: .hintShop) == "Overworld_HintShop")
        #expect(HotkeyHints.selectorID(for: .deathMountain) == "HintZone_DeathMountain")
        #expect(HotkeyHints.selectorID(for: .coast) == "HintZone_Coast")
    }

    @Test("suffix/keyLabel reflect the bound chord, empty when unbound")
    func hintFormatting() {
        let config = HotkeyConfig()
        config.setChord(HotkeyChord(key: "b"), for: "Overworld_BombShop")
        config.setChord(HotkeyChord(modifier: .shift, key: "4"), for: "HintZone_DeathMountain")

        #expect(HotkeyHints.suffix(for: .shop(.bomb), config: config) == " (B)")
        #expect(HotkeyHints.keyLabel(for: .shop(.bomb), config: config) == "B")
        #expect(HotkeyHints.suffix(for: .deathMountain, config: config) == " (⇧ 4)")
        // Unbound → empty (no clutter).
        #expect(HotkeyHints.suffix(for: .armos, config: config) == "")
        #expect(HotkeyHints.keyLabel(for: .lake, config: config) == "")
    }
}
