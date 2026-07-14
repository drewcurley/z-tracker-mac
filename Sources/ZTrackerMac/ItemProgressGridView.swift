import SwiftUI
import TrackerCore

/// Pure, testable description of the overworld item-grid layout (T-025.1) —
/// the reference's `owItemGrid` cell arrangement (`OW_ITEM_GRID_LOCATIONS`,
/// `Z1R_Avalonia/OverworldMapTileCustomization.fs:17-42`), 5 columns × 3 rows.
/// Separated from the SwiftUI view so the cell → content mapping is unit-
/// testable without a running app.
enum ItemProgressGrid {
    static let columns = 5
    static let rows = 3

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
    }

    /// The 3×5 grid content, ported cell-for-cell from `OW_ITEM_GRID_LOCATIONS`
    /// (only the columns/rows this sub-task renders; take-any hearts row is
    /// T-025.2). `layout[row][col]`.
    static let layout: [[Cell]] = [
        // row 0
        [.indicator(.whiteSword), .pickerBox(.whiteSword), .toggle(.magicalSword), .toggle(.woodSword), .toggle(.boomBook)],
        // row 1
        [.indicator(.coast), .pickerBox(.coast), .toggle(.blueCandle), .toggle(.woodArrow), .toggle(.blueRing)],
        // row 2
        [.indicator(.armos), .pickerBox(.armos), .toggle(.bomb), .toggle(.ganon), .toggle(.zelda)],
    ]

    /// The cell at a position (nil if out of range) — the testable mapping.
    static func cell(row: Int, col: Int) -> Cell? {
        guard layout.indices.contains(row), layout[row].indices.contains(col) else { return nil }
        return layout[row][col]
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
    var model: TrackerModel

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
        }
        .padding(8)
        .background(RoundedRectangle(cornerRadius: 8).fill(Color(white: 0.09)))
    }

    @ViewBuilder
    private func cellView(_ cell: ItemProgressGrid.Cell) -> some View {
        switch cell {
        case .indicator(let coast):
            IndicatorCell(icon: coast.indicator, help: coast.help, size: Self.cellSize)
        case .pickerBox(let coast):
            BoxView(box: coast.box(in: model.dungeonTracker), instance: model.dungeonTracker, label: nil)
                .help(coast.help)
        case .toggle(let toggle):
            ItemToggleBox(
                progress: model.playerProgress,
                toggle: toggle,
                iconOverride: (toggle == .magicalSword && model.isWSMSReplacedByBU) ? .wsMsBombUpgrade : nil,
                size: Self.cellSize
            )
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
    let size: CGFloat

    private var has: Bool { progress[keyPath: toggle.keyPath] }

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 4).fill(Color.black)
            if let image = Image(atlasIcon: ItemIconAtlas.cgImage(iconOverride ?? toggle.icon)) {
                image.interpolation(.none).resizable()
                    .frame(width: size - 10, height: size - 10)
                    .opacity(has ? 1 : 0.4)
            }
        }
        .frame(width: size, height: size)
        .overlay(
            RoundedRectangle(cornerRadius: 4)
                .strokeBorder(has ? Color.green : Color(white: 0.3), lineWidth: 1.5)
        )
        .onTapGesture { progress[keyPath: toggle.keyPath].toggle() }
        .onRightClick { progress[keyPath: toggle.keyPath] = false }
        .help(toggle.help)
    }
}
