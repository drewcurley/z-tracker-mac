import Testing
import TrackerCore
@testable import ZTrackerMac

@Suite("Overworld overlay state + predicates")
struct OverworldOverlaysTests {
    @MainActor
    @Test("overlay state: hover previews, click locks; active = locked OR hovered")
    func stateModel() {
        let s = OverworldOverlayState()
        #expect(!s.isActive(.money))
        // Hover previews.
        s.setHover(.money, true)
        #expect(s.isActive(.money) && !s.isLocked(.money))
        s.setHover(.money, false)
        #expect(!s.isActive(.money))
        // Click locks (stays on without hover).
        s.toggleLock(.money)
        #expect(s.isActive(.money) && s.isLocked(.money))
        s.toggleLock(.money)
        #expect(!s.isActive(.money))
        // Leaving a different overlay doesn't clear the current hover.
        s.setHover(.openCaves, true)
        s.setHover(.money, false)
        #expect(s.hovered == .openCaves)
    }

    @MainActor
    @Test("hide-marks overlay: previews on hover, locks on click, independent of highlights")
    func hideMarksState() {
        let s = OverworldOverlayState()
        #expect(!s.isActive(.hideMarks))
        // Hover previews the suppression without committing it.
        s.setHover(.hideMarks, true)
        #expect(s.isActive(.hideMarks) && !s.isLocked(.hideMarks))
        s.setHover(.hideMarks, false)
        #expect(!s.isActive(.hideMarks))
        // Click keeps it on.
        s.toggleLock(.hideMarks)
        #expect(s.isActive(.hideMarks) && s.isLocked(.hideMarks))
        // It doesn't entangle with a highlight overlay.
        #expect(!s.isActive(.money) && !s.isLocked(.money))
        s.toggleLock(.hideMarks)
        #expect(!s.isActive(.hideMarks))
    }

    @Test("money tile: MMG + Unknown Secret always; sized secrets while not collected (T-111)")
    func moneyTile() {
        #expect(OverworldOverlays.isMoneyTile(.moneyMakingGame, secretCollected: false))
        #expect(OverworldOverlays.isMoneyTile(.moneyMakingGame, secretCollected: true))
        #expect(OverworldOverlays.isMoneyTile(.secret(.unknown), secretCollected: false))
        // A marked sized secret is money while it hasn't been collected...
        #expect(OverworldOverlays.isMoneyTile(.secret(.large), secretCollected: false))
        #expect(OverworldOverlays.isMoneyTile(.secret(.medium), secretCollected: false))
        #expect(OverworldOverlays.isMoneyTile(.secret(.small), secretCollected: false))
        // ...and drops out once collected (spent).
        #expect(!OverworldOverlays.isMoneyTile(.secret(.large), secretCollected: true))
        // Non-money marks never highlight.
        #expect(!OverworldOverlays.isMoneyTile(.dungeon(3), secretCollected: false))
        #expect(!OverworldOverlays.isMoneyTile(.unmarked, secretCollected: false))
    }

    @Test("open-cave early game: unmarked nothingable screens")
    func openCaveEarly() {
        #expect(OverworldOverlays.isOpenCaveTile(
            mark: .unmarked, nothingable: true, hasArmos: false,
            pastEarlyGame: false, armosClaimed: false))
        // Marked, or not nothingable → no.
        #expect(!OverworldOverlays.isOpenCaveTile(
            mark: .dungeon(1), nothingable: true, hasArmos: false,
            pastEarlyGame: false, armosClaimed: false))
        #expect(!OverworldOverlays.isOpenCaveTile(
            mark: .unmarked, nothingable: false, hasArmos: false,
            pastEarlyGame: false, armosClaimed: false))
    }

    @Test("open-cave late game: only unclaimed Armos spots")
    func openCaveLate() {
        // Past early game, a nothingable non-armos screen is no longer shown.
        #expect(!OverworldOverlays.isOpenCaveTile(
            mark: .unmarked, nothingable: true, hasArmos: false,
            pastEarlyGame: true, armosClaimed: false))
        // Armos spot shows until the armos item is claimed.
        #expect(OverworldOverlays.isOpenCaveTile(
            mark: .unmarked, nothingable: false, hasArmos: true,
            pastEarlyGame: true, armosClaimed: false))
        #expect(!OverworldOverlays.isOpenCaveTile(
            mark: .unmarked, nothingable: false, hasArmos: true,
            pastEarlyGame: true, armosClaimed: true))
    }

    @Test("open-cave phase transition: wood sword cave found, or sword + candle")
    func phaseTransition() {
        #expect(!OverworldOverlays.openCavesPastEarlyGame(woodSwordCaveFound: false, swordLevel: 0, candleLevel: 0))
        #expect(OverworldOverlays.openCavesPastEarlyGame(woodSwordCaveFound: true, swordLevel: 0, candleLevel: 0))
        #expect(OverworldOverlays.openCavesPastEarlyGame(woodSwordCaveFound: false, swordLevel: 1, candleLevel: 1))
        #expect(!OverworldOverlays.openCavesPastEarlyGame(woodSwordCaveFound: false, swordLevel: 1, candleLevel: 0))
    }
}
