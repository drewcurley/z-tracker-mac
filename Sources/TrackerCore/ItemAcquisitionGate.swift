/// Whether the player could *already have collected* certain gated items, used to default their
/// tracker state to **untaken** when they can't have reached them yet (T-214).
///
/// The randomizer gates a few items behind requirements the tracker can't seed-snoop:
/// - **Coast item** — always needs the **ladder** to reach.
/// - **White Sword item** — needs a heart-container minimum that varies **4–6** by seed.
/// - **Magical Sword** — needs a heart-container minimum that varies **10–14** by seed.
///
/// Since we can't read the seed's exact requirement, we use the **minimum** of each range: below
/// it, the item can't possibly be held, so mark it untaken automatically; at or above it, we trust
/// the user to mark it. `playerHearts` is the max heart-container count (starts at 3).
public enum ItemAcquisitionGate {
    /// White Sword item cave: 4–6 hearts by seed → use the minimum.
    public static let whiteSwordItemMinHearts = 4
    /// Magical Sword cave: 10–14 hearts by seed → use the minimum.
    public static let magicalSwordMinHearts = 10

    /// The coast item is reachable only with the ladder.
    public static func coastReachable(_ s: PlayerComputedStateSummary) -> Bool { s.haveLadder }

    /// The White Sword item is *possibly* reachable at or above the minimum heart gate.
    public static func whiteSwordItemReachable(_ s: PlayerComputedStateSummary) -> Bool {
        s.playerHearts >= whiteSwordItemMinHearts
    }

    /// The Magical Sword is *possibly* reachable at or above the minimum heart gate.
    public static func magicalSwordReachable(_ s: PlayerComputedStateSummary) -> Bool {
        s.playerHearts >= magicalSwordMinHearts
    }
}
