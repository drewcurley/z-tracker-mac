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

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            tabBar
            if isSummary {
                summaryPlaceholder
            } else {
                HStack(alignment: .top, spacing: 8) {
                    DungeonRoomGridView(map: model.dungeonRoomMaps[selected],
                                        dungeonNumber: selected + 1,
                                        headerText: headerText)
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
            // FQ / SQ vanilla-map-overlay buttons — placeholders (their own slice).
            HStack(spacing: 4) {
                ForEach(["FQ", "SQ"], id: \.self) { q in
                    Button(q) {}
                        .font(.system(size: 12, weight: .semibold))
                        .disabled(true)
                        .help("\(q == "FQ" ? "First" : "Second")-quest vanilla dungeon outline — coming soon")
                }
            }
        }
        .frame(width: Self.contentWidth)
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

    /// Quick per-dungeon reference beside the grid: the old-man count (real) and
    /// reserved room for the local triforce/item inset (its own slice).
    private var dungeonInfoStrip: some View {
        VStack(alignment: .leading, spacing: 8) {
            VStack(alignment: .leading, spacing: 2) {
                Text("OLD MEN").font(.system(size: 8, weight: .semibold)).foregroundStyle(.secondary)
                Text("\(model.dungeonRoomMaps[selected].oldManCount)")
                    .font(.system(size: 18, weight: .heavy, design: .rounded))
                    .foregroundStyle(.orange)
            }
            Divider()
            // Reserved for the local triforce + item boxes (mirrors the top card).
            VStack(spacing: 4) {
                Text("Dungeon\nitems").font(.system(size: 9)).multilineTextAlignment(.center)
                    .foregroundStyle(.secondary)
                Text("(soon)").font(.system(size: 8)).foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, minHeight: 90)
            .background(RoundedRectangle(cornerRadius: 5).fill(Color(white: 0.08)))
            .overlay(RoundedRectangle(cornerRadius: 5).strokeBorder(Color(white: 0.18), style: StrokeStyle(lineWidth: 1, dash: [3, 2])))
            Spacer(minLength: 0)
        }
        .frame(width: Self.infoStripWidth)
    }

    private var summaryPlaceholder: some View {
        VStack(spacing: 6) {
            Text("Summary").font(.headline)
            Text("The all-dungeons overview lands in its own slice.")
                .font(.caption).foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, minHeight: 200)
    }
}

/// One dungeon's 8×8 room grid.
struct DungeonRoomGridView: View {
    @Bindable var map: DungeonRoomMap
    var dungeonNumber: Int
    /// The "LEVEL-N" / "BOARD-N" header, one character centered per column.
    var headerText: String = ""

    /// Cell size — the 13×9 sprite scaled 4× (nearest-neighbor). The `gap` is the
    /// door channel between rooms (the reference's 12px gap at 3×, so 16 at 4×);
    /// doors render there in D3.
    private static let cellW: CGFloat = 52
    private static let cellH: CGFloat = 36
    private static let gap: CGFloat = 16

    /// The grid's natural width: 8 cells + the inter-cell door gaps + the 4pt
    /// padding on each side. The map card uses this to cap its total width so a
    /// wide window grows Blockers/Notes rather than the (fixed-size) grid.
    static let contentWidth: CGFloat = cellW * CGFloat(DungeonRoomMap.cols)
        + gap * CGFloat(DungeonRoomMap.cols - 1) + 8

    var body: some View {
        VStack(spacing: Self.gap) {
            headerRow
            ForEach(0..<DungeonRoomMap.rows, id: \.self) { row in
                HStack(spacing: Self.gap) {
                    ForEach(0..<DungeonRoomMap.cols, id: \.self) { col in
                        RoomCellView(map: map, col: col, row: row,
                                     width: Self.cellW, height: Self.cellH)
                    }
                }
            }
        }
        .padding(4)
        .background(RoundedRectangle(cornerRadius: 6).fill(.black.opacity(0.25)))
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

/// One room cell: the room-type sprite on a completion-tinted background; click
/// opens the room-type picker (D2 will add monsters/floor-drops/doors).
private struct RoomCellView: View {
    @Bindable var map: DungeonRoomMap
    let col: Int
    let row: Int
    let width: CGFloat
    let height: CGFloat
    @State private var showingPicker = false

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
        }
        .frame(width: width, height: height)
        .overlay(RoundedRectangle(cornerRadius: 3).strokeBorder(Color(white: 0.2), lineWidth: 0.5))
        .contentShape(Rectangle())
        // Precise mouse handling (D2a): left = the reference accelerator / cycle /
        // completion toggle; right = the room-type picker. Shift+click details
        // land in D2b.
        .overlay(RoomMouseCatcher { gesture in
            switch gesture {
            case .left: applyLeftClick()
            case .right: showingPicker = true
            case .shiftLeft, .shiftRight, .middle: break   // D2b
            }
        })
        .popover(isPresented: $showingPicker, arrowEdge: .bottom) {
            RoomTypePicker(current: room.roomType) { newType in
                var r = room
                r.roomType = newType
                map.setRoom(r, col: col, row: row)
                map.firstInteractionDone = true
                showingPicker = false
            }
        }
        // VoiceOver (docs/ux.md § Accessibility). Default action = the primary
        // left-click; a named action opens the room-type picker.
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Room column \(col + 1), row \(row + 1)")
        .accessibilityValue(accessibilityValue)
        .accessibilityAddTraits(.isButton)
        .accessibilityAction { applyLeftClick() }
        .accessibilityAction(named: "Set room type") { showingPicker = true }
    }

    /// Apply the reference's plain left-click behavior at this cell.
    private func applyLeftClick() {
        map.leftClick(col: col, row: row)
    }

    private var accessibilityValue: String {
        let type = room.roomType.isNotMarked ? "Unmarked" : room.roomType.displayDescription
        return room.isCompleted ? "\(type), completed" : type
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
