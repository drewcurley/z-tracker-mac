import SwiftUI

/// The keyboard cursor's cyan ring for one cell, as its **own view** (T-245). The "is the cursor
/// here?" check runs in this view's body, so it's the ring — not the whole panel — that observes
/// `focus`. As a `@ViewBuilder` helper on the parent, every cursor move re-rendered all of a
/// panel's cells (the same fix T-179 made for the dungeon map with `DungeonCursorRing`).
struct FocusCursorRing: View {
    let focus: TrackerFocusState
    let isHere: (TrackerFocusState) -> Bool
    var cornerRadius: CGFloat = 4

    var body: some View {
        if isHere(focus) {
            RoundedRectangle(cornerRadius: cornerRadius)
                .strokeBorder(Color.cyan, lineWidth: 2)
                .shadow(color: .cyan, radius: 2)
                .allowsHitTesting(false)
        }
    }
}
