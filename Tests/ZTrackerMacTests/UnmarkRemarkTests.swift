import Testing
import TrackerCore
@testable import ZTrackerMac

/// T-169 — the v1.3 "Unmark → Remark" chains: pressing a dungeon-room key three times
/// (mark, unmark, remark) fires that key's linked action. Driven through the real
/// dispatcher so the `justUnmarked` state machine is exercised end to end.
@Suite("Unmark–Remark chains (T-169)")
@MainActor
struct UnmarkRemarkTests {

    /// A dispatcher wired to a fresh model, with the dungeon-map cursor parked on a
    /// given tab + room.
    private func makeDispatcher(tab: Int, col: Int, row: Int)
        -> (GlobalHotkeyDispatcher, TrackerModel) {
        let model = TrackerModel(quest: .first)
        let focus = TrackerFocusState()
        focus.selectedDungeonTab = tab
        focus.cursorRegion = .dungeonMap
        focus.dungeonCursor = .init(col: col, row: row)
        focus.cursorShown = true
        let d = GlobalHotkeyDispatcher(model: model, options: TrackerOptions(),
                                       timer: TrackerTimer(), hotkeys: HotkeyConfig(), focus: focus)
        return (d, model)
    }

    private func roomSel(_ name: String) -> String { "DungeonRoom_" + name }

    @Test("first press marks, second unmarks, third re-marks and fires the linked action")
    func triforceChainTogglesHasTriforce() {
        let (d, model) = makeDispatcher(tab: 3, col: 2, row: 2)
        let sel = roomSel(FloorDropDetail.triforce.hotKeyName)
        let dungeon = model.dungeonTracker.dungeon(3)
        #expect(dungeon.playerHasTriforce == false)

        d.performDungeonRoom(sel)     // mark triforce floor drop
        #expect(model.dungeonRoomMaps[3].room(col: 2, row: 2).floorDropDetail == .triforce)
        #expect(dungeon.playerHasTriforce == false)   // not yet

        d.performDungeonRoom(sel)     // unmark
        #expect(model.dungeonRoomMaps[3].room(col: 2, row: 2).floorDropDetail == .unmarked)

        d.performDungeonRoom(sel)     // re-mark → fires: toggle has-triforce
        #expect(model.dungeonRoomMaps[3].room(col: 2, row: 2).floorDropDetail == .triforce)
        #expect(dungeon.playerHasTriforce == true)
    }

    @Test("a fifth press fires again (successive unmark–remark)")
    func successiveChainsFireEachTime() {
        let (d, model) = makeDispatcher(tab: 3, col: 2, row: 2)
        let sel = roomSel(FloorDropDetail.map.hotKeyName)
        let dungeon = model.dungeonTracker.dungeon(3)
        for _ in 0..<3 { d.performDungeonRoom(sel) }   // fires once
        #expect(dungeon.playerHasMap == true)
        d.performDungeonRoom(sel)                       // unmark
        d.performDungeonRoom(sel)                       // remark → fires again
        #expect(dungeon.playerHasMap == false)
    }

    @Test("a plain single mark does not fire the linked action")
    func singleMarkDoesNotFire() {
        let (d, model) = makeDispatcher(tab: 3, col: 2, row: 2)
        d.performDungeonRoom(roomSel(FloorDropDetail.triforce.hotKeyName))
        #expect(model.dungeonTracker.dungeon(3).playerHasTriforce == false)
    }

    @Test("unmark then a DIFFERENT key's remark does not fire")
    func differentKeyBreaksTheChain() {
        let (d, model) = makeDispatcher(tab: 3, col: 2, row: 2)
        let triforce = roomSel(FloorDropDetail.triforce.hotKeyName)
        d.performDungeonRoom(triforce)   // mark
        d.performDungeonRoom(triforce)   // unmark (justUnmarked set)
        d.performDungeonRoom(roomSel(FloorDropDetail.heart.hotKeyName))   // different key
        // Re-marking triforce now should NOT fire, because the chain was broken.
        d.performDungeonRoom(triforce)
        #expect(model.dungeonTracker.dungeon(3).playerHasTriforce == false)
    }

    @Test("a moat room's chain marks a maybe-Ladder blocker")
    func moatChainAddsMaybeLadder() {
        let (d, model) = makeDispatcher(tab: 3, col: 2, row: 2)
        let sel = roomSel(RoomType.circleMoat.hotKeyName)
        for _ in 0..<3 { d.performDungeonRoom(sel) }
        #expect(model.dungeonBlockers.dungeonBlocker(dungeon: 3, slot: 0) == .maybeLadder)
        #expect(model.dungeonRoomMaps[3].room(col: 2, row: 2).roomType == .circleMoat)
    }

    @Test("Gohma/Digdogger/Dodongo chains map to their blockers")
    func monsterChainsMapToBlockers() {
        for (monster, blocker) in [(MonsterDetail.bow, DungeonBlocker.maybeBowAndArrow),
                                   (.digdogger, .maybeRecorder),
                                   (.dodongo, .maybeBomb)] {
            let (d, model) = makeDispatcher(tab: 5, col: 1, row: 1)
            let sel = roomSel(monster.hotKeyName)
            for _ in 0..<3 { d.performDungeonRoom(sel) }
            #expect(model.dungeonBlockers.dungeonBlocker(dungeon: 5, slot: 0) == blocker,
                    "\(monster) should map to \(blocker)")
        }
    }

    @Test("the chain is scoped by tab — the same room in another dungeon doesn't fire")
    func chainScopedByTab() {
        let model = TrackerModel(quest: .first)
        let focus = TrackerFocusState()
        focus.cursorRegion = .dungeonMap
        focus.dungeonCursor = .init(col: 2, row: 2)
        focus.cursorShown = true
        let d = GlobalHotkeyDispatcher(model: model, options: TrackerOptions(),
                                       timer: TrackerTimer(), hotkeys: HotkeyConfig(), focus: focus)
        let sel = "DungeonRoom_" + FloorDropDetail.triforce.hotKeyName
        focus.selectedDungeonTab = 3
        d.performDungeonRoom(sel)      // mark on dungeon 3
        d.performDungeonRoom(sel)      // unmark on dungeon 3 (justUnmarked = tab 3)
        focus.selectedDungeonTab = 4   // switch dungeons, same room coord
        d.performDungeonRoom(sel)      // mark on dungeon 4 — must NOT fire dungeon 4's triforce
        #expect(model.dungeonTracker.dungeon(4).playerHasTriforce == false)
    }

    @Test("OtherKeyItem chain parks the dungeon-item cursor on this dungeon's box")
    func otherKeyItemParksCursor() {
        let model = TrackerModel(quest: .first)
        let focus = TrackerFocusState()
        focus.selectedDungeonTab = 6
        focus.cursorRegion = .dungeonMap
        focus.dungeonCursor = .init(col: 3, row: 3)
        focus.cursorShown = true
        let d = GlobalHotkeyDispatcher(model: model, options: TrackerOptions(),
                                       timer: TrackerTimer(), hotkeys: HotkeyConfig(), focus: focus)
        let sel = "DungeonRoom_" + FloorDropDetail.otherKeyItem.hotKeyName
        for _ in 0..<3 { d.performDungeonRoom(sel) }
        #expect(focus.cursorRegion == .dungeonItem)
        #expect(focus.dungeonItemCursor.col == 6)      // this dungeon
    }
}

/// T-169 — the remaining repeat-press smarts that live in the dispatcher: blocker
/// repeat-unmark and the overworld brightness (dark) toggle.
@Suite("Dispatcher repeat smarts (T-169)")
@MainActor
struct DispatcherRepeatSmartsTests {

    private func dispatcher(_ model: TrackerModel, _ focus: TrackerFocusState) -> GlobalHotkeyDispatcher {
        GlobalHotkeyDispatcher(model: model, options: TrackerOptions(), timer: TrackerTimer(),
                               hotkeys: HotkeyConfig(), focus: focus)
    }

    @Test("a repeat blocker key toggles the box back to empty")
    func blockerRepeatUnmarks() {
        let model = TrackerModel(quest: .first)
        let focus = TrackerFocusState()
        focus.cursorRegion = .blockers
        focus.blockersCursor = BlockerRegion.cell(dungeon: 2, slot: 0)
        focus.cursorShown = true
        let d = dispatcher(model, focus)
        let sel = DungeonBlocker.ladder.asHotKeyName
        d.performBlockers(sel)
        #expect(model.dungeonBlockers.dungeonBlocker(dungeon: 2, slot: 0) == .ladder)
        d.performBlockers(sel)   // repeat → empty
        #expect(model.dungeonBlockers.dungeonBlocker(dungeon: 2, slot: 0) == .nothing)
    }

    @Test("a repeat overworld key on a brightness-toggleable mark flips its dark state")
    func overworldBrightnessToggles() {
        let model = TrackerModel(quest: .first)
        model.selectQuest(.first)
        let focus = TrackerFocusState()
        focus.cursorRegion = .overworld
        // A markable, brightness-toggleable tile: pick a non-dead spot and use a take-any.
        var placed: (Int, Int)?
        outer: for y in 0..<OverworldGrid.rowCount {
            for x in 0..<OverworldGrid.columnCount where !model.isDeadSpot(x: x, y: y) {
                placed = (x, y); break outer
            }
        }
        let (x, y) = placed!
        focus.overworldCursor = .init(col: x, row: y)
        focus.cursorShown = true
        let d = dispatcher(model, focus)
        let sel = "Overworld_TakeAny"                       // .takeAny is brightness-toggleable
        d.performOverworld(sel)                             // place take-any
        #expect(model.overworldGrid.mark(column: x, row: y) == .takeAny)
        let used0 = model.overworldGrid.isUsed(column: x, row: y)
        d.performOverworld(sel)                             // repeat → toggle dark
        #expect(model.overworldGrid.isUsed(column: x, row: y) != used0)
    }
}
