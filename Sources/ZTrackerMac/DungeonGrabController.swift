import Observation
import TrackerCore

/// Transient UI state for the dungeon room-map **GRAB** tool (T-083) — the
/// reference's `GrabHelper` (`Dungeon.fs:61-160`) + its DungeonUI interaction.
///
/// GRAB is a cut-and-paste for a connected segment of rooms: enter grab mode,
/// click a marked room to pick up it and every room contiguous with it (plus the
/// doors between them), then click a destination to drop the segment there. The
/// drop is previewed on hover (lime = lands on empty, yellow = would overwrite),
/// and completes with a keep/undo prompt so you can experiment.
///
/// This holds only interaction state; the actual grid math lives on
/// `DungeonRoomMap` (`contiguousRegion` / `moveRegion` / `snapshot`).
@Observable
final class DungeonGrabController {
    /// Whether grab mode is armed (the GRAB button is lit).
    var isGrabMode = false
    /// The picked-up segment, or `nil` when nothing is grabbed yet.
    private(set) var region: Set<DungeonRoomMap.RoomCoord>?
    /// The room that was clicked to grab (the offset origin for the drop).
    private(set) var anchor: DungeonRoomMap.RoomCoord?
    /// The cell the pointer is currently over, for the live preview.
    var hoverCell: DungeonRoomMap.RoomCoord?

    /// The keep/undo prompt is showing after a drop.
    var pendingConfirm = false
    private var snapshot: DungeonRoomMap.Snapshot?

    var hasGrab: Bool { region != nil }

    /// Toggle grab mode from the GRAB button; turning it off aborts any grab.
    func toggle() {
        isGrabMode.toggle()
        if !isGrabMode { clear() }
    }

    /// Abort entirely (tab switch, groundhog reset, GRAB off).
    func abort() {
        isGrabMode = false
        clear()
    }

    private func clear() {
        region = nil
        anchor = nil
        hoverCell = nil
    }

    /// A left-click on `(col,row)` while in grab mode: pick up (first click) or
    /// drop (second click). Returns `true` if it consumed the click (so the cell
    /// skips its normal marking behavior).
    @discardableResult
    func handleClick(col: Int, row: Int, map: DungeonRoomMap) -> Bool {
        guard isGrabMode else { return false }
        if region == nil {
            // Pick up: only a marked (non-empty) room starts a grab.
            guard !map.room(col: col, row: row).isEmpty else { return true }
            region = map.contiguousRegion(col: col, row: row)
            anchor = DungeonRoomMap.RoomCoord(col: col, row: row)
        } else if let region, let anchor {
            // Drop at the offset; snapshot first so Undo can restore.
            snapshot = map.snapshot()
            map.moveRegion(region, byColumns: col - anchor.col, rows: row - anchor.row)
            clear()
            isGrabMode = false          // the reference's DoDrop → Abort()
            pendingConfirm = true
        }
        return true
    }

    /// Keep the moved segment.
    func keepChanges() {
        snapshot = nil
        pendingConfirm = false
    }

    /// Undo the move, restoring the pre-drop grid.
    func undoChanges(map: DungeonRoomMap) {
        if let snapshot { map.restore(snapshot) }
        snapshot = nil
        pendingConfirm = false
    }

    /// How `(col,row)` should be tinted in grab mode.
    enum Highlight { case none, source, preview, ok, warn }

    /// The preview tint for a cell: nothing outside grab mode; the pink source
    /// segment and lime/yellow drop targets once grabbed; a lime preview of what
    /// the hovered room would pick up before that.
    func highlight(col: Int, row: Int, map: DungeonRoomMap) -> Highlight {
        guard isGrabMode else { return .none }
        let cell = DungeonRoomMap.RoomCoord(col: col, row: row)
        if let region {
            if region.contains(cell) { return .source }
            if let anchor, let hoverCell {
                let dx = hoverCell.col - anchor.col, dy = hoverCell.row - anchor.row
                if region.contains(DungeonRoomMap.RoomCoord(col: col - dx, row: row - dy)) {
                    return map.room(col: col, row: row).isEmpty ? .ok : .warn
                }
            }
            return .none
        }
        // No grab yet: preview the segment the hovered marked room would pick up.
        if let hoverCell, !map.room(col: hoverCell.col, row: hoverCell.row).isEmpty,
           map.contiguousRegion(col: hoverCell.col, row: hoverCell.row).contains(cell) {
            return .preview
        }
        return .none
    }
}
