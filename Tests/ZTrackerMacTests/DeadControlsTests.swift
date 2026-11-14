import Testing
import Foundation
import TrackerCore
@testable import ZTrackerMac

/// T-249 — the hotkeys that used to do nothing: door +/−, Take-Any / Take-This, the click /
/// scroll keys, and the item hotkeys' reachability gate.
@Suite("Dead hotkeys wired (T-249)")
@MainActor
struct DeadControlsTests {

    private func dispatcher(_ region: TrackerFocusState.CursorRegion, col: Int = 0, row: Int = 0,
                            hotkeys: HotkeyConfig = HotkeyConfig())
        -> (GlobalHotkeyDispatcher, TrackerModel, TrackerFocusState) {
        let model = TrackerModel(quest: .first)
        let focus = TrackerFocusState()
        focus.cursorRegion = region
        focus.cursorShown = true
        switch region {
        case .overworld: focus.overworldCursor = .init(col: col, row: row)
        case .dungeonMap: focus.dungeonCursor = .init(col: col, row: row)
        case .items: focus.itemsCursor = .init(col: col, row: row)
        case .dungeonItem: focus.dungeonItemCursor = .init(col: col, row: row)
        default: break
        }
        let d = GlobalHotkeyDispatcher(model: model, options: TrackerOptions(), timer: TrackerTimer(),
                                       hotkeys: hotkeys, focus: focus)
        return (d, model, focus)
    }

    // MARK: Doors

    @Test("door keys step the wall on that side; the outer wall has no door")
    func doorNudges() {
        let map = DungeonRoomMap()
        #expect(DungeonRoomMark.nudgeDoor(.east, increment: true, col: 2, row: 3, map: map))
        #expect(map.door(.horizontal, col: 2, row: 3) == DoorState.unknown.next)
        #expect(DungeonRoomMark.nudgeDoor(.east, increment: false, col: 2, row: 3, map: map))
        #expect(map.door(.horizontal, col: 2, row: 3) == .unknown)
        #expect(DungeonRoomMark.nudgeDoor(.west, increment: true, col: 3, row: 3, map: map))
        #expect(map.door(.horizontal, col: 2, row: 3) == DoorState.unknown.next)   // same wall
        #expect(DungeonRoomMark.nudgeDoor(.north, increment: true, col: 1, row: 1, map: map))
        #expect(map.door(.vertical, col: 1, row: 0) == DoorState.unknown.next)
        #expect(!DungeonRoomMark.nudgeDoor(.west, increment: true, col: 0, row: 0, map: map))
        #expect(!DungeonRoomMark.nudgeDoor(.north, increment: true, col: 0, row: 0, map: map))
        #expect(!DungeonRoomMark.nudgeDoor(.east, increment: true, col: DungeonRoomMap.cols - 1, row: 0, map: map))
        #expect(!DungeonRoomMark.nudgeDoor(.south, increment: true, col: 0, row: DungeonRoomMap.rows - 1, map: map))
        #expect(map.firstInteractionDone)
    }

    @Test("door hotkeys reach the cursor room through the dispatcher")
    func doorHotkeyDispatch() {
        #expect(GlobalHotkeyDispatcher.doorNudge(for: "DungeonRoom_SouthDoorIncrement")?.side == .south)
        #expect(GlobalHotkeyDispatcher.doorNudge(for: "DungeonRoom_WestDoorDecrement")?.increment == false)
        #expect(GlobalHotkeyDispatcher.doorNudge(for: "DungeonRoom_RoomType_Unmarked") == nil)
        let (d, model, focus) = dispatcher(.dungeonMap, col: 4, row: 4)
        focus.selectedDungeonTab = 2
        #expect(d.performDungeonRoom("DungeonRoom_SouthDoorIncrement"))
        #expect(model.dungeonRoomMaps[2].door(.vertical, col: 4, row: 4) == DoorState.unknown.next)
    }

    // MARK: Take-Any / Take-This

    @Test("placing a take-any by hotkey arms the choice keys; a choice claims the slot")
    func takeAnyChoice() throws {
        let hk = HotkeyConfig()
        hk.loadDefaults()
        let (d, model, focus) = dispatcher(.overworld, hotkeys: hk)
        let cell = try #require(liveCell(model))
        focus.overworldCursor = .init(col: cell.0, row: cell.1)
        d.performOverworld("Overworld_TakeAny")
        #expect(d.pendingContextual?.kind == .takeAny)
        let heart = try #require(hk.chord(for: "Contextual_TakeAny_Heart"))
        #expect(d.takeContextual(heart))
        let slot = try #require(model.overworldGrid.takeAnySlot(column: cell.0, row: cell.1))
        #expect(model.playerProgress.takeAnyHearts[slot] == .takenHeart)
        #expect(d.pendingContextual == nil)
    }

    @Test("a wood-sword cave's Take-This sword key grants the sword; other keys just dismiss")
    func takeThisChoice() throws {
        let hk = HotkeyConfig()
        hk.loadDefaults()
        let (d, model, focus) = dispatcher(.overworld, hotkeys: hk)
        let cell = try #require(liveCell(model))
        focus.overworldCursor = .init(col: cell.0, row: cell.1)
        d.performOverworld("Overworld_Sword1")
        #expect(d.pendingContextual?.kind == .takeThis)
        #expect(!d.takeContextual(HotkeyChord(key: "q")))      // not a choice → dismissed
        #expect(d.pendingContextual == nil)
        d.armContextual(.takeThis, col: cell.0, row: cell.1)
        #expect(d.takeContextual(try #require(hk.chord(for: "Contextual_TakeThis_Sword"))))
        #expect(model.playerProgress.hasWoodSword)
        #expect(model.overworldGrid.isUsed(column: cell.0, row: cell.1))
    }

    @Test("a stale choice (after the window) is ignored")
    func contextualExpires() throws {
        let hk = HotkeyConfig()
        hk.loadDefaults()
        let (d, model, _) = dispatcher(.overworld, hotkeys: hk)
        let cell = try #require(liveCell(model))
        let t0 = Date(timeIntervalSince1970: 1_000)
        d.armContextual(.takeAny, col: cell.0, row: cell.1, now: t0)
        let heart = try #require(hk.chord(for: "Contextual_TakeAny_Heart"))
        #expect(!d.takeContextual(heart, now: t0.addingTimeInterval(GlobalHotkeyDispatcher.contextualWindow + 1)))
    }

    @Test("with no choice keys bound, nothing is armed")
    func noBindingsNoArm() throws {
        let (d, model, _) = dispatcher(.overworld)
        let cell = try #require(liveCell(model))
        d.armContextual(.takeAny, col: cell.0, row: cell.1)
        #expect(d.pendingContextual == nil)
    }

    @Test("repeating the take-any key cycles its slot instead of a bare used-toggle")
    func takeAnyRepeatCycles() throws {
        let (d, model, focus) = dispatcher(.overworld)
        let cell = try #require(liveCell(model))
        focus.overworldCursor = .init(col: cell.0, row: cell.1)
        d.performOverworld("Overworld_TakeAny")
        d.performOverworld("Overworld_TakeAny")
        let slot = try #require(model.overworldGrid.takeAnySlot(column: cell.0, row: cell.1))
        #expect(model.playerProgress.takeAnyHearts[slot] == .takenHeart)
    }

    // MARK: Click / scroll keys

    @Test("on the overworld and dungeon map, a click key becomes a request for that grid view")
    func clickRequests() {
        let (d, _, focus) = dispatcher(.dungeonMap, col: 3, row: 5)
        #expect(d.performClick(.scrollDown))
        let req = focus.clickRequest
        #expect(req?.kind == .scrollDown && req?.region == .dungeonMap && req?.cell == .init(col: 3, row: 5))
        // Taken once (a mirror window finds nothing left), and only by its own region.
        #expect(focus.takeClickRequest(req!.id, in: .overworld) == nil)
        #expect(focus.takeClickRequest(req!.id, in: .dungeonMap) != nil)
        #expect(focus.takeClickRequest(req!.id, in: .dungeonMap) == nil)
    }

    @Test("an Items left-click toggles; right-click clears; the magical sword stays gated")
    func itemClicks() {
        let (d, model, focus) = dispatcher(.items, col: 3, row: 0)     // wood sword
        #expect(d.performClick(.left))
        #expect(model.playerProgress.hasWoodSword)
        #expect(d.performClick(.right))
        #expect(!model.playerProgress.hasWoodSword)
        #expect(!d.performClick(.right))                                 // already off
        focus.itemsCursor = .init(col: 2, row: 0)                       // magical sword, 3 hearts
        #expect(!d.performClick(.left))
        #expect(!model.playerProgress.hasMagicalSword)
        focus.itemsCursor = .init(col: 0, row: 3)                       // take-any slot 1
        #expect(d.performClick(.left))
        #expect(model.playerProgress.takeAnyHearts[0] == .takenHeart)
    }

    @Test("no active region → the click key isn't consumed")
    func clickWithoutRegion() {
        let (d, _, focus) = dispatcher(.overworld)
        focus.cursorShown = false
        #expect(!d.performClick(.left))
    }

    // MARK: Item hotkeys' gate

    @Test("an item hotkey on the white-sword box below the heart minimum marks it untaken")
    func itemHotkeyHonorsGate() {
        let (d, model, focus) = dispatcher(.items, col: 1, row: 0)     // white-sword item box
        #expect(d.performItems("Item_Raft"))
        let ws = ItemProgressGrid.CoastBox.whiteSword.box(in: model.dungeonTracker)
        #expect(ws.cellCurrent == ITEMS.raft && ws.playerHas == .no)
        focus.itemsCursor = .init(col: 1, row: 2)                       // armos: ungated
        #expect(d.performItems("Item_Bow"))
        let armos = ItemProgressGrid.CoastBox.armos.box(in: model.dungeonTracker)
        #expect(armos.cellCurrent == ITEMS.bow && armos.playerHas == .yes)
    }

    /// A first-quest overworld screen that can hold a mark.
    private func liveCell(_ model: TrackerModel) -> (Int, Int)? {
        for r in 0..<OverworldGrid.rowCount {
            for c in 0..<OverworldGrid.columnCount where !model.isDeadSpot(x: c, y: r) {
                return (c, r)
            }
        }
        return nil
    }
}
