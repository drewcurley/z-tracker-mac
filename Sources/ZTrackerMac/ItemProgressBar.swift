import SwiftUI
import TrackerCore

/// A read-only progression strip (T-035.9), ported from the reference's
/// `MakeItemProgressBar` (`Z1R_WPF/UIComponents.fs:433`). Each item shows its
/// current variant from `PlayerComputedStateSummary` (sword by level, candle
/// blue/red, etc.), full when obtained and dimmed when not. Derived state only —
/// nothing here is clickable or persisted. (The reference's hover-to-locate is
/// deferred with routing.)
struct ItemProgressBar: View {
    var playerState: PlayerComputedStateSummary
    var iconOptions: ItemIconOptions

    /// One item cell: which icon to show and whether it's obtained.
    struct Slot: Equatable {
        var icon: ItemIconAtlas.Icon
        var obtained: Bool
    }

    /// The ordered cells for a player state — pure, so it's unit-testable.
    /// Order mirrors the reference bar (sword, candle, ring, bow, arrow, wand,
    /// book, boomerang, ladder, recorder, bracelet, raft, key).
    nonisolated static func slots(_ s: PlayerComputedStateSummary, options: ItemIconOptions) -> [Slot] {
        [
            Slot(icon: s.swordLevel >= 3 ? .magicalSword : (s.swordLevel == 2 ? .whiteSword : .brownSword),
                 obtained: s.swordLevel >= 1),
            Slot(icon: s.candleLevel >= 2 ? .redCandle : .blueCandle, obtained: s.candleLevel >= 1),
            Slot(icon: s.ringLevel >= 2 ? .redRing : .blueRing, obtained: s.ringLevel >= 1),
            Slot(icon: .bow, obtained: s.haveBow),
            Slot(icon: s.arrowLevel >= 2 ? .silverArrow : .woodArrow, obtained: s.arrowLevel >= 1),
            Slot(icon: .wand, obtained: s.haveWand),
            Slot(icon: options.isCurrentlyBook ? .book : .magicShield, obtained: s.haveBookOrShield),
            Slot(icon: s.boomerangLevel >= 2 ? .magicBoomerang : .boomerang, obtained: s.boomerangLevel >= 1),
            Slot(icon: .ladder, obtained: s.haveLadder),
            Slot(icon: .recorder, obtained: s.haveRecorder),
            Slot(icon: .powerBracelet, obtained: s.havePowerBracelet),
            Slot(icon: .raft, obtained: s.haveRaft),
            Slot(icon: .key, obtained: s.haveAnyKey),
        ]
    }

    var body: some View {
        HStack(spacing: 6) {
            Text("Item Progress").font(.system(size: 12, weight: .semibold))
            ForEach(Array(Self.slots(playerState, options: iconOptions).enumerated()), id: \.offset) { _, slot in
                if let image = Image(atlasIcon: ItemIconAtlas.cgImage(slot.icon)) {
                    image.interpolation(.none).resizable()
                        .frame(width: 20, height: 20)
                        .opacity(slot.obtained ? 1 : 0.22)
                }
            }
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(RoundedRectangle(cornerRadius: 6).fill(Color(white: 0.11)))
        .overlay(RoundedRectangle(cornerRadius: 6).strokeBorder(Color(white: 0.25), lineWidth: 1))
    }
}
