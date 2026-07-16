/// The vanilla (canonical NES) dungeon room footprints (T-071), transcribed
/// exactly from the reference `DungeonData.firstQuest` / `secondQuest`
/// (`Z1R_Tracker/DungeonData.fs:72-290`). Each dungeon is 8 rows of 8 chars,
/// `X` = a room exists at that cell, `.` = no room. Used by the FQ/SQ outline
/// overlay to show a dungeon's vanilla shape over the user's room map.
public enum VanillaQuest: Sendable, Equatable, CaseIterable {
    case first, second
}

public enum VanillaDungeonData {
    /// First-quest layouts, dungeons 1–9 (index 0–8).
    public static let firstQuest: [[String]] = [
        ["........", "........", "..XX....", "...X.XX.", ".XXXXX..", "..XXX...", "...X....", "..XXX..."], // L1
        ["...XX...", "....XX..", "....XX..", "....XX..", "....XX..", "....XX..", "..XXXX..", "...XX..."], // L2
        ["........", "........", "..XX....", "...X.X..", ".XXXXX..", ".XXXXX..", ".X.X....", "...XX..."], // L3
        ["..XXXX..", "..XXXX..", "..XX....", "..XXX...", "..X.....", "..XX....", "...XX...", "..XX...."], // L4
        ["...XX...", "..XXXX..", "..XXXX..", "..X..X..", "....XX..", "...XXX..", "..XXXX..", "....XX.."], // L5
        ["..XXXX..", ".XXXXXX.", ".XX..XX.", ".XXX.X..", ".X......", ".X......", ".X.X....", ".XXX...."], // L6
        [".XXXXXX.", ".XXXXX..", ".XXXX...", ".XXX....", ".XX.....", ".XXXX...", ".XXXXXX.", ".XXX...."], // L7
        ["....X...", "...XXX..", "..XXX...", ".XXXXX..", ".XXXX...", "..XXXX..", "....X...", "..XXXX.."], // L8
        [".XXXXXXX", "XXXXXXXX", "XXXXXXXX", "XXXXXXXX", "XXXXXXXX", "XXXXXXXX", ".XXXXXX.", ".X.XX.X."], // L9
    ]

    /// Second-quest layouts, dungeons 1–9 (index 0–8).
    public static let secondQuest: [[String]] = [
        ["...XX...", "...XX...", "...X....", "...XX...", "...XX...", "...X....", "...XX...", "...XX..."], // L1
        ["...X....", "..XXX...", "..XXX...", "..XXX...", "..XXX...", "..XXX...", "..X.X...", "..X.X..."], // L2
        ["........", ".....X..", "X....X..", "X....X..", ".....X..", ".....X..", ".....XX.", ".....XX."], // L3
        ["..XXX...", "..XXXX..", "..XXXX..", "..XXXX..", "..XXXX..", "..XXXX..", "..XXXX..", "..XXX..."], // L4
        ["..XXX...", "..XXX...", "....X...", "...XX...", "..XX....", "..X.....", "..XXX...", "..XXX..."], // L5
        ["....XXX.", "...XX.X.", "...XX.X.", "...XX.X.", "..XXX...", ".XXXX...", "...XX...", "....X..."], // L6
        ["........", "..XXXXX.", "..X...X.", "..XXX.X.", "..XXX.X.", "..XXX.X.", "......X.", "XXXXXXX."], // L7
        ["XXXXXXXX", "XX.....X", "XX...X.X", "XX...X.X", "XX...X.X", "XX...X.X", "XXXXXX.X", ".......X"], // L8
        ["XX....XX", "XXXXXXXX", "..XXXX..", ".XXXXXX.", "XXXXXXXX", "XXXXXXXX", ".XXXXXX.", "...XX..."], // L9
    ]

    /// The 8-row layout for a quest + dungeon (0–8).
    public static func layout(_ quest: VanillaQuest, dungeon: Int) -> [String] {
        (quest == .first ? firstQuest : secondQuest)[dungeon]
    }

    /// Whether the vanilla dungeon has a room at `(col, row)`. Out-of-range → false.
    public static func isRoom(_ quest: VanillaQuest, dungeon: Int, col: Int, row: Int) -> Bool {
        guard (0..<9).contains(dungeon), (0..<8).contains(col), (0..<8).contains(row) else { return false }
        let chars = Array(layout(quest, dungeon: dungeon)[row])
        return col < chars.count && chars[col] == "X"
    }

    /// The number of vanilla rooms in a dungeon (spot-check / summary helper).
    public static func roomCount(_ quest: VanillaQuest, dungeon: Int) -> Int {
        layout(quest, dungeon: dungeon).reduce(0) { $0 + $1.filter { $0 == "X" }.count }
    }
}

/// The expected number of "old man" NPC rooms (hint / bomb-upgrade / hungry-goriya
/// / life-or-money) in each dungeon (T-074), from the reference
/// `DungeonData.oldManCounts1Q`/`2Q` (`DungeonData.fs:69-70`). Used for the info
/// strip's `X/Y` readout: `X` marked, `Y` expected. Constant per dungeon unless
/// specific flags shuffle old men — the tracker just shows the vanilla total.
public enum DungeonOldManCounts {
    public static let firstQuest = [1, 1, 1, 1, 3, 2, 3, 2, 3]
    public static let secondQuest = [0, 0, 1, 3, 0, 1, 2, 2, 1]

    /// Expected old-man count for dungeon `0…8` on the given quest layout.
    public static func expected(secondQuestDungeons: Bool, dungeon: Int) -> Int {
        (secondQuestDungeons ? secondQuest : firstQuest)[dungeon]
    }
}
