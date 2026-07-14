import Foundation
import Observation

/// The UI-agnostic tracker state, mirroring the reference app's
/// UI-framework-agnostic F# core (see docs/architecture.md § 2).
///
/// Covers the startup screen's core toggles (docs/domain.md § 4.1, T-003).
/// The full state (dungeon items, overworld tiles, blockers, timeline, the
/// embedded settings panel — see docs/domain.md) is out of scope here and
/// lands incrementally in later feature tasks, each updating
/// docs/contracts.md as it goes.
@Observable
public final class TrackerModel {
    public private(set) var quest: OverworldQuest?

    /// Pre-fills each dungeon's first item box with a Heart Container
    /// (docs/domain.md § 4.1). Off by default, matching the reference app.
    public var heartShuffle: Bool

    /// Hides which numbered dungeon is which, changing several UI behaviors
    /// elsewhere (docs/domain.md § 4.1–4.2). Off by default.
    public var hideDungeonNumbers: Bool

    /// The overworld map's tile-mark state (docs/domain.md § 4.5, T-006).
    /// Owned here since `TrackerModel` is documented as the eventual home
    /// for all main-tracker-view state, not a separate parallel container.
    public let overworldGrid: OverworldGrid

    /// Seed-configured starting inventory (docs/domain.md § 6, T-012 —
    /// foundation piece of the player-state layer; `PlayerComputedStateSummary`
    /// derivation that actually consumes this lands in T-014).
    public let startingItemsAndExtras: StartingItemsAndExtras

    /// Runtime-acquired player progress not tied to a dungeon-box location
    /// (docs/domain.md § 6, T-012).
    public let playerProgress: PlayerProgressAndTakeAnyHearts

    /// The nine dungeons' item/completion/triforce state plus the three
    /// standalone boxes (docs/domain.md § 6, T-013). DEFAULT mode only —
    /// Hidden Dungeon Numbers is T-016. `PlayerComputedStateSummary`, the
    /// glue that turns these boxes into `HaveLadder`/`SwordLevel`/etc., is
    /// T-014.
    public let dungeonTracker: DungeonTrackerInstance

    /// Seed flag: in some seed variants the White-Sword and Magical-Sword
    /// item slots are Bomb-Upgrade slots instead, so they don't raise the
    /// player's sword level. The one seed-option flag
    /// `PlayerComputedStateSummary.compute` branches on (T-014;
    /// `TrackerModel.fs:170-176`, read at `:911`/`:924`). Its sibling flags
    /// `IsCurrentlyBook`/`IsBookAnAtlas` gate `PlayerHasTheBook` /
    /// `PlayerCanSeeMapOfThisDungeon`, which are deferred with their own
    /// consumers — so they're added when those land, not here.
    public var isWSMSReplacedByBU: Bool

    /// Seed flag: whether item slot 0 is the Book (`true`, default) or the
    /// Magic Shield (`false`) — in boomstick seeds the book is a shield in the
    /// item pool (`IsCurrentlyBook`, `TrackerModel.fs:156-168`;
    /// `CustomComboBoxes.fs:46`). Consumed immediately by the item-icon display
    /// (book vs shield sprite); the deferred `PlayerHasTheBook` logic helper is
    /// separate and lands with its own consumer.
    public var isCurrentlyBook: Bool

    /// Seed flag: whether the overworld is **mirrored** East↔West (T-047).
    /// Ported from `TrackerModel.MirrorOverworld` (`TrackerModel.fs:31`,
    /// options-menu "Mirror overworld — Flip the overworld map East<->West").
    /// Flips the map display (and feeds the mirrored screen-scroll routing edge
    /// `MapStateSummary` already reads). Off by default.
    public var mirrorOverworld: Bool

    /// Per-target location hints (T-039) — which overworld region each dungeon /
    /// sword cave was hinted to be in. 11 slots (`HintTarget`: dungeons 1–9 →
    /// 0–8, white sword → 9, magical sword → 10). Map *knowledge*, so a
    /// groundhog reset keeps these.
    public var levelHints: [HintZone]

    /// Per-dungeon "why I left" blocker annotations (docs/domain.md § 6,
    /// T-017). Reads player state for staleness but doesn't feed back into
    /// it. The blocker-setting UI is a later task (uncharacterized).
    public let dungeonBlockers: DungeonBlockersContainer

    /// The edge-triggered reminder/announcement engine (T-018.2). Owned here
    /// so its transition state survives view redraws; driven by the app's
    /// poll loop via `pollReminders()` (T-018.3).
    public let reminderEngine: ReminderEngine

    public init(
        quest: OverworldQuest? = nil,
        heartShuffle: Bool = false,
        hideDungeonNumbers: Bool = false,
        overworldGrid: OverworldGrid = OverworldGrid(),
        startingItemsAndExtras: StartingItemsAndExtras = StartingItemsAndExtras(),
        playerProgress: PlayerProgressAndTakeAnyHearts = PlayerProgressAndTakeAnyHearts(),
        dungeonTracker: DungeonTrackerInstance = DungeonTrackerInstance(),
        isWSMSReplacedByBU: Bool = false,
        isCurrentlyBook: Bool = true,
        mirrorOverworld: Bool = false,
        levelHints: [HintZone] = Array(repeating: .unknown, count: HintTarget.count),
        dungeonBlockers: DungeonBlockersContainer = DungeonBlockersContainer(),
        reminderEngine: ReminderEngine = ReminderEngine()
    ) {
        self.quest = quest
        self.heartShuffle = heartShuffle
        self.hideDungeonNumbers = hideDungeonNumbers
        self.overworldGrid = overworldGrid
        self.startingItemsAndExtras = startingItemsAndExtras
        self.playerProgress = playerProgress
        self.dungeonTracker = dungeonTracker
        self.isWSMSReplacedByBU = isWSMSReplacedByBU
        self.isCurrentlyBook = isCurrentlyBook
        self.mirrorOverworld = mirrorOverworld
        self.levelHints = levelHints
        self.dungeonBlockers = dungeonBlockers
        self.reminderEngine = reminderEngine
    }

    /// Polls the reminder engine with the model's current derived state,
    /// returning the announcements to fire this tick (T-018.3). The app calls
    /// this on a ~1 Hz timer. The map-state's routing flags don't affect any
    /// reminder input, so they're passed as `false`.
    public func pollReminders() -> [ReminderAnnouncement] {
        let instance = OverworldInstance(quest: quest ?? .first)
        let mapState = MapStateSummary.compute(
            grid: overworldGrid, instance: instance, dungeonTracker: dungeonTracker,
            playerState: playerComputedStateSummary, progress: playerProgress,
            drawRoutes: false, routesCanScreenScroll: false, mirrorOverworld: false)
        let tag = TriforceAndGoSummary.compute(
            playerState: playerComputedStateSummary, dungeonTracker: dungeonTracker,
            mapState: mapState, progress: playerProgress, grid: overworldGrid, instance: instance)
        return reminderEngine.poll(
            playerState: playerComputedStateSummary, mapState: mapState,
            dungeonTracker: dungeonTracker, blockers: dungeonBlockers,
            progress: playerProgress, startingItems: startingItemsAndExtras, tagSummary: tag)
    }

    /// The derived player state (item possession, levels, hearts) read by
    /// routing/GYR and, later, the item tracker and reminders. Recomputed on
    /// demand from `startingItemsAndExtras`, `playerProgress`, and
    /// `dungeonTracker` (T-014). Because those inputs are all `@Observable`,
    /// reading this inside a SwiftUI view re-derives it whenever any of them
    /// changes.
    public var playerComputedStateSummary: PlayerComputedStateSummary {
        PlayerComputedStateSummary.compute(
            dungeonTracker: dungeonTracker,
            startingItems: startingItemsAndExtras,
            progress: playerProgress,
            isWSMSReplacedByBU: isWSMSReplacedByBU
        )
    }

    /// "Groundhog / routers / 4+4" reset — **remove inventory but preserve
    /// maps** (`OverworldItemGridUI.fs:678-717` reset button;
    /// `ResetForGroundhogOrRoutersOrFourPlusFourEtc`). For replaying the same
    /// seed from scratch while keeping everything you've learned:
    ///
    /// **Reset** (run progress): dungeon triforces; every non-`.skipped` box's
    /// *possession* (`.no`) while keeping its item *identity* and skipped marks;
    /// all `playerProgress` (progress items + take-any hearts — the "used"
    /// state); the reminder engine (so announcements fire again).
    ///
    /// **Kept** (knowledge): the overworld tile marks, the box item identities,
    /// dungeon labels, blockers (`:709` keeps them for 4+4 keyblock), and the
    /// seed's starting items (`startingItemsAndExtras` is not reset — same seed).
    ///
    /// The reference makes a hard save first; this app has no save/load yet, so
    /// callers should confirm before invoking (the operation is destructive).
    public func resetForGroundhogOrRouters() {
        // Remove triforces (dungeons 1–8; dungeon 9 has none).
        for i in 0..<8 where dungeonTracker.dungeon(i).playerHasTriforce {
            dungeonTracker.dungeon(i).toggleTriforce()
        }
        // Red-ify obtained items: keep the item identity + any SKIPPED marks,
        // reset "have it" → NO.
        for box in dungeonTracker.allBoxes() where box.playerHas != .skipped {
            box.setPlayerHas(.no)
        }
        // Clear progress items + take-any hearts (their "used" state).
        playerProgress.resetAll()
        // Let reminders announce again.
        reminderEngine.resetForGroundhogOrRouters()
    }

    /// Selects the overworld quest for this run. Mirrors the reference app's
    /// startup-screen quest buttons (docs/domain.md § 4.1) — once a quest is
    /// chosen, the reference app moves from the startup screen to the main
    /// tracker view; wiring that transition is `StartupView`'s concern, not
    /// this model's (the model just records the choice).
    public func selectQuest(_ quest: OverworldQuest) {
        self.quest = quest
        // At session start, seed the dungeon floor-item hearts per Heart
        // Shuffle (the reference's `makeAll` does this once the quest is
        // chosen — `UI.fs:142-144`).
        dungeonTracker.applyFloorItemHearts(heartShuffle: heartShuffle)
    }
}
