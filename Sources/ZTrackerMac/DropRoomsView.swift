import SwiftUI
import ImageIO
import CoreGraphics
import TrackerCore

/// Loads the bundled `droproom-*.png` thumbnails (sliced from the community drop-room chart) as
/// CGImages, memoized (T-219).
@MainActor
enum DropRoomImage {
    private static var cache: [String: CGImage?] = [:]
    static func image(_ key: String) -> CGImage? {
        if let hit = cache[key] { return hit }
        let img: CGImage? = {
            guard let url = AppResources.url(forResource: key, withExtension: "png"),
                  let src = CGImageSourceCreateWithURL(url as CFURL, nil),
                  let cg = CGImageSourceCreateImageAtIndex(src, 0, nil) else { return nil }
            return cg
        }()
        cache[key] = img
        return img
    }
}

/// The Drop Rooms breakout window (T-219): given the dungeon selected on the dungeon-map tab, shows
/// the room layouts that will **never** contain a floor drop there — so a runner knows not to waste
/// time checking them. Updates live as the selected dungeon (or its identified number) changes.
struct DropRoomsView: View {
    var model: TrackerModel
    @Bindable var focus: TrackerFocusState

    private let columns = [GridItem(.adaptive(minimum: 118, maximum: 150), spacing: 12)]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                header
                if let n = currentDungeonNumber {
                    Text("These room layouts **never** hold a floor drop in \(levelLabel(n)) — no need to check them for items.")
                        .font(.callout).foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                    LazyVGrid(columns: columns, alignment: .leading, spacing: 12) {
                        ForEach(DropRooms.neverDrop(dungeon: n), id: \.imageKey) { room in
                            roomCell(room)
                        }
                    }
                } else {
                    emptyState
                }
            }
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private var header: some View {
        HStack(spacing: 8) {
            Image(systemName: "questionmark.square.dashed").font(.title3)
            Text("Drop Rooms").font(.title3.weight(.semibold))
            Spacer()
            if let n = currentDungeonNumber {
                Text(levelLabel(n))
                    .font(.system(size: 12, weight: .bold, design: .rounded))
                    .padding(.horizontal, 8).padding(.vertical, 3)
                    .background(Capsule().fill(Color.accentColor.opacity(0.25)))
            }
        }
    }

    @ViewBuilder private var emptyState: some View {
        let hdnUnknown = focus.selectedDungeonTab <= 8 && model.hideDungeonNumbers
        VStack(alignment: .leading, spacing: 6) {
            Text(hdnUnknown
                 ? "This dungeon's number isn't identified yet."
                 : "Select a dungeon on the Dungeon Map tab.")
                .font(.callout).foregroundStyle(.secondary)
            Text(hdnUnknown
                 ? "Set its number (hidden-dungeon-numbers is on) and its drop rooms will appear here."
                 : "Pick a dungeon (1–9) and this shows the rooms that never drop there.")
                .font(.caption).foregroundStyle(.tertiary)
        }
    }

    private func roomCell(_ room: DropRoom) -> some View {
        VStack(spacing: 4) {
            Group {
                if let cg = DropRoomImage.image(room.imageKey) {
                    Image(decorative: cg, scale: 1, orientation: .up)
                        .resizable().aspectRatio(137.0 / 79.0, contentMode: .fit)
                } else {
                    RoundedRectangle(cornerRadius: 4).fill(Theme.boxFill)
                        .aspectRatio(137.0 / 79.0, contentMode: .fit)
                }
            }
            .overlay(RoundedRectangle(cornerRadius: 3).strokeBorder(.black.opacity(0.5), lineWidth: 1))
            Text(room.name)
                .font(.system(size: 11, weight: .medium))
                .lineLimit(1).minimumScaleFactor(0.7)
        }
    }

    private func levelLabel(_ n: Int) -> String { "Level \(n)" }

    /// The dungeon number (1…9) for the selected tab, or nil when there's no concrete dungeon:
    /// the Summary tab, or an HDN dungeon whose number isn't identified yet. Mirrors the
    /// `expectedOldMen` logic in `DungeonMapView` (T-219).
    private var currentDungeonNumber: Int? {
        let tab = focus.selectedDungeonTab
        guard (0...8).contains(tab) else { return nil }   // 9 = Summary
        if model.hideDungeonNumbers {
            guard let n = model.dungeonTracker.dungeon(tab).labelChar.wholeNumberValue,
                  (1...9).contains(n) else { return nil }
            return n
        }
        return tab + 1
    }
}
