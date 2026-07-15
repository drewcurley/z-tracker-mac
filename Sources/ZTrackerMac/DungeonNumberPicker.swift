import SwiftUI
import TrackerCore

extension Color {
    /// A SwiftUI `Color` from a `0xRRGGBB` int (the reference's dungeon-color
    /// encoding — see `DungeonColorPalette`).
    init(rgb: Int) {
        self.init(
            red: Double((rgb & 0xFF0000) >> 16) / 255.0,
            green: Double((rgb & 0x00FF00) >> 8) / 255.0,
            blue: Double(rgb & 0x0000FF) / 255.0
        )
    }
}

/// The Hidden-Dungeon-Numbers slot label (T-050 / T-016.3): shows the dungeon's
/// player-assigned real number (`labelChar`, "?" until identified) on its
/// player-assigned color (`color`), and opens the color+number chooser. Placed
/// above the A–H dungeon slot in HDN, where the location hint sits in default
/// mode. Mirrors the reference's triforce-row color swatch (`UI.fs:235-241`) +
/// `HiddenDungeonCustomizerPopup` (`Z1R_Avalonia/Dungeon.fs`).
struct DungeonNumberLabel: View {
    @Bindable var dungeon: Dungeon
    /// The slot letter (A–H), for the popover title.
    var slotLabel: String
    @State private var showPicker = false

    private var isUnassigned: Bool { dungeon.labelChar == "?" }
    private var hasColor: Bool { dungeon.color != DungeonColorPalette.unset }

    /// The swatch background: the assigned color, or a neutral dark chip when
    /// still unset (so it stays visible/tappable on the dark card).
    private var swatch: Color {
        hasColor ? Color(rgb: dungeon.color) : Color(white: 0.16)
    }

    /// The number glyph color: black or white for contrast on the assigned
    /// color (reference `isBlackGoodContrast`); a muted "?" when unassigned.
    private var glyph: Color {
        if isUnassigned { return Color(white: 0.55) }
        if !hasColor { return .white }
        return DungeonColorPalette.isBlackGoodContrast(dungeon.color) ? .black : .white
    }

    var body: some View {
        Text(isUnassigned ? "?" : String(dungeon.labelChar))
            .font(.system(size: 10, weight: .heavy, design: .rounded))
            .foregroundStyle(glyph)
            .frame(minWidth: 18)
            .padding(.horizontal, 3).padding(.vertical, 1)
            .background(RoundedRectangle(cornerRadius: 3).fill(swatch))
            .overlay(RoundedRectangle(cornerRadius: 3)
                .strokeBorder(Color(white: 0.35), lineWidth: 1))
            .contentShape(Rectangle())
            .onTapGesture { showPicker = true }
            .help("Dungeon \(slotLabel): assigned number \(isUnassigned ? "unknown" : String(dungeon.labelChar)) — tap to set color & number")
            .popover(isPresented: $showPicker, arrowEdge: .bottom) {
                DungeonNumberPicker(dungeon: dungeon, slotLabel: slotLabel) { showPicker = false }
            }
            // Custom-gesture control → expose to VoiceOver (T-067).
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("Dungeon \(slotLabel) number")
            .accessibilityValue(isUnassigned ? "Unknown" : String(dungeon.labelChar))
            .accessibilityHint("Choose the color and number")
            .accessibilityAddTraits(.isButton)
            .accessibilityAction { showPicker = true }
    }
}

/// The number-chooser popover: pick "?" or 1–8 for this dungeon slot, with the
/// triforce reference diagrams so you can see where each number sits (and infer
/// two- vs three-item dungeons). The mark drives triforce-piece placement and
/// two-boxer completion (already in the model).
struct DungeonNumberPicker: View {
    @Bindable var dungeon: Dungeon
    var slotLabel: String
    var dismiss: () -> Void

    private let choices: [Character] = ["?", "1", "2", "3", "4", "5", "6", "7", "8"]
    private let columns = Array(repeating: GridItem(.fixed(40), spacing: 6), count: 3)

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Dungeon \(slotLabel)").font(.headline)

            // Color chooser (T-016.3): the reference's 3-row × 14-column shade
            // grid. Click a swatch to assign; the change is live so you can set
            // color and number in either order before dismissing.
            Text("Color").font(.caption).foregroundStyle(.secondary)
            colorGrid

            Divider()

            Text("Assign its real dungeon number")
                .font(.caption).foregroundStyle(.secondary)

            LazyVGrid(columns: columns, spacing: 6) {
                ForEach(choices, id: \.self) { ch in
                    let selected = dungeon.labelChar == ch
                    Button {
                        dungeon.labelChar = ch
                        dismiss()
                    } label: {
                        Text(String(ch))
                            .font(.system(size: 20, weight: .bold, design: .rounded))
                            .foregroundStyle(ch == "?" ? Color(white: 0.7) : .white)
                            .frame(width: 40, height: 34)
                            .background(RoundedRectangle(cornerRadius: 5)
                                .fill(selected ? Color.accentColor.opacity(0.55) : Color(white: 0.16)))
                            .overlay(RoundedRectangle(cornerRadius: 5)
                                .strokeBorder(selected ? Color.green : Color.clear, lineWidth: 2))
                    }
                    .buttonStyle(.plain)
                }
            }

            Text("Don't assign a number unless you're certain.")
                .font(.caption2).foregroundStyle(.orange)

            Divider()

            // Triforce reference (T-050) — which number sits where, per quest.
            // Stacked vertically for room; the selected number's triangle
            // lights up in both so you can see where the dungeon sits.
            Text("Triforce reference")
                .font(.caption).bold().foregroundStyle(.secondary)
            Text("In Mixed Quest, 7 and 8 may be swapped.")
                .font(.caption2).foregroundStyle(.secondary)
            diagram(title: "First Quest / Shapes dungeons", ordering: TriforceReference.firstQuest)
            diagram(title: "Second Quest dungeons", ordering: TriforceReference.secondQuest)
        }
        .padding(12)
        .frame(width: 300)
    }

    /// The 3-row × 14-column swatch grid. Selecting a swatch sets `color` live
    /// (no dismiss); the black column is the reference's "unset" default.
    private var colorGrid: some View {
        VStack(spacing: 4) {
            ForEach(DungeonColorPalette.rows.indices, id: \.self) { r in
                HStack(spacing: 3) {
                    ForEach(DungeonColorPalette.rows[r].indices, id: \.self) { c in
                        let rgb = DungeonColorPalette.rows[r][c]
                        let selected = dungeon.color == rgb && rgb != DungeonColorPalette.unset
                        Button { dungeon.color = rgb } label: {
                            RoundedRectangle(cornerRadius: 3)
                                .fill(Color(rgb: rgb))
                                .frame(width: 16, height: 16)
                                .overlay(RoundedRectangle(cornerRadius: 3)
                                    .strokeBorder(selected ? Color.white : Color(white: 0.3),
                                                  lineWidth: selected ? 2 : 0.5))
                        }
                        .buttonStyle(.plain)
                        .help(rgb == DungeonColorPalette.unset ? "No color" : String(format: "#%06X", rgb))
                        .accessibilityLabel(rgb == DungeonColorPalette.unset ? "No color" : String(format: "Color %06X", rgb))
                        .accessibilityAddTraits(selected ? [.isButton, .isSelected] : .isButton)
                    }
                }
            }
        }
    }

    private func diagram(title: String, ordering: String) -> some View {
        VStack(spacing: 4) {
            Text(title).font(.caption2).foregroundStyle(.orange)
            TriforceReferenceDiagram(ordering: ordering,
                                     highlight: dungeon.labelChar == "?" ? nil : dungeon.labelChar)
        }
        .frame(maxWidth: .infinity)
    }
}

/// A triforce diagram drawn from the reference's 8 sub-triangles (T-050): each
/// numbered piece is its own triangle; the selected number's triangle fills
/// orange so you can see where the dungeon sits (and, via the number, whether
/// it's a two- or three-item dungeon).
struct TriforceReferenceDiagram: View {
    /// 8 chars; position `i` shows `ordering[i]` (see `TriforceReference`).
    let ordering: String
    var highlight: Character? = nil

    /// TRIFORCE-size unit in points.
    private static let unit: CGFloat = 40
    private static let edge = Color(red: 0.28, green: 0.24, blue: 0.55) // DarkSlateBlue-ish

    private func point(_ idx: Int, _ n: CGFloat) -> CGPoint {
        CGPoint(x: TriforceReference.gridPoints[idx].x * n, y: TriforceReference.gridPoints[idx].y * n)
    }

    var body: some View {
        let n = Self.unit
        let chars = Array(ordering)
        ZStack(alignment: .topLeading) {
            ForEach(0..<8, id: \.self) { i in
                let isHi = chars[i] == highlight
                Path { p in
                    let v = TriforceReference.triangles[i]
                    p.move(to: point(v[0], n))
                    p.addLine(to: point(v[1], n))
                    p.addLine(to: point(v[2], n))
                    p.closeSubpath()
                }
                .fill(isHi ? Color.orange : Color.black)
                .overlay(
                    Path { p in
                        let v = TriforceReference.triangles[i]
                        p.move(to: point(v[0], n))
                        p.addLine(to: point(v[1], n))
                        p.addLine(to: point(v[2], n))
                        p.closeSubpath()
                    }
                    .stroke(Self.edge, lineWidth: 1.5)
                )
            }
            ForEach(0..<8, id: \.self) { i in
                let c = TriforceReference.centroid(i)
                Text(String(chars[i]))
                    .font(.system(size: n * 0.4, weight: .bold, design: .rounded))
                    .foregroundStyle(chars[i] == highlight ? .black : .white)
                    .position(x: c.x * n, y: c.y * n)
            }
        }
        .frame(width: 4 * n, height: 2 * n)
    }
}
