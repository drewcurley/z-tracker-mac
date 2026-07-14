import Testing
@testable import TrackerCore

@Suite("PlayerProgressAndTakeAnyHearts")
struct PlayerProgressAndTakeAnyHeartsTests {
    @Test("defaults match the reference app's PlayerProgressAndTakeAnyHearts field-for-field")
    func defaultsMatchReferenceApp() {
        let progress = PlayerProgressAndTakeAnyHearts()

        #expect(progress.takeAnyHearts == Array(repeating: .untaken, count: 4))
        #expect(progress.hasBoomBook == false)
        #expect(progress.hasWoodSword == false)
        #expect(progress.hasWoodArrow == false)
        #expect(progress.hasBlueRing == false)
        #expect(progress.hasBlueCandle == false)
        #expect(progress.hasMagicalSword == false)
        #expect(progress.hasDefeatedGanon == false)
        #expect(progress.hasRescuedZelda == false)
        #expect(progress.hasBombs == false)
    }

    @Test("fields are independently settable")
    func fieldsAreIndependentlySettable() {
        let progress = PlayerProgressAndTakeAnyHearts()

        progress.hasBombs = true
        progress.takeAnyHearts[2] = .takenPotion

        #expect(progress.hasBombs == true)
        #expect(progress.takeAnyHearts == [.untaken, .untaken, .takenPotion, .untaken])
        #expect(progress.hasWoodSword == false)
    }

    @Test("resetAll zeroes every field, matching ResetAll()")
    func resetAllZeroesEverything() {
        let progress = PlayerProgressAndTakeAnyHearts(
            takeAnyHearts: [.takenHeart, .takenPotion, .takenHeart, .untaken],
            hasBoomBook: true,
            hasWoodSword: true,
            hasWoodArrow: true,
            hasBlueRing: true,
            hasBlueCandle: true,
            hasMagicalSword: true,
            hasDefeatedGanon: true,
            hasRescuedZelda: true,
            hasBombs: true
        )

        progress.resetAll()

        #expect(progress.takeAnyHearts == Array(repeating: .untaken, count: 4))
        #expect(progress.hasBoomBook == false)
        #expect(progress.hasWoodSword == false)
        #expect(progress.hasWoodArrow == false)
        #expect(progress.hasBlueRing == false)
        #expect(progress.hasBlueCandle == false)
        #expect(progress.hasMagicalSword == false)
        #expect(progress.hasDefeatedGanon == false)
        #expect(progress.hasRescuedZelda == false)
        #expect(progress.hasBombs == false)
    }

    @Test("TakeAnyHeartState raw values: reference 0/1/2 preserved, candle added at 3")
    func takeAnyHeartStateRawValues() {
        #expect(TakeAnyHeartState.untaken.rawValue == 0)
        #expect(TakeAnyHeartState.takenHeart.rawValue == 1)
        // The reference's combined potion/candle (2) becomes potion; candle is
        // the new distinct state (3) — T-031, back-compatible with old saves.
        #expect(TakeAnyHeartState.takenPotion.rawValue == 2)
        #expect(TakeAnyHeartState.takenCandle.rawValue == 3)
        #expect(TakeAnyHeartState.allCases.count == 4)
    }
}
