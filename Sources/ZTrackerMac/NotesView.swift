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
    /// Notes is the sixth cursor region (T-168): cycling onto it focuses this field,
    /// and Escape blurs it. Optional so previews can omit it.
    var focus: TrackerFocusState? = nil
    @FocusState private var focused: Bool

    var body: some View {
        let _ = perfTrace()
        ZStack(alignment: .topLeading) {
            TextEditor(text: $model.notes)
                .font(.system(size: 13, design: .monospaced))
                .foregroundStyle(Theme.notesText)
                .scrollContentBackground(.hidden)
                .padding(6)
                .focused($focused)
                // Escape is the fixed exit: while this field is first responder the
                // hotkey dispatcher stands down, so a *bound* cycle key can't reach us.
                .onKeyPress(.escape) {
                    guard focused else { return .ignored }
                    focus?.setNotesFocus(false)
                    focused = false
                    return .handled
                }
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
        // The keyboard cursor parked here (T-168) — same cyan as the grid regions'
        // ring, so it's obvious the next letter you type starts a note.
        .overlay {
            if focus?.notesParked == true {
                RoundedRectangle(cornerRadius: 6)
                    .strokeBorder(Color.cyan, lineWidth: 2)
                    .shadow(color: .cyan, radius: 2)
                    .allowsHitTesting(false)
            }
        }
        .frame(minHeight: 110)
        // Cycling onto the Notes region raises focus here…
        .onChange(of: focus?.notesFocused ?? false) { _, wanted in
            if focused != wanted { focused = wanted }
        }
        // …and clicking straight into the field claims the cursor, so cycling out
        // afterwards continues around the ring from Notes rather than from wherever
        // the cursor happened to be.
        .onChange(of: focused) { _, isFocused in
            guard let focus else { return }
            if isFocused { focus.setNotesFocus(true) }
            else if focus.notesFocused { focus.setNotesFocus(false) }
        }
    }
}
