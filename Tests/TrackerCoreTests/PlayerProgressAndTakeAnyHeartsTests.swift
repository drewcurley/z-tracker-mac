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

    @Test("recordTakeAny fills the next unclaimed slot; no-op on untaken or when full (T-057)")
    func recordTakeAny() {
        let p = PlayerProgressAndTakeAnyHearts()
        // Untaken is a no-op.
        #expect(p.recordTakeAny(.untaken) == nil)
        #expect(p.takeAnyHearts.allSatisfy { $0 == .untaken })

        // Each claimed item fills the next slot in order.
        #expect(p.recordTakeAny(.takenPotion) == 0)
        #expect(p.recordTakeAny(.takenHeart) == 1)
        #expect(p.takeAnyHearts == [.takenPotion, .takenHeart, .untaken, .untaken])

        // Fill the rest, then a further record is a no-op (all 4 taken).
        p.recordTakeAny(.takenCandle)
        p.recordTakeAny(.takenHeart)
        #expect(p.takeAnyHearts == [.takenPotion, .takenHeart, .takenCandle, .takenHeart])
        #expect(p.recordTakeAny(.takenPotion) == nil)
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
