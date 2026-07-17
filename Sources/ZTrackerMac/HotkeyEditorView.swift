import SwiftUI
import AppKit
import TrackerCore

/// The in-app hotkey editor (T-131, docs/domain.md § 4.11) — every bindable selector
/// grouped by context. Click a binding, press the key(s) you want; if that key is
/// already used in a conflicting context you're warned and can use it anyway. Import
/// / export the Windows `HotKeys.txt`. (Editing only — keys don't fire yet; that's a
/// later phase.)
struct HotkeyEditorView: View {
    @Bindable var config: HotkeyConfig

    /// The selector id currently listening for a keypress (nil = not capturing).
    @State private var capturing: String?
    @State private var keyMonitor: Any?
    @State private var pendingConflict: PendingConflict?
    @State private var importReport: ImportReport?
    @State private var filter: String = ""

    struct PendingConflict: Identifiable {
        let id = UUID(); let selectorID: String; let chord: HotkeyChord; let conflicts: [HotkeySelector]
    }
    struct ImportReport: Identifiable { let id = UUID(); let warnings: [String] }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            toolbar
            Divider()
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 14, pinnedViews: [.sectionHeaders]) {
                    ForEach(HotkeyContext.editorOrder, id: \.self) { context in
                        let rows = visibleSelectors(context)
                        if !rows.isEmpty {
                            Section {
                                ForEach(rows) { selector in row(selector) }
                            } header: {
                                Text(context.displayName)
                                    .font(.caption.bold()).foregroundStyle(.secondary)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .padding(.vertical, 3)
                                    .background(.bar)
                            }
                        }
                    }
                }
                .padding(.horizontal, 4)
            }
        }
        .padding(12)
        .frame(minWidth: 420, minHeight: 400)
        .onDisappear { stopCapture() }
        .alert("Reassign key?", isPresented: Binding(
            get: { pendingConflict != nil }, set: { if !$0 { pendingConflict = nil } })) {
            Button("Reassign") {
                if let p = pendingConflict { config.reassign(p.chord, to: p.selectorID) }
                pendingConflict = nil
            }
            Button("Cancel", role: .cancel) { pendingConflict = nil }
        } message: {
            if let p = pendingConflict {
                let names = p.conflicts.map(\.displayName).joined(separator: ", ")
                let plural = p.conflicts.count == 1 ? "" : "s"
                Text("\(p.chord.displayName) is already bound to \(names). A key can only do one "
                     + "thing per context — reassigning it here will remove it from that binding\(plural).")
            }
        }
        .alert("Import finished with warnings", isPresented: Binding(
            get: { importReport != nil }, set: { if !$0 { importReport = nil } })) {
            Button("OK") { importReport = nil }
        } message: {
            Text((importReport?.warnings.prefix(12).joined(separator: "\n") ?? "")
                 + ((importReport?.warnings.count ?? 0) > 12 ? "\n…" : ""))
        }
    }

    // MARK: Toolbar

    private var toolbar: some View {
        HStack(spacing: 8) {
            Text("Hotkeys").font(.headline)
            Spacer()
            TextField("Filter", text: $filter)
                .textFieldStyle(.roundedBorder).frame(width: 130)
            Button("Import…") { importFile() }
            Button("Export…") { exportFile() }
            Button("Clear all") { config.clearAll() }
                .disabled(config.bindings.isEmpty)
        }
        .controlSize(.small)
    }

    // MARK: One selector row

    private func row(_ selector: HotkeySelector) -> some View {
        HStack(spacing: 8) {
            Text(selector.displayName).font(.system(size: 12))
            Spacer(minLength: 8)
            if config.chord(for: selector.id) != nil {
                Button { config.setChord(nil, for: selector.id) } label: {
                    Image(systemName: "xmark.circle.fill").foregroundStyle(.secondary)
                }
                .buttonStyle(.plain).help("Clear")
            }
            Button { toggleCapture(selector.id) } label: {
                Text(capturing == selector.id ? "Press a key…"
                     : (config.chord(for: selector.id)?.displayName ?? "—"))
                    .font(.system(size: 11, weight: .medium, design: .monospaced))
                    .frame(minWidth: 74)
                    .padding(.horizontal, 8).padding(.vertical, 3)
                    .background(RoundedRectangle(cornerRadius: 5)
                        .fill(capturing == selector.id ? Color.accentColor.opacity(0.3) : Color(white: 0.16)))
                    .overlay(RoundedRectangle(cornerRadius: 5)
                        .strokeBorder(capturing == selector.id ? Color.accentColor : .clear))
            }
            .buttonStyle(.plain)
        }
        .padding(.vertical, 1)
    }

    private func visibleSelectors(_ context: HotkeyContext) -> [HotkeySelector] {
        let sels = HotkeyCatalog.selectors(in: context)
        guard !filter.isEmpty else { return sels }
        let f = filter.lowercased()
        return sels.filter { $0.displayName.lowercased().contains(f) || $0.id.lowercased().contains(f) }
    }

    // MARK: Key capture

    private func toggleCapture(_ selectorID: String) {
        if capturing == selectorID { stopCapture() } else { startCapture(selectorID) }
    }

    private func startCapture(_ selectorID: String) {
        stopCapture()
        capturing = selectorID
        keyMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { event in
            handleCapture(event, for: selectorID)
            return nil   // consume the keystroke while capturing
        }
    }

    private func stopCapture() {
        if let m = keyMonitor { NSEvent.removeMonitor(m); keyMonitor = nil }
        capturing = nil
    }

    private func handleCapture(_ event: NSEvent, for selectorID: String) {
        if event.keyCode == 53 { stopCapture(); return }   // Escape cancels
        guard let chord = Self.chord(from: event) else { stopCapture(); return }
        let conflicts = config.conflicts(for: selectorID, chord: chord)
        stopCapture()
        if conflicts.isEmpty {
            config.setChord(chord, for: selectorID)
        } else {
            pendingConflict = PendingConflict(selectorID: selectorID, chord: chord, conflicts: conflicts)
        }
    }

    /// Translate a key event to a chord: one of Shift/Control/Option (Command is not a
    /// binding modifier here — it drives the app menus); letters/digits store the char,
    /// anything else stores the raw Mac key code as `\nnn`.
    static func chord(from event: NSEvent) -> HotkeyChord? {
        let mods = event.modifierFlags
        if mods.contains(.command) { return nil }
        var modifier = HotkeyChord.Modifier.none
        if mods.contains(.shift) { modifier = .shift }
        else if mods.contains(.control) { modifier = .control }
        else if mods.contains(.option) { modifier = .option }
        let chars = event.charactersIgnoringModifiers?.lowercased() ?? ""
        if chars.count == 1, let ch = chars.first, ch.isLetter || ch.isNumber {
            return HotkeyChord(modifier: modifier, key: String(ch))
        }
        return HotkeyChord(modifier: modifier, key: "\\\(event.keyCode)")
    }

    // MARK: Import / Export

    private func importFile() {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [.plainText, .text]
        panel.allowsOtherFileTypes = true
        panel.message = "Import a Z-Tracker HotKeys.txt"
        guard panel.runModal() == .OK, let url = panel.url,
              let text = try? String(contentsOf: url, encoding: .utf8) else { return }
        let result = HotkeyConfig.parse(text)
        config.apply(result)
        if !result.warnings.isEmpty { importReport = ImportReport(warnings: result.warnings) }
    }

    private func exportFile() {
        let panel = NSSavePanel()
        panel.allowedContentTypes = [.plainText]
        panel.nameFieldStringValue = "HotKeys.txt"
        panel.message = "Export your hotkey bindings"
        guard panel.runModal() == .OK, let url = panel.url else { return }
        try? config.exportText().write(to: url, atomically: true, encoding: .utf8)
    }
}
