import SwiftUI
import TrackerCore

/// The dungeon room-map area (T-019.5, "D1"): a tab strip for dungeons 1–9 and
/// the selected dungeon's 8×8 room grid. First render slice — room-type sprites
/// + a room-type picker to set them; monsters, floor drops, doors, and the rest
/// of the editing gestures are later slices.
struct DungeonMapView: View {
    @Bindable var model: TrackerModel
    var options: TrackerOptions
    /// The visible tab (0…8 = dungeons 1–9, 9 = Summary), owned by the shared focus
    /// state (T-133) so Global `DungeonTab*` hotkeys can switch it and it survives
    /// the band's reflow.
    @Bindable var focus: TrackerFocusState
    private var selected: Int {
        get { focus.selectedDungeonTab }
        nonmutating set { focus.selectedDungeonTab = newValue }
    }
    /// The FQ/SQ vanilla-outline overlay mode (nil = off) — global across all
    /// dungeons: toggling it shows each dungeon's own vanilla footprint (T-071).
    @State private var outlineMode: VanillaQuest? = nil
    /// The grid row the pointer is over (T-078) — set by the grid's room cells,
    /// read by the info strip's row-locator widget.
    @State private var hoveredRow: Int?
    /// The GRAB cut-and-paste tool's transient state (T-083).
    @State private var grab = DungeonGrabController()
    /// Room-grid zoom (T-127) — shrinks the map to reclaim vertical space; the tab
    /// bar and controls stay full size. Owned by `DungeonBandView` (T-129) so it
    /// survives the band's reflow (a `ViewThatFits`/layout swap would otherwise
    /// recreate this view and reset the zoom). Discrete levels 60/80/100/120%.
    @Binding var mapScale: CGFloat
    static let zoomLevels: [CGFloat] = [0.6, 0.8, 1.0, 1.2]
    /// Step to the adjacent zoom level (dir −1/+1), clamped to the ends.
    private func stepZoom(_ dir: Int) {
        let i = Self.zoomLevels.firstIndex(of: mapScale) ?? Self.zoomLevels.firstIndex(of: 1.0)!
        mapScale = Self.zoomLevels[min(Self.zoomLevels.count - 1, max(0, i + dir))]
    }
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

    /// The in-game HUD header ("LEVEL-4" / "BOARD-4" per the flag, "LEVEL-A" under
    /// HDN), spread one character per grid column so it lines up with the game's
    /// on-screen text. Shares `DungeonLabeling.columnName` with the overworld
    /// picker so all dungeon naming agrees (T-112).
    private var headerText: String {
        DungeonLabeling.columnName(slot: selected + 1,
                                   boardInsteadOfLevel: options.boardInsteadOfLevel,
                                   hideDungeonNumbers: model.hideDungeonNumbers)
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
                if grab.isGrabMode { grabBanner }
                HStack(alignment: .top, spacing: 8) {
                    DungeonRoomGridView(map: model.dungeonRoomMaps[selected],
                                        dungeonNumber: selected + 1,
                                        headerText: headerText,
                                        inferDoors: options.doDoorInference,
                                        outlineQuest: outlineMode,
                                        hoveredRow: $hoveredRow,
                                        grab: grab,
                                        focus: focus)
                    dungeonInfoStrip
                }
            }
        }
        // Cap the whole card at its natural content width; a wider window flows
        // the extra space to Blockers/Notes, not here.
        .frame(width: Self.contentWidth, alignment: .leading)
        // Zoom the whole card to reclaim vertical space (T-127) — the Summary tab is
        // not scaled. Passing the known natural width keeps the dungeon band's
        // side-by-side reflow deterministic while zoomed. The zoom control overlays
        // at full size (bottom-trailing, where the card has empty space).
        .scaledFootprint(isSummary ? 1 : mapScale, naturalWidth: Self.contentWidth)
        .overlay(alignment: .bottomTrailing) { if !isSummary { zoomControl } }
        // Leaving a dungeon tab cancels any in-progress grab (reference behavior).
        .onChange(of: selected) { _, _ in grab.abort() }
        // Keep / undo prompt after a drop (reference's "Verify changes" dialog).
        .confirmationDialog("You moved a dungeon segment. Keep this change?",
                            isPresented: $grab.pendingConfirm, titleVisibility: .visible) {
            Button("Keep changes") { grab.keepChanges() }
            Button("Undo", role: .cancel) { grab.undoChanges(map: model.dungeonRoomMaps[selected]) }
        }
    }

    /// The map-zoom control (T-127/T-129) — two larger −/+ buttons spanning the
    /// info-strip width, with the current % (tap to reset to 100). Overlaid in the
    /// card's bottom-trailing corner (the info strip's empty space) at full size.
    private var zoomControl: some View {
        VStack(spacing: 1) {
            Button { mapScale = 1 } label: {
                Text("\(Int(mapScale * 100))%").font(.system(size: 9, weight: .semibold, design: .monospaced))
            }
            .help("Reset zoom to 100%")
            HStack(spacing: 3) {
                Button { stepZoom(-1) } label: {
                    Image(systemName: "minus.magnifyingglass").frame(maxWidth: .infinity)
                }
                .disabled(mapScale <= Self.zoomLevels.first!)
                Button { stepZoom(1) } label: {
                    Image(systemName: "plus.magnifyingglass").frame(maxWidth: .infinity)
                }
                .disabled(mapScale >= Self.zoomLevels.last!)
            }
            .font(.system(size: 15))
        }
        .buttonStyle(.plain)
        .foregroundStyle(.secondary)
        .frame(width: Self.infoStripWidth)
        .padding(.vertical, 3)
        .background(.black.opacity(0.5), in: RoundedRectangle(cornerRadius: 5))
        .padding(2)
        .help("Zoom the dungeon map")
    }

    /// The grab-mode instruction banner (reference `grabModeTextBlock`).
    private var grabBanner: some View {
        Text(grab.hasGrab
             ? "GRAB: click a destination to drop the segment (yellow = would overwrite). Click GRAB again to cancel."
             : "GRAB: click a marked room to pick up its connected segment. Click GRAB again to cancel.")
            .font(.system(size: 10, weight: .medium))
            .foregroundStyle(.white)
            .padding(.horizontal, 8).padding(.vertical, 4)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(RoundedRectangle(cornerRadius: 5).fill(Color.red.opacity(0.55)))
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
                grabButton
                outlineButton("FQ", quest: .first)
                outlineButton("SQ", quest: .second)
            }
        }
        .frame(width: Self.contentWidth)
    }

    /// The GRAB toggle (reference's per-tab GRAB button): red when armed. Moves a
    /// connected segment of rooms + doors as a cut-and-paste.
    private var grabButton: some View {
        Button { grab.toggle() } label: {
            Text("GRAB")
                .font(.system(size: 11, weight: .heavy))
                .foregroundStyle(grab.isGrabMode ? .white : .secondary)
                .frame(width: 40, height: 20)
                .background(RoundedRectangle(cornerRadius: 4)
                    .fill(grab.isGrabMode ? Color.red.opacity(0.85) : Color(white: 0.16)))
        }
        .buttonStyle(.plain)
        .disabled(isSummary)
        .help("Grab mode: move a connected segment of dungeon rooms and doors at once (cut & paste, with keep/undo).")
        .accessibilityLabel("Grab mode")
        .accessibilityValue(grab.isGrabMode ? "On" : "Off")
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
                .font(.system(size: 14, weight: .bold, design: .rounded))
                // Wider than the label needs (T-087) so the "needs" markers — the
                // bait icon at the leading edge and the dots trailing — have room
                // to sit clear of the centered number without crowding.
                .frame(width: 38, height: 24)
                .background(RoundedRectangle(cornerRadius: 5)
                    .fill(selected == i ? Color.accentColor.opacity(0.5) : Color(white: 0.16)))
                .overlay { if i < 9 { tabNeedsMarkers(dungeon: i) } }
        }
        .buttonStyle(.plain)
        .accessibilityLabel(i == 9 ? "Summary" : "Dungeon \(label)")
        .accessibilityValue(i < 9 ? tabNeedsA11y(dungeon: i) : "")
        .accessibilityAddTraits(selected == i ? [.isButton, .isSelected] : .isButton)
    }

    /// The "what this dungeon needs" markers overlaid on a dungeon tab (T-084):
    /// a bait-meat icon (Hungry-Goriya, lime-checked once fed) at the leading edge,
    /// a DodgerBlue dot (unbought Bomb-Upgrade) top-trailing, and a red dot (unread
    /// NPC hint — only with the "book for hints" option) bottom-trailing.
    @ViewBuilder
    private func tabNeedsMarkers(dungeon i: Int) -> some View {
        let map = model.dungeonRoomMaps[i]
        ZStack {
            if map.hasHungryGoriya {
                ZStack(alignment: .bottomTrailing) {
                    if let img = Image(atlasIcon: ItemIconAtlas.cgImage(.bait)) {
                        img.interpolation(.none).resizable().frame(width: 13, height: 13)
                    }
                    if map.hungryGoriyaFed {
                        Image(systemName: "checkmark")
                            .font(.system(size: 7, weight: .heavy)).foregroundStyle(.green)
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
                .offset(x: 1)
            }
            VStack(spacing: 3) {
                dot(Color(red: 30/255, green: 144/255, blue: 255/255), on: map.hasUnboughtBombUpgrade)  // DodgerBlue
                dot(.red, on: options.bookForHelpfulHints && map.hasUnreadOldManHint)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .trailing)
            .offset(x: -1)
        }
        .allowsHitTesting(false)
    }

    private func dot(_ color: Color, on: Bool) -> some View {
        Circle().fill(on ? color : .clear).frame(width: 6, height: 6)
    }

    private func tabNeedsA11y(dungeon i: Int) -> String {
        let map = model.dungeonRoomMaps[i]
        var parts: [String] = []
        if map.hasHungryGoriya { parts.append(map.hungryGoriyaFed ? "hungry goriya fed" : "needs meat") }
        if map.hasUnboughtBombUpgrade { parts.append("bomb upgrade available") }
        if options.bookForHelpfulHints && map.hasUnreadOldManHint { parts.append("unread hint") }
        return parts.joined(separator: ", ")
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

/// Which detail picker a room cell requested (T-145).
enum RoomPickerKind: Equatable { case roomType, monster, floorDrop }

/// A request to open a detail picker anchored at a specific room cell. Lifted to
/// the grid (T-145) so all 64 cells share **one** popover per kind (3 total)
/// instead of each carrying its own three (192 popover anchors) — that
/// proliferation was slow to present (~500 ms) and crash-prone on macOS 27.
private struct RoomPickerRequest: Identifiable, Equatable {
    let col: Int
    let row: Int
    let kind: RoomPickerKind
    var id: String { "\(col).\(row).\(kind)" }
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

    /// Cell size (T-127 — trimmed ~12% from the original 52×36×16 so the dungeon
    /// map + blockers + notes fit side-by-side at a narrower window; the map's zoom
    /// control grows it back for detail). The `gap` is the door channel between
    /// rooms; doors render there in D3.
    private static let cellW: CGFloat = 46
    private static let cellH: CGFloat = 32
    private static let gap: CGFloat = 14
    /// Door segment lengths across a cell edge (derived from the cell so they track
    /// the trimmed size): horizontal-axis door along the cell height, vertical-axis
    /// door along the cell width.
    private static let hDoorLen: CGFloat = 20
    private static let vDoorLen: CGFloat = 25

    /// Which grid row the pointer is over (nil = not hovering) — drives the
    /// row-locator widget in the info strip (T-078). Owned by `DungeonMapView`
    /// so the grid (hover source) and the info-strip widget share it.
    @Binding var hoveredRow: Int?
    /// The GRAB tool state (T-083) — when armed, cells route clicks/hover to it
    /// and paint the pick-up / drop preview.
    var grab: DungeonGrabController
    /// Shared focus state (T-134) — the keyboard cursor follows hover here and is
    /// drawn on the cursor room when the cursor is on the dungeon grid.
    @Bindable var focus: TrackerFocusState

    /// The single active detail-picker request (T-145). Grid-level so there are
    /// three popovers total, not three per cell.
    @State private var activePicker: RoomPickerRequest?

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
                                 grab: grab,
                                 onHover: { hovering in
                                     if hovering {
                                         hoveredRow = row
                                         focus.hoverDungeon(col: col, row: row)   // cursor follows (T-134)
                                         if grab.isGrabMode { grab.hoverCell = .init(col: col, row: row) }
                                     } else {
                                         if hoveredRow == row { hoveredRow = nil }
                                         focus.endHover(.dungeonMap)
                                         if grab.hoverCell == .init(col: col, row: row) { grab.hoverCell = nil }
                                     }
                                 },
                                 onPick: { kind in
                                     // Present without the popover's fade/expand animation so it
                                     // snaps in immediately (T-145) — the animation is the bulk of
                                     // the perceived open delay.
                                     presentPopoverWithoutAnimation {
                                         activePicker = RoomPickerRequest(col: col, row: row, kind: kind)
                                     }
                                 })
                        .overlay {
                            // Keyboard cursor (T-134): bright ring on the cursor room
                            // while the cursor is on the dungeon grid.
                            if focus.cursorShown, focus.cursorRegion == .dungeonMap,
                               focus.dungeonCursor == .init(col: col, row: row) {
                                RoundedRectangle(cornerRadius: 3)
                                    .strokeBorder(Color.cyan, lineWidth: 2)
                                    .shadow(color: .cyan, radius: 2)
                                    .frame(width: Self.cellW, height: Self.cellH)
                                    .allowsHitTesting(false)
                            }
                        }
                        .offset(x: CGFloat(col) * Self.pitchX, y: CGFloat(row) * Self.pitchY)
                }
            }
            // Horizontal-axis doors (vertical walls) — between columns i and i+1.
            ForEach(0..<(DungeonRoomMap.cols - 1), id: \.self) { i in
                ForEach(0..<DungeonRoomMap.rows, id: \.self) { j in
                    DungeonDoorView(map: map, axis: .horizontal, col: i, row: j,
                                    frameW: Self.gap, frameH: Self.hDoorLen)
                        .allowsHitTesting(!grab.isGrabMode)
                        .offset(x: CGFloat(i) * Self.pitchX + Self.cellW,
                                y: CGFloat(j) * Self.pitchY + (Self.cellH - Self.hDoorLen) / 2)
                }
            }
            // Vertical-axis doors (horizontal walls) — between rows j and j+1.
            ForEach(0..<DungeonRoomMap.cols, id: \.self) { i in
                ForEach(0..<(DungeonRoomMap.rows - 1), id: \.self) { j in
                    DungeonDoorView(map: map, axis: .vertical, col: i, row: j,
                                    frameW: Self.vDoorLen, frameH: Self.gap)
                        .allowsHitTesting(!grab.isGrabMode)
                        .offset(x: CGFloat(i) * Self.pitchX + (Self.cellW - Self.vDoorLen) / 2,
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
        // Three grid-level popovers (T-145), each anchored to whichever cell is
        // active — replacing 3-per-cell (192 total). Same behaviour: right =
        // room type, shift+left/scroll-up = monster (stays open to add a 2nd),
        // shift+right/scroll-down = floor drop.
        .popover(isPresented: pickerPresented(.roomType),
                 attachmentAnchor: .rect(.rect(activeCellRect)), arrowEdge: .bottom) {
            if let req = activePicker {
                RoomTypePicker(current: map.room(col: req.col, row: req.row).roomType) { newType in
                    DungeonRoomMark.applyRoomType(newType, col: req.col, row: req.row,
                                                  map: map, inferDoors: inferDoors)
                    activePicker = nil
                }
            }
        }
        .popover(isPresented: pickerPresented(.monster),
                 attachmentAnchor: .rect(.rect(activeCellRect)), arrowEdge: .bottom) {
            if let req = activePicker {
                let r = map.room(col: req.col, row: req.row)
                MonsterPicker(primary: r.monsterDetail, secondary: r.monsterDetail2,
                              onToggle: { md in
                                  DungeonRoomMark.toggleMonster(md, col: req.col, row: req.row, map: map)
                                  if md.isNotMarked { activePicker = nil }   // clearing dismisses (T-116)
                              },
                              onDone: { activePicker = nil })
            }
        }
        .popover(isPresented: pickerPresented(.floorDrop),
                 attachmentAnchor: .rect(.rect(activeCellRect)), arrowEdge: .bottom) {
            if let req = activePicker {
                FloorDropPicker(current: map.room(col: req.col, row: req.row).floorDropDetail) { fd in
                    DungeonRoomMark.setFloorDrop(fd, col: req.col, row: req.row, map: map)
                    activePicker = nil
                }
            }
        }
    }

    /// A presentation binding for one picker kind: true iff that kind is the
    /// active request; setting false (dismiss) clears it.
    private func pickerPresented(_ kind: RoomPickerKind) -> Binding<Bool> {
        Binding(get: { activePicker?.kind == kind },
                set: { shown in if !shown, activePicker?.kind == kind { activePicker = nil } })
    }

    /// The active cell's rect in the rooms/doors coordinate space (top-left
    /// origin), so the shared popover's arrow points at the right room.
    private var activeCellRect: CGRect {
        guard let p = activePicker else { return .zero }
        return CGRect(x: CGFloat(p.col) * Self.pitchX, y: CGFloat(p.row) * Self.pitchY,
                      width: Self.cellW, height: Self.cellH)
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
    /// The GRAB tool state (T-083) — routes clicks and paints the preview.
    var grab: DungeonGrabController
    /// Reports hover enter/leave for the row-locator (T-078).
    var onHover: (Bool) -> Void = { _ in }
    /// Requests a detail picker for this cell — the grid owns the (shared) popover
    /// state and anchors it here (T-145).
    var onPick: (RoomPickerKind) -> Void = { _ in }

    /// Dim factor for a "handled" detail (completed monster / collected drop) —
    /// the reference's `DARKEN = 0.5` black overlay, as an opacity here.
    private static let dim: Double = 0.4
    private static let detailIcon: CGFloat = 20

    private var room: DungeonRoom { map.room(col: col, row: row) }

    /// The GRAB preview tint for this cell (nil = none).
    private var grabHighlightColor: Color? {
        switch grab.highlight(col: col, row: row, map: map) {
        case .none: nil
        case .source: Color(red: 1, green: 0.4, blue: 0.7)   // pink source segment
        case .preview: .green                                 // pick-up preview
        case .ok: .green                                      // valid drop
        case .warn: .yellow                                   // would overwrite
        }
    }

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
            // Monster(s) (top-leading), dimmed on a completed room unless it's a
            // persistent hazard (bubbles / traps / "other"). Up to two stack
            // vertically (T-116).
            VStack(alignment: .leading, spacing: 0) {
                ForEach(Array(room.monsters.enumerated()), id: \.offset) { _, monster in
                    if let image = Image(atlasIcon: DungeonMonsterAtlas.sprite(monster)) {
                        image.interpolation(.none).resizable()
                            .frame(width: Self.detailIcon, height: Self.detailIcon)
                            .opacity(room.isCompleted && monster.darkensWhenCompleted ? Self.dim : 1)
                    }
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            .offset(x: -2, y: -2)
            .allowsHitTesting(false)
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
        // GRAB preview tint (T-083): pink source, lime pick-up preview / valid
        // drop, yellow "would overwrite".
        .overlay {
            if let color = grabHighlightColor {
                RoundedRectangle(cornerRadius: 3).fill(color.opacity(0.4))
                    .overlay(RoundedRectangle(cornerRadius: 3).strokeBorder(color, lineWidth: 2))
                    .allowsHitTesting(false)
            }
        }
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
                // In grab mode every gesture is a grab pick-up / drop; the normal
                // room-editing gestures are suppressed (reference behavior).
                if grab.isGrabMode {
                    if case .left = gesture { grab.handleClick(col: col, row: row, map: map) }
                    return
                }
                switch gesture {
                case .left: markWithInference()
                case .right: onPick(.roomType)
                // Scroll (Windows wheel) and Shift+click both open the detail pickers:
                // up/Shift-left = monster, down/Shift-right = floor drop.
                case .shiftLeft, .scrollUp: onPick(.monster)
                case .shiftRight, .scrollDown: onPick(.floorDrop)
                // ⌥-click stands in for the reference middle-click (no middle button).
                case .middle, .optionLeft: map.middleClick(col: col, row: row)
                }
            },
            // Drag-paint (T-072): left over off-map → unmarked, right over unmarked
            // → off-map, ⌥/middle over unmarked → default. Clicks fire on release.
            // Disabled in grab mode (a drag there would fight the grab click).
            dragContext: .init(col: col, row: row, pitchX: pitchX, pitchY: pitchY),
            onDragPaint: { button, c, r in if !grab.isGrabMode { map.dragPaint(button, col: c, row: r) } }
        ))
        // The detail-picker popovers live at the grid level now (T-145) — the cell
        // only requests them via `onPick`.
        // VoiceOver (docs/ux.md § Accessibility). Default action = the primary
        // left-click; named actions open each detail picker.
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Room column \(col + 1), row \(row + 1)")
        .accessibilityValue(accessibilityValue)
        .accessibilityAddTraits(.isButton)
        .accessibilityAction { markWithInference() }
        .accessibilityAction(named: "Set room type") { onPick(.roomType) }
        .accessibilityAction(named: "Set monster") { onPick(.monster) }
        .accessibilityAction(named: "Set floor drop") { onPick(.floorDrop) }
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
        let monsters = room.monsters.map(\.displayName)
        if !monsters.isEmpty { parts.append("monster\(monsters.count > 1 ? "s" : "") \(monsters.joined(separator: " and "))") }
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
/// the last cell. Supports **up to two** monsters (T-116): tapping toggles a
/// monster into the room's pair; the popover stays open so a second can be added,
/// with a Done button to close.
private struct MonsterPicker: View {
    let primary: MonsterDetail
    let secondary: MonsterDetail
    let onToggle: (MonsterDetail) -> Void
    let onDone: () -> Void
    private let columns = Array(repeating: GridItem(.fixed(30), spacing: 4), count: 8)

    private func isSelected(_ md: MonsterDetail) -> Bool {
        !md.isNotMarked && (md == primary || md == secondary)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Select up to two monsters").font(.caption).foregroundStyle(.secondary)
                Spacer()
                Button("Done") { onDone() }.font(.caption)
            }
            LazyVGrid(columns: columns, spacing: 4) {
                ForEach(Array(MonsterDetail.allInPickerOrder.enumerated()), id: \.offset) { _, md in
                    Button { onToggle(md) } label: {
                        ZStack {
                            RoundedRectangle(cornerRadius: 4)
                                .fill(isSelected(md) ? Color.accentColor.opacity(0.5) : Color(white: 0.14))
                            if md == .unmarked {
                                Image(systemName: "xmark").font(.system(size: 11)).foregroundStyle(.secondary)
                            } else if let image = Image(atlasIcon: DungeonMonsterAtlas.sprite(md)) {
                                image.interpolation(.none).resizable().frame(width: 22, height: 22)
                            }
                        }
                        .frame(width: 30, height: 30)
                        // Badge the selection order (1 = primary, 2 = secondary).
                        .overlay(alignment: .topTrailing) {
                            if md == primary && !md.isNotMarked {
                                selectionBadge("1")
                            } else if md == secondary && !md.isNotMarked {
                                selectionBadge("2")
                            }
                        }
                    }
                    .buttonStyle(.plain)
                    .help(md == .unmarked ? "None (clear both)" : md.displayName)
                    .accessibilityLabel(md == .unmarked ? "None" : md.displayName)
                }
            }
        }
        .padding(10)
        .frame(width: 300)
    }

    private func selectionBadge(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 8, weight: .bold))
            .foregroundStyle(.white)
            .padding(2)
            .background(Circle().fill(Color.accentColor))
            .offset(x: 3, y: -3)
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
