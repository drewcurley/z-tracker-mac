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
    /// Shared keyboard-cursor state (T-135) — this is the "blockers" cursor region.
    var focus: TrackerFocusState

    private var located: Set<Int> { DungeonTrackerView.locatedDungeonIndices(in: model.overworldGrid) }

    var body: some View {
        // A clean 3×3 of dungeons 1–9 (T-090). The old top-left "Blockers" label
        // cell is dropped — the group header already says "Blockers" — so every
        // dungeon shifts one column left and Level 9 fills the freed slot.
        Grid(horizontalSpacing: 10, verticalSpacing: 6) {
            GridRow { dungeonCell(0); dungeonCell(1); dungeonCell(2) }
            GridRow { dungeonCell(3); dungeonCell(4); dungeonCell(5) }
            GridRow { dungeonCell(6); dungeonCell(7); dungeonCell(8) }
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
                    .overlay { cursorRing(dungeon: dungeonIndex, slot: slot) }
                    .onHover { hovering in
                        if hovering {
                            let c = BlockerRegion.cell(dungeon: dungeonIndex, slot: slot)
                            focus.hoverBlockers(col: c.col, row: c.row)
                        } else {
                            focus.endHover(.blockers)
                        }
                    }
            }
        }
    }

    /// The keyboard cursor's cyan ring on its blocker box (T-135).
    @ViewBuilder
    private func cursorRing(dungeon: Int, slot: Int) -> some View {
        if focus.cursorShown, focus.cursorRegion == .blockers,
           focus.blockersCursor == BlockerRegion.cell(dungeon: dungeon, slot: slot) {
            RoundedRectangle(cornerRadius: 4)
                .strokeBorder(Color.cyan, lineWidth: 2)
                .shadow(color: .cyan, radius: 2)
                .allowsHitTesting(false)
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
    @State private var showingAppliesTo = false
    private static let size: CGFloat = 30

    private var blocker: DungeonBlocker {
        model.dungeonBlockers.dungeonBlocker(dungeon: dungeonIndex, slot: slot)
    }

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 4).fill(.black.opacity(0.35))
            if let icon = BlockerIcons.icon(for: blocker) {
                ItemGlyph(icon).frame(width: 20, height: 20)
                    .opacity(blocker.isMaybe ? 0.85 : 1)
            }
        }
        .frame(width: Self.size, height: Self.size)
        .overlay(border)
        .contentShape(Rectangle())
        // Left-click sets the kind (need / might-need); right-click sets what the
        // blocker "applies to" (the reference uses middle / shift-left for that).
        .onTapGesture { presentPopoverWithoutAnimation { showingKindPicker = true } }
        .onRightClick { presentPopoverWithoutAnimation { showingAppliesTo = true } }
        .help("Dungeon \(dungeonIndex + 1) blocker: \(blocker.displayDescription.replacingOccurrences(of: "\n", with: " ")) — right-click to set what it applies to")
        .popover(isPresented: $showingKindPicker, arrowEdge: .bottom) {
            BlockerKindPicker(current: blocker, playerState: playerState) { kind in
                model.dungeonBlockers.setDungeonBlocker(kind, dungeon: dungeonIndex, slot: slot)
                showingKindPicker = false
            }
        }
        .popover(isPresented: $showingAppliesTo, arrowEdge: .bottom) {
            BlockerAppliesToPanel(
                model: model, dungeonIndex: dungeonIndex, slot: slot,
                boxCount: model.dungeonTracker.dungeon(dungeonIndex).boxes.count)
        }
        // VoiceOver: a labeled button reading its current blocker.
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Dungeon \(dungeonIndex + 1) blocker \(slot + 1)")
        .accessibilityValue(blocker == .nothing ? "Empty" : blocker.displayDescription.replacingOccurrences(of: "\n", with: " "))
        .accessibilityAddTraits(.isButton)
        .accessibilityAction { presentPopoverWithoutAnimation { showingKindPicker = true } }
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

/// The kind-picker popover: the definite ("Need") and uncertain ("Might need")
/// blocker kinds — the reference's full `DungeonBlocker.All` grid — dimmed when
/// the player can no longer be blocked by them, plus Clear.
private struct BlockerKindPicker: View {
    let current: DungeonBlocker
    let playerState: PlayerComputedStateSummary
    let onPick: (DungeonBlocker) -> Void

    /// The definite kinds (`combat` has no "maybe" form in the reference).
    private static let needKinds: [DungeonBlocker] =
        [.bowAndArrow, .recorder, .ladder, .key, .bait, .money, .bomb, .combat]
    /// The "might need" (uncertain) forms — same order, minus combat.
    private static let maybeKinds: [DungeonBlocker] =
        [.maybeBowAndArrow, .maybeRecorder, .maybeLadder, .maybeKey, .maybeBait, .maybeMoney, .maybeBomb]
    private let columns = Array(repeating: GridItem(.fixed(40), spacing: 6), count: 4)

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Why did you leave?").font(.caption).foregroundStyle(.secondary)
            section("Need", kinds: Self.needKinds)
            section("Might need", kinds: Self.maybeKinds)
            Divider()
            Button("Clear") { onPick(.nothing) }.font(.caption)
        }
        .padding(10)
        .frame(width: 210)
    }

    private func section(_ title: String, kinds: [DungeonBlocker]) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title.uppercased())
                .font(.system(size: 9, weight: .semibold)).foregroundStyle(.secondary)
            LazyVGrid(columns: columns, spacing: 6) {
                ForEach(kinds, id: \.self) { kind in
                    let canBlock = kind.playerCouldBeBlockedByThis(playerState)
                    Button { onPick(kind) } label: {
                        ZStack {
                            if let icon = BlockerIcons.icon(for: kind) {
                                ItemGlyph(icon).frame(width: 22, height: 22)
                            }
                        }
                        .frame(width: 40, height: 34)
                        .background(RoundedRectangle(cornerRadius: 5)
                            .fill(current == kind ? Color.accentColor.opacity(0.5) : Color(white: 0.16)))
                        // "Might need" kinds carry the green→red gradient edge, matching
                        // the box border, so the two states read the same everywhere.
                        .overlay(RoundedRectangle(cornerRadius: 5).strokeBorder(
                            kind.isMaybe
                            ? AnyShapeStyle(LinearGradient(colors: [Color(red: 0.24, green: 0.7, blue: 0.24),
                                                                    Color(red: 0.7, green: 0.24, blue: 0.24)],
                                                           startPoint: .topLeading, endPoint: .bottomTrailing))
                            : AnyShapeStyle(Color.clear),
                            lineWidth: kind.isMaybe ? 1.5 : 0))
                    }
                    .buttonStyle(.plain)
                    .opacity(canBlock ? 1 : 0.35)
                    .help(kind.displayDescription.replacingOccurrences(of: "\n", with: " "))
                    .accessibilityLabel(kind.displayDescription.replacingOccurrences(of: "\n", with: " "))
                }
            }
        }
    }
}

/// The "Applies to…" panel (right-click a blocker box): which of the dungeon's
/// tracked cells the blocker sits in front of — its **triforce** and each **item
/// box** — with All / None. Ported from the reference's `doPanel`
/// (`UIComponents.fs:868-902`). This tracker's dungeon cards have no separate
/// map/compass cell, so those two reference elements (which would draw nowhere)
/// are omitted; the model still stores all six for save-file parity.
private struct BlockerAppliesToPanel: View {
    @Bindable var model: TrackerModel
    let dungeonIndex: Int
    let slot: Int
    let boxCount: Int

    private var blocker: DungeonBlocker {
        model.dungeonBlockers.dungeonBlocker(dungeon: dungeonIndex, slot: slot)
    }

    /// The elements this tracker can chip: triforce (except Level 9, which has no
    /// triforce cell — T-090), then each real item box.
    private var elements: [(name: String, k: Int)] {
        var e: [(String, Int)] = []
        if dungeonIndex != 8 {
            e.append(("Triforce", DungeonBlockerAppliesTo.Element.triforce.rawValue))
        }
        for n in 0..<boxCount { e.append(("Item Box \(n + 1)", DungeonBlockerAppliesTo.Element.box(n))) }
        return e
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 6) {
                if let icon = BlockerIcons.icon(for: blocker) {
                    ItemGlyph(icon).frame(width: 18, height: 18)
                }
                Text(blocker == .nothing ? "Applies to… (set a blocker first)"
                     : "\(blocker.displayDescription.replacingOccurrences(of: "\n", with: " ")) applies to…")
                    .font(.caption)
            }
            HStack(spacing: 6) {
                Button("All") { setAll(true) }
                Button("None") { setAll(false) }
            }
            .font(.caption).controlSize(.small)
            .disabled(blocker == .nothing)

            ForEach(elements, id: \.k) { el in
                Toggle(el.name, isOn: Binding(
                    get: { model.dungeonBlockers.dungeonBlockerAppliesTo(dungeon: dungeonIndex, slot: slot, element: el.k) },
                    set: { model.dungeonBlockers.setDungeonBlockerAppliesTo($0, dungeon: dungeonIndex, slot: slot, element: el.k) }))
                    .font(.caption)
            }
            .disabled(blocker == .nothing)
        }
        .toggleStyle(.checkbox)
        .padding(12)
        .frame(width: 170, alignment: .leading)
    }

    private func setAll(_ v: Bool) {
        for el in elements {
            model.dungeonBlockers.setDungeonBlockerAppliesTo(v, dungeon: dungeonIndex, slot: slot, element: el.k)
        }
    }
}

/// A tiny "applies to" chip drawn on a dungeon cell (triforce / item box): the
/// blocker's icon on a black square, or a **lime** square once the player has the
/// item that would unblock it (the reference's "go back, you can clear it now"
/// cue — `Views.fs:141-146`).
struct BlockerChip: View {
    let blocker: DungeonBlocker
    /// The player now has whatever unblocks this (so it's stale / actionable).
    let resolved: Bool

    var body: some View {
        ZStack {
            Rectangle().fill(resolved ? Color.green : Color.black)
                .frame(width: 11, height: 11)
            if let icon = BlockerIcons.icon(for: blocker) {
                ItemGlyph(icon).frame(width: 9, height: 9)
            }
        }
    }
}

/// A row of `BlockerChip`s for the blockers that apply to one cell.
struct BlockerChipRow: View {
    let blockers: [DungeonBlocker]
    let playerState: PlayerComputedStateSummary

    var body: some View {
        if !blockers.isEmpty {
            HStack(spacing: 1) {
                ForEach(Array(blockers.enumerated()), id: \.offset) { _, b in
                    BlockerChip(blocker: b, resolved: !b.playerCouldBeBlockedByThis(playerState))
                }
            }
        }
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

