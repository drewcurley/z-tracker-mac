import Testing
@testable import TrackerCore

/// Maps hotkey selector suffixes to overworld tile marks (T-134).
struct OverworldTileMarkHotkeyTests {
    @Test func mapsRepresentativeSuffixes() {
        #expect(OverworldTileMark.fromHotkeySuffix("Level1") == .dungeon(1))
        #expect(OverworldTileMark.fromHotkeySuffix("Level9") == .dungeon(9))
        #expect(OverworldTileMark.fromHotkeySuffix("AnyRoad3") == .anyRoad(3))
        #expect(OverworldTileMark.fromHotkeySuffix("Sword1") == .swordCave(1))
        #expect(OverworldTileMark.fromHotkeySuffix("Sword2") == .swordCave(2))
        #expect(OverworldTileMark.fromHotkeySuffix("Sword3") == .swordCave(3))
        #expect(OverworldTileMark.fromHotkeySuffix("BombShop") == .shop(.bomb))
        #expect(OverworldTileMark.fromHotkeySuffix("BlueRingShop") == .shop(.blueRing))
        #expect(OverworldTileMark.fromHotkeySuffix("UnknownSecret") == .secret(.unknown))
        #expect(OverworldTileMark.fromHotkeySuffix("SmallSecret") == .secret(.small))
        #expect(OverworldTileMark.fromHotkeySuffix("DoorRepairCharge") == .doorRepair)
        #expect(OverworldTileMark.fromHotkeySuffix("Letter") == .theLetter)
        #expect(OverworldTileMark.fromHotkeySuffix("Armos") == .armos)
        #expect(OverworldTileMark.fromHotkeySuffix("TakeAny") == .takeAny)
        #expect(OverworldTileMark.fromHotkeySuffix("PotionShop") == .potionShop)
        #expect(OverworldTileMark.fromHotkeySuffix("DarkX") == .dontCare)
        #expect(OverworldTileMark.fromHotkeySuffix("Nothing") == .unmarked)
    }

    @Test func unknownSuffixIsNil() {
        #expect(OverworldTileMark.fromHotkeySuffix("Bogus") == nil)
        #expect(OverworldTileMark.fromHotkeySuffix("") == nil)
        #expect(OverworldTileMark.fromHotkeySuffix("Level10") == nil)
    }

    /// Parity guard: every overworld selector the editor/import can bind must map to
    /// a mark, or a bound key would silently do nothing.
    @Test func everyCatalogOverworldSelectorMaps() {
        let prefix = "Overworld_"
        for selector in HotkeyCatalog.selectors(in: .overworld) {
            #expect(selector.id.hasPrefix(prefix), "unexpected id \(selector.id)")
            let suffix = String(selector.id.dropFirst(prefix.count))
            #expect(OverworldTileMark.fromHotkeySuffix(suffix) != nil,
                    "no mark mapping for \(selector.id)")
        }
    }
}
