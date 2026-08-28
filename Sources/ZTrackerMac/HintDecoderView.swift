import SwiftUI
import TrackerCore

/// The Hint Decoder (T-039.1), ported from `MakeHintDecoderUI`
/// (`Z1R_WPF/UIComponents.fs:629-796`) — one place to translate the in-game
/// hint phrases and record the hinted region for each target.
///
/// Each of the 11 rows shows the exact in-game **phrase** ("Aquamentus
/// Awaits", "Meet (npc) at"), what it **decodes to** ("Level 1", "Magical
/// Sword"), and a **region picker** that writes the same `levelHints` the
/// dungeon cards / sword boxes read — so everything stays in sync. Placing a
/// dungeon on the overworld auto-fills its region here too (T-039.1).
///
/// The "Other hints" disclosure lists the remaining hint types (feat of
/// strength, sail, melody, arrow, step-over-water). These are informational
/// only — the player keeps them in mind; the tracker deliberately does not
/// darken the map for them, since those spots can still hold useful (just
/// non-critical) items.
struct HintDecoderView: View {
    @Bindable var model: TrackerModel

    @State private var showOtherHints = false

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Hint Decoder").font(.headline)
            Text("Translate an in-game hint, then record the region it points to.")
                .font(.caption).foregroundStyle(.secondary)
            Divider()

            Grid(alignment: .leading, horizontalSpacing: 12, verticalSpacing: 5) {
                ForEach(Array(HintPhrases.levelHints.enumerated()), id: \.offset) { _, entry in
                    GridRow {
                        Text(entry.phrase)
                            .font(.system(size: 13, design: .serif))
                            .italic()
                            .foregroundStyle(Color.orange)
                            .gridColumnAlignment(.leading)
                        Text(entry.meaning)
                            .font(.system(size: 13, weight: .medium))
                            .gridColumnAlignment(.leading)
                        HintLabel(
                            hint: $model.levelHints[entry.target],
                            title: entry.meaning)
                    }
                }
            }

            Divider()
            DisclosureGroup(isExpanded: $showOtherHints) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("These don't pin a single region — just keep them in mind. "
                         + "Their spots may still hold useful (non-critical) items.")
                        .font(.caption).foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                    Grid(alignment: .leading, horizontalSpacing: 12, verticalSpacing: 5) {
                        ForEach(Array(HintPhrases.otherHints.enumerated()), id: \.offset) { _, entry in
                            GridRow {
                                Text(entry.phrase)
                                    .font(.system(size: 12, design: .serif))
                                    .italic()
                                    .foregroundStyle(Color.orange)
                                    .gridColumnAlignment(.leading)
                                Text(entry.meaning)
                                    .font(.system(size: 12))
                                    .foregroundStyle(.secondary)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                        }
                    }
                    .padding(.top, 2)
                }
            } label: {
                // Clicking the title (not just the chevron) toggles the section (T-219 polish).
                Text("Other hints").font(.system(size: 13, weight: .semibold))
                    .contentShape(Rectangle())
                    .onTapGesture { withAnimation { showOtherHints.toggle() } }
            }
        }
        .padding(14)
        .frame(width: showOtherHints ? 560 : 340)
    }
}
