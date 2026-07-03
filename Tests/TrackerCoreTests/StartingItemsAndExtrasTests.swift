import Testing
@testable import TrackerCore

@Suite("StartingItemsAndExtras")
struct StartingItemsAndExtrasTests {
    @Test("defaults match the reference app's StartingItemsAndExtras field-for-field")
    func defaultsMatchReferenceApp() {
        let items = StartingItemsAndExtras()

        #expect(items.hdnStartingTriforcePieces == Array(repeating: false, count: 8))
        #expect(items.hasWhiteSword == false)
        #expect(items.hasMagicalSword == false)
        #expect(items.hasSilverArrow == false)
        #expect(items.hasBow == false)
        #expect(items.hasWand == false)
        #expect(items.hasRedCandle == false)
        #expect(items.hasBoomerang == false)
        #expect(items.hasMagicBoomerang == false)
        #expect(items.hasRedRing == false)
        #expect(items.hasPowerBracelet == false)
        #expect(items.hasLadder == false)
        #expect(items.hasRaft == false)
        #expect(items.hasRecorder == false)
        #expect(items.hasAnyKey == false)
        #expect(items.hasBook == false)
        #expect(items.maxHeartsDifferential == 0)
    }

    @Test("fields are independently settable")
    func fieldsAreIndependentlySettable() {
        let items = StartingItemsAndExtras()

        items.hasLadder = true
        items.maxHeartsDifferential = 2

        #expect(items.hasLadder == true)
        #expect(items.maxHeartsDifferential == 2)
        #expect(items.hasRaft == false)
        #expect(items.hasWhiteSword == false)
    }

    @Test("individual triforce pieces are independently settable")
    func triforcePiecesAreIndependentlySettable() {
        let items = StartingItemsAndExtras()

        items.hdnStartingTriforcePieces[3] = true

        #expect(items.hdnStartingTriforcePieces == [false, false, false, true, false, false, false, false])
    }

    @Test("the initializer accepts explicit non-default values")
    func initializerAcceptsExplicitValues() {
        let items = StartingItemsAndExtras(
            hasWhiteSword: true,
            hasRaft: true,
            maxHeartsDifferential: -1
        )

        #expect(items.hasWhiteSword == true)
        #expect(items.hasRaft == true)
        #expect(items.maxHeartsDifferential == -1)
        #expect(items.hasLadder == false)
    }
}
