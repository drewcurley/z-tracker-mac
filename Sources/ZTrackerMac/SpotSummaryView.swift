import SwiftUI
import TrackerCore

/// Renders an overworld tile-mark's interior icon on a small tile, reusing the
/// same atlases as the map (T-053). Used by the Spot Summary; general enough to
/// reuse elsewhere.
struct OverworldMarkIcon: View {
    let mark: OverworldTileMark
    var size: CGFloat = 24
    var hideDungeonNumbers: Bool = false

    private static let anyRoadBg = Color(red: 218.0 / 255, green: 112.0 / 255, blue: 214.0 / 255)
    private static let hintBg = Color(white: 0.58)

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 4).fill(Theme.boxFill)
            content
        }
        .frame(width: size, height: size)
        .overlay(RoundedRectangle(cornerRadius: 4).strokeBorder(Theme.border, lineWidth: 1))
    }

    @ViewBuilder private var content: some View {
        switch mark.iconSource {
        case .dungeonDigit(let n):
            digit(DungeonLabeling.slotLabel(n, hideDungeonNumbers: hideDungeonNumbers), background: .yellow)
        case .anyRoadDigit(let n):
            digit("\(n)", background: Self.anyRoadBg)
        case .anyRoadUnknown:
            digit("?", background: Self.anyRoadBg)
        case .hintTile:
            digit("?", background: Self.hintBg)
        case .ghostRupee:
            // Pale-white ghost rupee (user request), matching the map/chooser glyph.
            if let cg = GameSprite.image("Rupy") {
                Image(decorative: cg, scale: 1, orientation: .up)
                    .interpolation(.none).resizable().scaledToFit()
                    .saturation(0).brightness(0.45).opacity(0.9)
                    .padding(size * 0.14)
            }
        case .interiorSprite(let idx):
            interiorSprite(idx)
        case .swordCaveItem(let level):
            swordCave(level)
        case .shopSprite(let idx):
            shopSprite(idx)
        case .none, .solidBlackTile:
            EmptyView()
        }
    }

    /// The plain interior sprites — prefer the real game sprite (matching the map, T-161);
    /// the sized secrets (small/medium/large = indices 9/6/8) are 1/2/3 five-rupee clusters;
    /// fall back to the old atlas glyph only when no sprite is mapped.
    @ViewBuilder private func interiorSprite(_ index: Int) -> some View {
        switch index {
        case 9: secretRupees(1)
        case 6: secretRupees(2)
        case 8: secretRupees(3)
        default:
            if let file = GameSprite.overworldFile(index: index), let cg = GameSprite.image(file) {
                gameSprite(cg, inset: size * 0.1)
            } else {
                sprite(OverworldInteriorIconAtlas.icon(at: index), inset: size * 0.14)
            }
        }
    }

    /// A cluster of `count` five-rupee sprites for a secret-money spot, mirroring the map.
    @ViewBuilder private func secretRupees(_ count: Int) -> some View {
        if let cg = GameSprite.image("5 Rupees") {
            HStack(spacing: -size * 0.05) {
                ForEach(0..<count, id: \.self) { _ in
                    Image(decorative: cg, scale: 1, orientation: .up)
                        .interpolation(.none).resizable().scaledToFit()
                }
            }
            .padding(size * 0.1)
        } else {
            sprite(OverworldInteriorIconAtlas.icon(at: count == 1 ? 9 : count == 2 ? 6 : 8), inset: size * 0.14)
        }
    }

    /// The sword-cave item — prefer the real game sword sprite (T-213), drawn on the box plate
    /// with a drop-shadow for contrast; fall back to the atlas glyph.
    @ViewBuilder private func swordCave(_ level: Int) -> some View {
        let icon = swordIcon(forCaveLevel: level)
        if let file = GameSprite.itemFile(icon), let cg = GameSprite.image(file) {
            gameSprite(cg, inset: size * 0.14, shadow: true)
        } else {
            sprite(ItemIconAtlas.cgImage(icon), inset: size * 0.16)
        }
    }

    /// A shop's primary item — the real game sprite drawn straight on the plate (no orange
    /// backing, matching the map after T-212); fall back to the atlas glyph.
    @ViewBuilder private func shopSprite(_ index: Int) -> some View {
        if index >= 0, index < ShopKind.allCases.count,
           let file = GameSprite.shopFile(ShopKind.allCases[index]), let cg = GameSprite.image(file) {
            gameSprite(cg, inset: size * 0.14, shadow: true)
        } else {
            sprite(OverworldShopIconAtlas.icon(at: index), inset: size * 0.18)
        }
    }

    /// A real game sprite, fit to the tile at its native aspect (crisp nearest-neighbor).
    @ViewBuilder private func gameSprite(_ cg: CGImage, inset: CGFloat, shadow: Bool = false) -> some View {
        Image(decorative: cg, scale: 1, orientation: .up)
            .interpolation(.none).resizable().scaledToFit()
            .shadow(color: shadow ? .black : .clear, radius: shadow ? 1 : 0)
            .padding(inset)
    }

    /// Cave level 1 / 2 / 3 → wood / white / magical sword (T-063). Only levels
    /// 1...3 reach here from `iconSource`; magical is the safe default.
    private func swordIcon(forCaveLevel level: Int) -> ItemIconAtlas.Icon {
        switch level {
        case 1: .brownSword
        case 2: .whiteSword
        default: .magicalSword
        }
    }

    @ViewBuilder private func sprite(_ cg: CGImage?, inset: CGFloat) -> some View {
        if let cg {
            Image(decorative: cg, scale: 1, orientation: .up)
                .interpolation(.none)
                .resizable()
                .scaledToFit()
                .padding(inset)
        }
    }

    private func digit(_ text: String, background: Color) -> some View {
        RoundedRectangle(cornerRadius: size * 0.18)
            .fill(background)
            .overlay(
                Text(text)
                    .font(.system(size: size * 0.5, weight: .heavy, design: .rounded))
                    .minimumScaleFactor(0.4)
                    .foregroundStyle(.black)
            )
            .padding(size * 0.12)
    }
}

/// The Spot Summary popover (T-053): unique overworld locations (dimmed once
/// marked) and money secrets remaining by size. Mirrors the reference's
/// `MakeRemainderSummaryDisplay`, minus the unknown-secret bin-shuffling — an
/// unsized secret is surfaced as a small note instead.
struct SpotSummaryView: View {
    /// What to show: one combined tally, or — in commentary mode — one tally per runner (T-234).
    let content: Content
    var hideDungeonNumbers: Bool = false
    /// How the two runner panes are arranged in dual (commentary) mode: side-by-side (default) or
    /// stacked. The breakout window switches to `.vertical` when it's too narrow for side-by-side
    /// (T-234); the inline popover always uses the default horizontal layout.
    var dualAxis: Axis = .horizontal

    /// A runner's column in the dual-pane (commentary) layout: their name, color, and the tally of
    /// only the spots they've been shown.
    struct RunnerColumn {
        let name: String
        let colorHex: String
        let summary: SpotSummary
    }

    enum Content {
        case single(SpotSummary)
        case dual(RunnerColumn, RunnerColumn)
    }

    /// Convenience for the plain (non-commentary) single-tally case — keeps existing call sites working.
    init(summary: SpotSummary, hideDungeonNumbers: Bool = false) {
        self.content = .single(summary)
        self.hideDungeonNumbers = hideDungeonNumbers
    }

    init(content: Content, hideDungeonNumbers: Bool = false, dualAxis: Axis = .horizontal) {
        self.content = content
        self.hideDungeonNumbers = hideDungeonNumbers
        self.dualAxis = dualAxis
    }

    /// One column's fixed width. The unique-locations grid (9 × 26pt) sets the floor.
    static let columnWidth: CGFloat = 300
    private static let hPadding: CGFloat = 14
    private static let columnGap: CGFloat = 12

    /// The view's natural width for the given content and dual-pane axis — the breakout window scales
    /// the whole view by (window width ÷ this) so it fills a resized window instead of leaving dead
    /// space. Single = 340 (unchanged); dual side-by-side = two columns + the divider gap + padding;
    /// dual stacked = a single column's width (the panes are full-width, one above the other).
    static func naturalWidth(for content: Content, axis: Axis = .horizontal) -> CGFloat {
        switch content {
        case .single: return 340
        case .dual: return axis == .horizontal ? columnWidth * 2 + columnGap + hPadding * 2
                                                : columnWidth + hPadding * 2
        }
    }

    private let uniqueColumns = Array(repeating: GridItem(.fixed(26), spacing: 5), count: 9)

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Remaining Locations Summary").font(.headline)
            switch content {
            case .single(let summary):
                sections(summary)
            case .dual(let r1, let r2):
                // One column per runner, split by a divider, each headed by the runner's name on a
                // color chip matching the map's commentary indicators (T-234). Side-by-side by
                // default; stacked when the breakout window is too narrow.
                if dualAxis == .horizontal {
                    HStack(alignment: .top, spacing: Self.columnGap) {
                        runnerColumn(r1)
                        Divider()
                        runnerColumn(r2)
                    }
                } else {
                    VStack(alignment: .leading, spacing: Self.columnGap) {
                        runnerColumn(r1)
                        Divider().frame(width: Self.columnWidth)
                        runnerColumn(r2)
                    }
                }
            }
        }
        .padding(Self.hPadding)
        .frame(width: Self.naturalWidth(for: content, axis: dualAxis))
    }

    @ViewBuilder private func runnerColumn(_ r: RunnerColumn) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 6) {
                RoundedRectangle(cornerRadius: 3)
                    .fill(Color(commentaryHex: r.colorHex))
                    .frame(width: 12, height: 12)
                Text(r.name).font(.subheadline).bold().lineLimit(1)
            }
            sections(r.summary)
        }
        .frame(width: Self.columnWidth, alignment: .leading)
    }

    /// The three tally sections (unique / secrets / non-unique) for one summary — rendered once in
    /// single mode, and once per runner column in dual mode.
    @ViewBuilder private func sections(_ summary: SpotSummary) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Unique locations").font(.caption).bold().foregroundStyle(.secondary)
                Text("Bright = to find · faded = found · dim = collected")
                    .font(.caption2).foregroundStyle(.secondary)
                LazyVGrid(columns: uniqueColumns, spacing: 5) {
                    ForEach(Array(summary.uniques.enumerated()), id: \.offset) { _, u in
                        OverworldMarkIcon(mark: u.mark, size: 24, hideDungeonNumbers: hideDungeonNumbers)
                            .opacity(uniqueOpacity(u))
                            .help("\(u.displayName): \(uniqueState(u))")
                    }
                }
            }

            Divider()

            VStack(alignment: .leading, spacing: 5) {
                Text("Secrets remaining").font(.caption).bold().foregroundStyle(.secondary)
                secretRow(.secret(.large), label: "Large",
                          total: summary.secretsTotal.large, remaining: summary.secretsRemaining.large)
                secretRow(.secret(.medium), label: "Medium",
                          total: summary.secretsTotal.medium, remaining: summary.secretsRemaining.medium)
                secretRow(.secret(.small), label: "Small",
                          total: summary.secretsTotal.small, remaining: summary.secretsRemaining.small)
                if summary.secretsPlaced.unknown > 0 {
                    Text("+ \(summary.secretsPlaced.unknown) marked without a size")
                        .font(.caption2).foregroundStyle(.orange)
                }
            }

            Divider()

            VStack(alignment: .leading, spacing: 5) {
                Text("Non-unique locations").font(.caption).bold().foregroundStyle(.secondary)
                Text("Number = still to find · bright icons = remaining")
                    .font(.caption2).foregroundStyle(.secondary)
                ForEach(Array(summary.nonUniques.enumerated()), id: \.offset) { _, nu in
                    nonUniqueRow(nu)
                }
            }
        }
    }

    /// Builds the display content from the model: a single combined tally, or — when commentary mode
    /// is on — one per-runner tally each filtered to the spots that runner has been shown (T-234).
    static func makeContent(model: TrackerModel, commentaryMode: Bool) -> Content {
        let quest = model.quest ?? .first
        func summary(_ include: @escaping (Int, Int) -> Bool) -> SpotSummary {
            SpotSummary.compute(
                grid: model.overworldGrid, quest: quest,
                armosDone: model.dungeonTracker.armosBox.isDone,
                whiteSwordItemDone: model.dungeonTracker.sword2Box.isDone,
                hasMagicalSword: model.playerComputedStateSummary.swordLevel >= 3,
                includeCell: include)
        }
        guard commentaryMode else { return .single(summary { _, _ in true }) }
        let c = model.commentary
        return .dual(
            RunnerColumn(name: c.runner1Name, colorHex: c.runner1ColorHex,
                         summary: summary { c.knowledge(column: $0, row: $1).contains(.runner1) }),
            RunnerColumn(name: c.runner2Name, colorHex: c.runner2ColorHex,
                         summary: summary { c.knowledge(column: $0, row: $1).contains(.runner2) }))
    }

    private func nonUniqueRow(_ nu: SpotSummary.NonUniqueCount) -> some View {
        HStack(spacing: 6) {
            Text("\(nu.remaining)")
                .font(.system(size: 13, weight: .bold, design: .rounded))
                .foregroundStyle(nu.remaining == 0 ? .secondary : .primary)
                .frame(width: 16, alignment: .trailing)
            Text(nu.displayName).font(.caption).foregroundStyle(.secondary)
                .frame(width: 100, alignment: .leading)
            HStack(spacing: 2) {
                ForEach(0..<max(nu.total, 0), id: \.self) { i in
                    OverworldMarkIcon(mark: nu.mark, size: 15).opacity(i < nu.remaining ? 1 : 0.28)
                }
            }
        }
        .help("\(nu.displayName): \(nu.marked) of \(nu.total) found, \(nu.remaining) left")
    }

    /// Bright when still to find; faded once found (placed); fully dim once
    /// collected (used). Non-claimable spots (dungeons/roads/swords) have no
    /// used state, so found → dim directly.
    private func uniqueOpacity(_ u: SpotSummary.UniqueSpot) -> Double {
        if u.used { return 0.28 }
        if u.placed { return u.mark.isUsedToggleable ? 0.6 : 0.28 }
        return 1
    }

    private func uniqueState(_ u: SpotSummary.UniqueSpot) -> String {
        if u.used { return "collected" }
        if u.placed { return u.mark.isUsedToggleable ? "found, not collected" : "found" }
        return "not yet found"
    }

    private func secretRow(_ mark: OverworldTileMark, label: String, total: Int, remaining: Int) -> some View {
        HStack(spacing: 6) {
            Text("\(remaining)")
                .font(.system(size: 13, weight: .bold, design: .rounded))
                .foregroundStyle(remaining == 0 ? .secondary : .primary)
                .frame(width: 16, alignment: .trailing)
            Text(label).font(.caption).foregroundStyle(.secondary).frame(width: 48, alignment: .leading)
            HStack(spacing: 2) {
                ForEach(0..<max(total, 0), id: \.self) { i in
                    // The first `remaining` are still out there (bright); the
                    // rest are already marked (dim).
                    OverworldMarkIcon(mark: mark, size: 18).opacity(i < remaining ? 1 : 0.28)
                }
            }
        }
    }
}

/// The broken-out Spot Summary window body (T-199): recomputes the summary live from the
/// model each render (the model is `@Observable`, so it stays current as marks change) and
/// shows it scrollably. The inline popover computes the same value; this just keeps it up.
struct SpotSummaryWindowView: View {
    let model: TrackerModel
    var options: TrackerOptions

    /// Clamp how far the summary scales: never smaller than ~0.8× (stays legible in a tiny
    /// window) nor larger than 3× (a huge window shouldn't make it comically big).
    private static let minScale: CGFloat = 0.8
    private static let maxScale: CGFloat = 3.0
    /// The window padding on each side that the content width must fit within.
    private static let hPadding: CGFloat = 14

    var body: some View {
        // Scale the whole summary to fill the window width (both up and down) — the window is
        // resizable, so match its size instead of leaving the fixed-width view stranded. In
        // commentary mode (dual-pane, T-234) the panes sit side-by-side while there's room, then
        // stack vertically once the window is too narrow to show them side-by-side without shrinking
        // past the minimum scale — at which point one full-width column reads far better.
        let content = SpotSummaryView.makeContent(model: model, commentaryMode: options.commentaryMode)
        let sideBySideWidth = SpotSummaryView.naturalWidth(for: content, axis: .horizontal)
        GeometryReader { proxy in
            let usable = max(proxy.size.width - Self.hPadding * 2, 1)
            // Stack the runner panes when side-by-side would have to shrink below the minimum scale.
            let axis: Axis = usable >= sideBySideWidth * Self.minScale ? .horizontal : .vertical
            let naturalWidth = SpotSummaryView.naturalWidth(for: content, axis: axis)
            let scale = min(max(usable / naturalWidth, Self.minScale), Self.maxScale)
            ScrollView([.vertical, .horizontal]) {
                SpotSummaryView(content: content, hideDungeonNumbers: model.hideDungeonNumbers, dualAxis: axis)
                    .scaledFootprint(scale, naturalWidth: naturalWidth)
                    .padding(Self.hPadding)
            }
        }
    }
}
