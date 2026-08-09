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
    private static let shopBg = Color(red: 0xEF / 255.0, green: 0x83 / 255.0, blue: 0)
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
            sprite(OverworldInteriorIconAtlas.icon(at: idx), inset: size * 0.14)
        case .swordCaveItem(let level):
            // High-fidelity Items-area sword sprite (T-063); the black box below
            // already provides the plate, so just inset the sword.
            sprite(ItemIconAtlas.cgImage(swordIcon(forCaveLevel: level)), inset: size * 0.16)
        case .shopSprite(let idx):
            ZStack {
                Self.shopBg
                sprite(OverworldShopIconAtlas.icon(at: idx), inset: size * 0.18)
            }
            .clipShape(RoundedRectangle(cornerRadius: 4))
            .padding(size * 0.1)
        case .none, .solidBlackTile:
            EmptyView()
        }
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
    let summary: SpotSummary
    var hideDungeonNumbers: Bool = false

    private let uniqueColumns = Array(repeating: GridItem(.fixed(26), spacing: 5), count: 9)

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Remaining Locations Summary").font(.headline)

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
        .padding(14)
        .frame(width: 340)
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
