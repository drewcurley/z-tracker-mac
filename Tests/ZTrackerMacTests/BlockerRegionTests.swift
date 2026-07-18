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
}
