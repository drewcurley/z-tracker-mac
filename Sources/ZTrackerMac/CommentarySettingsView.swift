import SwiftUI
import TrackerCore

/// The Commentary Mode configuration subscreen (T-215), opened from Settings in its own window
/// (like the hotkey / voice editors) since it's a less commonly used feature. Owns the mode
/// toggle + overlay style (global prefs) and the two runners' names/colors (per-session, on the
/// model's `CommentaryLayer`).
struct CommentarySettingsView: View {
    var options: TrackerOptions
    @Bindable var commentary: CommentaryLayer

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text("Commentary Mode")
                    .font(.title3.bold())
                Text("A commentator-only overlay marking which runner has discovered each spot. "
                     + "On the overworld, ⌥-click marks \(name(commentary.runner1Name, "Runner 1")), "
                     + "⌥-right-click marks \(name(commentary.runner2Name, "Runner 2")). Normal clicks "
                     + "still mark the seed as usual.")
                    .font(.callout).foregroundStyle(.secondary).fixedSize(horizontal: false, vertical: true)

                Toggle("Commentary mode on", isOn: Bindable(options).commentaryMode)
                    .font(.headline)

                Divider()

                VStack(alignment: .leading, spacing: 8) {
                    Text("Overlay style").font(.headline)
                    Picker("Overlay style", selection: Bindable(options).commentaryEncoding) {
                        Text("Corner pips").tag(CommentaryEncoding.pips)
                        Text("Edge border").tag(CommentaryEncoding.border)
                    }
                    .pickerStyle(.segmented).labelsHidden().frame(maxWidth: 320)
                }

                Divider()

                VStack(alignment: .leading, spacing: 12) {
                    Text("Runners").font(.headline)
                    runnerRow(color: $commentary.runner1ColorHex, name: $commentary.runner1Name,
                              placeholder: "Runner 1")
                    runnerRow(color: $commentary.runner2ColorHex, name: $commentary.runner2Name,
                              placeholder: "Runner 2")
                }

                Divider()

                Button("Clear all commentary marks", role: .destructive) { commentary.clearAll() }
                    .help("Remove every runner-knowledge mark. Keeps the runner names and colors.")
            }
            .padding(20)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .frame(minWidth: 380, minHeight: 340)
    }

    private func runnerRow(color: Binding<String>, name: Binding<String>, placeholder: String) -> some View {
        HStack(spacing: 10) {
            ColorPicker("", selection: color.commentaryColor, supportsOpacity: false).labelsHidden()
            TextField(placeholder, text: name).frame(width: 220)
        }
    }

    private func name(_ v: String, _ fallback: String) -> String {
        v.trimmingCharacters(in: .whitespaces).isEmpty ? fallback : v
    }
}
