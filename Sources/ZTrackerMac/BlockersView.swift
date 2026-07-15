import SwiftUI
import TrackerCore

/// The Blockers grid (T-019.2) — ported from the reference's `MakeBlockers`
/// (`UIComponents.fs:955-997`). A 3×3 grid: the top-left cell is the "Blockers"
/// title; the other eight are dungeons 1–8 (dungeon 9 has none), each a row of
/// three blocker boxes with a slot label that lights white once the dungeon is
/// located on the overworld.
///
/// A blocker records *why you left a dungeon* — an item you were missing (bombs,
/// key, meat, bow, recorder, ladder, money) or that you needed a better
/// weapon/armor (combat). Definite vs "maybe" is shown by the box border
/// (solid light-gray vs a green→red gradient); an empty slot is gray.
///
/// Interaction: **left- or right-click** a box opens the kind picker (the
/// reference treats both the same); the picker has a Clear. The reference's
/// "applies to" (which reward inside the dungeon is behind the blocker, drawn as
/// chips on the dungeon widgets) is a separate future slice, deferred until its
/// chip rendering exists. Every box is a VoiceOver element from the start
/// (docs/ux.md § Accessibility).
struct BlockersView: View {
    @Bindable var model: TrackerModel

    private var located: Set<Int> { DungeonTrackerView.locatedDungeonIndices(in: model.overworldGrid) }

    var body: some View {
        Grid(horizontalSpacing: 10, verticalSpacing: 6) {
            GridRow {
                Text("Blockers")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.orange)
                    .frame(minWidth: 90, alignment: .leading)
                dungeonCell(0)
                dungeonCell(1)
            }
            GridRow { dungeonCell(2); dungeonCell(3); dungeonCell(4) }
            GridRow { dungeonCell(5); dungeonCell(6); dungeonCell(7) }
        }
    }

    /// One dungeon's cell: its slot label + three blocker boxes.
    private func dungeonCell(_ dungeonIndex: Int) -> some View {
        HStack(spacing: 4) {
            Text(DungeonLabeling.slotLabel(dungeonIndex + 1, hideDungeonNumbers: model.hideDungeonNumbers))
                .font(.system(size: 11, weight: .bold, design: .rounded))
                .foregroundStyle(located.contains(dungeonIndex) ? .white : .orange)
                .frame(width: 12)
            ForEach(0..<DungeonBlockersContainer.maxBlockersPerDungeon, id: \.self) { slot in
                BlockerBoxView(
                    model: model,
                    dungeonIndex: dungeonIndex,
                    slot: slot,
                    playerState: model.playerComputedStateSummary)
            }
        }
    }
}

/// One blocker box — the state border + kind icon, with the kind picker
/// (left-click) and the "applies to" / clear context menu (right-click).
private struct BlockerBoxView: View {
    @Bindable var model: TrackerModel
    let dungeonIndex: Int
    let slot: Int
    let playerState: PlayerComputedStateSummary

    @State private var showingKindPicker = false
    private static let size: CGFloat = 30

    private var blocker: DungeonBlocker {
        model.dungeonBlockers.dungeonBlocker(dungeon: dungeonIndex, slot: slot)
    }

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 4).fill(.black.opacity(0.35))
            if let icon = BlockerIcons.icon(for: blocker),
               let image = Image(atlasIcon: ItemIconAtlas.cgImage(icon)) {
                image.interpolation(.none).resizable().frame(width: 20, height: 20)
                    .opacity(blocker.isMaybe ? 0.85 : 1)
            }
        }
        .frame(width: Self.size, height: Self.size)
        .overlay(border)
        .contentShape(Rectangle())
        // Left- and right-click both open the picker (the reference treats them
        // the same; "applies to" is a separate future slice with its own chips).
        .onTapGesture { showingKindPicker = true }
        .onRightClick { showingKindPicker = true }
        .help("Dungeon \(dungeonIndex + 1) blocker: \(blocker.displayDescription.replacingOccurrences(of: "\n", with: " "))")
        .popover(isPresented: $showingKindPicker, arrowEdge: .bottom) {
            BlockerKindPicker(current: blocker, playerState: playerState) { kind in
                model.dungeonBlockers.setDungeonBlocker(kind, dungeon: dungeonIndex, slot: slot)
                showingKindPicker = false
            }
        }
        // VoiceOver: a labeled button reading its current blocker.
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Dungeon \(dungeonIndex + 1) blocker \(slot + 1)")
        .accessibilityValue(blocker == .nothing ? "Empty" : blocker.displayDescription.replacingOccurrences(of: "\n", with: " "))
        .accessibilityAddTraits(.isButton)
        .accessibilityAction { showingKindPicker = true }
    }

    /// The state border: gray (empty), green→red gradient (maybe), light-gray
    /// (definite) — mirrors the reference's `blocker_brush`.
    @ViewBuilder private var border: some View {
        let shape = RoundedRectangle(cornerRadius: 4)
        if blocker == .nothing {
            shape.strokeBorder(Color(white: 0.4), lineWidth: 2)
        } else if blocker.isMaybe {
            shape.strokeBorder(
                LinearGradient(colors: [Color(red: 0.24, green: 0.7, blue: 0.24),
                                        Color(red: 0.7, green: 0.24, blue: 0.24)],
                               startPoint: .topLeading, endPoint: .bottomTrailing),
                lineWidth: 2.5)
        } else {
            shape.strokeBorder(Color(white: 0.8), lineWidth: 2.5)
        }
    }

}

/// The kind-picker popover: the eight blocker kinds (dimmed when the player can
/// no longer be blocked by them) plus Clear.
private struct BlockerKindPicker: View {
    let current: DungeonBlocker
    let playerState: PlayerComputedStateSummary
    let onPick: (DungeonBlocker) -> Void

    private static let kinds: [DungeonBlocker] =
        [.bowAndArrow, .recorder, .ladder, .key, .bait, .money, .bomb, .combat]
    private let columns = Array(repeating: GridItem(.fixed(40), spacing: 6), count: 4)

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Why did you leave?").font(.caption).foregroundStyle(.secondary)
            LazyVGrid(columns: columns, spacing: 6) {
                ForEach(Self.kinds, id: \.self) { kind in
                    let canBlock = kind.playerCouldBeBlockedByThis(playerState)
                    Button { onPick(kind) } label: {
                        VStack(spacing: 2) {
                            if let icon = BlockerIcons.icon(for: kind),
                               let image = Image(atlasIcon: ItemIconAtlas.cgImage(icon)) {
                                image.interpolation(.none).resizable().frame(width: 22, height: 22)
                            }
                        }
                        .frame(width: 40, height: 34)
                        .background(RoundedRectangle(cornerRadius: 5)
                            .fill(current.hardCanonical == kind ? Color.accentColor.opacity(0.5) : Color(white: 0.16)))
                    }
                    .buttonStyle(.plain)
                    .opacity(canBlock ? 1 : 0.35)
                    .help(kind.displayDescription.replacingOccurrences(of: "\n", with: " "))
                    .accessibilityLabel(kind.displayDescription.replacingOccurrences(of: "\n", with: " "))
                }
            }
            Divider()
            Button("Clear") { onPick(.nothing) }.font(.caption)
        }
        .padding(10)
        .frame(width: 210)
    }
}

/// Blocker-kind → item icon (`Graphics.blockerHardCanonicalBMP`).
enum BlockerIcons {
    static func icon(for blocker: DungeonBlocker) -> ItemIconAtlas.Icon? {
        switch blocker.hardCanonical {
        case .combat: .whiteSword
        case .bowAndArrow: .bowAndArrow
        case .recorder: .recorder
        case .ladder: .ladder
        case .bait: .bait
        case .key: .key
        case .bomb: .bomb
        case .money: .rupee
        default: nil
        }
    }
}

