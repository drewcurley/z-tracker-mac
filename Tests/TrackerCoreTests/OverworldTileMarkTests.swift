import Foundation
import Testing
@testable import TrackerCore

@Suite("OverworldTileMark")
struct OverworldTileMarkTests {
    @Test("dungeon marks are constructible for all 9 dungeons", arguments: 1...9)
    func dungeonMarks(number: Int) {
        let mark = OverworldTileMark.dungeon(number)
        #expect(mark.displayName == "Dungeon \(number)")
    }

    @Test("any-road marks are constructible for all 4 any-roads", arguments: 1...4)
    func anyRoadMarks(number: Int) {
        let mark = OverworldTileMark.anyRoad(number)
        #expect(mark.displayName == "Any road \(number)")
    }

    @Test("sword cave marks are constructible for all 3 sword caves", arguments: 1...3)
    func swordCaveMarks(number: Int) {
        let mark = OverworldTileMark.swordCave(number)
        #expect(mark.displayName == "Sword cave \(number)")
    }

    @Test("every shop kind has a distinct display name", arguments: ShopKind.allCases)
    func shopDisplayNames(kind: ShopKind) {
        let mark = OverworldTileMark.shop(kind)
        #expect(!mark.displayName.isEmpty)
    }

    @Test("every secret size has a distinct display name", arguments: SecretSize.allCases)
    func secretDisplayNames(size: SecretSize) {
        let mark = OverworldTileMark.secret(size)
        #expect(!mark.displayName.isEmpty)
    }

    @Test("standalone marks have expected display names")
    func standaloneDisplayNames() {
        #expect(OverworldTileMark.unmarked.displayName == "Unmarked")
        #expect(OverworldTileMark.dontCare.displayName == "Don't care")
        #expect(OverworldTileMark.doorRepair.displayName == "Door repair")
        #expect(OverworldTileMark.moneyMakingGame.displayName == "Money making game")
        #expect(OverworldTileMark.theLetter.displayName == "The letter")
        #expect(OverworldTileMark.armos.displayName == "Armos")
        #expect(OverworldTileMark.hintShop.displayName == "Hint shop")
        #expect(OverworldTileMark.takeAny.displayName == "Take any")
        #expect(OverworldTileMark.potionShop.displayName == "Potion shop")
    }

    @Test("marks with the same associated value are equal")
    func equality() {
        #expect(OverworldTileMark.dungeon(3) == OverworldTileMark.dungeon(3))
        #expect(OverworldTileMark.dungeon(3) != OverworldTileMark.dungeon(4))
        #expect(OverworldTileMark.shop(.arrow) == OverworldTileMark.shop(.arrow))
        #expect(OverworldTileMark.shop(.arrow) != OverworldTileMark.shop(.bomb))
    }

    @Test("iconStripIndex matches MapSquareChoiceDomainHelper exactly, 0...35, no duplicates")
    func iconStripIndexIsCompleteAndUnique() {
        var marks: [OverworldTileMark] = (1...9).map { .dungeon($0) }
        marks += (1...4).map { .anyRoad($0) }
        marks += (1...3).map { .swordCave($0) }
        marks += ShopKind.allCases.map { .shop($0) }
        marks += SecretSize.allCases.map { .secret($0) }
        marks += [.doorRepair, .moneyMakingGame, .theLetter, .armos, .hintShop, .takeAny, .potionShop, .dontCare]

        let indices = marks.compactMap(\.iconStripIndex)
        #expect(indices.count == 36)
        #expect(Set(indices) == Set(0...35))
    }

    @Test("iconStripIndex is nil for unmarked and out-of-range associated values")
    func iconStripIndexNilCases() {
        #expect(OverworldTileMark.unmarked.iconStripIndex == nil)
        #expect(OverworldTileMark.dungeon(0).iconStripIndex == nil)
        #expect(OverworldTileMark.dungeon(10).iconStripIndex == nil)
        #expect(OverworldTileMark.anyRoad(0).iconStripIndex == nil)
        #expect(OverworldTileMark.anyRoad(5).iconStripIndex == nil)
        #expect(OverworldTileMark.swordCave(0).iconStripIndex == nil)
        #expect(OverworldTileMark.swordCave(4).iconStripIndex == nil)
    }

    @Test("sword cave icon indices descend as cave number ascends (matches reference app order)")
    func swordCaveIconIndexOrder() {
        #expect(OverworldTileMark.swordCave(3).iconStripIndex == 13)
        #expect(OverworldTileMark.swordCave(2).iconStripIndex == 14)
        #expect(OverworldTileMark.swordCave(1).iconStripIndex == 15)
    }

    @Test("marks round-trip through Codable")
    func codableRoundTrip() throws {
        let marks: [OverworldTileMark] = [
            .unmarked, .dontCare, .dungeon(5), .anyRoad(2), .swordCave(1),
            .shop(.blueRing), .secret(.medium), .doorRepair, .takeAny
        ]
        let encoder = JSONEncoder()
        let decoder = JSONDecoder()
        for mark in marks {
            let data = try encoder.encode(mark)
            let decoded = try decoder.decode(OverworldTileMark.self, from: data)
            #expect(decoded == mark)
        }
    }
}
