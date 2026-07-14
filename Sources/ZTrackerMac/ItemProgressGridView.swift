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
            let url = Bundle.module.url(forResource: "icons10x10", withExtension: "png"),
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
            case .ganon, .zelda: false
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
            case .magicalSword, .boomBook, .bomb, .ganon, .zelda: false
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
        // row 3 — take-any heart caves (cols 0–3), nothing at 4,3
        [.takeAnyHeart(0), .takeAnyHeart(1), .takeAnyHeart(2), .takeAnyHeart(3), .empty],
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
        let n = TakeAnyHeartState.allCases.count
        return TakeAnyHeartState(rawValue: ((state.rawValue + delta) % n + n) % n) ?? state
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
    var playerState: PlayerComputedStateSummary
    var mapState: MapStateSummary

    var body: some View {
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
                        }
                    }
                }
            }
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
                        HintLabel(hint: $model.levelHints[HintTarget.whiteSwordCave], title: "White Sword Cave")
                    } else if col == 2 {
                        HintLabel(hint: $model.levelHints[HintTarget.magicalSwordCave], title: "Magical Sword Cave")
                    } else {
                        Color.clear
                    }
                }
                .frame(width: itemGridCellSize, height: 15)
            }
        }
    }

    /// Seed-option icon override for a toggle box: the magical-sword box shows
    /// the bomb-upgrade under swordless (T-025.4).
    private func iconOverride(for toggle: ItemProgressGrid.ItemToggle) -> ItemIconAtlas.Icon? {
        if toggle == .magicalSword && model.isWSMSReplacedByBU { return .wsMsBombUpgrade }
        return nil
    }

    @ViewBuilder
    private func cellView(_ cell: ItemProgressGrid.Cell) -> some View {
        switch cell {
        case .indicator(let coast):
            IndicatorCell(icon: coast.indicator, help: coast.help, size: itemGridCellSize)
        case .pickerBox(let coast):
            BoxView(box: coast.box(in: model.dungeonTracker), instance: model.dungeonTracker,
                    label: nil, iconOptions: model.iconOptions)
                .help(coast.help)
        case .toggle(let toggle):
            ItemToggleBox(
                progress: model.playerProgress,
                toggle: toggle,
                iconOverride: iconOverride(for: toggle),
                located: toggle.located(playerState: playerState, mapState: mapState),
                superseded: toggle.superseded(playerState: playerState),
                size: itemGridCellSize
            )
        case .takeAnyHeart(let i):
            TakeAnyHeartBox(progress: model.playerProgress, index: i, size: itemGridCellSize)
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
    /// The run timer — Heart Shuffle / Hidden Dungeon Numbers rebuild dungeon
    /// state, so while the timer is running they confirm first (T-051).
    var timer: TrackerTimer
    @State private var pending: DestructiveAction?

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            heartShuffleToggle
            hideDungeonNumbersToggle
            swordlessToggle
            bookShieldToggle
            mirrorToggle
        }
        .toggleStyle(.checkbox)
        .destructiveActionConfirmation($pending)
    }

    /// Heart Shuffle (T-049) — moved off the startup screen. Uses the model's
    /// setter so the dungeon floor-item hearts re-seed on change. Confirms
    /// mid-run (T-051), since it overwrites the floor-item boxes.
    private var heartShuffleToggle: some View {
        Toggle(isOn: Binding(get: { model.heartShuffle }, set: { newValue in
            runOrConfirm(timerIsRunning: timer.isRunning, into: &pending,
                         title: "Change Heart Shuffle mid-run?",
                         message: "This re-seeds every dungeon's floor-item box, discarding what you've marked there. This can't be undone.",
                         confirmLabel: "Change Heart Shuffle") {
                model.setHeartShuffle(newValue)
            }
        })) {
            HStack(spacing: 6) {
                Image(systemName: "suit.heart.fill").font(.system(size: 12)).foregroundStyle(.red)
                Text("Heart Shuffle").font(.system(size: 11))
            }
        }
        .help("Heart Shuffle: dungeon floor hearts are shuffled into the item pool instead of being known")
    }

    /// Hidden Dungeon Numbers (T-049) — moved off the startup screen. Rebuilds
    /// the dungeon tracker (3 boxes per dungeon) and relabels dungeons A–H.
    /// Confirms mid-run (T-051), since the rebuild wipes all dungeon progress.
    private var hideDungeonNumbersToggle: some View {
        Toggle(isOn: Binding(get: { model.hideDungeonNumbers }, set: { newValue in
            runOrConfirm(timerIsRunning: timer.isRunning, into: &pending,
                         title: "Change Hidden Dungeon Numbers mid-run?",
                         message: "This rebuilds the dungeon tracker, discarding all dungeon items, triforces, and number assignments. This can't be undone.",
                         confirmLabel: "Change Hidden Dungeon Numbers") {
                model.setHideDungeonNumbers(newValue)
            }
        })) {
            HStack(spacing: 6) {
                Image(systemName: "questionmark.square.fill").font(.system(size: 12))
                Text("Hide Dungeon #s").font(.system(size: 11))
            }
        }
        .help("Hidden Dungeon Numbers: dungeons are labeled A–H (numbers unknown) and each has three item boxes. Toggling rebuilds the dungeon tracker.")
    }

    /// Mirror the overworld East↔West (T-047).
    private var mirrorToggle: some View {
        Toggle(isOn: $model.mirrorOverworld) {
            HStack(spacing: 6) {
                Image(systemName: "arrow.left.arrow.right").font(.system(size: 13))
                Text("Mirror OW").font(.system(size: 11))
            }
        }
        .help("Mirror the overworld map East↔West (mirrored seeds)")
    }

    /// The swordless (WSMS→Bomb Upgrade) seed toggle. When on, the White Sword
    /// and Magical Sword are Bomb Upgrades (`isWSMSReplacedByBU`).
    private var swordlessToggle: some View {
        Toggle(isOn: $model.isWSMSReplacedByBU) {
            HStack(spacing: 6) { iconOnly(.wsMsBombUpgrade); Text("Swordless").font(.system(size: 11)) }
        }
        .help("Swordless seed: the White Sword and Magical Sword are replaced by Bomb Upgrades")
    }

    /// Book vs Magic Shield for item slot 0 (boomstick seeds). Checked = shield
    /// (`isCurrentlyBook == false`), matching the reference's "Shield instead of
    /// book" checkbox.
    private var bookShieldToggle: some View {
        Toggle(isOn: Binding(get: { !model.isCurrentlyBook }, set: { model.isCurrentlyBook = !$0 })) {
            HStack(spacing: 6) {
                iconOnly(model.isCurrentlyBook ? .book : .magicShield)
                Text("Boomstick").font(.system(size: 11))
            }
        }
        .help("When checked, item slot 0 is the Magic Shield instead of the Book (boomstick seeds)")
    }

    @ViewBuilder
    private func iconOnly(_ icon: ItemIconAtlas.Icon) -> some View {
        if let img = Image(atlasIcon: ItemIconAtlas.cgImage(icon)) {
            img.interpolation(.none).resizable().frame(width: 16, height: 16)
        }
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

    @State private var confirmingResetApp = false
    @State private var confirmingResetTimer = false
    @State private var confirmingGroundhog = false

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            statusReadout
            overlayToggles
            resetButtons
        }
    }

    /// The three always-visible reset actions (T-048). All three confirm first
    /// (T-051), so a misclick in the crowded top section can't wipe a run's
    /// state or its timer.
    private var resetButtons: some View {
        VStack(alignment: .leading, spacing: 4) {
            Button("Reset App") { confirmingResetApp = true }
                .help("Discard everything and return to the startup screen, as if you'd just reopened the app")
            Button("Reset Timer") { confirmingResetTimer = true }
                .help("Set the run timer back to 0:00:00 (keeps your marks and items)")
            Button("Reset (keep maps)") { confirmingGroundhog = true }
                .help("Groundhog/routers restart: clear inventory but keep your overworld marks and known item locations. Does not pause the timer.")
        }
        .font(.system(size: 10))
        .controlSize(.small)
        .confirmationDialog("Reset the app?", isPresented: $confirmingResetApp, titleVisibility: .visible) {
            Button("Reset App (discard everything)", role: .destructive, action: onResetApp)
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Returns to the startup screen as if you'd just reopened the app. All marks, items, hints, and the timer are discarded. This can't be undone (no save yet).")
        }
        .confirmationDialog("Reset the timer to 0:00:00?", isPresented: $confirmingResetTimer, titleVisibility: .visible) {
            Button("Reset Timer", role: .destructive) { timer.reset() }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Sets the run timer back to 0:00:00. Your marks and items are kept. This can't be undone.")
        }
        .confirmationDialog("Reset inventory for a groundhog/routers restart?",
                            isPresented: $confirmingGroundhog, titleVisibility: .visible) {
            Button("Reset inventory (keep maps)", role: .destructive) {
                model.resetForGroundhogOrRouters()
                // Fresh lap only — the main timer keeps running (never paused).
                timer.startLap()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Removes all items, triforces, and take-any hearts so you can replay the same seed. Your overworld marks and known item locations stay, and the lap timer restarts while the main timer keeps running. This can't be undone (no save yet).")
        }
    }

    /// Live map/heart status (T-035.1): unmarked overworld spots remaining, how
    /// many are currently *gettable* with the player's items (both computed in
    /// `MapStateSummary`, capability-aware + per quest), and the computed Max
    /// Hearts. All read-only.
    private var statusReadout: some View {
        VStack(alignment: .leading, spacing: 3) {
            Text("\(mapState.owSpotsRemain) OW spots left")
                .foregroundStyle(.orange)
                .help("Unmarked overworld screens remaining")
            Text("\(ItemProgressGrid.gettableCount(mapState)) gettable")
                .foregroundStyle(.green)
                .help("Unmarked spots you can currently uncover with your items (raft / recorder / bracelet / candle / bombs), for this quest")
            Text("Max Hearts: \(playerState.playerHearts)")
                .foregroundStyle(.orange)
                .help("Max hearts, computed from collected heart containers and take-any hearts")
        }
        .font(.system(size: 11))
    }

    /// The map-overlay toggle icons (T-035.2): hover previews the highlight on
    /// the map, click locks it on. No separate checkboxes (user preference).
    private var overlayToggles: some View {
        HStack(spacing: 6) {
            overlayToggle(.openCaves, systemImage: "mountain.2.fill",
                          help: "Highlight open caves (unmarked spots that can hold a plain cave); late game, the Armos spots. Hover to preview, click to lock on.")
            overlayToggle(.money, atlasIcon: .rupee,
                          help: "Highlight money spots: Money Making Game, Unknown Secret, and known money secrets. Hover to preview, click to lock on.")
            overlayToggle(.zones, systemImage: "map.fill",
                          help: "Tint the map by overworld region (Zones). Hover to preview, click to lock on.")
            overlayToggle(.coords, systemImage: "number",
                          help: "Overlay screen coordinates (A1…H16). Hover to preview, click to lock on.")
        }
    }

    @ViewBuilder
    private func overlayToggle(_ overlay: OverworldOverlayState.Overlay,
                               systemImage: String? = nil,
                               atlasIcon: ItemIconAtlas.Icon? = nil,
                               help: String) -> some View {
        let locked = overlays.isLocked(overlay)
        ZStack {
            if let systemImage {
                Image(systemName: systemImage).font(.system(size: 12))
                    .foregroundStyle(locked ? Color.green : Color(white: 0.75))
            } else if let atlasIcon, let img = Image(atlasIcon: ItemIconAtlas.cgImage(atlasIcon)) {
                img.interpolation(.none).resizable().frame(width: 15, height: 15)
            }
        }
        .frame(width: 24, height: 20)
        .background(RoundedRectangle(cornerRadius: 4).fill(locked ? Color.green.opacity(0.3) : Color.clear))
        .overlay(RoundedRectangle(cornerRadius: 4).strokeBorder(locked ? Color.green : Color(white: 0.28), lineWidth: 1))
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
        ZStack {
            if let image = Image(atlasIcon: ItemIconAtlas.cgImage(icon)) {
                image.interpolation(.none).resizable()
                    .frame(width: size - 12, height: size - 12)
                    .opacity(0.85)
            }
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
    let size: CGFloat

    private var has: Bool { progress[keyPath: toggle.keyPath] }

    /// Border precedence ported from `veryBasicBoxImpl`'s redraw
    /// (`OverworldItemGridUI.fs:295-306`): held → superseded → located → none.
    private var borderColor: Color {
        if has { return .green }
        if superseded { return Color(white: 0.5) }
        if located { return .yellow }
        return Color(white: 0.3)
    }

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 4).fill(Color.black)
            if let image = Image(atlasIcon: ItemIconAtlas.cgImage(iconOverride ?? toggle.icon)) {
                image.interpolation(.none).resizable()
                    .frame(width: size - 10, height: size - 10)
                    .opacity(has ? 1 : 0.4)
            }
            // Superseded items are moot — mark with an X (the reference's
            // placeSkippedItemXDecoration).
            if superseded && !has {
                Image(systemName: "xmark")
                    .font(.system(size: size * 0.4, weight: .bold))
                    .foregroundStyle(.white.opacity(0.75))
            }
        }
        .frame(width: size, height: size)
        .overlay(
            RoundedRectangle(cornerRadius: 4).strokeBorder(borderColor, lineWidth: 1.5)
        )
        .onTapGesture { progress[keyPath: toggle.keyPath].toggle() }
        .onRightClick { progress[keyPath: toggle.keyPath] = false }
        .help(toggle.help)
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

    private var state: TakeAnyHeartState { progress.takeAnyHearts[index] }

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 4).fill(Color.black)
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
            RoundedRectangle(cornerRadius: 4).strokeBorder(Color(white: 0.3), lineWidth: 1.5)
        )
        .onTapGesture { cycle(1) }
        .onRightClick { cycle(-1) }
        .help("Take-any cave \(index + 1): \(state.label)")
    }

    /// The item taken, overlaid on the empty heart (potion / blue candle).
    @ViewBuilder
    private var overlayIcon: some View {
        switch state {
        case .takenPotion:
            // The potion-shop sprite (ow_icons5x9 index 5) doubles as the potion.
            if let potion = Image(atlasIcon: OverworldInteriorIconAtlas.icon(at: 5)) {
                potion.interpolation(.none).resizable()
                    .frame(width: (size - 12) * 0.7, height: (size - 12) * 0.9)
            }
        case .takenCandle:
            if let candle = Image(atlasIcon: ItemIconAtlas.cgImage(.blueCandle)) {
                candle.interpolation(.none).resizable()
                    .frame(width: (size - 12) * 0.8, height: (size - 12) * 0.8)
            }
        case .untaken, .takenHeart:
            EmptyView()
        }
    }

    private func cycle(_ delta: Int) {
        progress.takeAnyHearts[index] = ItemProgressGrid.cycledHeart(state, by: delta)
    }
}

