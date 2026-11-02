import Testing
@testable import TrackerCore

@Suite("Hotkey config (T-130)")
struct HotkeyConfigTests {
    @Test("catalog: every context populated, ids unique, known selectors present")
    func catalog() {
        for ctx in HotkeyContext.allCases {
            #expect(!HotkeyCatalog.selectors(in: ctx).isEmpty)
        }
        let ids = HotkeyCatalog.all.map(\.id)
        #expect(Set(ids).count == ids.count)   // no duplicates
        #expect(HotkeyCatalog.selector(id: "Overworld_Level1")?.context == .overworld)
        #expect(HotkeyCatalog.selector(id: "Global_DungeonTab1")?.context == .global)
        // Mac-only additions (T-131) live in the Global group.
        #expect(HotkeyCatalog.selector(id: "Global_StartTimer")?.context == .global)
        #expect(HotkeyCatalog.selector(id: "Global_GroundhogReset")?.displayName == "Groundhog reset (skip confirmation)")
        #expect(HotkeyCatalog.selector(id: "DungeonRoom_MonsterDetail_Bow")?.displayName == "Gohma")
        #expect(HotkeyCatalog.selector(id: "Bogus_Name") == nil)
    }

    @Test("parseChord handles keys, modifiers, and raw codes")
    func parseChord() {
        #expect(HotkeyConfig.parseChord("a") == HotkeyChord(key: "a"))
        #expect(HotkeyConfig.parseChord("A") == HotkeyChord(key: "a"))         // lowercased
        #expect(HotkeyConfig.parseChord("5") == HotkeyChord(key: "5"))
        #expect(HotkeyConfig.parseChord("SHIFT 4") == HotkeyChord(modifier: .shift, key: "4"))
        #expect(HotkeyConfig.parseChord("CTRL g") == HotkeyChord(modifier: .control, key: "g"))
        #expect(HotkeyConfig.parseChord("\\75") == HotkeyChord(key: "\\75"))
        #expect(HotkeyConfig.parseChord("ab") == nil)     // two chars
        #expect(HotkeyConfig.parseChord("") == nil)
        #expect(HotkeyConfig.parseChord("\\") == nil)     // bare backslash
    }

    @Test("parse: known names, blank = unbound, unknown = warning")
    func parseFile() {
        let text = """
        # comment
        Overworld_Level1 = 1
        Overworld_Level2 =
        Item_Bow = SHIFT b
        Bogus_Thing = x
        """
        let r = HotkeyConfig.parse(text)
        #expect(r.bindings["Overworld_Level1"] == HotkeyChord(key: "1"))
        #expect(r.bindings["Overworld_Level2"] == nil)                        // blank
        #expect(r.bindings["Item_Bow"] == HotkeyChord(modifier: .shift, key: "b"))
        #expect(r.warnings.contains { $0.contains("Bogus_Thing") })
    }

    @Test("conflicts: same context clashes, different non-global contexts don't")
    func conflictsWithinContext() {
        let c = HotkeyConfig()
        c.setChord(HotkeyChord(key: "1"), for: "Overworld_Level1")
        // Same context, same key → conflict.
        #expect(c.conflicts(for: "Overworld_Level2", chord: HotkeyChord(key: "1"))
                .map(\.id) == ["Overworld_Level1"])
        // Different (non-global) context reuses the key freely → no conflict.
        #expect(c.conflicts(for: "Item_Bow", chord: HotkeyChord(key: "1")).isEmpty)
        // A different key → no conflict.
        #expect(c.conflicts(for: "Overworld_Level2", chord: HotkeyChord(key: "2")).isEmpty)
    }

    @Test("conflicts: global keys clash across all non-contextual contexts")
    func globalConflicts() {
        let c = HotkeyConfig()
        c.setChord(HotkeyChord(key: "g"), for: "Global_ToggleGannon")
        // A non-contextual context binding the same key clashes with the global.
        #expect(c.conflicts(for: "Item_Bow", chord: HotkeyChord(key: "g")).map(\.id)
                == ["Global_ToggleGannon"])
        // And vice-versa: binding a global key already used by a non-global context.
        let c2 = HotkeyConfig()
        c2.setChord(HotkeyChord(key: "b"), for: "Item_Bow")
        #expect(c2.conflicts(for: "Global_ToggleBombs", chord: HotkeyChord(key: "b")).map(\.id)
                == ["Item_Bow"])
    }

    @Test("conflicts: contextual menus are separate and exempt from global")
    func contextualExempt() {
        let c = HotkeyConfig()
        c.setChord(HotkeyChord(key: "p"), for: "Contextual_TakeAny_Potion")
        // Same menu → conflict.
        #expect(!c.conflicts(for: "Contextual_TakeAny_Candle", chord: HotkeyChord(key: "p")).isEmpty)
        // Different menu (Take-This) → no conflict.
        #expect(c.conflicts(for: "Contextual_TakeThis_Candle", chord: HotkeyChord(key: "p")).isEmpty)
        // A global key doesn't clash with a contextual one.
        #expect(c.conflicts(for: "Global_ToggleBombs", chord: HotkeyChord(key: "p")).isEmpty)
    }

    @Test("reassign moves a key: removes it from the conflicting binding(s)")
    func reassignMoves() {
        let c = HotkeyConfig()
        c.setChord(HotkeyChord(key: "b"), for: "Item_Bow")
        // Reassign the same key to another selector in the same context → moves it.
        let displaced = c.reassign(HotkeyChord(key: "b"), to: "Item_Boomerang")
        #expect(displaced.map(\.id) == ["Item_Bow"])
        #expect(c.chord(for: "Item_Bow") == nil)                 // taken away
        #expect(c.chord(for: "Item_Boomerang") == HotkeyChord(key: "b"))

        // A global key reassigned displaces the non-global that held it.
        c.setChord(HotkeyChord(key: "g"), for: "Item_Wand")
        let d2 = c.reassign(HotkeyChord(key: "g"), to: "Global_ToggleGannon")
        #expect(d2.map(\.id) == ["Item_Wand"])
        #expect(c.chord(for: "Item_Wand") == nil)
        // A non-conflicting reassign displaces nothing.
        #expect(c.reassign(HotkeyChord(key: "z"), to: "Overworld_Level1").isEmpty)
    }

    @Test("reverse lookup: selectors bound to a chord, filtered by context (T-132)")
    func reverseLookup() {
        let c = HotkeyConfig()
        c.setChord(HotkeyChord(key: "1"), for: "Overworld_Level1")
        c.setChord(HotkeyChord(key: "1"), for: "Item_Boomerang")   // same key, different context
        c.setChord(HotkeyChord(key: "t"), for: "Global_StartTimer")
        #expect(Set(c.selectorIDs(boundTo: HotkeyChord(key: "1")))
                == ["Overworld_Level1", "Item_Boomerang"])
        #expect(c.selectorID(boundTo: HotkeyChord(key: "1"), in: .overworld) == "Overworld_Level1")
        #expect(c.selectorID(boundTo: HotkeyChord(key: "t"), in: .global) == "Global_StartTimer")
        #expect(c.selectorID(boundTo: HotkeyChord(key: "z"), in: .global) == nil)
    }

    @Test("editor order lists Global first, Contextual last")
    func editorOrder() {
        #expect(HotkeyContext.editorOrder.first == .global)
        #expect(HotkeyContext.editorOrder.last == .contextual)
        #expect(Set(HotkeyContext.editorOrder) == Set(HotkeyContext.allCases))
    }

    @Test("export → parse round-trips the bindings")
    func roundTrip() {
        let c = HotkeyConfig()
        c.setChord(HotkeyChord(key: "1"), for: "Overworld_Level1")
        c.setChord(HotkeyChord(modifier: .shift, key: "b"), for: "Item_Bow")
        c.setChord(HotkeyChord(key: "\\75"), for: "Global_DungeonTab1")
        let r = HotkeyConfig.parse(c.exportText())
        #expect(r.warnings.isEmpty)                 // every catalog name is recognized
        #expect(r.bindings == c.bindings)
    }
}
