import CoreGraphics
import SwiftUI
import TrackerCore

/// Loads the reference app's overworld-heart strip (`icons10x10.png`, 100×10px
/// = 10 icons of 10×10px) and crops the take-any heart sprites. Order is
/// transcribed from `Graphics.fs:602-618`'s `icons10x10.png` slicing
/// (`brightTriforce`, `orangeTriforce`, `owHeartSkipped`, `owHeartEmpty`,
/// `owHeartFull`, …). The PNG already carries its transparent background in
/// alpha, so it loads directly like the other overworld-icon atlases.
enum OverworldHeartAtlas {
    static let iconWidth = 10
    static let iconHeight = 10

    /// Named indices into `icons10x10.png`.
    enum Icon: Int {
        case empty = 3   // owHeartEmpty_bmp
        case full = 4    // owHeartFull_bmp
    }

    private static let fullImage: CGImage? = {
        guard
            let url = AppResources.url(forResource: "icons10x10", withExtension: "png"),
            let provider = CGDataProvider(url: url as CFURL),
            let image = CGImage(pngDataProviderSource: provider, decode: nil,
                                shouldInterpolate: false, intent: .defaultIntent)
        else { return nil }
        // The sheet has a pure-white background (with an alpha channel, so the
        // `maskingColorComponents` trick the other atlases use no-ops here).
        // Key exact white → transparent, mirroring the reference
        // (`Graphics.fs:611`: `color = White → Transparent`).
        return whiteKeyed(image) ?? image
    }()

    /// Returns a copy of `image` with every pure-white (255,255,255) pixel made
    /// fully transparent — the reference's overworld-sprite background key.
    private static func whiteKeyed(_ image: CGImage) -> CGImage? {
        let width = image.width, height = image.height
        let bytesPerRow = width * 4
        var pixels = [UInt8](repeating: 0, count: height * bytesPerRow)
        guard let ctx = CGContext(
            data: &pixels, width: width, height: height, bitsPerComponent: 8,
            bytesPerRow: bytesPerRow, space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        ) else { return nil }
        ctx.draw(image, in: CGRect(x: 0, y: 0, width: width, height: height))
        for i in stride(from: 0, to: pixels.count, by: 4) where
            pixels[i] == 255 && pixels[i + 1] == 255 && pixels[i + 2] == 255 {
            pixels[i] = 0; pixels[i + 1] = 0; pixels[i + 2] = 0; pixels[i + 3] = 0
        }
        return ctx.makeImage()
    }

    static func icon(at index: Int) -> CGImage? {
        guard let fullImage else { return nil }
        return fullImage.cropping(to: CGRect(x: index * iconWidth, y: 0, width: iconWidth, height: iconHeight))
    }

    static func cgImage(_ icon: Icon) -> CGImage? { self.icon(at: icon.rawValue) }
}

/// Pure, testable description of the overworld item-grid layout (T-025.1) —
/// the reference's `owItemGrid` cell arrangement (`OW_ITEM_GRID_LOCATIONS`,
/// `Z1R_Avalonia/OverworldMapTileCustomization.fs:17-42`), 5 columns × 3 rows.
/// Separated from the SwiftUI view so the cell → content mapping is unit-
/// testable without a running app.
extension TakeAnyHeartState {
    /// Short UI label for the take-any box tooltip (T-031).
    var label: String {
        switch self {
        case .untaken: "unclaimed"
        case .takenHeart: "heart"
        case .takenPotion: "potion"
        case .takenCandle: "blue candle"
        }
    }
}

enum ItemProgressGrid {
    static let columns = 5
    static let rows = 4

    /// A `PlayerProgressAndTakeAnyHearts` boolean the player toggles by
    /// clicking a fixed-sprite box (`veryBasicBoxImpl`,
    /// `OverworldItemGridUI.fs:272-333`).
    enum ItemToggle: CaseIterable {
        case woodSword, magicalSword, boomBook
        case blueCandle, woodArrow, blueRing
        case bomb, ganon, zelda
        case meat

        /// Stable id for the commentary key (T-215).
        var commentaryID: String { "\(self)" }

        /// The `PlayerProgressAndTakeAnyHearts` flag this box toggles.
        var keyPath: ReferenceWritableKeyPath<PlayerProgressAndTakeAnyHearts, Bool> {
            switch self {
            case .woodSword: \.hasWoodSword
            case .magicalSword: \.hasMagicalSword
            case .boomBook: \.hasBoomBook
            case .blueCandle: \.hasBlueCandle
            case .woodArrow: \.hasWoodArrow
            case .blueRing: \.hasBlueRing
            case .bomb: \.hasBombs
            case .ganon: \.hasDefeatedGanon
            case .zelda: \.hasRescuedZelda
            case .meat: \.hasMeat
            }
        }

        /// The `icons7x7` sprite drawn in the box (the magical-sword box swaps
        /// to the bomb-upgrade sprite under `isWSMSReplacedByBU`; that override
        /// is applied by the view, not here).
        var icon: ItemIconAtlas.Icon {
            switch self {
            case .woodSword: .brownSword
            case .magicalSword: .magicalSword
            case .boomBook: .boomBook
            case .blueCandle: .blueCandle
            case .woodArrow: .woodArrow
            case .blueRing: .blueRing
            case .bomb: .bomb
            case .ganon: .ganon
            case .zelda: .zelda
            case .meat: .bait
            }
        }

        var help: String {
            switch self {
            case .woodSword: "Acquired the wood sword"
            case .magicalSword: "Acquired the magical sword"
            case .boomBook: "Purchased the boomstick book"
            case .blueCandle: "Acquired the blue candle"
            case .woodArrow: "Acquired the wood arrow"
            case .blueRing: "Acquired the blue ring"
            case .bomb: "Acquired bombs"
            case .ganon: "Killed Ganon"
            case .zelda: "Rescued Zelda"
            case .meat: "Obtained the meat/bait"
            }
        }

        /// The box's shop/cave is found on the map but the item isn't held yet
        /// → yellow border (`OverworldItemGridUI.fs:328-379`, `yellow*Logic` /
        /// `foundBookShop` / `foundBombShop` / `magsCaveFound`).
        func located(playerState: PlayerComputedStateSummary, mapState: MapStateSummary) -> Bool {
            switch self {
            case .woodSword: playerState.swordLevel == 0 && mapState.woodSwordCaveFound
            case .woodArrow: playerState.arrowLevel == 0 && mapState.foundArrowShop
            case .blueCandle: playerState.candleLevel == 0 && mapState.foundCandleShop
            case .blueRing: playerState.ringLevel == 0 && mapState.foundBlueRingShop
            case .magicalSword: mapState.magsCaveFound
            case .boomBook: mapState.foundBookShop
            case .bomb: mapState.foundBombShop
            case .ganon, .zelda, .meat: false
            }
        }

        /// A better item makes this one moot → gray border + X
        /// (`OverworldItemGridUI.fs:329-347`, `*Superseded`). Only the
        /// wood sword/arrow and blue candle/ring can be superseded.
        func superseded(playerState: PlayerComputedStateSummary) -> Bool {
            switch self {
            case .woodSword: playerState.swordLevel >= 1
            case .woodArrow: playerState.arrowLevel >= 2
            case .blueCandle: playerState.candleLevel >= 2
            case .blueRing: playerState.ringLevel >= 2
            case .magicalSword, .boomBook, .bomb, .ganon, .zelda, .meat: false
            }
        }
    }

    /// One of the three off-map "item found here" picker boxes — the same
    /// `Box` type as the dungeon cells, so they reuse `BoxView`.
    enum CoastBox {
        case coast, armos, whiteSword

        /// The indicator sprite shown in the column to the box's left
        /// (`LADDER_ICON` / `ARMOS_ICON` / `WHITE_SWORD_ICON`).
        var indicator: ItemIconAtlas.Icon {
            switch self {
            case .coast: .ladder
            case .armos: .owKeyArmos
            case .whiteSword: .whiteSword
            }
        }

        var help: String {
            switch self {
            case .coast: "Item found off the coast (F16)"
            case .armos: "Item found under an Armos"
            case .whiteSword: "Item in the White Sword cave"
            }
        }

        func box(in dt: DungeonTrackerInstance) -> Box {
            switch self {
            case .coast: dt.ladderBox
            case .armos: dt.armosBox
            case .whiteSword: dt.sword2Box
            }
        }

        /// Stable id for the commentary key (T-215).
        var commentaryID: String { "\(self)" }

        /// Whether identifying this box's item defaults to **taken** (T-214): the coast item needs
        /// the ladder and the white-sword item needs the heart minimum, so below those the mark
        /// defaults to untaken. Armos has no such gate.
        func defaultAcquired(_ s: PlayerComputedStateSummary) -> Bool {
            switch self {
            case .coast: ItemAcquisitionGate.coastReachable(s)
            case .whiteSword: ItemAcquisitionGate.whiteSwordItemReachable(s)
            case .armos: true
            }
        }
    }

    /// Semantic content of a grid cell.
    enum Cell: Equatable {
        case indicator(CoastBox)
        case pickerBox(CoastBox)
        case toggle(ItemToggle)
        /// One of the 4 overworld take-any heart-cave slots (`HEARTS`,
        /// `OverworldItemGridUI.fs:197-222`).
        case takeAnyHeart(Int)
        /// An unused grid position (`OW_ITEM_GRID_LOCATIONS` has nothing at 4,3).
        case empty
    }

    /// The 4×5 grid content, ported cell-for-cell from `OW_ITEM_GRID_LOCATIONS`.
    /// `layout[row][col]`.
    static let layout: [[Cell]] = [
        // row 0
        [.indicator(.whiteSword), .pickerBox(.whiteSword), .toggle(.magicalSword), .toggle(.woodSword), .toggle(.boomBook)],
        // row 1
        [.indicator(.coast), .pickerBox(.coast), .toggle(.blueCandle), .toggle(.woodArrow), .toggle(.blueRing)],
        // row 2
        [.indicator(.armos), .pickerBox(.armos), .toggle(.bomb), .toggle(.ganon), .toggle(.zelda)],
        // row 3 — take-any heart caves (cols 0–3); the meat toggle under Zelda
        // (T-035.10) fills the previously-empty 4,3.
        [.takeAnyHeart(0), .takeAnyHeart(1), .takeAnyHeart(2), .takeAnyHeart(3), .toggle(.meat)],
    ]

    /// The cell at a position (nil if out of range) — the testable mapping.
    static func cell(row: Int, col: Int) -> Cell? {
        guard layout.indices.contains(row), layout[row].indices.contains(col) else { return nil }
        return layout[row][col]
    }

    /// The number of unmarked overworld spots the player can currently uncover
    /// (the "N gettable" readout) — `MapStateSummary` already gates each screen
    /// by the player's items, per quest. Pulled out so the readout wiring is
    /// unit-testable (T-035.1).
    static func gettableCount(_ mapState: MapStateSummary) -> Int {
        mapState.owGettableLocations.trueCount
    }

    /// The take-any heart state advanced by `delta` (wrapping over all four
    /// states), generalizing the reference's 3-state `(cur + delta + 3) % 3`
    /// (`OverworldItemGridUI.fs:207`) to include the distinct potion/candle
    /// states (T-031): untaken → heart → potion → candle → untaken.
    static func cycledHeart(_ state: TakeAnyHeartState, by delta: Int) -> TakeAnyHeartState {
        state.cycled(by: delta)
    }
}

extension ItemProgressGrid.CoastBox: Equatable {}
extension ItemProgressGrid.ItemToggle: Equatable {}

/// Shared cell size for the obtainable-item grid and its hint row.
private let itemGridCellSize: CGFloat = 34

/// **Obtainables** group (T-043): the reference's top-right `owItemGrid`,
/// re-laid-out cleanly — the white-sword-item / armos / coast picker boxes, the
/// other obtainable-item toggles, and the take-any heart caves, with the
/// white/magical-sword location hints above their columns. Toggle boxes flip a
/// `PlayerProgressAndTakeAnyHearts` flag on click; the three picker boxes reuse
/// `BoxView`. Located (yellow) / superseded (gray-X) highlighting comes from
/// live state (T-025.3).
struct ObtainableItemsView: View {
    @Bindable var model: TrackerModel
    /// User prefs affecting the item boxes (the large-vs-corner unwanted X, T-212).
    var options: TrackerOptions
    var playerState: PlayerComputedStateSummary
    var mapState: MapStateSummary
    /// Shared keyboard-cursor state (T-135) — this is the "items" cursor region.
    var focus: TrackerFocusState

    var body: some View {
        let _ = perfTrace()
        VStack(alignment: .leading, spacing: 3) {
            // White / magical sword cave location hints (T-039), each sitting
            // directly above its box: the White Sword item box (col 1) and the
            // Magical Sword box (col 2), matching the reference.
            swordHintRow
            Grid(horizontalSpacing: 6, verticalSpacing: 6) {
                ForEach(0..<ItemProgressGrid.rows, id: \.self) { row in
                    GridRow {
                        ForEach(0..<ItemProgressGrid.columns, id: \.self) { col in
                            cellView(ItemProgressGrid.layout[row][col])
                                .overlay { cursorRing(col: col, row: row) }
                                .onHover { $0 ? focus.hoverItems(col: col, row: row)
                                              : focus.endHover(.items) }
                        }
                    }
                }
            }
        }
    }

    /// The keyboard cursor's cyan ring on its cell while the cursor is in the items
    /// region (T-135).
    @ViewBuilder
    private func cursorRing(col: Int, row: Int) -> some View {
        if focus.cursorShown, focus.cursorRegion == .items,
           focus.itemsCursor == .init(col: col, row: row) {
            RoundedRectangle(cornerRadius: 4)
                .strokeBorder(Color.cyan, lineWidth: 2)
                .shadow(color: .cyan, radius: 2)
                .allowsHitTesting(false)
        }
    }

    /// A row of hint labels aligned with the item-grid columns: the White Sword
    /// cave hint over the White Sword *item box* (col 1) and the Magical Sword
    /// cave hint over the Magical Sword box (col 2). Every column reserves a
    /// fixed-width slot (`Color.clear` for the empties) so the two labels stay
    /// aligned over their boxes.
    private var swordHintRow: some View {
        HStack(spacing: 6) {
            ForEach(0..<ItemProgressGrid.columns, id: \.self) { col in
                Group {
                    if col == 1 {
                        HintLabel(hint: $model.levelHints[HintTarget.whiteSwordCave], title: "White Sword Cave",
                                  focus: focus, hintTarget: HintTarget.whiteSwordCave)
                    } else if col == 2 {
                        HintLabel(hint: $model.levelHints[HintTarget.magicalSwordCave], title: "Magical Sword Cave",
                                  focus: focus, hintTarget: HintTarget.magicalSwordCave)
                    } else {
                        Color.clear
                    }
                }
                .frame(width: itemGridCellSize, height: 20)
            }
        }
    }

    /// Seed-option icon override for a toggle box: the magical-sword box shows
    /// the bomb-upgrade under swordless (T-025.4).
    private func iconOverride(for toggle: ItemProgressGrid.ItemToggle) -> ItemIconAtlas.Icon? {
        if toggle == .magicalSword && model.isWSMSReplacedByBU { return .wsMsBombUpgrade }
        return nil
    }

    // Commentary Mode (T-215): shared style + per-cell helpers for the item-grid cells.
    private var commentaryActive: Bool { options.commentaryMode }
    private var commentaryR1: Color { Color(commentaryHex: model.commentary.runner1ColorHex) }
    private var commentaryR2: Color { Color(commentaryHex: model.commentary.runner2ColorHex) }
    private func commentaryKnowledge(_ key: String) -> CommentaryKnowledge {
        commentaryActive ? model.commentary.knowledge(key) : []
    }

    @ViewBuilder
    private func cellView(_ cell: ItemProgressGrid.Cell) -> some View {
        switch cell {
        case .indicator(let coast):
            IndicatorCell(icon: coast.indicator, help: coast.help, size: itemGridCellSize)
        case .pickerBox(let coast):
            let key = CommentaryLayer.itemKey(coast.commentaryID)
            BoxView(box: coast.box(in: model.dungeonTracker), instance: model.dungeonTracker,
                    label: nil, iconOptions: model.iconOptions.with(largeUnwantedX: options.largeUnwantedX),
                    defaultAcquired: coast.defaultAcquired(playerState),
                    commentaryKnowledge: commentaryKnowledge(key),
                    commentaryEncoding: options.commentaryEncoding,
                    commentaryR1: commentaryR1, commentaryR2: commentaryR2,
                    commentaryActive: commentaryActive,
                    onCommentaryR1: { model.commentary.toggle(.runner1, key: key) },
                    onCommentaryR2: { model.commentary.toggle(.runner2, key: key) })
                .help(coast.help)
        case .toggle(let toggle):
            let key = CommentaryLayer.itemKey("toggle:" + toggle.commentaryID)
            ItemToggleBox(
                progress: model.playerProgress,
                toggle: toggle,
                iconOverride: iconOverride(for: toggle),
                located: toggle.located(playerState: playerState, mapState: mapState),
                superseded: toggle.superseded(playerState: playerState),
                // Magical sword can't be marked held below its 10-heart minimum (T-214).
                canAcquire: toggle == .magicalSword ? ItemAcquisitionGate.magicalSwordReachable(playerState) : true,
                size: itemGridCellSize,
                commentaryKnowledge: commentaryKnowledge(key),
                commentaryEncoding: options.commentaryEncoding,
                commentaryR1: commentaryR1, commentaryR2: commentaryR2,
                commentaryActive: commentaryActive,
                onCommentaryR1: { model.commentary.toggle(.runner1, key: key) },
                onCommentaryR2: { model.commentary.toggle(.runner2, key: key) }
            )
        case .takeAnyHeart(let i):
            let key = CommentaryLayer.itemKey("takeAny:\(i)")
            // Cycling a heart box routes through the model so a take-any tile
            // linked to this slot updates its dim in sync (T-066).
            TakeAnyHeartBox(progress: model.playerProgress, index: i, size: itemGridCellSize,
                            onCycle: { delta in model.cycleTakeAnySlot(i, by: delta) },
                            commentaryKnowledge: commentaryKnowledge(key),
                            commentaryEncoding: options.commentaryEncoding,
                            commentaryR1: commentaryR1, commentaryR2: commentaryR2,
                            commentaryActive: commentaryActive,
                            onCommentaryR1: { model.commentary.toggle(.runner1, key: key) },
                            onCommentaryR2: { model.commentary.toggle(.runner2, key: key) })
        case .empty:
            Color.clear.frame(width: itemGridCellSize, height: itemGridCellSize)
        }
    }
}

/// **Flags** group (T-043): the seed-option toggles — swordless (White/Magical
/// Sword → Bomb Upgrade), Book vs Magic Shield (boomstick seeds), and Mirror
/// Overworld (T-047). Book-as-atlas is listed in the reference but its only
/// consumer (`PlayerCanSeeMapOfThisDungeon`, a dungeon-map view) isn't built
/// yet, so it's intentionally still absent (no dead toggle / invented flag).
struct SeedFlagsView: View {
    @Bindable var model: TrackerModel
    /// Seed-flag options that live in the Flags section (T-092: Book for Helpful
    /// Hints), toggled here rather than in the preferences panel.
    @Bindable var options: TrackerOptions
    /// For the recorder widget (T-104), which moved here from the Info group — its
    /// "record to new/unbeaten" settings are seed flags, so it belongs with Flags.
    var playerState: PlayerComputedStateSummary
    var mapState: MapStateSummary
    /// The run timer — Heart Shuffle / Hidden Dungeon Numbers rebuild dungeon
    /// state, so once the run has started (even if paused) they confirm first
    /// (T-051/T-052).
    var timer: TrackerTimer
    /// Voice control (T-137) — the mic toggle lives here in Flags.
    var voice: VoiceController? = nil
    @State private var pending: DestructiveAction?

    var body: some View {
        let _ = perfTrace()
        VStack(alignment: .leading, spacing: 8) {
            // Seed/config flags as toggleable icon tiles (T-035.13), matching the
            // Info overlay tiles for a consistent look; tooltips carry each
            // flag's name. Clicking a tile is the same as the old checkbox/label.
            Grid(horizontalSpacing: 6, verticalSpacing: 6) {
                GridRow {
                    heartShuffleTile
                    hideDungeonNumbersTile
                    swordlessTile
                }
                GridRow {
                    bookShieldTile
                    mirrorTile
                    bookHintsTile
                }
            }
            // Auto-map dungeons is game config, so it lives with the Flags
            // (T-035.11); "Hide tile icons" moved to the Info overlay-icon row.
            AutoMapDungeonsMenu(model: model)
            // Recorder destination (T-104): moved here from the Info group to save
            // vertical space; its new/unbeaten settings are seed flags anyway.
            RecorderInfoWidget(model: model, playerState: playerState, mapState: mapState)
            if let voice { micToggle(voice) }
        }
        .destructiveActionConfirmation($pending)
    }

    /// Voice-control mic toggle (T-137): green live mic while listening, with a small
    /// feedback line showing the last command run. Denied auth shows a hint.
    @ViewBuilder
    private func micToggle(_ voice: VoiceController) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Button {
                voice.toggle()
            } label: {
                HStack(spacing: 5) {
                    Image(systemName: voice.isListening ? "mic.fill" : "mic.slash")
                        .font(.system(size: 13))
                        .foregroundStyle(voice.isListening ? .green : .secondary)
                    Text(voice.isListening ? "Listening…" : "Voice control")
                        .font(.system(size: 11, weight: .medium))
                }
            }
            .buttonStyle(.plain)
            .help("Toggle voice control. Say e.g. \u{201C}D5 bomb shop\u{201D}, \u{201C}enter level 5\u{201D}, \u{201C}north\u{201D}.")

            if voice.auth == .denied {
                Text("Mic/speech access denied — enable in System Settings ▸ Privacy.")
                    .font(.system(size: 9)).foregroundStyle(.orange)
            } else if voice.isListening, !voice.lastCommand.isEmpty {
                Text("✓ \(voice.lastCommand)").font(.system(size: 9)).foregroundStyle(.green)
            } else if voice.isListening, !voice.lastHeard.isEmpty {
                Text("“\(voice.lastHeard)”").font(.system(size: 9)).foregroundStyle(.secondary)
                    .lineLimit(1)
            }
        }
    }

    /// Heart Shuffle (T-049) — moved off the startup screen. Uses the model's
    /// setter so the dungeon floor-item hearts re-seed on change. Confirms once
    /// the run has started (T-051/T-052), since it overwrites the floor boxes.
    private var heartShuffleTile: some View {
        let mode = model.heartShuffle
        let on = mode != .off
        let badge: String? = mode == .intra ? "I" : (mode == .full ? "F" : nil)
        return ZStack {
            Image(systemName: "suit.heart.fill").font(.system(size: 18)).foregroundStyle(.red)
            if let badge {
                // A corner letter distinguishes Intra vs Full at a glance.
                Text(badge)
                    .font(.system(size: 9, weight: .heavy, design: .rounded))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 3).padding(.vertical, 1)
                    .background(Capsule().fill(.black.opacity(0.8)))
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomTrailing)
                    .padding(1)
            }
        }
        .frame(width: itemGridCellSize, height: itemGridCellSize)
        .background(RoundedRectangle(cornerRadius: 6).fill(on ? Color.green.opacity(0.3) : Color.clear))
        .overlay(RoundedRectangle(cornerRadius: 6).strokeBorder(on ? Color.green : Theme.border, lineWidth: 1))
        .contentShape(Rectangle())
        .onTapGesture {
            let newValue = mode.next   // Off → Intra → Full → Off
            runOrConfirm(confirmFirst: timer.hasStarted, into: &pending,
                         title: "Change Heart Shuffle mid-run?",
                         message: "This re-seeds every dungeon's floor-item box, discarding what you've marked there. This can't be undone.",
                         confirmLabel: "Change Heart Shuffle") {
                model.setHeartShuffle(newValue)
            }
        }
        .help("Heart Shuffle (click to cycle): Off → Intra (I) → Full (F). Intra deduces each dungeon's heart once its other items are known; Full shuffles hearts into the global item pool.")
    }

    /// Hidden Dungeon Numbers (T-049) — moved off the startup screen. Rebuilds
    /// the dungeon tracker (3 boxes per dungeon) and relabels dungeons A–H.
    /// Confirms once the run has started (T-051/T-052); the rebuild wipes all
    /// dungeon progress.
    private var hideDungeonNumbersTile: some View {
        flagTile(on: model.hideDungeonNumbers, systemImage: "questionmark.square.fill",
                 help: "Hidden Dungeon Numbers: dungeons are labeled A–H (numbers unknown) and each has three item boxes. Toggling rebuilds the dungeon tracker.") {
            let newValue = !model.hideDungeonNumbers
            runOrConfirm(confirmFirst: timer.hasStarted, into: &pending,
                         title: "Change Hidden Dungeon Numbers mid-run?",
                         message: "This rebuilds the dungeon tracker, discarding all dungeon items, triforces, and number assignments. This can't be undone.",
                         confirmLabel: "Change Hidden Dungeon Numbers") {
                model.setHideDungeonNumbers(newValue)
            }
        }
    }

    /// The swordless (WSMS→Bomb Upgrade) seed toggle. When on, the White Sword
    /// and Magical Sword are Bomb Upgrades (`isWSMSReplacedByBU`).
    private var swordlessTile: some View {
        flagTile(on: model.isWSMSReplacedByBU, atlasIcon: .wsMsBombUpgrade,
                 help: "Swordless seed: the White Sword and Magical Sword are replaced by Bomb Upgrades") {
            model.isWSMSReplacedByBU.toggle()
        }
    }

    /// Book vs Magic Shield for item slot 0 (boomstick seeds). On = shield
    /// (`isCurrentlyBook == false`), matching the reference's "Shield instead of
    /// book" flag. The tile's icon reflects the current mode.
    private var bookShieldTile: some View {
        flagTile(on: !model.isCurrentlyBook,
                 atlasIcon: model.isCurrentlyBook ? .book : .magicShield,
                 help: "Boomstick: when on, item slot 0 is the Magic Shield instead of the Book") {
            model.isCurrentlyBook.toggle()
        }
    }

    /// Mirror the overworld East↔West (T-047).
    private var mirrorTile: some View {
        flagTile(on: model.mirrorOverworld, systemImage: "arrow.left.arrow.right",
                 help: "Mirror the overworld map East↔West (mirrored seeds)") {
            model.mirrorOverworld.toggle()
        }
    }

    /// Book for Helpful Hints (T-092) — moved here from the preferences panel as a
    /// seed flag. The icon is a book with a character glyph ("translate the old
    /// man's gibberish"). When on, NPC-hint rooms are flagged and you're reminded
    /// to visit the hints once you have the Book.
    private var bookHintsTile: some View {
        flagTile(on: options.bookForHelpfulHints, systemImage: "character.book.closed.fill", tint: .yellow,
                 help: "Book for Helpful Hints: this seed's Book grants hints — mark NPC-hint rooms, and remind you to visit them once you have the Book") {
            options.bookForHelpfulHints.toggle()
        }
    }

    /// A flag as a toggleable icon tile, styled like the Info overlay tiles
    /// (T-035.13): item-icon sized, green fill+border when on. Takes either an SF
    /// Symbol (tinted) or an atlas icon. `action` runs on tap.
    @ViewBuilder
    private func flagTile(on: Bool,
                          systemImage: String? = nil,
                          tint: Color = .secondary,
                          atlasIcon: ItemIconAtlas.Icon? = nil,
                          help: String,
                          action: @escaping () -> Void) -> some View {
        ZStack {
            if let systemImage {
                Image(systemName: systemImage).font(.system(size: 18)).foregroundStyle(tint)
            } else if let atlasIcon {
                ItemGlyph(atlasIcon).frame(width: 22, height: 22)
            }
        }
        .frame(width: itemGridCellSize, height: itemGridCellSize)
        .background(RoundedRectangle(cornerRadius: 6).fill(on ? Color.green.opacity(0.3) : Color.clear))
        .overlay(RoundedRectangle(cornerRadius: 6).strokeBorder(on ? Color.green : Theme.border, lineWidth: 1))
        .contentShape(Rectangle())
        .onTapGesture(perform: action)
        .help(help)
    }
}

/// **Informational** group (T-043): live read-only readouts (unmarked overworld
/// spots left, how many are currently gettable, computed Max Hearts), the map-
/// overlay toggle icons (open caves / money / zones / coords — hover to preview,
/// click to lock), and the three **omnipresent reset buttons** (T-048): Reset
/// App, Reset Timer, and Reset (keep maps). They're always visible here (not
/// gated behind pausing), and the groundhog reset never pauses the main timer.
struct MapInfoView: View {
    @Bindable var model: TrackerModel
    var playerState: PlayerComputedStateSummary
    var mapState: MapStateSummary
    var overlays: OverworldOverlayState
    /// The run timer — Reset Timer zeroes it; Reset (keep maps) restarts the lap
    /// without pausing the main timer (T-048).
    var timer: TrackerTimer
    /// "Reset App" — discard everything and return to the startup screen (T-046).
    var onResetApp: () -> Void = {}
    /// For the Commentary Mode quick toggle (T-215).
    var options: TrackerOptions

    @State private var showingSpotSummary = false
    @State private var showingHintDecoder = false
    @Environment(\.openWindow) private var openWindow
    @Environment(\.dismissWindow) private var dismissWindow

    var body: some View {
        let _ = perfTrace()
        VStack(alignment: .leading, spacing: 8) {
            spotSummaryButton
            hintDecoderButton
            settingsButton
            overlayToggles
            // (Recorder widget moved to the Flags group, T-104; Commentary + Shop/Price
            //  live in the overlay-icon grid's 4th column, T-218.)
        }
    }

    /// Opens the mid-game Settings window (T-091) — same panel as the startup
    /// screen, also reachable via ⌘,.
    private var settingsButton: some View {
        Button {
            openWindow(id: SettingsWindowID)
        } label: {
            Label("Settings…", systemImage: "gearshape")
        }
        .font(.system(size: 10))
        .controlSize(.small)
        .buttonStyle(.bordered)
        .help("Open Settings (also ⌘,) — draw routes, magnifier, animation, and other preferences, live")
    }

    /// "Hint Decoder" (T-039.1): the consolidated per-target location-hint
    /// editor (writes the same `levelHints` the dungeon cards use).
    private var hintDecoderButton: some View {
        Button("Hint Decoder…") { showingHintDecoder = true }
            .font(.system(size: 10))
            .controlSize(.small)
            .buttonStyle(.bordered)
            .help("Record the hinted overworld region for each dungeon and sword cave")
            .popover(isPresented: $showingHintDecoder, arrowEdge: .bottom) {
                HintDecoderView(model: model)
            }
    }

    /// "Spot Summary" (T-053): opens the remaining-locations popover — which
    /// unique spots and money secrets are still to be found.
    private var spotSummaryButton: some View {
        Button("Spot Summary…") { showingSpotSummary = true }
            .font(.system(size: 10))
            .controlSize(.small)
            .buttonStyle(.bordered)
            .help("What overworld locations and secrets you still have left to find")
            .popover(isPresented: $showingSpotSummary, arrowEdge: .bottom) {
                VStack(alignment: .trailing, spacing: 6) {
                    // Pop the summary out into its own window so it can stay up (T-199).
                    Button {
                        showingSpotSummary = false
                        openWindow(id: SpotSummaryWindowID)
                    } label: {
                        Label("Open in window", systemImage: "macwindow.on.rectangle")
                    }
                    .font(.system(size: 10)).controlSize(.small).buttonStyle(.bordered)
                    .help("Keep the Spot Summary open in its own window")

                    SpotSummaryView(
                        summary: SpotSummary.compute(
                            grid: model.overworldGrid, quest: model.quest ?? .first,
                            armosDone: model.dungeonTracker.armosBox.isDone,
                            whiteSwordItemDone: model.dungeonTracker.sword2Box.isDone,
                            hasMagicalSword: model.playerComputedStateSummary.swordLevel >= 3),
                        hideDungeonNumbers: model.hideDungeonNumbers
                    )
                }
                .padding(10)
            }
    }

    /// The map-overlay toggle icons (T-035.2): hover previews the highlight on
    /// the map, click locks it on. No separate checkboxes (user preference).
    /// "Hide tile icons" leads (T-035.11), moved here from the Flags checkboxes
    /// since it's the same hover-preview / click-lock overlay model.
    private var overlayToggles: some View {
        // Two rows of four (T-218): the map-overlay toggles fill the first three columns; the
        // 4th column holds the two breakout openers — Shop & Price (top), Commentary (bottom) —
        // so we add them without taking any more app vertical space.
        Grid(horizontalSpacing: 6, verticalSpacing: 6) {
            GridRow {
                overlayToggle(.hideMarks, systemImage: "eye.slash",
                              help: "Temporarily hide the overworld map's tile marks to see the terrain. Hover to preview, click to keep it on.")
                overlayToggle(.openCaves, systemImage: "mountain.2.fill",
                              help: "3-way (hover previews, then cycle by clicking): green = open caves only (late game, Armos spots); orange = ALL currently-gettable locations; third click = off.")
                overlayToggle(.money, atlasIcon: .rupee,
                              help: "Highlight money spots: Money Making Game, Unknown Secret, and known money secrets. Hover to preview, click to lock on.")
                shopPricesToggle
            }
            GridRow {
                overlayToggle(.zones, systemImage: "map.fill",
                              help: "Tint the map by overworld region (Zones). Hover to preview, click to lock on.")
                overlayToggle(.coords, systemImage: "number",
                              help: "Overlay screen coordinates (A1…H16). Hover to preview, click to lock on.")
                progressToggle
                commentaryToggle
            }
        }
    }

    /// Opens/closes the Shop & Price tracker breakout window (T-218). Tints green while that window
    /// is open (mirrors the Progress toggle), not based on whether the record holds data.
    private var shopPricesToggle: some View {
        iconCell(systemImage: "cart.fill", on: model.showShopPricesWindow,
                 help: "Shops & Prices — record shop stock/prices, potions, bomb upgrades, and paid hints in a separate window.") {
            model.showShopPricesWindow.toggle()
        }
        .onChange(of: model.showShopPricesWindow) { _, isOn in
            if isOn { openWindow(id: ShopPricesWindowID) } else { dismissWindow(id: ShopPricesWindowID) }
        }
    }

    /// The Commentary-Mode quick toggle (T-218) — the old checkbox as a race-flag icon matching the
    /// other overlay toggles (green when on). Full config lives in the Commentary settings window.
    private var commentaryToggle: some View {
        let c = model.commentary
        return iconCell(systemImage: "flag.checkered", on: options.commentaryMode,
                        help: "Commentary Mode — mark who's discovered each spot: ⌥-click = \(c.runner1Name), ⌥-right-click = \(c.runner2Name). Click to toggle.") {
            options.commentaryMode.toggle()
        }
    }

    /// A tap-action overlay icon styled like `progressToggle` / `overlayToggle` (green when `on`).
    private func iconCell(systemImage: String, on: Bool, help: String, action: @escaping () -> Void) -> some View {
        ZStack {
            Image(systemName: systemImage).font(.system(size: 18))
                .foregroundStyle(on ? Color.green : Color.secondary)
        }
        .frame(width: itemGridCellSize, height: itemGridCellSize)
        .background(RoundedRectangle(cornerRadius: 6).fill(on ? Color.green.opacity(0.3) : Color.clear))
        .overlay(RoundedRectangle(cornerRadius: 6).strokeBorder(on ? Color.green : Theme.border, lineWidth: 1))
        .contentShape(Rectangle())
        .onTapGesture { action() }
        .help(help)
    }

    /// The "Progress" toggle icon (T-035.10), styled like the overlay toggles:
    /// hover peeks the items+hearts HUD; clicking breaks it out into a separate,
    /// placeable window. Replaces the old "Max Hearts" readout (the HUD shows the
    /// heart row).
    private var progressToggle: some View {
        let on = model.showProgressWindow
        return ZStack {
            Image(systemName: "chart.bar.doc.horizontal").font(.system(size: 18))
                .foregroundStyle(on ? Color.green : Color.secondary)
        }
        .frame(width: itemGridCellSize, height: itemGridCellSize)
        .background(RoundedRectangle(cornerRadius: 6).fill(on ? Color.green.opacity(0.3) : Color.clear))
        .overlay(RoundedRectangle(cornerRadius: 6).strokeBorder(on ? Color.green : Theme.border, lineWidth: 1))
        .contentShape(Rectangle())
        // A plain click toggles the standalone HUD window (no hover preview — a
        // popover just fought the click; user preference).
        .onTapGesture { model.showProgressWindow.toggle() }
        .onChange(of: model.showProgressWindow) { _, isOn in
            if isOn { openWindow(id: ProgressHUDWindowID) } else { dismissWindow(id: ProgressHUDWindowID) }
        }
        .help("Items + hearts HUD — click to open/close it as a separate, resizable window you can place anywhere.")
    }

    @ViewBuilder
    private func overlayToggle(_ overlay: OverworldOverlayState.Overlay,
                               systemImage: String? = nil,
                               atlasIcon: ItemIconAtlas.Icon? = nil,
                               help: String) -> some View {
        // The open-caves overlay is 3-way (T-189): green in "open caves" mode, orange in
        // "all gettable" mode, off otherwise. Binary overlays are green-when-locked.
        let tint: Color? = {
            if overlay == .openCaves {
                switch overlays.openCavesMode {
                case .off: return nil
                case .openCaves: return .green
                case .allGettable: return .orange
                }
            }
            return overlays.isLocked(overlay) ? .green : nil
        }()
        let on = tint != nil
        ZStack {
            if let systemImage {
                Image(systemName: systemImage).font(.system(size: 18))
                    .foregroundStyle(tint ?? Color.secondary)
            } else if let atlasIcon {
                ItemGlyph(atlasIcon).frame(width: 22, height: 22)
            }
        }
        .frame(width: itemGridCellSize, height: itemGridCellSize)
        .background(RoundedRectangle(cornerRadius: 6).fill(on ? (tint ?? .green).opacity(0.3) : Color.clear))
        .overlay(RoundedRectangle(cornerRadius: 6).strokeBorder(tint ?? Theme.border, lineWidth: 1))
        .contentShape(Rectangle())
        .onHover { overlays.setHover(overlay, $0) }
        .onTapGesture { overlays.toggleLock(overlay) }
        .help(help)
    }
}

/// A non-interactive label sprite pointing at the picker box to its right.
private struct IndicatorCell: View {
    let icon: ItemIconAtlas.Icon
    let help: String
    let size: CGFloat

    var body: some View {
        let _ = perfTrace()
        ZStack {
            ItemGlyph(icon)
                .frame(width: size - 12, height: size - 12)
                .opacity(0.85)
        }
        .frame(width: size, height: size)
        .help(help)
        .accessibilityHidden(true)
    }
}

/// A fixed-sprite item box that toggles a `PlayerProgressAndTakeAnyHearts`
/// bool. Any click toggles it (the reference's `prop.Toggle()` on `MouseDown`);
/// right-click explicitly clears it. Green border when held, dim otherwise.
private struct ItemToggleBox: View {
    var progress: PlayerProgressAndTakeAnyHearts
    let toggle: ItemProgressGrid.ItemToggle
    var iconOverride: ItemIconAtlas.Icon? = nil
    /// The item's shop/cave is found but the item isn't held → yellow.
    var located: Bool = false
    /// A better item makes this one moot → gray + X.
    var superseded: Bool = false
    /// Whether the item can be acquired yet (T-214). `false` blocks turning the toggle **on**
    /// (used for the magical sword below its 10-heart minimum — you can't have it yet); turning it
    /// back off is always allowed.
    var canAcquire: Bool = true
    let size: CGFloat

    /// Commentary Mode overlay for this item (T-215).
    var commentaryKnowledge: CommentaryKnowledge = []
    var commentaryEncoding: CommentaryEncoding = .pips
    var commentaryR1: Color = .red
    var commentaryR2: Color = .blue
    var commentaryActive: Bool = false
    var onCommentaryR1: () -> Void = {}
    var onCommentaryR2: () -> Void = {}

    private var has: Bool { progress[keyPath: toggle.keyPath] }

    /// Border precedence ported from `veryBasicBoxImpl`'s redraw
    /// (`OverworldItemGridUI.fs:295-306`): held → superseded → located → none.
    private var borderColor: Color {
        if has { return .green }
        if superseded { return Color(white: 0.5) }
        if located { return .yellow }
        return Theme.border
    }

    var body: some View {
        let _ = perfTrace()
        ZStack {
            RoundedRectangle(cornerRadius: 4).fill(Theme.boxFill)
            ItemGlyph(iconOverride ?? toggle.icon)
                .frame(width: size - 10, height: size - 10)
                .opacity(has ? 1 : 0.4)
            // Superseded items are moot — mark with an X (the reference's
            // placeSkippedItemXDecoration).
            if superseded && !has {
                Image(systemName: "xmark")
                    .font(.system(size: size * 0.4, weight: .bold))
                    .foregroundStyle(.primary.opacity(0.75))
            }
        }
        .frame(width: size, height: size)
        .overlay(
            RoundedRectangle(cornerRadius: 4).strokeBorder(borderColor, lineWidth: 1.5)
        )
        .onTapGesture {
            // Commentary Mode (T-215): ⌥-click toggles runner 1's knowledge of this item.
            if commentaryActive, commentaryOptionKeyDown() { onCommentaryR1(); return }
            // Block turning it on when it can't be reached yet (T-214); turning off is fine.
            if !progress[keyPath: toggle.keyPath] && !canAcquire { return }
            progress[keyPath: toggle.keyPath].toggle()
        }
        .onRightClick { progress[keyPath: toggle.keyPath] = false }
        .commentaryCell(knowledge: commentaryKnowledge, encoding: commentaryEncoding,
                        r1: commentaryR1, r2: commentaryR2, active: commentaryActive,
                        size: size, onRunner2: onCommentaryR2)
        .help(canAcquire ? toggle.help : toggle.help + " — needs \(ItemAcquisitionGate.magicalSwordMinHearts) hearts (min) before you can have it")
    }
}

/// One of the 4 overworld "take-any" heart-cave slots. Left-click cycles
/// forward, right-click backward, over four states (T-031): untaken →
/// taken-heart → taken-potion → taken-candle. The empty-heart sprite stays as
/// the background (so the slot is recognizable in the UI); a taken *heart*
/// fills it, while a taken *potion* or *candle* keeps the empty heart and
/// overlays that item's icon.
private struct TakeAnyHeartBox: View {
    var progress: PlayerProgressAndTakeAnyHearts
    let index: Int
    let size: CGFloat
    /// Cycle by `delta` — routed through the model so a linked take-any tile
    /// stays in sync (T-066).
    var onCycle: (Int) -> Void

    /// Commentary Mode overlay for this take-any slot (T-215).
    var commentaryKnowledge: CommentaryKnowledge = []
    var commentaryEncoding: CommentaryEncoding = .pips
    var commentaryR1: Color = .red
    var commentaryR2: Color = .blue
    var commentaryActive: Bool = false
    var onCommentaryR1: () -> Void = {}
    var onCommentaryR2: () -> Void = {}

    private var state: TakeAnyHeartState { progress.takeAnyHearts[index] }

    var body: some View {
        let _ = perfTrace()
        ZStack {
            RoundedRectangle(cornerRadius: 4).fill(Theme.boxFill)
            // Background heart: full (pink) when a heart was taken, empty
            // otherwise (kept under the potion/candle overlays too).
            let sprite: OverworldHeartAtlas.Icon = state == .takenHeart ? .full : .empty
            if let image = Image(atlasIcon: OverworldHeartAtlas.cgImage(sprite)) {
                image.interpolation(.none).resizable()
                    .frame(width: size - 12, height: size - 12)
            }
            overlayIcon
        }
        .frame(width: size, height: size)
        .overlay(
            RoundedRectangle(cornerRadius: 4).strokeBorder(Theme.border, lineWidth: 1.5)
        )
        .onTapGesture {
            if commentaryActive, commentaryOptionKeyDown() { onCommentaryR1(); return }
            cycle(1)
        }
        .onRightClick { cycle(-1) }
        .commentaryCell(knowledge: commentaryKnowledge, encoding: commentaryEncoding,
                        r1: commentaryR1, r2: commentaryR2, active: commentaryActive,
                        size: size, onRunner2: onCommentaryR2)
        .help("Take-any cave \(index + 1): \(state.label)")
    }

    /// The item taken, overlaid on the empty heart (potion / blue candle).
    @ViewBuilder
    private var overlayIcon: some View {
        switch state {
        case .takenPotion:
            // The real Life Potion game sprite (T-161); the ow_icons5x9 index-5
            // potion-shop glyph is the fallback if it's missing.
            Group {
                if let cg = GameSprite.image("Life Potion") {
                    Image(decorative: cg, scale: 1, orientation: .up).resizable().interpolation(.none)
                } else if let potion = Image(atlasIcon: OverworldInteriorIconAtlas.icon(at: 5)) {
                    potion.interpolation(.none).resizable()
                }
            }
            .frame(width: (size - 12) * 0.7, height: (size - 12) * 0.9)
        case .takenCandle:
            ItemGlyph(.blueCandle)
                .frame(width: (size - 12) * 0.8, height: (size - 12) * 0.8)
        case .untaken, .takenHeart:
            EmptyView()
        }
    }

    private func cycle(_ delta: Int) { onCycle(delta) }
}

