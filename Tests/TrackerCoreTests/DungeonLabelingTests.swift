import Testing
@testable import TrackerCore

@Suite("Dungeon labeling + HDN toggles (T-049)")
struct DungeonLabelingTests {
    @Test("slot labels: numbers when off, A–H when HDN, Level 9 stays 9")
    func slotLabels() {
        // Non-HDN: the number itself.
        for n in 1...9 {
            #expect(DungeonLabeling.slotLabel(n, hideDungeonNumbers: false) == "\(n)")
        }
        // HDN: 1–8 → A–H.
        #expect(DungeonLabeling.slotLabel(1, hideDungeonNumbers: true) == "A")
        #expect(DungeonLabeling.slotLabel(8, hideDungeonNumbers: true) == "H")
        // Level 9 is always known, stays "9".
        #expect(DungeonLabeling.slotLabel(9, hideDungeonNumbers: true) == "9")
    }

    @Test("columnName joins the prefix to the slot label; the prefix carries its separator (T-171)")
    func columnNames() {
        #expect(DungeonLabeling.columnName(slot: 1, prefix: "LEVEL-", hideDungeonNumbers: false) == "LEVEL-1")
        #expect(DungeonLabeling.columnName(slot: 9, prefix: "LEVEL-", hideDungeonNumbers: false) == "LEVEL-9")
        // Custom prefixes carry their own separator — a dash, or none at all.
        #expect(DungeonLabeling.columnName(slot: 1, prefix: "area-", hideDungeonNumbers: false) == "area-1")
        #expect(DungeonLabeling.columnName(slot: 1, prefix: "DUNGEON", hideDungeonNumbers: false) == "DUNGEON1")
        #expect(DungeonLabeling.columnName(slot: 3, prefix: "BOARD-", hideDungeonNumbers: false) == "BOARD-3")
        // HDN: 1–8 → letters, 9 stays 9.
        #expect(DungeonLabeling.columnName(slot: 1, prefix: "LEVEL-", hideDungeonNumbers: true) == "LEVEL-A")
        #expect(DungeonLabeling.columnName(slot: 9, prefix: "BOARD-", hideDungeonNumbers: true) == "BOARD-9")
    }

    @Test("columnWord strips a trailing separator for the picker submenu title (T-171)")
    func columnWordStripsSeparator() {
        #expect(DungeonLabeling.columnWord(prefix: "LEVEL-") == "LEVEL")
        #expect(DungeonLabeling.columnWord(prefix: "area-") == "area")
        #expect(DungeonLabeling.columnWord(prefix: "DUNGEON") == "DUNGEON")
        #expect(DungeonLabeling.columnWord(prefix: "L-") == "L")
        // All-separator prefix has no word to show — fall back to the raw prefix.
        #expect(DungeonLabeling.columnWord(prefix: "--") == "--")
    }

    @Test("setHideDungeonNumbers rebuilds the tracker (3 boxes) and back")
    func hdnRebuildsTracker() {
        let model = TrackerModel(quest: .first)
        model.selectQuest(.first)
        #expect(model.dungeonTracker.kind == .default)
        #expect(model.dungeonTracker.dungeon(0).baseBoxes.count == 2)

        model.setHideDungeonNumbers(true)
        #expect(model.hideDungeonNumbers)
        #expect(model.dungeonTracker.kind == .hideDungeonNumbers)
        #expect(model.dungeonTracker.dungeon(0).baseBoxes.count == 3)  // 3 boxes per dungeon
        #expect(model.dungeonTracker.dungeon(8).baseBoxes.count == 2)  // Level 9 keeps 2

        // Toggling back restores DEFAULT.
        model.setHideDungeonNumbers(false)
        #expect(model.dungeonTracker.kind == .default)
        #expect(model.dungeonTracker.dungeon(0).baseBoxes.count == 2)
    }

    @Test("setHideDungeonNumbers preserves the second-quest-dungeons choice")
    func hdnPreservesSecondQuest() {
        let model = TrackerModel()
        model.dungeonTracker.toggleSecondQuestDungeons()
        #expect(model.dungeonTracker.isSecondQuestDungeons)
        model.setHideDungeonNumbers(true)
        #expect(model.dungeonTracker.isSecondQuestDungeons)
    }

    @Test("identifiedAsTwoBoxer: HDN dungeons flagged once assigned a 2-item number")
    func twoBoxerIdentification() {
        // Two-boxer whitelist: 1Q → 234567 (three-item = 1,8); 2Q → 123567 (=4,8).
        #expect(Dungeon.twoBoxerDigits(secondQuest: false) == "234567")
        #expect(Dungeon.twoBoxerDigits(secondQuest: true) == "123567")

        let inst = DungeonTrackerInstance(kind: .hideDungeonNumbers, isSecondQuestDungeons: false)
        let d = inst.dungeon(0)
        // Unassigned → not a two-boxer (no disabling).
        #expect(!d.identifiedAsTwoBoxer)
        // Assign a two-item number (5) → two-boxer; assign a three-item (8) → not.
        d.labelChar = "5"
        #expect(d.identifiedAsTwoBoxer)
        d.labelChar = "8"
        #expect(!d.identifiedAsTwoBoxer)
        d.labelChar = "1"   // 1 is a three-item dungeon in 1Q
        #expect(!d.identifiedAsTwoBoxer)

        // In DEFAULT mode there's no HDN identification, so never flagged.
        let def = DungeonTrackerInstance(kind: .default)
        def.dungeon(0).labelChar = "5"
        #expect(!def.dungeon(0).identifiedAsTwoBoxer)
    }

    @Test("setHeartShuffle re-seeds the dungeon floor hearts")
    func heartShuffleReseeds() {
        let model = TrackerModel(quest: .first)
        model.selectQuest(.first)
        // Shuffle off (default): dungeon 1's floor box knows a Heart Container.
        #expect(model.dungeonTracker.dungeon(0).baseBoxes[0].cellCurrent == ITEMS.heartContainer)
        // Turn shuffle on: that box empties (heart shuffled into the pool).
        model.setHeartShuffle(.full)
        #expect(model.dungeonTracker.dungeon(0).baseBoxes[0].cellCurrent == -1)
        // Back off: the known heart returns.
        model.setHeartShuffle(.off)
        #expect(model.dungeonTracker.dungeon(0).baseBoxes[0].cellCurrent == ITEMS.heartContainer)
    }
}
