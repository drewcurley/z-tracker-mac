import SwiftUI
import TrackerCore

/// A small clickable location-hint label (T-039) — shows the target's current
/// hint as two chars (yellow when set, gray when Unknown); clicking opens the
/// zone picker. Placed above each dungeon and the white/magical sword boxes.
struct HintLabel: View {
    @Binding var hint: HintZone
    var title: String
    @State private var showPicker = false

    var body: some View {
        Text(hint.twoChars)
            .font(.system(size: 9, weight: .bold, design: .monospaced))
            .foregroundStyle(hint == .unknown ? Color(white: 0.5) : .yellow)
            .frame(minWidth: 18)
            .padding(.horizontal, 3).padding(.vertical, 1)
            .background(RoundedRectangle(cornerRadius: 3).fill(Color(white: 0.16)))
            .contentShape(Rectangle())
            .onTapGesture { showPicker = true }
            .help("Location hint for \(title): \(hint.displayName)")
            .popover(isPresented: $showPicker, arrowEdge: .bottom) {
                HintZonePicker(hint: $hint, title: title) { showPicker = false }
            }
    }
}

/// The hint-zone picker popover: the target's name + its current hint, and a
/// grid of the 11 zones. Mirrors the reference's hint popup
/// (`OverworldItemGridUI.fs` fast-hint selector).
struct HintZonePicker: View {
    @Binding var hint: HintZone
    var title: String
    var dismiss: () -> Void

    private let columns = Array(repeating: GridItem(.fixed(36), spacing: 4), count: 4)

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title).font(.caption).bold()
            Text(hint.displayName).font(.caption).foregroundStyle(.orange)
            Divider()
            LazyVGrid(columns: columns, spacing: 4) {
                ForEach(HintZone.allCases, id: \.self) { zone in
                    Button {
                        hint = zone
                        dismiss()
                    } label: {
                        Text(zone.twoChars)
                            .font(.system(size: 11, weight: .bold, design: .monospaced))
                            .foregroundStyle(zone == .unknown ? Color(white: 0.6) : .yellow)
                            .frame(width: 36, height: 22)
                            .background(RoundedRectangle(cornerRadius: 4)
                                .fill(zone == hint ? Color.accentColor.opacity(0.5) : Color(white: 0.18)))
                    }
                    .buttonStyle(.plain)
                    .help(zone.displayName)
                }
            }
        }
        .padding(10)
        .frame(width: 190)
    }
}
