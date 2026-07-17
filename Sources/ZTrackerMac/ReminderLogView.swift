import SwiftUI
import TrackerCore

/// The reminder log (T-102, now a window — T-122): a most-recent-first list of the
/// reminders that have fired, each with its run-time and a row of icons describing
/// what it's about (e.g. ladder → coast item, or magical sword → Level 3), plus a
/// Clear action.
struct ReminderLogView: View {
    @Bindable var log: ReminderLog

    /// Log zoom (T-125): scales every row's text + icons; ⌘+ / ⌘- / ⌘0.
    @State private var fontScale: CGFloat = 1.0
    private static let minScale: CGFloat = 0.7
    private static let maxScale: CGFloat = 2.6
    private func zoom(_ by: CGFloat) {
        fontScale = min(Self.maxScale, max(Self.minScale, fontScale + by))
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Reminder log").font(.headline)
                Spacer()
                // Zoom controls (⌘- / ⌘0 / ⌘+).
                Button("A−") { zoom(-0.15) }
                    .keyboardShortcut("-", modifiers: .command)
                    .disabled(fontScale <= Self.minScale)
                Button("A") { fontScale = 1.0 }
                    .keyboardShortcut("0", modifiers: .command)
                Button("A+") { zoom(0.15) }
                    .keyboardShortcut("+", modifiers: .command)
                    .disabled(fontScale >= Self.maxScale)
                Divider().frame(height: 14)
                Button("Clear") { log.clear() }
                    .disabled(log.entries.isEmpty)
            }
            .font(.caption).controlSize(.small)
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
        // Timestamp, then the icons and text all on one line (T-125), the text
        // wrapping to the right of the icons; everything scales with `fontScale`.
        HStack(alignment: .top, spacing: 6 * fontScale) {
            Text(split(entry.elapsedSeconds))
                .font(.system(size: 11 * fontScale, weight: .semibold, design: .monospaced))
                .foregroundStyle(.secondary)
                .frame(width: 44 * fontScale, alignment: .leading)
            ForEach(Array(entry.icons.enumerated()), id: \.offset) { _, icon in
                ReminderIconView(icon: icon, size: 16 * fontScale)
            }
            Text(entry.text)
                .font(.system(size: 12 * fontScale))
                .frame(maxWidth: .infinity, alignment: .leading)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.vertical, 4 * fontScale)
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
            // The dungeon *number* tile (T-125), matching how the player reads
            // "consider dungeon 3".
            Text("\(n)")
                .font(.system(size: size * 0.72, weight: .heavy, design: .rounded))
                .foregroundStyle(.white)
                .frame(width: size, height: size)
                .background(RoundedRectangle(cornerRadius: size * 0.18).fill(Color(white: 0.22)))
                .overlay(RoundedRectangle(cornerRadius: size * 0.18).strokeBorder(Color(white: 0.45)))
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
