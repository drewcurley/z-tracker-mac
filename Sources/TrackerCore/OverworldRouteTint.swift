/// The green/yellow/red accessibility tint for a highlighted overworld
/// screen — the "GYR" the tracker is named for. Ported from the color
/// cascade in `doComputedDrawing`
/// (`Zelda1RandoTools/Z1R_Tracker/Z1R_WPF/OverworldRouteDrawing.fs:44-63`).
///
/// This is only the *color* decision. Bold-vs-pale is a separate axis (the
/// reference's `bright` flag; this project's `OverworldRouteHighlightEntry.isBold`)
/// applied by the view as opacity. The **cyan override** for the currently-
/// selected route target (`whatToCyan`, `:65-68`) is deferred with the
/// destination picker that produces a selection (T-015.6).
public enum OverworldRouteTint: Sendable, Equatable, CaseIterable {
    /// Accessible (or a marked dungeon 1–8).
    case green
    /// Accessible but "sometimes empty" depending on quest.
    case yellow
    /// Inaccessible — the player can't currently reach/uncover this screen.
    case red

    /// The reference's exact ordered cascade for a highlighted screen:
    /// 1. a tile marked as **dungeon 1–8** (raw index `0…7`) → green
    ///    (callers sometimes pass located dungeons through the "unmarked"
    ///    highlight set; they're accessible);
    /// 2. else if **not gettable** → red (the inaccessible signal);
    /// 3. else if **sometimes empty** → yellow;
    /// 4. else → green.
    ///
    /// - Parameters:
    ///   - markRawIndex: the screen's `OverworldTileMark.rawIndex`
    ///     (`-1` = unmarked).
    ///   - gettable: `MapStateSummary.owGettableLocations[x, y]`.
    ///   - sometimesEmpty: `OverworldInstance.sometimesEmpty(x:y:)`.
    public static func forHighlightedTile(
        markRawIndex: Int,
        gettable: Bool,
        sometimesEmpty: Bool
    ) -> OverworldRouteTint {
        if markRawIndex >= 0 && markRawIndex <= 7 { return .green } // dungeon 1–8
        if !gettable { return .red }
        if sometimesEmpty { return .yellow }
        return .green
    }
}
