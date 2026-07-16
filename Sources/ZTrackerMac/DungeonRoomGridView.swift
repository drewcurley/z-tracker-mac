import SwiftUI
import TrackerCore

/// The dungeon room-map area (T-019.5, "D1"): a tab strip for dungeons 1–9 and
/// the selected dungeon's 8×8 room grid. First render slice — room-type sprites
/// + a room-type picker to set them; monsters, floor drops, doors, and the rest
/// of the editing gestures are later slices.
struct DungeonMapView: View {
    @Bindable var model: TrackerModel
    var options: TrackerOptions
    /// 0…8 = dungeons 1–9; 9 = the Summary tab.
    @State private var selected = 0
    /// The FQ/SQ vanilla-outline overlay mode (nil = off) — global across all
    /// dungeons: toggling it shows each dungeon's own vanilla footprint (T-071).
    @State private var outlineMode: VanillaQuest? = nil
    /// The grid row the pointer is over (T-078) — set by the grid's room cells,
    /// read by the info strip's row-locator widget.
    @State private var hoveredRow: Int?
    /// The info strip's fixed width (old-men count + reserved dungeon-items box).
    private static let infoStripWidth: CGFloat = 72

    /// The map card's natural content width: the room grid + spacing + info
    /// strip. The card is capped to this so a wide window grows Blockers/Notes,
    /// not the map (the grid can't use extra space). Also the width the tab bar
    /// spreads its dungeon tabs across.
    static let contentWidth: CGFloat = DungeonRoomGridView.contentWidth + 8 + infoStripWidth

    private var isSummary: Bool { selected == 9 }

    private var slotLabel: String {
        DungeonLabeling.slotLabel(selected + 1, hideDungeonNumbers: model.hideDungeonNumbers)
    }

    /// The in-game HUD header ("LEVEL-4" / "BOARD-4" per the flag), spread one
    /// character per grid column so it lines up with the game's on-screen text.
    private var headerText: String {
        "\(options.boardInsteadOfLevel ? "BOARD" : "LEVEL")-\(slotLabel)"
    }

    /// The old-man readout (T-074): "X/Y" (marked / expected), or just "X" in HDN
    /// mode when the slot isn't yet identified (the expected count is then unknown).
    private var oldManText: String {
        let marked = model.dungeonRoomMaps[selected].oldManCount
        guard let expected = expectedOldMen else { return "\(marked)" }
        return "\(marked)/\(expected)"
    }

    /// Expected old men for the selected dungeon, or nil when unknowable (HDN + the
    /// slot has no assigned dungeon number yet). Uses the 1Q/2Q vanilla totals.
    private var expectedOldMen: Int? {
        let secondQuest = model.dungeonTracker.isSecondQuestDungeons
        if model.hideDungeonNumbers {
            guard let n = model.dungeonTracker.dungeon(selected).labelChar.wholeNumberValue,
                  (1...9).contains(n) else { return nil }
            return DungeonOldManCounts.expected(secondQuestDungeons: secondQuest, dungeon: n - 1)
        }
        return DungeonOldManCounts.expected(secondQuestDungeons: secondQuest, dungeon: selected)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            tabBar
            if isSummary {
                DungeonSummaryView(model: model, options: options) { selected = $0 }
            } else {
                HStack(alignment: .top, spacing: 8) {
                    DungeonRoomGridView(map: model.dungeonRoomMaps[selected],
                                        dungeonNumber: selected + 1,
                                        headerText: headerText,
                                        inferDoors: options.doDoorInference,
                                        outlineQuest: outlineMode,
                                        hoveredRow: $hoveredRow)
                    dungeonInfoStrip
                }
            }
        }
        // Cap the whole card at its natural content width; a wider window flows
        // the extra space to Blockers/Notes, not here.
        .frame(width: Self.contentWidth, alignment: .leading)
    }


    /// Level tabs 1–9 + Summary evenly spread across the map width, with the
    /// FQ/SQ vanilla-outline buttons pinned to the right edge.
    private var tabBar: some View {
        HStack(spacing: 0) {
            ForEach(0..<10, id: \.self) { i in
                tab(index: i, label: i == 9 ? "S"
                    : DungeonLabeling.slotLabel(i + 1, hideDungeonNumbers: model.hideDungeonNumbers))
                Spacer(minLength: 6)   // even inter-tab distribution; the last
                                       // one pushes FQ/SQ to the right edge
            }
            // FQ / SQ — toggle the vanilla footprint overlay for this dungeon.
            HStack(spacing: 4) {
                outlineButton("FQ", quest: .first)
                outlineButton("SQ", quest: .second)
            }
        }
        .frame(width: Self.contentWidth)
    }

    private func outlineButton(_ label: String, quest: VanillaQuest) -> some View {
        let active = outlineMode == quest
        return Button {
            outlineMode = active ? nil : quest
        } label: {
            Text(label)
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(active ? .white : .secondary)
                .frame(width: 26, height: 20)
                .background(RoundedRectangle(cornerRadius: 4)
                    .fill(active ? Color(red: 147/255, green: 112/255, blue: 219/255).opacity(0.7) : Color(white: 0.16)))
        }
        .buttonStyle(.plain)
        .disabled(isSummary)
        .help("Overlay the vanilla \(quest == .first ? "first" : "second")-quest layout of this dungeon")
        .accessibilityLabel("\(quest == .first ? "First" : "Second")-quest vanilla outline")
        .accessibilityValue(active ? "Showing" : "Hidden")
    }

    private func tab(index i: Int, label: String) -> some View {
        Button { selected = i } label: {
            Text(label)
                .font(.system(size: 13, weight: .bold, design: .rounded))
                .frame(width: 26, height: 22)
                .background(RoundedRectangle(cornerRadius: 5)
                    .fill(selected == i ? Color.accentColor.opacity(0.5) : Color(white: 0.16)))
        }
        .buttonStyle(.plain)
        .accessibilityLabel(i == 9 ? "Summary" : "Dungeon \(label)")
        .accessibilityAddTraits(selected == i ? [.isButton, .isSelected] : .isButton)
    }

    /// Quick per-dungeon reference beside the grid: the old-man count and the
    /// local triforce/item inset — the selected dungeon's card (triforce + item
    /// boxes), mirroring the top row so items can be marked without scrolling up
    /// (the reference's local dungeon-tracker panel).
    private var dungeonInfoStrip: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Row-locator (T-078): always-visible rupee/key/bomb HUD-row icons; a
            // highlight reveals the hovered room's in-game-map row on hover.
            RowLocatorWidget(hoveredRow: hoveredRow)
            // Old-man count on its own single line (icon + X/Y), like the reference.
            HStack(spacing: 5) {
                if let image = Image(atlasIcon: DungeonMonsterAtlas.oldMan) {
                    image.interpolation(.none).resizable().frame(width: 20, height: 20)
                }
                Text(oldManText)
                    .font(.system(size: 17, weight: .heavy, design: .rounded))
                    .foregroundStyle(.orange)
            }
            .help("Old-man rooms (NPC hint / bomb-upgrade / hungry-goriya / life-or-money) marked vs. the number expected in this dungeon")
            Divider()
            Text("ITEMS").font(.system(size: 8, weight: .semibold)).foregroundStyle(.secondary)
            DungeonCardView(
                dungeon: model.dungeonTracker.dungeon(selected),
                instance: model.dungeonTracker,
                isLocated: DungeonTrackerView.locatedDungeonIndices(in: model.overworldGrid).contains(selected),
                iconOptions: model.iconOptions,
                hideDungeonNumbers: model.hideDungeonNumbers,
                showLocationHeader: false,
                blockers: model.dungeonBlockers,
                chipPlayerState: model.playerComputedStateSummary,
                hint: $model.levelHints[HintTarget.dungeon(selected + 1)]
            )
            .frame(maxWidth: .infinity)
            // Minimap preview (T-079): hover to see the faux in-game HUD map.
            DungeonMinimapHoverIcon(map: model.dungeonRoomMaps[selected], headerText: headerText)
                .frame(maxWidth: .infinity)   // centered in the sidebar
                .padding(.top, 4)
            Spacer(minLength: 0)
        }
        .frame(width: Self.infoStripWidth)
    }

}

/// One dungeon's 8×8 room grid.
struct DungeonRoomGridView: View {
    @Bindable var map: DungeonRoomMap
    var dungeonNumber: Int
    /// The "LEVEL-N" / "BOARD-N" header, one character centered per column.
    var headerText: String = ""
    /// Forwarded to each room cell — auto-open an inferred entry door on marking.
    var inferDoors: Bool = false
    /// When set, overlays this vanilla quest's footprint for this dungeon (FQ/SQ).
    var outlineQuest: VanillaQuest? = nil

    /// Cell size — the 13×9 sprite scaled 4× (nearest-neighbor). The `gap` is the
    /// door channel between rooms (the reference's 12px gap at 3×, so 16 at 4×);
    /// doors render there in D3.
    private static let cellW: CGFloat = 52
    private static let cellH: CGFloat = 36
    private static let gap: CGFloat = 16

    /// Which grid row the pointer is over (nil = not hovering) — drives the
    /// row-locator widget in the info strip (T-078). Owned by `DungeonMapView`
    /// so the grid (hover source) and the info-strip widget share it.
    @Binding var hoveredRow: Int?

    /// The grid's natural width: 8 cells + the inter-cell door gaps + the 4pt
    /// padding on each side. The map card uses this to cap its total width so a
    /// wide window grows Blockers/Notes rather than the (fixed-size) grid.
    static let contentWidth: CGFloat = cellW * CGFloat(DungeonRoomMap.cols)
        + gap * CGFloat(DungeonRoomMap.cols - 1) + 8

    /// Column pitch / row pitch (cell + one gap).
    private static var pitchX: CGFloat { cellW + gap }
    private static var pitchY: CGFloat { cellH + gap }
    private static var roomsW: CGFloat { cellW * CGFloat(DungeonRoomMap.cols) + gap * CGFloat(DungeonRoomMap.cols - 1) }
    private static var roomsH: CGFloat { cellH * CGFloat(DungeonRoomMap.rows) + gap * CGFloat(DungeonRoomMap.rows - 1) }

    var body: some View {
        VStack(alignment: .leading, spacing: Self.gap) {
            headerRow
            roomsAndDoors
        }
        .padding(4)
        .background(RoundedRectangle(cornerRadius: 6).fill(.black.opacity(0.25)))
    }

    /// Rooms and the door segments in the gaps between them, absolutely placed in
    /// one coordinate system (D3) — doors need to live in the gaps, which a plain
    /// stack layout can't address.
    private var roomsAndDoors: some View {
        ZStack(alignment: .topLeading) {
            ForEach(0..<DungeonRoomMap.rows, id: \.self) { row in
                ForEach(0..<DungeonRoomMap.cols, id: \.self) { col in
                    RoomCellView(map: map, col: col, row: row,
                                 width: Self.cellW, height: Self.cellH,
                                 pitchX: Self.pitchX, pitchY: Self.pitchY, inferDoors: inferDoors,
                                 onHover: { hovering in
                                     if hovering { hoveredRow = row }
                                     else if hoveredRow == row { hoveredRow = nil }
                                 })
                        .offset(x: CGFloat(col) * Self.pitchX, y: CGFloat(row) * Self.pitchY)
                }
            }
            // Horizontal-axis doors (vertical walls) — between columns i and i+1.
            ForEach(0..<(DungeonRoomMap.cols - 1), id: \.self) { i in
                ForEach(0..<DungeonRoomMap.rows, id: \.self) { j in
                    DungeonDoorView(map: map, axis: .horizontal, col: i, row: j,
                                    frameW: Self.gap, frameH: 22)
                        .offset(x: CGFloat(i) * Self.pitchX + Self.cellW,
                                y: CGFloat(j) * Self.pitchY + (Self.cellH - 22) / 2)
                }
            }
            // Vertical-axis doors (horizontal walls) — between rows j and j+1.
            ForEach(0..<DungeonRoomMap.cols, id: \.self) { i in
                ForEach(0..<(DungeonRoomMap.rows - 1), id: \.self) { j in
                    DungeonDoorView(map: map, axis: .vertical, col: i, row: j,
                                    frameW: 28, frameH: Self.gap)
                        .offset(x: CGFloat(i) * Self.pitchX + (Self.cellW - 28) / 2,
                                y: CGFloat(j) * Self.pitchY + Self.cellH)
                }
            }
            // FQ/SQ vanilla footprint overlay (T-071), on top of rooms/doors.
            if let outlineQuest {
                VanillaOutlineOverlay(quest: outlineQuest, dungeon: dungeonNumber - 1,
                                      cellW: Self.cellW, cellH: Self.cellH, gap: Self.gap)
            }
        }
        .frame(width: Self.roomsW, height: Self.roomsH, alignment: .topLeading)
    }

    /// The header letters spread one-per-column (`LEVEL-1` over columns 0…6), so
    /// the text lines up with the room columns as in the reference.
    private var headerRow: some View {
        let chars = Array(headerText)
        return HStack(spacing: Self.gap) {
            ForEach(0..<DungeonRoomMap.cols, id: \.self) { col in
                Text(col < chars.count ? String(chars[col]) : " ")
                    .font(.system(size: 22, weight: .heavy, design: .monospaced))
                    .foregroundStyle(.white)
                    .frame(width: Self.cellW)
            }
        }
        .accessibilityElement()
        .accessibilityLabel(headerText)
    }
}

/// One room cell: the room-type sprite on a completion-tinted background, with
/// the monster (top-left) and floor-drop (bottom-right) detail overlays and the
/// "circled" ring. Left = accelerator/cycle/toggle, right = room-type picker,
/// Shift+left = monster, Shift+right = floor drop, middle = circle / brightness.
private struct RoomCellView: View {
    @Bindable var map: DungeonRoomMap
    let col: Int
    let row: Int
    let width: CGFloat
    let height: CGFloat
    /// Column/row pitch (cell + gap) — lets a drag map the cursor to a room.
    let pitchX: CGFloat
    let pitchY: CGFloat
    /// Door inference (T-019.12): auto-open the inferred entry door when this room
    /// is newly marked. Gated by the `doDoorInference` option upstream.
    var inferDoors: Bool = false
    /// Reports hover enter/leave for the row-locator (T-078).
    var onHover: (Bool) -> Void = { _ in }
    @State private var showingPicker = false
    @State private var showingMonster = false
    @State private var showingFloorDrop = false

    /// Dim factor for a "handled" detail (completed monster / collected drop) —
    /// the reference's `DARKEN = 0.5` black overlay, as an opacity here.
    private static let dim: Double = 0.4
    private static let detailIcon: CGFloat = 20

    private var room: DungeonRoom { map.room(col: col, row: row) }

    var body: some View {
        ZStack {
            // Off-map rooms read as a dark "not part of this dungeon" cell.
            RoundedRectangle(cornerRadius: 3)
                .fill(room.roomType == .offTheMap ? Color.black.opacity(0.6) : Color(white: 0.10))
            if let sprite = DungeonRoomSpriteAtlas.sprite(room.roomType, completed: room.isCompleted),
               let image = Image(atlasIcon: sprite) {
                image.interpolation(.none).resizable()
                    .frame(width: width - 4, height: height - 4)
            }
            // Monster (top-leading), dimmed on a completed room unless it's a
            // persistent hazard (bubbles / traps / "other").
            if let image = Image(atlasIcon: DungeonMonsterAtlas.sprite(room.monsterDetail)) {
                image.interpolation(.none).resizable()
                    .frame(width: Self.detailIcon, height: Self.detailIcon)
                    .opacity(room.isCompleted && room.monsterDetail.darkensWhenCompleted ? Self.dim : 1)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                    .offset(x: -2, y: -2)
                    .allowsHitTesting(false)
            }
            // Floor drop (bottom-trailing), dimmed when marked "already collected".
            if let image = Image(atlasIcon: DungeonFloorDropAtlas.sprite(room.floorDropDetail)) {
                image.interpolation(.none).resizable()
                    .frame(width: Self.detailIcon, height: Self.detailIcon)
                    .opacity(room.floorDropAppearsBright ? 1 : Self.dim)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomTrailing)
                    .offset(x: 2, y: 2)
                    .allowsHitTesting(false)
            }
        }
        .frame(width: width, height: height)
        .onHover { onHover($0) }   // row-locator reveal (T-078)
        .overlay(RoundedRectangle(cornerRadius: 3).strokeBorder(Color(white: 0.2), lineWidth: 0.5))
        // The "circled" ring — a yellow dashed ellipse overhanging the cell
        // (reference `Brushes.Yellow`, dashed, slightly larger than the room).
        .overlay {
            if map.isCircled(col: col, row: row) {
                Ellipse()
                    .stroke(Color.yellow, style: StrokeStyle(lineWidth: 2, dash: [1.5, 4]))
                    .padding(-3)
                    .allowsHitTesting(false)
            }
        }
        .contentShape(Rectangle())
        // Precise mouse handling: left = accelerator / cycle / completion toggle;
        // right = room-type picker; Shift+left = monster; Shift+right = floor
        // drop; middle = circle (no drop) / floor-drop brightness.
        .overlay(RoomMouseCatcher(
            onGesture: { gesture in
                switch gesture {
                case .left: markWithInference()
                case .right: showingPicker = true
                // Scroll (Windows wheel) and Shift+click both open the detail pickers:
                // up/Shift-left = monster, down/Shift-right = floor drop.
                case .shiftLeft, .scrollUp: showingMonster = true
                case .shiftRight, .scrollDown: showingFloorDrop = true
                // ⌥-click stands in for the reference middle-click (no middle button).
                case .middle, .optionLeft: map.middleClick(col: col, row: row)
                }
            },
            // Drag-paint (T-072): left over off-map → unmarked, right over unmarked
            // → off-map, ⌥/middle over unmarked → default. Clicks fire on release.
            dragContext: .init(col: col, row: row, pitchX: pitchX, pitchY: pitchY),
            onDragPaint: { button, c, r in map.dragPaint(button, col: c, row: r) }
        ))
        .popover(isPresented: $showingPicker, arrowEdge: .bottom) {
            RoomTypePicker(current: room.roomType) { newType in
                let wasUnmarked = room.roomType.isNotMarked
                var r = room
                r.roomType = newType
                map.setRoom(r, col: col, row: row)
                map.firstInteractionDone = true
                if inferDoors, wasUnmarked { map.inferEntryDoor(col: col, row: row) }
                showingPicker = false
            }
        }
        .popover(isPresented: $showingMonster, arrowEdge: .bottom) {
            MonsterPicker(current: room.monsterDetail) { md in
                var r = room; r.monsterDetail = md
                map.setRoom(r, col: col, row: row)
                showingMonster = false
            }
        }
        .popover(isPresented: $showingFloorDrop, arrowEdge: .bottom) {
            FloorDropPicker(current: room.floorDropDetail) { fd in
                var r = room; r.floorDropDetail = fd
                map.setRoom(r, col: col, row: row)
                showingFloorDrop = false
            }
        }
        // VoiceOver (docs/ux.md § Accessibility). Default action = the primary
        // left-click; named actions open each detail picker.
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Room column \(col + 1), row \(row + 1)")
        .accessibilityValue(accessibilityValue)
        .accessibilityAddTraits(.isButton)
        .accessibilityAction { markWithInference() }
        .accessibilityAction(named: "Set room type") { showingPicker = true }
        .accessibilityAction(named: "Set monster") { showingMonster = true }
        .accessibilityAction(named: "Set floor drop") { showingFloorDrop = true }
        .accessibilityAction(named: "Toggle circle or drop brightness") { map.middleClick(col: col, row: row) }
    }

    /// Primary left-click: mark the room, then (if enabled) infer its entry door.
    /// Shared by the mouse gesture and the VoiceOver default action.
    private func markWithInference() {
        let wasUnmarked = room.roomType.isNotMarked
        map.leftClick(col: col, row: row)
        if inferDoors, wasUnmarked { map.inferEntryDoor(col: col, row: row) }
    }

    private var accessibilityValue: String {
        var parts: [String] = [room.roomType.isNotMarked ? "Unmarked" : room.roomType.displayDescription]
        if room.isCompleted { parts.append("completed") }
        if !room.monsterDetail.isNotMarked { parts.append("monster \(room.monsterDetail.displayName)") }
        if !room.floorDropDetail.isNotMarked {
            parts.append("drop \(room.floorDropDetail.displayName)\(room.floorDropAppearsBright ? "" : ", collected")")
        }
        if map.isCircled(col: col, row: row) { parts.append("circled") }
        return parts.joined(separator: ", ")
    }
}

/// The room-type picker — the reference's exact 7×5 grid order
/// (`DungeonPopups.fs:254-261`). `unmarked` (the empty room / "clear") sits in
/// the grid; the trailing cell is empty padding.
private struct RoomTypePicker: View {
    let current: RoomType
    let onPick: (RoomType) -> Void

    /// The reference `grid` array, row-major (7 wide × 5 tall). `nil` = the
    /// trailing padding cell.
    private static let order: [RoomType?] = [
        .doubleMoat, .circleMoat, .lifeOrMoney, .bombUpgrade, .hungryGoriyaMeatBlock, .startEnterFromE, .gannon,
        .topMoat, .chevy, .oldManHint, .vChute, .hChute, .startEnterFromN, .zelda,
        .rightMoat, .unmarked, .maybePushBlock, .nonDescript, .tee, .startEnterFromS, .lavaMoat,
        .itemBasement, .staircaseToUnknown, .transport1, .transport2, .transport3, .startEnterFromW, .offTheMap,
        .transport4, .transport5, .transport6, .transport7, .transport8, .turnstile, nil,
    ]
    private let columns = Array(repeating: GridItem(.fixed(44), spacing: 4), count: 7)

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Select a room type").font(.caption).foregroundStyle(.secondary)
            LazyVGrid(columns: columns, spacing: 4) {
                ForEach(Array(Self.order.enumerated()), id: \.offset) { _, entry in
                    if let type = entry {
                        Button { onPick(type) } label: {
                            ZStack {
                                RoundedRectangle(cornerRadius: 4)
                                    .fill(current == type ? Color.accentColor.opacity(0.5) : Color(white: 0.14))
                                if let sprite = DungeonRoomSpriteAtlas.sprite(type, completed: false),
                                   let image = Image(atlasIcon: sprite) {
                                    image.interpolation(.none).resizable().frame(width: 39, height: 27)
                                }
                            }
                            .frame(width: 44, height: 32)
                        }
                        .buttonStyle(.plain)
                        .help(type == .unmarked ? "Unmarked (clear)" : type.displayDescription)
                        .accessibilityLabel(type == .unmarked ? "Unmarked" : type.displayDescription)
                    } else {
                        Color.clear.frame(width: 44, height: 32)
                    }
                }
            }
        }
        .padding(10)
        .frame(width: 360)
    }
}

/// The monster-detail picker (Shift+left-click) — the reference's 8×4 grid order
/// (`MonsterDetail.All()`, `DungeonRoomState.fs:164-167`); `unmarked` (clear) is
/// the last cell.
private struct MonsterPicker: View {
    let current: MonsterDetail
    let onPick: (MonsterDetail) -> Void
    private let columns = Array(repeating: GridItem(.fixed(30), spacing: 4), count: 8)

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Select a monster").font(.caption).foregroundStyle(.secondary)
            LazyVGrid(columns: columns, spacing: 4) {
                ForEach(Array(MonsterDetail.allInPickerOrder.enumerated()), id: \.offset) { _, md in
                    Button { onPick(md) } label: {
                        ZStack {
                            RoundedRectangle(cornerRadius: 4)
                                .fill(current == md ? Color.accentColor.opacity(0.5) : Color(white: 0.14))
                            if md == .unmarked {
                                Image(systemName: "xmark").font(.system(size: 11)).foregroundStyle(.secondary)
                            } else if let image = Image(atlasIcon: DungeonMonsterAtlas.sprite(md)) {
                                image.interpolation(.none).resizable().frame(width: 22, height: 22)
                            }
                        }
                        .frame(width: 30, height: 30)
                    }
                    .buttonStyle(.plain)
                    .help(md == .unmarked ? "None (clear)" : md.displayName)
                    .accessibilityLabel(md == .unmarked ? "None" : md.displayName)
                }
            }
        }
        .padding(10)
        .frame(width: 300)
    }
}

/// The floor-drop picker (Shift+right-click) — the reference's 3×3 grid order
/// (`FloorDropDetail.All()`, `DungeonRoomState.fs:221-222`); `unmarked` (clear)
/// is the last cell.
private struct FloorDropPicker: View {
    let current: FloorDropDetail
    let onPick: (FloorDropDetail) -> Void
    private let columns = Array(repeating: GridItem(.fixed(34), spacing: 6), count: 3)

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Select a floor drop").font(.caption).foregroundStyle(.secondary)
            LazyVGrid(columns: columns, spacing: 6) {
                ForEach(Array(FloorDropDetail.allInPickerOrder.enumerated()), id: \.offset) { _, fd in
                    Button { onPick(fd) } label: {
                        ZStack {
                            RoundedRectangle(cornerRadius: 4)
                                .fill(current == fd ? Color.accentColor.opacity(0.5) : Color(white: 0.14))
                            if fd == .unmarked {
                                Image(systemName: "xmark").font(.system(size: 12)).foregroundStyle(.secondary)
                            } else if let image = Image(atlasIcon: DungeonFloorDropAtlas.sprite(fd)) {
                                image.interpolation(.none).resizable().frame(width: 24, height: 24)
                            }
                        }
                        .frame(width: 34, height: 34)
                    }
                    .buttonStyle(.plain)
                    .help(fd == .unmarked ? "None (clear)" : fd.displayName)
                    .accessibilityLabel(fd == .unmarked ? "None" : fd.displayName)
                }
            }
        }
        .padding(10)
        .frame(width: 150)
    }
}
