import CoreGraphics
import SwiftUI
import TrackerCore

/// The overworld map (docs/domain.md § 4.5, T-006 core data model +
/// interaction, T-007 tile-mark sprite rendering, T-008 terrain background).
/// Renders the reference app's actual terrain art
/// (`s_map_overworld_vanilla_strip8.png`, per selected quest, via
/// `OverworldBackgroundAtlas`) as the base layer, with tile-mark icons
/// (`s_icon_overworld_strip39.png`, via `OverworldIconAtlas`) composited on
/// top wherever a mark is set. Both assets are MIT-licensed — see
/// `/NOTICE.md`.
///
/// Confirmed gestures implemented: left-click an unmarked tile marks it
/// `.dontCare` ("dark"); left-click a `.dontCare` tile, or right-click any
/// tile, opens a mark-selection menu. The reference app's actual popup UI
/// shape (a custom grid-of-icons picker) is a follow-up — a context menu is
/// this task's functional stand-in, not a guess at the real design.
struct OverworldMapView: View {
    var grid: OverworldGrid
    var quest: OverworldQuest

    /// Aspect ratio matches the reference app's base tile shape (16×11px,
    /// `Graphics.fs` `OMTW`/`OMTH` — resolves a previously-open question in
    /// `docs/domain.md` about the layout's numeric constants) — kept even
    /// though this view doesn't render the real sprites yet, so later sprite
    /// integration doesn't have to fight a mismatched grid shape.
    private let tileAspectRatio: CGFloat = 16.0 / 11.0

    var body: some View {
        GeometryReader { geometry in
            let tileWidth = geometry.size.width / CGFloat(OverworldGrid.columnCount)
            let tileHeight = tileWidth / tileAspectRatio

            VStack(spacing: 0) {
                ForEach(0..<OverworldGrid.rowCount, id: \.self) { row in
                    HStack(spacing: 0) {
                        ForEach(0..<OverworldGrid.columnCount, id: \.self) { column in
                            let mark = grid.mark(column: column, row: row)
                            let background = OverworldBackgroundAtlas.tile(quest: quest, column: column, row: row)
                            TileView(mark: mark, background: background)
                                .frame(width: tileWidth, height: tileHeight)
                                .onTapGesture { handleLeftClick(column: column, row: row) }
                                .contextMenu { markMenu(column: column, row: row) }
                                // Custom-drawn tiles (Rectangle + onTapGesture) have NO
                                // accessibility representation by default -- confirmed by
                                // inspecting the accessibility tree while testing this view,
                                // not assumed. VoiceOver users could not otherwise perceive
                                // or activate any of these 128 tiles. See docs/ux.md
                                // "Accessibility baseline" -- this is the first view with
                                // fully custom interactive elements, so it's handled here
                                // rather than deferred again.
                                .accessibilityElement(children: .ignore)
                                .accessibilityLabel("Overworld tile, column \(column + 1), row \(row + 1)")
                                .accessibilityValue(mark.displayName)
                                .accessibilityAddTraits(.isButton)
                                .accessibilityAction { handleLeftClick(column: column, row: row) }
                        }
                    }
                }
            }
        }
        .aspectRatio(tileAspectRatio * CGFloat(OverworldGrid.columnCount) / CGFloat(OverworldGrid.rowCount), contentMode: .fit)
    }

    private func handleLeftClick(column: Int, row: Int) {
        // "LC unmarked → mark dark" (docs/domain.md § 4.5). Left-click on an
        // already-dark tile is handled by the context menu, matching "LC
        // dark tile ... → popup" — SwiftUI's contextMenu also responds to a
        // plain click when attached this way is avoided by only mutating
        // state here for the unmarked case.
        if grid.mark(column: column, row: row) == .unmarked {
            grid.setMark(.dontCare, column: column, row: row)
        }
    }

    @ViewBuilder
    private func markMenu(column: Int, row: Int) -> some View {
        Button("Clear (unmarked)") { grid.setMark(.unmarked, column: column, row: row) }
        Button("Don't care") { grid.setMark(.dontCare, column: column, row: row) }
        Divider()
        Menu("Dungeon") {
            ForEach(1...9, id: \.self) { number in
                Button("Dungeon \(number)") { grid.setMark(.dungeon(number), column: column, row: row) }
            }
        }
        Menu("Any road") {
            ForEach(1...4, id: \.self) { number in
                Button("Any road \(number)") { grid.setMark(.anyRoad(number), column: column, row: row) }
            }
        }
        Menu("Sword cave") {
            ForEach(1...3, id: \.self) { number in
                Button("Sword cave \(number)") { grid.setMark(.swordCave(number), column: column, row: row) }
            }
        }
        Menu("Shop") {
            ForEach(ShopKind.allCases, id: \.self) { kind in
                Button(kind.displayName) { grid.setMark(.shop(kind), column: column, row: row) }
            }
        }
        Menu("Secret") {
            ForEach(SecretSize.allCases, id: \.self) { size in
                Button(size.displayName) { grid.setMark(.secret(size), column: column, row: row) }
            }
        }
        Divider()
        Button("Door repair") { grid.setMark(.doorRepair, column: column, row: row) }
        Button("Money making game") { grid.setMark(.moneyMakingGame, column: column, row: row) }
        Button("The letter") { grid.setMark(.theLetter, column: column, row: row) }
        Button("Armos") { grid.setMark(.armos, column: column, row: row) }
        Button("Hint shop") { grid.setMark(.hintShop, column: column, row: row) }
        Button("Take any") { grid.setMark(.takeAny, column: column, row: row) }
        Button("Potion shop") { grid.setMark(.potionShop, column: column, row: row) }
    }
}

/// A single tile's visual: the real terrain background (T-008) as the base
/// layer, with the real tile-mark icon (T-007) composited on top wherever a
/// mark is set. `.unmarked` tiles show terrain alone, undecorated — matching
/// how the reference app's map looks before the player has marked anything.
/// Falls back to a colored placeholder + abbreviation only if the terrain
/// image failed to load (defensive, not expected in practice).
private struct TileView: View {
    var mark: OverworldTileMark
    var background: CGImage?

    var body: some View {
        Group {
            if let background {
                Image(decorative: background, scale: 1, orientation: .up)
                    .resizable()
                    .interpolation(.none)
                    .aspectRatio(contentMode: .fill)
            } else {
                Rectangle().fill(color)
            }
        }
        .overlay {
            if let index = mark.iconStripIndex, let icon = OverworldIconAtlas.icon(at: index) {
                Image(decorative: icon, scale: 1, orientation: .up)
                    .resizable()
                    .interpolation(.none) // crisp nearest-neighbor, matches the reference app's own integer scaling
                    .aspectRatio(contentMode: .fit)
                    .padding(1)
            } else if background == nil {
                // Only show the text fallback when terrain also failed to load --
                // otherwise .unmarked tiles would get a spurious empty overlay.
                Text(abbreviation)
                    .font(.system(size: 8))
                    .foregroundStyle(.white)
                    .lineLimit(1)
                    .minimumScaleFactor(0.5)
            }
        }
        .overlay(Rectangle().stroke(.black.opacity(0.3), lineWidth: 0.5))
    }

    private var color: Color {
        switch mark {
        case .unmarked: .gray.opacity(0.3)
        case .dontCare: .black.opacity(0.6)
        case .dungeon: .orange
        case .anyRoad: .yellow
        case .swordCave: .red
        case .shop: .blue
        case .secret: .purple
        case .doorRepair: .brown
        case .moneyMakingGame: .green
        case .theLetter: .cyan
        case .armos: .pink
        case .hintShop: .indigo
        case .takeAny: .mint
        case .potionShop: .teal
        }
    }

    private var abbreviation: String {
        switch mark {
        case .unmarked: ""
        case .dontCare: "·"
        case .dungeon(let n): "D\(n)"
        case .anyRoad(let n): "R\(n)"
        case .swordCave(let n): "S\(n)"
        case .shop: "$"
        case .secret: "?"
        case .doorRepair: "DR"
        case .moneyMakingGame: "MG"
        case .theLetter: "L"
        case .armos: "A"
        case .hintShop: "H"
        case .takeAny: "T"
        case .potionShop: "P"
        }
    }
}

/// Loads the reference app's overworld tile-icon strip once and crops
/// individual icons on demand. Each icon is exactly 16×11px
/// (`docs/domain.md` § 4.5/§ 6, grounded in `Graphics.fs`'s `OMTW` constant
/// and a direct `sips` measurement of the strip). Uses plain `CGImage`
/// cropping + SwiftUI `Image(decorative:)` with `.interpolation(.none)`
/// rather than a `Canvas`-based draw call (ADR 0002's stated plan) — for a
/// single static per-tile icon these are equivalent in output (both give
/// nearest-neighbor-scaled, uninterpolated pixels); `Canvas` would matter
/// more for compositing many icons in one custom draw pass, which isn't
/// needed here. Revisit with `Canvas` if a future task needs that (e.g.
/// layering multiple icons/overlays on one tile).
enum OverworldIconAtlas {
    static let iconWidth = 16
    static let iconHeight = 11
    /// The strip has 39 images total; only indices reachable via
    /// `OverworldTileMark.iconStripIndex` (0...35) are ever requested.
    static let iconCount = 39

    private static let fullImage: CGImage? = {
        guard
            let url = Bundle.module.url(forResource: "s_icon_overworld_strip39", withExtension: "png"),
            let dataProvider = CGDataProvider(url: url as CFURL),
            let image = CGImage(
                pngDataProviderSource: dataProvider,
                decode: nil,
                shouldInterpolate: false,
                intent: .defaultIntent
            )
        else { return nil }
        return image
    }()

    static func icon(at index: Int) -> CGImage? {
        guard let fullImage, (0..<iconCount).contains(index) else { return nil }
        let rect = CGRect(x: index * iconWidth, y: 0, width: iconWidth, height: iconHeight)
        return fullImage.cropping(to: rect)
    }
}

/// Loads the reference app's overworld terrain-art strip once and crops
/// individual 16×11px terrain tiles on demand, per quest (T-008). The
/// source (`s_map_overworld_vanilla_strip8.png`, 1280×88px) is 5
/// horizontal sections of 256×88px each — the first 4 are the real quest
/// layouts (`OverworldQuest.referenceAppIndex`, grounded in
/// `OverworldData.fs`'s `OWQuest.AsInt`), the 5th is unused/blank (the
/// reference app's `OWQuest.BLANK`, which maps to the already-deferred
/// "alternative overworld map" mode — not read here). Each 256×88px section
/// is itself a 16×8 grid of 16×11px tiles, identical in shape to
/// `OverworldIconAtlas`'s icons — confirmed via `Graphics.fs`'s
/// `overworldMapBMPs` pixel-indexing math, not guessed.
enum OverworldBackgroundAtlas {
    static let tileWidth = 16
    static let tileHeight = 11
    static let sectionWidth = tileWidth * OverworldGrid.columnCount // 256
    static let questCount = 4 // FIRST, SECOND, MIXED_FIRST, MIXED_SECOND -- BLANK excluded, see above

    private static let fullImage: CGImage? = {
        guard
            let url = Bundle.module.url(forResource: "s_map_overworld_vanilla_strip8", withExtension: "png"),
            let dataProvider = CGDataProvider(url: url as CFURL),
            let image = CGImage(
                pngDataProviderSource: dataProvider,
                decode: nil,
                shouldInterpolate: false,
                intent: .defaultIntent
            )
        else { return nil }
        return image
    }()

    static func tile(quest: OverworldQuest, column: Int, row: Int) -> CGImage? {
        guard
            let fullImage,
            (0..<OverworldGrid.columnCount).contains(column),
            (0..<OverworldGrid.rowCount).contains(row)
        else { return nil }
        let sectionX = quest.referenceAppIndex * sectionWidth
        let rect = CGRect(
            x: sectionX + column * tileWidth,
            y: row * tileHeight,
            width: tileWidth,
            height: tileHeight
        )
        return fullImage.cropping(to: rect)
    }
}

#Preview {
    OverworldMapView(grid: OverworldGrid(), quest: .first)
        .frame(width: 800)
        .padding()
}
