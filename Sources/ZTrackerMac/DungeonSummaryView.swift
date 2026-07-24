import SwiftUI
import TrackerCore

/// The dungeon-map "Summary" tab (T-019.9) — a 3×3 overview of all nine dungeons'
/// room maps at a glance, each clickable to jump to that dungeon. A bounded take
/// on the reference summary (`DungeonUI.fs:1552+`): the read-only mini maps +
/// found/complete states + click-to-select. The reference's hover-preview and
/// per-dungeon monster-priority list are follow-ups.
struct DungeonSummaryView: View {
    @Bindable var model: TrackerModel
    var options: TrackerOptions
    /// Select a dungeon (0…8) — switches the map area to that dungeon's tab.
    var onSelect: (Int) -> Void

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 10), count: 3)

    var body: some View {
        LazyVGrid(columns: columns, spacing: 10) {
            ForEach(0..<9, id: \.self) { i in
                DungeonSummaryPanel(
                    map: model.dungeonRoomMaps[i],
                    label: DungeonLabeling.slotLabel(i + 1, hideDungeonNumbers: model.hideDungeonNumbers),
                    prefix: options.levelPrefix,
                    isComplete: model.dungeonTracker.dungeon(i).isComplete,
                    onSelect: { onSelect(i) }
                )
            }
        }
        .frame(maxWidth: .infinity)
    }
}

/// One dungeon's summary card: label + completion, its mini map, and a
/// "not yet found" state for an untouched dungeon.
private struct DungeonSummaryPanel: View {
    @Bindable var map: DungeonRoomMap
    let label: String
    let prefix: String
    let isComplete: Bool
    let onSelect: () -> Void

    var body: some View {
        Button(action: onSelect) {
            VStack(spacing: 4) {
                HStack(spacing: 4) {
                    Text("\(prefix)\(label)")
                        .font(.system(size: 11, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                    if isComplete {
                        Image(systemName: "checkmark.seal.fill")
                            .font(.system(size: 10)).foregroundStyle(.green)
                    }
                }
                ZStack {
                    DungeonMiniMapView(map: map)
                    if !map.firstInteractionDone {
                        Text("not yet found")
                            .font(.system(size: 9)).foregroundStyle(.secondary)
                            .padding(.horizontal, 4).padding(.vertical, 1)
                            .background(RoundedRectangle(cornerRadius: 3).fill(.black.opacity(0.6)))
                    }
                }
            }
            .padding(6)
            .background(RoundedRectangle(cornerRadius: 6).fill(Color(white: 0.08)))
            .overlay(RoundedRectangle(cornerRadius: 6).strokeBorder(
                isComplete ? Color.green.opacity(0.4) : Color(white: 0.16), lineWidth: 1))
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Dungeon \(label)\(isComplete ? ", complete" : map.firstInteractionDone ? "" : ", not yet found")")
        .accessibilityAddTraits(.isButton)
        .accessibilityHint("Opens this dungeon's map")
    }
}

/// A small read-only render of a dungeon's 8×8 room map (room-type sprites +
/// completion). Off-map rooms are blank; doors are omitted at this scale, as in
/// the reference tiny map (`DungeonUI.fs:1621-1628`).
struct DungeonMiniMapView: View {
    var map: DungeonRoomMap
    /// Mini cell width; height keeps the sprite's 13:9 ratio.
    var cell: CGFloat = 16
    private var cellH: CGFloat { (cell * 9 / 13).rounded() }

    var body: some View {
        VStack(spacing: 0) {
            ForEach(0..<DungeonRoomMap.rows, id: \.self) { row in
                HStack(spacing: 0) {
                    ForEach(0..<DungeonRoomMap.cols, id: \.self) { col in
                        cellView(map.room(col: col, row: row))
                    }
                }
            }
        }
        .background(Color.black)
    }

    @ViewBuilder private func cellView(_ room: DungeonRoom) -> some View {
        ZStack {
            Color.black
            if room.roomType != .offTheMap,
               let image = Image(atlasIcon: DungeonRoomSpriteAtlas.sprite(room.roomType, completed: room.isCompleted)) {
                image.interpolation(.none).resizable()
            }
        }
        .frame(width: cell, height: cellH)
    }
}
