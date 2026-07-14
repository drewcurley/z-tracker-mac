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

    /// The take-any heart tri-state advanced by `delta` (wrapping), ported
    /// from the reference's `(cur + delta + 3) % 3` (`OverworldItemGridUI.fs:207`).
    static func cycledHeart(_ state: TakeAnyHeartState, by delta: Int) -> TakeAnyHeartState {
        TakeAnyHeartState(rawValue: ((state.rawValue + delta) % 3 + 3) % 3) ?? state
    }
}

extension ItemProgressGrid.CoastBox: Equatable {}
extension ItemProgressGrid.ItemToggle: Equatable {}

/// The overworld item grid (T-025.1): the reference's top-right `owItemGrid`,
/// re-laid-out cleanly. Toggle boxes flip a `PlayerProgressAndTakeAnyHearts`
/// flag on click; the three coast/armos/white-sword boxes are full item
/// pickers (reused `BoxView`). Located/superseded highlighting and the
/// take-any hearts row are later T-025 sub-tasks.
struct ItemProgressGridView: View {
    @Bindable var model: TrackerModel
    /// Live derived state driving the located (yellow) / superseded (gray-X)
    /// box highlighting (T-025.3). Supplied by the parent, which already
    /// computes them for the overworld map.
    var playerState: PlayerComputedStateSummary
    var mapState: MapStateSummary

    private static let cellSize: CGFloat = 34

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Items").font(.caption2).foregroundStyle(.secondary)
            Grid(horizontalSpacing: 6, verticalSpacing: 6) {
                ForEach(0..<ItemProgressGrid.rows, id: \.self) { row in
                    GridRow {
                        ForEach(0..<ItemProgressGrid.columns, id: \.self) { col in
                            cellView(ItemProgressGrid.layout[row][col])
                        }
                    }
                }
            }
            Divider().overlay(Color(white: 0.2))
            swordlessToggle
            bookShieldToggle
            MaxHeartsControl(startingItems: model.startingItemsAndExtras, hearts: playerState.playerHearts)
        }
        .padding(8)
        .background(RoundedRectangle(cornerRadius: 8).fill(Color(white: 0.09)))
    }

    /// The swordless (WSMS→Bomb Upgrade) seed toggle. When on, the White Sword
    /// and Magical Sword are Bomb Upgrades (`isWSMSReplacedByBU`).
    private var swordlessToggle: some View {
        Toggle(isOn: $model.isWSMSReplacedByBU) {
            iconLabel(.wsMsBombUpgrade, "Swordless (White / Magical Sword → Bomb Upgrade)")
        }
        .toggleStyle(.checkbox)
        .help("Swordless seed: the White Sword and Magical Sword are replaced by Bomb Upgrades")
    }

    /// Book vs Magic Shield for item slot 0 (boomstick seeds). Checked = shield
    /// (`isCurrentlyBook == false`), matching the reference's "Shield instead of
    /// book" checkbox.
    private var bookShieldToggle: some View {
        Toggle(isOn: Binding(get: { !model.isCurrentlyBook }, set: { model.isCurrentlyBook = !$0 })) {
            iconLabel(model.isCurrentlyBook ? .book : .magicShield, "Shield instead of book (boomstick seeds)")
        }
        .toggleStyle(.checkbox)
        .help("When checked, item slot 0 is the Magic Shield instead of the Book (boomstick seeds)")
    }

    private func iconLabel(_ icon: ItemIconAtlas.Icon, _ text: String) -> some View {
        HStack(spacing: 5) {
            if let img = Image(atlasIcon: ItemIconAtlas.cgImage(icon)) {
                img.interpolation(.none).resizable().frame(width: 16, height: 16)
            }
            Text(text).font(.system(size: 10))
        }
    }

    @ViewBuilder
    private func cellView(_ cell: ItemProgressGrid.Cell) -> some View {
        switch cell {
        case .indicator(let coast):
            IndicatorCell(icon: coast.indicator, help: coast.help, size: Self.cellSize)
        case .pickerBox(let coast):
            BoxView(box: coast.box(in: model.dungeonTracker), instance: model.dungeonTracker,
                    label: nil, iconOptions: model.iconOptions)
                .help(coast.help)
        case .toggle(let toggle):
            ItemToggleBox(
                progress: model.playerProgress,
                toggle: toggle,
                iconOverride: (toggle == .magicalSword && model.isWSMSReplacedByBU) ? .wsMsBombUpgrade : nil,
                located: toggle.located(playerState: playerState, mapState: mapState),
                superseded: toggle.superseded(playerState: playerState),
                size: Self.cellSize
            )
        case .takeAnyHeart(let i):
            TakeAnyHeartBox(progress: model.playerProgress, index: i, size: Self.cellSize)
        case .empty:
            Color.clear.frame(width: Self.cellSize, height: Self.cellSize)
        }
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

/// One of the 4 overworld "take-any" heart-cave slots. Left-click cycles the
/// tri-state forward, right-click backward — the reference's
/// `(cur + delta + 3) % 3` on `MouseLeftButtonDown`/`MouseRightButtonDown`
/// (`OverworldItemGridUI.fs:207-209`): untaken → taken-heart → taken-
/// potion/candle. The heart sprite is full when a heart was taken, empty
/// otherwise; an X marks the potion/candle choice.
private struct TakeAnyHeartBox: View {
    var progress: PlayerProgressAndTakeAnyHearts
    let index: Int
    let size: CGFloat

    private var state: TakeAnyHeartState { progress.takeAnyHearts[index] }

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 4).fill(Color.black)
            let sprite: OverworldHeartAtlas.Icon = state == .takenHeart ? .full : .empty
            if let image = Image(atlasIcon: OverworldHeartAtlas.cgImage(sprite)) {
                image.interpolation(.none).resizable()
                    .frame(width: size - 12, height: size - 12)
            }
            if state == .takenPotionOrCandle {
                Image(systemName: "xmark")
                    .font(.system(size: 12, weight: .heavy))
                    .foregroundStyle(.white.opacity(0.85))
            }
        }
        .frame(width: size, height: size)
        .overlay(
            RoundedRectangle(cornerRadius: 4).strokeBorder(Color(white: 0.3), lineWidth: 1.5)
        )
        .onTapGesture { cycle(1) }
        .onRightClick { cycle(-1) }
        .help("Take-any cave \(index + 1): heart / potion-or-candle")
    }

    private func cycle(_ delta: Int) {
        progress.takeAnyHearts[index] = ItemProgressGrid.cycledHeart(state, by: delta)
    }
}

/// Max-hearts readout + adjust, ported from the reference's max-hearts panel
/// (`OverworldItemGridUI.fs:542-556`): shows the derived `playerHearts` and
/// steps `maxHeartsDifferential` (nested `@Bindable` so the stepper can mutate
/// the observable starting-items object).
private struct MaxHeartsControl: View {
    @Bindable var startingItems: StartingItemsAndExtras
    var hearts: Int

    var body: some View {
        HStack(spacing: 6) {
            Text("Max Hearts: \(hearts)")
                .font(.system(size: 10)).foregroundStyle(.orange)
            Stepper("", value: $startingItems.maxHeartsDifferential, in: -8...16)
                .labelsHidden().controlSize(.mini)
        }
        .help("Adjust starting/bonus max hearts (the differential from the default of 3)")
    }
}
