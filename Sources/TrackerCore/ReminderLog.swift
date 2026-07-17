import Observation

/// A capped, most-recent-first log of the reminders that have fired (T-102) — the
/// reference's "log" affordance for reviewing past reminders / beep explanations
/// (`whats-new v1.3`). Pure data so it's unit-testable; the UI just lists `entries`.
@Observable
public final class ReminderLog {
    /// One logged reminder: its text, the run-time (elapsed seconds) it fired at, the
    /// icons describing it (T-122), and a monotonically-increasing sequence number
    /// (so identical texts are still distinct rows).
    public struct Entry: Identifiable, Equatable, Sendable {
        public let id: Int
        public let text: String
        /// Elapsed run seconds when the reminder fired (for the timestamp column).
        public let elapsedSeconds: Int
        /// Icons describing the reminder (rendered beside the text).
        public let icons: [ReminderIcon]
    }

    /// Newest first.
    public private(set) var entries: [Entry] = []
    private var nextID = 0
    private let cap: Int

    public init(cap: Int = 100) { self.cap = cap }

    /// Append a fired reminder; drops the oldest past `cap`.
    public func append(_ text: String, elapsedSeconds: Int = 0, icons: [ReminderIcon] = []) {
        entries.insert(Entry(id: nextID, text: text, elapsedSeconds: elapsedSeconds, icons: icons), at: 0)
        nextID += 1
        if entries.count > cap { entries.removeLast(entries.count - cap) }
    }

    public func clear() { entries.removeAll() }
}
