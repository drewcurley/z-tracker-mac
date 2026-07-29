import AppKit
import SwiftUI
import TrackerCore

/// Import panel for a Z1R randomizer spoiler log (T-181). Per-section checkboxes (remembered
/// across opens via `@AppStorage`); picking a `…_log.txt` parses it and applies the checked
/// sections to the board. Overwrites the affected state — spoiling is the point.
struct SpoilerImportView: View {
    var model: TrackerModel
    @Environment(\.dismiss) private var dismiss

    // Remembered selections.
    @AppStorage("spoilerImport.overworld") private var overworld = true
    @AppStorage("spoilerImport.items") private var items = true
    @AppStorage("spoilerImport.roomMaps") private var roomMaps = true
    @AppStorage("spoilerImport.l9") private var l9 = true
    /// The seed's Heart Shuffle setting — the log doesn't state it, and it changes how dungeon
    /// items are placed (off: fixed heart in each dungeon's first box; on: empty slots become hearts).
    @AppStorage("spoilerImport.heartShuffleOn") private var heartShuffleOn = false

    @State private var resultText: String?

    private var sections: SpoilerLog.Sections {
        var s: SpoilerLog.Sections = []
        if overworld { s.insert(.overworldMarks) }
        if items { s.insert(.dungeonItems) }
        if roomMaps { s.insert(.roomMaps) }
        if l9 { s.insert(.l9AndStart) }
        return s
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Import Spoiler Log").font(.headline)
            Text("Auto-marks the board from a Z1R randomizer spoiler log (…_log.txt). "
                 + "The checked sections are overwritten.")
                .font(.caption).foregroundStyle(.secondary).fixedSize(horizontal: false, vertical: true)

            VStack(alignment: .leading, spacing: 6) {
                Toggle("Overworld markers", isOn: $overworld)
                Toggle("Dungeon items (incl. white-sword / coast / armos)", isOn: $items)
                Toggle("Dungeon room maps", isOn: $roomMaps)
                Toggle("Level 9 requirements + start spot", isOn: $l9)
            }
            .toggleStyle(.checkbox)

            Divider()
            Toggle("This seed has Heart Shuffle ON", isOn: $heartShuffleOn)
                .toggleStyle(.checkbox)
                .help("The log doesn't record Heart Shuffle. Off: each dungeon keeps a fixed heart in its first box. On: all 9 hearts are shuffled, so empty slots after placing items become hearts.")
                .disabled(!items)

            if let resultText {
                Text(resultText).font(.caption).foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            HStack {
                Spacer()
                Button("Close") { dismiss() }
                Button("Choose Log & Import…") { chooseAndImport() }
                    .keyboardShortcut(.defaultAction)
                    .disabled(sections.isEmpty)
            }
        }
        .padding(20)
        .frame(width: 380)
    }

    private func chooseAndImport() {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [.plainText, .text]
        panel.directoryURL = GameSave.defaultDirectory
        panel.message = "Choose a Z1R spoiler log (…_log.txt)"
        panel.prompt = "Import"
        guard panel.runModal() == .OK, let url = panel.url,
              let text = try? String(contentsOf: url, encoding: .utf8) else { return }

        let result = SpoilerLog.parse(text).apply(to: model, sections: sections, heartShuffle: heartShuffleOn)

        var parts: [String] = []
        if result.overworldMarksSet > 0 { parts.append("\(result.overworldMarksSet) overworld marks") }
        if result.armosInferred { parts.append("armos spot") }
        if result.dungeonItemsSet > 0 { parts.append("\(result.dungeonItemsSet) dungeon items") }
        if result.heartsPlaced > 0 { parts.append("\(result.heartsPlaced) hearts") }
        if result.swordlessInferred { parts.append("swordless inferred") }
        if result.unmappedItemCount > 0 { parts.append("\(result.unmappedItemCount) item(s) skipped") }
        if result.unmappedCaveCount > 0 { parts.append("\(result.unmappedCaveCount) unmapped caves") }
        if result.roomMapsApplied > 0 {
            var rm = "\(result.roomMapsApplied) room maps"
            if result.transportsRelocated > 0 { rm += " (\(result.transportsRelocated) transports moved to fit)" }
            parts.append(rm)
        }
        if result.startSpotSet { parts.append("start spot") }
        if result.l9NoteAdded { parts.append("L9 → Notes") }
        if !result.deferredSections.isEmpty {
            parts.append("not yet implemented: " + result.deferredSections.joined(separator: ", "))
        }
        resultText = "Imported " + (parts.isEmpty ? "nothing." : parts.joined(separator: " · ") + ".")
    }
}
