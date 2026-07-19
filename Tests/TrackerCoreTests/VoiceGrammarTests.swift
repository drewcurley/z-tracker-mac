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

    @Test func stopListeningCommand() {
        #expect(VoiceGrammar.parse("stop listening", config: config) == .stopListening)
        #expect(VoiceGrammar.parse("pause voice", config: config) == .stopListening)
        #expect(VoiceGrammar.parse("go to sleep", config: config) == .stopListening)
        // "restart" is still go-to-start, not stop.
        #expect(VoiceGrammar.parse("restart", config: config) == .gotoStart)
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

    @Test func coordinatePlusLevelMarksNotTab() {
        // A coordinate before "level N" places the dungeon at that cell (T-151),
        // not a tab switch.
        #expect(VoiceGrammar.parse("E2 level two", config: config)
                == .actionAt(column: 1, row: 4, words: ["set", "level", "2"]))
        #expect(VoiceGrammar.parse("A6 level six", config: config)
                == .actionAt(column: 5, row: 0, words: ["set", "level", "6"]))
        // No coordinate → still a tab switch.
        #expect(VoiceGrammar.parse("level two", config: config) == .dungeonTab(2))
    }

    @Test func natoLettersAndNumberWords() {
        #expect(VoiceGrammar.parse("echo seven", config: config) == .cursorTo(column: 6, row: 4))
        #expect(VoiceGrammar.parse("charlie three bomb shop", config: config)
            == .actionAt(column: 2, row: 2, words: ["bomb", "shop"]))
        #expect(VoiceGrammar.parse("echo twelve", config: config) == .cursorTo(column: 11, row: 4))
    }

    @Test func twoDigitColumnFold() {
        // "G12" heard as "G1 two" / "G1 2" folds back to column 12 (T-152).
        #expect(VoiceGrammar.parse("G1 two", config: config) == .cursorTo(column: 11, row: 6))
        #expect(VoiceGrammar.parse("G1 2", config: config) == .cursorTo(column: 11, row: 6))
        #expect(VoiceGrammar.parse("E1 six", config: config) == .cursorTo(column: 15, row: 4))
        // With a trailing action: "G1 two door repair" → mark at G12.
        #expect(VoiceGrammar.parse("G1 two door repair", config: config)
                == .actionAt(column: 11, row: 6, words: ["door", "repair"]))
        // A number that isn't a number-word doesn't fold: "G2 potion" stays G2.
        #expect(VoiceGrammar.parse("G2 potion", config: config)
                == .actionAt(column: 1, row: 6, words: ["potion"]))
    }

    @Test func letterHomophonesForCoordinates() {
        // H ("aitch") is the worst-recognised row (T-148).
        #expect(VoiceGrammar.parse("each four", config: config) == .cursorTo(column: 3, row: 7))
        #expect(VoiceGrammar.parse("each 8", config: config) == .cursorTo(column: 7, row: 7))
        #expect(VoiceGrammar.parse("aitch 2", config: config) == .cursorTo(column: 1, row: 7))
        #expect(VoiceGrammar.parse("gee 3", config: config) == .cursorTo(column: 2, row: 6))
        // A homophone with no following number is NOT a coordinate.
        #expect(VoiceGrammar.parse("each", config: config) == nil)
    }

    @Test func gibberishIsRejected() {
        #expect(VoiceGrammar.parse("", config: config) == nil)
        #expect(VoiceGrammar.parse("hello there", config: config) == nil)
    }

    @Test func partialPhraseAliases() {
        // Natural partial forms that missed in QA now resolve (T-154).
        #expect(VoiceGrammar.overworldAction(["money", "making"], config: config) == .mark(.moneyMakingGame))
        #expect(VoiceGrammar.overworldAction(["money"], config: config) == .mark(.moneyMakingGame))
        #expect(VoiceGrammar.dungeonActions(["possible", "push"], config: config) == [.roomType(.maybePushBlock)])
        #expect(VoiceGrammar.dungeonActions(["maybe", "push"], config: config) == [.roomType(.maybePushBlock)])
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

    @Test func combinedDungeonCommand() {
        // Room + monster + door in one utterance (T-150). Order: doors, entrance,
        // room, monster, drop.
        #expect(VoiceGrammar.dungeonActions(["nondescript", "digdogger", "open", "left"], config: config)
                == [.door(.yes, .west), .roomType(.nonDescript), .monster(.digdogger)])
        #expect(VoiceGrammar.dungeonActions(["nondescript", "digdogger"], config: config)
                == [.roomType(.nonDescript), .monster(.digdogger)])
        #expect(VoiceGrammar.dungeonActions(["nondescript", "heart", "drop"], config: config)
                == [.roomType(.nonDescript), .floorDrop(.heart)])
        // Room + two doors.
        #expect(VoiceGrammar.dungeonActions(["nondescript", "open", "left", "open", "down"], config: config)
                == [.door(.yes, .west), .door(.yes, .south), .roomType(.nonDescript)])
    }

    @Test func genericDropMarker() {
        // Bare "drop"/"floor drop"/"dropped" → a generic item drop (T-157)...
        #expect(VoiceGrammar.dungeonActions(["drop"], config: config) == [.floorDrop(.otherKeyItem)])
        #expect(VoiceGrammar.dungeonActions(["floor", "drop"], config: config) == [.floorDrop(.otherKeyItem)])
        // ...but specific drops still win via longest-match.
        #expect(VoiceGrammar.dungeonActions(["heart", "drop"], config: config) == [.floorDrop(.heart)])
        #expect(VoiceGrammar.dungeonActions(["key", "drop"], config: config) == [.floorDrop(.key)])
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

    @Test func itemBoxWithoutQualifier() {
        // "armos ladder" / "white sword bow" set the box without needing "item"/"box" (T-153);
        // the following item disambiguates from the bare cave mark.
        #expect(VoiceGrammar.parse("armos ladder", config: config)
                == .setItemBox(boxID: "Box_Armos", itemID: "Item_Ladder"))
        #expect(VoiceGrammar.parse("white sword bow", config: config)
                == .setItemBox(boxID: "Box_WhiteSword", itemID: "Item_Bow"))
        #expect(VoiceGrammar.parse("armor recorder", config: config)
                == .setItemBox(boxID: "Box_Armos", itemID: "Item_Recorder"))
    }

    // MARK: Clear / un-mark (T-149)

    @Test func clearRoutesToClearCommand() {
        #expect(VoiceGrammar.parse("clear triforce", config: config) == .clearAtCursor(words: ["triforce"]))
        #expect(VoiceGrammar.parse("clear gleeok", config: config) == .clearAtCursor(words: ["gleeok"]))
        #expect(VoiceGrammar.parse("clear north", config: config) == .clearAtCursor(words: ["north"]))
        #expect(VoiceGrammar.parse("clear", config: config) == .clearAtCursor(words: []))
        #expect(VoiceGrammar.parse("remove", config: config) == .clearAtCursor(words: []))
        // Progression un-mark (negation is the action word here).
        #expect(VoiceGrammar.parse("un take silver arrows", config: config) == .clearAtCursor(words: ["silver", "arrows"]))
        #expect(VoiceGrammar.parse("untake wood sword", config: config) == .clearAtCursor(words: ["wood", "sword"]))
    }

    @Test func clearStartStaysASpecificCommand() {
        // "clear start" is OW_ClearStart, not a generic clear — must fall through.
        #expect(VoiceGrammar.parse("clear start", config: config) == .actionAtCursor(words: ["clear", "start"]))
    }

    @Test func dungeonClearTargets() {
        #expect(VoiceGrammar.dungeonClearActions(["triforce"], config: config) == [.floorDrop(.triforce)])
        #expect(VoiceGrammar.dungeonClearActions(["gleeok"], config: config) == [.monster(.gleeok)])
        #expect(VoiceGrammar.dungeonClearActions(["north"], config: config) == [.door(.unknown, .north)])
        #expect(VoiceGrammar.dungeonClearActions(["door", "left"], config: config) == [.door(.unknown, .west)])
        #expect(VoiceGrammar.dungeonClearActions([], config: config) == [])   // → generic room clear
    }

    @Test func doorCommandNotEatenByCursorMove() {
        // "open left" is a door command at the cursor, not a cursor move left.
        #expect(VoiceGrammar.parse("open left", config: config) == .actionAtCursor(words: ["open", "left"]))
        // bare "left" is still a cursor move.
        #expect(VoiceGrammar.parse("left", config: config) == .moveCursor(dcol: -1, drow: 0))
    }

    // MARK: - T-158: single-utterance two-item shop

    private func shopPair(_ phrase: String) -> (primary: ShopKind, second: ShopKind)? {
        VoiceGrammar.overworldShopPair(phrase.split(separator: " ").map(String.init), config: config)
    }

    @Test func twoShopWordsGiveAPair() {
        // "second item" filler between the two shop names.
        #expect(shopPair("bomb shop second item meat")?.primary == .bomb)
        #expect(shopPair("bomb shop second item meat")?.second == .meat)
    }

    @Test func twoShopWordsJoinedByAnd() {
        let p = shopPair("bomb shop and meat")
        #expect(p?.primary == .bomb)
        #expect(p?.second == .meat)
    }

    @Test func shopPairKeepsSpokenOrder() {
        // Order spoken decides primary vs second, regardless of enum order.
        let p = shopPair("meat and bomb shop")
        #expect(p?.primary == .meat)
        #expect(p?.second == .bomb)
    }

    @Test func singleShopIsNotAPair() {
        #expect(shopPair("bomb shop") == nil)
        #expect(shopPair("meat") == nil)
    }

    @Test func repeatedSameShopIsNotAPair() {
        // Two mentions of the *same* kind is not two distinct items.
        #expect(shopPair("bomb shop and bombs") == nil)
    }

    @Test func potionAndHintShopsNeverPair() {
        // Potion/hint are their own marks, not ShopKind — never a shop pair.
        #expect(shopPair("potion shop and hint shop") == nil)
        #expect(shopPair("bomb shop and potion") == nil)   // only one real shop kind
    }

    @Test func threeShopsTakeFirstTwo() {
        let p = shopPair("candle bomb shop meat")
        #expect(p?.primary == .candle)
        #expect(p?.second == .bomb)
    }
}
