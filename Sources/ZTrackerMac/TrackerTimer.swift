import Foundation
import Observation

/// Formats a run-timer interval as `H:MM:SS.mmm` (T-035.4) — the reference's
/// `H:MM:SS` plus milliseconds for precise timing.
enum TimerFormatting {
    static func hmsMillis(_ interval: TimeInterval) -> String {
        let totalMs = Int((max(0, interval) * 1000).rounded(.down))
        let ms = totalMs % 1000
        let totalSec = totalMs / 1000
        return String(format: "%d:%02d:%02d.%03d", totalSec / 3600, (totalSec / 60) % 60, totalSec % 60, ms)
    }
}

/// The run timer: a **main** stopwatch (counts up from session start, pausable)
/// plus an independent **lap** timer that resets on each groundhog/routers reset
/// while the main keeps running (T-035.4). The elapsed values are pure
/// functions of an injected "now" `Date`, so a `TimelineView` drives the
/// display and the logic stays unit-testable.
@Observable
@MainActor
final class TrackerTimer {
    /// Elapsed accumulated across prior (now-ended) running segments.
    private var accumulated: TimeInterval = 0
    /// Start of the current running segment, or `nil` when paused.
    private var segmentStart: Date?
    /// The main-elapsed value at the last lap reset (the lap's origin).
    private var lapOrigin: TimeInterval = 0
    /// Whether a lap has been started (a groundhog reset has occurred).
    private(set) var hasLap = false

    var isRunning: Bool { segmentStart != nil }

    init(now: Date = Date()) { segmentStart = now }

    /// Total elapsed on the main timer as of `now`.
    func mainElapsed(asOf now: Date) -> TimeInterval {
        accumulated + (segmentStart.map { now.timeIntervalSince($0) } ?? 0)
    }

    /// Elapsed on the current lap (since the last reset) as of `now`. The lap
    /// tracks the main, so pausing the main also freezes the lap.
    func lapElapsed(asOf now: Date) -> TimeInterval {
        max(0, mainElapsed(asOf: now) - lapOrigin)
    }

    /// Start a fresh lap at the current moment (called on a groundhog reset).
    /// The main timer is unaffected.
    func startLap(asOf now: Date = Date()) {
        lapOrigin = mainElapsed(asOf: now)
        hasLap = true
    }

    /// Pause the main (and thus the lap). No-op if already paused.
    func pause(asOf now: Date = Date()) {
        guard let start = segmentStart else { return }
        accumulated += now.timeIntervalSince(start)
        segmentStart = nil
    }

    /// Resume the main. No-op if already running.
    func resume(asOf now: Date = Date()) {
        guard segmentStart == nil else { return }
        segmentStart = now
    }

    /// Pause ⇄ resume the main (and thus the lap).
    func togglePause(asOf now: Date = Date()) {
        if isRunning { pause(asOf: now) } else { resume(asOf: now) }
    }

    /// Reset everything to zero, keeping the running/paused state.
    func reset(asOf now: Date = Date()) {
        accumulated = 0
        segmentStart = isRunning ? now : nil
        lapOrigin = 0
        hasLap = false
    }
}
