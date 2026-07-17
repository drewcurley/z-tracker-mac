import Observation

/// A capped, most-recent-first log of the reminders that have fired (T-102) — the
/// reference's "log" affordance for reviewing past reminders / beep explanations
/// (`whats-new v1.3`). Pure data so it's unit-testable; the UI just lists `entries`.
@Observable
public final class ReminderLog {
    /// One logged reminder: its text and a monotonically-increasing sequence
    /// number (so identical texts are still distinct rows).
    public struct Entry: Identifiable, Equatable, Sendable {
        public let id: Int
        public let text: String
    }

    /// Newest first.
    public private(set) var entries: [Entry] = []
    private var nextID = 0
    private let cap: Int

    public init(cap: Int = 100) { self.cap = cap }

    /// Append a fired reminder; drops the oldest past `cap`.
    public func append(_ text: String) {
        entries.insert(Entry(id: nextID, text: text), at: 0)
        nextID += 1
        if entries.count > cap { entries.removeLast(entries.count - cap) }
    }

    public func clear() { entries.removeAll() }
}
