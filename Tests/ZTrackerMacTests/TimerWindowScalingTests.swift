import Testing
import CoreGraphics
@testable import ZTrackerMac

@Suite("Timer window scaling (T-115)")
struct TimerWindowScalingTests {
    @Test("readout scales up with the window and never below the floor")
    func scales() {
        let small = TimerWindowView.mainFontSize(for: .init(width: 220, height: 90), hasLap: false)
        let big = TimerWindowView.mainFontSize(for: .init(width: 900, height: 400), hasLap: false)
        #expect(big > small)                       // grows with the window
        #expect(small >= 12)                       // floor respected

        // A very small window clamps to the 12pt floor rather than vanishing.
        #expect(TimerWindowView.mainFontSize(for: .init(width: 20, height: 10), hasLap: false) == 12)
    }

    @Test("width- and height-limited windows both constrain the size")
    func bothAxesConstrain() {
        // Very wide but short → height limits.
        let wide = TimerWindowView.mainFontSize(for: .init(width: 2000, height: 120), hasLap: false)
        #expect(wide == 120 / 1.7)
        // Tall but narrow → width limits.
        let tall = TimerWindowView.mainFontSize(for: .init(width: 200, height: 2000), hasLap: false)
        #expect(tall == 200 / 6.6)
    }

    @Test("a lap line reserves extra vertical room")
    func lapReservesRoom() {
        let size = CGSize(width: 2000, height: 300)  // height-limited so the lap factor shows
        let noLap = TimerWindowView.mainFontSize(for: size, hasLap: false)
        let withLap = TimerWindowView.mainFontSize(for: size, hasLap: true)
        #expect(withLap < noLap)
    }
}
