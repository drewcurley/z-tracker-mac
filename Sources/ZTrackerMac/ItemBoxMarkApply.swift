import TrackerCore

/// Applies an `Item_*` hotkey to an item picker-box (T-135) — the white-sword /
/// coast / armos boxes in the item grid. The i-th `.items` selector names item
/// index i (verified against `ITEMS`); `Item_Nothing` clears the box.
enum ItemBoxMark {
    /// The item index a hotkey suffix names, or `-1` to clear (`Nothing`); `nil` if
    /// the suffix isn't an item.
    static func itemIndex(forHotkeySuffix suffix: String) -> Int? {
        switch suffix {
        case "BookOrShield":   return ITEMS.bookOrShield
        case "Boomerang":      return ITEMS.boomerang
        case "Bow":            return ITEMS.bow
        case "PowerBracelet":  return ITEMS.powerBracelet
        case "Ladder":         return ITEMS.ladder
        case "MagicBoomerang": return ITEMS.magicBoomerang
        case "AnyKey":         return ITEMS.anyKey
        case "Raft":           return ITEMS.raft
        case "Recorder":       return ITEMS.recorder
        case "RedCandle":      return ITEMS.redCandle
        case "RedRing":        return ITEMS.redRing
        case "SilverArrow":    return ITEMS.silverArrow
        case "Wand":           return ITEMS.wand
        case "WhiteSword":     return ITEMS.whiteSword
        case "HeartContainer": return ITEMS.heartContainer
        case "Nothing":        return -1
        default:               return nil
        }
    }

    /// Place (or clear) an item in `box`, mirroring the picker's left-click. Respects
    /// the unique-item rule (`canSelectItem`); returns false if the item can't go here.
    @MainActor @discardableResult
    static func apply(itemIndex index: Int, to box: Box,
                      instance: DungeonTrackerInstance) -> Bool {
        if index < 0 {
            box.set(cellCurrent: -1, playerHas: .no)   // clear
            return true
        }
        guard instance.canSelectItem(index, forBox: box) else { return false }
        box.set(cellCurrent: index, playerHas: .yes)
        return true
    }

    /// The item-box **hotkey** behavior (T-169), which adds repeat-press smarts on top
    /// of `apply`. Ported from the box key handler (`Views.fs:360-384`), with one
    /// deliberate deviation (user, 2026-07-22): a *fresh* mark claims possession
    /// (`.yes`, green) as this clone already does, rather than the reference's `.no`.
    ///
    /// - A key for the item the box **already holds** cycles possession
    ///   green → skipped → red → green (`.yes → .skipped → .no → .yes`).
    /// - `Nothing` (index < 0) clears a filled box to empty, or toggles an empty box's
    ///   outline red ⇄ white (`.no ⇄ .skipped`), matching the reference.
    /// - Any other key sets that item at `.yes` (respecting the unique-item rule).
    @MainActor @discardableResult
    static func cycleHotkey(itemIndex index: Int, box: Box,
                            instance: DungeonTrackerInstance) -> Bool {
        if index >= 0, box.cellCurrent == index {
            switch box.playerHas {
            case .yes:     box.setPlayerHas(.skipped)
            case .skipped: box.setPlayerHas(.no)
            case .no:      box.setPlayerHas(.yes)
            }
            return true
        }
        if index < 0 {
            if box.cellCurrent != -1 { box.set(cellCurrent: -1, playerHas: .no) }
            else if box.playerHas == .no { box.set(cellCurrent: -1, playerHas: .skipped) }
            else { box.set(cellCurrent: -1, playerHas: .no) }
            return true
        }
        return apply(itemIndex: index, to: box, instance: instance)
    }
}
