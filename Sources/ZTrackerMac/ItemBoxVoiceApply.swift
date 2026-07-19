import TrackerCore

/// Applies a voice **item-box** command (T-143) — "coast ladder" sets the coast /
/// armos / white-sword picker box to a chosen item. Pure/testable helper (like
/// `OverworldMark` / `ProgressionVoiceApply`), reusing `ItemBoxMark` (the same path
/// the item hotkeys use), so voice and tests can't drift.
enum ItemBoxVoiceApply {
    /// Maps a `Box_*` action id to its item-grid picker box.
    static func box(forID id: String) -> ItemProgressGrid.CoastBox? {
        switch id {
        case "Box_Coast": .coast
        case "Box_Armos": .armos
        case "Box_WhiteSword": .whiteSword
        default: nil
        }
    }

    /// The item index an `Item_<suffix>` id names (or `-1` to clear); `nil` if unknown.
    static func itemIndex(forID id: String) -> Int? {
        guard id.hasPrefix("Item_") else { return nil }
        return ItemBoxMark.itemIndex(forHotkeySuffix: String(id.dropFirst("Item_".count)))
    }

    /// Place the item in the named box. Overworld-scoped (the user's decision: these
    /// items are acquired on the overworld). Returns `true` if it applied; `false` if
    /// the ids are unknown, the region is wrong, or the unique-item rule rejected it.
    @MainActor @discardableResult
    static func apply(boxID: String, itemID: String, region: TrackerFocusState.CursorRegion,
                      tracker: DungeonTrackerInstance) -> Bool {
        guard region == .overworld else { return false }
        guard let box = box(forID: boxID), let index = itemIndex(forID: itemID) else { return false }
        return ItemBoxMark.apply(itemIndex: index, to: box.box(in: tracker), instance: tracker)
    }
}
