import Testing
@testable import TrackerCore

@Suite("ReminderAnnouncement display mapping")
struct ReminderAnnouncementDisplayTests {
    @Test("each announcement maps to the reference's reminder category")
    func categories() {
        #expect(ReminderAnnouncement.considerSword2.category == .swordHearts)
        #expect(ReminderAnnouncement.considerSword3.category == .swordHearts)
        #expect(ReminderAnnouncement.completedDungeon(0).category == .dungeonFeedback)
        #expect(ReminderAnnouncement.foundDungeonCount(3).category == .dungeonFeedback)
        #expect(ReminderAnnouncement.triforceCount(2).category == .dungeonFeedback)
        let tag = TriforceAndGoSummary(level: 103, haveBow: true, haveSilvers: true,
            silversKnownToBeInLevel9: false, haveLadder: true, haveRecorder: true, missingDungeonCount: 0)
        #expect(ReminderAnnouncement.triforceAndGo(triforces: 8, summary: tag).category == .dungeonFeedback)
        #expect(ReminderAnnouncement.remindUnblock(blocker: .ladder, dungeons: [1], combatDetails: []).category == .blockers)
        #expect(ReminderAnnouncement.remindShortly(itemId: ITEMS.ladder).category == .haveKeyLadder)
    }

    @Test("display text matches the reference SendReminder strings")
    func text() {
        #expect(ReminderAnnouncement.considerSword2.displayText == "Consider getting the white sword item")
        #expect(ReminderAnnouncement.considerSword3.displayText == "Consider the magical sword")
        #expect(ReminderAnnouncement.completedDungeon(0).displayText == "Dungeon 1 is complete")
        #expect(ReminderAnnouncement.completedDungeon(7).displayText == "Dungeon 8 is complete")
        #expect(ReminderAnnouncement.foundDungeonCount(1).displayText == "You have located one dungeon")
        #expect(ReminderAnnouncement.foundDungeonCount(9).displayText == "Congratulations, you have located all 9 dungeons")
        #expect(ReminderAnnouncement.foundDungeonCount(4).displayText == "You have located 4 dungeons")
        #expect(ReminderAnnouncement.triforceCount(1).displayText == "You now have one triforce")
        #expect(ReminderAnnouncement.triforceCount(3).displayText == "You now have 3 triforces")
        #expect(ReminderAnnouncement.remindShortly(itemId: ITEMS.ladder).displayText == "Don't forget that you have the ladder")
        #expect(ReminderAnnouncement.remindShortly(itemId: ITEMS.anyKey).displayText == "Don't forget that you have the any key")
    }

    @Test("triforce-and-go text tracks the summary level")
    func tagText() {
        func tag(_ level: Int) -> ReminderAnnouncement {
            .triforceAndGo(triforces: 8, summary: TriforceAndGoSummary(
                level: level, haveBow: true, haveSilvers: true, silversKnownToBeInLevel9: false,
                haveLadder: true, haveRecorder: true, missingDungeonCount: 0))
        }
        #expect(tag(103).displayText == "You are triforce and go")
        #expect(tag(102).displayText == "You are probably triforce and go")
        #expect(tag(101).displayText == "You might be triforce and go")
        #expect(tag(50).displayText == "You need something to be triforce and go")
    }

    @Test("door-repair count text: N of N, and 'all' at the max")
    func doorRepairText() {
        #expect(ReminderAnnouncement.doorRepairCount(found: 1, max: 9).displayText
                == "You found 1 of 9 door repairs")
        #expect(ReminderAnnouncement.doorRepairCount(found: 9, max: 9).displayText
                == "You found all 9 of 9 door repairs")
        #expect(ReminderAnnouncement.doorRepairCount(found: 3, max: 9).category == .doorRepair)
    }

    @Test("periodic reminder text + categories (T-089)")
    func periodicText() {
        #expect(ReminderAnnouncement.getCoastItem(itemName: nil).displayText
                == "Get the coast item with the ladder")
        #expect(ReminderAnnouncement.getCoastItem(itemName: "white sword").displayText
                == "Get the white sword off the coast")
        #expect(ReminderAnnouncement.getCoastItem(itemName: nil).category == .coastItem)
        #expect(ReminderAnnouncement.recorderSpots(1).displayText == "There is one recorder spot")
        #expect(ReminderAnnouncement.recorderSpots(4).displayText == "There are 4 recorder spots")
        #expect(ReminderAnnouncement.powerBraceletSpots(1).displayText == "There is one power bracelet spot")
        #expect(ReminderAnnouncement.powerBraceletSpots(3).displayText == "There are 3 power bracelet spots")
        #expect(ReminderAnnouncement.considerBoomstickBook.displayText == "Consider buying the boomstick book")
        #expect(ReminderAnnouncement.recorderSpots(2).category == .recorderPBSpotsAndBoomstickBook)
    }

    @Test("unblock text lists the dungeon numbers and the need")
    func unblockText() {
        let one = ReminderAnnouncement.remindUnblock(blocker: .ladder, dungeons: [1], combatDetails: [])
        #expect(one.displayText == "You can revisit dungeon 2 — Need ladder")
        let many = ReminderAnnouncement.remindUnblock(blocker: .bomb, dungeons: [1, 4], combatDetails: [])
        #expect(many.displayText == "You can revisit dungeons 2, 5 — Need bombs")
    }
}

@Suite("TrackerModel.pollReminders integration")
struct PollRemindersTests {
    @Test("polling reflects real state transitions through the owned engine")
    func pollReflectsState() {
        let model = TrackerModel(quest: .first)
        // Fresh model, empty state -> nothing.
        #expect(model.pollReminders().isEmpty)

        // Give the player the ladder -> item nudge fires once.
        model.startingItemsAndExtras.hasLadder = true
        let first = model.pollReminders()
        #expect(first.contains(.remindShortly(itemId: ITEMS.ladder)))
        // Second poll -> already reminded.
        #expect(!model.pollReminders().contains(.remindShortly(itemId: ITEMS.ladder)))
    }
}
