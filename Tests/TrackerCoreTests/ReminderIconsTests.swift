import Testing
@testable import TrackerCore

@Suite("Reminder icons (T-122)")
struct ReminderIconsTests {
    @Test("coast-item reminder shows ladder → the coast item")
    func coastItemIcons() {
        // e.g. the coast item is the red candle: ladder → red candle.
        let icons = ReminderIcons.icons(for: .getCoastItem(itemName: "red candle"),
                                        coastItemId: ITEMS.redCandle)
        #expect(icons == [.ladder, .rightArrow, .item(ITEMS.redCandle)])
        // Unknown coast item: just ladder → (no item).
        #expect(ReminderIcons.icons(for: .getCoastItem(itemName: nil)) == [.ladder, .rightArrow])
    }

    @Test("combat unblock shows the sword you just got → the dungeon(s)")
    func combatUnblockIcons() {
        // Got the magical sword (level 3); dungeon 3 (index 2) was combat-blocked.
        let icons = ReminderIcons.icons(
            for: .remindUnblock(blocker: .combat, dungeons: [2], combatDetails: [.betterSword]),
            swordLevel: 3)
        #expect(icons == [.sword(level: 3), .rightArrow, .dungeon(3)])

        // Better armor uses the ring level; multiple dungeons list all.
        let armor = ReminderIcons.icons(
            for: .remindUnblock(blocker: .combat, dungeons: [0, 4], combatDetails: [.betterArmor]),
            ringLevel: 2)
        #expect(armor == [.ring(level: 2), .rightArrow, .dungeon(1), .dungeon(5)])
    }

    @Test("non-combat unblock shows the blocker item → the dungeon(s)")
    func nonCombatUnblockIcons() {
        #expect(ReminderIcons.icons(for: .remindUnblock(blocker: .ladder, dungeons: [2], combatDetails: []))
                == [.ladder, .rightArrow, .dungeon(3)])
        #expect(ReminderIcons.icons(for: .remindUnblock(blocker: .bomb, dungeons: [7], combatDetails: []))
                == [.bomb, .rightArrow, .dungeon(8)])
    }

    @Test("other reminders carry sensible icons")
    func miscIcons() {
        #expect(ReminderIcons.icons(for: .considerSword3) == [.rightArrow, .sword(level: 3)])
        #expect(ReminderIcons.icons(for: .completedDungeon(0)) == [.dungeon(1), .checkmark])
        #expect(ReminderIcons.icons(for: .remindShortly(itemId: ITEMS.ladder)) == [.item(ITEMS.ladder)])
        #expect(ReminderIcons.icons(for: .secretsRemaining(size: .large, remaining: 1)) == [.secret(.large)])
        #expect(ReminderIcons.icons(for: .considerBoomstickBook) == [.rightArrow, .boomBook])
    }
}
