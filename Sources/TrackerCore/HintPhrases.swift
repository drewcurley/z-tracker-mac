/// The in-game hint phrases and what they decode to (T-039.1).
///
/// A Z1R hint is a scrap of text an NPC gives ("Aquamentus Awaits...",
/// "Meet the old man at..."); on its own it's opaque, so the Hint Decoder
/// translates the phrase to the dungeon / sword / mechanic it points at.
///
/// Ported verbatim from `OverworldData.hintMeanings` (OverworldData.fs:10-22)
/// and the "Other hints" list in `MakeHintDecoderUI`
/// (UIComponents.fs:762-790). The strings match the reference so a player can
/// pattern-match the exact wording they saw in-game.
public struct LevelHintPhrase: Sendable, Equatable {
    /// The phrase as it appears in-game, e.g. "Aquamentus Awaits".
    public let phrase: String
    /// What it decodes to, e.g. "Level 1", "White Sword item", "Magical Sword".
    public let meaning: String
    /// The `levelHints` target index this phrase pins a region to
    /// (dungeon 1-9 → 0-8, White Sword item → 9, Magical Sword → 10).
    public let target: Int

    public init(phrase: String, meaning: String, target: Int) {
        self.phrase = phrase
        self.meaning = meaning
        self.target = target
    }
}

public enum HintPhrases {
    /// The 11 region-pinning hints, in decoder-row order: dungeons 1-9, then
    /// the White Sword item and Magical Sword caves. Row order and indices line
    /// up with `HintTarget` and `TrackerModel.levelHints`.
    ///
    /// Note (as the user stresses): the sword rows decode to the *item* found
    /// with an NPC — "(npc) has (item) at" is the **White Sword item** (the
    /// random item in that cave, not the White Sword weapon), and "Meet (npc)
    /// at" is the **Magical Sword**.
    public static let levelHints: [LevelHintPhrase] = [
        .init(phrase: "Aquamentus Awaits", meaning: "Level 1", target: HintTarget.dungeon(1)),
        .init(phrase: "Dodongo Dwells", meaning: "Level 2", target: HintTarget.dungeon(2)),
        .init(phrase: "Manhandla Threatens", meaning: "Level 3", target: HintTarget.dungeon(3)),
        .init(phrase: "Gleeok Lurks", meaning: "Level 4", target: HintTarget.dungeon(4)),
        .init(phrase: "Digdogger Gazes", meaning: "Level 5", target: HintTarget.dungeon(5)),
        .init(phrase: "Gohma Creeps", meaning: "Level 6", target: HintTarget.dungeon(6)),
        .init(phrase: "Goriya Grumbles", meaning: "Level 7", target: HintTarget.dungeon(7)),
        .init(phrase: "Gleeok Returns", meaning: "Level 8", target: HintTarget.dungeon(8)),
        .init(phrase: "entrance to death", meaning: "Level 9", target: HintTarget.dungeon(9)),
        .init(phrase: "(npc) has (item) at", meaning: "White Sword item", target: HintTarget.whiteSwordCave),
        .init(phrase: "Meet (npc) at", meaning: "Magical Sword", target: HintTarget.magicalSwordCave),
    ]

    /// The other hint types, which don't pin a single region — purely
    /// informational reference for the player to keep in mind.
    ///
    /// These are deliberately NOT auto-applied to the map (a deviation from the
    /// reference, which offered "No feat of strength" / "Sail not" as
    /// spot-darkening checkboxes): a hinted feat/raft spot may still hold a
    /// useful item, just nothing critical to beating the game, so darkening it
    /// would hide real value. Meanings are taken from the reference decoder.
    public static let otherHints: [(phrase: String, meaning: String)] = [
        ("A feat of strength will lead to...",
         "Either push a gravestone, or push an overworld rock requiring the Power Bracelet"),
        ("Sail across the water...",
         "Raft required to reach a place"),
        ("Play a melody...",
         "Either an overworld recorder spot, or a Digdogger in a dungeon logically blocks the way"),
        ("Fire the arrow...",
         "In a dungeon, Gohma logically blocks the way"),
        ("Step over the water...",
         "Ladder required to obtain — a coast item, overworld river, or dungeon moat"),
        ("No feat of strength...",
         "Power Bracelet / pushing graves not required"),
        ("Sail not...",
         "Raft not required"),
    ]
}
