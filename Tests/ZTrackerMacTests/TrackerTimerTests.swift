import Foundation
import Testing
@testable import ZTrackerMac

@Suite("Timer formatting")
struct TimerFormattingTests {
    @Test("H:MM:SS.mmm formatting")
    func formats() {
        #expect(TimerFormatting.hmsMillis(0) == "0:00:00.000")
        #expect(TimerFormatting.hmsMillis(771) == "0:12:51.000")          // 12:51
        #expect(TimerFormatting.hmsMillis(3661.5) == "1:01:01.500")       // 1h 1m 1.5s
        #expect(TimerFormatting.hmsMillis(0.042) == "0:00:00.042")
        #expect(TimerFormatting.hmsMillis(-5) == "0:00:00.000")            // clamps negatives
    }
}

@Suite("TrackerTimer main + lap")
@MainActor
struct TrackerTimerTests {
    private let t0 = Date(timeIntervalSinceReferenceDate: 1_000_000)
    private func at(_ secs: TimeInterval) -> Date { t0.addingTimeInterval(secs) }
    /// A timer already "Go"-started at t0.
    private func startedTimer() -> TrackerTimer { let t = TrackerTimer(); t.start(asOf: t0); return t }

    @Test("timer waits for Go, then starts")
    func goButton() {
        let timer = TrackerTimer()
        #expect(!timer.hasStarted && !timer.isRunning)
        #expect(timer.mainElapsed(asOf: at(10)) == 0)   // not counting yet
        // Pause/resume are no-ops before Go.
        timer.resume(asOf: at(5))
        #expect(!timer.isRunning)
        // Go.
        timer.start(asOf: at(10))
        #expect(timer.hasStarted && timer.isRunning)
        #expect(timer.mainElapsed(asOf: at(20)) == 10)  // counts from Go
        // A second start is a no-op.
        timer.start(asOf: at(99))
        #expect(timer.mainElapsed(asOf: at(30)) == 20)
    }

    @Test("main counts up from start")
    func mainCounts() {
        let timer = startedTimer()
        #expect(timer.isRunning)
        #expect(timer.mainElapsed(asOf: at(10)) == 10)
        #expect(!timer.hasLap)
        #expect(timer.lapElapsed(asOf: at(10)) == 10) // lap == main until a lap starts
    }

    @Test("a lap resets independently while the main keeps running")
    func lapIndependent() {
        let timer = startedTimer()
        // 30s in, a groundhog reset starts a fresh lap.
        timer.startLap(asOf: at(30))
        #expect(timer.hasLap)
        // Main keeps its total; lap counts from the reset moment.
        #expect(timer.mainElapsed(asOf: at(50)) == 50)
        #expect(timer.lapElapsed(asOf: at(50)) == 20)
        // A second reset restarts the lap again; main is unaffected.
        timer.startLap(asOf: at(50))
        #expect(timer.mainElapsed(asOf: at(60)) == 60)
        #expect(timer.lapElapsed(asOf: at(60)) == 10)
    }

    @Test("pause freezes both main and lap; resume continues")
    func pauseFreezes() {
        let timer = startedTimer()
        timer.startLap(asOf: at(10))
        timer.togglePause(asOf: at(20)) // pause at 20s (lap = 10)
        #expect(!timer.isRunning)
        // Time passes while paused — no change.
        #expect(timer.mainElapsed(asOf: at(100)) == 20)
        #expect(timer.lapElapsed(asOf: at(100)) == 10)
        // Resume at 100s; another 5s elapses.
        timer.togglePause(asOf: at(100))
        #expect(timer.mainElapsed(asOf: at(105)) == 25)
        #expect(timer.lapElapsed(asOf: at(105)) == 15)
    }

    @Test("explicit pause/resume are idempotent (for the Zelda-rescued trigger)")
    func pauseResumeIdempotent() {
        let timer = startedTimer()
        timer.pause(asOf: at(10))
        #expect(!timer.isRunning && timer.mainElapsed(asOf: at(30)) == 10)
        // Pausing again does nothing.
        timer.pause(asOf: at(40))
        #expect(timer.mainElapsed(asOf: at(50)) == 10)
        // Resume, then a redundant resume doesn't lose time.
        timer.resume(asOf: at(50))
        timer.resume(asOf: at(60))
        #expect(timer.mainElapsed(asOf: at(70)) == 30) // 10 + (70-50)
    }

    @Test("reset zeroes everything and clears the lap")
    func resetClears() {
        let timer = startedTimer()
        timer.startLap(asOf: at(30))
        timer.reset(asOf: at(50))
        #expect(!timer.hasLap)
        #expect(timer.mainElapsed(asOf: at(50)) == 0)
        #expect(timer.mainElapsed(asOf: at(60)) == 10) // still running from reset
    }

    @Test("hardReset returns to the pristine pre-Go state (T-109)")
    func hardResetClears() {
        let timer = startedTimer()
        timer.startLap(asOf: at(30))
        #expect(timer.hasStarted && timer.isRunning)
        timer.hardReset()
        #expect(!timer.hasStarted)
        #expect(!timer.isRunning)
        #expect(!timer.hasLap)
        #expect(timer.mainElapsed(asOf: at(100)) == 0) // frozen at zero, not running
    }
}
