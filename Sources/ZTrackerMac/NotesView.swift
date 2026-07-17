import SwiftUI
import TrackerCore

/// The dungeon-band Notes box (T-019.1) — a port of the reference's single
/// global, multiline notes field (`WPFUI.fs:1219-1229`). Free-text scratch space
/// for a run; it survives a groundhog reset (it's player knowledge, like the
/// location hints). Lime-on-dark text nods at the reference's styling without
/// copying its exact geometry.
///
/// First slice of the dungeon band (frame-first order): the room-map grid and
/// blockers UI land in later slices above/beside this.
struct NotesView: View {
    @Bindable var model: TrackerModel
    @FocusState private var focused: Bool

    var body: some View {
        ZStack(alignment: .topLeading) {
            TextEditor(text: $model.notes)
                .font(.system(size: 13, design: .monospaced))
                .foregroundStyle(Color.green)
                .scrollContentBackground(.hidden)
                .padding(6)
                .focused($focused)
            // TextEditor has no native placeholder — hide ours as soon as the
            // field is focused (clicked into), not only once typing starts (T-103).
            if model.notes.isEmpty && !focused {
                Text("Notes…")
                    .font(.system(size: 13, design: .monospaced))
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 11)
                    .padding(.vertical, 14)
                    .allowsHitTesting(false)
            }
        }
        .background(RoundedRectangle(cornerRadius: 6).fill(.black.opacity(0.4)))
        .overlay(RoundedRectangle(cornerRadius: 6).strokeBorder(Color(white: 0.28), lineWidth: 1))
        .frame(minHeight: 110)
    }
}
