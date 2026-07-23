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
    private let voice: VoiceController?
    private var monitor: Any?

    init(model: TrackerModel, options: TrackerOptions, timer: TrackerTimer,
         hotkeys: HotkeyConfig, focus: TrackerFocusState, voice: VoiceController? = nil) {
        self.model = model
        self.options = options
        self.timer = timer
        self.hotkeys = hotkeys
        self.focus = focus
        self.voice = voice
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
        // The one exception is being parked on Notes: there, only cursor navigation
        // keeps firing, so an ordinary letter starts a note instead of marking.
        if let selectorID = hotkeys.selectorID(boundTo: chord, in: .global) {
            if !focus.notesParked || Self.isNavigation(selectorID) {
                return perform(selectorID)
            }
        }
        // Parked on Notes: the first alphanumeric starts typing. The field isn't first
        // responder yet, so this keystroke would be dropped by the focus change —
        // append it here and it appears exactly as typed.
        if focus.notesParked, let typed = Self.typedAlphanumeric(event) {
            focus.setNotesFocus(true)
            model.notes.append(typed)
            return true
        }
        // Hint zones aren't a grid region — a hovered hint box claims the key first
        // (T-168), so `HintZone_*` can reuse letters bound in the grid contexts.
        if let target = focus.hoveredHintTarget,
           let selectorID = hotkeys.selectorID(boundTo: chord, in: .hintZones) {
            return performHintZone(selectorID, target: target)
        }
        // Region keys act on whatever the mouse is over, falling back to the keyboard
        // cursor's region (T-168 — see `TrackerFocusState.activeRegion`).
        guard let region = focus.activeRegion else { return false }
        switch region {
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
        case .dungeonItem:
            if let selectorID = hotkeys.selectorID(boundTo: chord, in: .items) {
                return performDungeonItem(selectorID)
            }
        case .notes:
            // Notes has no marks. In practice the field is the first responder here,
            // so this handler already stood down above; if focus was lost some other
            // way, region keys simply don't apply.
            break
        }
        return false
    }

    /// Cursor-navigation globals, which stay live even while parked on Notes so you
    /// can always move on without reaching for the mouse.
    static func isNavigation(_ selectorID: String) -> Bool {
        selectorID.hasPrefix("Global_MoveCursor") || selectorID.hasPrefix("Global_CycleRegion")
    }

    /// The character this event types, if it's a plain alphanumeric — Shift is allowed
    /// (it just picks the capital); ⌘/⌃/⌥ are not, since those are shortcuts, not text.
    static func typedAlphanumeric(_ event: NSEvent) -> String? {
        let flags = event.modifierFlags.intersection(.deviceIndependentFlagsMask)
        guard flags.subtracting(.shift).isEmpty else { return nil }
        guard let characters = event.characters, characters.count == 1,
              let scalar = characters.unicodeScalars.first,
              CharacterSet.alphanumerics.contains(scalar)
        else { return nil }
        return characters
    }

    /// Set the hovered hint box's zone (T-168), the same as picking it in the popover.
    private func performHintZone(_ selectorID: String, target: Int) -> Bool {
        let prefix = "HintZone_"
        guard selectorID.hasPrefix(prefix),
              let zone = HintZone.fromHotKeyName(String(selectorID.dropFirst(prefix.count)))
        else { return false }
        model.levelHints[target] = zone
        return true
    }

    /// Apply an `Item_*` mark to the dungeon item box under the cursor (T-168):
    /// `col` is the dungeon 0…8, `row` the box index 0…2 — the same axes as the
    /// on-screen layout. A two-boxer dungeon's third cell has no box, so the key is
    /// consumed but does nothing.
    private func performDungeonItem(_ selectorID: String) -> Bool {
        let prefix = "Item_"
        guard selectorID.hasPrefix(prefix),
              let index = ItemBoxMark.itemIndex(forHotkeySuffix: String(selectorID.dropFirst(prefix.count)))
        else { return false }
        let cell = focus.dungeonItemCursor
        guard (0..<9).contains(cell.col) else { return true }
        let dungeon = model.dungeonTracker.dungeon(cell.col)
        guard cell.row >= 0, cell.row < dungeon.boxes.count else { return true }
        ItemBoxMark.apply(itemIndex: index, to: dungeon.boxes[cell.row],
                          instance: model.dungeonTracker)
        return true
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
        // Don't mark a border screen that never holds anything (vanilla map only —
        // a custom map has no dead spots, T-167).
        guard !model.isDeadSpot(x: cell.col, y: cell.row) else { return true }
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
        case "Global_ToggleVoice": voice?.toggle()   // T-137 (unbound by default)
        default:
            // Click / scroll globals + hover-region marks are phase 2b — a
            // recognized-but-unimplemented Global key is left for the app.
            return false
        }
        return true
    }
}
