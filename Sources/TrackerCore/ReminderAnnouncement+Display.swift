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
        }
    }

    /// The pre-rendered audio clip key for this announcement (a filename in
    /// the app's `audio/` resources, without extension), or `nil` if there's
    /// no clip (falls back to live TTS). Bounded set — see
    /// `scripts/generate-reminder-audio.sh`, which must stay in sync.
    public var audioKey: String? {
        switch self {
        case .considerSword2: "consider_sword2"
        case .considerSword3: "consider_sword3"
        case .completedDungeon(let i) where (0...8).contains(i): "dungeon_complete_\(i + 1)"
        case .foundDungeonCount(let n) where (1...9).contains(n): "located_\(n)"
        case .triforceCount(let n) where (1...8).contains(n): "triforce_\(n)"
        case .triforceAndGo(_, let summary):
            switch summary.level {
            case 103: "tag_go"
            case 102: "tag_probably"
            case 101: "tag_might"
            default: "tag_need"
            }
        case .remindUnblock(let blocker, _, _):
            switch blocker.hardCanonical {
            case .ladder: "unblock_ladder"
            case .recorder: "unblock_recorder"
            case .bowAndArrow: "unblock_bow"
            case .key: "unblock_key"
            case .bomb: "unblock_bomb"
            case .combat: "unblock_combat"
            default: nil
            }
        case .remindShortly(let itemId):
            switch itemId {
            case ITEMS.ladder: "have_ladder"
            case ITEMS.anyKey: "have_key"
            default: nil
            }
        case .completedDungeon, .foundDungeonCount, .triforceCount: nil
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
        }
    }
}
