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

    @Test("main counts up from start")
    func mainCounts() {
        let timer = TrackerTimer(now: t0)
        #expect(timer.isRunning)
        #expect(timer.mainElapsed(asOf: at(10)) == 10)
        #expect(!timer.hasLap)
        #expect(timer.lapElapsed(asOf: at(10)) == 10) // lap == main until a lap starts
    }

    @Test("a lap resets independently while the main keeps running")
    func lapIndependent() {
        let timer = TrackerTimer(now: t0)
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
        let timer = TrackerTimer(now: t0)
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

    @Test("reset zeroes everything and clears the lap")
    func resetClears() {
        let timer = TrackerTimer(now: t0)
        timer.startLap(asOf: at(30))
        timer.reset(asOf: at(50))
        #expect(!timer.hasLap)
        #expect(timer.mainElapsed(asOf: at(50)) == 0)
        #expect(timer.mainElapsed(asOf: at(60)) == 10) // still running from reset
    }
}
