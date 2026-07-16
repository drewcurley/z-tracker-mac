import SwiftUI
import TrackerCore

/// One door (wall segment) between two adjacent dungeon rooms (T-019.8, "D3").
/// Renders the reference door states (`Dungeon.fs:13-17`) and forwards the
/// reference gestures (`DungeonUI.fs:717-748`): left = toggle YES, right = toggle
/// NO, middle = toggle YELLOW, Shift+left = prev, Shift+right = next.
///
/// An `unknown` door renders as a faint stub, or nothing when either adjacent
/// room is off-map (the reference blacks it out so off-map borders read as gone).
struct DungeonDoorView: View {
    @Bindable var map: DungeonRoomMap
    let axis: DungeonRoomMap.DoorAxis
    let col: Int
    let row: Int
    /// The interactive frame filling the inter-room gap.
    let frameW: CGFloat
    let frameH: CGFloat

    private var state: DoorState { map.door(axis, col: col, row: row) }

    /// Whether the door sits on an off-map border (its `unknown` state hides).
    private var onOffMapBorder: Bool {
        switch axis {
        case .horizontal:
            return map.room(col: col, row: row).roomType.isOffMap
                || map.room(col: col + 1, row: row).roomType.isOffMap
        case .vertical:
            return map.room(col: col, row: row).roomType.isOffMap
                || map.room(col: col, row: row + 1).roomType.isOffMap
        }
    }

    var body: some View {
        ZStack {
            Color.clear
            marker
        }
        .frame(width: frameW, height: frameH)
        .contentShape(Rectangle())
        .overlay(RoomMouseCatcher { gesture in
            let s = state
            switch gesture {
            case .left: set(s.toggled(to: .yes))
            case .right: set(s.toggled(to: .no))
            case .middle: set(s.toggled(to: .yellow))
            case .shiftLeft: set(s.prev)
            case .shiftRight: set(s.next)
            }
        })
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(axisLabel)
        .accessibilityValue(stateLabel)
        .accessibilityAddTraits(.isButton)
        .accessibilityAction { set(state.toggled(to: .yes)) }
        .accessibilityAction(named: "Cycle door") { set(state.next) }
    }

    @ViewBuilder private var marker: some View {
        switch state {
        case .no:
            // A wall: a red bar across the gap, perpendicular to the passage.
            let color = Color(doorRGB: DoorState.no.rgb)
            if axis == .horizontal {
                Rectangle().fill(color).frame(width: 3, height: frameH + 10)
            } else {
                Rectangle().fill(color).frame(width: frameW + 10, height: 3)
            }
        case .unknown:
            if !onOffMapBorder {
                stateBlock(Color(doorRGB: DoorState.unknown.rgb), inset: 5)
            }
        case .yes, .yellow, .purple:
            stateBlock(Color(doorRGB: state.rgb), inset: 2)
        }
    }

    /// A filled door block sized to the gap, `inset` smaller than the passage
    /// width so it reads as a doorway rather than a full wall.
    @ViewBuilder private func stateBlock(_ color: Color, inset: CGFloat) -> some View {
        if axis == .horizontal {
            RoundedRectangle(cornerRadius: 2).fill(color)
                .frame(width: max(4, frameW - 4), height: frameH - inset * 2)
        } else {
            RoundedRectangle(cornerRadius: 2).fill(color)
                .frame(width: frameW - inset * 2, height: max(4, frameH - 4))
        }
    }

    private func set(_ newState: DoorState) {
        map.setDoor(newState, axis: axis, col: col, row: row)
    }

    private var axisLabel: String {
        axis == .horizontal
            ? "Door between column \(col + 1) and \(col + 2), row \(row + 1)"
            : "Door between row \(row + 1) and \(row + 2), column \(col + 1)"
    }

    private var stateLabel: String {
        switch state {
        case .unknown: "Unknown"
        case .no: "No door (wall)"
        case .yes: "Open"
        case .yellow: "Yellow"
        case .purple: "Purple"
        }
    }
}

extension Color {
    /// A `Color` from a `0xRRGGBB` integer (the reference door palette).
    init(doorRGB rgb: Int) {
        self.init(
            red: Double((rgb >> 16) & 0xFF) / 255,
            green: Double((rgb >> 8) & 0xFF) / 255,
            blue: Double(rgb & 0xFF) / 255
        )
    }
}
