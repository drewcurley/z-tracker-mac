/// The canonical vanilla overworld screens for dungeons 1–9, ported from the
/// reference's `vanilla1QDungeonLocations` / `vanilla2QDungeonLocations`
/// (`Z1R_Tracker/OverworldData.fs:25-26`). Index 0 = Dungeon 1 … index 8 =
/// Dungeon 9; each entry is `(column, row)` with column 0–15, row 0–7.
///
/// Used by the "auto-map vanilla dungeons" action (T-035.x): unlike the
/// reference — which paints a *non-destructive* numbered-circle overlay on a
/// separate layer this port doesn't have — the clone sets the real
/// `.dungeon(n)` marks and clears any prior dungeon marks first, per the user's
/// request ("map the vanilla locations and remove any previous dungeon
/// markers").
public enum OverworldVanillaDungeons {
    /// First-quest vanilla dungeon screens, dungeon 1 … 9.
    public static let firstQuest: [(column: Int, row: Int)] = [
        (7, 3), (12, 3), (4, 7), (5, 4), (11, 0), (2, 2), (2, 4), (13, 6), (5, 0),
    ]

    /// Second-quest vanilla dungeon screens, dungeon 1 … 9.
    public static let secondQuest: [(column: Int, row: Int)] = [
        (7, 3), (4, 3), (12, 3), (11, 1), (5, 4), (0, 3), (12, 6), (8, 1), (0, 0),
    ]
}
