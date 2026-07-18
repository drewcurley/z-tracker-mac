import Testing
@testable import TrackerCore

/// The built-in right-half default binding scheme (T-135).
struct HotkeyDefaultsTests {
    private let defaults = HotkeyDefaults.bindings()

    @Test func bindsEverySelectorExceptDoorNudges() {
        for sel in HotkeyCatalog.all {
            let isDoorNudge = sel.id.contains("DoorIncrement") || sel.id.contains("DoorDecrement")
            if isDoorNudge {
                #expect(defaults[sel.id] == nil, "\(sel.id) should be unbound by default")
            } else {
                #expect(defaults[sel.id] != nil, "\(sel.id) has no default binding")
            }
        }
    }

    /// The whole default set must be internally conflict-free, or a shipped default
    /// would silently shadow another.
    @Test func hasNoConflicts() {
        let config = HotkeyConfig(bindings: defaults)
        for (id, chord) in defaults {
            guard let sel = HotkeyCatalog.selector(id: id) else { continue }
            let clashes = config.conflicts(for: id, chord: chord)
            #expect(clashes.isEmpty,
                    "\(id) (\(chord.fileToken)) conflicts with \(clashes.map(\.id))")
        }
    }

    @Test func usesOnlyRightHalfModifiers() {
        // No Command / Control in defaults (OS-reserved / absent on the right side).
        for chord in defaults.values {
            #expect(chord.modifier == .none || chord.modifier == .shift || chord.modifier == .option)
        }
    }

    @Test func regionsShareTheTypingBlockAcrossScopes() {
        // The same plain key drives the first selector of several regions (proof the
        // palette is reused across non-conflicting scopes).
        let firstItem = HotkeyCatalog.selectors(in: .items).first!.id
        let firstOw = HotkeyCatalog.selectors(in: .overworld).first!.id
        #expect(defaults[firstItem] == defaults[firstOw])   // both palette[0] = "7"
    }

    @Test func dungeonRoomTiersFollowGrouping() {
        // Room types plain, monsters Shift, floor drops Option.
        let roomType = "DungeonRoom_RoomType_NonDescript"
        let monster = "DungeonRoom_MonsterDetail_Gleeok"
        let floor = "DungeonRoom_FloorDropDetail_Triforce"
        #expect(defaults[roomType]?.modifier == HotkeyChord.Modifier.none)
        #expect(defaults[monster]?.modifier == HotkeyChord.Modifier.shift)
        #expect(defaults[floor]?.modifier == HotkeyChord.Modifier.option)
    }

    @Test func regionCycleOnPageDown() {
        #expect(defaults["Global_CycleRegionForward"] == HotkeyChord(key: "\\121"))
        #expect(defaults["Global_CycleRegionBackward"] == HotkeyChord(modifier: .shift, key: "\\121"))
    }
}
