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
}
