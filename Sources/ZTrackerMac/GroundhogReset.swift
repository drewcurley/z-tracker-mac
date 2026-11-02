import Foundation
import TrackerCore

/// The groundhog/routers inventory reset (T-246), shared by the hotkey and the "Reset (keep
/// maps)" button. Like the reference's reset button, it first saves the whole tracker to a
/// `ztracker-pre-groundhog-…` file; then it resets at once — one press, no double-tap — and the
/// toast offers **Undo** for a few seconds, so a stray press costs one click instead of the run.
@MainActor
final class GroundhogReset {
    /// Everything a reset changes: the model, the reminder engine's memory (so restored items
    /// don't re-announce), and the lap timer. The main timer is never touched.
    struct Snapshot {
        let model: TrackerModel.State
        let reminders: ReminderEngine.GroundhogMemory
        let lap: TrackerTimer.LapState
    }

    static let undoWindow: Duration = .seconds(10)

    /// The pre-reset state Undo restores while the toast is up. A repeat press inside the
    /// window keeps the *first* snapshot, so a habitual double-tap still undoes to before it.
    private(set) var pending: Snapshot?
    private var pendingToast: UUID?
    private var generation = 0
    private let directory: URL

    init(directory: URL = GameSave.defaultDirectory) {
        self.directory = directory
    }

    /// Back up, reset, restart the lap, and offer Undo. Returns the backup file, or `nil` when
    /// none was written (a repeat press while Undo is still pending, or the write failed).
    @discardableResult
    func perform(model: TrackerModel, timer: TrackerTimer,
                 reminders: ReminderController? = nil) -> URL? {
        var backup: URL?
        if pending == nil {
            pending = Snapshot(model: model.snapshot(), reminders: model.reminderEngine.groundhogMemory,
                               lap: timer.lapState)
            let url = directory.appendingPathComponent(GameSave.archivedName("pre-groundhog"))
            if (try? GameSave.write(GameSave.makeFile(model: model, timer: timer), to: url)) != nil {
                backup = url
            }
        }
        model.resetForGroundhogOrRouters()
        timer.startLap()

        generation += 1
        let current = generation
        if let reminders {
            if let old = pendingToast { reminders.dismiss(old) }
            pendingToast = reminders.toast(
                "Inventory reset (groundhog restart)", duration: Self.undoWindow,
                action: .init(title: "Undo") { [weak self, weak model, weak timer, weak reminders] in
                    guard let self, let model, let timer else { return }
                    self.undo(model: model, timer: timer)
                    reminders?.toast("Reset undone")
                })
        }
        Task { [weak self] in
            try? await Task.sleep(for: Self.undoWindow)
            if self?.generation == current { self?.expire() }
        }
        return backup
    }

    /// Put back the state from before the reset. No-op once the Undo window has passed.
    func undo(model: TrackerModel, timer: TrackerTimer) {
        guard let s = pending else { return }
        expire()
        model.restore(s.model)
        model.reminderEngine.restore(s.reminders)
        timer.restoreLap(s.lap)
    }

    /// The Undo window ended (the backup file is still there for Load).
    func expire() {
        pending = nil
        pendingToast = nil
    }
}
