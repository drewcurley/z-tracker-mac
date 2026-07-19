import Testing
import TrackerCore
@testable import ZTrackerMac

/// Blockers cursor ↔ (dungeon, slot) mapping + hotkey kind resolution (T-135).
@MainActor
struct BlockerRegionTests {
    typealias Cell = TrackerFocusState.GridCell

    @Test func cellAndTargetRoundTrip() {
        for dungeon in 0..<9 {
            for slot in 0..<BlockerRegion.slots {
                let cell = BlockerRegion.cell(dungeon: dungeon, slot: slot)
                let t = BlockerRegion.target(cell)
                #expect(t.dungeon == dungeon && t.slot == slot)
            }
        }
    }

    @Test func gridCoversAllDungeonsAndSlots() {
        var seen = Set<String>()
        for row in 0..<BlockerRegion.rows {
            for col in 0..<BlockerRegion.cols {
                let t = BlockerRegion.target(Cell(col: col, row: row))
                seen.insert("\(t.dungeon)-\(t.slot)")
            }
        }
        #expect(seen.count == 9 * BlockerRegion.slots)
    }

    @Test func selectorIDResolvesToBlockerKind() {
        #expect(DungeonBlocker.fromHotKeyName("Blocker_Bomb") == .bomb)
        #expect(DungeonBlocker.fromHotKeyName("Blocker_Maybe_Ladder") == .maybeLadder)
        #expect(DungeonBlocker.fromHotKeyName("Blocker_Nothing") == .nothing)
    }

    /// Every catalog blocker selector resolves to a non-defaulted kind (except the
    /// intentional Nothing → .nothing).
    @Test func everyBlockerSelectorResolves() {
        for sel in HotkeyCatalog.selectors(in: .blockers) {
            let kind = DungeonBlocker.fromHotKeyName(sel.id)
            if sel.id != "Blocker_Nothing" {
                #expect(kind.asHotKeyName == sel.id, "\(sel.id) → \(kind.asHotKeyName)")
            }
        }
    }

    /// T-159: a spoken blocker word applied at a blockers cursor cell sets that
    /// dungeon+slot — the end-to-end path grammar → BlockerRegion.target → model.
    @Test func spokenBlockerSetsTheCursorSlot() {
        let config = VoiceConfig()
        let model = TrackerModel(quest: .first)
        let cell = BlockerRegion.cell(dungeon: 5, slot: 1)
        let kind = VoiceGrammar.blockerAction(["maybe", "ladder"], config: config)
        #expect(kind == .maybeLadder)
        let t = BlockerRegion.target(cell)
        model.dungeonBlockers.setDungeonBlocker(kind!, dungeon: t.dungeon, slot: t.slot)
        #expect(model.dungeonBlockers.dungeonBlocker(dungeon: 5, slot: 1) == .maybeLadder)
        // A "nothing" clears it.
        model.dungeonBlockers.setDungeonBlocker(.nothing, dungeon: t.dungeon, slot: t.slot)
        #expect(model.dungeonBlockers.dungeonBlocker(dungeon: 5, slot: 1) == .nothing)
    }

    /// Every catalog voice-blocker phrase resolves to the kind whose hotkey-name
    /// matches its id, so the voice vocabulary can't silently drift from the model.
    @Test func everyVoiceBlockerActionResolves() {
        let config = VoiceConfig()
        for action in VoiceCatalog.actions(in: .blockers) {
            let kind = DungeonBlocker.fromHotKeyName(action.id)
            #expect(kind.asHotKeyName == action.id, "\(action.id) → \(kind.asHotKeyName)")
            // And its first default phrase parses back to that same kind.
            if let phrase = action.defaultPhrases.first {
                let words = phrase.split(separator: " ").map(String.init)
                #expect(VoiceGrammar.blockerAction(words, config: config) == kind,
                        "phrase \(phrase) did not resolve to \(action.id)")
            }
        }
    }
}
