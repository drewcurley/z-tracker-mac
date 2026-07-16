/// Presentation of a `ReminderAnnouncement` — its reminder category (which
/// per-category Voice/Visual toggle gates it) and its spoken/shown text.
/// Ported from the `SendReminder(category, text, …)` call sites in the
/// reference's `ITrackerEvents` implementation
/// (`Zelda1RandoTools/Z1R_Tracker/Z1R_Avalonia/UI.fs:1399-1615`).
extension ReminderAnnouncement {
    /// The reminder category this announcement belongs to. The player's
    /// `voiceReminders`/`visualReminders[category]` toggles decide whether it
    /// is spoken/shown.
    public var category: ReminderCategory {
        switch self {
        case .considerSword2, .considerSword3: .swordHearts
        case .completedDungeon, .foundDungeonCount, .triforceCount, .triforceAndGo: .dungeonFeedback
        case .remindUnblock: .blockers
        case .remindShortly: .haveKeyLadder
        case .doorRepairCount: .doorRepair
        case .getCoastItem: .coastItem
        case .recorderSpots, .powerBraceletSpots, .considerBoomstickBook: .recorderPBSpotsAndBoomstickBook
        case .remindVisitHints: .haveKeyLadder
        }
    }

    /// The human-readable reminder text. Ported from the reference's
    /// `SendReminder` strings. (The Hidden-Dungeon-Numbers lettered variant
    /// of "Dungeon N is complete" is a later refinement — this uses the
    /// dungeon number, correct in the common non-HDN case.)
    public var displayText: String {
        switch self {
        case .considerSword2:
            return "Consider getting the white sword item"
        case .considerSword3:
            return "Consider the magical sword"
        case .completedDungeon(let i):
            return "Dungeon \(i + 1) is complete"
        case .foundDungeonCount(let n):
            switch n {
            case 1: return "You have located one dungeon"
            case 9: return "Congratulations, you have located all 9 dungeons"
            default: return "You have located \(n) dungeons"
            }
        case .triforceCount(let n):
            return n == 1 ? "You now have one triforce" : "You now have \(n) triforces"
        case .triforceAndGo(_, let summary):
            switch summary.level {
            case 103: return "You are triforce and go"
            case 102: return "You are probably triforce and go"
            case 101: return "You might be triforce and go"
            default: return "You need something to be triforce and go"
            }
        case .remindUnblock(let blocker, let dungeons, _):
            let nums = dungeons.map { String($0 + 1) }.joined(separator: ", ")
            let need = blocker.displayDescription.replacingOccurrences(of: "\n", with: " ")
            let plural = dungeons.count == 1 ? "dungeon" : "dungeons"
            return "You can revisit \(plural) \(nums) — \(need)"
        case .remindShortly(let itemId):
            switch itemId {
            case ITEMS.ladder: return "Don't forget that you have the ladder"
            case ITEMS.anyKey: return "Don't forget that you have the any key"
            default: return "Don't forget that you have an item"
            }
        case .doorRepairCount(let found, let max):
            // "You found all N of N door repairs" once complete, else "N of N".
            return "You found \(found == max ? "all " : "")\(found) of \(max) door repairs"
        case .getCoastItem(let itemName):
            return itemName.map { "Get the \($0) off the coast" }
                ?? "Get the coast item with the ladder"
        case .recorderSpots(let n):
            return n == 1 ? "There is one recorder spot" : "There are \(n) recorder spots"
        case .powerBraceletSpots(let n):
            return n == 1 ? "There is one power bracelet spot" : "There are \(n) power bracelet spots"
        case .considerBoomstickBook:
            return "Consider buying the boomstick book"
        case .remindVisitHints:
            return "You have the book — visit the hint NPCs"
        }
    }
}
