/// Community nicknames for the five vanilla Armos-item overworld screens (T-223, user-provided).
/// Keyed by 0-indexed grid `(column, row)`; these exactly match `Masks.armos` (the reference
/// armos-capability mask). Used by the auto-deduction alert ("<name> has your item").
public enum ArmosLocation {
    /// The nickname for an armos-eligible screen, or `nil` if `(column, row)` isn't one of the five.
    public static func name(column: Int, row: Int) -> String? {
        switch (column, row) {
        case (12, 1): "Lost Hills Armos"    // B13
        case (4, 2):  "Grave Armos"         // C5
        case (4, 3):  "Death Armos"         // D5
        case (13, 3): "North Forest Armos"  // D14
        case (14, 4): "East Forest Armos"   // E15
        default: nil
        }
    }
}
