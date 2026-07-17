import Testing
@testable import TrackerCore

@Suite("TrackerOptions")
struct TrackerOptionsTests {
    @Test("defaults match the reference app's TrackerModelOptions.fs field-for-field")
    func defaultsMatchReferenceApp() {
        let options = TrackerOptions()

        // Overworld settings
        #expect(options.drawRoutes == true)
        #expect(options.showScreenScrolls == false)
        #expect(options.highlightNearby == true)
        #expect(options.showMagnifier == true)
        #expect(options.shopsBeforeDungeons == true)

        // Dungeon settings
        #expect(options.boardInsteadOfLevel == false)
        #expect(options.showBasementInfo == true)
        #expect(options.doDoorInference == false)
        #expect(options.bookForHelpfulHints == false)
        #expect(options.leftDragAutoInverts == false)
        #expect(options.defaultToNonDescript == false)
        #expect(options.dungeonSunglasses == true)

        // "More settings…" (overworld tile hiding)
        #expect(options.hideNoLongerRelevantShopItems == false)
        #expect(options.alwaysHideMeatShops == false)

        // Reminders
        #expect(options.reminderVolume == 30)
        #expect(options.preferredVoiceIdentifier == nil)

        // Other
        #expect(options.animateTileChanges == true)
        #expect(options.animateShopHighlights == true)
        #expect(options.saveOnCompletion == false)
        #expect(options.snoopSeedAndFlags == false)
        #expect(options.displaySeedAndFlags == true)
        #expect(options.listenForSpeech == false)
        #expect(options.confirmationSound == true)
        #expect(options.showBroadcastWindow == false)
        #expect(options.broadcastWindowSize == .full)
        #expect(options.broadcastWindowIncludesOverworldMagnifier == false)
        #expect(options.showMouseMagnifierWindow == false)
        #expect(options.hideTimer == false)
        // Beyond the reference (T-109): warn on quit while timer runs, default on.
        #expect(options.warnOnCloseWhileTimerRunning == true)
    }

    @Test(
        "every overworld hideable tile kind defaults to false (nothing hidden)",
        arguments: OverworldHiddenTileKind.allCases
    )
    func hiddenOverworldTileDefaults(kind: OverworldHiddenTileKind) {
        let options = TrackerOptions()
        #expect(options.hiddenOverworldTiles[kind] == false)
    }

    @Test("hiddenOverworldTiles has exactly the 12 confirmed kinds")
    func hiddenOverworldTilesCount() {
        let options = TrackerOptions()
        #expect(options.hiddenOverworldTiles.count == 12)
        #expect(OverworldHiddenTileKind.allCases.count == 12)
    }

    @Test("alwaysHideMeatShops is settable independently of hideNoLongerRelevantShopItems")
    func alwaysHideMeatShopsIndependent() {
        let options = TrackerOptions()
        options.alwaysHideMeatShops = true
        #expect(options.alwaysHideMeatShops == true)
        #expect(options.hideNoLongerRelevantShopItems == false)
    }

    @Test(
        "every reminder category defaults to true except recorderPBSpotsAndBoomstickBook",
        arguments: ReminderCategory.allCases
    )
    func reminderDefaults(category: ReminderCategory) {
        let options = TrackerOptions()
        let expected = category != .recorderPBSpotsAndBoomstickBook
        #expect(options.voiceReminders[category] == expected)
        #expect(options.visualReminders[category] == expected)
    }

    @Test("disableAllReminders zeroes every voice and visual toggle")
    func disableAllReminders() {
        let options = TrackerOptions()
        options.disableAllReminders()
        for category in ReminderCategory.allCases {
            #expect(options.voiceReminders[category] == false)
            #expect(options.visualReminders[category] == false)
        }
    }

    @Test("disableAllReminders does not affect unrelated settings")
    func disableAllReminderScoping() {
        let options = TrackerOptions()
        options.drawRoutes = false
        options.reminderVolume = 75
        options.disableAllReminders()
        #expect(options.drawRoutes == false)
        #expect(options.reminderVolume == 75)
    }

    @Test("toggles are independently settable")
    func togglesAreIndependent() {
        let options = TrackerOptions()
        options.drawRoutes = false
        options.showBroadcastWindow = true
        options.broadcastWindowSize = .oneThird
        #expect(options.drawRoutes == false)
        #expect(options.showBroadcastWindow == true)
        #expect(options.broadcastWindowSize == .oneThird)
        #expect(options.highlightNearby == true) // unaffected
    }

    @Test("BroadcastWindowSize raw values match the reference app's clamp range (1...3)")
    func broadcastWindowSizeRawValues() {
        #expect(BroadcastWindowSize.oneThird.rawValue == 1)
        #expect(BroadcastWindowSize.twoThirds.rawValue == 2)
        #expect(BroadcastWindowSize.full.rawValue == 3)
    }

    @Test("ReminderCategory display names match the reference app's DisplayName exactly")
    func reminderCategoryDisplayNames() {
        #expect(ReminderCategory.dungeonFeedback.displayName == "Dungeon feedback")
        #expect(ReminderCategory.swordHearts.displayName == "Sword hearts")
        #expect(ReminderCategory.coastItem.displayName == "Coast Item")
        #expect(ReminderCategory.recorderPBSpotsAndBoomstickBook.displayName == "Recorder/PB/Boomstick")
        #expect(ReminderCategory.haveKeyLadder.displayName == "Have magic key/ladder")
        #expect(ReminderCategory.blockers.displayName == "Blockers")
        #expect(ReminderCategory.doorRepair.displayName == "Door Repair Count")
        #expect(ReminderCategory.overworldOverwrites.displayName == "Overworld overwrites")
    }
}
