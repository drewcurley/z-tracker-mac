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

    /// The dungeon-column **word** — the label prefix with any trailing separator
    /// stripped, for surfaces that show the word alone (e.g. the overworld picker's
    /// submenu title). `"LEVEL-"` → `"LEVEL"`, `"area-"` → `"area"`, `"DUNGEON"` →
    /// `"DUNGEON"`. Generalizes the reference's fixed LEVEL/BOARD choice (T-171).
    public static func columnWord(prefix: String) -> String {
        var s = prefix
        while let last = s.last, !last.isLetter, !last.isNumber { s.removeLast() }
        return s.isEmpty ? prefix : s
    }

    /// A dungeon slot's full column name: the label **prefix** (which carries its own
    /// separator) joined to the slot label — e.g. `LEVEL-` + `9` = `LEVEL-9`,
    /// `area-` + `1` = `area-1`, `DUNGEON` + `1` = `DUNGEON1`, or `LEVEL-` + `A` =
    /// `LEVEL-A` under Hidden Dungeon Numbers. Used for the overworld picker's dungeon
    /// menu and the dungeon-map title so both agree. The prefix generalizes the
    /// reference's LEVEL/BOARD word (T-171) — the caller resolves it from the rename
    /// preference (`TrackerOptions.levelPrefix`).
    public static func columnName(slot number: Int, prefix: String,
                                  hideDungeonNumbers: Bool) -> String {
        "\(prefix)\(slotLabel(number, hideDungeonNumbers: hideDungeonNumbers))"
    }
}
