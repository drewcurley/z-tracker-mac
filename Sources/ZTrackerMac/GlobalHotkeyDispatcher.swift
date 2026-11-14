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

    /// The last dungeon-room key that *unmarked* a room (T-169) — its tab, cell, and
    /// selector. Re-marking that same room with that same key is the "Unmark–Remark"
    /// interaction (`whats-new.md` v1.3) that fires a linked action. Scoped by tab so
    /// the same room coordinate in a different dungeon can't false-fire.
    private var justUnmarked: (tab: Int, col: Int, row: Int, selector: String)?

    /// After a take-any or wood-sword cave is placed by hotkey, the next key may say what was
    /// taken there — the reference's pie-menu keys (`Contextual_TakeAny_*` / `_TakeThis_*`,
    /// `PieMenus.fs:119-129`). Any other key, or the window passing, dismisses it (T-249).
    struct PendingContextual {
        enum Kind { case takeAny, takeThis }
        let kind: Kind
        let col: Int
        let row: Int
        let armedAt: Date
    }
    private(set) var pendingContextual: PendingContextual?
    private var contextualToast: UUID?
    static let contextualWindow: TimeInterval = 8

    /// Shows the groundhog reset's Undo toast (T-246).
    private let reminders: ReminderController?
    private let groundhog: GroundhogReset

    init(model: TrackerModel, options: TrackerOptions, timer: TrackerTimer,
         hotkeys: HotkeyConfig, focus: TrackerFocusState, voice: VoiceController? = nil,
         reminders: ReminderController? = nil, groundhog: GroundhogReset = GroundhogReset()) {
        self.model = model
        self.options = options
        self.timer = timer
        self.hotkeys = hotkeys
        self.focus = focus
        self.voice = voice
        self.reminders = reminders
        self.groundhog = groundhog
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
        if pendingContextual != nil, takeContextual(chord) {
            ConfirmationSound.input(options)
            return true
        }
        // Global keys are always live (a chord can't be bound both global and in a
        // region — their conflict scopes intersect, so this ordering is unambiguous).
        // The one exception is being parked on Notes: there, only cursor navigation
        // keeps firing, so an ordinary letter starts a note instead of marking.
        if let selectorID = hotkeys.selectorID(boundTo: chord, in: .global) {
            if !focus.notesParked || Self.isNavigation(selectorID) {
                let ok = perform(selectorID)
                // Tick on a performed *edit* — not pure cursor navigation (T-208).
                if ok, !Self.isNavigation(selectorID) { ConfirmationSound.input(options) }
                return ok
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
            return ticked(performHintZone(selectorID, target: target))
        }
        // Region keys act on whatever the mouse is over, falling back to the keyboard
        // cursor's region (T-168 — see `TrackerFocusState.activeRegion`).
        guard let region = focus.activeRegion else { return false }
        switch region {
        case .overworld:
            if let selectorID = hotkeys.selectorID(boundTo: chord, in: .overworld) {
                return ticked(performOverworld(selectorID))
            }
        case .dungeonMap:
            if let selectorID = hotkeys.selectorID(boundTo: chord, in: .dungeonRoom) {
                return ticked(performDungeonRoom(selectorID))
            }
        case .items:
            if let selectorID = hotkeys.selectorID(boundTo: chord, in: .items) {
                return ticked(performItems(selectorID))
            }
        case .blockers:
            if let selectorID = hotkeys.selectorID(boundTo: chord, in: .blockers) {
                return ticked(performBlockers(selectorID))
            }
        case .dungeonItem:
            if let selectorID = hotkeys.selectorID(boundTo: chord, in: .items) {
                return ticked(performDungeonItem(selectorID))
            }
        case .notes:
            // Notes has no marks. In practice the field is the first responder here,
            // so this handler already stood down above; if focus was lost some other
            // way, region keys simply don't apply.
            break
        }
        return false
    }

    /// Resolve a pending take-any / take-this choice with this key (T-249). Always disarms;
    /// returns whether the key was a matching choice (and so is consumed).
    @discardableResult
    func takeContextual(_ chord: HotkeyChord, now: Date = Date()) -> Bool {
        guard let pending = pendingContextual else { return false }
        pendingContextual = nil
        if let toast = contextualToast { reminders?.dismiss(toast); contextualToast = nil }
        guard now.timeIntervalSince(pending.armedAt) <= Self.contextualWindow,
              let id = hotkeys.selectorID(boundTo: chord, in: .contextual) else { return false }
        return performContextual(id, pending)
    }

    private func performContextual(_ id: String, _ p: PendingContextual) -> Bool {
        let grid = model.overworldGrid, progress = model.playerProgress
        switch (p.kind, id) {
        // "None" leaves the tile as placed (unclaimed / not collected), like the reference.
        case (.takeAny, "Contextual_TakeAny_None"), (.takeThis, "Contextual_TakeThis_None"):
            return true
        case (.takeAny, "Contextual_TakeAny_Potion"):
            model.setOverworldTakeAny(.takenPotion, column: p.col, row: p.row)
        case (.takeAny, "Contextual_TakeAny_Candle"):
            model.setOverworldTakeAny(.takenCandle, column: p.col, row: p.row)
        case (.takeAny, "Contextual_TakeAny_Heart"):
            model.setOverworldTakeAny(.takenHeart, column: p.col, row: p.row)
        case (.takeThis, "Contextual_TakeThis_Sword"):
            grid.setUsed(true, column: p.col, row: p.row)
            progress.hasWoodSword = true
        case (.takeThis, "Contextual_TakeThis_Candle"):
            grid.setUsed(true, column: p.col, row: p.row)
            progress.hasBlueCandle = true
        default:
            return false
        }
        return true
    }

    /// Arm the take-any / take-this keys for the tile just placed, showing the bound choices —
    /// the stand-in for the reference's pie menu. No keys bound → nothing to arm.
    func armContextual(_ kind: PendingContextual.Kind, col: Int, row: Int, now: Date = Date()) {
        let choices: [(id: String, name: String)] = kind == .takeAny
            ? [("TakeAny_None", "none"), ("TakeAny_Potion", "potion"),
               ("TakeAny_Candle", "candle"), ("TakeAny_Heart", "heart")]
            : [("TakeThis_None", "none"), ("TakeThis_Candle", "candle"), ("TakeThis_Sword", "sword")]
        let parts = choices.compactMap { c in
            hotkeys.chord(for: "Contextual_" + c.id).map { "\($0.displayName) \(c.name)" }
        }
        guard !parts.isEmpty else { return }
        pendingContextual = PendingContextual(kind: kind, col: col, row: row, armedAt: now)
        if let old = contextualToast { reminders?.dismiss(old) }
        contextualToast = reminders?.toast(
            (kind == .takeAny ? "Take Any: " : "Take This: ") + parts.joined(separator: " · "),
            duration: .seconds(Self.contextualWindow))
    }

    /// Play the mouse/keyboard confirmation tick (T-208) when a region hotkey performed an
    /// edit, then pass the result through so the monitor still consumes the key.
    private func ticked(_ performed: Bool) -> Bool {
        if performed { ConfirmationSound.input(options) }
        return performed
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
        ItemBoxMark.cycleHotkey(itemIndex: index, box: dungeon.boxes[cell.row],
                                instance: model.dungeonTracker)
        return true
    }

    /// Set the blocker at the cursor's (dungeon, slot) to the selector's kind (T-135).
    /// A **repeat** press of the kind already in that box toggles it back to empty
    /// (T-169, `extras.md` §hotkeys).
    @discardableResult
    func performBlockers(_ selectorID: String) -> Bool {
        let t = BlockerRegion.target(focus.blockersCursor)
        let kind = DungeonBlocker.fromHotKeyName(selectorID)
        let current = model.dungeonBlockers.dungeonBlocker(dungeon: t.dungeon, slot: t.slot)
        model.dungeonBlockers.setDungeonBlocker(current == kind ? .nothing : kind,
                                                dungeon: t.dungeon, slot: t.slot)
        return true
    }

    /// Apply an `Item_*` mark to the item box under the cursor (T-135). Only the
    /// grid's assignable picker-boxes (white-sword / coast / armos item) respond;
    /// the fixed toggle boxes have their own Global hotkeys, so the key is consumed
    /// there but does nothing on a non-box cell.
    @discardableResult
    func performItems(_ selectorID: String) -> Bool {
        let prefix = "Item_"
        guard selectorID.hasPrefix(prefix),
              let index = ItemBoxMark.itemIndex(forHotkeySuffix: String(selectorID.dropFirst(prefix.count)))
        else { return false }
        let cell = focus.itemsCursor
        guard (0..<ItemProgressGrid.rows).contains(cell.row),
              (0..<ItemProgressGrid.columns).contains(cell.col),
              case .pickerBox(let coast) = ItemProgressGrid.layout[cell.row][cell.col]
        else { return true }   // consumed, but not a box cell
        // Below the box's gate (coast without the ladder, white-sword item under the heart
        // minimum) a fresh mark lands untaken, the same as voice and the picker (T-249).
        let reachable = coast.defaultAcquired(model.playerComputedStateSummary)
        ItemBoxMark.cycleHotkey(itemIndex: index, box: coast.box(in: model.dungeonTracker),
                                instance: model.dungeonTracker, acquired: reachable ? .yes : .no)
        return true
    }

    /// One field a `DungeonRoom_*` hotkey targets, parsed once so the mark, the
    /// toggle-off check, and the Unmark–Remark behavior all agree.
    private enum RoomField {
        case roomType(RoomType), monster(MonsterDetail), floorDrop(FloorDropDetail)
    }

    /// A `DungeonRoom_{West|East|North|South}Door{Increment|Decrement}` key (T-249).
    static func doorNudge(for selectorID: String) -> (side: DungeonRoomMark.DoorSide, increment: Bool)? {
        guard let s = selectorID.hotkeySuffix("DungeonRoom_") else { return nil }
        for side in DungeonRoomMark.DoorSide.allCases {
            if s == side.hotkeyName + "DoorIncrement" { return (side, true) }
            if s == side.hotkeyName + "DoorDecrement" { return (side, false) }
        }
        return nil
    }

    private static func roomField(for selectorID: String) -> RoomField? {
        if let s = selectorID.hotkeySuffix("DungeonRoom_RoomType_") {
            return .roomType(RoomType.fromHotKeyName("RoomType_" + s))
        }
        if let s = selectorID.hotkeySuffix("DungeonRoom_MonsterDetail_") {
            return .monster(MonsterDetail.fromHotKeyName("MonsterDetail_" + s))
        }
        if let s = selectorID.hotkeySuffix("DungeonRoom_FloorDropDetail_") {
            return .floorDrop(FloorDropDetail.fromHotKeyName("FloorDropDetail_" + s))
        }
        return nil
    }

    /// Apply a `DungeonRoom_*` mark to the dungeon-map cursor room (T-135). A repeat
    /// press toggles the mark back off, and an "Unmark → Remark" of the same room with
    /// the same key fires that key's linked action (T-169). No-op on the Summary tab.
    /// Internal (not private) so the Unmark–Remark state machine can be driven directly
    /// in tests without synthesizing key events.
    @discardableResult
    func performDungeonRoom(_ selectorID: String) -> Bool {
        let tab = focus.selectedDungeonTab
        guard (0..<model.dungeonRoomMaps.count).contains(tab) else { return false }
        if let nudge = Self.doorNudge(for: selectorID) {
            justUnmarked = nil
            return DungeonRoomMark.nudgeDoor(nudge.side, increment: nudge.increment,
                                             col: focus.dungeonCursor.col, row: focus.dungeonCursor.row,
                                             map: model.dungeonRoomMaps[tab])
        }
        guard let field = Self.roomField(for: selectorID) else { return false }
        let map = model.dungeonRoomMaps[tab]
        let cell = focus.dungeonCursor
        let (col, row) = (cell.col, cell.row)

        // Was this key's value already on the room? If so this press *unmarks* it;
        // otherwise it *sets* it (and may complete an Unmark→Remark).
        let wasPresent: Bool
        switch field {
        case .roomType(let t):  wasPresent = map.room(col: col, row: row).roomType == t
        case .monster(let m):   wasPresent = map.room(col: col, row: row).monsters.contains(m)
        case .floorDrop(let d): wasPresent = map.room(col: col, row: row).floorDropDetail == d
        }

        if wasPresent {
            unmarkRoomField(field, col: col, row: row, map: map)
            justUnmarked = (tab, col, row, selectorID)
        } else {
            setRoomField(field, col: col, row: row, map: map)
            if let ju = justUnmarked, ju.tab == tab, ju.col == col, ju.row == row,
               ju.selector == selectorID {
                runUnmarkRemark(field, tab: tab)     // reference leaves justUnmarked set,
            } else {                                  // so `ttttt` fires on the 3rd and 5th
                justUnmarked = nil                    // press
            }
        }
        return true
    }

    private func setRoomField(_ field: RoomField, col: Int, row: Int, map: DungeonRoomMap) {
        switch field {
        case .roomType(let t):
            DungeonRoomMark.applyRoomType(t, col: col, row: row, map: map,
                                          inferDoors: options.doDoorInference)
        case .monster(let m):
            DungeonRoomMark.toggleMonster(m, col: col, row: row, map: map)   // absent → adds
        case .floorDrop(let d):
            DungeonRoomMark.setFloorDrop(d, col: col, row: row, map: map)
        }
    }

    private func unmarkRoomField(_ field: RoomField, col: Int, row: Int, map: DungeonRoomMap) {
        switch field {
        case .roomType:
            DungeonRoomMark.applyRoomType(.unmarked, col: col, row: row, map: map, inferDoors: false)
        case .monster(let m):
            DungeonRoomMark.toggleMonster(m, col: col, row: row, map: map)   // present → removes
        case .floorDrop:
            DungeonRoomMark.setFloorDrop(.unmarked, col: col, row: row, map: map)
        }
    }

    /// The Unmark–Remark behavior table (T-169, `whats-new.md` v1.3, ported from
    /// `unmarkRemarkBehavior` in `DungeonUI.fs`). `tab` is the dungeon index.
    private func runUnmarkRemark(_ field: RoomField, tab: Int) {
        let dungeon = model.dungeonTracker.dungeon(tab)
        let playerState = model.playerComputedStateSummary
        switch field {
        // Moats drive maybe-Ladder; the meat block and life-or-money their own maybes.
        case .roomType(.chevy), .roomType(.circleMoat), .roomType(.doubleMoat),
             .roomType(.lavaMoat), .roomType(.rightMoat), .roomType(.topMoat):
            model.dungeonBlockers.applyMaybeBlockerLogic(.maybeLadder, dungeon: tab, playerState: playerState)
        case .roomType(.hungryGoriyaMeatBlock):
            model.dungeonBlockers.applyMaybeBlockerLogic(.maybeBait, dungeon: tab, playerState: playerState)
        case .roomType(.lifeOrMoney):
            model.dungeonBlockers.applyMaybeBlockerLogic(.maybeMoney, dungeon: tab, playerState: playerState)
        // The three "boss = blocker" monsters.
        case .monster(.bow):
            model.dungeonBlockers.applyMaybeBlockerLogic(.maybeBowAndArrow, dungeon: tab, playerState: playerState)
        case .monster(.digdogger):
            model.dungeonBlockers.applyMaybeBlockerLogic(.maybeRecorder, dungeon: tab, playerState: playerState)
        case .monster(.dodongo):
            model.dungeonBlockers.applyMaybeBlockerLogic(.maybeBomb, dungeon: tab, playerState: playerState)
        // Floor-drop toggles.
        case .floorDrop(.triforce):
            dungeon.toggleTriforce()
        case .floorDrop(.map):
            dungeon.playerHasMap.toggle()
        case .floorDrop(.heart):
            markFloorHeart(dungeon: dungeon)
        // "Activate a box" rows: we don't warp the mouse (T-168 descope), so instead
        // park the dungeon-item cursor on the target box, ready for an item hotkey.
        case .floorDrop(.otherKeyItem):
            parkDungeonItemCursor(dungeon: dungeon, tab: tab, basement: false)
        case .roomType(.itemBasement):
            parkDungeonItemCursor(dungeon: dungeon, tab: tab, basement: true)
        default:
            break
        }
    }

    /// FloorDrop.Heart remark: flip the first not-yet-taken floor Heart to taken, else
    /// fill the first empty non-basement box with a taken Heart Container.
    private func markFloorHeart(dungeon: Dungeon) {
        let boxes = dungeon.boxes
        if let box = boxes.first(where: {
            !model.dungeonTracker.currentlyHasBasementStair($0)
                && $0.cellCurrent == ITEMS.heartContainer && $0.playerHas == .no
        }) {
            box.setPlayerHas(.yes)
            return
        }
        if let box = boxes.first(where: {
            !model.dungeonTracker.currentlyHasBasementStair($0) && $0.cellCurrent == -1
        }), model.dungeonTracker.canSelectItem(ITEMS.heartContainer, forBox: box) {
            box.set(cellCurrent: ITEMS.heartContainer, playerHas: .yes)
        }
    }

    /// Park the dungeon-item cursor on the box an "activate box" remark targets: the
    /// bottommost empty basement box, or the topmost empty non-basement box (falling
    /// back to the bottom/top box). Switches the cursor into the dungeon-item region.
    private func parkDungeonItemCursor(dungeon: Dungeon, tab: Int, basement: Bool) {
        let boxes = dungeon.boxes
        guard !boxes.isEmpty else { return }
        let indices = Array(boxes.indices)
        let search = basement ? Array(indices.reversed()) : indices
        let target = search.first(where: { i in
            let box = boxes[i]
            let isBasement = model.dungeonTracker.currentlyHasBasementStair(box)
            return box.cellCurrent == -1 && isBasement == basement
        }) ?? search.first!
        focus.dungeonItemCursor = .init(col: tab, row: target)
        focus.cursorRegion = .dungeonItem
        focus.cursorShown = true
    }

    /// Apply an `Overworld_*` mark to the overworld cursor cell (T-134), with the
    /// T-169 repeat-press smarts: a shop key on a tile that's already a shop
    /// adds/removes/replaces items, and a repeat of a brightness-toggleable mark
    /// flips the tile's bright/dark (used) state.
    @discardableResult
    func performOverworld(_ selectorID: String) -> Bool {
        let prefix = "Overworld_"
        guard selectorID.hasPrefix(prefix),
              let mark = OverworldTileMark.fromHotkeySuffix(String(selectorID.dropFirst(prefix.count)))
        else { return false }
        let cell = focus.overworldCursor
        // Don't mark a border screen that never holds anything (vanilla map only —
        // a custom map has no dead spots, T-167).
        guard !model.isDeadSpot(x: cell.col, y: cell.row) else { return true }
        // Armos only on the five eligible screens (T-223) — a hotkey mustn't place it elsewhere.
        if mark == .armos, !model.canMarkArmos(column: cell.col, row: cell.row) { return true }
        // Shop add/remove/replace on an existing shop (T-169). Returns false on a
        // non-shop tile, so a fresh shop still places through `apply` below.
        if case .shop(let kind) = mark,
           OverworldMark.applyShopHotkeySmart(kind, column: cell.col, row: cell.row,
                                              grid: model.overworldGrid) {
            return true
        }
        // Brightness repeat (T-169): pressing the mark already on a bright/dark-
        // toggleable tile flips its used (dark) state instead of re-placing it.
        if model.overworldGrid.mark(column: cell.col, row: cell.row) == mark,
           mark.isUsedToggleable {
            // A take-any cycles its claimed slot and the wood-sword cave grants the sword,
            // exactly as a left-click does — a bare used-toggle left them out of sync (T-249).
            if mark == .takeAny {
                model.cycleOverworldTakeAny(column: cell.col, row: cell.row)
            } else {
                model.overworldGrid.toggleUsed(column: cell.col, row: cell.row)
                if case .swordCave(1) = mark {
                    model.playerProgress.hasWoodSword = model.overworldGrid.isUsed(column: cell.col, row: cell.row)
                }
            }
            return true
        }
        OverworldMark.apply(mark, column: cell.col, row: cell.row, grid: model.overworldGrid,
                            releaseTakeAny: { c, r in model.releaseOverworldTakeAny(column: c, row: r) },
                            placeDungeon: { number, c, r in
                                OverworldMark.didPlaceDungeon(number, column: c, row: r, model: model, focus: focus)
                            },
                            placeSwordCave: { level, c, r in
                                OverworldMark.didPlaceSwordCave(level, column: c, row: r, model: model)
                            })
        if mark == .takeAny { armContextual(.takeAny, col: cell.col, row: cell.row) }
        if case .swordCave(1) = mark { armContextual(.takeThis, col: cell.col, row: cell.row) }
        return true
    }

    /// Perform a Global selector's action. Returns `true` if handled (consumed).
    private func perform(_ selectorID: String) -> Bool {
        let progress = model.playerProgress
        switch selectorID {
        case "Global_ToggleMagicalSword":
            // Can't take it below the heart minimum (T-249), the same rule as the Items box;
            // turning it off is always allowed.
            guard progress.hasMagicalSword
                    || ItemAcquisitionGate.magicalSwordReachable(model.playerComputedStateSummary)
            else { return false }
            progress.hasMagicalSword.toggle()
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
            // Match the "Reset (keep maps)" button — reset the inventory *and* restart the lap
            // timer (T-132.1) — on a single press, without the dialog. A stray press (it
            // defaults to Shift+Space, next to Space = start timer) is one click to reverse:
            // the state is saved first and the toast offers Undo (T-246).
            groundhog.perform(model: model, timer: timer, reminders: reminders)
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
        // Click / scroll keys (T-249): the reference synthesizes a real click at the pointer
        // (its keyboard cursor *is* the pointer). Here they act on the hovered cell, else the
        // keyboard cursor's cell — the same cell every other region hotkey targets.
        case "Global_LeftClick":   return performClick(.left)
        case "Global_RightClick":  return performClick(.right)
        case "Global_MiddleClick": return performClick(.middle)
        case "Global_ScrollUp":    return performClick(.scrollUp)
        case "Global_ScrollDown":  return performClick(.scrollDown)
        default:
            return false
        }
        return true
    }

    /// A click / scroll key on the active region's cell (T-249). Items and dungeon-item boxes
    /// are edited here directly; the overworld and dungeon map hand the click to their grid
    /// view (it owns their pickers). Blockers and Notes have no keyboard click.
    @discardableResult
    func performClick(_ kind: TrackerFocusState.ClickRequest.Kind) -> Bool {
        guard let region = focus.activeRegion else { return false }
        let cell = focus.cell(in: region)
        switch region {
        case .overworld, .dungeonMap:
            focus.clickRequest = .init(kind: kind, region: region, cell: cell)
            return true
        case .items:
            return clickItem(kind, cell: cell)
        case .dungeonItem:
            guard kind == .left, (0..<9).contains(cell.col) else { return false }
            let boxes = model.dungeonTracker.dungeon(cell.col).boxes
            guard boxes.indices.contains(cell.row), boxes[cell.row].hasKnownItem else { return false }
            boxes[cell.row].toggleTaken()
            return true
        case .blockers, .notes:
            return false
        }
    }

    /// The Items grid's mouse actions on a cell (T-249), mirroring `ItemToggleBox`,
    /// `TakeAnyHeartBox` and `BoxView`: left toggles (the magical sword not below its heart
    /// minimum), right clears; take-any slots cycle; a box with a known item toggles taken.
    private func clickItem(_ kind: TrackerFocusState.ClickRequest.Kind, cell: TrackerFocusState.GridCell) -> Bool {
        guard let c = ItemProgressGrid.cell(row: cell.row, col: cell.col) else { return false }
        let progress = model.playerProgress
        switch (c, kind) {
        case (.toggle(let t), .left):
            if !progress[keyPath: t.keyPath], t == .magicalSword,
               !ItemAcquisitionGate.magicalSwordReachable(model.playerComputedStateSummary) { return false }
            progress[keyPath: t.keyPath].toggle()
        case (.toggle(let t), .right):
            guard progress[keyPath: t.keyPath] else { return false }
            progress[keyPath: t.keyPath] = false
        case (.takeAnyHeart(let i), .left):  model.cycleTakeAnySlot(i, by: 1)
        case (.takeAnyHeart(let i), .right): model.cycleTakeAnySlot(i, by: -1)
        case (.pickerBox(let coast), .left):
            let box = coast.box(in: model.dungeonTracker)
            guard box.hasKnownItem else { return false }
            box.toggleTaken()
        default:
            return false
        }
        return true
    }
}

private extension String {
    /// The remainder after `prefix`, or nil if `self` doesn't start with it (T-169).
    func hotkeySuffix(_ prefix: String) -> String? {
        hasPrefix(prefix) ? String(dropFirst(prefix.count)) : nil
    }
}
