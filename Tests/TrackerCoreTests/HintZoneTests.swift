import Testing
@testable import TrackerCore

@Suite("HintZone + level hints")
struct HintZoneTests {
    @Test("11 zones with distinct two-char labels; zone chars match owMapZone")
    func zones() {
        #expect(HintZone.allCases.count == 11)
        let labels = HintZone.allCases.map(\.twoChars)
        #expect(Set(labels).count == 11) // all distinct
        #expect(HintZone.unknown.twoChars == "UN")
        #expect(HintZone.deathMountain.twoChars == "DM")
        #expect(HintZone.deadWoods.twoChars == "DW")
        // zoneChar matches the owMapZone letters (unknown = '_').
        #expect(HintZone.unknown.zoneChar == "_")
        #expect(HintZone.deathMountain.zoneChar == "M")   // M zone
        #expect(HintZone.forest.zoneChar == "F")          // F zone
        #expect(HintZone.deadWoods.zoneChar == "W")       // W zone
        // Every non-unknown zoneChar is one of the owMapZone letters.
        let owLetters = Set("MLHRGDCWSF")
        for z in HintZone.allCases where z != .unknown {
            #expect(owLetters.contains(z.zoneChar))
        }
    }

    @Test("forZoneChar inverts zoneChar; unknown/nil → .unknown (T-039.1)")
    func forZoneChar() {
        for zone in HintZone.allCases {
            #expect(HintZone.forZoneChar(zone.zoneChar) == zone)
        }
        #expect(HintZone.forZoneChar(nil) == .unknown)
        #expect(HintZone.forZoneChar("_") == .unknown)
        #expect(HintZone.forZoneChar("Z") == .unknown)
        #expect(HintZone.forZoneChar("M") == .deathMountain)
        #expect(HintZone.forZoneChar("D") == .desert)
    }

    @Test("hint-target indices: dungeons 1–9 → 0–8, WS → 9, MS → 10")
    func targets() {
        #expect(HintTarget.dungeon(1) == 0)
        #expect(HintTarget.dungeon(9) == 8)
        #expect(HintTarget.whiteSwordCave == 9)
        #expect(HintTarget.magicalSwordCave == 10)
        #expect(HintTarget.count == 11)
    }

    @Test("model starts with 11 Unknown hints; set/get per target")
    func modelHints() {
        let model = TrackerModel()
        #expect(model.levelHints.count == 11)
        #expect(model.levelHints.allSatisfy { $0 == .unknown })
        model.levelHints[HintTarget.dungeon(2)] = .deathMountain
        model.levelHints[HintTarget.whiteSwordCave] = .coast
        #expect(model.levelHints[1] == .deathMountain)
        #expect(model.levelHints[9] == .coast)
    }

    @Test("groundhog reset keeps hints (map knowledge)")
    func resetKeepsHints() {
        let model = TrackerModel(quest: .first)
        model.selectQuest(.first)
        model.levelHints[HintTarget.dungeon(3)] = .lake
        model.playerProgress.hasWoodSword = true
        model.resetForGroundhogOrRouters()
        // Inventory cleared, but the hint survives.
        #expect(!model.playerProgress.hasWoodSword)
        #expect(model.levelHints[2] == .lake)
    }
}
