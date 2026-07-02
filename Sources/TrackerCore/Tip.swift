/// A z1r gameplay tip/factoid shown on the startup screen (docs/domain.md § 4.1).
public struct Tip: Identifiable, Equatable, Sendable {
    public let id: String
    public let text: String

    public init(id: String, text: String) {
        self.id = id
        self.text = text
    }
}

public enum TipProvider {
    /// **Explicitly a placeholder subset, not the exhaustive original list.**
    /// The reference app's full tip/factoid set lives in its `DungeonData.fs`
    /// and was not extracted during the domain inventory (docs/domain.md is a
    /// contract-completeness document; flavor-text tips are not a contract,
    /// so this is not held to the same exhaustiveness bar — but it must not
    /// be mistaken for complete either). Extracting the full list is a
    /// follow-up, not guessed here (docs/tasks/T-003.md "Out of scope").
    public static let placeholderTips: [Tip] = [
        Tip(
            id: "khananakey",
            text: "If you have 0 keys, and a room has both a shutter and a locked door, "
                + "and you press against the locked door the moment the shutter opens, "
                + "you can go through the door without a key, unlocking it (khananakey)."
        ),
        Tip(
            // Sourced from https://z1r.fandom.com/wiki/Boomstick, 2026-07-02
            // (the randomizer's own docs, not this app's source) — an
            // earlier draft guessed "Bow + Boomerang" without checking any
            // source. See docs/glossary.md "Boomstick".
            id: "boomstick",
            text: "In a \"Boomstick\" seed, once you get the Book your Wand shoots "
                + "explosions instead of fire — usable like Bombs, but they won't "
                + "kill (only stun) a Dodongo."
        ),
        Tip(
            id: "atlas-seed",
            text: "In an \"Atlas\" seed, the Book item behaves as a map/atlas instead of "
                + "its usual role."
        )
    ]

    public static func random() -> Tip {
        placeholderTips.randomElement() ?? placeholderTips[0]
    }
}
