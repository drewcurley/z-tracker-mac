/// A semantic icon attached to a reminder-log entry (T-122) — the log shows these
/// beside each entry so you can see *what* a reminder is about at a glance (e.g. the
/// ladder + coast item, or the magical sword + Level 3). The UI maps each case to a
/// concrete sprite; keeping the enum here (pure data) lets `ReminderLog` store it and
/// keeps the mapping unit-testable. Mirrors the reference's `SendReminder(..., icons)`
/// image lists (`Z1R_Avalonia/UI.fs`).
public enum ReminderIcon: Equatable, Sendable {
    case item(Int)          // an ITEMS.* id → its box sprite
    case sword(level: Int)  // 1 wood / 2 white / 3 magical
    case ring(level: Int)   // 1 blue / 2 red
    case wand
    case dungeon(Int)       // dungeon 1…9 marker
    case rightArrow
    case checkmark
    case triforce
    case doorRepair
    case secret(SecretSize)
    case bowAndArrow, bomb, key, ladder, recorder, powerBracelet, bait, rupee, book, boomBook
}

/// Resolves the icon row for a reminder, given the live values needed to make the
/// tiered/contextual ones accurate (the sword/ring the player just reached, the coast
/// item behind the ladder). Pure + testable; called at fire-time by the log.
public enum ReminderIcons {
    public static func icons(for a: ReminderAnnouncement,
                             swordLevel: Int = 0,
                             ringLevel: Int = 0,
                             coastItemId: Int? = nil) -> [ReminderIcon] {
        switch a {
        case .considerSword2: return [.rightArrow, .sword(level: 2)]
        case .considerSword3: return [.rightArrow, .sword(level: 3)]
        case .completedDungeon(let i): return [.dungeon(i + 1), .checkmark]
        case .foundDungeonCount(let n): return n == 9 ? [.checkmark] : []
        case .triforceCount(let n): return n == 8 ? [.triforce, .checkmark] : [.triforce]
        case .triforceAndGo: return [.triforce]
        case .remindUnblock(let blocker, let dungeons, let combatDetails):
            var icons: [ReminderIcon] = []
            if blocker.hardCanonical == .combat {
                for d in combatDetails {
                    switch d {
                    case .betterSword: icons.append(.sword(level: max(1, swordLevel)))
                    case .betterArmor: icons.append(.ring(level: max(1, ringLevel)))
                    case .wand: icons.append(.wand)
                    }
                }
            } else {
                icons.append(contentsOf: blockerIcons(blocker))
            }
            icons.append(.rightArrow)
            icons.append(contentsOf: dungeons.map { .dungeon($0 + 1) })
            return icons
        case .remindShortly(let itemId): return [.item(itemId)]
        case .doorRepairCount: return [.doorRepair]
        case .getCoastItem:
            var icons: [ReminderIcon] = [.ladder, .rightArrow]
            if let id = coastItemId, id >= 0 { icons.append(.item(id)) }
            return icons
        case .considerBoomstickBook: return [.rightArrow, .boomBook]
        case .remindVisitHints: return [.book]
        case .overworldOverwrite: return []
        case .secretsRemaining(let size, _): return [.secret(size)]
        }
    }

    /// A non-combat blocker's own icon(s).
    private static func blockerIcons(_ b: DungeonBlocker) -> [ReminderIcon] {
        switch b.hardCanonical {
        case .bowAndArrow: return [.bowAndArrow]
        case .recorder: return [.recorder]
        case .ladder: return [.ladder]
        case .bait: return [.bait]
        case .key: return [.key]
        case .bomb: return [.bomb]
        case .money: return [.rupee]
        default: return []
        }
    }
}
