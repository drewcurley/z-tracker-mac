import TrackerCore

/// Applies a voice **progression toggle** (T-142) — the item-grid "acquired" boxes —
/// to the player-progress model. Kept as a pure, testable helper (like
/// `OverworldMark` / `DungeonRoomMark`) so the region-scoping and id→toggle mapping
/// can't drift from what the grammar promises.
enum ProgressionVoiceApply {
    /// Maps a `Prog_*` action id to its item-grid toggle.
    static func toggle(forID id: String) -> ItemProgressGrid.ItemToggle? {
        switch id {
        case "Prog_WoodSword": .woodSword
        case "Prog_MagicalSword": .magicalSword
        case "Prog_BoomBook": .boomBook
        case "Prog_BlueCandle": .blueCandle
        case "Prog_WoodArrow": .woodArrow
        case "Prog_BlueRing": .blueRing
        case "Prog_Bomb": .bomb
        case "Prog_Meat": .meat
        case "Prog_Ganon": .ganon
        case "Prog_Zelda": .zelda
        default: nil
        }
    }

    /// Flag the item as acquired. Overworld-acquired items only fire while the cursor is
    /// in the overworld region (the user's scoping); bombs and the Ganon/Zelda end-states
    /// are global. Acquisition is directional — sets the flag on. Returns `true` if it
    /// applied, `false` if the id was unknown or blocked by region scope.
    @MainActor @discardableResult
    static func apply(id: String, region: TrackerFocusState.CursorRegion,
                      progress: PlayerProgressAndTakeAnyHearts, value: Bool = true) -> Bool {
        guard let toggle = toggle(forID: id) else { return false }
        // Overworld-acquired items are set only from the overworld; a *clear* (value
        // false) is allowed from anywhere — undoing shouldn't be region-gated.
        if value, !VoiceGrammar.isGlobalProgression(id), region != .overworld { return false }
        progress[keyPath: toggle.keyPath] = value
        return true
    }
}
