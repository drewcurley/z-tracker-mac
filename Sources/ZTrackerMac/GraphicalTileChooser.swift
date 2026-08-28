import AppKit
import SwiftUI
import TrackerCore

/// One selectable action in the graphical overworld tile chooser (T-185). Most are
/// a plain mark; the three take-any variants set a claimed state (not a mark), and
/// the start-spot cell places the spawn marker.
enum OverworldChooserAction: Equatable {
    case mark(OverworldTileMark)
    case takeAny(TakeAnyHeartState)   // .takenPotion / .takenHeart / .takenCandle
    case startSpot
}

/// The chooser's fixed 5×8 layout (user-specified, T-185), independent of the
/// "shops before dungeons" ordering the text menu uses. Pure + testable.
///
/// - Row 1: the 8 shop items
/// - Row 2: the 4 secrets, money-making game, door repair, hint, potion
/// - Row 3: letter, armos, take-any potion/candle/heart (in-game order), don't-care,
///   unmarked, start
/// - Row 4: levels 1–8
/// - Row 5: level 9, any-road 1–4, sword caves 1–3
///
/// The "?" any-road isn't offered here — in the chooser you always know the warp's
/// number in the rotation.
enum OverworldChooserLayout {
    static let rows: [[OverworldChooserAction]] = [
        ShopKind.allCases.map { .mark(.shop($0)) },
        [.mark(.secret(.small)), .mark(.secret(.medium)), .mark(.secret(.large)), .mark(.secret(.unknown)),
         .mark(.moneyMakingGame), .mark(.doorRepair), .mark(.hintShop), .mark(.potionShop)],
        [.mark(.theLetter), .mark(.armos),
         .takeAny(.takenPotion), .takeAny(.takenCandle), .takeAny(.takenHeart),
         .mark(.dontCare), .mark(.unmarked), .startSpot],
        (1...8).map { .mark(.dungeon($0)) },
        [.mark(.dungeon(9)), .mark(.anyRoad(1)), .mark(.anyRoad(2)), .mark(.anyRoad(3)), .mark(.anyRoad(4)),
         .mark(.swordCave(1)), .mark(.swordCave(2)), .mark(.swordCave(3))],
    ]

    /// Flattened, for tests / iteration.
    static var all: [OverworldChooserAction] { rows.flatMap { $0 } }
}

/// The graphical overworld tile chooser popover (T-185) — a grid of icons instead
/// of the text menu, because graphics read faster than menu text. Reuses the map's
/// own `TileView` glyphs so each option looks exactly like the placed tile.
struct GraphicalTileChooser: View {
    /// The tile being edited, for highlighting its current mark / start-spot state.
    var currentMark: OverworldTileMark
    var isStartSpot: Bool
    var hideDungeonNumbers: Bool
    /// Whether a mark is exhausted (all copies placed) → dim + disable, matching the menu.
    var isExhausted: (OverworldTileMark) -> Bool
    var onPick: (OverworldChooserAction) -> Void

    private static let cell: CGFloat = 30
    private static let gap: CGFloat = 4

    /// The label of the icon the pointer is currently over, shown live in the header so you
    /// don't have to wait out the system tooltip delay (T-205).
    @State private var hoverLabel: String?

    var body: some View {
        VStack(spacing: Self.gap) {
            Text(hoverLabel ?? (currentMark == .unmarked ? "Unmarked" : currentMark.displayName))
                .font(.caption).foregroundStyle(hoverLabel == nil ? Color.secondary : Color.primary)
                .lineLimit(1)
            ForEach(Array(OverworldChooserLayout.rows.enumerated()), id: \.offset) { _, row in
                HStack(spacing: Self.gap) {
                    ForEach(Array(row.enumerated()), id: \.offset) { _, action in
                        cellButton(action)
                    }
                }
            }
        }
        .padding(10)
    }

    @ViewBuilder
    private func cellButton(_ action: OverworldChooserAction) -> some View {
        let disabled = isDisabled(action)
        Button {
            if !disabled { onPick(action) }
        } label: {
            ZStack {
                RoundedRectangle(cornerRadius: 4).fill(.black)
                glyph(action)
            }
            .frame(width: Self.cell, height: Self.cell)
            .overlay(
                RoundedRectangle(cornerRadius: 4)
                    .strokeBorder(isSelected(action) ? Color.accentColor : Color(white: 0.28),
                                  lineWidth: isSelected(action) ? 2 : 1)
            )
            .opacity(disabled ? 0.3 : 1)
        }
        .buttonStyle(.plain)
        .disabled(disabled)
        .help(tooltip(action))
        // Live header label on hover (T-205) — instant, unlike the delayed system tooltip.
        // Clear only if *this* cell's label is still showing, so moving between cells (whose
        // enter/exit events can arrive in either order) doesn't wrongly blank the header.
        .onHover { inside in
            let label = tooltip(action)
            if inside { hoverLabel = label }
            else if hoverLabel == label { hoverLabel = nil }
        }
    }

    @ViewBuilder
    private func glyph(_ action: OverworldChooserAction) -> some View {
        switch action {
        case .mark(.unmarked):
            Image(systemName: "xmark").font(.system(size: 12)).foregroundStyle(.white)
        case .mark(let m):
            // Reuse the map's glyph on our black plate (sharedBackground = draw only the glyph).
            TileView(mark: m, background: nil, tileWidth: Self.cell, tileHeight: Self.cell,
                     hideDungeonNumbers: hideDungeonNumbers, sharedBackground: true)
        case .takeAny(let state):
            TakeAnyVariantGlyph(state: state, size: Self.cell)
        case .startSpot:
            Image(systemName: "figure.walk")
                .font(.system(size: 15, weight: .bold))
                .foregroundStyle(Color(red: 0.6, green: 0.4, blue: 0.9))
        }
    }

    private func isDisabled(_ action: OverworldChooserAction) -> Bool {
        switch action {
        case .mark(.unmarked), .mark(.dontCare), .startSpot: false
        case .mark(let m): isExhausted(m)
        case .takeAny: isExhausted(.takeAny)
        }
    }

    private func isSelected(_ action: OverworldChooserAction) -> Bool {
        switch action {
        case .mark(let m): return currentMark == m
        case .startSpot: return isStartSpot
        case .takeAny: return currentMark == .takeAny
        }
    }

    private func tooltip(_ action: OverworldChooserAction) -> String {
        switch action {
        case .mark(.unmarked): "Clear (unmarked)"
        // Sword caves read swordless-aware (user request, T-185).
        case .mark(.swordCave(1)): "Wood sword (or candle cave if swordless)"
        case .mark(.swordCave(2)): "White sword item"
        case .mark(.swordCave(3)): "Magical sword (or magical bomb upgrade if swordless)"
        case .mark(let m): m.displayName
        case .takeAny(let s): "Take-any: \(s.label)"
        case .startSpot: "Set as start spot"
        }
    }
}

/// A take-any variant icon (potion / heart / blue candle) for the chooser, mirroring
/// the Items-grid take-any box: an empty heart (full+pink for the heart variant) with
/// the taken item overlaid.
struct TakeAnyVariantGlyph: View {
    let state: TakeAnyHeartState
    let size: CGFloat

    var body: some View {
        ZStack {
            let base: OverworldHeartAtlas.Icon = state == .takenHeart ? .full : .empty
            if let image = Image(atlasIcon: OverworldHeartAtlas.cgImage(base)) {
                image.interpolation(.none).resizable()
                    .frame(width: size - 12, height: size - 12)
            }
            switch state {
            case .takenPotion:
                Group {
                    if let cg = GameSprite.image("Life Potion") {
                        Image(decorative: cg, scale: 1, orientation: .up).resizable().interpolation(.none)
                    } else if let potion = Image(atlasIcon: OverworldInteriorIconAtlas.icon(at: 5)) {
                        potion.interpolation(.none).resizable()
                    }
                }
                .frame(width: (size - 12) * 0.7, height: (size - 12) * 0.9)
            case .takenCandle:
                ItemGlyph(.blueCandle).frame(width: (size - 12) * 0.8, height: (size - 12) * 0.8)
            case .untaken, .takenHeart:
                EmptyView()
            }
        }
    }
}

/// Renders an overworld enemy icon: the dungeon-sheet sprite when it has one, else the
/// game-sprite GIF for the overworld-only enemies (octorok / peahat / leever, T-185).
struct OverworldEnemyGlyph: View {
    let enemy: MonsterDetail
    let size: CGFloat

    var body: some View {
        if let atlas = DungeonMonsterAtlas.sprite(enemy), let img = Image(atlasIcon: atlas) {
            img.interpolation(.none).resizable().frame(width: size, height: size)
        } else if let cg = GameSprite.image(Self.gifName(enemy)) {
            Image(decorative: cg, scale: 1, orientation: .up)
                .resizable().interpolation(.none).aspectRatio(contentMode: .fit)
                .frame(width: size, height: size)
        }
    }

    static func gifName(_ enemy: MonsterDetail) -> String {
        switch enemy {
        case .octorok: "Octorok - Red (Front)"
        case .peahat: "Peahat"
        case .leever: "Leever - Red1"
        case .bombDroppers: "Bomb"   // generic bomb-droppers marker (T-217)
        default: ""
        }
    }
}

/// The overworld enemy picker (T-185) — opened by scrolling up on a tile when the
/// graphical chooser is active, mirroring the dungeon-room scroll-to-monster. Uses
/// the reduced overworld enemy set (`MonsterDetail.overworldEnemies`) already offered
/// in the text menu; each pick toggles the tile's up-to-two enemy annotation.
struct OverworldEnemyPicker: View {
    var current: [MonsterDetail]
    var onToggle: (MonsterDetail) -> Void
    var onClear: () -> Void
    var onDone: () -> Void

    private let columns = Array(repeating: GridItem(.fixed(34), spacing: 4), count: 6)

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Enemies (up to two)").font(.caption).foregroundStyle(.secondary)
                Spacer()
                Button("Done") { onDone() }.font(.caption)
            }
            LazyVGrid(columns: columns, spacing: 4) {
                ForEach(Array(MonsterDetail.overworldEnemies.enumerated()), id: \.offset) { _, enemy in
                    Button { onToggle(enemy) } label: {
                        ZStack {
                            RoundedRectangle(cornerRadius: 4)
                                .fill(current.contains(enemy) ? Color.accentColor.opacity(0.5) : Color(white: 0.14))
                            OverworldEnemyGlyph(enemy: enemy, size: 26)
                        }
                        .frame(width: 34, height: 34)
                    }
                    .buttonStyle(.plain)
                    .help(enemy.displayName)
                }
            }
            if !current.isEmpty {
                Button("Clear enemies") { onClear() }.font(.caption)
            }
        }
        .padding(10)
        .frame(width: 236)
    }
}

/// A transparent overlay that intercepts **only** scroll-wheel events, forwarding an
/// upward scroll (T-185). Clicks/hover fall through to the SwiftUI tile beneath
/// (`hitTest` returns nil unless the current event is a scroll), mirroring how
/// `RoomMouseCatcher` gates its hit testing.
struct ScrollUpCatcher: NSViewRepresentable {
    var onScrollUp: () -> Void

    func makeNSView(context: Context) -> NSView {
        let v = CatcherView()
        v.onScrollUp = onScrollUp
        return v
    }
    func updateNSView(_ nsView: NSView, context: Context) {
        (nsView as? CatcherView)?.onScrollUp = onScrollUp
    }

    final class CatcherView: NSView {
        var onScrollUp: () -> Void = {}
        override func hitTest(_ point: NSPoint) -> NSView? {
            NSApp.currentEvent?.type == .scrollWheel ? super.hitTest(point) : nil
        }
        override func scrollWheel(with event: NSEvent) {
            if event.scrollingDeltaY > 0 { onScrollUp() }
        }
    }
}
