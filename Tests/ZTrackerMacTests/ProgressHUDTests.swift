import Testing
import TrackerCore
@testable import ZTrackerMac

@Suite("Progress HUD compositor (T-035.10)")
@MainActor
struct ProgressHUDTests {
    @Test("renders a 98×79 image for the empty state")
    func emptyRenders() throws {
        let img = try #require(FauxItemsHUD.render(
            state: PlayerComputedStateSummary(), progress: PlayerProgressAndTakeAnyHearts(),
            havePotionLetter: false, haveBook: false))
        #expect(img.width == FauxItemsHUD.width)
        #expect(img.height == FauxItemsHUD.height)
    }

    @Test("renders for a fully-kitted state without crashing")
    func fullRenders() throws {
        let s = PlayerComputedStateSummary(
            haveRecorder: true, haveLadder: true, haveAnyKey: true, havePowerBracelet: true,
            haveRaft: true, playerHearts: 16, swordLevel: 3, candleLevel: 2, ringLevel: 2,
            haveBow: true, arrowLevel: 2, haveWand: true, haveBookOrShield: true, boomerangLevel: 2)
        let p = PlayerProgressAndTakeAnyHearts(hasBombs: true, hasMeat: true)
        let img = try #require(FauxItemsHUD.render(state: s, progress: p, havePotionLetter: true, haveBook: true))
        #expect(img.width == 98 && img.height == 79)
    }
}
