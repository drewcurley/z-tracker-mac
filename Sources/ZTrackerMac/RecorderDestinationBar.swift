import SwiftUI
import TrackerCore

/// The recorder-destination stepper (T-035.7) — the **single place** to see
/// where the whistle would take you, sitting directly below the map. Two arrows
/// step your whistle count through the ordered available destinations; the
/// current one is named here and marked with a lone diamond on the map. A
/// settings button holds the two "which dungeons" checkboxes.
struct RecorderDestinationBar: View {
    @Bindable var model: TrackerModel
    /// The ordered available destinations (empty unless the player has the recorder).
    var destinations: [RecorderDestinations.Destination]
    /// The destination the stepper currently points at.
    var current: RecorderDestinations.Destination?
    var hideDungeonNumbers: Bool

    @State private var showingSettings = false

    /// 1-based position of the current destination within the list.
    private var position: Int {
        let n = destinations.count
        guard n > 0 else { return 0 }
        return ((model.recorderDestinationIndex % n) + n) % n + 1
    }

    var body: some View {
        HStack(spacing: 10) {
            Text("Recorder Destination")
                .font(.system(size: 12, weight: .semibold))

            if destinations.isEmpty {
                Text(model.playerComputedStateSummary.haveRecorder
                     ? "— no destinations (per your settings)"
                     : "— none (get the recorder first)")
                    .font(.system(size: 12)).foregroundStyle(.secondary)
            } else {
                Button { model.recorderDestinationIndex -= 1 } label: {
                    Image(systemName: "chevron.left.circle.fill").font(.system(size: 16))
                }
                .buttonStyle(.plain)
                .help("Previous whistle destination")

                currentDisplay

                Button { model.recorderDestinationIndex += 1 } label: {
                    Image(systemName: "chevron.right.circle.fill").font(.system(size: 16))
                }
                .buttonStyle(.plain)
                .help("Next whistle destination (as if you whistled again)")
            }

            Spacer()
            settingsButton
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(RoundedRectangle(cornerRadius: 6).fill(Color(white: 0.11)))
        .overlay(RoundedRectangle(cornerRadius: 6).strokeBorder(Color(white: 0.25), lineWidth: 1))
    }

    @ViewBuilder
    private var currentDisplay: some View {
        HStack(spacing: 6) {
            // The same cyan diamond used on the map marker.
            Rectangle().fill(Color.cyan)
                .frame(width: 10, height: 10)
                .rotationEffect(.degrees(45))
            if let c = current {
                Text("Dungeon \(DungeonLabeling.slotLabel(c.slot + 1, hideDungeonNumbers: hideDungeonNumbers))")
                    .font(.system(size: 12, weight: .bold))
                Text(OverworldCoords.label(column: c.coordinate.x, row: c.coordinate.y))
                    .font(.system(size: 11, design: .monospaced))
                    .foregroundStyle(.secondary)
            }
            Text("(\(position)/\(destinations.count))")
                .font(.system(size: 11)).foregroundStyle(.secondary)
        }
        .frame(minWidth: 150, alignment: .leading)
    }

    private var settingsButton: some View {
        Button { showingSettings = true } label: {
            Image(systemName: "slider.horizontal.3").font(.system(size: 12))
        }
        .buttonStyle(.plain)
        .help("Choose which dungeons the recorder warps to")
        .popover(isPresented: $showingSettings, arrowEdge: .bottom) {
            VStack(alignment: .leading, spacing: 10) {
                Text("Recorder destinations").font(.headline)
                Toggle("To new dungeons", isOn: $model.recorderToNewDungeons)
                    .help("On: warp to the dungeon locations you've marked on the map. Off: the fixed vanilla first-quest dungeon screens.")
                Toggle("To unbeaten dungeons", isOn: $model.recorderToUnbeatenDungeons)
                    .help("On: dungeons whose triforce you do NOT yet have. Off: dungeons you've already beaten.")
                Text("Needs the recorder; 'new' also needs the dungeon located on the map.")
                    .font(.caption2).foregroundStyle(.secondary)
                    .frame(width: 240, alignment: .leading)
            }
            .toggleStyle(.checkbox)
            .padding(12)
        }
    }
}
