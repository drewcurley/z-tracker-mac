import AppKit
import SwiftUI
import TrackerCore

/// The dungeon item-tracker (T-013/T-016 model, rendered). Nine dungeon
/// cards, each with its located triforce numeral and its item boxes.
/// Box interaction (T-044, mirroring the overworld map): **right-click** opens
/// the item picker (left-click an item = have it, right-click = don't have it,
/// or Don't-want-it / Clear); once an item is known, a **left-click** toggles
/// taken ⇄ untaken. Basement-stair glyphs render `currentlyHasBasementStair`
/// (T-016.2).
///
/// Aesthetic license (per the project): the reference's cramped grid is
/// re-laid-out as clean cards; the Zelda item sprites are kept.
struct DungeonTrackerView: View {
    @Bindable var model: TrackerModel

    /// Dungeon indices (0–8) currently marked somewhere on the overworld —
    /// which numerals light up. Ported behavior of the reference's
    /// `HasBeenLocated()` (a dungeon marked on the map), here read directly
    /// from the typed marks.
    static func locatedDungeonIndices(in grid: OverworldGrid) -> Set<Int> {
        var s: Set<Int> = []
        for col in 0..<OverworldGrid.columnCount {
            for row in 0..<OverworldGrid.rowCount {
                if case .dungeon(let n) = grid.mark(column: col, row: row) {
                    s.insert(n - 1)
                }
            }
        }
        return s
    }

    var body: some View {
        let dt = model.dungeonTracker
        let loc = Self.locatedDungeonIndices(in: model.overworldGrid)
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .top, spacing: 6) {
                ForEach(0..<9, id: \.self) { i in
                    DungeonCardView(dungeon: dt.dungeon(i), instance: dt, isLocated: loc.contains(i),
                                    iconOptions: model.iconOptions,
                                    hideDungeonNumbers: model.hideDungeonNumbers,
                                    blockers: model.dungeonBlockers,
                                    chipPlayerState: model.playerComputedStateSummary,
                                    hint: $model.levelHints[HintTarget.dungeon(i + 1)])
                }
            }
        }
    }
}

/// One dungeon: located numeral + triforce pip + its item boxes, highlighted
/// when complete.
struct DungeonCardView: View {
    @Bindable var dungeon: Dungeon
    var instance: DungeonTrackerInstance
    var isLocated: Bool
    var iconOptions = ItemIconOptions()
    /// Hidden Dungeon Numbers (T-049): label the slot A–H instead of 1–8, and
    /// hide the location hint (replaced by the number chooser — a later task).
    var hideDungeonNumbers: Bool = false
    /// The overworld-location header (hint menu / HDN chooser). Shown atop the
    /// top-row cards; the dungeon-map item inset (T-019.10) drops it — the room
    /// map is about interior contents, not where the dungeon sits on the map.
    var showLocationHeader: Bool = true
    /// The blocker container + player state, so this card can draw "applies to"
    /// chips on its triforce and item boxes (T-082). `nil` → no chips.
    var blockers: DungeonBlockersContainer? = nil
    var chipPlayerState: PlayerComputedStateSummary? = nil
    @Binding var hint: HintZone

    /// The slot label: A–H under HDN (1–8), else the number; Level 9 stays "9".
    private var slotLabel: String {
        DungeonLabeling.slotLabel(dungeon.id + 1, hideDungeonNumbers: hideDungeonNumbers)
    }

    var body: some View {
        VStack(spacing: 4) {
            // Above the slot: the location hint (T-039) in default mode; in HDN
            // (T-050) the dungeon-number chooser instead — except Level 9
            // (id 8), which is always known.
            if showLocationHeader {
                if hideDungeonNumbers {
                    if dungeon.id != 8 {
                        DungeonNumberLabel(dungeon: dungeon, slotLabel: slotLabel)
                    } else {
                        Color.clear.frame(height: 16)
                    }
                } else {
                    HintLabel(hint: $hint, title: "Dungeon \(dungeon.id + 1)")
                }
            }
            HStack(spacing: 3) {
                Text(slotLabel)
                    .font(.system(size: 15, weight: .heavy, design: .rounded))
                    .foregroundStyle(isLocated ? Color.white : Color(white: 0.42))
                // Triforce pip (ignore for dungeon 9).
                if dungeon.id != 8 {
                    Button {
                        dungeon.toggleTriforce()
                    } label: {
                        Image(systemName: "triangle.fill")
                            .font(.system(size: 9))
                            .foregroundStyle(dungeon.playerHasTriforce ? Color.yellow : Color(white: 0.3))
                    }
                    .buttonStyle(.plain)
                    .help("Toggle triforce")
                    .accessibilityLabel("Dungeon triforce")
                    .accessibilityValue(dungeon.playerHasTriforce ? "Obtained" : "Not obtained")
                }
            }
            // Triforce "applies to" chips — only while the triforce is unobtained
            // (once you have it, you're no longer blocked there — Views.fs:131).
            if let blockers, let ps = chipPlayerState, dungeon.id != 8, !dungeon.playerHasTriforce {
                BlockerChipRow(
                    blockers: blockers.blockersApplyingTo(
                        dungeon: dungeon.id, element: DungeonBlockerAppliesTo.Element.triforce.rawValue),
                    playerState: ps)
            }
            ForEach(Array(dungeon.boxes.enumerated()), id: \.offset) { idx, box in
                // In HDN, an identified two-boxer dungeon has no third item, so
                // its last box is disabled (T-050, beyond the reference).
                let isDisabledThirdBox = dungeon.identifiedAsTwoBoxer && idx == dungeon.boxes.count - 1
                BoxView(box: box, instance: instance, label: nil, iconOptions: iconOptions,
                        disabled: isDisabledThirdBox,
                        chips: blockers?.blockersApplyingTo(
                            dungeon: dungeon.id, element: DungeonBlockerAppliesTo.Element.box(idx)) ?? [],
                        chipPlayerState: chipPlayerState)
            }
            // The "ghost" slot under whichever of L1/L4 doesn't hold the movable
            // extra floor item (1Q overworld ↔ 2Q dungeons). Clicking it moves
            // the extra item here.
            if instance.ghostBoxDungeonId == dungeon.id {
                GhostBoxView { instance.toggleSecondQuestDungeons() }
            }
        }
        .padding(6)
        .background(
            RoundedRectangle(cornerRadius: 6)
                .fill(dungeon.isComplete ? Color.green.opacity(0.18) : Color(white: 0.11))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 6)
                .strokeBorder(dungeon.isComplete ? Color.green.opacity(0.8) : Color(white: 0.25), lineWidth: 1)
        )
    }
}

/// The dimmed placeholder shown under whichever of dungeon 1 / dungeon 4 does
/// **not** currently hold the movable extra floor item (a first-quest overworld
/// puts it under L1; second-quest dungeons move it to L4). Clicking it toggles
/// which dungeon carries the extra item. Mirrors the reference's "ghost" box;
/// rendered as a dashed, dimmed slot with a down-arrow hint (aesthetic license).
private struct GhostBoxView: View {
    var onToggle: () -> Void
    /// Matches `BoxView`'s cell size so the ghost aligns with the real boxes.
    private static let size: CGFloat = 34

    var body: some View {
        RoundedRectangle(cornerRadius: 4)
            .fill(Color(white: 0.14))
            .frame(width: Self.size, height: Self.size)
            .overlay(
                RoundedRectangle(cornerRadius: 4)
                    .strokeBorder(Color(white: 0.4), style: StrokeStyle(lineWidth: 1.5, dash: [3, 2]))
            )
            .overlay(
                Image(systemName: "arrow.down")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(Color(white: 0.5))
            )
            .contentShape(Rectangle())
            .onTapGesture(perform: onToggle)
            .help("Move the extra floor item here (1st-quest overworld ↔ 2nd-quest dungeons)")
            // Custom-gesture control → expose to VoiceOver (T-067).
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("Move the extra floor item")
            .accessibilityHint("Toggles which dungeon carries the shared extra item")
            .accessibilityAddTraits(.isButton)
            .accessibilityAction { onToggle() }
    }
}

/// One item box: the item sprite (if known) on a state-colored cell, with a
/// basement-stair glyph when applicable. Left-click toggles taken/untaken once
/// an item is known (else opens the picker); right-click opens the picker.
struct BoxView: View {
    @Bindable var box: Box
    var instance: DungeonTrackerInstance
    var label: String?
    /// Seed-option flags affecting item-icon display (swordless, book/shield).
    var iconOptions = ItemIconOptions()
    /// The box carries no item (an identified HDN two-boxer's third box, T-050):
    /// rendered dimmed + non-interactive so it can't be filled.
    var disabled: Bool = false
    /// Blocker "applies to" chips for this box + the player state that decides
    /// whether each is resolved (T-082). Empty → no chips.
    var chips: [DungeonBlocker] = []
    var chipPlayerState: PlayerComputedStateSummary? = nil

    @State private var showPicker = false

    private static let size: CGFloat = 34

    private var borderColor: Color {
        switch box.playerHas {
        case .yes: .green
        case .skipped: Color(white: 0.55)
        case .no: box.cellCurrent == -1 ? Color.red.opacity(0.7) : Color.orange
        }
    }

    /// VoiceOver value for the box's state (T-067).
    private var boxA11yValue: String {
        if disabled { return "Unavailable" }
        switch box.playerHas {
        case .skipped: return "Skipped"
        case .yes: return box.hasKnownItem ? "Item obtained" : "Obtained"
        case .no: return box.hasKnownItem ? "Item known, not obtained" : "Empty"
        }
    }

    var body: some View {
        if disabled { disabledBox } else { interactiveBox }
    }

    /// A dimmed, dashed, non-interactive slot for a dungeon's absent third item.
    private var disabledBox: some View {
        VStack(spacing: 2) {
            RoundedRectangle(cornerRadius: 4)
                .fill(Color(white: 0.07))
                .frame(width: Self.size, height: Self.size)
                .overlay(RoundedRectangle(cornerRadius: 4)
                    .strokeBorder(Color(white: 0.22), style: StrokeStyle(lineWidth: 1.5, dash: [3, 2])))
                .overlay(Image(systemName: "nosign")
                    .font(.system(size: 12))
                    .foregroundStyle(Color(white: 0.35)))
                .help("No third item — this dungeon has only two items")
            if let label {
                Text(label).font(.system(size: 8)).foregroundStyle(.secondary)
            }
        }
    }

    private var interactiveBox: some View {
        VStack(spacing: 2) {
            ZStack {
                RoundedRectangle(cornerRadius: 4).fill(Color.black)
                if box.cellCurrent != -1,
                   let icon = ItemIconAtlas.icon(forItemIndex: box.cellCurrent, options: iconOptions),
                   let image = Image(atlasIcon: ItemIconAtlas.cgImage(icon)) {
                    image
                        .interpolation(.none)
                        .resizable()
                        .frame(width: Self.size - 10, height: Self.size - 10)
                        .opacity(box.playerHas == .no ? 0.45 : 1)
                }
                if instance.currentlyHasBasementStair(box),
                   let stair = Image(atlasIcon: ItemIconAtlas.cgImage(.basementStair)) {
                    stair
                        .interpolation(.none)
                        .resizable()
                        .frame(width: 10, height: 10)
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomTrailing)
                        .padding(1)
                }
                if box.playerHas == .skipped {
                    Image(systemName: "xmark")
                        .font(.system(size: 9, weight: .bold))
                        .foregroundStyle(.white.opacity(0.8))
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                        .padding(2)
                }
            }
            .frame(width: Self.size, height: Self.size)
            .overlay(RoundedRectangle(cornerRadius: 4).strokeBorder(borderColor, lineWidth: 1.5))
            // Blocker "applies to" chips (T-082), inside the box's bottom-left so
            // each chip clearly belongs to its own box (not the gap below it).
            .overlay(alignment: .bottomLeading) {
                if let ps = chipPlayerState {
                    BlockerChipRow(blockers: chips, playerState: ps)
                        .padding(.leading, 1).padding(.bottom, 1)
                }
            }
            // Map-style interaction (T-044): left-click toggles taken/untaken
            // once an item is known here; right-click opens the picker to set /
            // change the item. An empty box has nothing to toggle, so a
            // left-click opens the picker too.
            .onTapGesture {
                if box.hasKnownItem { box.toggleTaken() } else { showPicker = true }
            }
            .onRightClick { showPicker = true }
            .popover(isPresented: $showPicker, arrowEdge: .bottom) {
                BoxItemPicker(box: box, instance: instance, iconOptions: iconOptions) { showPicker = false }
            }
            // Custom-gesture control → expose to VoiceOver (T-067): reads the
            // box's state, primary action toggles taken / opens the picker.
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(label.map { "Dungeon box \($0)" } ?? "Dungeon item box")
            .accessibilityValue(boxA11yValue)
            .accessibilityAddTraits(disabled ? [] : .isButton)
            .accessibilityAction {
                guard !disabled else { return }
                if box.hasKnownItem { box.toggleTaken() } else { showPicker = true }
            }
            .accessibilityAction(named: "Set item") {
                guard !disabled else { return }
                showPicker = true
            }
            if let label {
                Text(label).font(.system(size: 8)).foregroundStyle(.secondary)
            }
        }
    }
}

/// The item-selection popover: pick an item and its possession state, or
/// clear the box. Mirrors the reference's box popup (Have it / Don't want it
/// / Don't have it), presented as explicit clear controls per the aesthetic
/// license (macOS lacks a clean middle-click in SwiftUI).
struct BoxItemPicker: View {
    @Bindable var box: Box
    var instance: DungeonTrackerInstance
    var iconOptions = ItemIconOptions()
    var dismiss: () -> Void

    private let columns = Array(repeating: GridItem(.fixed(30), spacing: 4), count: 8)

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Set item — left-click = have it, right-click = don't have it")
                .font(.caption).foregroundStyle(.secondary)
            LazyVGrid(columns: columns, spacing: 4) {
                ForEach(0..<Box.itemCount, id: \.self) { item in
                    // An item already placed elsewhere (unique items, except
                    // the 9 hearts) is disabled and can't be picked again.
                    let available = instance.canSelectItem(item, forBox: box)
                    let isCurrent = box.cellCurrent == item
                    Group {
                        if let icon = ItemIconAtlas.icon(forItemIndex: item, options: iconOptions),
                           let image = Image(atlasIcon: ItemIconAtlas.cgImage(icon)) {
                            image.interpolation(.none).resizable().frame(width: 22, height: 22)
                        } else {
                            Color.gray.frame(width: 22, height: 22)
                        }
                    }
                    .opacity(available ? 1 : 0.28)
                    .padding(3)
                    .background(RoundedRectangle(cornerRadius: 4).fill(isCurrent ? Color.accentColor.opacity(0.4) : Color(white: 0.15)))
                    .onTapGesture {
                        guard available else { return }
                        box.set(cellCurrent: item, playerHas: .yes)
                        dismiss()
                    }
                    .onRightClick {
                        guard available else { return }
                        box.set(cellCurrent: item, playerHas: .no)
                        dismiss()
                    }
                    .help(available ? "Left-click: have it · Right-click: don't have it" : "Already placed elsewhere")
                    // Icon-only custom-gesture item → expose to VoiceOver (T-067).
                    .accessibilityElement(children: .ignore)
                    .accessibilityLabel(ItemIconAtlas.itemName(forItemIndex: item, options: iconOptions))
                    .accessibilityValue(isCurrent ? "Current" : (available ? "" : "Unavailable"))
                    .accessibilityAddTraits(available ? .isButton : [])
                    .accessibilityAction {
                        guard available else { return }
                        box.set(cellCurrent: item, playerHas: .yes); dismiss()
                    }
                    .accessibilityAction(named: "Mark as not having it") {
                        guard available else { return }
                        box.set(cellCurrent: item, playerHas: .no); dismiss()
                    }
                }
            }
            Divider()
            HStack(spacing: 8) {
                Button("Don't want it") { box.setPlayerHas(.skipped); dismiss() }
                Button("Clear") { box.set(cellCurrent: -1, playerHas: .no); dismiss() }
            }
            .font(.caption)
        }
        .padding(10)
        .frame(width: 300)
    }
}
