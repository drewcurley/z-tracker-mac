import SwiftUI
import TrackerCore

/// A small clickable location-hint label (T-039) — shows the target's current
/// hint as two chars (yellow when set, gray when Unknown); clicking opens the
/// zone picker. Placed above each dungeon and the white/magical sword boxes.
struct HintLabel: View {
    @Binding var hint: HintZone
    var title: String
    /// Hover tracking for the `HintZone_*` hotkey context (T-168). Optional so the
    /// preview and any non-tracker use site can omit it.
    var focus: TrackerFocusState? = nil
    /// This box's `HintTarget` index (dungeon 0…8, white-sword 9, magical-sword 10).
    var hintTarget: Int? = nil
    @State private var showPicker = false
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        // In Light mode the gold text shift is subtle, so a set hint also gets a gold
        // outline to make "value changed" obvious (T-188, user request). Dark mode keeps
        // just the gold text (already high-contrast on the dark chip).
        let showGoldBorder = hint != .unknown && colorScheme == .light
        return Text(hint.twoChars)
            .font(.system(size: 9, weight: .bold, design: .monospaced))
            .foregroundStyle(hint == .unknown ? Color.secondary : Theme.hint)
            .frame(minWidth: 18)
            .padding(.horizontal, 3).padding(.vertical, 1)
            .background(RoundedRectangle(cornerRadius: 3).fill(Theme.panelFill))
            .overlay(RoundedRectangle(cornerRadius: 3)
                .strokeBorder(Theme.hint, lineWidth: showGoldBorder ? 1 : 0))
            .contentShape(Rectangle())
            .onHover { hovering in
                guard let focus, let hintTarget else { return }
                hovering ? focus.beginHoverHint(hintTarget) : focus.endHoverHint(hintTarget)
            }
            .onTapGesture { presentPopoverWithoutAnimation { showPicker = true } }
            .help("Location hint for \(title): \(hint.displayName)")
            .popover(isPresented: $showPicker, arrowEdge: .bottom) {
                HintZonePicker(hint: $hint, title: title) { showPicker = false }
            }
            // A custom-gesture control is invisible to VoiceOver by default
            // (T-067) — expose it as a button that reads its target + current
            // hint and opens the zone picker.
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("\(title) location hint")
            .accessibilityValue(hint.displayName)
            .accessibilityHint("Choose the hinted region")
            .accessibilityAddTraits(.isButton)
            .accessibilityAction { presentPopoverWithoutAnimation { showPicker = true } }
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
                            .foregroundStyle(zone == .unknown ? Color.secondary : Theme.hint)
                            .frame(width: 36, height: 22)
                            .background(RoundedRectangle(cornerRadius: 4)
                                .fill(zone == hint ? Color.accentColor.opacity(0.5) : Theme.panelFill))
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
