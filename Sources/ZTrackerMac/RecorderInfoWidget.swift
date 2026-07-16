import SwiftUI
import TrackerCore

/// The recorder-destination widget for the **Info** group, below the six overlay
/// toggles (T-081). Replaces the old full-width `RecorderDestinationBar` that sat
/// between the overworld and dungeon maps.
///
/// Layout: `◄ [recorder] ► N  coord`. The recorder icon is greyed until you have
/// the recorder. The number is the dungeon the whistle warps to:
///  - `0` when there's no destination — you don't have the recorder yet, OR you
///    have it but hold no triforce (there is **no default**: you don't know which
///    dungeon the recorder came out of until you've beaten one),
///  - otherwise the lowest obtained-triforce dungeon — unless you've stepped the
///    arrows, which pins it to your manual choice.
///
/// Destinations are driven purely by which triforces you hold, independent of
/// whether that dungeon is placed on the overworld map (see
/// `RecorderDestinations.infoEntries`); the coordinate simply shows `—` until you
/// mark it.
struct RecorderInfoWidget: View {
    @Bindable var model: TrackerModel
    var playerState: PlayerComputedStateSummary
    var mapState: MapStateSummary

    private var haveRecorder: Bool { playerState.haveRecorder }

    private var entries: [RecorderDestinations.WidgetEntry] {
        RecorderDestinations.infoEntries(
            dungeonTracker: model.dungeonTracker,
            hideDungeonNumbers: model.hideDungeonNumbers,
            dungeonLocations: mapState.dungeonLocations,
            toNewDungeons: model.recorderToNewDungeons,
            toUnbeatenDungeons: model.recorderToUnbeatenDungeons)
    }

    /// The currently pointed-at entry, honoring the manual-override flag.
    private var selected: RecorderDestinations.WidgetEntry? {
        RecorderDestinations.selectedEntry(
            entries: entries,
            manualIndex: model.recorderDestinationManual ? model.recorderDestinationIndex : nil)
    }

    /// The numeral shown next to the recorder: `0` when there's no destination
    /// (no recorder, or the recorder but no obtained triforce — no default), else
    /// the selected dungeon number.
    private var destinationNumber: Int {
        guard haveRecorder else { return 0 }
        return selected?.dungeonNumber ?? 0
    }

    /// Whether the arrows can do anything (need the recorder and ≥1 destination).
    private var steppable: Bool { haveRecorder && !entries.isEmpty }

    var body: some View {
        HStack(spacing: 6) {
            stepButton(systemName: "chevron.left", delta: -1)
            recorderIcon
            stepButton(systemName: "chevron.right", delta: +1)

            Text("\(destinationNumber)")
                .font(.system(size: 15, weight: .heavy, design: .rounded))
                .foregroundStyle(haveRecorder ? .orange : Color(white: 0.4))
                .frame(minWidth: 14)

            Text(coordLabel)
                .font(.system(size: 11, design: .monospaced))
                .foregroundStyle(.secondary)
        }
        .help(helpText)
    }

    private var coordLabel: String {
        guard haveRecorder, let c = selected?.coordinate else { return "—" }
        return OverworldCoords.label(column: c.x, row: c.y)
    }

    private var recorderIcon: some View {
        ZStack {
            if let img = Image(atlasIcon: ItemIconAtlas.cgImage(.recorder)) {
                img.interpolation(.none).resizable().frame(width: 22, height: 22)
                    .opacity(haveRecorder ? 1 : 0.28)
                    .saturation(haveRecorder ? 1 : 0)
            }
        }
        .frame(width: 26, height: 26)
    }

    private func stepButton(systemName: String, delta: Int) -> some View {
        Button {
            model.recorderDestinationManual = true
            model.recorderDestinationIndex += delta
        } label: {
            Image(systemName: systemName).font(.system(size: 12, weight: .bold))
        }
        .buttonStyle(.plain)
        .disabled(!steppable)
        .opacity(steppable ? 1 : 0.3)
        .help(delta < 0 ? "Previous whistle destination" : "Next whistle destination (as if you whistled again)")
    }

    private var helpText: String {
        if !haveRecorder { return "Recorder destination — appears once you have the recorder." }
        if entries.isEmpty { return "Recorder destination — unknown until you obtain a triforce." }
        return "Where the recorder warps you. Arrows step through your obtained-triforce dungeons; the coordinate shows once you mark the dungeon on the map."
    }
}
