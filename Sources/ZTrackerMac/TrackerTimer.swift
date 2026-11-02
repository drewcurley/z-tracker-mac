import Foundation
import Observation

/// Formats a run-timer interval as `H:MM:SS.mmm` (T-035.4) — the reference's
/// `H:MM:SS` plus milliseconds for precise timing.
enum TimerFormatting {
    /// Upper bound for displayed/restored elapsed time (~115 days). Keeps a corrupt or
    /// absurd value from trapping the `Int` conversions below (T-241).
    static let maxInterval: TimeInterval = 10_000_000
    static func clamped(_ interval: TimeInterval) -> TimeInterval {
        guard interval.isFinite else { return 0 }
        return min(max(0, interval), maxInterval)
    }

    static func hmsMillis(_ interval: TimeInterval) -> String {
        let totalMs = Int((clamped(interval) * 1000).rounded(.down))
        let ms = totalMs % 1000
        let totalSec = totalMs / 1000
        return String(format: "%d:%02d:%02d.%03d", totalSec / 3600, (totalSec / 60) % 60, totalSec % 60, ms)
    }

    /// `H:MM:SS` without milliseconds — the on-screen display format. The ms are
    /// only needed at capture time (written to the notes), read from the timer at
    /// that instant via `hmsMillis`, so the visible clock can tick once per second.
    static func hms(_ interval: TimeInterval) -> String {
        let totalSec = Int(clamped(interval).rounded(.down))
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
    /// Total time spent paused since `runStart` (completed pauses only). Lets real-time
    /// restore count the time the app was closed *while running* without also counting the
    /// player's deliberate pauses (T-240).
    private var pausedTotal: TimeInterval = 0
    /// When the current pause began (nil while running or before Go).
    private var pauseStart: Date?

    var isRunning: Bool { segmentStart != nil }

    /// Starts the run (the "Go" button). No-op if already started.
    func start(asOf now: Date = Date()) {
        guard !hasStarted else { return }
        hasStarted = true
        segmentStart = now
        runStart = now
        pausedTotal = 0
        pauseStart = nil
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

    /// Just the lap, so a groundhog reset's Undo can put the previous lap back (T-246).
    struct LapState: Equatable {
        var origin: TimeInterval
        var hasLap: Bool
    }
    var lapState: LapState { LapState(origin: lapOrigin, hasLap: hasLap) }
    func restoreLap(_ s: LapState) {
        lapOrigin = s.origin
        hasLap = s.hasLap
    }

    /// Pause the main (and thus the lap). No-op if already paused.
    func pause(asOf now: Date = Date()) {
        guard let start = segmentStart else { return }
        accumulated += now.timeIntervalSince(start)
        segmentStart = nil
        pauseStart = now
    }

    /// Resume the main. No-op if not started or already running.
    func resume(asOf now: Date = Date()) {
        guard hasStarted, segmentStart == nil else { return }
        if let p = pauseStart { pausedTotal += max(0, now.timeIntervalSince(p)) }
        pauseStart = nil
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
        pausedTotal = 0
        pauseStart = (hasStarted && !isRunning) ? now : nil
    }

    /// A `Codable` snapshot of the timer for save/load (T-164): the total elapsed, whether
    /// the run had started, the wall-clock instant it began (`runStart`, T-192), and — so a
    /// reopened run comes back exactly as it was (T-240) — whether it was running, the time
    /// spent paused, and the lap. The newer fields are optional for backward-compat with
    /// older saves.
    struct State: Codable, Sendable {
        var elapsed: TimeInterval
        var hasStarted: Bool
        var runStart: Date?
        var wasRunning: Bool?
        var pausedTotal: TimeInterval?
        var lapOrigin: TimeInterval?
        var hasLap: Bool?
    }
    func snapshot(asOf now: Date = Date()) -> State {
        let currentPause = pauseStart.map { max(0, now.timeIntervalSince($0)) } ?? 0
        return State(elapsed: mainElapsed(asOf: now), hasStarted: hasStarted, runStart: runStart,
                     wasRunning: isRunning, pausedTotal: pausedTotal + currentPause,
                     lapOrigin: lapOrigin, hasLap: hasLap)
    }

    /// The elapsed a restore should start from (T-240). Pure, so it's testable.
    /// - Active mode, or a run saved **paused**: the saved elapsed, as-is (time the app was
    ///   closed while paused never counts).
    /// - Real-time mode for a run saved **running**: real time since the run began, minus the
    ///   time spent paused — i.e. the saved elapsed plus the closed gap. Never less than the
    ///   saved elapsed (guards clock changes). Older saves without pause data count no pauses.
    static func restoredElapsed(_ s: State, realTimeSinceStart: Bool, now: Date) -> TimeInterval {
        let saved = TimerFormatting.clamped(s.elapsed)
        guard realTimeSinceStart, s.wasRunning != false, let rs = s.runStart else { return saved }
        let real = now.timeIntervalSince(rs) - TimerFormatting.clamped(s.pausedTotal ?? 0)
        return TimerFormatting.clamped(max(saved, real))
    }

    /// Restore a saved timer (T-192/T-240). Crash-recovery default is to **resume** a run
    /// that was running when saved, so a reopened session keeps timing; a run saved paused
    /// stays paused. `realTimeSinceStart` picks the elapsed basis (see `restoredElapsed`).
    /// The lap is restored too. Afterwards the wall-clock anchor is re-based on `now`, so a
    /// later real-time restore measures from this point consistently.
    func restore(_ s: State, resuming: Bool = false,
                 realTimeSinceStart: Bool = false, asOf now: Date = Date()) {
        hasStarted = s.hasStarted
        accumulated = Self.restoredElapsed(s, realTimeSinceStart: realTimeSinceStart, now: now)
        let lap = TimerFormatting.clamped(s.lapOrigin ?? 0)
        hasLap = s.hasLap ?? false
        lapOrigin = hasLap ? min(lap, accumulated) : 0
        // Resume only a started run that was running when saved (older saves: assume running).
        let run = resuming && hasStarted && s.wasRunning != false
        segmentStart = run ? now : nil
        pauseStart = (hasStarted && !run) ? now : nil
        pausedTotal = 0
        runStart = hasStarted ? now.addingTimeInterval(-accumulated) : nil
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
        pausedTotal = 0
        pauseStart = nil
    }
}
