import SwiftUI
import TrackerCore

/// The reminder log (T-102, now a window — T-122): a most-recent-first list of the
/// reminders that have fired, each with its run-time and a row of icons describing
/// what it's about (e.g. ladder → coast item, or magical sword → Level 3), plus a
/// Clear action.
struct ReminderLogView: View {
    @Bindable var log: ReminderLog

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Reminder log").font(.headline)
                Spacer()
                Button("Clear") { log.clear() }
                    .font(.caption).controlSize(.small)
                    .disabled(log.entries.isEmpty)
            }
            if log.entries.isEmpty {
                Text("No reminders yet.")
                    .font(.callout).foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            } else {
                ScrollView {
                    VStack(alignment: .leading, spacing: 0) {
                        ForEach(log.entries) { entry in
                            entryRow(entry)
                            Divider()
                        }
                    }
                }
            }
        }
        .padding(12)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }

    private func entryRow(_ entry: ReminderLog.Entry) -> some View {
        HStack(alignment: .top, spacing: 8) {
            // Timestamp (run-time split).
            Text(split(entry.elapsedSeconds))
                .font(.system(size: 11, weight: .semibold, design: .monospaced))
                .foregroundStyle(.secondary)
                .frame(width: 44, alignment: .leading)
            VStack(alignment: .leading, spacing: 2) {
                if !entry.icons.isEmpty {
                    HStack(spacing: 3) {
                        ForEach(Array(entry.icons.enumerated()), id: \.offset) { _, icon in
                            ReminderIconView(icon: icon)
                        }
                    }
                }
                Text(entry.text)
                    .font(.system(size: 12))
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(.vertical, 4)
    }

    private func split(_ seconds: Int) -> String {
        String(format: "%d:%02d", seconds / 60, seconds % 60)
    }
}

/// Renders one `ReminderIcon` (T-122) — item/sword/ring/etc. map to the item atlas;
/// dungeons/secrets to overworld marks; arrow/checkmark/triforce/door-repair to SF
/// Symbols.
struct ReminderIconView: View {
    let icon: ReminderIcon
    var size: CGFloat = 16

    var body: some View {
        switch icon {
        case .rightArrow:
            Image(systemName: "arrow.right").font(.system(size: size * 0.7, weight: .bold))
                .foregroundStyle(.secondary).frame(width: size, height: size)
        case .checkmark:
            Image(systemName: "checkmark").font(.system(size: size * 0.7, weight: .bold))
                .foregroundStyle(.green).frame(width: size, height: size)
        case .triforce:
            Image(systemName: "triangle.fill").font(.system(size: size * 0.7))
                .foregroundStyle(.yellow).frame(width: size, height: size)
        case .doorRepair:
            Image(systemName: "wrench.and.screwdriver.fill").font(.system(size: size * 0.65))
                .foregroundStyle(.orange).frame(width: size, height: size)
        case .dungeon(let n):
            OverworldMarkIcon(mark: .dungeon(n), size: size)
        case .secret(let s):
            OverworldMarkIcon(mark: .secret(s), size: size)
        default:
            if let atlas = Self.atlasIcon(for: icon),
               let img = Image(atlasIcon: ItemIconAtlas.cgImage(atlas)) {
                img.interpolation(.none).resizable().frame(width: size, height: size)
            } else {
                Image(systemName: "questionmark").font(.system(size: size * 0.6))
                    .foregroundStyle(.secondary).frame(width: size, height: size)
            }
        }
    }

    /// The item-atlas sprite for the sprite-backed icon cases.
    private static func atlasIcon(for icon: ReminderIcon) -> ItemIconAtlas.Icon? {
        switch icon {
        case .item(let id): return ItemIconAtlas.icon(forItemIndex: id)
        case .sword(let level): return level >= 3 ? .magicalSword : (level == 2 ? .whiteSword : .brownSword)
        case .ring(let level): return level >= 2 ? .redRing : .blueRing
        case .wand: return .wand
        case .bowAndArrow: return .bowAndArrow
        case .bomb: return .bomb
        case .key: return .key
        case .ladder: return .ladder
        case .recorder: return .recorder
        case .powerBracelet: return .powerBracelet
        case .bait: return .bait
        case .rupee: return .rupee
        case .book: return .book
        case .boomBook: return .boomBook
        default: return nil
        }
    }
}
