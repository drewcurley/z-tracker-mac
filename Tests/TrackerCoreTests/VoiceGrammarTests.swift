import Testing
@testable import TrackerCore

/// Structured voice-command grammar (T-137/T-138/T-139) — cursor-driven, region-aware,
/// config-matched.
struct VoiceGrammarTests {
    private let config = VoiceConfig()

    @Test func coordinateOnlyMovesCursor() {
        #expect(VoiceGrammar.parse("E7", config: config) == .cursorTo(column: 6, row: 4))
        #expect(VoiceGrammar.parse("A1", config: config) == .cursorTo(column: 0, row: 0))
        #expect(VoiceGrammar.parse("H16", config: config) == .cursorTo(column: 15, row: 7))
    }

    @Test func coordinatePlusActionMovesAndMarks() {
        #expect(VoiceGrammar.parse("D5 bomb shop", config: config)
            == .actionAt(column: 4, row: 3, words: ["bomb", "shop"]))
    }

    @Test func actionOnlyActsAtCursor() {
        #expect(VoiceGrammar.parse("potion", config: config) == .actionAtCursor(words: ["potion"]))
        #expect(VoiceGrammar.parse("meat shop", config: config) == .actionAtCursor(words: ["meat", "shop"]))
    }

    @Test func directionsMoveCursor() {
        #expect(VoiceGrammar.parse("up", config: config) == .moveCursor(dcol: 0, drow: -1))
        #expect(VoiceGrammar.parse("go down", config: config) == .moveCursor(dcol: 0, drow: 1))
        #expect(VoiceGrammar.parse("right", config: config) == .moveCursor(dcol: 1, drow: 0))
        #expect(VoiceGrammar.parse("left", config: config) == .moveCursor(dcol: -1, drow: 0))
    }

    @Test func regionNavAndStart() {
        #expect(VoiceGrammar.parse("overworld", config: config) == .exitToOverworld)
        #expect(VoiceGrammar.parse("leave dungeon", config: config) == .exitToOverworld)
        #expect(VoiceGrammar.parse("start", config: config) == .gotoStart)
        #expect(VoiceGrammar.parse("go to start", config: config) == .gotoStart)
    }

    @Test func dungeonEnterVsMark() {
        #expect(VoiceGrammar.parse("enter level 5", config: config) == .dungeonTab(5))
        #expect(VoiceGrammar.parse("level five", config: config) == .dungeonTab(5))
        #expect(VoiceGrammar.parse("set level 1", config: config) == .actionAtCursor(words: ["set", "level", "1"]))
        #expect(VoiceGrammar.overworldAction(["set", "level", "1"], config: config) == .mark(.dungeon(1)))
    }

    @Test func natoLettersAndNumberWords() {
        #expect(VoiceGrammar.parse("echo seven", config: config) == .cursorTo(column: 6, row: 4))
        #expect(VoiceGrammar.parse("charlie three bomb shop", config: config)
            == .actionAt(column: 2, row: 2, words: ["bomb", "shop"]))
        #expect(VoiceGrammar.parse("echo twelve", config: config) == .cursorTo(column: 11, row: 4))
    }

    @Test func gibberishIsRejected() {
        #expect(VoiceGrammar.parse("", config: config) == nil)
        #expect(VoiceGrammar.parse("hello there", config: config) == nil)
    }

    @Test func overworldActionResolvesMarks() {
        #expect(VoiceGrammar.overworldAction(["bomb", "shop"], config: config) == .mark(.shop(.bomb)))
        #expect(VoiceGrammar.overworldAction(["potion"], config: config) == .mark(.potionShop))
        #expect(VoiceGrammar.overworldAction(["meat"], config: config) == .mark(.shop(.meat)))
        #expect(VoiceGrammar.overworldAction(["armas"], config: config) == .mark(.armos))
        #expect(VoiceGrammar.overworldAction(["white", "sword"], config: config) == .mark(.swordCave(2)))
        #expect(VoiceGrammar.overworldAction(["any", "road", "2"], config: config) == .mark(.anyRoad(2)))
        #expect(VoiceGrammar.overworldAction(["nothing"], config: config) == .mark(.unmarked))
    }

    @Test func overworldActionTakeAnyAndStart() {
        #expect(VoiceGrammar.overworldAction(["take", "any", "potion"], config: config) == .takeAny(.takenPotion))
        #expect(VoiceGrammar.overworldAction(["take", "any"], config: config) == .takeAny(.untaken))
        #expect(VoiceGrammar.overworldAction(["set", "start"], config: config) == .setStart)
        #expect(VoiceGrammar.overworldAction(["clear", "start"], config: config) == .clearStart)
        #expect(VoiceGrammar.overworldAction(["take", "any", "potion"], config: config) != .mark(.potionShop))
    }

    @Test func userAddedPhraseWorks() {
        let c = VoiceConfig()
        c.addPhrase("boom", to: "OW_BombShop")
        #expect(VoiceGrammar.overworldAction(["boom"], config: c) == .mark(.shop(.bomb)))
    }

    // MARK: Dungeon region (T-140)

    @Test func dungeonRoomMonsterAndDropResolve() {
        #expect(VoiceGrammar.dungeonActions(["gleeok"], config: config) == [.monster(.gleeok)])
        #expect(VoiceGrammar.dungeonActions(["staircase"], config: config) == [.roomType(.staircaseToUnknown)])
        #expect(VoiceGrammar.dungeonActions(["heart", "drop"], config: config) == [.floorDrop(.heart)])
        #expect(VoiceGrammar.dungeonActions(["triforce"], config: config) == [.floorDrop(.triforce)])
    }

    @Test func dungeonTransportTakesNumber() {
        #expect(VoiceGrammar.dungeonActions(["transport", "3"], config: config) == [.roomType(.transport3)])
    }

    @Test func singleDoorCommand() {
        #expect(VoiceGrammar.dungeonActions(["open", "left"], config: config) == [.door(.yes, .west)])
        #expect(VoiceGrammar.dungeonActions(["shutter", "right"], config: config) == [.door(.purple, .east)])
        #expect(VoiceGrammar.dungeonActions(["key", "up"], config: config) == [.door(.yellow, .north)])
        #expect(VoiceGrammar.dungeonActions(["blocked", "down"], config: config) == [.door(.no, .south)])
        #expect(VoiceGrammar.dungeonActions(["none", "west"], config: config) == [.door(.unknown, .west)])
    }

    @Test func compoundDoorCommand() {
        #expect(VoiceGrammar.dungeonActions(["open", "west", "shutter", "east", "key", "north"], config: config)
                == [.door(.yes, .west), .door(.purple, .east), .door(.yellow, .north)])
    }

    @Test func doorFillerWordSkipped() {
        // "door" between state and direction is tolerated (T-147).
        #expect(VoiceGrammar.dungeonActions(["open", "door", "north"], config: config) == [.door(.yes, .north)])
        #expect(VoiceGrammar.dungeonActions(["shutter", "door", "left"], config: config) == [.door(.purple, .west)])
        #expect(VoiceGrammar.dungeonActions(["open", "door", "right", "shutter", "door", "down"], config: config)
                == [.door(.yes, .east), .door(.purple, .south)])
    }

    @Test func doorColourSynonyms() {
        #expect(VoiceGrammar.dungeonActions(["green", "north"], config: config) == [.door(.yes, .north)])
        #expect(VoiceGrammar.dungeonActions(["green", "door", "north"], config: config) == [.door(.yes, .north)])
        #expect(VoiceGrammar.dungeonActions(["red", "east"], config: config) == [.door(.no, .east)])
        #expect(VoiceGrammar.dungeonActions(["gold", "up"], config: config) == [.door(.yellow, .north)])
        #expect(VoiceGrammar.dungeonActions(["purple", "down"], config: config) == [.door(.purple, .south)])
        // Compound with colours.
        #expect(VoiceGrammar.dungeonActions(["green", "west", "purple", "east", "gold", "north"], config: config)
                == [.door(.yes, .west), .door(.purple, .east), .door(.yellow, .north)])
    }

    @Test func entranceDirection() {
        #expect(VoiceGrammar.dungeonActions(["entrance", "south"], config: config) == [.entrance(.south)])
        #expect(VoiceGrammar.dungeonActions(["entrance", "down"], config: config) == [.entrance(.south)])
    }

    @Test func entranceFlexiblePhrasing() {
        // Filler "from" between the trigger and the direction (T-146).
        #expect(VoiceGrammar.dungeonActions(["entrance", "from", "north"], config: config) == [.entrance(.north)])
        #expect(VoiceGrammar.dungeonActions(["enter", "from", "north"], config: config) == [.entrance(.north)])
        #expect(VoiceGrammar.dungeonActions(["entered", "from", "west"], config: config) == [.entrance(.west)])
        // Direction before the trigger.
        #expect(VoiceGrammar.dungeonActions(["north", "entrance"], config: config) == [.entrance(.north)])
        // west/east/up/down all resolve.
        #expect(VoiceGrammar.dungeonActions(["entrance", "from", "left"], config: config) == [.entrance(.west)])
    }

    @Test func enterLevelStillSwitchesTab() {
        // Adding "enter"-ish entrance triggers must not steal "enter level N".
        #expect(VoiceGrammar.parse("enter level 5", config: config) == .dungeonTab(5))
    }

    // MARK: Progression toggles (T-142)

    @Test func actionWordTriggersProgressionToggle() {
        #expect(VoiceGrammar.parse("took wood sword", config: config) == .toggleProgression(id: "Prog_WoodSword"))
        #expect(VoiceGrammar.parse("got magical sword", config: config) == .toggleProgression(id: "Prog_MagicalSword"))
        #expect(VoiceGrammar.parse("bought bombs", config: config) == .toggleProgression(id: "Prog_Bomb"))
        #expect(VoiceGrammar.parse("grabbed the meat", config: config) == .toggleProgression(id: "Prog_Meat"))
        #expect(VoiceGrammar.parse("have blue ring", config: config) == .toggleProgression(id: "Prog_BlueRing"))
        #expect(VoiceGrammar.parse("killed ganon", config: config) == .toggleProgression(id: "Prog_Ganon"))
        #expect(VoiceGrammar.parse("rescued zelda", config: config) == .toggleProgression(id: "Prog_Zelda"))
    }

    @Test func bareItemWordStaysACaveOrShopMark() {
        // No action word → the overworld cave / shop mark, not a progression toggle.
        #expect(VoiceGrammar.parse("wood sword", config: config) == .actionAtCursor(words: ["wood", "sword"]))
        #expect(VoiceGrammar.parse("meat", config: config) == .actionAtCursor(words: ["meat"]))
        #expect(VoiceGrammar.parse("bomb shop", config: config) == .actionAtCursor(words: ["bomb", "shop"]))
    }

    @Test func takeAnyNotSwallowedByProgression() {
        // "take" is an action word, but nothing after it names a progression item.
        #expect(VoiceGrammar.parse("take any potion", config: config) == .actionAtCursor(words: ["take", "any", "potion"]))
    }

    @Test func globalVsOverworldProgressionScope() {
        #expect(VoiceGrammar.isGlobalProgression("Prog_Bomb"))
        #expect(VoiceGrammar.isGlobalProgression("Prog_Ganon"))
        #expect(VoiceGrammar.isGlobalProgression("Prog_Zelda"))
        #expect(VoiceGrammar.isGlobalProgression("Prog_WoodSword") == false)
        #expect(VoiceGrammar.isGlobalProgression("Prog_Meat") == false)
    }

    // MARK: Item boxes (T-143)

    @Test func itemBoxCommandResolvesBoxAndItem() {
        #expect(VoiceGrammar.parse("coast ladder", config: config) == .setItemBox(boxID: "Box_Coast", itemID: "Item_Ladder"))
        #expect(VoiceGrammar.parse("coast item recorder", config: config) == .setItemBox(boxID: "Box_Coast", itemID: "Item_Recorder"))
        #expect(VoiceGrammar.parse("armos item bow", config: config) == .setItemBox(boxID: "Box_Armos", itemID: "Item_Bow"))
        #expect(VoiceGrammar.parse("coast item nothing", config: config) == .setItemBox(boxID: "Box_Coast", itemID: "Item_Nothing"))
    }

    @Test func whiteSwordBoxDoesNotEatItsOwnName() {
        // "white sword item bow" → the box holds a *bow*, not the white sword.
        #expect(VoiceGrammar.parse("white sword item bow", config: config)
                == .setItemBox(boxID: "Box_WhiteSword", itemID: "Item_Bow"))
        // …but the box CAN hold the white sword item.
        #expect(VoiceGrammar.parse("white sword box white sword", config: config)
                == .setItemBox(boxID: "Box_WhiteSword", itemID: "Item_WhiteSword"))
    }

    @Test func bareBoxWordStaysACaveMark() {
        // No item after the box word → the overworld cave mark, not a box command.
        #expect(VoiceGrammar.parse("white sword", config: config) == .actionAtCursor(words: ["white", "sword"]))
        #expect(VoiceGrammar.parse("armos", config: config) == .actionAtCursor(words: ["armos"]))
    }

    @Test func doorCommandNotEatenByCursorMove() {
        // "open left" is a door command at the cursor, not a cursor move left.
        #expect(VoiceGrammar.parse("open left", config: config) == .actionAtCursor(words: ["open", "left"]))
        // bare "left" is still a cursor move.
        #expect(VoiceGrammar.parse("left", config: config) == .moveCursor(dcol: -1, drow: 0))
    }
}
