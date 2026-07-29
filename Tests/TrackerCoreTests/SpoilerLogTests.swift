import Foundation
import Testing
@testable import TrackerCore

/// Fixture drawn from a real Z1R spoiler log (seed 3952398579), covering every cave type,
/// the item forms (dungeon w/ located-at, white-sword, armos, coast, L9 two-item), and shops.
private let fixture = """
The following is the report of what's generated in the file.

SEED 3952398579
------------------------------
LEVEL 9 ENTRY:
Specific triforces needed:  3 5 7
Start Screen:  B15
ITEMS
Level 1-6 (located at 47 E8) contains Boomerang
Level 1-4 (located at f A16) contains Magic Boomerang
White Sword Cave contains Wand
Armos Item contains Red Ring
Coast Ladder Spot contains BOMB UPGRADE
Level 1-9 (located at 7d H14) contains Red Candle
Level 1-9 (located at 7d H14) contains Silver Arrow
Level 1-8 (located at 2c C13) contains Magic Key
Level 1-8 (located at 2c C13) contains Heart Container
-----------------------------
CAVES
Location A2 contains: TAKE ANY ROAD...
Location A4 contains: MONEY MAKING GAME
Location A5 contains: WATERFALL PAY ME
Location A6 contains: LEVEL 1
Location A8 contains: SHOP 3
Location A11 contains: WHITE SWORD CAVE
Location A13 contains: 30 SECRET
Location A15 contains: WOODEN SWORD CAVE
Location B4 contains: DOOR REPAIR
Location B5 contains: POTION SHOP
Location B7 contains: 10 SECRET
Location B13 contains: SECRET IS IN...
Location B16 contains: 100 SECRET
Location C4 contains: SHOP 1
Location C5 contains: SHOP 3
Location C6 contains: OLD MAN AT GRAVE
Location D14 contains: POTION SHOP
Location E15 contains: DOOR REPAIR
Location E6 contains: TAKE ANY ONE
Location E10 contains: MAGICAL SWORD CAVE
Location G16 contains: LOST WOODS PAY ME
Location H8 contains: LETTER CAVE
Location H14 contains: LEVEL 9
-----------------------------
SHOP INFO
SHOP 1
Heart:  13
Wooden Arrow:  83
Magic Shield:  140
SHOP 3
Blue Ring:  244
Key:  97
Bait:  66
POTION SHOP
BLUE:  45
RED:  58
LEVEL 1 MAP
             *-A-*-*
"""

@Suite("Spoiler log parser (T-181)")
struct SpoilerLogTests {
    private var log: SpoilerLog { SpoilerLog.parse(fixture) }

    private func mark(_ log: SpoilerLog, _ coord: String) -> OverworldTileMark? {
        guard let c = SpoilerLog.Coord.parse(coord) else { return nil }
        return log.caves.first { $0.coord == c }?.mark
    }

    @Test("header: seed, L9 triforces, start screen")
    func header() {
        #expect(log.seed == 3952398579)
        #expect(log.level9Triforces == [3, 5, 7])
        #expect(log.startScreen == SpoilerLog.Coord(column: 14, row: 1))   // B15
    }

    @Test("coordinate parse matches the hex index (E8 → 0x47)")
    func coord() {
        let c = SpoilerLog.Coord.parse("E8")
        #expect(c == SpoilerLog.Coord(column: 7, row: 4))
        #expect((c!.row * 16 + c!.column) == 0x47)
        #expect(SpoilerLog.Coord.parse("A6") == SpoilerLog.Coord(column: 5, row: 0))
        #expect(SpoilerLog.Coord.parse("Z9") == nil)
    }

    @Test("standard cave types map correctly")
    func standardCaves() {
        #expect(mark(log, "A6") == .dungeon(1))
        #expect(mark(log, "H14") == .dungeon(9))
        #expect(mark(log, "A15") == .swordCave(1))
        #expect(mark(log, "A11") == .swordCave(2))
        #expect(mark(log, "E10") == .swordCave(3))
        #expect(mark(log, "B7") == .secret(.small))
        #expect(mark(log, "A13") == .secret(.medium))
        #expect(mark(log, "B16") == .secret(.large))
        #expect(mark(log, "B4") == .doorRepair)
        #expect(mark(log, "A4") == .moneyMakingGame)
        #expect(mark(log, "B5") == .potionShop)
        #expect(mark(log, "H8") == .theLetter)
    }

    @Test("user-verified ambiguous caves: take-any-road ?, take-any-one, hints")
    func verifiedCaves() {
        #expect(mark(log, "A2") == .anyRoad(0))   // TAKE ANY ROAD → "?"
        #expect(mark(log, "E6") == .takeAny)       // TAKE ANY ONE
        #expect(mark(log, "A5") == .hintShop)      // WATERFALL PAY ME
        #expect(mark(log, "G16") == .hintShop)     // LOST WOODS PAY ME
        #expect(mark(log, "B13") == .hintShop)     // SECRET IS IN...
        #expect(mark(log, "C6") == .hintShop)      // OLD MAN AT GRAVE
    }

    @Test("shops resolve via SHOP INFO to the notable item (+ second)")
    func shops() {
        // SHOP 3 = Blue Ring / Key / Bait → primary Blue Ring, second Key.
        let s3 = log.caves.first { $0.coord == SpoilerLog.Coord.parse("A8")! }
        #expect(s3?.mark == .shop(.blueRing))
        #expect(s3?.shopSecondItem == .key)
        // SHOP 1 = Heart(untracked) / Wooden Arrow / Magic Shield → primary Arrow, second Shield.
        let s1 = log.caves.first { $0.coord == SpoilerLog.Coord.parse("C4")! }
        #expect(s1?.mark == .shop(.arrow))
        #expect(s1?.shopSecondItem == .shield)
    }

    @Test("nothing is left unmapped for a standard log")
    func noUnmapped() {
        #expect(log.unmappedCaves.isEmpty)
    }

    @Test("item placements: dungeon (with location), white-sword, armos, coast, L9 two-item")
    func items() {
        #expect(log.items.count == 9)
        let d6 = log.items.first { $0.site == .dungeon(6) }
        #expect(d6?.itemName == "Boomerang")
        #expect(d6?.overworld == SpoilerLog.Coord(column: 7, row: 4))   // E8
        #expect(log.items.first { $0.site == .whiteSwordCave }?.itemName == "Wand")
        #expect(log.items.first { $0.site == .armos }?.itemName == "Red Ring")
        #expect(log.items.first { $0.site == .coastLadderSpot }?.itemName == "BOMB UPGRADE")
        // Level 9 lists two items — both captured.
        let l9 = log.items.filter { $0.site == .dungeon(9) }.map(\.itemName).sorted()
        #expect(l9 == ["Red Candle", "Silver Arrow"])
    }

    @Test("apply writes overworld marks (+ shop second), start spot, and the L9 note")
    func applyToModel() {
        let model = TrackerModel()
        let result = SpoilerLog.parse(fixture).apply(to: model, sections: [.overworldMarks, .l9AndStart])
        // Overworld marks landed at the right screens.
        #expect(model.overworldGrid.mark(column: 5, row: 0) == .dungeon(1))    // A6
        #expect(model.overworldGrid.mark(column: 9, row: 4) == .swordCave(3))   // E10
        #expect(model.overworldGrid.mark(column: 1, row: 0) == .anyRoad(0))     // A2 = "?"
        // Shop primary + second.
        #expect(model.overworldGrid.mark(column: 7, row: 0) == .shop(.blueRing)) // A8
        #expect(model.overworldGrid.shopSecondItem(column: 7, row: 0) == .key)
        // Armos inferred: of D5/B13/C5/D14/E15, four are caves here, so D5 is the leftover.
        #expect(model.overworldGrid.mark(column: 4, row: 3) == .armos)           // D5
        #expect(result.armosInferred)
        // Start spot + L9 note.
        #expect(model.startSpot == OverworldScreenCoordinate(x: 14, y: 1))       // B15
        #expect(model.notes.contains("Triforces needed for Level 9: 3 5 7"))
        // Summary (23 cave lines; the inferred armos is separate from overworldMarksSet).
        #expect(result.overworldMarksSet == 23)
        #expect(result.startSpotSet)
        #expect(result.l9NoteAdded)
        #expect(result.deferredSections.contains("Dungeon items") == false)
    }

    @Test("armos is not inferred when more than one candidate is unmarked")
    func armosAmbiguous() {
        // A near-empty log: only B13 is a cave, so 4 candidates are unmarked → no inference.
        let model = TrackerModel()
        let r = SpoilerLog.parse("CAVES\nLocation B13 contains: 30 SECRET\n").apply(to: model, sections: .overworldMarks)
        #expect(!r.armosInferred)
        #expect(model.overworldGrid.mark(column: 4, row: 3) == .unmarked)   // D5 untouched
    }

    @Test("apply, heart shuffle OFF: box[0] of L1–8 is the fixed heart; items fill the rest")
    func applyDungeonItems() {
        let model = TrackerModel()
        let result = SpoilerLog.parse(fixture).apply(to: model, sections: .dungeonItems, heartShuffle: false)
        let t = model.dungeonTracker
        #expect(model.heartShuffle == false)
        // L1–8: box[0] is the fixed heart, the floor item goes in box[1].
        #expect(t.dungeons[5].boxes[0].cellCurrent == ITEMS.heartContainer)  // Level 6 heart row
        #expect(t.dungeons[5].boxes[1].cellCurrent == ITEMS.boomerang)       // Level 1-6 item
        #expect(t.dungeons[3].boxes[0].cellCurrent == ITEMS.heartContainer)  // Level 4 heart row
        #expect(t.dungeons[3].boxes[1].cellCurrent == ITEMS.magicBoomerang)
        // Level 9 has no fixed heart → its two items fill box[0]/box[1].
        #expect(t.dungeons[8].boxes[0].cellCurrent == ITEMS.redCandle)
        #expect(t.dungeons[8].boxes[1].cellCurrent == ITEMS.silverArrow)
        // The three named caves.
        #expect(t.sword2Box.cellCurrent == ITEMS.wand)                       // White Sword Cave
        #expect(t.armosBox.cellCurrent == ITEMS.redRing)                     // Armos
        #expect(t.ladderBox.cellCurrent == ITEMS.whiteSword)                 // Coast BOMB UPGRADE
        #expect(model.isWSMSReplacedByBU)
        #expect(result.swordlessInferred)
        // L8 lists the relocated 9th ("coast") heart alongside its floor item: box[0] is the fixed
        // heart, box[1] the Magic Key, box[2] the log-listed Heart Container — the heart is NOT dropped.
        #expect(t.dungeons[7].boxes[0].cellCurrent == ITEMS.heartContainer)  // fixed heart
        #expect(t.dungeons[7].boxes[1].cellCurrent == ITEMS.anyKey)          // Magic Key
        #expect(t.dungeons[7].boxes[2].cellCurrent == ITEMS.heartContainer)  // relocated coast heart
        #expect(result.dungeonItemsSet == 9)   // 6 dungeon items (incl. L8 key + heart) + 3 named
        #expect(result.heartsPlaced == 0)      // off → no sweep
        #expect(result.unmappedItemCount == 0)
        #expect(t.dungeons[5].boxes[1].playerHas == .no)
    }

    @Test("apply, heart shuffle ON: items placed as listed, every empty slot becomes a heart")
    func applyDungeonItemsHeartShuffle() {
        let model = TrackerModel()
        let r = SpoilerLog.parse(fixture).apply(to: model, sections: .dungeonItems, heartShuffle: true)
        let t = model.dungeonTracker
        #expect(model.heartShuffle == true)
        // L6: one listed item → box[0]; its other box is a shuffled heart.
        #expect(t.dungeons[5].boxes[0].cellCurrent == ITEMS.boomerang)
        #expect(t.dungeons[5].boxes[1].cellCurrent == ITEMS.heartContainer)
        // L9: two items fill both boxes → no leftover heart.
        #expect(t.dungeons[8].boxes[0].cellCurrent == ITEMS.redCandle)
        #expect(t.dungeons[8].boxes[1].cellCurrent == ITEMS.silverArrow)
        // A dungeon with no listed items → all its boxes become hearts (L2 = id 1).
        #expect(t.dungeons[1].boxes.allSatisfy { $0.cellCurrent == ITEMS.heartContainer })
        #expect(r.heartsPlaced > 0)
    }

    @Test("apply reports the still-deferred room-maps section")
    func applyDeferred() {
        let model = TrackerModel()
        let result = SpoilerLog.parse(fixture).apply(to: model, sections: .roomMaps)
        #expect(result.deferredSections == ["Dungeon room maps"])
    }

    @Test("unrecognized cave strings land in unmapped, not mis-marked")
    func unmappedRouting() {
        let weird = SpoilerLog.parse("CAVES\nLocation C4 contains: FLYING TOASTER\n")
        #expect(weird.caves.isEmpty)
        #expect(weird.unmappedCaves.first?.raw == "FLYING TOASTER")
        #expect(weird.unmappedCaves.first?.coord == SpoilerLog.Coord(column: 3, row: 2))
    }
}
