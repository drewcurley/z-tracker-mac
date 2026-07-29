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
        case .considerSword2, .getSword2, .considerSword3: .swordHearts
        case .completedDungeon, .foundDungeonCount, .triforceCount, .triforceAndGo: .dungeonFeedback
        case .remindUnblock: .blockers
        case .remindShortly: .haveKeyLadder
        case .doorRepairCount: .doorRepair
        case .getCoastItem: .coastItem
        case .getArmosItem: .armosItem
        case .considerBoomstickBook: .recorderPBSpotsAndBoomstickBook
        case .remindVisitHints: .haveKeyLadder
        case .overworldOverwrite: .overworldOverwrites
        case .secretsRemaining: .secrets
        }
    }

    /// The human-readable reminder text (non-HDN naming). See
    /// `displayText(hideDungeonNumbers:assignedLabels:)` for the Hidden-Dungeon-
    /// Numbers variant.
    public var displayText: String { displayText(hideDungeonNumbers: false, assignedLabels: []) }

    /// The human-readable reminder text. Ported from the reference's `SendReminder`
    /// strings. Under Hidden Dungeon Numbers, dungeon references use letters
    /// (T-112, matching the reference): a **completed** dungeon uses its *assigned*
    /// label (`GetDungeon(i).LabelChar`, or "This dungeon" when still unknown,
    /// `UI.fs:1442-1449`), while a **revisit** reminder uses the slot letter
    /// `'A'+d` (`UI.fs:1508-1512`).
    /// - Parameters:
    ///   - hideDungeonNumbers: HDN mode is on.
    ///   - assignedLabels: each slot's assigned label char (`'?'` if unknown),
    ///     slot-indexed 0–7. Only consulted under HDN for completed-dungeon text.
    public func displayText(hideDungeonNumbers: Bool, assignedLabels: [Character]) -> String {
        /// Revisit naming: HDN slot letter `'A'+d`, else the 1-based number.
        func revisitName(_ d: Int) -> String {
            hideDungeonNumbers ? String(UnicodeScalar(UInt8(65 + d))) : String(d + 1)
        }
        switch self {
        case .considerSword2:
            return "Consider getting the white sword item"
        case .getSword2:
            return "Get the white sword item"
        case .considerSword3:
            return "Consider the magical sword"
        case .completedDungeon(let i):
            guard hideDungeonNumbers else { return "Dungeon \(i + 1) is complete" }
            let label = i < assignedLabels.count ? assignedLabels[i] : "?"
            return label == "?" ? "This dungeon is complete" : "Dungeon \(label) is complete"
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
            let nums = dungeons.map(revisitName).joined(separator: ", ")
            let need = blocker.displayDescription.replacingOccurrences(of: "\n", with: " ")
            let plural = dungeons.count == 1 ? "dungeon" : "dungeons"
            return "You can revisit \(plural) \(nums) — \(need)"
        case .remindShortly(let itemId):
            switch itemId {
            case ITEMS.ladder: return "Don't forget that you have the ladder"
            case ITEMS.anyKey: return "Don't forget that you have the any key"
            case ITEMS.recorder: return "Don't forget that you have the recorder"
            case ITEMS.powerBracelet: return "Don't forget that you have the power bracelet"
            default: return "Don't forget that you have an item"
            }
        case .doorRepairCount(let found, let max):
            // "You found all N of N door repairs" once complete, else "N of N".
            return "You found \(found == max ? "all " : "")\(found) of \(max) door repairs"
        case .getCoastItem(let itemName):
            return itemName.map { "Get the \($0) off the coast" }
                ?? "Get the coast item with the ladder"
        case .getArmosItem(let itemName):
            return itemName.map { "Get the \($0) from the armos" }
                ?? "Get the armos item"
        case .considerBoomstickBook:
            return "Consider buying the boomstick book"
        case .remindVisitHints:
            return "You have the book — visit the hint NPCs"
        case .overworldOverwrite(let coordLabel, let from, let to):
            return "You changed \(coordLabel) from \(from) to \(to)"
        case .secretsRemaining(let size, let remaining):
            let name = "\(size.rawValue) secret"
            return remaining == 0 ? "No more \(name)s to find" : "One \(name) left"
        }
    }
}
