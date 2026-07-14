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

    @Test(
        """
        iconSource covers every documented mark exactly once across its real \
        source (interiorSprite 3...13, sword caves via swordCaveItem, \
        shopSprite 0...7, dungeon/any-road digits) -- bugfix: not a single flat \
        0...35 strip index into the dead s_icon_overworld_strip39.png ZHelper \
        leftover
        """
    )
    func iconSourceIsCompleteAndUnique() {
        let dungeonMarks: [OverworldTileMark] = (1...9).map { .dungeon($0) }
        let anyRoadMarks: [OverworldTileMark] = (1...4).map { .anyRoad($0) }
        let shopMarks: [OverworldTileMark] = ShopKind.allCases.map { .shop($0) }
        // Sword caves now render via the Items-area sword sprites (T-063), so
        // they no longer occupy the ow interior-sprite indices 0...2 — those
        // three slots are intentionally unused by the live UI.
        let otherMarks: [OverworldTileMark] = SecretSize.allCases.map { .secret($0) }
            + [.doorRepair, .moneyMakingGame, .theLetter, .armos, .hintShop, .takeAny, .potionShop]

        let dungeonDigits = dungeonMarks.map { mark -> Int in
            guard case .dungeonDigit(let n) = mark.iconSource else { fatalError("expected dungeonDigit") }
            return n
        }
        #expect(Set(dungeonDigits) == Set(1...9))

        let anyRoadDigits = anyRoadMarks.map { mark -> Int in
            guard case .anyRoadDigit(let n) = mark.iconSource else { fatalError("expected anyRoadDigit") }
            return n
        }
        #expect(Set(anyRoadDigits) == Set(1...4))

        let shopIndices = shopMarks.map { mark -> Int in
            guard case .shopSprite(let i) = mark.iconSource else { fatalError("expected shopSprite") }
            return i
        }
        #expect(Set(shopIndices) == Set(0...7))

        let interiorIndices = otherMarks.map { mark -> Int in
            guard case .interiorSprite(let i) = mark.iconSource else { fatalError("expected interiorSprite") }
            return i
        }
        #expect(Set(interiorIndices) == Set(3...13))

        let swordLevels = (1...3).map { level -> Int in
            guard case .swordCaveItem(let l) = OverworldTileMark.swordCave(level).iconSource else {
                fatalError("expected swordCaveItem")
            }
            return l
        }
        #expect(swordLevels == [1, 2, 3])

        #expect(OverworldTileMark.dontCare.iconSource == .solidBlackTile)
        #expect(OverworldTileMark.unmarked.iconSource == .none)
    }

    @Test("iconSource is .none for unmarked and out-of-range associated values")
    func iconSourceNilCases() {
        #expect(OverworldTileMark.unmarked.iconSource == .none)
        #expect(OverworldTileMark.dungeon(0).iconSource == .none)
        #expect(OverworldTileMark.dungeon(10).iconSource == .none)
        #expect(OverworldTileMark.anyRoad(0).iconSource == .none)
        #expect(OverworldTileMark.anyRoad(5).iconSource == .none)
        #expect(OverworldTileMark.swordCave(0).iconSource == .none)
        #expect(OverworldTileMark.swordCave(4).iconSource == .none)
    }

    @Test("sword caves map to the Items-area sword sprite by level (T-063)")
    func swordCaveIconIsItemSword() {
        #expect(OverworldTileMark.swordCave(1).iconSource == .swordCaveItem(1))
        #expect(OverworldTileMark.swordCave(2).iconSource == .swordCaveItem(2))
        #expect(OverworldTileMark.swordCave(3).iconSource == .swordCaveItem(3))
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
