import Foundation
import Observation

/// The 8 reminder categories (docs/domain.md § 4.10), verified directly
/// against `Zelda1RandoTools/Z1R_Tracker/Z1R_Tracker/TrackerModel.fs:6-15`
/// (`ReminderCategory`), not re-derived from an earlier, undercounted draft.
/// A 9th case in the source, `Asterisk` ("Error beeps"), is not confirmed to
/// be a user-facing settings-panel toggle and is deliberately omitted here —
/// see `docs/domain.md` § 4.10 UNKNOWN note.
public enum ReminderCategory: String, Codable, CaseIterable, Sendable {
    case dungeonFeedback
    case swordHearts
    case coastItem
    case recorderPBSpotsAndBoomstickBook
    case haveKeyLadder
    case blockers
    case doorRepair
    case overworldOverwrites
    /// Secret-count reminders (T-105, beyond the reference) — one-left / none-left
    /// per money-secret size, so you don't over-mark.
    case secrets

    /// Matches the reference app's own `DisplayName` exactly
    /// (`TrackerModel.fs:16-26`); `secrets` is this project's addition.
    public var displayName: String {
        switch self {
        case .dungeonFeedback: "Dungeon feedback"
        case .swordHearts: "Sword hearts"
        case .coastItem: "Coast Item"
        case .recorderPBSpotsAndBoomstickBook: "Recorder/PB/Boomstick"
        case .haveKeyLadder: "Have magic key/ladder"
        case .blockers: "Blockers"
        case .doorRepair: "Door Repair Count"
        case .overworldOverwrites: "Overworld overwrites"
        case .secrets: "Secret counts"
        }
    }
}

/// The 12 overworld tile kinds the "More settings…" popup can hide
/// (`TrackerModel.fs`'s `MapSquareChoiceDomainHelper.TilesThatSupportHidingOverworldMarks`,
/// backed by `TrackerModelOptions.OverworldTilesToHide`, T-005/T-007). Case
/// order matches that source array exactly (T-007 — corrected from an
/// earlier draft's alphabetical-ish guess), so `allCases` iterates in the
/// same order the reference app's "More settings…" popup lays them out in.
/// Display names are straightforward derivations of the confirmed field
/// names — the reference app's exact on-screen tile labels come from a
/// separate lookup (`TrackerModel.dummyOverworldTiles`) not transcribed
/// here; revisit if a mismatch is found.
public enum OverworldHiddenTileKind: String, Codable, CaseIterable, Sendable {
    case sword3, sword2, sword1
    case moneyMakingGame
    case largeSecret, mediumSecret, smallSecret
    case doorRepair, theLetter, armos, hintShop, takeAny

    public var displayName: String {
        switch self {
        case .sword1: "Sword cave 1"
        case .sword2: "Sword cave 2"
        case .sword3: "Sword cave 3"
        case .largeSecret: "Large secret"
        case .mediumSecret: "Medium secret"
        case .smallSecret: "Small secret"
        case .doorRepair: "Door repair"
        case .moneyMakingGame: "Money making game"
        case .theLetter: "The letter"
        case .armos: "Armos"
        case .hintShop: "Hint shop"
        case .takeAny: "Take any"
        }
    }
}

/// The startup screen's embedded settings panel (docs/domain.md § 4.1,
/// T-004/T-005) — the "Overworld settings" / "Dungeon settings" /
/// "Reminders" / "Other" columns, confirmed by direct screenshot of the
/// running reference app *and* by reading `OptionsMenu.fs` directly (the
/// single WPF component shared by both the startup screen and the main
/// window's "Options…" button — resolving what a partial screenshot alone
/// could not). Two fields that exist in `TrackerModelOptions.fs` are
/// confirmed **excluded** from this panel, not just unconfirmed:
/// `RequirePTTForSpeech` is dead code in the reference app itself (its
/// checkbox is commented out — "not (yet) a fully supported feature, so
/// don't publish it on the options menu", `OptionsMenu.fs:400-419`), and
/// `UseBlurEffects` does not appear anywhere in `OptionsMenu.fs` — it's
/// controlled elsewhere in the reference app, not this component.
@Observable
public final class TrackerOptions {
    // MARK: Overworld settings (TrackerModelOptions.fs Overworld module)

    /// `Overworld.DrawRoutes`, default `true`.
    public var drawRoutes: Bool
    /// `Overworld.RoutesCanScreenScroll`, default `false`.
    public var showScreenScrolls: Bool
    /// `Overworld.HighlightNearby`, default `true`.
    public var highlightNearby: Bool
    /// `Overworld.ShowMagnifier`, default `true`.
    public var showMagnifier: Bool
    /// `Overworld.ShopsFirst`, default `true`.
    public var shopsBeforeDungeons: Bool

    // MARK: Dungeon settings (top-level fields in TrackerModelOptions.fs)

    /// Rename the dungeon column label (T-171, generalizing the reference's
    /// `BOARDInsteadOfLEVEL`): when on, `customLevelPrefix` replaces the default
    /// `LEVEL-` word, so dungeons read `area-1`, `DUNGEON1`, `BOARD-1`, etc.
    public var renameLevelsEnabled: Bool
    /// The custom dungeon label **prefix** — everything before the slot digit, so it
    /// carries its own separator (`"area-"` → `area-1`, `"DUNGEON"` → `DUNGEON1`).
    /// Capped to 7 characters (prefix + 1 digit fills the 8-cell header). Only used
    /// when `renameLevelsEnabled`; default matches the built-in `LEVEL-`.
    public var customLevelPrefix: String

    /// The effective dungeon column-label prefix (T-171): the custom prefix when
    /// renaming is on, else the built-in `"LEVEL-"`. Callers pass this to
    /// `DungeonLabeling.columnName(slot:prefix:…)`.
    public var levelPrefix: String { renameLevelsEnabled ? customLevelPrefix : Self.defaultLevelPrefix }

    /// The built-in dungeon label prefix and the editor's character cap.
    public static let defaultLevelPrefix = "LEVEL-"
    public static let maxLevelPrefixLength = 7
    /// `ShowBasementInfo`, default `true`.
    public var showBasementInfo: Bool
    /// `DoDoorInference` — default **true** (T-156): auto-open the inferred entry
    /// door when a room is newly marked. It's a helpful default (and what makes
    /// voice "mark, move, mark" draw the connecting doors); toggle off in Settings.
    public var doDoorInference: Bool
    /// `BookForHelpfulHints`, default `false`.
    public var bookForHelpfulHints: Bool
    /// `LeftClickDragAutoInverts`, default `false`.
    public var leftDragAutoInverts: Bool
    /// `DefaultRoomPreferNonDescriptToMaybePushBlock`, default `false`.
    /// Labeled "Default to NonDescript" on-screen (`OptionsMenu.fs:60`).
    public var defaultToNonDescript: Bool
    /// `GiveDungeonTrackerSunglasses`, default `true`. Labeled "Dungeon
    /// 'sunglasses'" on-screen (`OptionsMenu.fs:61`).
    public var dungeonSunglasses: Bool

    // MARK: "More settings…" — overworld tile hiding (OptionsMenu.fs:115-205)

    /// `OverworldTilesToHide.*` for the 12 kinds in `OverworldHiddenTileKind`.
    /// All default `false` (nothing hidden), matching source.
    public var hiddenOverworldTiles: [OverworldHiddenTileKind: Bool]
    /// `OverworldTilesToHide.Shop`, default `false`. Labeled "Hide
    /// no-longer-relevant shop items" in the "More settings…" popup.
    public var hideNoLongerRelevantShopItems: Bool
    /// `OverworldTilesToHide.AlwaysHideMeatShops`, default `false`. Only
    /// meaningful when `hideNoLongerRelevantShopItems` is on
    /// (`OptionsMenu.fs:179-189`).
    public var alwaysHideMeatShops: Bool

    // MARK: Reminders

    /// `Volume`, default `30` (reference app range appears to be 0...100 —
    /// see the `max 0 (min 100 ...)` clamp in `TrackerModelOptions.fs:345`).
    /// Persisted across launches once `enableReminderPersistence` is called.
    public var reminderVolume: Int { didSet { persistRemindersIfNeeded() } }
    /// `VoiceReminders.*` — one entry per category. Defaults match source
    /// exactly: all `true` except `.recorderPBSpotsAndBoomstickBook` (`false`).
    public var voiceReminders: [ReminderCategory: Bool] { didSet { persistRemindersIfNeeded() } }
    /// `VisualReminders.*` — same categories and defaults as `voiceReminders`.
    public var visualReminders: [ReminderCategory: Bool] { didSet { persistRemindersIfNeeded() } }
    /// `PreferredVoice`, default empty (no preference / system default).
    public var preferredVoiceIdentifier: String? { didSet { persistRemindersIfNeeded() } }

    // MARK: Other

    /// `AnimateTileChanges`, default `true`.
    public var animateTileChanges: Bool
    /// `AnimateShopHighlights`, default `true`.
    public var animateShopHighlights: Bool
    /// `SaveOnCompletion`, default `false`.
    public var saveOnCompletion: Bool
    /// `SnoopSeedAndFlags`, default `false`.
    public var snoopSeedAndFlags: Bool
    /// `DisplaySeedAndFlags`, default `true`.
    public var displaySeedAndFlags: Bool
    /// `ListenForSpeech`, default `false`. Startup-screen-only per the
    /// reference app (docs/domain.md § 4.1) — this project carries that
    /// constraint forward by only exposing it here, not in a later settings
    /// surface (not yet enforced anywhere else, since no other surface exists).
    public var listenForSpeech: Bool
    /// `PlaySoundWhenUseSpeech`, default `true`. Labeled "Confirmation sound"
    /// on-screen.
    public var confirmationSound: Bool
    /// Use the alternate **detailed** (original, more complex) app icon instead of the
    /// default simple one (T-178, default **false**). The simple icon is the bundle
    /// icon; this swaps the *running* app's dock icon to the detailed design for people
    /// who prefer it (when closed, the Dock shows the default simple icon).
    public var useDetailedAppIcon: Bool
    /// Show the top **Info** panel (Spot Summary / Hint Decoder / overlay toggles /
    /// reset buttons) — T-178, default **true**. Off for players who don't use it and
    /// want a tighter layout (and a cleaner broadcast). Global: applies to the main
    /// window and the broadcast mirror alike.
    public var showInfoPanel: Bool
    /// `ShowMouseMagnifierWindow`, default `false`.
    public var showMouseMagnifierWindow: Bool
    /// `HideTimer`, default `false`. Labeled "Hide timer" on-screen
    /// (`OptionsMenu.fs:460-466`).
    public var hideTimer: Bool
    /// Warn before quitting while the run timer is still running (T-109, beyond
    /// the reference). Default **true**.
    public var warnOnCloseWhileTimerRunning: Bool
    /// Show a small live FPS/main-thread-responsiveness readout (dev diagnostic,
    /// beyond the reference). Default **false**.
    public var showFPS: Bool
    /// On launch, check GitHub for a newer release and show a dismissible notice
    /// (T-174, beyond the reference). Default **true**; it's an unauthenticated GET
    /// to the project's releases and sends no data, but stays user-toggleable.
    public var checkForUpdatesOnLaunch: Bool

    public init(
        drawRoutes: Bool = true,
        showScreenScrolls: Bool = false,
        highlightNearby: Bool = true,
        showMagnifier: Bool = true,
        shopsBeforeDungeons: Bool = true,
        renameLevelsEnabled: Bool = false,
        customLevelPrefix: String = TrackerOptions.defaultLevelPrefix,
        showBasementInfo: Bool = true,
        doDoorInference: Bool = true,
        bookForHelpfulHints: Bool = false,
        leftDragAutoInverts: Bool = false,
        defaultToNonDescript: Bool = false,
        dungeonSunglasses: Bool = true,
        hiddenOverworldTiles: [OverworldHiddenTileKind: Bool]? = nil,
        hideNoLongerRelevantShopItems: Bool = false,
        alwaysHideMeatShops: Bool = false,
        reminderVolume: Int = 30,
        voiceReminders: [ReminderCategory: Bool]? = nil,
        visualReminders: [ReminderCategory: Bool]? = nil,
        preferredVoiceIdentifier: String? = nil,
        animateTileChanges: Bool = true,
        animateShopHighlights: Bool = true,
        saveOnCompletion: Bool = false,
        snoopSeedAndFlags: Bool = false,
        displaySeedAndFlags: Bool = true,
        listenForSpeech: Bool = false,
        confirmationSound: Bool = true,
        useDetailedAppIcon: Bool = false,
        showInfoPanel: Bool = true,
        showMouseMagnifierWindow: Bool = false,
        hideTimer: Bool = false,
        warnOnCloseWhileTimerRunning: Bool = true,
        showFPS: Bool = false,
        checkForUpdatesOnLaunch: Bool = true
    ) {
        self.drawRoutes = drawRoutes
        self.showScreenScrolls = showScreenScrolls
        self.highlightNearby = highlightNearby
        self.showMagnifier = showMagnifier
        self.shopsBeforeDungeons = shopsBeforeDungeons
        self.renameLevelsEnabled = renameLevelsEnabled
        self.customLevelPrefix = customLevelPrefix
        self.showBasementInfo = showBasementInfo
        self.doDoorInference = doDoorInference
        self.bookForHelpfulHints = bookForHelpfulHints
        self.leftDragAutoInverts = leftDragAutoInverts
        self.defaultToNonDescript = defaultToNonDescript
        self.dungeonSunglasses = dungeonSunglasses
        self.hiddenOverworldTiles = hiddenOverworldTiles ?? Self.defaultHiddenOverworldTiles()
        self.hideNoLongerRelevantShopItems = hideNoLongerRelevantShopItems
        self.alwaysHideMeatShops = alwaysHideMeatShops
        self.reminderVolume = reminderVolume
        self.voiceReminders = voiceReminders ?? Self.defaultReminderToggles()
        self.visualReminders = visualReminders ?? Self.defaultReminderToggles()
        self.preferredVoiceIdentifier = preferredVoiceIdentifier
        self.animateTileChanges = animateTileChanges
        self.animateShopHighlights = animateShopHighlights
        self.saveOnCompletion = saveOnCompletion
        self.snoopSeedAndFlags = snoopSeedAndFlags
        self.displaySeedAndFlags = displaySeedAndFlags
        self.listenForSpeech = listenForSpeech
        self.confirmationSound = confirmationSound
        self.useDetailedAppIcon = useDetailedAppIcon
        self.showInfoPanel = showInfoPanel
        self.showMouseMagnifierWindow = showMouseMagnifierWindow
        self.hideTimer = hideTimer
        self.warnOnCloseWhileTimerRunning = warnOnCloseWhileTimerRunning
        self.showFPS = showFPS
        self.checkForUpdatesOnLaunch = checkForUpdatesOnLaunch
    }

    /// Every category defaults to `true` except `.recorderPBSpotsAndBoomstickBook`
    /// (`false`) — matches `VoiceReminders`/`VisualReminders` in
    /// `TrackerModelOptions.fs:22-39` exactly (both blocks have the same
    /// per-category defaults).
    private static func defaultReminderToggles() -> [ReminderCategory: Bool] {
        Dictionary(uniqueKeysWithValues: ReminderCategory.allCases.map { category in
            (category, category != .recorderPBSpotsAndBoomstickBook)
        })
    }

    /// All 12 hideable tile kinds default to `false` (nothing hidden),
    /// matching `OverworldTilesToHide` in `TrackerModelOptions.fs:40-54`.
    private static func defaultHiddenOverworldTiles() -> [OverworldHiddenTileKind: Bool] {
        Dictionary(uniqueKeysWithValues: OverworldHiddenTileKind.allCases.map { ($0, false) })
    }

    /// The "Disable all" button (docs/domain.md § 4.1) — not itself a
    /// persisted field in the reference app (no matching source field), a UI
    /// convenience that zeroes every voice+visual toggle. Implemented as a
    /// method rather than stored state for that reason.
    public func disableAllReminders() {
        for category in ReminderCategory.allCases {
            voiceReminders[category] = false
            visualReminders[category] = false
        }
    }

    // MARK: Reminder-settings persistence (T-004.1)

    /// Where the reminder settings persist. `nil` (the default) disables
    /// persistence, so plain `TrackerOptions()` — used throughout the tests and
    /// previews — never touches `UserDefaults`. The app opts in once at launch
    /// via `enableReminderPersistence`.
    @ObservationIgnored private var reminderStore: UserDefaults?
    /// Set while `enableReminderPersistence` applies loaded values, so the
    /// `didSet` observers don't immediately write them straight back.
    @ObservationIgnored private var isApplyingPersistedReminders = false

    private static let volumeKey = "ztracker.reminders.volume"
    private static let voiceKey = "ztracker.reminders.voice"
    private static let visualKey = "ztracker.reminders.visual"
    private static let preferredVoiceKey = "ztracker.reminders.preferredVoice"

    /// Turns on reminder-settings persistence to `store` and applies whatever
    /// was saved on a previous launch over the current defaults (T-004.1). Only
    /// the Reminders section persists for now: volume, the per-category voice /
    /// visual toggles, and the preferred voice. Categories missing from a saved
    /// dictionary keep their default, so adding a category later is safe.
    public func enableReminderPersistence(store: UserDefaults = .standard) {
        reminderStore = store
        isApplyingPersistedReminders = true
        defer { isApplyingPersistedReminders = false }

        if store.object(forKey: Self.volumeKey) != nil {
            reminderVolume = max(0, min(100, store.integer(forKey: Self.volumeKey)))
        }
        if let raw = store.dictionary(forKey: Self.voiceKey) as? [String: Bool] {
            voiceReminders = Self.decodeToggles(raw, over: voiceReminders)
        }
        if let raw = store.dictionary(forKey: Self.visualKey) as? [String: Bool] {
            visualReminders = Self.decodeToggles(raw, over: visualReminders)
        }
        if let id = store.string(forKey: Self.preferredVoiceKey) {
            preferredVoiceIdentifier = id
        }
    }

    /// Writes the current reminder settings to the store, unless persistence is
    /// off or we're mid-load. Driven by the `didSet` observers, so every UI
    /// mutation (a toggle, the volume slider, "Disable all", the voice picker)
    /// saves automatically.
    private func persistRemindersIfNeeded() {
        guard let store = reminderStore, !isApplyingPersistedReminders else { return }
        store.set(reminderVolume, forKey: Self.volumeKey)
        store.set(Self.encodeToggles(voiceReminders), forKey: Self.voiceKey)
        store.set(Self.encodeToggles(visualReminders), forKey: Self.visualKey)
        if let id = preferredVoiceIdentifier {
            store.set(id, forKey: Self.preferredVoiceKey)
        } else {
            store.removeObject(forKey: Self.preferredVoiceKey)
        }
    }

    /// `[ReminderCategory: Bool]` → a `[String: Bool]` keyed by the category's
    /// stable `rawValue`, so `UserDefaults` (and any future JSON) can store it.
    private static func encodeToggles(_ toggles: [ReminderCategory: Bool]) -> [String: Bool] {
        Dictionary(uniqueKeysWithValues: toggles.map { ($0.key.rawValue, $0.value) })
    }

    /// Applies a saved `[String: Bool]` over `base`, ignoring unknown keys and
    /// leaving categories absent from the save at their `base` value.
    private static func decodeToggles(_ raw: [String: Bool],
                                      over base: [ReminderCategory: Bool]) -> [ReminderCategory: Bool] {
        var result = base
        for (key, value) in raw {
            if let category = ReminderCategory(rawValue: key) { result[category] = value }
        }
        return result
    }

    /// A `TrackerOptions` with reminder persistence enabled and any saved
    /// reminder settings applied — the app's entry point (T-004.1).
    public static func withReminderPersistence(store: UserDefaults = .standard) -> TrackerOptions {
        let options = TrackerOptions()
        options.enableReminderPersistence(store: store)
        return options
    }

    // MARK: Startup-settings persistence (T-004.2)

    /// Where the startup settings persist. `nil` disables it (tests/previews).
    @ObservationIgnored private var settingsStore: UserDefaults?
    /// Set while a saved snapshot is being applied, so a keypath write doesn't
    /// recurse. (Kept for symmetry with the reminders path; loads are one-shot.)
    @ObservationIgnored private var isApplyingSettings = false

    private static let settingsBoolsKey = "ztracker.settings.bools"
    private static let hiddenTilesKey = "ztracker.settings.hiddenTiles"
    private static let customLevelPrefixKey = "ztracker.settings.customLevelPrefix"

    /// Every persisted Bool setting, keyed by a stable name → its storage. This
    /// is the single source of truth for what persists — add a setting here and
    /// it saves + loads automatically. (Non-Bool settings — the broadcast size
    /// and the hidden-tiles map — persist under their own keys below.)
    // Immutable map; `nonisolated(unsafe)` because key paths of the (non-Sendable)
    // options class aren't `Sendable`, though the dictionary itself never mutates.
    nonisolated(unsafe) static let persistedBoolKeyPaths: [String: ReferenceWritableKeyPath<TrackerOptions, Bool>] = [
        "drawRoutes": \.drawRoutes,
        "showScreenScrolls": \.showScreenScrolls,
        "highlightNearby": \.highlightNearby,
        "showMagnifier": \.showMagnifier,
        "shopsBeforeDungeons": \.shopsBeforeDungeons,
        "renameLevelsEnabled": \.renameLevelsEnabled,
        "showBasementInfo": \.showBasementInfo,
        "doDoorInference": \.doDoorInference,
        "bookForHelpfulHints": \.bookForHelpfulHints,
        "leftDragAutoInverts": \.leftDragAutoInverts,
        "defaultToNonDescript": \.defaultToNonDescript,
        "dungeonSunglasses": \.dungeonSunglasses,
        "hideNoLongerRelevantShopItems": \.hideNoLongerRelevantShopItems,
        "alwaysHideMeatShops": \.alwaysHideMeatShops,
        "animateTileChanges": \.animateTileChanges,
        "animateShopHighlights": \.animateShopHighlights,
        "saveOnCompletion": \.saveOnCompletion,
        "snoopSeedAndFlags": \.snoopSeedAndFlags,
        "displaySeedAndFlags": \.displaySeedAndFlags,
        "listenForSpeech": \.listenForSpeech,
        "confirmationSound": \.confirmationSound,
        "useDetailedAppIcon": \.useDetailedAppIcon,
        "showInfoPanel": \.showInfoPanel,
        "showMouseMagnifierWindow": \.showMouseMagnifierWindow,
        "hideTimer": \.hideTimer,
        "warnOnCloseWhileTimerRunning": \.warnOnCloseWhileTimerRunning,
        "showFPS": \.showFPS,
        "checkForUpdatesOnLaunch": \.checkForUpdatesOnLaunch,
    ]

    /// Turn on startup-settings persistence and apply whatever a previous launch
    /// saved over the current defaults (T-004.2). Unknown/missing keys keep their
    /// default, so adding or removing a setting later is safe.
    public func enableSettingsPersistence(store: UserDefaults = .standard) {
        settingsStore = store
        isApplyingSettings = true
        defer { isApplyingSettings = false }

        if let bools = store.dictionary(forKey: Self.settingsBoolsKey) as? [String: Bool] {
            for (key, value) in bools {
                if let keyPath = Self.persistedBoolKeyPaths[key] { self[keyPath: keyPath] = value }
            }
        }
        if let raw = store.dictionary(forKey: Self.hiddenTilesKey) as? [String: Bool] {
            hiddenOverworldTiles = Self.decodeHiddenTiles(raw, over: hiddenOverworldTiles)
        }
        if let prefix = store.string(forKey: Self.customLevelPrefixKey) {
            customLevelPrefix = prefix
        }
    }

    /// Write the current startup settings to the store (no-op if persistence is
    /// off). Called at the commit point — when a quest starts — since the startup
    /// settings are only editable before the run.
    public func saveSettings() {
        guard let store = settingsStore, !isApplyingSettings else { return }
        var bools: [String: Bool] = [:]
        for (key, keyPath) in Self.persistedBoolKeyPaths { bools[key] = self[keyPath: keyPath] }
        store.set(bools, forKey: Self.settingsBoolsKey)
        store.set(Self.encodeHiddenTiles(hiddenOverworldTiles), forKey: Self.hiddenTilesKey)
        store.set(customLevelPrefix, forKey: Self.customLevelPrefixKey)
    }

    private static func encodeHiddenTiles(_ tiles: [OverworldHiddenTileKind: Bool]) -> [String: Bool] {
        Dictionary(uniqueKeysWithValues: tiles.map { ($0.key.rawValue, $0.value) })
    }
    private static func decodeHiddenTiles(_ raw: [String: Bool],
                                          over base: [OverworldHiddenTileKind: Bool]) -> [OverworldHiddenTileKind: Bool] {
        var result = base
        for (key, value) in raw {
            if let kind = OverworldHiddenTileKind(rawValue: key) { result[kind] = value }
        }
        return result
    }

    /// The app's entry point: a `TrackerOptions` with both reminder- and
    /// startup-settings persistence enabled and any saved values applied.
    public static func withPersistence(store: UserDefaults = .standard) -> TrackerOptions {
        let options = TrackerOptions()
        options.enableReminderPersistence(store: store)
        options.enableSettingsPersistence(store: store)
        return options
    }
}
