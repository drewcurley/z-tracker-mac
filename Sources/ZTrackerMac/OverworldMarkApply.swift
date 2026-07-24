import TrackerCore

/// The one place overworld tile marks are applied to the grid (T-134), so a mouse
/// click on the picker and a keyboard hotkey on the cursor cell do *identically* the
/// same thing. Mirrors the reference `applyMark` mechanics; the take-any release and
/// dungeon-location-hint side effects stay as injected closures (the view already
/// wires them to the model, and so does the hotkey dispatcher).
enum OverworldMark {
    /// What the caller still needs to do *around* the grid change — fire the
    /// overwrite reminder for `oldMark → mark`, and (for Armos / White-Sword-cave)
    /// open the "what item was here?" prompt. Kept out of the shared core because
    /// they're UI concerns the click path and the hotkey path handle differently.
    struct ApplyResult {
        let oldMark: OverworldTileMark
        /// `true` = Armos prompt, `false` = White-Sword-cave prompt, `nil` = no prompt.
        let itemPromptIsArmos: Bool?
    }

    @MainActor @discardableResult
    static func apply(_ mark: OverworldTileMark, column: Int, row: Int,
                      grid: OverworldGrid,
                      releaseTakeAny: (Int, Int) -> Void,
                      placeDungeon: (Int, Int, Int) -> Void) -> ApplyResult {
        let oldMark = grid.mark(column: column, row: row)
        // Changing a take-any to anything else frees its linked heart slot (T-066).
        if oldMark == .takeAny { releaseTakeAny(column, row) }
        grid.setMark(mark, column: column, row: row)
        // Secrets / letter / hint shop default to dark on placement (T-110).
        if mark.placesUsedWhenMarked { grid.setUsed(true, column: column, row: row) }
        // A shop can't hold the same item twice (T-060).
        if case .shop(let item1) = mark, grid.shopSecondItem(column: column, row: row) == item1 {
            grid.setShopSecondItem(nil, column: column, row: row)
        }
        // Placing a dungeon auto-sets its location hint to this screen's region (T-039.1).
        if case .dungeon(let number) = mark { placeDungeon(number, column, row) }
        // Armos / White-Sword-cave prompt for the item that was there (T-106).
        let isArmos: Bool?
        if mark == .armos { isArmos = true }
        else if case .swordCave(2) = mark { isArmos = false }
        else { isArmos = nil }
        return ApplyResult(oldMark: oldMark, itemPromptIsArmos: isArmos)
    }

    /// Voice (T-141): a second, distinct shop word on a tile that's already a shop
    /// sets the tile's **second** item (T-060) instead of overwriting the primary —
    /// you can't say "2nd item" by voice, so the additive reading is what's meant.
    /// Returns `true` if it handled the mark as a second item (caller then stops);
    /// `false` means apply `mark` normally.
    @MainActor @discardableResult
    static func applyVoiceSecondShopItem(_ mark: OverworldTileMark, column: Int, row: Int,
                                         grid: OverworldGrid) -> Bool {
        guard case .shop(let newKind) = mark,
              case .shop(let firstKind) = grid.mark(column: column, row: row),
              newKind != firstKind else { return false }
        grid.setShopSecondItem(newKind, column: column, row: row)
        return true
    }

    /// The overworld **shop hotkey** smarts (T-169, `extras.md` §hotkeys) for a tile
    /// that is *already* a shop: pressing an item already in the shop removes it;
    /// a new item fills the free slot; and when both slots are full, a third item
    /// replaces the **first** (primary) item. Returns `false` when the tile isn't a
    /// shop yet, so the caller places it fresh through `apply` (which handles the
    /// take-any release and other side effects).
    @MainActor @discardableResult
    static func applyShopHotkeySmart(_ newKind: ShopKind, column: Int, row: Int,
                                     grid: OverworldGrid) -> Bool {
        guard case .shop(let first) = grid.mark(column: column, row: row) else { return false }
        let second = grid.shopSecondItem(column: column, row: row)
        if newKind == first {
            // Remove the primary; a present secondary is promoted to primary.
            if let second {
                grid.setMark(.shop(second), column: column, row: row)
                grid.setShopSecondItem(nil, column: column, row: row)
            } else {
                grid.setMark(.unmarked, column: column, row: row)
            }
        } else if newKind == second {
            grid.setShopSecondItem(nil, column: column, row: row)   // remove the secondary
        } else if second == nil {
            grid.setShopSecondItem(newKind, column: column, row: row)  // fill the free slot
        } else {
            // Both slots full → replace the primary, keep the secondary (which differs,
            // so no dup).
            grid.setMark(.shop(newKind), column: column, row: row)
        }
        return true
    }
}
