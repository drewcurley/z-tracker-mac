import AppKit
import SwiftUI
import TrackerCore

/// Runtime dispatch for **Global** hotkeys (Part B, phase 1 — T-132). A local
/// key-down monitor, active while the main tracker window is key, resolves the
/// pressed chord against the Global bindings and performs the action. Region
/// (hover) contexts and the cursor subsystem come in later phases.
///
/// Only fires for the **main window** (`"Z-Tracker"`) and never while a text field
/// is being edited (so Notes / the editor filter type normally). Global keys that
/// belong to the not-yet-built cursor subsystem (`MoveCursor*`, clicks, scroll) are
/// recognized but no-op for now.
@MainActor
final class GlobalHotkeyDispatcher {
    private let model: TrackerModel
    private let options: TrackerOptions
    private let timer: TrackerTimer
    private let hotkeys: HotkeyConfig
    private let focus: TrackerFocusState
    private var monitor: Any?

    init(model: TrackerModel, options: TrackerOptions, timer: TrackerTimer,
         hotkeys: HotkeyConfig, focus: TrackerFocusState) {
        self.model = model
        self.options = options
        self.timer = timer
        self.hotkeys = hotkeys
        self.focus = focus
    }

    func install() {
        guard monitor == nil else { return }
        monitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            self?.handle(event) == true ? nil : event
        }
    }

    func uninstall() {
        if let m = monitor { NSEvent.removeMonitor(m); monitor = nil }
    }

    /// Returns `true` if the event was a bound Global hotkey and was performed
    /// (and should be consumed).
    private func handle(_ event: NSEvent) -> Bool {
        // Only the main tracker window, and not while editing text.
        guard event.window?.title == "Z-Tracker" else { return false }
        let responder = event.window?.firstResponder
        if responder is NSTextView || responder is NSText { return false }
        guard let chord = HotkeyChord(nsEvent: event) else { return false }
        // Global keys are always live (a chord can't be bound both global and in a
        // region — their conflict scopes intersect, so this ordering is unambiguous).
        if let selectorID = hotkeys.selectorID(boundTo: chord, in: .global) {
            return perform(selectorID)
        }
        // Region keys act on the keyboard cursor's cell when it's on that region
        // (T-134/T-135).
        guard focus.cursorShown else { return false }
        switch focus.cursorRegion {
        case .overworld:
            if let selectorID = hotkeys.selectorID(boundTo: chord, in: .overworld) {
                return performOverworld(selectorID)
            }
        case .dungeonMap:
            if let selectorID = hotkeys.selectorID(boundTo: chord, in: .dungeonRoom) {
                return performDungeonRoom(selectorID)
            }
        case .items:
            if let selectorID = hotkeys.selectorID(boundTo: chord, in: .items) {
                return performItems(selectorID)
            }
        case .blockers:
            if let selectorID = hotkeys.selectorID(boundTo: chord, in: .blockers) {
                return performBlockers(selectorID)
            }
        default:
            break   // dungeon-item cursor nav not built yet
        }
        return false
    }

    /// Set the blocker at the cursor's (dungeon, slot) to the selector's kind (T-135),
    /// the same as its picker.
    private func performBlockers(_ selectorID: String) -> Bool {
        let t = BlockerRegion.target(focus.blockersCursor)
        model.dungeonBlockers.setDungeonBlocker(DungeonBlocker.fromHotKeyName(selectorID),
                                                dungeon: t.dungeon, slot: t.slot)
        return true
    }

    /// Apply an `Item_*` mark to the item box under the cursor (T-135). Only the
    /// grid's assignable picker-boxes (white-sword / coast / armos item) respond;
    /// the fixed toggle boxes have their own Global hotkeys, so the key is consumed
    /// there but does nothing on a non-box cell.
    private func performItems(_ selectorID: String) -> Bool {
        let prefix = "Item_"
        guard selectorID.hasPrefix(prefix),
              let index = ItemBoxMark.itemIndex(forHotkeySuffix: String(selectorID.dropFirst(prefix.count)))
        else { return false }
        let cell = focus.itemsCursor
        guard (0..<ItemProgressGrid.rows).contains(cell.row),
              (0..<ItemProgressGrid.columns).contains(cell.col),
              case .pickerBox(let coast) = ItemProgressGrid.layout[cell.row][cell.col]
        else { return true }   // consumed, but not a box cell
        ItemBoxMark.apply(itemIndex: index, to: coast.box(in: model.dungeonTracker),
                          instance: model.dungeonTracker)
        return true
    }

    /// Apply a `DungeonRoom_*` mark to the dungeon-map cursor room (T-135), the same
    /// way its picker would. No-op on the Summary tab (no room map).
    private func performDungeonRoom(_ selectorID: String) -> Bool {
        let tab = focus.selectedDungeonTab
        guard (0..<model.dungeonRoomMaps.count).contains(tab) else { return false }
        let cell = focus.dungeonCursor
        return DungeonRoomMark.applyHotkey(selectorID, col: cell.col, row: cell.row,
                                           map: model.dungeonRoomMaps[tab],
                                           inferDoors: options.doDoorInference)
    }

    /// Apply an `Overworld_*` mark to the overworld cursor cell (T-134), the same
    /// way a mouse click on the tile picker would.
    private func performOverworld(_ selectorID: String) -> Bool {
        let prefix = "Overworld_"
        guard selectorID.hasPrefix(prefix),
              let mark = OverworldTileMark.fromHotkeySuffix(String(selectorID.dropFirst(prefix.count)))
        else { return false }
        let cell = focus.overworldCursor
        // Don't mark a border screen that never holds anything.
        let instance = OverworldInstance(quest: model.quest ?? .first)
        guard !instance.alwaysEmpty(x: cell.col, y: cell.row) else { return true }
        OverworldMark.apply(mark, column: cell.col, row: cell.row, grid: model.overworldGrid,
                            releaseTakeAny: { c, r in model.releaseOverworldTakeAny(column: c, row: r) },
                            placeDungeon: { number, c, r in
                                model.levelHints[HintTarget.dungeon(number)] =
                                    HintZone.forZoneChar(OverworldZones.zone(column: c, row: r))
                            })
        return true
    }

    /// Perform a Global selector's action. Returns `true` if handled (consumed).
    private func perform(_ selectorID: String) -> Bool {
        let progress = model.playerProgress
        switch selectorID {
        case "Global_ToggleMagicalSword": progress.hasMagicalSword.toggle()
        case "Global_ToggleWoodSword":    progress.hasWoodSword.toggle()
        case "Global_ToggleBoomBook":     progress.hasBoomBook.toggle()
        case "Global_ToggleBlueCandle":   progress.hasBlueCandle.toggle()
        case "Global_ToggleWoodArrow":    progress.hasWoodArrow.toggle()
        case "Global_ToggleBlueRing":     progress.hasBlueRing.toggle()
        case "Global_ToggleBombs":        progress.hasBombs.toggle()
        case "Global_ToggleGannon":       progress.hasDefeatedGanon.toggle()
        case "Global_ToggleZelda":        progress.hasRescuedZelda.toggle()
        case "Global_StartTimer":         timer.start()
        case "Global_GroundhogReset":
            // Match the "Reset (keep maps)" button exactly, minus its confirm dialog:
            // reset the inventory *and* restart the lap timer (T-132.1).
            model.resetForGroundhogOrRouters()
            timer.startLap()
        // Dungeon-tab switching (T-133): 1–9 → tabs 0–8, S → Summary (9).
        case "Global_DungeonTab1": focus.selectedDungeonTab = 0
        case "Global_DungeonTab2": focus.selectedDungeonTab = 1
        case "Global_DungeonTab3": focus.selectedDungeonTab = 2
        case "Global_DungeonTab4": focus.selectedDungeonTab = 3
        case "Global_DungeonTab5": focus.selectedDungeonTab = 4
        case "Global_DungeonTab6": focus.selectedDungeonTab = 5
        case "Global_DungeonTab7": focus.selectedDungeonTab = 6
        case "Global_DungeonTab8": focus.selectedDungeonTab = 7
        case "Global_DungeonTab9": focus.selectedDungeonTab = 8
        case "Global_DungeonTabS": focus.selectedDungeonTab = 9
        // Keyboard cursor movement (T-134) + region cycle (T-135).
        case "Global_MoveCursorLeft":  focus.moveCursor(dcol: -1, drow: 0)
        case "Global_MoveCursorRight": focus.moveCursor(dcol: 1, drow: 0)
        case "Global_MoveCursorUp":    focus.moveCursor(dcol: 0, drow: -1)
        case "Global_MoveCursorDown":  focus.moveCursor(dcol: 0, drow: 1)
        case "Global_CycleRegionForward":  focus.cycleRegion(forward: true)
        case "Global_CycleRegionBackward": focus.cycleRegion(forward: false)
        // Whistle destination stepper (T-135): same as the ◀ ▶ arrows by the recorder.
        case "Global_RecorderDestPrev": model.recorderDestinationManual = true; model.recorderDestinationIndex -= 1
        case "Global_RecorderDestNext": model.recorderDestinationManual = true; model.recorderDestinationIndex += 1
        default:
            // Click / scroll globals + hover-region marks are phase 2b — a
            // recognized-but-unimplemented Global key is left for the app.
            return false
        }
        return true
    }
}
