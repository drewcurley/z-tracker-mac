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

    /// `H:MM:SS` without milliseconds — the on-screen display format. The ms are
    /// only needed at capture time (written to the notes), read from the timer at
    /// that instant via `hmsMillis`, so the visible clock can tick once per second.
    static func hms(_ interval: TimeInterval) -> String {
        let totalSec = Int(max(0, interval).rounded(.down))
        return String(format: "%d:%02d:%02d", totalSec / 3600, (totalSec / 60) % 60, totalSec % 60)
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
    /// Whether the run has been started via "Go". Before this, the timer shows
    /// a Go button (the reference auto-starts, which the community dislikes —
    /// the tracker can be loaded/configured before starting).
    private(set) var hasStarted = false
    /// Wall-clock instant the run first began (or last had its elapsed zeroed).
    /// Persisted so a reopened session can, optionally, count *real* time since the
    /// run began — including the gap while the app was closed (T-192).
    private var runStart: Date?

    var isRunning: Bool { segmentStart != nil }

    /// Starts the run (the "Go" button). No-op if already started.
    func start(asOf now: Date = Date()) {
        guard !hasStarted else { return }
        hasStarted = true
        segmentStart = now
        runStart = now
    }

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

    /// Resume the main. No-op if not started or already running.
    func resume(asOf now: Date = Date()) {
        guard hasStarted, segmentStart == nil else { return }
        segmentStart = now
    }

    /// Pause ⇄ resume the main (and thus the lap). No-op before the run starts.
    func togglePause(asOf now: Date = Date()) {
        guard hasStarted else { return }
        if isRunning { pause(asOf: now) } else { resume(asOf: now) }
    }

    /// Reset the elapsed to zero, keeping the running/paused (and started) state.
    func reset(asOf now: Date = Date()) {
        accumulated = 0
        if isRunning { segmentStart = now }
        lapOrigin = 0
        hasLap = false
        // A reset restarts the "time since it began" clock too, so real-time restore
        // measures from here rather than the original Go.
        runStart = hasStarted ? now : nil
    }

    /// A `Codable` snapshot of the timer for save/load (T-164): the total elapsed,
    /// whether the run had started, and the wall-clock instant it began (`runStart`,
    /// T-192 — optional for backward-compat with saves written before it existed).
    struct State: Codable, Sendable {
        var elapsed: TimeInterval
        var hasStarted: Bool
        var runStart: Date?
    }
    func snapshot(asOf now: Date = Date()) -> State {
        State(elapsed: mainElapsed(asOf: now), hasStarted: hasStarted, runStart: runStart)
    }

    /// Restore a saved timer (T-192). Crash-recovery default is to **resume** so a
    /// reopened session keeps timing (the user forgot to un-pause after a crash once
    /// too often). `realTimeSinceStart` picks the elapsed basis:
    /// - `false` (default): pick up the saved *active* elapsed where it left off.
    /// - `true`: count real wall-clock time since the run began, including the gap
    ///   while the app was closed (falls back to the saved elapsed if no `runStart`).
    func restore(_ s: State, resuming: Bool = false,
                 realTimeSinceStart: Bool = false, asOf now: Date = Date()) {
        hasStarted = s.hasStarted
        runStart = s.runStart
        lapOrigin = 0
        hasLap = false
        if realTimeSinceStart, let rs = s.runStart {
            accumulated = max(0, now.timeIntervalSince(rs))
        } else {
            accumulated = max(0, s.elapsed)
        }
        // Resume only makes sense once the run has actually started.
        segmentStart = (resuming && hasStarted) ? now : nil
    }

    /// Reset to the pristine pre-"Go" state (T-109) — used by Reset App, which
    /// keeps the same timer instance (so the quit-warning check stays valid)
    /// instead of replacing it.
    func hardReset() {
        accumulated = 0
        segmentStart = nil
        lapOrigin = 0
        hasLap = false
        hasStarted = false
        runStart = nil
    }
}
