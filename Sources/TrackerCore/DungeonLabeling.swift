/// How a dungeon **slot** is labeled in the UI (T-049). In Hidden Dungeon
/// Numbers, the eight numbered dungeons are shown as letters **A–H** (their slot
/// position, since you don't yet know the real number) both in the dungeon
/// tracker and the overworld tile selector; Level 9 stays "9". Otherwise the
/// slot is just its number. Ported from the reference's HDN A–H labeling
/// (`TrackerModel.fs` `labelChar` / the HDN dungeon tabs).
///
/// The letter is the fixed slot, **not** the assigned real number — that
/// assignment is `Dungeon.labelChar`, chosen via the HDN number chooser
/// (a separate concern).
public enum DungeonLabeling {
    /// Label for dungeon slot `number` (1–9). HDN → 1…8 become "A"…"H";
    /// 9 stays "9". Non-HDN → the number itself.
    public static func slotLabel(_ number: Int, hideDungeonNumbers: Bool) -> String {
        guard hideDungeonNumbers, (1...8).contains(number) else { return "\(number)" }
        // 1 → 'A' (65) … 8 → 'H' (72).
        return String(UnicodeScalar(UInt8(64 + number)))
    }

    /// The dungeon-column word — "LEVEL" or "BOARD" — chosen by the
    /// `BOARDInsteadOfLEVEL` option (`Dungeon.fs:783-785`).
    public static func columnWord(boardInsteadOfLevel: Bool) -> String {
        boardInsteadOfLevel ? "BOARD" : "LEVEL"
    }

    /// A dungeon slot's full column name in the user's chosen scheme (T-112):
    /// the column word joined to the slot label, e.g. `LEVEL-9`, `BOARD-3`, or
    /// `LEVEL-A` under Hidden Dungeon Numbers. Matches the reference dungeon-tab
    /// text (`DungeonUI.fs:1085`) and is used for the overworld picker's dungeon
    /// menu and the dungeon-map title so all three agree.
    public static func columnName(slot number: Int, boardInsteadOfLevel: Bool,
                                  hideDungeonNumbers: Bool) -> String {
        "\(columnWord(boardInsteadOfLevel: boardInsteadOfLevel))-\(slotLabel(number, hideDungeonNumbers: hideDungeonNumbers))"
    }
}
