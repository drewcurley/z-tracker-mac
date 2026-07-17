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
    private let timer: TrackerTimer
    private let hotkeys: HotkeyConfig
    private let focus: TrackerFocusState
    private var monitor: Any?

    init(model: TrackerModel, timer: TrackerTimer, hotkeys: HotkeyConfig, focus: TrackerFocusState) {
        self.model = model
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
        guard let chord = HotkeyChord(nsEvent: event),
              let selectorID = hotkeys.selectorID(boundTo: chord, in: .global) else { return false }
        return perform(selectorID)
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
        default:
            // Cursor / click / scroll globals are later phases — a recognized-but-
            // unimplemented Global key is left for the app (not consumed).
            return false
        }
        return true
    }
}
